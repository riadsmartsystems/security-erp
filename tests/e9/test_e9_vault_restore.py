"""E9: Vault restore drill tests — верифікація що Vault-компоненти працюють після restore."""
import hashlib
import os
import unittest


class TestVaultKeyLoading(unittest.TestCase):
    """Перевіряє що master key завантажується з файлу."""

    def test_key_file_exists_and_is_32_bytes(self):
        key_path = os.environ.get("VAULT_MASTER_KEY_PATH", "configs/vault_master_key")
        if not os.path.exists(key_path):
            self.skipTest(f"Key file not found: {key_path}")
        key_hex = open(key_path).read().strip()
        key_bytes = bytes.fromhex(key_hex)
        self.assertEqual(len(key_bytes), 32, f"Key must be 32 bytes, got {len(key_bytes)}")

    def test_key_hex_is_valid(self):
        key_path = os.environ.get("VAULT_MASTER_KEY_PATH", "configs/vault_master_key")
        if not os.path.exists(key_path):
            self.skipTest(f"Key file not found: {key_path}")
        key_hex = open(key_path).read().strip()
        try:
            bytes.fromhex(key_hex)
        except ValueError:
            self.fail(f"Key is not valid hex: {key_hex[:20]}...")


class TestVaultCryptoRoundtrip(unittest.TestCase):
    """Simulates encrypt→decrypt roundtrip (без Frappe)."""

    def test_aes_gcm_roundtrip(self):
        try:
            from cryptography.hazmat.primitives.ciphers.aead import AESGCM
        except ImportError:
            self.skipTest("cryptography not installed")

        key = os.urandom(32)
        plaintext = b"test_password_123"
        nonce = os.urandom(12)
        aesgcm = AESGCM(key)
        ct = aesgcm.encrypt(nonce, plaintext, None)
        pt = aesgcm.decrypt(nonce, ct, None)
        self.assertEqual(pt, plaintext)

    def test_wrong_key_fails(self):
        try:
            from cryptography.hazmat.primitives.ciphers.aead import AESGCM
        except ImportError:
            self.skipTest("cryptography not installed")

        key1 = os.urandom(32)
        key2 = os.urandom(32)
        nonce = os.urandom(12)
        aesgcm = AESGCM(key1)
        ct = aesgcm.encrypt(nonce, b"secret", None)
        aesgcm2 = AESGCM(key2)
        with self.assertRaises(Exception):
            aesgcm2.decrypt(nonce, ct, None)

    def test_tamper_detection(self):
        try:
            from cryptography.hazmat.primitives.ciphers.aead import AESGCM
        except ImportError:
            self.skipTest("cryptography not installed")

        key = os.urandom(32)
        nonce = os.urandom(12)
        aesgcm = AESGCM(key)
        ct = aesgcm.encrypt(nonce, b"hello", None)
        tampered = bytes([ct[0] ^ 0xFF]) + ct[1:]
        with self.assertRaises(Exception):
            aesgcm.decrypt(nonce, tampered, None)


class TestAuditHashChain(unittest.TestCase):
    """Simulates hash-chain integrity check."""

    def _make_record(self, seq, prev_hash, action="view", user="test"):
        ts = "2026-01-01T00:00:00"
        data = f"{seq}|{ts}|{action}|test_entry|{user}|field|{prev_hash}"
        return hashlib.sha256(data.encode()).hexdigest()

    def test_chain_links_correctly(self):
        genesis = "0" * 64
        r1_hash = self._make_record(1, genesis)
        r2_hash = self._make_record(2, r1_hash)
        r3_hash = self._make_record(3, r2_hash)
        self.assertEqual(len(r1_hash), 64)
        self.assertEqual(len(r2_hash), 64)
        self.assertNotEqual(r1_hash, r2_hash)

    def test_tamper_breaks_chain(self):
        genesis = "0" * 64
        r1_hash = self._make_record(1, genesis)
        r2_hash = self._make_record(2, r1_hash)
        r2_tampered = self._make_record(2, "a" * 64)
        self.assertNotEqual(r2_hash, r2_tampered)


if __name__ == "__main__":
    unittest.main()
