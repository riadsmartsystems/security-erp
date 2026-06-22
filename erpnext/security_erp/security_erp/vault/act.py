"""vault/act.py — Access Transfer Act: generate / get_meta / serve / acknowledge.

Security model
--------------
- ``token_hex`` (64 hex chars, 256-bit entropy) — first factor.
  Redis key: act:tok:{token_hex} → JSON{act_name, expires_at}. TTL=86400s.
- OTP (6 digits) — second factor, transmitted via separate channel.
  Redis key: act:otp:{token_hex} → sha256(otp). TTL=86400s.
- Reverse lookup: act:act_to_tok:{act_name} → token_hex. TTL=86400s.
  Used only by generate() for revoke-on-regenerate.
- MariaDB field delivery_token = sha256(token_hex) — non-reversible.
- Decrypted secrets live only in Python memory during a single HTTP response.
- Token is burned (all 3 Redis keys deleted) on acknowledge() only.
  serve() leaves the token alive so client can view multiple times.
"""

import hashlib
import json
import secrets
from datetime import datetime, timedelta, timezone

import frappe

from ._crypto import _decrypt_field, _is_encrypted
from ._hooks import ENC_FIELDS
from ._key import _load_key
from .audit import append_audit_log
from .mfa import _check_mfa_session

_ACT_TTL = 86400  # 24 hours


# ── Redis key helpers ─────────────────────────────────────────────────────────


def _token_key(token: str) -> str:
    return f"act:tok:{token}"


def _otp_key(token: str) -> str:
    return f"act:otp:{token}"


def _act_to_tok_key(act_name: str) -> str:
    return f"act:act_to_tok:{act_name}"


