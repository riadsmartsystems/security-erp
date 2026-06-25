"""E5 Estimate confirm → Quotation integration tests.

Tests estimate_service.py business logic:
- confirm_estimate(): status=Approved + reviewed_by → create_quotation
- review_estimate(): origin!=manual + ai_result non-empty → sets reviewed_by + status
- Full lifecycle: review → confirm → quotation

TDD: each test verified to FAIL before GREEN.

Run:
    cd "/home/joker/RIAD CRM"
    python3 -m pytest tests/e5/test_e5_estimate_confirm.py -v
"""

import asyncio
import os
import sys
import unittest
from unittest.mock import AsyncMock, patch

_services_root = os.path.join(
    os.path.dirname(__file__), "..", "..", "services", "security-api"
)
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)


def _run(coro):
    """Run async coroutine in sync test context."""
    loop = asyncio.new_event_loop()
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


def _est_data(*, name="EST-001", status="Draft", reviewed_by="", origin="ai_primary",
              ai_result="some ai content"):
    """Build a realistic Frappe AI Estimate data dict."""
    return {
        "data": {
            "name": name,
            "status": status,
            "reviewed_by": reviewed_by,
            "origin": origin,
            "ai_result": ai_result,
        }
    }


# ── confirm_estimate tests ──────────────────────────────────────────────

class TestConfirmEstimate(unittest.TestCase):
    """confirm_estimate(): hard boundary — status=Approved AND reviewed_by."""

    def test_approved_with_reviewed_by_creates_quotation(self):
        from app.services.estimate_service import confirm_estimate

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get, \
             patch("app.services.estimate_service.frappe_post",
                    new_callable=AsyncMock) as mock_post:
            mock_get.return_value = _est_data(
                status="Approved", reviewed_by="eng@riad.fun"
            )
            mock_post.return_value = {"message": "QTN-001"}

            result = _run(confirm_estimate(sid="test-sid", name="EST-001"))

            self.assertEqual(result["quotation_name"], "QTN-001")
            mock_post.assert_called_once()
            call_path = mock_post.call_args[0][0]
            self.assertIn("create_quotation", call_path)
            self.assertEqual(mock_post.call_args[1]["sid"], "test-sid")

    def test_missing_reviewed_by_raises_value_error(self):
        from app.services.estimate_service import confirm_estimate

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get:
            mock_get.return_value = _est_data(
                status="Approved", reviewed_by=""
            )

            with self.assertRaises(ValueError) as ctx:
                _run(confirm_estimate(sid="s", name="EST-002"))
            msg = str(ctx.exception)
            self.assertIn("RIAD-VALIDATION", msg)
            self.assertIn("approved and reviewed", msg)

    def test_draft_status_raises_value_error(self):
        from app.services.estimate_service import confirm_estimate

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get:
            mock_get.return_value = _est_data(
                status="Draft", reviewed_by="eng@riad.fun"
            )

            with self.assertRaises(ValueError) as ctx:
                _run(confirm_estimate(sid="s", name="EST-003"))
            msg = str(ctx.exception)
            self.assertIn("RIAD-VALIDATION", msg)

    def test_rejected_status_raises_value_error(self):
        from app.services.estimate_service import confirm_estimate

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get:
            mock_get.return_value = _est_data(
                status="Rejected", reviewed_by=""
            )

            with self.assertRaises(ValueError) as ctx:
                _run(confirm_estimate(sid="s", name="EST-004"))
            msg = str(ctx.exception)
            self.assertIn("RIAD-VALIDATION", msg)

    def test_empty_string_status_raises_value_error(self):
        from app.services.estimate_service import confirm_estimate

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get:
            mock_get.return_value = _est_data(status="", reviewed_by="")

            with self.assertRaises(ValueError):
                _run(confirm_estimate(sid="s", name="EST-005"))


# ── review_estimate tests ───────────────────────────────────────────────

