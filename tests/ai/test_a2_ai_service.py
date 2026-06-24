"""A2 tests — AI Request Log, sync_provider_health, /execute endpoint.

Run inside security-api container:
  docker compose exec security-api python -m pytest tests/ai/test_a2_ai_service.py -v
  # or via unittest:
  docker compose exec security-api python -m unittest tests.ai.test_a2_ai_service -v

Uses unittest.mock to mock Frappe REST API and Redis.
"""

import asyncio
import os
import sys
import unittest
from unittest.mock import AsyncMock, MagicMock, patch

# Ensure security-api app is importable
_services_root = os.path.join(os.path.dirname(__file__), "..", "..", "services", "security-api")
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)

_erpnext_root = os.path.join(os.path.dirname(__file__), "..", "..", "erpnext", "security_erp")
if os.path.isdir(_erpnext_root):
    sys.path.insert(0, _erpnext_root)


class TestAnonymizePayload(unittest.TestCase):
    def test_basic_anonymization(self):
        from app.services.ai_orchestrator_service import _anonymize_payload

        result = _anonymize_payload("project_builder", {
            "technical_task": "встановити 8 камер",
            "catalog": "DS-2CD2042|Camera|5000",
        })
        self.assertEqual(result["task"], "project_builder")
        self.assertIn("technical_task", result["payload_keys"])
        self.assertIn("catalog", result["payload_keys"])
        self.assertNotIn("встановити", str(result))
        self.assertNotIn("DS-2CD2042", str(result))
        self.assertEqual(len(result["text_lengths"]), 2)
        self.assertIsInstance(result["text_lengths"][0], int)

    def test_empty_payload(self):
        from app.services.ai_orchestrator_service import _anonymize_payload

        result = _anonymize_payload("inspection_report", {})
        self.assertEqual(result["task"], "inspection_report")
        self.assertEqual(result["payload_keys"], [])
        self.assertEqual(result["text_lengths"], [])

    def test_nested_dict_values_not_leaked(self):
        from app.services.ai_orchestrator_service import _anonymize_payload

        result = _anonymize_payload("project_builder", {
            "nested": {"secret_key": "sk-abc123", "token": "tok_xyz"},
            "plain": "some text",
        })
        self.assertIn("nested", result["payload_keys"])
        self.assertIn("plain", result["payload_keys"])
        self.assertNotIn("sk-abc123", str(result))
        self.assertNotIn("tok_xyz", str(result))

    def test_keys_sorted(self):
        from app.services.ai_orchestrator_service import _anonymize_payload

        result = _anonymize_payload("task", {"zebra": "a", "alpha": "b", "middle": "c"})
        self.assertEqual(result["payload_keys"], ["alpha", "middle", "zebra"])


class TestSyncProviderHealth(unittest.IsolatedAsyncioTestCase):
    async def test_closed_maps_to_healthy(self):
        from app.services.ai_orchestrator_service import sync_provider_health

        mock_redis = AsyncMock()
        mock_redis.hgetall = AsyncMock(return_value={"state": "closed", "failures": "0"})

        with patch("app.services.ai_orchestrator_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.ai_orchestrator_service.frappe_put", new_callable=AsyncMock) as mock_put:
            mock_get.return_value = {"data": [
                {"name": "AI Provider-gemini", "provider_name": "gemini", "health_status": "healthy", "priority": 1, "is_enabled": 1}
            ]}

            result = await sync_provider_health(mock_redis, "test-sid")
            self.assertEqual(len(result), 1)
            self.assertEqual(result[0]["name"], "gemini")
            self.assertEqual(result[0]["health"], "healthy")
            mock_put.assert_not_awaited()

    async def test_open_maps_to_down(self):
        from app.services.ai_orchestrator_service import sync_provider_health

        mock_redis = AsyncMock()
        mock_redis.hgetall = AsyncMock(return_value={"state": "open", "failures": "5"})

        with patch("app.services.ai_orchestrator_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.ai_orchestrator_service.frappe_put", new_callable=AsyncMock) as mock_put:
            mock_get.return_value = {"data": [
                {"name": "AI Provider-gemini", "provider_name": "gemini", "health_status": "healthy", "priority": 1, "is_enabled": 1}
            ]}

            result = await sync_provider_health(mock_redis, "test-sid")
            self.assertEqual(result[0]["health"], "down")
            mock_put.assert_awaited_once()

    async def test_half_open_maps_to_degraded(self):
        from app.services.ai_orchestrator_service import sync_provider_health

        mock_redis = AsyncMock()
        mock_redis.hgetall = AsyncMock(return_value={"state": "half_open", "failures": "0"})

        with patch("app.services.ai_orchestrator_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.ai_orchestrator_service.frappe_put", new_callable=AsyncMock) as mock_put:
            mock_get.return_value = {"data": [
                {"name": "AI Provider-stub", "provider_name": "stub", "health_status": "healthy", "priority": 2, "is_enabled": 1}
            ]}

            result = await sync_provider_health(mock_redis, "test-sid")
            self.assertEqual(result[0]["health"], "degraded")
            mock_put.assert_awaited_once()

    async def test_no_cb_key_defaults_to_healthy(self):
        from app.services.ai_orchestrator_service import sync_provider_health

        mock_redis = AsyncMock()
        mock_redis.hgetall = AsyncMock(return_value={})

        with patch("app.services.ai_orchestrator_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.ai_orchestrator_service.frappe_put", new_callable=AsyncMock) as mock_put:
            mock_get.return_value = {"data": [
                {"name": "AI Provider-new", "provider_name": "new", "health_status": "", "priority": 3, "is_enabled": 1}
            ]}

            result = await sync_provider_health(mock_redis, "test-sid")
            self.assertEqual(result[0]["health"], "healthy")
            mock_put.assert_awaited_once()


