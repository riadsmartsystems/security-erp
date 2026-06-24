"""vault/_key.py — Master key loading. No DB access, no AI context.

Priority: env VAULT_MASTER_KEY (hex) → file VAULT_MASTER_KEY_FILE path.
Key must be exactly 32 bytes (256 bits) for AES-256-GCM.
"""

import base64
import binascii
import os
from pathlib import Path


class VaultKeyError(Exception):
    pass


def _parse_key_bytes(raw: str) -> bytes:
    """Accept hex (64 chars) or base64 (44 chars with = padding) key strings."""
    raw = raw.strip()
    # Try hex first (64 hex chars = 32 bytes)
    if len(raw) == 64:
        try:
            key = binascii.unhexlify(raw)
            if len(key) == 32:
                return key
        except binascii.Error:
            pass
    # Try base64
    try:
        key = base64.b64decode(raw)
        if len(key) == 32:
            return key
    except Exception:
        pass
    raise VaultKeyError(
        f"VAULT_MASTER_KEY must be 32 bytes encoded as hex (64 chars) or base64. Got {len(raw)} chars."
    )


def get_master_key() -> bytes:
    """Load master key from env or file. Raises VaultKeyError if unavailable."""
    env_val = os.environ.get("VAULT_MASTER_KEY", "").strip()
    if env_val:
        return _parse_key_bytes(env_val)

    key_file_path = os.environ.get("VAULT_MASTER_KEY_FILE", "").strip()
    if key_file_path:
        p = Path(key_file_path)
        if not p.exists():
            raise VaultKeyError(f"VAULT_MASTER_KEY_FILE path does not exist: {key_file_path}")
        raw = p.read_text(encoding="utf-8")
        return _parse_key_bytes(raw)

    # Fallback: check for a file at the project config path used in development
    default_path = Path(os.environ.get("FRAPPE_BENCH_PATH", "/home/frappe/frappe-bench")) / "configs" / "vault_master_key"
    if default_path.exists():
        raw = default_path.read_text(encoding="utf-8")
        return _parse_key_bytes(raw)

    raise VaultKeyError(
        "Vault master key not configured. Set VAULT_MASTER_KEY env var or VAULT_MASTER_KEY_FILE."
    )


# Internal alias used by act.py and other vault submodules
def _load_key() -> bytes:
    return get_master_key()