class TestReviewEstimate(unittest.TestCase):
    """review_estimate(): must be AI-generated (origin!=manual, ai_result≠empty)."""

    def test_approved_sets_reviewed_by_and_status(self):
        from app.services.estimate_service import review_estimate

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get, \
             patch("app.services.estimate_service.frappe_put",
                    new_callable=AsyncMock) as mock_put:
            mock_get.return_value = _est_data(origin="ai_primary", ai_result="test")
            mock_put.return_value = {"data": {}}

            result = _run(review_estimate(
                sid="s", name="EST-010",
                decision="approved", user_id="eng@riad.fun"
            ))

            self.assertEqual(result["status"], "Approved")
            self.assertEqual(result["reviewed_by"], "eng@riad.fun")
            self.assertEqual(result["name"], "EST-010")

    def test_rejected_sets_status_rejected(self):
        from app.services.estimate_service import review_estimate

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get, \
             patch("app.services.estimate_service.frappe_put",
                    new_callable=AsyncMock) as mock_put:
            mock_get.return_value = _est_data(origin="ai_fallback", ai_result="ok")
            mock_put.return_value = {"data": {}}

            result = _run(review_estimate(
                sid="s", name="EST-011",
                decision="rejected", user_id="mgr@riad.fun"
            ))

            self.assertEqual(result["status"], "Rejected")
            self.assertEqual(result["reviewed_by"], "mgr@riad.fun")

    def test_manual_origin_raises_value_error(self):
        from app.services.estimate_service import review_estimate

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get:
            mock_get.return_value = _est_data(origin="manual", ai_result="test")

            with self.assertRaises(ValueError) as ctx:
                _run(review_estimate(
                    sid="s", name="EST-012",
                    decision="approved", user_id="eng@riad.fun"
                ))
            msg = str(ctx.exception)
            self.assertIn("RIAD-VALIDATION", msg)
            self.assertIn("AI-generated", msg)

    def test_empty_ai_result_raises_value_error(self):
        from app.services.estimate_service import review_estimate

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get:
            mock_get.return_value = _est_data(origin="ai_primary", ai_result="")

            with self.assertRaises(ValueError) as ctx:
                _run(review_estimate(
                    sid="s", name="EST-013",
                    decision="approved", user_id="eng@riad.fun"
                ))
            msg = str(ctx.exception)
            self.assertIn("RIAD-VALIDATION", msg)
            self.assertIn("ai_result", msg)

    def test_both_manual_and_empty_raises_value_error(self):
        from app.services.estimate_service import review_estimate

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get:
            mock_get.return_value = _est_data(origin="manual", ai_result="")

            with self.assertRaises(ValueError) as ctx:
                _run(review_estimate(
                    sid="s", name="EST-014",
                    decision="approved", user_id="eng@riad.fun"
                ))
            msg = str(ctx.exception)
            self.assertIn("RIAD-VALIDATION", msg)

    def test_frappe_put_called_with_correct_data(self):
        from app.services.estimate_service import review_estimate

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get, \
             patch("app.services.estimate_service.frappe_put",
                    new_callable=AsyncMock) as mock_put:
            mock_get.return_value = _est_data(origin="ai_primary", ai_result="content")
            mock_put.return_value = {"data": {}}

            _run(review_estimate(
                sid="test-sid", name="EST-015",
                decision="approved", user_id="eng@riad.fun"
            ))

            mock_put.assert_called_once()
            put_path = mock_put.call_args[0][0]
            self.assertIn("EST-015", put_path)
            put_data = mock_put.call_args[1]["data"]
            self.assertEqual(put_data["status"], "Approved")
            self.assertEqual(put_data["reviewed_by"], "eng@riad.fun")
            self.assertEqual(mock_put.call_args[1]["sid"], "test-sid")


# ── E2E lifecycle ───────────────────────────────────────────────────────

