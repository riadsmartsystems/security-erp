"""vault/audit.py — Append-only hash-chain audit log for Vault operations.

Design (DECISIONS.md Фаза 2):
- Global hash-chain: each record's prev_hash = previous record's record_hash.
- record_hash = sha256(prev_hash + action + user + timestamp + vault_entry + field_touched)
- DocType: Vault Audit Log (seq, log_timestamp, action, user, vault_entry, field_touched, prev_hash, record_hash)
- No update or delete of log records — only insert (append).
- The genesis record has prev_hash = "GENESIS".
"""

import hashlib
import json
from datetime import datetime, timezone
from typing import Any


_GENESIS = "GENESIS"
_AUDIT_DOCTYPE = "Vault Audit Log"


def _sha256(*parts: str) -> str:
    combined = "\x00".join(str(p) for p in parts)
    return hashlib.sha256(combined.encode("utf-8")).hexdigest()


def _get_last_hash() -> str:
    """Return the record_hash of the most recent audit log entry, or GENESIS."""
    try:
        import frappe
        last = frappe.get_all(
            _AUDIT_DOCTYPE,
            fields=["record_hash"],
            order_by="seq desc",
            limit=1,
        )
        if last and last[0].get("record_hash"):
            return last[0]["record_hash"]
    except Exception:
        pass
    return _GENESIS


def _build_record_hash(prev_hash: str, action: str, user: str, timestamp: str, vault_entry: str, field_touched: str) -> str:
    return _sha256(prev_hash, action, user, timestamp, vault_entry, field_touched)


def append_audit_log(
    action: str,
    vault_entry: str = "",
    field_touched: str = "",
    user: str = "",
    session_id: str = "",
    ip: str = "",
    passport: str = "",
) -> None:
    """Insert a new hash-chained record into Vault Audit Log.

    Called by vault.api, vault.act, and anywhere a Vault operation occurs.
    Silently skips if Frappe context is unavailable (e.g. unit tests).
    """
    try:
        import frappe
    except ImportError:
        return

    now = datetime.now(timezone.utc)
    timestamp_str = now.strftime("%Y-%m-%d %H:%M:%S")

    prev_hash = _get_last_hash()
    record_hash = _build_record_hash(prev_hash, action, user, timestamp_str, vault_entry, field_touched)

    try:
        doc = frappe.get_doc({
            "doctype": _AUDIT_DOCTYPE,
            "log_timestamp": timestamp_str,
            "action": action,
            "user": user or (frappe.session.user if hasattr(frappe, "session") else ""),
            "session_id": session_id,
            "ip": ip,
            "vault_entry": vault_entry or None,
            "passport": passport or None,
            "field_touched": field_touched,
            "prev_hash": prev_hash,
            "record_hash": record_hash,
        })
        doc.insert(ignore_permissions=True)
        frappe.db.commit()
    except Exception:
        pass


def log_action(
    action: str,
    doc_name: str,
    user: str,
    meta: dict[str, Any] | None = None,
) -> None:
    """Public API: log a vault action with optional metadata dict.

    Wraps append_audit_log for callers that don't need the full signature.
    """
    meta = meta or {}
    append_audit_log(
        action=action,
        vault_entry=doc_name,
        field_touched=meta.get("field_touched", ""),
        user=user,
        session_id=meta.get("session_id", ""),
        ip=meta.get("ip", ""),
        passport=meta.get("passport", ""),
    )


def verify_chain(limit: int = 1000) -> list[dict]:
    """Verify hash-chain integrity. Returns list of broken links (should be empty).

    Used for diagnostic / auditor tooling. Not called in the hot path.
    """
    import frappe

    records = frappe.get_all(
        _AUDIT_DOCTYPE,
        fields=["name", "seq", "action", "user", "log_timestamp", "vault_entry", "field_touched", "prev_hash", "record_hash"],
        order_by="seq asc",
        limit=limit,
    )

    broken = []
    prev_record_hash = _GENESIS

    for rec in records:
        expected_record_hash = _build_record_hash(
            rec.get("prev_hash", ""),
            rec.get("action", ""),
            rec.get("user", ""),
            str(rec.get("log_timestamp", "")),
            rec.get("vault_entry", "") or "",
            rec.get("field_touched", "") or "",
        )
        if rec.get("prev_hash") != prev_record_hash:
            broken.append({"name": rec["name"], "error": "prev_hash mismatch"})
        if rec.get("record_hash") != expected_record_hash:
            broken.append({"name": rec["name"], "error": "record_hash mismatch"})
        prev_record_hash = rec.get("record_hash", "")

    return broken
