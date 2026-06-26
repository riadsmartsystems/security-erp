"""P1: Push notification service + FCM tests.

Run:
  cd "/home/joker/RIAD CRM"
  python -m unittest tests.p1.test_push_service -v
"""

import asyncio
import json
import os
import sys
import types
import unittest
from unittest.mock import AsyncMock, MagicMock, patch

_services_root = os.path.join(os.path.dirname(__file__), "..", "..", "services", "security-api")
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)

os.environ.setdefault("SECRET_KEY", "ci-test-secret-key-min-32-chars-ok")
os.environ.setdefault("FRAPPE_URL", "http://localhost:8000")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379")

if "firebase_admin" not in sys.modules:
    _fa = types.ModuleType("firebase_admin")
    _fa.credentials = MagicMock()
    _fa.initialize_app = MagicMock()
    _fa.messaging = MagicMock()
    sys.modules["firebase_admin"] = _fa


def _run(coro):
    loop = asyncio.new_event_loop()
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


# ---------------------------------------------------------------------------
# 1. register_token — stores token in Redis with correct TTL
# ---------------------------------------------------------------------------

class TestRegisterToken(unittest.TestCase):

    @patch("app.services.push_service.get_redis", new_callable=AsyncMock)
    def test_register_token_stores_key(self, mock_get_redis):
        mock_r = AsyncMock()
        mock_get_redis.return_value = mock_r
        from app.services.push_service import register_token

        result = _run(register_token(user_id="u1", device_id="d1", fcm_token="tok_abc", platform="android"))

        self.assertTrue(result)
        mock_r.setex.assert_called_once()
        args = mock_r.setex.call_args[0]
        self.assertEqual(args[0], "push:u1:d1")
        self.assertEqual(args[1], 60 * 60 * 24 * 90)
        stored = json.loads(args[2])
        self.assertEqual(stored["token"], "tok_abc")
        self.assertEqual(stored["platform"], "android")
        mock_r.sadd.assert_called_once_with("push:devices:u1", "d1")

    @patch("app.services.push_service.get_redis", new_callable=AsyncMock)
    def test_register_token_default_platform(self, mock_get_redis):
        mock_r = AsyncMock()
        mock_get_redis.return_value = mock_r
        from app.services.push_service import register_token

        _run(register_token(user_id="u1", device_id="d1", fcm_token="tok"))
        stored = json.loads(mock_r.setex.call_args[0][2])
        self.assertEqual(stored["platform"], "android")


# ---------------------------------------------------------------------------
# 2. revoke_token — removes from Redis
# ---------------------------------------------------------------------------

class TestRevokeToken(unittest.TestCase):

    @patch("app.services.push_service.get_redis", new_callable=AsyncMock)
    def test_revoke_token_deletes_key(self, mock_get_redis):
        mock_r = AsyncMock()
        mock_get_redis.return_value = mock_r
        from app.services.push_service import revoke_token

        result = _run(revoke_token(user_id="u1", device_id="d1"))

        self.assertEqual(result, "d1")
        mock_r.delete.assert_called_once_with("push:u1:d1")
        mock_r.srem.assert_called_once_with("push:devices:u1", "d1")


# ---------------------------------------------------------------------------
# 3. _get_user_tokens — returns valid tokens, cleans stale devices
# ---------------------------------------------------------------------------

class TestGetUserTokens(unittest.TestCase):

    @patch("app.services.push_service.get_redis", new_callable=AsyncMock)
    def test_returns_valid_tokens(self, mock_get_redis):
        mock_r = AsyncMock()
        mock_get_redis.return_value = mock_r
        mock_r.smembers.return_value = [b"d1", b"d2"]
        mock_r.get.side_effect = [
            json.dumps({"token": "tok1", "platform": "android"}).encode(),
            json.dumps({"token": "tok2", "platform": "ios"}).encode(),
        ]
        from app.services.push_service import _get_user_tokens

        result = _run(_get_user_tokens(user_id="u1"))

        self.assertEqual(len(result), 2)
        self.assertEqual(result[0], ("d1", "tok1"))
        self.assertEqual(result[1], ("d2", "tok2"))

    @patch("app.services.push_service.get_redis", new_callable=AsyncMock)
    def test_stale_device_removed(self, mock_get_redis):
        mock_r = AsyncMock()
        mock_get_redis.return_value = mock_r
        mock_r.smembers.return_value = [b"d1", b"d2"]
        mock_r.get.side_effect = [json.dumps({"token": "tok1", "platform": "android"}).encode(), None]

        from app.services.push_service import _get_user_tokens
        result = _run(_get_user_tokens(user_id="u1"))

        self.assertEqual(len(result), 1)
        self.assertEqual(result[0], ("d1", "tok1"))
        mock_r.srem.assert_called_once_with("push:devices:u1", "d2")

    @patch("app.services.push_service.get_redis", new_callable=AsyncMock)
    def test_empty_devices(self, mock_get_redis):
        mock_r = AsyncMock()
        mock_get_redis.return_value = mock_r
        mock_r.smembers.return_value = []

        from app.services.push_service import _get_user_tokens
        result = _run(_get_user_tokens(user_id="u1"))
        self.assertEqual(result, [])


# ---------------------------------------------------------------------------
# 4. send_push — Firebase not initialized → graceful fallback
# ---------------------------------------------------------------------------

