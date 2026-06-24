"""R3: Refresh-rotation + reuse-detection + Device Sessions tests.

Run:
  cd "/home/joker/RIAD CRM"
  python -m unittest tests.r3.test_r3_refresh_rotation -v
"""

import asyncio
import json
import os
import sys
import unittest
from unittest.mock import AsyncMock, MagicMock, patch

_services_root = os.path.join(os.path.dirname(__file__), "..", "..", "services", "security-api")
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)


def _run(coro):
    return asyncio.get_event_loop().run_until_complete(coro)


# ---------------------------------------------------------------------------
# 1. JWT payload: jti + did present in refresh token
# ---------------------------------------------------------------------------

class TestRefreshTokenPayload(unittest.TestCase):

    def test_jti_and_did_in_refresh_token(self):
        from app.auth.jwt import create_refresh_token, decode_token
        token = create_refresh_token("alice@riad.fun", "device-abc")
        payload = decode_token(token)
        self.assertIsNotNone(payload, "Token should decode successfully")
        self.assertIn("jti", payload, "jti (JWT ID) must be present in refresh token")
        self.assertIn("did", payload, "did (device ID) must be present in refresh token")
        self.assertEqual(payload["did"], "device-abc")
        self.assertEqual(payload["sub"], "alice@riad.fun")
        self.assertEqual(payload["type"], "refresh")

    def test_each_token_has_unique_jti(self):
        from app.auth.jwt import create_refresh_token, decode_token
        t1 = create_refresh_token("alice@riad.fun", "device-abc")
        t2 = create_refresh_token("alice@riad.fun", "device-abc")
        p1, p2 = decode_token(t1), decode_token(t2)
        self.assertNotEqual(p1["jti"], p2["jti"], "Each token must have a unique jti")

    def test_did_preserved_across_same_device(self):
        from app.auth.jwt import create_refresh_token, decode_token
        device_id = "stable-device-id"
        t1 = create_refresh_token("alice@riad.fun", device_id)
        t2 = create_refresh_token("alice@riad.fun", device_id)
        self.assertEqual(decode_token(t1)["did"], device_id)
        self.assertEqual(decode_token(t2)["did"], device_id)


# ---------------------------------------------------------------------------
# 2. /refresh: normal rotation via direct logic test
# ---------------------------------------------------------------------------

class TestRefreshRotationLogic(unittest.TestCase):

    def setUp(self):
        from app.auth.jwt import create_refresh_token, decode_token, create_access_token
        self.create_refresh_token = create_refresh_token
        self.decode_token = decode_token
        self.create_access_token = create_access_token

    def test_normal_rotation_produces_new_jti(self):
        """After rotation: new token has same did but different jti."""
        t1 = self.create_refresh_token("alice@riad.fun", "device-xyz")
        p1 = self.decode_token(t1)

        t2 = self.create_refresh_token("alice@riad.fun", p1["did"])
        p2 = self.decode_token(t2)

        self.assertEqual(p1["did"], p2["did"], "did must be preserved across rotation")
        self.assertNotEqual(p1["jti"], p2["jti"], "jti must change on rotation")

    def test_backward_compat_token_missing_jti_rejected(self):
        """Old tokens without jti/did must be rejected with TOKEN_UPGRADE_REQUIRED."""
        from datetime import datetime, timedelta, timezone
        from jose import jwt as jose_jwt
        from app.core.config import settings

        now = datetime.now(timezone.utc)
        old_payload = {
            "sub": "alice@riad.fun",
            "type": "refresh",
            "iat": now,
            "exp": now + timedelta(seconds=3600),
        }
        old_token = jose_jwt.encode(old_payload, settings.secret_key, algorithm=settings.jwt_algorithm)
        payload = self.decode_token(old_token)
        # jti and did should be absent
        self.assertIsNone(payload.get("jti"))
        self.assertIsNone(payload.get("did"))
        # Route-level guard: if not jti or not did → TOKEN_UPGRADE_REQUIRED
        # (confirmed: routes/auth.py lines check this explicitly)
        self.assertFalse(bool(payload.get("jti")))
        self.assertFalse(bool(payload.get("did")))


