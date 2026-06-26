#!/usr/bin/env bash
set -euo pipefail
echo "=== Vault Restore Drill ==="
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

KEY_PATH="${VAULT_MASTER_KEY_PATH:-configs/vault_master_key}"
if [ ! -f "$KEY_PATH" ]; then
    echo "FAIL: Key file not found at $KEY_PATH"
    exit 1
fi
KEY_HEX=$(cat "$KEY_PATH" | tr -d '\n')
KEY_LEN=$(echo -n "$KEY_HEX" | wc -c)
echo "Step 1: Key file found, length=$KEY_LEN hex chars ($(($KEY_LEN / 2)) bytes)"
if [ "$KEY_LEN" -ne 64 ]; then
    echo "FAIL: Key must be 64 hex chars (32 bytes), got $KEY_LEN"
    exit 1
fi

python3 -c "
import os
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
key = bytes.fromhex('$KEY_HEX')
nonce = os.urandom(12)
aesgcm = AESGCM(key)
ct = aesgcm.encrypt(nonce, b'drill_test', None)
pt = aesgcm.decrypt(nonce, ct, None)
assert pt == b'drill_test', 'Roundtrip failed'
print('Step 2: Crypto roundtrip OK')
"

python3 -m pytest tests/e9/test_e9_vault_restore.py -v --tb=short 2>&1 | tail -5
echo "Step 3: Vault restore drill PASSED"
echo "=== Drill Complete ==="
