"""A4 tests - estimate lifecycle, media transcription, scenario CRUD, ai-admin, degradation.

Run:
  cd "/home/joker/RIAD CRM" && python -m pytest tests/a4/test_a4_session.py -v
"""

import asyncio
import os
import sys
import unittest
from unittest.mock import AsyncMock, MagicMock, patch

_services_root = os.path.join(os.path.dirname(__file__), "..", "..", "services", "security-api")
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)

_erpnext_root = os.path.join(os.path.dirname(__file__), "..", "..", "erpnext", "security_erp")
if os.path.isdir(_erpnext_root):
    sys.path.insert(0, _erpnext_root)


def _mock_user(frappe_roles=None):
    from app.auth.dependencies import CurrentUser
    from app.auth.permissions import Role
    return CurrentUser(
        user_id="test@test.com",
        role=Role.SALES_MANAGER,
        frappe_sid="test-sid",
        frappe_roles=frappe_roles or [],
    )


def _make_app_with_overrides(mock_user=None):
    """Returns (app, ctx, client) — ctx is a context manager that must wrap requests."""
    from fastapi.testclient import TestClient
    from app.main import app
    from app.core.redis import get_redis
    from app.auth.dependencies import get_current_user

    if mock_user is None:
        mock_user = _mock_user()

    mock_redis_instance = AsyncMock()
    mock_redis_instance.incr = AsyncMock(return_value=1)
    mock_redis_instance.expire = AsyncMock()

    async def _mock_redis():
        return mock_redis_instance

    async def _mock_current_user():
        return mock_user

    app.dependency_overrides[get_redis] = _mock_redis
    app.dependency_overrides[get_current_user] = _mock_current_user

    from contextlib import ExitStack
    ctx = ExitStack()
    ctx.enter_context(patch("app.core.redis.get_redis", side_effect=_mock_redis))
    ctx.enter_context(patch("app.core.redis.redis_client", mock_redis_instance))
    client = TestClient(app, raise_server_exceptions=False)
    return app, ctx, client


# ── Estimate Build ──────────────────────────────────────────────────────────


class TestEstimateBuildSync(unittest.IsolatedAsyncioTestCase):
    async def test_sync_estimate_build_creates_estimate(self):
        from app.services.estimate_service import build_estimate

        mock_site_brief = {"data": {"brief_name": "Test Brief", "security_type": "CCTV", "brief_text": "8 cameras"}}
        mock_estimate_created = {"data": {"name": "EST-TEST-001"}}
        mock_result = {
            "status": "ok",
            "content": '{"items": [{"item_code": "CAM-1", "qty": 8}]}',
            "tokens": 50,
            "latency_ms": 200.0,
            "origin": "gemini",
        }

        with patch("app.services.estimate_service.frappe_get", new_callable=AsyncMock) as mock_frappe_get, \
             patch("app.services.estimate_service.frappe_post", new_callable=AsyncMock) as mock_frappe_post, \
             patch("app.services.estimate_service.frappe_put", new_callable=AsyncMock) as mock_frappe_put:

            mock_frappe_get.return_value = mock_site_brief
            mock_frappe_post.return_value = mock_estimate_created

            mock_redis = AsyncMock()
            async def _mock_get_redis():
                return mock_redis

            with patch("app.core.redis.get_redis", side_effect=_mock_get_redis), \
                 patch("app.services.estimate_service.asyncio_wait_for", new_callable=AsyncMock) as mock_wait, \
                 patch("app.services.ai_orchestrator_service.write_ai_request_log", new_callable=AsyncMock):
                mock_wait.return_value = mock_result

                result = await build_estimate(
                    sid="test-sid",
                    site_brief_name="Test Brief",
                    variant="optimal",
                    user_id="test@test.com",
                )

        self.assertEqual(result["name"], "EST-TEST-001")
        self.assertEqual(result["origin"], "ai_primary")


