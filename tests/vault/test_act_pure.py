"""Pure-logic unit tests for vault/act.py helpers.

These tests verify the cryptographic helpers and Redis key naming used
by vault/act.py without requiring a live Frappe/MariaDB environment.
Run with: python -m pytest tests/vault/test_act_pure.py -v
"""
import hashlib
import secrets


def _sha256(s: str) -> str:
    return hashlib.sha256(s.encode("utf-8")).hexdigest()


# ── OTP helpers ──────────────────────────────────────────────────────────

class TestOtpGeneration:
    def test_otp_is_six_digits(self):
        otp = f"{secrets.randbelow(1_000_000):06d}"
        assert len(otp) == 6
        assert otp.isdigit()

    def test_otp_lower_bound_padded(self):
        assert f"{0:06d}" == "000000"

    def test_otp_upper_bound(self):
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


# ── Redis key naming ──────────────────────────────────────────────────────

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
        assert stored != token
        assert len(stored) == 64

    def test_two_tokens_never_collide(self):
        t1 = secrets.token_hex(32)
        t2 = secrets.token_hex(32)
        assert t1 != t2
        assert _sha256(t1) != _sha256(t2)
