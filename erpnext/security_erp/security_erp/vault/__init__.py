"""security_erp.vault — Password Vault crypto core.

Public surface (import these, not internal _* names):
- get_master_key()        → bytes
- encrypt(plaintext, key) → str
- decrypt(ciphertext, key)→ str
- encrypt_doc_fields(doc, method=None)
- decrypt_doc_fields(doc, method=None)
- log_action(action, doc_name, user, meta)
- verify_totp(user, code) → bool
- VaultMFAError

Internal (used by submodules, not external callers):
- _load_key, _is_encrypted, _decrypt_field, ENC_FIELDS, append_audit_log, _check_mfa_session
"""

from ._crypto import decrypt, encrypt
from ._hooks import decrypt_doc_fields, encrypt_doc_fields
from ._key import get_master_key
from .audit import log_action
from .mfa import VaultMFAError, verify_totp

__all__ = [
    "get_master_key",
    "encrypt",
    "decrypt",
    "encrypt_doc_fields",
    "decrypt_doc_fields",
    "log_action",
    "verify_totp",
    "VaultMFAError",
]
