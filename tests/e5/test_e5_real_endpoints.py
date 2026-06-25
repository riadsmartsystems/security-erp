"""E5 Real Integration Tests — FastAPI endpoints with TestClient.

Uses real FastAPI app with mocked Frappe/Redis dependencies.
Tests actual HTTP requests and response formats.
"""
import asyncio
import os
import sys
import unittest
from unittest.mock import AsyncMock, patch

_services_root = os.path.join(os.path.dirname(__file__), "..", "..", "services", "security-api")
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)

from fastapi.testclient import TestClient


def _make_client():
    """Create TestClient with mocked auth and Redis."""
    from app.main import app
    from app.core.redis import get_redis
    from app.auth.dependencies import get_current_user, CurrentUser
    from app.auth.permissions import Role

    mock_user = CurrentUser(
        user_id="test@test.com",
        role=Role.SALES_MANAGER,
        frappe_sid="test-sid",
        frappe_roles=["RIAD AI Admin"],
    )

    mock_redis_instance = AsyncMock()
    mock_redis_instance.incr = AsyncMock(return_value=1)
    mock_redis_instance.expire = AsyncMock()
    mock_redis_instance.get = AsyncMock(return_value=None)
    mock_redis_instance.hgetall = AsyncMock(return_value={"state": "closed"})

    async def _mock_redis():
        return mock_redis_instance

    async def _mock_current_user():
        return mock_user

    app.dependency_overrides[get_redis] = _mock_redis
    app.dependency_overrides[get_current_user] = _mock_current_user

    return TestClient(app), mock_redis_instance


class TestDegradationEndpoint(unittest.TestCase):
    def test_degradation_returns_primary_when_all_healthy(self):
        client, mock_redis = _make_client()

        with patch("app.routes.ai.get_provider_degradation", new_callable=AsyncMock) as mock_get_degradation:
            mock_get_degradation.return_value = [
                {"name": "Gemini", "provider_name": "gemini", "health_status": "healthy", "priority": 1},
            ]

            response = client.get("/api/v2/ai/degradation")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["level"], "primary")
        self.assertIn("message", data)
        self.assertIsInstance(data["providers"], list)

    def test_degradation_returns_manual_when_all_down(self):
        client, mock_redis = _make_client()
        mock_redis.hgetall = AsyncMock(return_value={"state": "open"})

        with patch("app.routes.ai.get_provider_degradation", new_callable=AsyncMock) as mock_get_degradation:
            mock_get_degradation.return_value = [
                {"name": "Gemini", "provider_name": "gemini", "health_status": "down", "priority": 1},
            ]

            response = client.get("/api/v2/ai/degradation")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["level"], "manual")

    def test_degradation_handles_frappe_error(self):
        client, mock_redis = _make_client()

        with patch("app.routes.ai.get_provider_degradation", new_callable=AsyncMock) as mock_get_degradation:
            mock_get_degradation.side_effect = Exception("Frappe unavailable")

            response = client.get("/api/v2/ai/degradation")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["level"], "manual")


class TestAIProviderEndpoints(unittest.TestCase):
    def test_create_provider(self):
        client, _ = _make_client()

        with patch("app.routes.ai_admin.ai_admin_service.upsert_provider", new_callable=AsyncMock) as mock_upsert:
            mock_upsert.return_value = {"name": "Gemini", "provider_name": "gemini", "priority": 1}

            response = client.post("/api/v2/ai-admin/providers", json={
                "name": "Gemini",
                "provider_name": "gemini",
                "priority": 1,
                "is_enabled": True,
                "health_status": "healthy",
            })

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["name"], "Gemini")

    def test_list_providers(self):
        client, _ = _make_client()

        with patch("app.routes.ai_admin.ai_admin_service.list_providers", new_callable=AsyncMock) as mock_list:
            mock_list.return_value = [
                {"name": "Gemini", "provider_name": "gemini", "health_status": "healthy", "priority": 1},
            ]

            response = client.get("/api/v2/ai-admin/providers")

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(len(data), 1)
        self.assertEqual(data[0]["name"], "Gemini")


class TestAIExecuteEndpoint(unittest.TestCase):
    def test_execute_returns_result(self):
        client, _ = _make_client()

        with patch("app.routes.ai.frappe_post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = {
                "status": "ok",
                "result": "Test result",
                "tokens_used": 100,
                "latency_ms": 50.0,
                "provider_used": "gemini",
                "raw_meta": {},
            }

            response = client.post("/api/v2/ai/execute", json={
                "task": "test_task",
                "payload": {"key": "value"},
            })

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "ok")
        self.assertEqual(data["content"], "Test result")
        self.assertEqual(data["tokens"], 100)


if __name__ == "__main__":
    unittest.main()
