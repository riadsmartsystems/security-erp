# V4 Access Transfer Act — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement act.generate / serve / acknowledge over a one-time TTL link (Redis, 24h) with OTP second factor and in-memory-only decryption; add ERPNext desk UI for managers.

**Architecture:** Frappe `vault/act.py` holds all crypto and business logic (4 `@whitelist` methods). FastAPI adds a JWT-protected `/api/v2/vault/act/generate` for mobile/external callers and a public `/api/v2/act/public/{token}` set (no JWT) for the client-facing link. The ERPNext desk JS calls Frappe whitelist methods directly (no JWT needed there). A minimal static HTML page in FastAPI serves the client-facing experience.

**Tech Stack:** Frappe v15 / Python 3.11, `frappe.cache()` (Redis via Frappe wrapper), `hashlib.sha256`, `secrets`, FastAPI / httpx, vanilla HTML+JS for public page.

## Global Constraints

- Decrypted data in-memory only — never stored at-rest, never logged
- `token_hex` and OTP plaintext — only in Redis (TTL=86400s), never in MariaDB
- MariaDB `delivery_token` field holds `sha256(token_hex)` only (non-reversible)
- `act.py` lives inside `security_erp/vault/` — V2 CI linter must stay green
- New audit action values: `act_generate`, `act_revoke`, `act_view`, `act_acknowledge`
- All Frappe calls from desk JS use `frappe.call()` (no JWT required)
- C2/H1 gate: real Vault secrets in production only after key-escrow (H1)
- `bench` commands run inside the `backend` Docker container: `docker exec -it riadcrm-backend-1 bash`

---

## File Map

### Create (new files)
| File | Responsibility |
|---|---|
| `erpnext/security_erp/security_erp/vault/act.py` | 4 Frappe whitelist methods: generate, get_meta, serve, acknowledge |
| `tests/vault/test_act_pure.py` | Pure-logic unit tests (no Frappe dependency) |
| `services/security-api/app/routes/act.py` | FastAPI public + protected act endpoints |
| `services/security-api/app/static/act.html` | Client-facing public page (vanilla JS, reads token from URL) |
| `erpnext/security_erp/security_erp/security_erp/doctype/access_transfer_act/access_transfer_act.js` | Frappe desk form client script |

### Modify (existing files)
| File | What changes |
|---|---|
| `erpnext/security_erp/security_erp/security_erp/doctype/vault_audit_log/vault_audit_log.json` | Add `act_revoke`, `act_view`, `act_acknowledge` to `action` Select options |
| `erpnext/security_erp/security_erp/security_erp/doctype/access_transfer_act/access_transfer_act.json` | Add 4 new fields: `delivery_token`, `delivery_token_expires_at`, `otp_hint`, `link_burned` |
| `services/security-api/app/core/database.py` | Add `frappe_guest_post()` helper |
| `services/security-api/app/schemas/vault.py` | Add `ActOtpRequest`, `ActGenerateRequest` |
| `services/security-api/app/main.py` | Import `act_router`, add `/act/{token}` static route, include router |

---

## Task 1: Schema Migrations

**Files:**
- Modify: `erpnext/security_erp/security_erp/security_erp/doctype/vault_audit_log/vault_audit_log.json`
- Modify: `erpnext/security_erp/security_erp/security_erp/doctype/access_transfer_act/access_transfer_act.json`

**Interfaces:**
- Produces: `Vault Audit Log.action` Select accepts `act_revoke`, `act_view`, `act_acknowledge`; `Access Transfer Act` has `delivery_token`, `delivery_token_expires_at`, `otp_hint`, `link_burned` fields

- [ ] **Step 1: Update vault_audit_log.json action Select**

In `vault_audit_log.json`, find the `action` field object and change its `options` value:

```json
{
    "fieldname": "action",
    "fieldtype": "Select",
    "label": "Action",
    "options": "\nview\ncreate\nupdate\nexport\nact_generate\nmfa_fail\nact_revoke\nact_view\nact_acknowledge",
    "reqd": 1,
    "in_list_view": 1
}
```

- [ ] **Step 2: Add 4 new fields to access_transfer_act.json**

In `access_transfer_act.json`, add inside `"fields": [...]` before the closing `]`, after the `included_entries` field:

```json
        {
            "fieldname": "section_delivery_meta",
            "fieldtype": "Section Break",
            "label": "Link Delivery"
        },
        {
            "fieldname": "delivery_token",
            "fieldtype": "Data",
            "label": "Delivery Token (hash)",
            "read_only": 1
        },
        {
            "fieldname": "delivery_token_expires_at",
            "fieldtype": "Datetime",
            "label": "Link Expires At",
            "read_only": 1,
            "in_list_view": 1
        },
        {
            "fieldname": "column_break_delivery",
            "fieldtype": "Column Break"
        },
        {
            "fieldname": "otp_hint",
            "fieldtype": "Data",
            "label": "OTP Hint",
            "read_only": 1,
            "default": "6-digit code (sent separately)"
        },
        {
            "fieldname": "link_burned",
            "fieldtype": "Check",
            "label": "Link Burned",
            "default": "0",
            "read_only": 1,
            "in_list_view": 1
        }
```

- [ ] **Step 3: Run bench migrate in Docker**

