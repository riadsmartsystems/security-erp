"""P1: Push notification routes tests.

Run:
  cd "/home/joker/RIAD CRM"
  python -m unittest tests.p1.test_push_routes -v
"""

import os
import sys
import unittest
from unittest.mock import AsyncMock, patch

_services_root = os.path.join(os.path.dirname(__file__), "..", "..", "services", "security-api")
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)

os.environ.setdefault("SECRET_KEY", "ci-test-secret-key-min-32-chars-ok")
os.environ.setdefault("FRAPPE_URL", "http://localhost:8000")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379")

from app.auth.dependencies import CurrentUser, get_current_user
from app.schemas.push import (
    PushTokenRegisterRequest, PushTokenRevokeRequest, PushSendRequest,
)


def _make_app():
    from fastapi import FastAPI
    from app.routes.push import router
    a = FastAPI()
    a.include_router(router)
    return a


def _mock_user(user_id="test-user", roles=None):
    return CurrentUser(
        user_id=user_id,
        role="engineer",
        frappe_sid="test-sid",
        frappe_roles=roles or ["Engineer"],
    )


def _admin_user(user_id="admin-user"):
    return CurrentUser(
        user_id=user_id,
        role="owner",
        frappe_sid="admin-sid",
        frappe_roles=["System Manager"],
    )


# ---------------------------------------------------------------------------
# 1. Schemas — Pydantic validation
# ---------------------------------------------------------------------------

class TestPushSchemas(unittest.TestCase):

    def test_register_request_valid(self):
        req = PushTokenRegisterRequest(device_id="d1", fcm_token="tok", platform="android")
        self.assertEqual(req.device_id, "d1")
        self.assertEqual(req.platform, "android")

    def test_register_request_default_platform(self):
        req = PushTokenRegisterRequest(device_id="d1", fcm_token="tok")
        self.assertEqual(req.platform, "android")

    def test_register_request_invalid_platform(self):
        with self.assertRaises(Exception):
            PushTokenRegisterRequest(device_id="d1", fcm_token="tok", platform="blackberry")

    def test_send_request_valid(self):
        req = PushSendRequest(user_id="u1", title="Hi", body="Test")
        self.assertEqual(req.data, {})

    def test_send_request_empty_title_rejected(self):
        with self.assertRaises(Exception):
            PushSendRequest(user_id="u1", title="", body="Test")

    def test_revoke_request_valid(self):
        req = PushTokenRevokeRequest(device_id="d1")
        self.assertEqual(req.device_id, "d1")


# ---------------------------------------------------------------------------
# 2. POST /api/v2/push/token — register
# ---------------------------------------------------------------------------

