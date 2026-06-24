"""vault/_crypto.py — AES-256-GCM field-level encryption.

Wire format: base64(nonce):base64(ciphertext):base64(tag)
- nonce: 12 bytes (96-bit, GCM standard)
- ciphertext: variable length
- tag: 16 bytes (128-bit GCM auth tag)

The cryptography.hazmat AESGCM returns ct+tag concatenated; we split on the
last 16 bytes as tag.
"""

import base64
import os

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

_NONCE_SIZE = 12  # bytes
_TAG_SIZE = 16    # bytes
_SENTINEL = "v1:"  # version prefix stored in DB value


def encrypt(plaintext: str, key: bytes) -> str:
    """Encrypt plaintext with AES-256-GCM. Returns versioned wire-format string."""
    if len(key) != 32:
        raise ValueError(f"Key must be 32 bytes, got {len(key)}")
    nonce = os.urandom(_NONCE_SIZE)
    aes = AESGCM(key)
    ct_tag = aes.encrypt(nonce, plaintext.encode("utf-8"), None)
    ct = ct_tag[:-_TAG_SIZE]
    tag = ct_tag[-_TAG_SIZE:]
    b64 = lambda b: base64.b64encode(b).decode("ascii")
    return _SENTINEL + b64(nonce) + ":" + b64(ct) + ":" + b64(tag)


def decrypt(ciphertext: str, key: bytes) -> str:
    """Decrypt a wire-format string. Raises ValueError on tamper/wrong key."""
    if len(key) != 32:
        raise ValueError(f"Key must be 32 bytes, got {len(key)}")
    if not ciphertext.startswith(_SENTINEL):
        raise ValueError("Ciphertext does not start with version prefix 'v1:'")
    body = ciphertext[len(_SENTINEL):]
    parts = body.split(":")
    if len(parts) != 3:
        raise ValueError(f"Expected 3 base64 parts, got {len(parts)}")
    try:
        nonce = base64.b64decode(parts[0])
        ct = base64.b64decode(parts[1])
        tag = base64.b64decode(parts[2])
    except Exception as e:
        raise ValueError(f"Invalid base64 in ciphertext: {e}") from e
    aes = AESGCM(key)
    plaintext_bytes = aes.decrypt(nonce, ct + tag, None)
    return plaintext_bytes.decode("utf-8")


def _is_encrypted(value: str) -> bool:
    """Return True if value looks like a Vault-encrypted string."""
    if not value or not isinstance(value, str):
        return False
    if not value.startswith(_SENTINEL):
        return False
    body = value[len(_SENTINEL):]
    return body.count(":") == 2


def _decrypt_field(value: str, key: bytes) -> str:
    """Decrypt a single field value. Returns empty string if not encrypted or empty."""
    if not value or not _is_encrypted(value):
        return ""
    try:
        return decrypt(value, key)
    except Exception:
        return ""