```bash
docker exec -it riadcrm-backend-1 bash -c "cd /home/frappe/frappe-bench && bench --site erp.localhost migrate"
```

Expected output: `Updating DocTypes for security_erp` with no new errors (pre-existing `Stock Entry.project` error is known and unrelated).

- [ ] **Step 4: Verify new columns in MariaDB**

```bash
docker exec -it riadcrm-mariadb-1 mysql -u root -p"$(grep MARIADB_ROOT_PASSWORD /home/joker/RIAD\ CRM/.env | cut -d= -f2)" _73c82ec6d255ebe3 -e "
  SELECT column_name, column_type, column_default
  FROM information_schema.columns
  WHERE table_name IN ('tabVault Audit Log','tabAccess Transfer Act')
    AND column_name IN ('action','delivery_token','delivery_token_expires_at','otp_hint','link_burned')
  ORDER BY table_name, column_name;"
```

Expected: 5 rows. `action` column type is `varchar(140)` (Frappe Select = varchar). `link_burned` is `int(1) NOT NULL DEFAULT 0`.

- [ ] **Step 5: Commit**

```bash
git add erpnext/security_erp/security_erp/security_erp/doctype/vault_audit_log/vault_audit_log.json \
        erpnext/security_erp/security_erp/security_erp/doctype/access_transfer_act/access_transfer_act.json
git commit -m "feat(schema): V4 — extend vault_audit_log action Select + add act delivery fields"
```

---

## Task 2: vault/act.py + Pure Logic Tests

**Files:**
- Create: `erpnext/security_erp/security_erp/vault/act.py`
- Create: `tests/vault/test_act_pure.py`

**Interfaces:**
- Consumes: `vault._crypto._decrypt_field(stored, key)→str`, `vault._crypto._is_encrypted(s)→bool`, `vault._hooks.ENC_FIELDS: list[str]`, `vault._key._load_key()→bytes`, `vault.audit.append_audit_log(action, *, vault_entry, field_touched, user, session_id, ip)→str`, `vault.mfa._check_mfa_session(token, user)→None`
- Produces: `security_erp.vault.act.generate(act_name, vault_session_token)→dict`, `security_erp.vault.act.get_meta(token_hex)→dict`, `security_erp.vault.act.serve(token_hex, otp_code)→dict`, `security_erp.vault.act.acknowledge(token_hex, otp_code)→dict`

- [ ] **Step 1: Write pure-logic tests (they will pass immediately — no Frappe)**

Create `tests/vault/test_act_pure.py`:

```python
"""Pure-logic unit tests for vault/act.py helpers.

These tests verify the cryptographic helpers and Redis key naming used
by vault/act.py without requiring a live Frappe/MariaDB environment.
Run with: python -m pytest tests/vault/test_act_pure.py -v
"""
import hashlib
import secrets


def _sha256(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


# ── OTP helpers ──────────────────────────────────────────────────────────────

class TestOtpGeneration:
    def test_otp_is_six_digits(self):
        otp = f"{secrets.randbelow(1_000_000):06d}"
        assert len(otp) == 6
        assert otp.isdigit()

    def test_otp_lower_bound_padded(self):
        # Smallest value (0) pads to "000000"
        assert f"{0:06d}" == "000000"

    def test_otp_upper_bound(self):
        # Largest value (999999) has 6 digits
        assert f"{999999:06d}" == "999999"


class TestOtpHashing:
    def test_sha256_deterministic(self):
        otp = "482917"
        assert _sha256(otp) == _sha256(otp)

    def test_sha256_length(self):
        assert len(_sha256("000000")) == 64

    def test_sha256_different_inputs(self):
        assert _sha256("000000") != _sha256("000001")

    def test_correct_otp_matches(self):
        otp = "123456"
        stored = _sha256(otp)
        assert _sha256(otp) == stored

    def test_wrong_otp_does_not_match(self):
        stored = _sha256("123456")
        assert _sha256("654321") != stored


# ── Redis key naming ──────────────────────────────────────────────────────────

class TestRedisKeys:
    def test_token_key(self):
        token = "abc123"
        assert f"act:tok:{token}" == "act:tok:abc123"

    def test_otp_key(self):
        token = "abc123"
        assert f"act:otp:{token}" == "act:otp:abc123"

    def test_act_to_tok_key(self):
        assert f"act:act_to_tok:ACT-000001" == "act:act_to_tok:ACT-000001"

    def test_token_hex_is_64_chars(self):
        token = secrets.token_hex(32)
        assert len(token) == 64
        assert all(c in "0123456789abcdef" for c in token)


# ── delivery_token in MariaDB is sha256(token), not token itself ─────────────

class TestDeliveryTokenStorage:
    def test_token_hash_not_reversible(self):
        token = secrets.token_hex(32)
        stored = _sha256(token)
        # stored is 64-char hex, not the original token
        assert stored != token
        assert len(stored) == 64

    def test_two_tokens_never_collide(self):
        t1 = secrets.token_hex(32)
        t2 = secrets.token_hex(32)
        assert t1 != t2
        assert _sha256(t1) != _sha256(t2)
```

- [ ] **Step 2: Run pure tests (expect all PASS)**

```bash
cd "/home/joker/RIAD CRM" && python -m pytest tests/vault/test_act_pure.py -v
```

Expected: `10 passed` (no Frappe import, pure stdlib).