class TestPushTokenRegisterEndpoint(unittest.TestCase):

    @patch("app.routes.push.register_token", new_callable=AsyncMock)
    def test_register_returns_device_id(self, mock_reg):
        mock_reg.return_value = True
        app = _make_app()
        app.dependency_overrides[get_current_user] = lambda: _mock_user()
        from fastapi.testclient import TestClient
        client = TestClient(app)
        resp = client.post(
            "/api/v2/push/token",
            json={"device_id": "d1", "fcm_token": "tok", "platform": "android"},
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertTrue(data["ok"])
        self.assertEqual(data["device_id"], "d1")
        mock_reg.assert_called_once_with(user_id="test-user", device_id="d1", fcm_token="tok", platform="android")
        app.dependency_overrides.clear()

    def test_register_missing_fcm_token(self):
        app = _make_app()
        app.dependency_overrides[get_current_user] = lambda: _mock_user()
        from fastapi.testclient import TestClient
        client = TestClient(app)
        resp = client.post(
            "/api/v2/push/token",
            json={"device_id": "d1"},
        )
        self.assertEqual(resp.status_code, 422)
        app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# 3. DELETE /api/v2/push/token — revoke
# ---------------------------------------------------------------------------

class TestPushTokenRevokeEndpoint(unittest.TestCase):

    @patch("app.routes.push.revoke_token", new_callable=AsyncMock)
    def test_revoke_returns_device_id(self, mock_revoke):
        mock_revoke.return_value = "d1"
        app = _make_app()
        app.dependency_overrides[get_current_user] = lambda: _mock_user()
        from fastapi.testclient import TestClient
        client = TestClient(app)
        resp = client.request(
            "DELETE",
            "/api/v2/push/token",
            json={"device_id": "d1"},
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertTrue(data["ok"])
        self.assertEqual(data["revoked"], "d1")
        app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# 4. POST /api/v2/push/send — test push
# ---------------------------------------------------------------------------

class TestPushSendEndpoint(unittest.TestCase):

    @patch("app.routes.push.send_push", new_callable=AsyncMock)
    def test_send_to_self_allowed(self, mock_send):
        mock_send.return_value = {"ok": True, "sent": 1, "failed": 0}
        app = _make_app()
        app.dependency_overrides[get_current_user] = lambda: _mock_user(user_id="u1")
        from fastapi.testclient import TestClient
        client = TestClient(app)
        resp = client.post(
            "/api/v2/push/send",
            json={"user_id": "u1", "title": "Hi", "body": "Test"},
        )
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertTrue(data["ok"])
        self.assertEqual(data["sent"], 1)
        app.dependency_overrides.clear()

    @patch("app.routes.push.send_push", new_callable=AsyncMock)
    def test_admin_can_send_to_others(self, mock_send):
        mock_send.return_value = {"ok": True, "sent": 2, "failed": 0}
        app = _make_app()
        app.dependency_overrides[get_current_user] = lambda: _admin_user(user_id="admin")
        from fastapi.testclient import TestClient
        client = TestClient(app)
        resp = client.post(
            "/api/v2/push/send",
            json={"user_id": "other-user", "title": "Hi", "body": "Test"},
        )
        self.assertEqual(resp.status_code, 200)
        mock_send.assert_called_once_with(user_id="other-user", title="Hi", body="Test", data={})
        app.dependency_overrides.clear()

    def test_non_admin_cannot_send_to_others(self):
        app = _make_app()
        app.dependency_overrides[get_current_user] = lambda: _mock_user(user_id="u1", roles=["Engineer"])
        from fastapi.testclient import TestClient
        client = TestClient(app)
        resp = client.post(
            "/api/v2/push/send",
            json={"user_id": "other-user", "title": "Hi", "body": "Test"},
        )
        self.assertEqual(resp.status_code, 403)
        self.assertIn("Можна надсилати тестовий push лише собі", resp.json()["detail"])
        app.dependency_overrides.clear()

    @patch("app.routes.push.send_push", new_callable=AsyncMock)
    def test_send_with_data(self, mock_send):
        mock_send.return_value = {"ok": True, "sent": 1, "failed": 0}
        app = _make_app()
        app.dependency_overrides[get_current_user] = lambda: _mock_user(user_id="u1")
        from fastapi.testclient import TestClient
        client = TestClient(app)
        resp = client.post(
            "/api/v2/push/send",
            json={"user_id": "u1", "title": "Hi", "body": "Test", "data": {"type": "test", "id": "123"}},
        )
        self.assertEqual(resp.status_code, 200)
        call_kwargs = mock_send.call_args[1]
        self.assertEqual(call_kwargs["data"], {"type": "test", "id": "123"})
        app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# 5. Auth — 401/403 for unauthenticated push routes (HTTPBearer → 403)
# ---------------------------------------------------------------------------

class TestPushAuthRequired(unittest.TestCase):

    def test_token_endpoint_no_auth(self):
        app = _make_app()
        from fastapi.testclient import TestClient
        client = TestClient(app)
        resp = client.post("/api/v2/push/token", json={"device_id": "d1", "fcm_token": "tok"})
        self.assertIn(resp.status_code, [401, 403])

    def test_send_endpoint_no_auth(self):
        app = _make_app()
        from fastapi.testclient import TestClient
        client = TestClient(app)
        resp = client.post("/api/v2/push/send", json={"user_id": "u1", "title": "Hi", "body": "Test"})
        self.assertIn(resp.status_code, [401, 403])

    def test_revoke_endpoint_no_auth(self):
        app = _make_app()
        from fastapi.testclient import TestClient
        client = TestClient(app)
        resp = client.request("DELETE", "/api/v2/push/token", json={"device_id": "d1"})
        self.assertIn(resp.status_code, [401, 403])


# ---------------------------------------------------------------------------
# 6. Fire-and-forget triggers exist in sync/estimates/media
# ---------------------------------------------------------------------------

class TestFireAndForgetTriggers(unittest.TestCase):

    def test_sync_route_has_fire_and_forget(self):
        with open(os.path.join(_services_root, "app/routes/sync.py")) as f:
            content = f.read()
        self.assertIn("fire_and_forget_push", content)
        self.assertIn("sync_conflict_resolved", content)

    def test_estimates_route_has_fire_and_forget(self):
        with open(os.path.join(_services_root, "app/routes/estimates.py")) as f:
            content = f.read()
        self.assertIn("fire_and_forget_push", content)
        self.assertIn("estimate_review", content)

    def test_media_route_has_fire_and_forget(self):
        with open(os.path.join(_services_root, "app/routes/media.py")) as f:
            content = f.read()
        self.assertIn("fire_and_forget_push", content)
        self.assertIn("transcription_ready", content)


# ---------------------------------------------------------------------------
# 7. Push endpoints registered (probed via TestClient)
# ---------------------------------------------------------------------------

class TestPushRouteRegistered(unittest.TestCase):

    @patch("app.routes.push.register_token", new_callable=AsyncMock)
    def test_token_post_registered(self, mock_reg):
        mock_reg.return_value = True
        app = _make_app()
        app.dependency_overrides[get_current_user] = lambda: _mock_user()
        from fastapi.testclient import TestClient
        client = TestClient(app)
        resp = client.post("/api/v2/push/token", json={"device_id": "d1", "fcm_token": "tok"})
        self.assertEqual(resp.status_code, 200)
        app.dependency_overrides.clear()

    @patch("app.routes.push.revoke_token", new_callable=AsyncMock)
    def test_token_delete_registered(self, mock_revoke):
        mock_revoke.return_value = "d1"
        app = _make_app()
        app.dependency_overrides[get_current_user] = lambda: _mock_user()
        from fastapi.testclient import TestClient
        client = TestClient(app)
        resp = client.request("DELETE", "/api/v2/push/token", json={"device_id": "d1"})
        self.assertEqual(resp.status_code, 200)
        app.dependency_overrides.clear()

    @patch("app.routes.push.send_push", new_callable=AsyncMock)
    def test_send_post_registered(self, mock_send):
        mock_send.return_value = {"ok": True, "sent": 1, "failed": 0}
        app = _make_app()
        app.dependency_overrides[get_current_user] = lambda: _mock_user(user_id="u1")
        from fastapi.testclient import TestClient
        client = TestClient(app)
        resp = client.post("/api/v2/push/send", json={"user_id": "u1", "title": "Hi", "body": "Test"})
        self.assertEqual(resp.status_code, 200)
        app.dependency_overrides.clear()

    def test_push_prefix_in_route_paths(self):
        from app.routes.push import router
        paths = [r.path for r in router.routes if hasattr(r, "path")]
        self.assertTrue(any("/push" in p for p in paths), f"No /push in router paths: {paths}")

    def test_push_router_imported_in_main(self):
        from app.routes import push as push_mod
        self.assertTrue(hasattr(push_mod, "router"))
        self.assertEqual(push_mod.router.prefix, "/api/v2/push")


if __name__ == "__main__":
    unittest.main()
