"""vault/mfa.py — TOTP step-up MFA for Vault access.

Flow:
1. User calls vault_mfa_verify(code) → we look up their enrolled TOTP secret,
   verify the code, create a Redis vault-session with TTL=300s, return token.
2. Protected vault operations pass vault_session_token → _check_mfa_session().

Vault Audit Log records mfa_fail on bad code (no session on success — only
the subsequent vault operation logs to audit).
"""

import secrets
from datetime import timedelta

_SESSION_TTL = 300  # 5 minutes
_SESSION_PREFIX = "vault:sess:"


class VaultMFAError(Exception):
    """Raised when MFA verification fails or session is invalid."""


def _get_user_totp_secret(user: str) -> str:
    """Fetch and decrypt the TOTP secret for a user. Raises VaultMFAError if not enrolled."""
    import frappe
    from ._crypto import _is_encrypted, decrypt
    from ._key import _load_key

    enrollments = frappe.get_all(
        "Vault Access Enrollment",
        filters={"user": user, "is_active": 1},
        fields=["totp_secret_enc"],
        limit=1,
    )
    if not enrollments:
        raise VaultMFAError(f"User {user} is not enrolled in Vault MFA.")

    secret_enc = enrollments[0].get("totp_secret_enc", "")
    if not secret_enc:
        raise VaultMFAError(f"Vault enrollment for {user} has no TOTP secret.")

    if _is_encrypted(secret_enc):
        return decrypt(secret_enc, _load_key())
    return secret_enc


def verify_totp(user: str, code: str) -> bool:
    """Verify a TOTP code for user against their enrolled secret.

    Returns True if valid, False if invalid.
    Raises VaultMFAError if user is not enrolled.
    """
    import pyotp

    secret = _get_user_totp_secret(user)
    totp = pyotp.TOTP(secret)
    # valid_window=1 allows ±30s clock drift
    return totp.verify(code, valid_window=1)


def create_vault_session(user: str) -> str:
    """Create a Redis-backed Vault session after successful MFA. Returns opaque token."""
    import frappe

    token = secrets.token_hex(32)
    cache = frappe.cache()
    cache.set_value(f"{_SESSION_PREFIX}{token}", user, expires_in_sec=_SESSION_TTL)
    return token


def _check_mfa_session(vault_session_token: str, user: str) -> None:
    """Validate vault_session_token from Redis. Raises VaultMFAError if invalid/expired."""
    if not vault_session_token:
        raise VaultMFAError("Vault session token required for this operation.")

    import frappe

    stored_user = frappe.cache().get_value(f"{_SESSION_PREFIX}{vault_session_token}")
    if not stored_user:
        raise VaultMFAError("Vault session expired or invalid. Please re-authenticate with TOTP.")
    if stored_user != user:
        raise VaultMFAError("Vault session user mismatch.")


@property
def _frappe_whitelist():
    """Decorator applied inline to keep import order clean."""
    import frappe
    return frappe.whitelist


def vault_mfa_verify(code: str) -> dict:
    """Frappe whitelisted — verify TOTP and return a short-lived vault session token.

    Called from the ERPNext desk or API before any Vault write/export operation.
    """
    import frappe
    from .audit import append_audit_log

    user = frappe.session.user
    if not user or user == "Guest":
        frappe.throw("Authentication required.", frappe.PermissionError)

    try:
        valid = verify_totp(user, code)
    except VaultMFAError as exc:
        append_audit_log("mfa_fail", vault_entry="", field_touched="", user=user)
        frappe.throw(str(exc), frappe.PermissionError)

    if not valid:
        append_audit_log("mfa_fail", vault_entry="", field_touched="", user=user)
        frappe.throw("Invalid or expired TOTP code.", frappe.PermissionError)

    token = create_vault_session(user)
    return {"ok": True, "vault_session_token": token, "ttl": _SESSION_TTL}


# Apply @frappe.whitelist at module load time (after Frappe is available)
try:
    import frappe as _frappe
    vault_mfa_verify = _frappe.whitelist()(vault_mfa_verify)
except Exception:
    pass