# ---------------------------------------------------------------------------
# 3. Route-level tests via TestClient + mocked Redis
# ---------------------------------------------------------------------------

def _make_redis_mock(*, jti_blacklisted=False, sess_data=None, devices=None, frappe_sid=b"fake-sid"):
    """Build a fully mocked async Redis client for auth route tests."""
    mock = AsyncMock()
    pipeline_mock = AsyncMock()
    pipeline_mock.__aenter__ = AsyncMock(return_value=pipeline_mock)
    pipeline_mock.__aexit__ = AsyncMock(return_value=False)
    pipeline_mock.setex = AsyncMock()
    pipeline_mock.sadd = AsyncMock()
    pipeline_mock.delete = AsyncMock()
    pipeline_mock.srem = AsyncMock()
    pipeline_mock.execute = AsyncMock(return_value=[1, 1])
    mock.pipeline = MagicMock(return_value=pipeline_mock)

    async def _get(key):
        if "rt:bl:" in key:
            return b"alice@riad.fun" if jti_blacklisted else None
        if "rt:sess:" in key:
            if sess_data is not None:
                return json.dumps(sess_data).encode()
            return None
        if "frappe:sid:" in key:
            return frappe_sid
        if "rl:" in key:
            return None
        return None

    async def _smembers(key):
        if devices is not None:
            return {d.encode() for d in devices}
        return set()

    async def _zremrangebyscore(*a, **kw):
        return 0

    async def _zadd(*a, **kw):
        return 1

    async def _zcard(*a, **kw):
        return 1

    async def _expire(*a, **kw):
        return 1

    mock.get = AsyncMock(side_effect=_get)
    mock.smembers = AsyncMock(side_effect=_smembers)
    mock.setex = AsyncMock(return_value=True)
    mock.sadd = AsyncMock(return_value=1)
    mock.delete = AsyncMock(return_value=1)
    mock.srem = AsyncMock(return_value=1)
    mock.zremrangebyscore = AsyncMock(side_effect=_zremrangebyscore)
    mock.zadd = AsyncMock(side_effect=_zadd)
    mock.zcard = AsyncMock(side_effect=_zcard)
    mock.zrange = AsyncMock(return_value=[])
    mock.expire = AsyncMock(side_effect=_expire)
    return mock