class TestSendPush(unittest.TestCase):

    def test_firebase_not_initialized(self):
        import app.services.push_service as svc
        orig = svc._firebase_initialized
        try:
            svc._firebase_initialized = False
            from app.services.push_service import send_push

            result = _run(send_push(user_id="u1", title="Hi", body="Test"))
            self.assertFalse(result["ok"])
            self.assertEqual(result["reason"], "firebase_not_initialized")
        finally:
            svc._firebase_initialized = orig

    @patch("app.services.push_service.get_redis", new_callable=AsyncMock)
    def test_no_tokens_returns_zero(self, mock_get_redis):
        mock_r = AsyncMock()
        mock_get_redis.return_value = mock_r
        mock_r.smembers.return_value = []

        import app.services.push_service as svc
        orig = svc._firebase_initialized
        try:
            svc._firebase_initialized = True
            from app.services.push_service import send_push

            result = _run(send_push(user_id="u1", title="Hi", body="Test"))
            self.assertTrue(result["ok"])
            self.assertEqual(result["sent"], 0)
            self.assertEqual(result["failed"], 0)
        finally:
            svc._firebase_initialized = orig

    @patch("app.services.push_service.revoke_token", new_callable=AsyncMock)
    @patch("app.services.push_service._get_user_tokens", new_callable=AsyncMock)
    def test_sends_multicast_and_revokes_dead_tokens(self, mock_get_tokens, mock_revoke):
        mock_get_tokens.return_value = [("d1", "tok1"), ("d2", "tok2")]

        mock_messaging = sys.modules["firebase_admin"].messaging
        mock_messaging.send_each_for_multicast.reset_mock()
        mock_messaging.UnregisteredError = type("UnregisteredError", (Exception,), {})

        resp1 = MagicMock()
        resp1.success = False
        resp1.exception = mock_messaging.UnregisteredError("unregistered")
        resp2 = MagicMock()
        resp2.success = True
        resp2.exception = None

        mock_response = MagicMock()
        mock_response.success_count = 1
        mock_response.failure_count = 1
        mock_response.responses = [resp1, resp2]
        mock_messaging.send_each_for_multicast.return_value = mock_response

        import app.services.push_service as svc
        orig = svc._firebase_initialized
        try:
            svc._firebase_initialized = True
            from app.services.push_service import send_push

            result = _run(send_push(user_id="u1", title="Hi", body="Test", data={"key": "val"}))

            self.assertTrue(result["ok"])
            self.assertEqual(result["sent"], 1)
            self.assertEqual(result["failed"], 1)
            mock_messaging.send_each_for_multicast.assert_called_once()
            mock_revoke.assert_called_once_with(user_id="u1", device_id="d1")
        finally:
            svc._firebase_initialized = orig
            mock_messaging.send_each_for_multicast.side_effect = None

    @patch("app.services.push_service._get_user_tokens", new_callable=AsyncMock)
    def test_send_push_exception_returns_error(self, mock_get_tokens):
        mock_get_tokens.return_value = [("d1", "tok1")]

        mock_messaging = sys.modules["firebase_admin"].messaging
        mock_messaging.send_each_for_multicast.reset_mock()
        mock_messaging.send_each_for_multicast.side_effect = Exception("FCM down")

        import app.services.push_service as svc
        orig = svc._firebase_initialized
        try:
            svc._firebase_initialized = True
            from app.services.push_service import send_push

            result = _run(send_push(user_id="u1", title="Hi", body="Test"))
            self.assertFalse(result["ok"])
            self.assertIn("FCM down", result["error"])
        finally:
            svc._firebase_initialized = orig
            mock_messaging.send_each_for_multicast.side_effect = None


# ---------------------------------------------------------------------------
# 5. fire_and_forget_push — creates background task
# ---------------------------------------------------------------------------

class TestFireAndForget(unittest.TestCase):

    @patch("app.services.push_service.send_push", new_callable=AsyncMock)
    def test_creates_and_runs_background_task(self, mock_send):
        mock_send.return_value = {"ok": True, "sent": 1, "failed": 0}
        import app.services.push_service as svc
        svc._background_tasks.clear()
        from app.services.push_service import fire_and_forget_push

        async def _test():
            fire_and_forget_push(user_id="u1", title="Hi", body="Test", data={"k": "v"})
            self.assertGreater(len(svc._background_tasks), 0)
            await asyncio.sleep(0.1)
            mock_send.assert_called_once_with(user_id="u1", title="Hi", body="Test", data={"k": "v"})

        _run(_test())
        svc._background_tasks.clear()

    @patch("app.services.push_service.send_push", new_callable=AsyncMock)
    def test_background_task_removed_on_completion(self, mock_send):
        mock_send.return_value = {"ok": True, "sent": 1, "failed": 0}
        import app.services.push_service as svc
        svc._background_tasks.clear()
        from app.services.push_service import fire_and_forget_push

        async def _test():
            fire_and_forget_push(user_id="u1", title="Hi", body="Test")
            await asyncio.sleep(0.1)
            self.assertEqual(len(svc._background_tasks), 0)

        _run(_test())


# ---------------------------------------------------------------------------
# 6. Firebase init edge cases
# ---------------------------------------------------------------------------

class TestFirebaseInit(unittest.TestCase):

    @patch("app.services.push_service.os.path.exists", return_value=False)
    def test_no_credentials_file(self, mock_exists):
        import app.services.push_service as svc
        orig = svc._firebase_initialized
        try:
            svc._firebase_initialized = False
            svc._ensure_firebase()
            self.assertFalse(svc._firebase_initialized)
        finally:
            svc._firebase_initialized = orig

    def test_already_initialized_skipped(self):
        import app.services.push_service as svc
        orig = svc._firebase_initialized
        try:
            svc._firebase_initialized = True
            svc._ensure_firebase()
            self.assertTrue(svc._firebase_initialized)
        finally:
            svc._firebase_initialized = orig


if __name__ == "__main__":
    unittest.main()