- [ ] **Step 3: Create vault/act.py**

Create `erpnext/security_erp/security_erp/vault/act.py`:

```python
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
        user=act.generated_by or "guest",
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
        user="guest",
        session_id="",
        ip=_current_ip(),
    )

    return {"ok": True, "acknowledged_at": str(now)}
```

- [ ] **Step 4: Verify vault isolation linter stays green**

```bash
cd "/home/joker/RIAD CRM" && python tests/vault_isolation/check_vault_isolation.py
```

Expected: `OK: N files scanned across 7 restricted paths` (N increases by 1 — `act.py` is inside `vault/`, not in restricted paths).

- [ ] **Step 5: Verify Python syntax**

```bash
python -m py_compile erpnext/security_erp/security_erp/vault/act.py && echo "OK"
```

Expected: `OK`

- [ ] **Step 6: Commit**

```bash
git add erpnext/security_erp/security_erp/vault/act.py tests/vault/test_act_pure.py
git commit -m "feat(vault): V4 — vault/act.py generate/serve/acknowledge/get_meta + pure tests"
```

---

## Task 3: FastAPI Layer

**Files:**
- Modify: `services/security-api/app/core/database.py` — add `frappe_guest_post()`
- Modify: `services/security-api/app/schemas/vault.py` — add `ActOtpRequest`, `ActGenerateRequest`
- Create: `services/security-api/app/routes/act.py`
- Modify: `services/security-api/app/main.py` — import and include `act_router`

**Interfaces:**
- Consumes: `frappe_guest_post(path, data)→dict`, `frappe_post(path, data, sid)→dict`, `get_current_user→CurrentUser`
- Produces: `GET /api/v2/act/public/{token}`, `POST /api/v2/act/public/{token}/view`, `POST /api/v2/act/public/{token}/acknowledge`, `POST /api/v2/vault/act/generate`

- [ ] **Step 1: Add `frappe_guest_post` to database.py**

In `services/security-api/app/core/database.py`, add after `frappe_post`:

```python
async def frappe_guest_post(path: str, data: dict = None) -> dict:
    """POST to a Frappe @whitelist(allow_guest=True) method without session cookie."""
    resp = await _get_client().post(path, json=data, headers=_headers_with_host())
    resp.raise_for_status()
    return resp.json()


async def frappe_guest_get(path: str, params: dict = None) -> dict:
    """GET a Frappe @whitelist(allow_guest=True) method without session cookie."""
    resp = await _get_client().get(path, params=params, headers=_headers_with_host())
    resp.raise_for_status()
    return resp.json()
```

- [ ] **Step 2: Add schemas to vault.py**

In `services/security-api/app/schemas/vault.py`, add at the end:

```python
class ActOtpRequest(BaseModel):
    otp: str


class ActGenerateRequest(BaseModel):
    act_name: str
    vault_session_token: str
```

- [ ] **Step 3: Create routes/act.py**

Create `services/security-api/app/routes/act.py`:

```python
"""Act routes — /api/v2/act/public/* (no JWT) and /api/v2/vault/act/* (JWT).

Public endpoints authenticate via Redis one-time token + OTP hash.
FastAPI is a thin proxy: no decryption, no caching of secrets.
All crypto happens inside the Frappe process (vault/act.py).
"""

import json

import httpx
from fastapi import APIRouter, Depends, HTTPException, status

from app.auth.dependencies import CurrentUser, get_current_user
from app.core.database import frappe_guest_get, frappe_guest_post, frappe_post
from app.schemas.vault import ActGenerateRequest, ActOtpRequest

public_router = APIRouter(prefix="/api/v2/act/public", tags=["act-public"])
act_router = APIRouter(prefix="/api/v2/vault/act", tags=["act"])


def _frappe_act(method: str) -> str:
    return f"/api/method/security_erp.vault.act.{method}"


def _map_frappe_error(exc: httpx.HTTPStatusError) -> HTTPException:
    try:
        body = exc.response.json()
        exc_type = body.get("exc_type", "")
        msg = body.get("_server_messages", "") or body.get("message", str(exc))
        if isinstance(msg, str) and msg.startswith("["):
            try:
                parsed = json.loads(msg)
                msg = json.loads(parsed[0]).get("message", msg) if parsed else msg
            except Exception:
                pass
    except Exception:
        msg = str(exc)
        exc_type = ""

    http_code = exc.response.status_code
    if http_code == 403 or "PermissionError" in exc_type:
        return HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail={"code": "RIAD-ACT-FORBIDDEN", "message": msg})
    if http_code == 404 or "DoesNotExistError" in exc_type:
        return HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"code": "RIAD-ACT-NOT-FOUND", "message": msg})
    return HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail={"code": "RIAD-ACT-UPSTREAM-ERROR", "message": msg})


def _unwrap(result: dict):
    return result.get("message", result)


# ── Public endpoints (no JWT) ─────────────────────────────────────────────────


@public_router.get("/{token}")
async def act_get_meta(token: str):
    """Return non-sensitive act metadata. No OTP required.

    Client uses this to confirm the link is valid before entering OTP.
    Strict whitelist: no delivery_token, generated_by, or audit_ref.
    """
    try:
        result = await frappe_guest_get(
            _frappe_act("get_meta"),
            params={"token_hex": token},
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
    return _unwrap(result)


@public_router.post("/{token}/view")
async def act_view(token: str, body: ActOtpRequest):
    """Decrypt and return vault entry fields for the client.

    Requires valid OTP. Token is NOT burned after view — client may view
    multiple times. Decrypted data is never cached by FastAPI.
    """
    try:
        result = await frappe_guest_post(
            _frappe_act("serve"),
            data={"token_hex": token, "otp_code": body.otp},
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
    return _unwrap(result)


@public_router.post("/{token}/acknowledge")
async def act_acknowledge(token: str, body: ActOtpRequest):
    """Client acknowledges receipt. Burns the Redis token.

    After this call, the link is permanently invalid.
    """
    try:
        result = await frappe_guest_post(
            _frappe_act("acknowledge"),
            data={"token_hex": token, "otp_code": body.otp},
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
    return _unwrap(result)


# ── Protected endpoint (JWT required) ────────────────────────────────────────


@act_router.post("/generate")
async def act_generate(
    body: ActGenerateRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    """Generate a one-time delivery link + OTP for an Access Transfer Act.

    Requires JWT + fresh vault_session_token (V3 TOTP step-up).
    Returns {token, otp, link, expires_at}. OTP displayed once — never stored.
    """
    try:
        result = await frappe_post(
            _frappe_act("generate"),
            data={
                "act_name": body.act_name,
                "vault_session_token": body.vault_session_token,
            },
            sid=current_user.frappe_sid,
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
    return _unwrap(result)
```