class TestEstimateBuildRQEnqueue(unittest.IsolatedAsyncioTestCase):
    async def test_timeout_enqueues_rq(self):
        from app.services.estimate_service import build_estimate

        mock_site_brief = {"data": {"brief_name": "Test Brief", "security_type": "CCTV", "brief_text": "8 cameras"}}
        mock_estimate_created = {"data": {"name": "EST-TEST-002"}}

        with patch("app.services.estimate_service.frappe_get", new_callable=AsyncMock) as mock_frappe_get, \
             patch("app.services.estimate_service.frappe_post", new_callable=AsyncMock) as mock_frappe_post:

            mock_frappe_get.return_value = mock_site_brief
            mock_frappe_post.return_value = mock_estimate_created

            mock_redis = AsyncMock()
            async def _mock_get_redis():
                return mock_redis

            with patch("app.core.redis.get_redis", side_effect=_mock_get_redis), \
                 patch("app.services.estimate_service.asyncio_wait_for", new_callable=AsyncMock) as mock_wait:

                async def _slow_wait(*args, **kwargs):
                    await asyncio.sleep(10)
                    return {}

                mock_wait.side_effect = _slow_wait

                result = await build_estimate(
                    sid="test-sid",
                    site_brief_name="Test Brief",
                    variant="optimal",
                    user_id="test@test.com",
                )

        self.assertEqual(result["name"], "EST-TEST-002")
        self.assertEqual(result["status"], "pending")


# ── Estimate Review ─────────────────────────────────────────────────────────


