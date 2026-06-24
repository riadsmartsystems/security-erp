"""vault/api.py — Frappe whitelisted Vault API endpoints.

All endpoints require:
1. Frappe authentication (frappe.session.user != Guest)
2. vault_session_token — active TOTP step-up session (300s TTL)
3. Frappe permission check on the Vault Entry DocType

Public API surface:
- vault_get(vault_entry_name, vault_session_token) → decrypted fields dict
- vault_set(passport, category, label, vault_session_token, **enc_kwargs) → name
- vault_list(vault_session_token, passport=None, customer=None) → list of entries
"""

import frappe

from ._crypto import _is_encrypted, decrypt, encrypt
from ._hooks import ENC_FIELDS
from ._key import _load_key
from .audit import append_audit_log
from .mfa import VaultMFAError, _check_mfa_session


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


def _require_vault_user() -> str:
    user = frappe.session.user
    if not user or user == "Guest":
        frappe.throw("Authentication required.", frappe.PermissionError)
    return user


@frappe.whitelist()
def vault_get(vault_entry_name: str, vault_session_token: str = "") -> dict:
    """Return decrypted fields for a single Vault Entry.

    Requires Vault step-up MFA session. Logs audit action=view.
    """
    user = _require_vault_user()
    try:
        _check_mfa_session(vault_session_token, user)
    except VaultMFAError as exc:
        frappe.throw(str(exc), frappe.PermissionError)

    frappe.has_permission("Vault Entry", ptype="read", doc=vault_entry_name, throw=True)

    ve = frappe.get_doc("Vault Entry", vault_entry_name)
    key = _load_key()

    result = {
        "name": ve.name,
        "label": ve.label,
        "category": ve.category,
        "passport": ve.passport,
        "customer": ve.customer,
        "serial_no": ve.serial_no,
    }
    for field in ENC_FIELDS:
        raw = ve.get(field)
        if raw and _is_encrypted(raw):
            try:
                result[field] = decrypt(raw, key)
            except Exception:
                result[field] = None
        else:
            result[field] = raw or None

    append_audit_log(
        "view",
        vault_entry=ve.name,
        field_touched="",
        user=user,
        session_id=_current_sid(),
        ip=_current_ip(),
        passport=ve.passport or "",
    )

    return result


@frappe.whitelist()
def vault_set(
    passport: str,
    category: str,
    label: str,
    vault_session_token: str = "",
    vault_entry_name: str = "",
    login: str = "",
    password: str = "",
    ip: str = "",
    domain: str = "",
    ddns: str = "",
    serial: str = "",
    notes: str = "",
    serial_no: str = "",
    customer: str = "",
) -> dict:
    """Create or update a Vault Entry with encrypted fields.

    Plaintext values are passed in, encrypted before saving.
    vault_entry_name: if provided, update existing; else create new.
    """
    req_user = _require_vault_user()
    try:
        _check_mfa_session(vault_session_token, req_user)
    except VaultMFAError as exc:
        frappe.throw(str(exc), frappe.PermissionError)

    key = _load_key()

    def _enc(val: str) -> str | None:
        return encrypt(val, key) if val else None

    plain_map = {
        "login_enc": login,
        "password_enc": password,
        "ip_enc": ip,
        "domain_enc": domain,
        "ddns_enc": ddns,
        "serial_enc": serial,
        "notes_enc": notes,
    }

    if vault_entry_name:
        frappe.has_permission("Vault Entry", ptype="write", doc=vault_entry_name, throw=True)
        ve = frappe.get_doc("Vault Entry", vault_entry_name)
        action = "update"
        touched = []
        for field, plaintext in plain_map.items():
            if plaintext is not None and plaintext != "":
                ve.set(field, _enc(plaintext))
                touched.append(field)
        ve.label = label or ve.label
        ve.category = category or ve.category
        # Skip before_save hook re-encryption: fields already encrypted
        ve.flags.ignore_before_save = True
        ve.save(ignore_permissions=True)
    else:
        frappe.has_permission("Vault Entry", ptype="create", throw=True)
        doc_data = {
            "doctype": "Vault Entry",
            "passport": passport,
            "customer": customer,
            "category": category,
            "label": label,
            "serial_no": serial_no,
        }
        for field, plaintext in plain_map.items():
            doc_data[field] = _enc(plaintext)
        ve = frappe.get_doc(doc_data)
        ve.flags.ignore_before_save = True
        ve.insert(ignore_permissions=True)
        action = "create"
        touched = [f for f in plain_map if plain_map[f]]

    frappe.db.commit()

    append_audit_log(
        action,
        vault_entry=ve.name,
        field_touched=",".join(touched) if action == "update" else "all",
        user=req_user,
        session_id=_current_sid(),
        ip=_current_ip(),
        passport=ve.passport or "",
    )

    return {"ok": True, "name": ve.name}


@frappe.whitelist()
def vault_list(
    vault_session_token: str = "",
    passport: str = "",
    customer: str = "",
) -> dict:
    """List Vault Entries (metadata only — no decryption) for given passport or customer.

    Requires step-up MFA session. Returns label, category, passport, customer — no *_enc fields.
    """
    user = _require_vault_user()
    try:
        _check_mfa_session(vault_session_token, user)
    except VaultMFAError as exc:
        frappe.throw(str(exc), frappe.PermissionError)

    filters = {}
    if passport:
        filters["passport"] = passport
    if customer:
        filters["customer"] = customer

    entries = frappe.get_all(
        "Vault Entry",
        filters=filters,
        fields=["name", "label", "category", "passport", "customer", "serial_no"],
        order_by="modified desc",
        limit=200,
    )

    return {"ok": True, "entries": entries, "count": len(entries)}