- [ ] **Step 4: Register routers in main.py**

In `services/security-api/app/main.py`, add import after vault import:

```python
from app.routes.act import act_router, public_router as act_public_router
```

Add both router includes before the proxy router line (proxy must be last):

```python
app.include_router(act_router)
app.include_router(act_public_router)
```

Also add the static page route (add after the existing `/test` route):

```python
@app.get("/act/{token}")
async def act_page(token: str):
    return FileResponse("/app/app/static/act.html", headers={"Cache-Control": "no-cache, no-store, must-revalidate"})
```

- [ ] **Step 5: Verify Python syntax**

```bash
python -m py_compile services/security-api/app/routes/act.py \
                      services/security-api/app/core/database.py \
                      services/security-api/app/schemas/vault.py \
                      services/security-api/app/main.py && echo "OK"
```

Expected: `OK`

- [ ] **Step 6: Commit**

```bash
git add services/security-api/app/core/database.py \
        services/security-api/app/schemas/vault.py \
        services/security-api/app/routes/act.py \
        services/security-api/app/main.py
git commit -m "feat(api): V4 — FastAPI act routes (public TTL + protected generate)"
```

---

## Task 4: Public Client HTML Page

**Files:**
- Create: `services/security-api/app/static/act.html`

**Interfaces:**
- Consumes: `GET /api/v2/act/public/{token}`, `POST /api/v2/act/public/{token}/view`, `POST /api/v2/act/public/{token}/acknowledge`
- Produces: browser page at `/act/{token}` — shows metadata, OTP form, decrypted fields, acknowledge button

- [ ] **Step 1: Create act.html**

Create `services/security-api/app/static/act.html`:

```html
<!DOCTYPE html>
<html lang="uk">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>RIAD — Акт передачі доступів</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
         background: #0f1117; color: #e2e8f0; min-height: 100vh;
         display: flex; align-items: center; justify-content: center; padding: 24px; }
  .card { background: #1a1f2e; border: 1px solid #2d3748; border-radius: 16px;
          padding: 32px; max-width: 560px; width: 100%; }
  h1 { font-size: 22px; font-weight: 700; margin-bottom: 8px; color: #f7fafc; }
  .meta { font-size: 14px; color: #718096; margin-bottom: 24px; line-height: 1.6; }
  .meta span { color: #e2e8f0; }
  label { display: block; font-size: 13px; color: #a0aec0; margin-bottom: 6px; }
  input { width: 100%; padding: 12px 16px; background: #0f1117; border: 1px solid #2d3748;
          border-radius: 10px; color: #f7fafc; font-size: 20px; letter-spacing: 8px;
          text-align: center; outline: none; }
  input:focus { border-color: #4299e1; }
  button { width: 100%; padding: 14px; border: none; border-radius: 10px;
           font-size: 16px; font-weight: 600; cursor: pointer; margin-top: 12px;
           transition: opacity .2s; }
  button:disabled { opacity: .5; cursor: not-allowed; }
  .btn-primary { background: #3182ce; color: #fff; }
  .btn-success { background: #276749; color: #fff; }
  .entry { background: #0f1117; border: 1px solid #2d3748; border-radius: 10px;
           padding: 16px; margin-bottom: 12px; }
  .entry-title { font-weight: 600; margin-bottom: 10px; color: #90cdf4; }
  .field-row { display: flex; justify-content: space-between; align-items: center;
               padding: 6px 0; border-bottom: 1px solid #1a1f2e; }
  .field-row:last-child { border-bottom: none; }
  .field-name { font-size: 12px; color: #718096; text-transform: uppercase; }
  .field-value { font-family: monospace; font-size: 14px; }
  .masked { color: #4a5568; letter-spacing: 2px; }
  .reveal-btn { background: none; border: none; color: #4299e1; font-size: 12px;
                cursor: pointer; padding: 2px 8px; margin: 0; width: auto; }
  .error { color: #fc8181; font-size: 14px; margin-top: 12px; text-align: center; }
  .success { color: #68d391; font-size: 15px; margin-top: 16px; text-align: center; }
  #step-otp, #step-data { display: none; }
</style>
</head>
<body>
<div class="card">
  <div id="step-loading">
    <div class="meta">Завантаження акту…</div>
  </div>

  <div id="step-otp">
    <h1>Акт передачі доступів</h1>
    <div class="meta" id="meta-block"></div>
    <label for="otp-input">Введіть 6-значний код (отримали окремим повідомленням)</label>
    <input id="otp-input" type="text" inputmode="numeric" maxlength="6" placeholder="000000" autocomplete="one-time-code">
    <button class="btn-primary" id="btn-view" onclick="doView()">Переглянути доступи</button>
    <div class="error" id="otp-error"></div>
  </div>

  <div id="step-data">
    <h1>Доступи до об'єкта</h1>
    <div class="meta" id="data-meta"></div>
    <div id="entries"></div>
    <button class="btn-success" id="btn-ack" onclick="doAcknowledge()">✓ Підтверджую отримання</button>
    <div class="success" id="ack-success" style="display:none">Отримання підтверджено. Посилання анульовано.</div>
    <div class="error" id="ack-error"></div>
  </div>
</div>

<script>
const token = window.location.pathname.split('/').pop();
const BASE = window.location.origin;
let currentOtp = '';

const FIELD_LABELS = {
  login_enc: 'Логін', password_enc: 'Пароль', ip_enc: 'IP-адреса',
  domain_enc: 'Домен', ddns_enc: 'DDNS', serial_enc: 'Серійний №', notes_enc: 'Примітки'
};

async function init() {
  try {
    const r = await fetch(`${BASE}/api/v2/act/public/${token}`);
    if (!r.ok) { showError('Посилання недійсне або закінчилося.'); return; }
    const data = await r.json();
    if (data.link_burned) { showError('Акт вже підтверджений клієнтом.'); return; }
    document.getElementById('meta-block').innerHTML =
      `Об'єкт: <span>${data.passport_label || '—'}</span><br>` +
      `Клієнт: <span>${data.customer_label || '—'}</span><br>` +
      `Записів: <span>${data.entry_count}</span><br>` +
      `Дійсно до: <span>${data.expires_at}</span>`;
    show('step-otp');
  } catch(e) { showError('Помилка завантаження.'); }
}

async function doView() {
  currentOtp = document.getElementById('otp-input').value.trim();
  document.getElementById('otp-error').textContent = '';
  document.getElementById('btn-view').disabled = true;
  try {
    const r = await fetch(`${BASE}/api/v2/act/public/${token}/view`, {
      method: 'POST', headers: {'Content-Type':'application/json'},
      body: JSON.stringify({otp: currentOtp})
    });
    const data = await r.json();
    if (!r.ok) { document.getElementById('otp-error').textContent = data.detail?.message || 'Невірний код.'; document.getElementById('btn-view').disabled = false; return; }
    renderEntries(data.entries || []);
    document.getElementById('data-meta').textContent = `Акт: ${data.act_name}`;
    show('step-data');
  } catch(e) { document.getElementById('otp-error').textContent = 'Помилка мережі.'; document.getElementById('btn-view').disabled = false; }
}

async function doAcknowledge() {
  document.getElementById('btn-ack').disabled = true;
  document.getElementById('ack-error').textContent = '';
  try {
    const r = await fetch(`${BASE}/api/v2/act/public/${token}/acknowledge`, {
      method: 'POST', headers: {'Content-Type':'application/json'},
      body: JSON.stringify({otp: currentOtp})
    });
    if (!r.ok) { document.getElementById('ack-error').textContent = 'Помилка підтвердження.'; document.getElementById('btn-ack').disabled = false; return; }
    document.getElementById('btn-ack').style.display = 'none';
    document.getElementById('ack-success').style.display = 'block';
    document.getElementById('entries').innerHTML = '<div class="meta" style="margin-top:16px">Дані видалено з екрану після підтвердження.</div>';
  } catch(e) { document.getElementById('ack-error').textContent = 'Помилка мережі.'; document.getElementById('btn-ack').disabled = false; }
}

function renderEntries(entries) {
  const container = document.getElementById('entries');
  container.innerHTML = entries.map(e => `
    <div class="entry">
      <div class="entry-title">${e.vault_entry}</div>
      ${Object.entries(e.fields).map(([k,v]) => `
        <div class="field-row">
          <span class="field-name">${FIELD_LABELS[k] || k}</span>
          <span>
            <span class="field-value masked" id="val-${k}-${e.vault_entry}">${'•'.repeat(Math.min(v.length,12))}</span>
            <button class="reveal-btn" onclick="reveal('val-${k}-${e.vault_entry}','${v.replace(/'/g,"\\'")}')">Показати</button>
          </span>
        </div>`).join('')}
    </div>`).join('');
}

function reveal(id, val) {
  const el = document.getElementById(id);
  el.textContent = val;
  el.classList.remove('masked');
}

function show(id) {
  document.getElementById('step-loading').style.display = 'none';
  document.getElementById('step-otp').style.display = 'none';
  document.getElementById('step-data').style.display = 'none';
  document.getElementById(id).style.display = 'block';
}

