"""vault/_hooks.py — Frappe DocType hooks for transparent field encryption.

before_save  → encrypt_doc_fields  (encrypts plaintext *_enc fields)
after_fetch  → decrypt_doc_fields  (decrypts for in-memory use; not persisted)

Only VaultEntry uses these hooks. The *_enc fields in the DB always store
cipher-text; plaintext never reaches the database.
"""

from ._crypto import _is_encrypted, decrypt, encrypt
from ._key import _load_key

# All field names that must be encrypted at rest in VaultEntry
ENC_FIELDS = [
    "login_enc",
    "password_enc",
    "ip_enc",
    "domain_enc",
    "ddns_enc",
    "serial_enc",
    "notes_enc",
]

# VaultAccessEnrollment has one encrypted field
ENROLLMENT_ENC_FIELDS = [
    "totp_secret_enc",
]


def _encrypt_fields(doc, fields: list[str], key: bytes) -> None:
    """Encrypt any plaintext values in the given field list on doc."""
    for field in fields:
        value = doc.get(field)
        if not value:
            continue
        if _is_encrypted(value):
            # Already encrypted — leave as-is
            continue
        encrypted = encrypt(value, key)
        doc.set(field, encrypted)


def _decrypt_fields(doc, fields: list[str], key: bytes) -> None:
    """Decrypt encrypted values into in-memory doc fields (not saved back to DB)."""
    for field in fields:
        value = doc.get(field)
        if not value or not _is_encrypted(value):
            continue
        try:
            doc.set(field, decrypt(value, key))
        except Exception:
            # Decryption failure: leave encrypted value, do not crash the fetch
            pass


def encrypt_doc_fields(doc, method=None) -> None:
    """before_save hook — encrypt *_enc fields before writing to DB."""
    key = _load_key()
    doctype = getattr(doc, "doctype", None)
    if doctype == "Vault Entry":
        _encrypt_fields(doc, ENC_FIELDS, key)
    elif doctype == "Vault Access Enrollment":
        _encrypt_fields(doc, ENROLLMENT_ENC_FIELDS, key)
    else:
        # Generic: encrypt all fields whose name ends with _enc
        generic = [f for f in (doc.meta.get_field_names() if hasattr(doc, "meta") else []) if f.endswith("_enc")]
        if generic:
            _encrypt_fields(doc, generic, key)


def decrypt_doc_fields(doc, method=None) -> None:
    """after_fetch hook — decrypt *_enc fields into memory for use in Python/UI."""
    key = _load_key()
    doctype = getattr(doc, "doctype", None)
    if doctype == "Vault Entry":
        _decrypt_fields(doc, ENC_FIELDS, key)
    elif doctype == "Vault Access Enrollment":
        _decrypt_fields(doc, ENROLLMENT_ENC_FIELDS, key)
    else:
        generic = [f for f in (doc.meta.get_field_names() if hasattr(doc, "meta") else []) if f.endswith("_enc")]
        if generic:
            _decrypt_fields(doc, generic, key)