class TestWriteAIRequestLog(unittest.IsolatedAsyncioTestCase):
    async def test_anonymized_payload_in_log(self):
        from app.services.ai_orchestrator_service import write_ai_request_log, _anonymize_payload

        with patch("app.services.ai_orchestrator_service.frappe_post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = {"data": {"name": "AILOG-00001"}}

            anonymized = _anonymize_payload("project_builder", {"technical_task": "secret data"})
            await write_ai_request_log(
                sid="test-sid",
                anonymized_payload=anonymized,
                provider="gemini",
                latency_ms=150.5,
                tokens=100,
                status="ok",
            )

            mock_post.assert_awaited_once()
            call_args = mock_post.call_args
            data = call_args.kwargs.get("data") or call_args[1].get("data")
            self.assertIn("anonymized_payload", data)
            self.assertNotIn("secret data", data["anonymized_payload"])
            self.assertIn("project_builder", data["anonymized_payload"])
            self.assertEqual(data["provider"], "gemini")
            self.assertEqual(data["status"], "ok")

    async def test_error_message_truncated(self):
        from app.services.ai_orchestrator_service import write_ai_request_log

        with patch("app.services.ai_orchestrator_service.frappe_post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = {"data": {"name": "AILOG-00002"}}
            long_error = "x" * 1000
            await write_ai_request_log(
                sid="test-sid",
                anonymized_payload={"task": "t"},
                provider="stub",
                latency_ms=0,
                tokens=0,
                status="error",
                error_message=long_error,
            )
            data = mock_post.call_args.kwargs.get("data") or mock_post.call_args[1].get("data")
            self.assertEqual(len(data["error_message"]), 500)


class TestAIExecuteEndpoint(unittest.IsolatedAsyncioTestCase):
    async def test_execute_returns_result(self):
        """POST /api/v2/ai/execute with mock orchestrator → check response DTO."""
        from fastapi.testclient import TestClient

        mock_result = {
            "status": "ok",
            "result": '{"items":[]}',
            "tokens_used": 42,
            "latency_ms": 123.4,
            "provider_used": "gemini",
            "raw_meta": {"model": "gemini-2.0-flash"},
        }

        with patch("app.routes.ai.frappe_post", new_callable=AsyncMock) as mock_frappe_post, \
              patch("app.routes.ai.write_ai_request_log", new_callable=AsyncMock) as mock_log:

            mock_frappe_post.return_value = mock_result
            mock_log.return_value = None

            from app.auth.dependencies import CurrentUser
            from app.auth.permissions import Role

            mock_user = CurrentUser(user_id="test@test.com", role=Role.DIRECTOR, frappe_sid="test-sid")

            from app.main import app
            from app.core.redis import get_redis

            async def _mock_redis():
                return AsyncMock()

            app.dependency_overrides[get_redis] = _mock_redis

            from app.auth.dependencies import get_current_user

            async def _mock_current_user():
                return mock_user

            app.dependency_overrides[get_current_user] = _mock_current_user

            client = TestClient(app, raise_server_exceptions=False)
            resp = client.post(
                "/api/v2/ai/execute",
                json={"task": "project_builder", "payload": {"technical_task": "test"}},
                headers={"Authorization": "Bearer fake-jwt-token"},
            )
            self.assertEqual(resp.status_code, 200)
            body = resp.json()
            self.assertEqual(body["status"], "ok")
            self.assertEqual(body["origin"], "gemini")
            self.assertEqual(body["tokens"], 42)
            self.assertIn("content", body)
            self.assertIn("latency_ms", body)

            app.dependency_overrides.clear()


if __name__ == "__main__":
    unittest.main()