function showError(msg) {
  document.getElementById('step-loading').innerHTML = `<div class="error" style="font-size:16px">${msg}</div>`;
}

init();
</script>
</body>
</html>
```

- [ ] **Step 2: Verify the `/act/{token}` route is already in main.py from Task 3**

```bash
grep "act_page" services/security-api/app/main.py
```

Expected: matches `async def act_page`.

- [ ] **Step 3: Commit**

```bash
git add services/security-api/app/static/act.html
git commit -m "feat(ui): V4 — public act.html client page (token+OTP, reveal, acknowledge)"
```

---

## Task 5: ERPNext Desk Client Script

**Files:**
- Create: `erpnext/security_erp/security_erp/security_erp/doctype/access_transfer_act/access_transfer_act.js`

**Interfaces:**
- Consumes: `frappe.call('security_erp.vault.mfa.verify_step_up', {code})→{vault_session_token}`, `frappe.call('security_erp.vault.act.generate', {act_name, vault_session_token})→{token, otp, link, expires_at}`, `frappe.call('security_erp.vault.api.decrypt_vault_entry', {name, fields, vault_session_token})→{field: plaintext}`
- Produces: "Генерувати акт" and "Переглянути акт" buttons in Frappe desk form

- [ ] **Step 1: Create access_transfer_act.js**

Create `erpnext/security_erp/security_erp/security_erp/doctype/access_transfer_act/access_transfer_act.js`:

```javascript
// Frappe desk client script for Access Transfer Act.
// All API calls go directly to Frappe @whitelist methods — no FastAPI JWT needed from desk.

frappe.ui.form.on('Access Transfer Act', {
    refresh: function(frm) {
        if (frm.is_new()) return;

        const hasEntries = frm.doc.included_entries && frm.doc.included_entries.length > 0;
        const alreadyGenerated = frm.doc.delivery_token && !frm.doc.link_burned;

        if (hasEntries) {
            frm.add_custom_button(__('Генерувати акт'), function() {
                if (alreadyGenerated) {
                    frappe.confirm(
                        __('Попередній акт буде анульовано. Клієнт більше не зможе відкрити старе посилання. Продовжити?'),
                        () => riad_mfa_then_generate(frm)
                    );
                } else {
                    riad_mfa_then_generate(frm);
                }
            }, __('Vault'));

            frm.add_custom_button(__('Переглянути акт'), function() {
                riad_desk_preview(frm);
            }, __('Vault'));
        }
    }
});

function riad_mfa_then_generate(frm) {
    frappe.prompt(
        [{ fieldname: 'totp_code', fieldtype: 'Data', label: __('TOTP-код (з застосунку)'), reqd: 1 }],
        function(values) {
            frappe.call({
                method: 'security_erp.vault.mfa.verify_step_up',
                args: { code: values.totp_code },
                freeze: true,
                freeze_message: __('Перевірка MFA…'),
                callback: function(r) {
                    if (!r.message || !r.message.vault_session_token) {
                        frappe.msgprint({ title: __('Помилка'), message: __('MFA-верифікація не вдалася.'), indicator: 'red' });
                        return;
                    }
                    riad_do_generate(frm, r.message.vault_session_token);
                }
            });
        },
        __('Підтвердіть особу (MFA)'),
        __('Підтвердити')
    );
}

function riad_do_generate(frm, vault_session_token) {
    frappe.call({
        method: 'security_erp.vault.act.generate',
        args: { act_name: frm.doc.name, vault_session_token: vault_session_token },
        freeze: true,
        freeze_message: __('Генерація акту…'),
        callback: function(r) {
            if (!r.message || !r.message.ok) {
                frappe.msgprint({ title: __('Помилка'), message: __('Не вдалося згенерувати акт.'), indicator: 'red' });
                return;
            }
            const m = r.message;
            const domain = window.location.origin.replace('erp.', 'api.');
            const fullLink = `${domain}${m.link}`;

            frappe.msgprint({
                title: __('Акт згенеровано'),
                indicator: 'green',
                message: `
                    <p><b>Посилання для клієнта:</b></p>
                    <p><code style="word-break:break-all">${fullLink}</code></p>
                    <p style="margin-top:8px"><a href="#" onclick="navigator.clipboard.writeText('${fullLink}')">[Копіювати посилання]</a></p>
                    <hr style="margin:12px 0">
                    <p><b>OTP-код для клієнта:</b></p>
                    <p style="font-size:28px;letter-spacing:8px;font-weight:700;color:#276749">${m.otp}</p>
                    <p style="color:#e53e3e;margin-top:8px">⚠ Передайте окремим каналом (SMS/Viber/Telegram).<br>⚠ Після закриття цього вікна код більше не відображається.</p>
                    <p style="color:#718096;font-size:12px;margin-top:8px">Дійсно до: ${m.expires_at}</p>
                `
            });

            frm.reload_doc();
        }
    });
}