class TestEstimateReview(unittest.IsolatedAsyncioTestCase):
    async def test_review_approved_sets_status_and_reviewed_by(self):
        from app.services.estimate_service import review_estimate

        mock_estimate = {"data": {"name": "EST-TEST-001", "origin": "ai_primary", "ai_result": '{"items":[]}'}}

        with patch("app.services.estimate_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.estimate_service.frappe_put", new_callable=AsyncMock) as mock_put:
            mock_get.return_value = mock_estimate

            result = await review_estimate(
                sid="test-sid",
                name="EST-TEST-001",
                decision="approved",
                user_id="test@test.com",
            )

        self.assertEqual(result["status"], "Approved")
        self.assertEqual(result["reviewed_by"], "test@test.com")
        mock_put.assert_awaited_once()
        put_data = mock_put.call_args.kwargs.get("data") or mock_put.call_args[1].get("data")
        self.assertEqual(put_data["status"], "Approved")
        self.assertEqual(put_data["reviewed_by"], "test@test.com")

    async def test_review_rejected(self):
        from app.services.estimate_service import review_estimate

        mock_estimate = {"data": {"name": "EST-TEST-001", "origin": "ai_primary", "ai_result": '{"items":[]}'}}

        with patch("app.services.estimate_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.estimate_service.frappe_put", new_callable=AsyncMock) as mock_put:
            mock_get.return_value = mock_estimate

            result = await review_estimate(
                sid="test-sid",
                name="EST-TEST-001",
                decision="rejected",
                user_id="test@test.com",
            )

        self.assertEqual(result["status"], "Rejected")

    async def test_review_manual_origin_raises_validation(self):
        from app.services.estimate_service import review_estimate

        mock_estimate = {"data": {"name": "EST-TEST-003", "origin": "manual", "ai_result": ""}}

        with patch("app.services.estimate_service.frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_estimate

            with self.assertRaises(ValueError) as ctx:
                await review_estimate(
                    sid="test-sid",
                    name="EST-TEST-003",
                    decision="approved",
                    user_id="test@test.com",
                )
            self.assertIn("RIAD-VALIDATION", str(ctx.exception))


# ── Estimate Confirm ────────────────────────────────────────────────────────


class TestEstimateConfirm(unittest.IsolatedAsyncioTestCase):
    async def test_confirm_approved_with_reviewed_by_creates_quotation(self):
        from app.services.estimate_service import confirm_estimate

        mock_estimate = {"data": {"name": "EST-TEST-001", "status": "Approved", "reviewed_by": "test@test.com"}}
        mock_quotation_result = {"message": "QTN-TEST-001"}

        with patch("app.services.estimate_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.estimate_service.frappe_post", new_callable=AsyncMock) as mock_post:
            mock_get.return_value = mock_estimate
            mock_post.return_value = mock_quotation_result

            result = await confirm_estimate(sid="test-sid", name="EST-TEST-001")

        self.assertEqual(result["quotation_name"], "QTN-TEST-001")

    async def test_confirm_without_reviewed_by_raises_validation(self):
        from app.services.estimate_service import confirm_estimate

        mock_estimate = {"data": {"name": "EST-TEST-004", "status": "Approved", "reviewed_by": ""}}

        with patch("app.services.estimate_service.frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_estimate

            with self.assertRaises(ValueError) as ctx:
                await confirm_estimate(sid="test-sid", name="EST-TEST-004")
            self.assertIn("RIAD-VALIDATION", str(ctx.exception))

    async def test_confirm_wrong_status_raises_validation(self):
        from app.services.estimate_service import confirm_estimate

        mock_estimate = {"data": {"name": "EST-TEST-005", "status": "Draft", "reviewed_by": "test@test.com"}}

        with patch("app.services.estimate_service.frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = mock_estimate

            with self.assertRaises(ValueError) as ctx:
                await confirm_estimate(sid="test-sid", name="EST-TEST-005")
            self.assertIn("RIAD-VALIDATION", str(ctx.exception))


# ── Estimate Endpoints ──────────────────────────────────────────────────────


class TestEstimateEndpoints(unittest.IsolatedAsyncioTestCase):
    async def test_build_endpoint_returns_response(self):
        from app.main import app
        from app.core.redis import get_redis
        from app.auth.dependencies import get_current_user

        mock_user = _mock_user()
        mock_redis_instance = AsyncMock()
        mock_redis_instance.incr = AsyncMock(return_value=1)
        mock_redis_instance.expire = AsyncMock()

        async def _mock_redis():
            return mock_redis_instance

        async def _mock_current_user():
            return mock_user

        app.dependency_overrides[get_redis] = _mock_redis
        app.dependency_overrides[get_current_user] = _mock_current_user

        with patch("app.core.redis.get_redis", side_effect=_mock_redis), \
             patch("app.routes.estimates.build_estimate", new_callable=AsyncMock) as mock_build:
            mock_build.return_value = {"name": "EST-EP-001", "status": "ai_primary", "origin": "ai_primary"}

            from fastapi.testclient import TestClient
            client = TestClient(app, raise_server_exceptions=False)
            resp = client.post(
                "/api/v2/estimates/build",
                json={"site_brief_name": "Brief-1", "variant": "optimal"},
                headers={"Authorization": "Bearer fake-token"},
            )

        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(body["name"], "EST-EP-001")
        self.assertEqual(body["status"], "ai_primary")
        app.dependency_overrides.clear()

    async def test_review_endpoint_validation_error(self):
        from app.main import app
        from app.core.redis import get_redis
        from app.auth.dependencies import get_current_user

        mock_user = _mock_user()
        mock_redis_instance = AsyncMock()
        mock_redis_instance.incr = AsyncMock(return_value=1)
        mock_redis_instance.expire = AsyncMock()

        async def _mock_redis():
            return mock_redis_instance

        async def _mock_current_user():
            return mock_user

        app.dependency_overrides[get_redis] = _mock_redis
        app.dependency_overrides[get_current_user] = _mock_current_user

        with patch("app.core.redis.get_redis", side_effect=_mock_redis), \
             patch("app.routes.estimates.review_estimate", new_callable=AsyncMock) as mock_review:
            mock_review.side_effect = ValueError("RIAD-VALIDATION: estimate must be AI-generated")

            from fastapi.testclient import TestClient
            client = TestClient(app, raise_server_exceptions=False)
            resp = client.post(
                "/api/v2/estimates/EST-TEST/review",
                json={"decision": "approved"},
                headers={"Authorization": "Bearer fake-token"},
            )

        self.assertEqual(resp.status_code, 422)
        app.dependency_overrides.clear()


# ── Media Transcription ─────────────────────────────────────────────────────


class TestMediaTranscribe(unittest.IsolatedAsyncioTestCase):
    async def test_transcribe_enqueues_rq(self):
        from app.main import app
        from app.core.redis import get_redis
        from app.auth.dependencies import get_current_user

        mock_user = _mock_user()
        mock_redis_instance = AsyncMock()
        mock_redis_instance.incr = AsyncMock(return_value=1)
        mock_redis_instance.expire = AsyncMock()

        async def _mock_redis():
            return mock_redis_instance

        async def _mock_current_user():
            return mock_user

        app.dependency_overrides[get_redis] = _mock_redis
        app.dependency_overrides[get_current_user] = _mock_current_user

        with patch("app.core.redis.get_redis", side_effect=_mock_redis), \
             patch("app.services.media_service.enqueue_transcription", new_callable=AsyncMock) as mock_enqueue:
            mock_enqueue.return_value = None

            from fastapi.testclient import TestClient
            client = TestClient(app, raise_server_exceptions=False)
            resp = client.post(
                "/api/v2/media/MEDIA-001/transcribe",
                headers={"Authorization": "Bearer fake-token"},
            )

        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()["status"], "queued")
        app.dependency_overrides.clear()

    async def test_transcription_manual_writes_text(self):
        from app.main import app
        from app.core.redis import get_redis
        from app.auth.dependencies import get_current_user

        mock_user = _mock_user()
        mock_redis_instance = AsyncMock()
        mock_redis_instance.incr = AsyncMock(return_value=1)
        mock_redis_instance.expire = AsyncMock()

        async def _mock_redis():
            return mock_redis_instance

        async def _mock_current_user():
            return mock_user

        app.dependency_overrides[get_redis] = _mock_redis
        app.dependency_overrides[get_current_user] = _mock_current_user

        with patch("app.core.redis.get_redis", side_effect=_mock_redis), \
             patch("app.services.media_service.save_manual_transcription", new_callable=AsyncMock) as mock_save:
            mock_save.return_value = None

            from fastapi.testclient import TestClient
            client = TestClient(app, raise_server_exceptions=False)
            resp = client.post(
                "/api/v2/media/MEDIA-002/transcription",
                json={"text": "Manual transcription text"},
                headers={"Authorization": "Bearer fake-token"},
            )

        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()["status"], "manual")
        mock_save.assert_awaited_once()
        save_kwargs = mock_save.call_args.kwargs
        self.assertEqual(save_kwargs["text"], "Manual transcription text")
        self.assertEqual(save_kwargs["name"], "MEDIA-002")
        app.dependency_overrides.clear()


# ── Scenario CRUD + Role Gate ───────────────────────────────────────────────


class TestScenarioRoleGate(unittest.IsolatedAsyncioTestCase):
    async def test_no_role_returns_403(self):
        mock_user = _mock_user(frappe_roles=[])
        app, ctx, client = _make_app_with_overrides(mock_user)

        with ctx:
            resp = client.get(
                "/api/v2/scenarios",
                headers={"Authorization": "Bearer fake-token"},
            )
        self.assertEqual(resp.status_code, 403)
        body = resp.json()
        self.assertIn("RIAD-PERM-DENIED", str(body))
        app.dependency_overrides.clear()

    async def test_scenario_admin_role_passes(self):
        mock_user = _mock_user(frappe_roles=["RIAD Scenario Admin"])
        app, ctx, client = _make_app_with_overrides(mock_user)

        with ctx, \
             patch("app.routes.scenarios.frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = {"data": [
                {"name": "SC-001", "scenario_name": "CCTV Basic", "description": "8 cameras"}
            ]}

            resp = client.get(
                "/api/v2/scenarios",
                headers={"Authorization": "Bearer fake-token"},
            )

        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(len(body["scenarios"]), 1)
        self.assertEqual(body["scenarios"][0]["name"], "SC-001")
        app.dependency_overrides.clear()

    async def test_system_manager_role_passes(self):
        mock_user = _mock_user(frappe_roles=["System Manager"])
        app, ctx, client = _make_app_with_overrides(mock_user)

        with ctx, \
             patch("app.routes.scenarios.frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = {"data": []}

            resp = client.get(
                "/api/v2/scenarios",
                headers={"Authorization": "Bearer fake-token"},
            )

        self.assertEqual(resp.status_code, 200)
        app.dependency_overrides.clear()

    async def test_get_scenario_with_items(self):
        mock_user = _mock_user(frappe_roles=["RIAD Scenario Admin"])
        app, ctx, client = _make_app_with_overrides(mock_user)

        with ctx, \
             patch("app.routes.scenarios.frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.side_effect = [
                {"data": {"name": "SC-001", "scenario_name": "CCTV Basic"}},
                {"data": [{"item_code": "CAM-1", "qty": 8, "qty_rule": "per_camera"}]},
            ]

            resp = client.get(
                "/api/v2/scenarios/SC-001",
                headers={"Authorization": "Bearer fake-token"},
            )

        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(len(body["items"]), 1)
        app.dependency_overrides.clear()

    async def test_upsert_scenario_create(self):
        mock_user = _mock_user(frappe_roles=["RIAD Scenario Admin"])
        app, ctx, client = _make_app_with_overrides(mock_user)

        with ctx, \
             patch("app.routes.scenarios.frappe_post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = {"data": {"name": "SC-NEW"}}

            resp = client.post(
                "/api/v2/scenarios",
                json={"scenario_name": "New Scenario", "description": "desc"},
                headers={"Authorization": "Bearer fake-token"},
            )

        self.assertEqual(resp.status_code, 200)
        app.dependency_overrides.clear()


# ── AI Admin + Role Gate ────────────────────────────────────────────────────


class TestAIAdminRoleGate(unittest.IsolatedAsyncioTestCase):
    async def test_no_role_returns_403(self):
        mock_user = _mock_user(frappe_roles=[])
        app, ctx, client = _make_app_with_overrides(mock_user)

        with ctx:
            resp = client.get(
                "/api/v2/ai-admin/providers",
                headers={"Authorization": "Bearer fake-token"},
            )
        self.assertEqual(resp.status_code, 403)
        app.dependency_overrides.clear()

    async def test_ai_admin_role_passes(self):
        mock_user = _mock_user(frappe_roles=["RIAD AI Admin"])
        app, ctx, client = _make_app_with_overrides(mock_user)

        with ctx, \
             patch("app.services.ai_admin_service.list_providers", new_callable=AsyncMock) as mock_list:
            mock_list.return_value = [
                {"name": "AI Provider-gemini", "provider_name": "gemini", "priority": 1, "is_enabled": True, "health_status": "healthy"}
            ]

            resp = client.get(
                "/api/v2/ai-admin/providers",
                headers={"Authorization": "Bearer fake-token"},
            )

        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(len(body), 1)
        self.assertEqual(body[0]["provider_name"], "gemini")
        app.dependency_overrides.clear()

    async def test_request_logs_endpoint(self):
        mock_user = _mock_user(frappe_roles=["RIAD AI Admin"])
        app, ctx, client = _make_app_with_overrides(mock_user)

        with ctx, \
             patch("app.services.ai_admin_service.list_request_logs", new_callable=AsyncMock) as mock_list:
            mock_list.return_value = {
                "logs": [
                    {"name": "AILOG-001", "anonymized_payload": "{'task':'project_builder'}", "provider": "gemini", "latency_ms": 150, "tokens": 42, "status": "ok", "error_message": "", "creation": "2026-06-22 10:00:00"}
                ],
                "total": 1,
            }

            resp = client.get(
                "/api/v2/ai-admin/request-logs",
                headers={"Authorization": "Bearer fake-token"},
            )

        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(body["total"], 1)
        self.assertEqual(body["logs"][0]["name"], "AILOG-001")
        app.dependency_overrides.clear()


# ── AI Degradation Endpoint ─────────────────────────────────────────────────


class TestAIDegradation(unittest.IsolatedAsyncioTestCase):
    async def test_all_closed_returns_primary(self):
        from fastapi.testclient import TestClient
        from app.main import app
        from app.core.redis import get_redis
        from app.auth.dependencies import get_current_user

        mock_user = _mock_user()
        mock_redis = AsyncMock()
        mock_redis.hgetall = AsyncMock(return_value={"state": "closed", "failures": "0"})
        mock_redis.incr = AsyncMock(return_value=1)
        mock_redis.expire = AsyncMock()

        async def _mock_redis():
            return mock_redis

        async def _mock_current_user():
            return mock_user

        app.dependency_overrides[get_redis] = _mock_redis
        app.dependency_overrides[get_current_user] = _mock_current_user

        with patch("app.core.redis.get_redis", side_effect=_mock_redis), \
             patch("app.routes.ai.get_provider_degradation", new_callable=AsyncMock) as mock_get_degradation:
            mock_get_degradation.return_value = [
                {"name": "AI Provider-gemini", "provider_name": "gemini", "health_status": "healthy", "priority": 1},
                {"name": "AI Provider-stub", "provider_name": "stub", "health_status": "healthy", "priority": 2},
            ]
            client = TestClient(app, raise_server_exceptions=False)
            resp = client.get("/api/v2/ai/degradation")

        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(body["level"], "primary")
        self.assertEqual(len(body["providers"]), 2)
        app.dependency_overrides.clear()

    async def test_one_half_open_returns_fallback(self):
        from fastapi.testclient import TestClient
        from app.main import app
        from app.core.redis import get_redis
        from app.auth.dependencies import get_current_user

        mock_user = _mock_user()
        mock_redis = AsyncMock()
        mock_redis.hgetall = AsyncMock(return_value={"state": "half_open", "failures": "0"})
        mock_redis.incr = AsyncMock(return_value=1)
        mock_redis.expire = AsyncMock()

        async def _mock_redis():
            return mock_redis

        async def _mock_current_user():
            return mock_user

        app.dependency_overrides[get_redis] = _mock_redis
        app.dependency_overrides[get_current_user] = _mock_current_user

        with patch("app.core.redis.get_redis", side_effect=_mock_redis), \
             patch("app.routes.ai.get_provider_degradation", new_callable=AsyncMock) as mock_get_degradation:
            mock_get_degradation.return_value = [
                {"name": "AI Provider-gemini", "provider_name": "gemini", "health_status": "healthy", "priority": 1},
                {"name": "AI Provider-stub", "provider_name": "stub", "health_status": "healthy", "priority": 2},
            ]
            client = TestClient(app, raise_server_exceptions=False)
            resp = client.get("/api/v2/ai/degradation")

        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(body["level"], "fallback")
        self.assertIn("резервний", body["message"].lower())
        app.dependency_overrides.clear()

    async def test_all_open_returns_manual(self):
        from fastapi.testclient import TestClient
        from app.main import app
        from app.core.redis import get_redis
        from app.auth.dependencies import get_current_user

        mock_user = _mock_user()
        mock_redis = AsyncMock()
        mock_redis.hgetall = AsyncMock(return_value={"state": "open", "failures": "5"})
        mock_redis.incr = AsyncMock(return_value=1)
        mock_redis.expire = AsyncMock()

        async def _mock_redis():
            return mock_redis

        async def _mock_current_user():
            return mock_user

        app.dependency_overrides[get_redis] = _mock_redis
        app.dependency_overrides[get_current_user] = _mock_current_user

        with patch("app.core.redis.get_redis", side_effect=_mock_redis), \
             patch("app.core.database.frappe_get", new_callable=AsyncMock) as mock_frappe_get:
            mock_frappe_get.return_value = {"data": [
                {"name": "AI Provider-gemini", "provider_name": "gemini", "health_status": "healthy", "priority": 1},
                {"name": "AI Provider-stub", "provider_name": "stub", "health_status": "healthy", "priority": 2},
            ]}
            client = TestClient(app, raise_server_exceptions=False)
            resp = client.get("/api/v2/ai/degradation")

        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(body["level"], "manual")
        self.assertIn("ручний", body["message"].lower())
        app.dependency_overrides.clear()


# ── JWT frappe_roles ────────────────────────────────────────────────────────


class TestFrappeRolesInJWT(unittest.TestCase):
    def test_frappe_roles_in_token_payload(self):
        from app.auth.jwt import create_access_token, decode_token

        token = create_access_token("user@test.com", "viewer", frappe_roles=["RIAD Scenario Admin", "Desk User"])
        payload = decode_token(token)
        self.assertIn("frappe_roles", payload)
        self.assertEqual(payload["frappe_roles"], ["RIAD Scenario Admin", "Desk User"])

    def test_no_frappe_roles_omitted(self):
        from app.auth.jwt import create_access_token, decode_token

        token = create_access_token("user@test.com", "viewer")
        payload = decode_token(token)
        self.assertNotIn("frappe_roles", payload)

    def test_current_user_has_frappe_role(self):
        from app.auth.dependencies import CurrentUser
        from app.auth.permissions import Role

        user = CurrentUser("u@t.com", Role.VIEWER, "sid", frappe_roles=["RIAD AI Admin", "Desk User"])
        self.assertTrue(user.has_frappe_role("RIAD AI Admin"))
        self.assertFalse(user.has_frappe_role("RIAD Scenario Admin"))

    def test_current_user_empty_roles(self):
        from app.auth.dependencies import CurrentUser
        from app.auth.permissions import Role

        user = CurrentUser("u@t.com", Role.VIEWER, "sid")
        self.assertFalse(user.has_frappe_role("System Manager"))


if __name__ == "__main__":
    unittest.main()