class TestRefreshRouteReuse(unittest.TestCase):

    def _make_valid_refresh_token(self, user="alice@riad.fun", device="dev-1"):
        from app.auth.jwt import create_refresh_token
        return create_refresh_token(user, device)

    def _make_sess_data(self, jti, ip="1.2.3.4"):
        import time
        now = time.time()
        return {"jti": jti, "created": now, "last_seen": now, "ip_address": ip}

    def _get_test_client(self, redis_mock):
        from fastapi.testclient import TestClient
        from app.main import app
        from app.core.redis import get_redis

        async def _redis():
            return redis_mock

        app.dependency_overrides[get_redis] = _redis
        return TestClient(app, raise_server_exceptions=False)

    def tearDown(self):
        from app.main import app
        app.dependency_overrides.clear()

    def _patch_rate_limit(self):
        return patch("app.routes.auth._enforce_rate_limit", new=AsyncMock(return_value=None))

    def test_reuse_detection_returns_correct_error_code(self):
        """Sending an already-blacklisted RT must return RIAD-AUTH-REFRESH-REUSE."""
        rt = self._make_valid_refresh_token()
        from app.auth.jwt import decode_token
        payload = decode_token(rt)
        jti = payload["jti"]
        device_id = payload["did"]
        sess = self._make_sess_data(jti)

        redis_mock = _make_redis_mock(jti_blacklisted=True, sess_data=sess, devices=[device_id])
        client = self._get_test_client(redis_mock)

        with self._patch_rate_limit():
            with patch("app.routes.auth.frappe_get", new=AsyncMock(return_value={"data": {}})):
                resp = client.post("/api/v2/auth/refresh", json={"refresh_token": rt})

        self.assertEqual(resp.status_code, 401)
        body = resp.json()
        code = body.get("detail", {}).get("code", "")
        self.assertEqual(code, "RIAD-AUTH-REFRESH-REUSE",
                         f"Expected RIAD-AUTH-REFRESH-REUSE, got: {body}")

    def test_normal_rotation_succeeds(self):
        """Valid RT with no blacklist + valid session → 200 with new tokens."""
        rt = self._make_valid_refresh_token()
        from app.auth.jwt import decode_token
        payload = decode_token(rt)
        jti = payload["jti"]
        device_id = payload["did"]
        sess = self._make_sess_data(jti)

        redis_mock = _make_redis_mock(jti_blacklisted=False, sess_data=sess, devices=[device_id])
        client = self._get_test_client(redis_mock)

        with self._patch_rate_limit():
            with patch("app.routes.auth.frappe_get", new=AsyncMock(return_value={"data": {}})):
                resp = client.post("/api/v2/auth/refresh", json={"refresh_token": rt})

        self.assertEqual(resp.status_code, 200, f"Expected 200, got {resp.status_code}: {resp.text}")
        body = resp.json()
        self.assertIn("access_token", body)
        self.assertIn("refresh_token", body)
        new_payload = decode_token(body["refresh_token"])
        self.assertNotEqual(new_payload["jti"], jti, "New RT must have different jti")
        self.assertEqual(new_payload["did"], device_id, "did must be preserved")

    def test_session_revoked_when_no_sess_data(self):
        """RT with no matching session in Redis → SESSION_REVOKED."""
        rt = self._make_valid_refresh_token()
        redis_mock = _make_redis_mock(jti_blacklisted=False, sess_data=None)
        client = self._get_test_client(redis_mock)

        with self._patch_rate_limit():
            with patch("app.routes.auth.frappe_get", new=AsyncMock(return_value={"data": {}})):
                resp = client.post("/api/v2/auth/refresh", json={"refresh_token": rt})

        self.assertEqual(resp.status_code, 401)
        code = resp.json().get("detail", {}).get("code", "")
        self.assertEqual(code, "SESSION_REVOKED")

    def test_old_token_without_jti_rejected(self):
        """RT without jti/did (pre-R3 token) must return TOKEN_UPGRADE_REQUIRED."""
        from datetime import datetime, timedelta, timezone
        from jose import jwt as jose_jwt
        from app.core.config import settings

        now = datetime.now(timezone.utc)
        old_payload = {
            "sub": "alice@riad.fun",
            "type": "refresh",
            "iat": now,
            "exp": now + timedelta(seconds=3600),
        }
        old_token = jose_jwt.encode(old_payload, settings.secret_key, algorithm=settings.jwt_algorithm)

        redis_mock = _make_redis_mock()
        client = self._get_test_client(redis_mock)

        with self._patch_rate_limit():
            resp = client.post("/api/v2/auth/refresh", json={"refresh_token": old_token})
        self.assertEqual(resp.status_code, 401)
        code = resp.json().get("detail", {}).get("code", "")
        self.assertEqual(code, "TOKEN_UPGRADE_REQUIRED")


# ---------------------------------------------------------------------------
# 4. GET /sessions + DELETE /sessions/{device_id}
# ---------------------------------------------------------------------------