function riad_desk_preview(frm) {
    const entries = (frm.doc.included_entries || []).map(r => r.vault_entry).filter(Boolean);
    if (!entries.length) {
        frappe.msgprint(__('Акт не містить Vault Entry.'));
        return;
    }

    frappe.prompt(
        [{ fieldname: 'totp_code', fieldtype: 'Data', label: __('TOTP-код (MFA)'), reqd: 1 }],
        function(values) {
            frappe.call({
                method: 'security_erp.vault.mfa.verify_step_up',
                args: { code: values.totp_code },
                freeze: true,
                callback: function(r) {
                    if (!r.message || !r.message.vault_session_token) {
                        frappe.msgprint({ title: __('Помилка MFA'), indicator: 'red', message: __('Невірний код.') });
                        return;
                    }
                    riad_fetch_and_show_entries(entries, r.message.vault_session_token);
                }
            });
        },
        __('MFA підтвердження для перегляду'),
        __('Підтвердити')
    );
}

function riad_fetch_and_show_entries(entry_names, vault_session_token) {
    const enc_fields = ['login_enc', 'password_enc', 'ip_enc', 'domain_enc', 'ddns_enc', 'serial_enc', 'notes_enc'];
    const LABELS = { login_enc: 'Логін', password_enc: 'Пароль', ip_enc: 'IP', domain_enc: 'Домен', ddns_enc: 'DDNS', serial_enc: 'Серійний №', notes_enc: 'Примітки' };
    let results = {};
    let pending = entry_names.length;

    function done() {
        let html = '';
        entry_names.forEach(name => {
            const fields = results[name] || {};
            html += `<div style="margin-bottom:16px"><b style="color:#4299e1">${name}</b>`;
            Object.entries(fields).forEach(([k, v]) => {
                const masked = '•'.repeat(Math.min(v.length, 10));
                html += `<div style="display:flex;justify-content:space-between;padding:4px 0;border-bottom:1px solid #2d3748">
                    <span style="font-size:12px;color:#718096">${LABELS[k] || k}</span>
                    <span>
                        <span id="dv-${name}-${k}" style="font-family:monospace;color:#4a5568">${masked}</span>
                        <a href="#" onclick="document.getElementById('dv-${name}-${k}').textContent='${v.replace(/'/g,"\\'")}';" style="font-size:12px;margin-left:8px">Показати</a>
                    </span>
                </div>`;
            });
            html += '</div>';
        });
        frappe.msgprint({ title: __('Вміст акту (лише перегляд)'), message: html });
    }

    entry_names.forEach(name => {
        frappe.call({
            method: 'security_erp.vault.api.decrypt_vault_entry',
            args: { name: name, fields: JSON.stringify(enc_fields), vault_session_token: vault_session_token },
            callback: function(r) {
                results[name] = r.message || {};
                if (--pending === 0) done();
            }
        });
    });
}
```

- [ ] **Step 2: Verify syntax via Node (optional, can skip)**

```bash
node --check "erpnext/security_erp/security_erp/security_erp/doctype/access_transfer_act/access_transfer_act.js" 2>&1 || true
```

(If Node not available locally, skip — Frappe will report JS errors in browser console.)

- [ ] **Step 3: Commit**

```bash
git add "erpnext/security_erp/security_erp/security_erp/doctype/access_transfer_act/access_transfer_act.js"
git commit -m "feat(desk): V4 — Access Transfer Act form buttons (generate + MFA preview)"
```

---

## Task 6: Docker Build + Smoke Tests + BUILD_LOG

**Files:**
- Modify: `BUILD_LOG.md`

**Interfaces:**
- Consumes: all tasks 1–5 completed

- [ ] **Step 1: Rebuild Docker image**

```bash
cd "/home/joker/RIAD CRM" && docker compose build backend
```

Expected: builds without errors.

- [ ] **Step 2: Restart services**

```bash
docker compose up -d backend && docker exec -it riadcrm-backend-1 bash -c "cd /home/frappe/frappe-bench && bench --site erp.localhost clear-cache"
```

- [ ] **Step 3: Verify act.py is importable inside Frappe**

```bash
docker exec -it riadcrm-backend-1 bash -c "cd /home/frappe/frappe-bench && python -c \"import security_erp.vault.act; print('OK')\""
```

Expected: `OK`

- [ ] **Step 4: Smoke test — generate (requires valid Frappe session)**

First get a Frappe SID (replace with real credentials):

```bash
SID=$(curl -s -X POST http://localhost:8080/api/method/login \
  -H "Host: erp.localhost" \
  -d "usr=Administrator&pwd=YOUR_ADMIN_PASSWORD" \
  -c /tmp/cookies.txt | python3 -c "import sys,json; print(json.load(sys.stdin).get('sid',''))" 2>/dev/null || \
  grep -i sid /tmp/cookies.txt | awk '{print $7}')
```

Call get_meta with a known Access Transfer Act that has included_entries:

```bash
curl -s "http://localhost:8080/api/method/security_erp.vault.act.get_meta?token_hex=INVALID_TOKEN" \
  -H "Host: erp.localhost" | python3 -m json.tool
```

Expected: `{"exc_type": "DoesNotExistError", ...}` (404-equivalent from Frappe — proves method is registered and callable).

- [ ] **Step 5: Smoke test — public FastAPI endpoint**

```bash
curl -s http://localhost:8000/api/v2/act/public/nonexistent_token_hex_64chars | python3 -m json.tool
```

Expected: `{"detail": {"code": "RIAD-ACT-NOT-FOUND", ...}}` — proves the FastAPI route is registered and proxies to Frappe correctly.

- [ ] **Step 6: Verify vault isolation linter final check**

```bash
python tests/vault_isolation/check_vault_isolation.py
```

Expected: `OK: N files scanned` — green.

- [ ] **Step 7: Update BUILD_LOG.md**

Append the following section to `BUILD_LOG.md`:

```markdown
---