def _sha256(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


# ── Request context helpers ───────────────────────────────────────────────────


def _current_ip() -> str:
    try:
        return frappe.local.request_ip or ""
    except Exception:
        return ""


def _current_sid() -> str:
    try:
        return frappe.session.sid or ""
    except Exception:
        return ""


# ── Shared validator ──────────────────────────────────────────────────────────


def _validate_token_and_otp(token_hex: str, otp_code: str) -> str:
    """Read Redis, validate OTP hash, return act_name. Throws on invalid.

    Does NOT burn the token — caller is responsible for that (only acknowledge
    burns; serve does not).
    """
    cache = frappe.cache()

    tok_raw = cache.get_value(_token_key(token_hex))
    if not tok_raw:
        frappe.throw("Посилання недійсне або закінчилося.", frappe.DoesNotExistError)

    tok_data = json.loads(tok_raw) if isinstance(tok_raw, str) else tok_raw
    act_name = tok_data["act_name"]

    otp_hash_stored = cache.get_value(_otp_key(token_hex))
    if not otp_hash_stored:
        frappe.throw("Посилання недійсне або закінчилося.", frappe.DoesNotExistError)

    if _sha256(otp_code) != otp_hash_stored:
        frappe.throw("Невірний код доступу.", frappe.PermissionError)

    return act_name


# ── Whitelist methods ─────────────────────────────────────────────────────────


@frappe.whitelist()
def generate(act_name: str, vault_session_token: str = "") -> dict:
    """Generate a one-time delivery link + 6-digit OTP for an Access Transfer Act.

    MFA gate: vault_session_token required (V3 TOTP step-up, 300s).
    Requires write permission on Access Transfer Act.

    Revoke logic:
    - If a previous token exists in Redis (act:act_to_tok) → delete old Redis
      keys + write act_revoke audit.
    - If that key is already expired (>24h since last generate) → skip silently,
      no audit entry (token was already dead by TTL).

    Returns {ok, token, otp, link, expires_at}.
    OTP is returned ONCE here — never stored plaintext anywhere.
    """
    _check_mfa_session(vault_session_token, frappe.session.user)
    frappe.has_permission("Access Transfer Act", ptype="write", doc=act_name, throw=True)

    act = frappe.get_doc("Access Transfer Act", act_name)
    if not act.included_entries:
        frappe.throw("Акт не містить жодного Vault Entry.", frappe.ValidationError)

    cache = frappe.cache()
    user = frappe.session.user

    # Revoke previous link if still alive in Redis.
    if act.delivery_token and not act.link_burned:
        old_token = cache.get_value(_act_to_tok_key(act_name))
        if old_token:
            cache.delete_value(_token_key(old_token))
            cache.delete_value(_otp_key(old_token))
            cache.delete_value(_act_to_tok_key(act_name))
            append_audit_log(
                "act_revoke",
                vault_entry="",
                field_touched=act_name,
                user=user,
                session_id=_current_sid(),
                ip=_current_ip(),
            )
        # else: previous token expired by TTL — silent skip, no audit.

    token = secrets.token_hex(32)
    otp = f"{secrets.randbelow(1_000_000):06d}"
    expires_at = datetime.now(timezone.utc) + timedelta(seconds=_ACT_TTL)
    expires_at_str = expires_at.strftime("%Y-%m-%d %H:%M:%S")

    cache.set_value(_token_key(token), json.dumps({"act_name": act_name, "expires_at": expires_at_str}), expires_in_sec=_ACT_TTL)
    cache.set_value(_otp_key(token), _sha256(otp), expires_in_sec=_ACT_TTL)
    cache.set_value(_act_to_tok_key(act_name), token, expires_in_sec=_ACT_TTL)

    frappe.db.set_value(
        "Access Transfer Act",
        act_name,
        {
            "delivery_token": _sha256(token),
            "delivery_token_expires_at": expires_at_str,
            "generated_by": user,
            "generated_at": frappe.utils.now_datetime(),
            "link_burned": 0,
        },
    )
    frappe.db.commit()

    append_audit_log(
        "act_generate",
        vault_entry="",
        field_touched=act_name,
        user=user,
        session_id=_current_sid(),
        ip=_current_ip(),
    )

    return {
        "ok": True,
        "token": token,
        "otp": otp,
        "link": f"/api/v2/act/public/{token}",
        "expires_at": expires_at_str,
    }


@frappe.whitelist(allow_guest=True)
def get_meta(token_hex: str) -> dict:
    """Return non-sensitive metadata about an act without OTP or decryption.

    Strict field whitelist: no delivery_token, generated_by, or audit_ref.
    Lets the client confirm the link is valid before entering OTP.
    """
    tok_raw = frappe.cache().get_value(_token_key(token_hex))
    if not tok_raw:
        frappe.throw("Посилання недійсне або закінчилося.", frappe.DoesNotExistError)

    tok_data = json.loads(tok_raw) if isinstance(tok_raw, str) else tok_raw
    act_name = tok_data["act_name"]
    act = frappe.get_doc("Access Transfer Act", act_name)

    return {
        "act_name": act.name,
        "passport_label": act.passport,
        "customer_label": act.customer,
        "generated_at": str(act.generated_at or ""),
        "expires_at": str(act.delivery_token_expires_at or ""),
        "entry_count": len(act.included_entries),
        "link_burned": bool(act.link_burned),
    }


@frappe.whitelist(allow_guest=True)
def serve(token_hex: str, otp_code: str) -> dict:
    """Decrypt and return all non-empty *_enc fields for each Vault Entry in the act.

    In-memory only: decrypted dict is built, returned, then garbage-collected.
    Token is NOT burned — client may view multiple times until acknowledge.
    Writes audit log action=act_view.
    """
    act_name = _validate_token_and_otp(token_hex, otp_code)
    act = frappe.get_doc("Access Transfer Act", act_name)
    key = _load_key()

    entries = []
    for row in act.included_entries:
        ve_name = row.vault_entry
        try:
            ve = frappe.get_doc("Vault Entry", ve_name)
        except frappe.DoesNotExistError:
            continue

        fields = {
            f: _decrypt_field(ve.get(f), key)
            for f in ENC_FIELDS
            if ve.get(f) and _is_encrypted(ve.get(f))
        }

        entries.append({
            "vault_entry": ve_name,
            "label": ve.name,
            "fields": fields,
        })

    append_audit_log(
        "act_view",
        vault_entry="",
        field_touched=act_name,
        user=act.generated_by or "Guest",
        session_id="",
        ip=_current_ip(),
    )

    return {"ok": True, "act_name": act_name, "entries": entries}


@frappe.whitelist(allow_guest=True)
def acknowledge(token_hex: str, otp_code: str) -> dict:
    """Client acknowledges receipt. Burns all three Redis keys.

    Updates: client_acknowledged=1, acknowledged_at, link_burned=1.
    Writes audit log action=act_acknowledge.
    """
    act_name = _validate_token_and_otp(token_hex, otp_code)

    now = frappe.utils.now_datetime()
    frappe.db.set_value(
        "Access Transfer Act",
        act_name,
        {"client_acknowledged": 1, "acknowledged_at": now, "link_burned": 1},
    )
    frappe.db.commit()

    cache = frappe.cache()
    cache.delete_value(_token_key(token_hex))
    cache.delete_value(_otp_key(token_hex))
    cache.delete_value(_act_to_tok_key(act_name))

    append_audit_log(
        "act_acknowledge",
        vault_entry="",
        field_touched=act_name,
        user="Guest",
        session_id="",
        ip=_current_ip(),
    )

    return {"ok": True, "acknowledged_at": str(now)}