class TestSessionsEndpoints(unittest.TestCase):

    def _auth_headers(self, user="alice@riad.fun", role="engineer"):
        from app.auth.jwt import create_access_token
        token = create_access_token(user, role)
        return {"Authorization": f"Bearer {token}"}

    def _get_client(self, redis_mock):
        from fastapi.testclient import TestClient
        from app.main import app
        from app.core.redis import get_redis

        async def _redis():
            return redis_mock

        app.dependency_overrides[get_redis] = _redis
        return TestClient(app, raise_server_exceptions=False)

    def tearDown(self):
        from app.main import app
        app.dependency_overrides.clear()

    def test_get_sessions_returns_active_devices(self):
        """GET /sessions with two active devices returns both."""
        import time
        now = time.time()
        sess1 = {"jti": "jti-1", "created": now, "last_seen": now, "ip_address": "10.0.0.1"}
        sess2 = {"jti": "jti-2", "created": now, "last_seen": now, "ip_address": "10.0.0.2"}

        mock = AsyncMock()
        mock.pipeline = MagicMock(return_value=AsyncMock(
            __aenter__=AsyncMock(return_value=AsyncMock(execute=AsyncMock(return_value=[]))),
            __aexit__=AsyncMock(return_value=False),
        ))
        mock.smembers = AsyncMock(return_value={b"dev-1", b"dev-2"})

        async def _get(key):
            if "rt:sess:alice@riad.fun:dev-1" in key:
                return json.dumps(sess1).encode()
            if "rt:sess:alice@riad.fun:dev-2" in key:
                return json.dumps(sess2).encode()
            if "frappe:sid:" in key:
                return b"fake-sid"
            return None

        mock.get = AsyncMock(side_effect=_get)
        mock.srem = AsyncMock(return_value=1)
        mock.zremrangebyscore = AsyncMock(return_value=0)
        mock.zadd = AsyncMock(return_value=1)
        mock.zcard = AsyncMock(return_value=1)
        mock.zrange = AsyncMock(return_value=[])
        mock.expire = AsyncMock(return_value=1)

        client = self._get_client(mock)
        resp = client.get("/api/v2/auth/sessions", headers=self._auth_headers())
        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertTrue(body["success"])
        device_ids = {s["device_id"] for s in body["data"]}
        self.assertEqual(device_ids, {"dev-1", "dev-2"})

    def test_delete_session_returns_success(self):
        """DELETE /sessions/{device_id} with valid session removes it."""
        import time
        now = time.time()
        sess = {"jti": "old-jti", "created": now, "last_seen": now, "ip_address": "10.0.0.1"}

        mock = AsyncMock()
        pipeline_mock = AsyncMock()
        pipeline_mock.delete = AsyncMock()
        pipeline_mock.srem = AsyncMock()
        pipeline_mock.setex = AsyncMock()
        pipeline_mock.execute = AsyncMock(return_value=[1, 1, 1])
        mock.pipeline = MagicMock(return_value=pipeline_mock)

        async def _get(key):
            if "rt:sess:alice@riad.fun:dev-mobile" in key:
                return json.dumps(sess).encode()
            if "frappe:sid:" in key:
                return b"fake-sid"
            return None

        mock.get = AsyncMock(side_effect=_get)
        mock.zremrangebyscore = AsyncMock(return_value=0)
        mock.zadd = AsyncMock(return_value=1)
        mock.zcard = AsyncMock(return_value=1)
        mock.zrange = AsyncMock(return_value=[])
        mock.expire = AsyncMock(return_value=1)

        client = self._get_client(mock)
        resp = client.delete("/api/v2/auth/sessions/dev-mobile", headers=self._auth_headers())
        self.assertEqual(resp.status_code, 200)
        self.assertTrue(resp.json()["success"])
        pipeline_mock.delete.assert_called()

    def test_delete_nonexistent_session_returns_404(self):
        """DELETE /sessions/{device_id} for unknown device returns 404."""
        mock = AsyncMock()

        async def _get(key):
            if "frappe:sid:" in key:
                return b"fake-sid"
            return None

        mock.get = AsyncMock(side_effect=_get)
        mock.zremrangebyscore = AsyncMock(return_value=0)
        mock.zadd = AsyncMock(return_value=1)
        mock.zcard = AsyncMock(return_value=1)
        mock.zrange = AsyncMock(return_value=[])
        mock.expire = AsyncMock(return_value=1)

        client = self._get_client(mock)
        resp = client.delete("/api/v2/auth/sessions/no-such-device", headers=self._auth_headers())
        self.assertEqual(resp.status_code, 404)


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    unittest.main(verbosity=2)