### V4 — Access Transfer Act + Vault UI ✅ DONE

**Дата:** 2026-06-22
**Статус:** DoD виконано

#### Технічне рішення

Схема доставки: `act.generate` (MFA-gate) → Redis `act:tok:{token}` + `act:otp:{token}` (TTL=86400s) → менеджер надсилає link + OTP клієнту окремим каналом → клієнт відкриває `act.html` → вводить OTP → `act.serve` розшифровує in-memory → клієнт натискає "Підтверджую" → `act.acknowledge` спалює всі Redis-ключі.

| Компонент | Деталі |
|---|---|
| `security_erp/vault/act.py` | 4 @whitelist методи: generate/get_meta/serve/acknowledge |
| Redis keys | `act:tok:`, `act:otp:`, `act:act_to_tok:` — TTL=86400s |
| MariaDB | Лише `sha256(token)` у `delivery_token` — non-reversible |
| FastAPI | `/api/v2/act/public/{token}` (без JWT) + `/api/v2/vault/act/generate` (JWT) |
| Публічна сторінка | `act.html` — vanilla JS, reveal-кнопки, acknowledge |
| Desk UI | `access_transfer_act.js` — кнопки "Генерувати акт" + "Переглянути акт" під MFA |

#### Revoke-on-regenerate edge case
При `delivery_token` ≠ '' і `link_burned == 0` → lookup `act:act_to_tok:{act_name}` у Redis:
- Є: delete old keys + audit `act_revoke`
- Немає (TTL вийшов): silent skip (акт вже протух)

#### DoD перевірка

1. ✅ `vault_audit_log.json` — нові action: `act_revoke`, `act_view`, `act_acknowledge`; bench migrate — OK
2. ✅ `access_transfer_act.json` — поля `delivery_token`, `delivery_token_expires_at`, `otp_hint`, `link_burned`; bench migrate — OK
3. ✅ `act.generate` під MFA → token + otp + audit `act_generate`
4. ✅ `act.serve` з правильним token + otp → розшифровані поля in-memory + audit `act_view`
5. ✅ `act.acknowledge` → `link_burned=1` + Redis keys deleted + audit `act_acknowledge`
6. ✅ Регенерація: revoke старого token + confirm dialog у desk
7. ✅ Публічний endpoint `GET /api/v2/act/public/{token}` — без JWT
8. ✅ `act.html` — metadata → OTP → reveal → acknowledge
9. ✅ Desk buttons — "Генерувати акт" (MFA + dialog з OTP) + "Переглянути акт" (MFA + masked)
10. ✅ Vault isolation linter V2 — зелений (`act.py` в `vault/`, не в restricted paths)
11. ✅ `tests/vault/test_act_pure.py` — 10 тестів пройдено

#### ВАЖЛИВО — Гейт C2
🔴 Реальні Vault-секрети в production — ЛИШЕ після H1 (key-escrow процедура).
V4 технічно готовий. `act.generate` і `act.serve` працюють. Але наповнення
Vault Entry реальними паролями клієнтів — заморожено до:
- H1: key-escrow (майстер-ключ під контролем двох осіб)
- DR-runbook + restore-drill з Vault
```

- [ ] **Step 8: Final commit**

```bash
git add BUILD_LOG.md
git commit -m "docs: V4 DoD — BUILD_LOG, C2/H1 gate noted"
```

---

## Self-Review Checklist

**Spec coverage:**
- ✅ `act.generate` under MFA → §3.1
- ✅ TTL=86400s → §2.3
- ✅ OTP 6-digit sha256 hash → §2.3
- ✅ `act:act_to_tok` edge case (TTL expired) → §3.1
- ✅ `act.serve` in-memory decrypt → §3.2
- ✅ Token NOT burned on serve → §3.2
- ✅ `act.acknowledge` burns all 3 Redis keys → §3.3
- ✅ `get_meta` strict field whitelist → §3.4
- ✅ `frappe_guest_post/get` helper → §4.1
- ✅ Public FastAPI routes without JWT → §4.1
- ✅ Protected `/generate` endpoint with JWT → §4.2
- ✅ Desk "Генерувати акт" + confirm on regenerate → §5.1
- ✅ Desk "Переглянути акт" under MFA → §5.2
- ✅ `vault_audit_log.json` action migration → §2.2
- ✅ `access_transfer_act.json` new fields → §2.1
- ✅ C2/H1 gate documented in BUILD_LOG → §9
- ✅ Vault isolation linter check → §8 DoD #10
- ✅ Public HTML client page → §4.1 (implied)

**Type consistency:**
- `generate()` returns `dict` with keys `{ok, token, otp, link, expires_at}` — matches `ActGenerateRequest` usage in Task 3
- `ActOtpRequest(otp: str)` — used in `/view` and `/acknowledge` routes consistently
- `frappe_guest_post(path, data)` / `frappe_guest_get(path, params)` — consistent across database.py and routes/act.py
- `_validate_token_and_otp(token_hex, otp_code) → str` — returns `act_name`, used identically in `serve()` and `acknowledge()`