class TestEstimateLifecycle(unittest.TestCase):
    """End-to-end: review → confirm → quotation. Shared mutable state."""

    def test_full_review_confirm_cycle(self):
        from app.services.estimate_service import confirm_estimate, review_estimate

        est = {
            "name": "EST-L1",
            "status": "Draft",
            "reviewed_by": "",
            "origin": "ai_primary",
            "ai_result": '{"items": [{"name": "cam"}]}',
        }

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get, \
             patch("app.services.estimate_service.frappe_put",
                    new_callable=AsyncMock) as mock_put, \
             patch("app.services.estimate_service.frappe_post",
                    new_callable=AsyncMock) as mock_post:

            def fake_get(path, sid=""):
                return {"data": dict(est)}

            def fake_put(path, data=None, sid=""):
                est.update(data)
                return {"data": {}}

            mock_get.side_effect = fake_get
            mock_put.side_effect = fake_put
            mock_post.return_value = {"message": "QTN-L1"}

            # Step 1: review (Draft → Approved)
            review_res = _run(review_estimate(
                sid="s", name="EST-L1",
                decision="approved", user_id="eng@riad.fun"
            ))
            self.assertEqual(review_res["status"], "Approved")
            self.assertEqual(est["status"], "Approved")
            self.assertEqual(est["reviewed_by"], "eng@riad.fun")

            # Step 2: confirm (Approved + reviewed_by → Quotation)
            confirm_res = _run(confirm_estimate(sid="s", name="EST-L1"))
            self.assertEqual(confirm_res["quotation_name"], "QTN-L1")
            mock_post.assert_called_once()

    def test_reject_then_confirm_fails(self):
        """Rejected estimate cannot be confirmed."""
        from app.services.estimate_service import confirm_estimate, review_estimate

        est = {
            "name": "EST-L2",
            "status": "Draft",
            "reviewed_by": "",
            "origin": "ai_primary",
            "ai_result": "content",
        }

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get, \
             patch("app.services.estimate_service.frappe_put",
                    new_callable=AsyncMock) as mock_put:

            def fake_get(path, sid=""):
                return {"data": dict(est)}

            def fake_put(path, data=None, sid=""):
                est.update(data)
                return {"data": {}}

            mock_get.side_effect = fake_get
            mock_put.side_effect = fake_put

            # Step 1: reject
            _run(review_estimate(
                sid="s", name="EST-L2",
                decision="rejected", user_id="mgr@riad.fun"
            ))
            self.assertEqual(est["status"], "Rejected")

            # Step 2: confirm should fail (status=Rejected)
            with self.assertRaises(ValueError):
                _run(confirm_estimate(sid="s", name="EST-L2"))

    def test_manual_estimate_blocks_review(self):
        """origin=manual cannot pass review → cannot reach Approved."""
        from app.services.estimate_service import review_estimate

        with patch("app.services.estimate_service.frappe_get",
                    new_callable=AsyncMock) as mock_get:
            mock_get.return_value = _est_data(
                origin="manual", ai_result="manual content"
            )

            with self.assertRaises(ValueError) as ctx:
                _run(review_estimate(
                    sid="s", name="EST-M1",
                    decision="approved", user_id="eng@riad.fun"
                ))
            self.assertIn("AI-generated", str(ctx.exception))


# ── Integration: route layer error handling ─────────────────────────────

def _setup_app_overrides():
    """Set up app.dependency_overrides for get_current_user + get_redis."""
    from app.main import app
    from app.core.redis import get_redis
    from app.auth.dependencies import get_current_user, CurrentUser

    mock_user = CurrentUser(
        user_id="eng@riad.fun",
        role="engineer",
        frappe_sid="fake-sid",
        frappe_roles=["Engineer"],
    )

    mock_redis_instance = AsyncMock()
    mock_redis_instance.incr = AsyncMock(return_value=1)
    mock_redis_instance.expire = AsyncMock()

    async def _mock_redis():
        return mock_redis_instance

    async def _mock_current_user():
        return mock_user

    app.dependency_overrides[get_redis] = _mock_redis
    app.dependency_overrides[get_current_user] = _mock_current_user

    return app, mock_redis_instance


class TestRouteLayerErrorMapping(unittest.TestCase):
    """Verify routes/estimates.py correctly maps ValueError → HTTP 422."""

    def test_confirm_value_error_returns_422(self):
        """Route catches ValueError with RIAD-VALIDATION and returns 422."""
        app, _ = _setup_app_overrides()
        from fastapi.testclient import TestClient

        client = TestClient(app, raise_server_exceptions=False)

        with patch("app.services.estimate_service.frappe_get",
                   new_callable=AsyncMock) as mock_get:
            mock_get.return_value = _est_data(
                status="Draft", reviewed_by=""
            )
            resp = client.post(
                "/api/v2/estimates/EST-BAD/confirm",
                headers={"Authorization": "Bearer fake-token"},
            )
            self.assertEqual(resp.status_code, 422)
            body = resp.json()
            self.assertIn("RIAD-VALIDATION", body["detail"]["code"])

        from app.main import app as _app
        _app.dependency_overrides.clear()

    def test_review_value_error_returns_422(self):
        """Route catches ValueError with RIAD-VALIDATION and returns 422."""
        app, _ = _setup_app_overrides()
        from fastapi.testclient import TestClient

        client = TestClient(app, raise_server_exceptions=False)

        with patch("app.services.estimate_service.frappe_get",
                   new_callable=AsyncMock) as mock_get:
            mock_get.return_value = _est_data(
                origin="manual", ai_result="x"
            )
            resp = client.post(
                "/api/v2/estimates/EST-M2/review",
                json={"decision": "approved"},
                headers={"Authorization": "Bearer fake-token"},
            )
            self.assertEqual(resp.status_code, 422)
            body = resp.json()
            self.assertIn("RIAD-VALIDATION", body["detail"]["code"])

        from app.main import app as _app
        _app.dependency_overrides.clear()


if __name__ == "__main__":
    unittest.main()
