"""E5 Estimate confirm → Quotation integration tests.

Tests the estimate lifecycle: review_estimate (sets reviewed_by + status)
and confirm_estimate (creates Quotation from Approved estimate).

Key invariants:
- confirm_estimate requires status=Approved AND reviewed_by present
- review_estimate requires origin!=manual AND ai_result non-empty
- confirm_estimate calls frappe_post to create Quotation

Run:
    cd "/home/joker/RIAD CRM"
    python -m pytest tests/e5/test_e5_estimate_confirm.py -v
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
    loop = asyncio.new_event_loop()
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


class TestEstimateConfirm(unittest.TestCase):
    """Tests for confirm_estimate() → Quotation creation."""

    def test_confirm_with_reviewed_by_creates_quotation(self):
        from app.services.estimate_service import confirm_estimate

        with patch(
            "app.services.estimate_service.frappe_get", new_callable=AsyncMock
        ) as mock_get, patch(
            "app.services.estimate_service.frappe_post", new_callable=AsyncMock
        ) as mock_post:
            mock_get.return_value = {
                "data": {
                    "name": "EST-001",
                    "status": "Approved",
                    "reviewed_by": "eng@riad.fun",
                    "ai_result": "test",
                }
            }
            mock_post.return_value = {"message": "QTN-001"}

            result = _run(confirm_estimate(sid="sid", name="EST-001"))

            self.assertEqual(result["quotation_name"], "QTN-001")
            mock_post.assert_called_once()
            call_args = mock_post.call_args
            self.assertIn("create_quotation", call_args[0][0])

    def test_confirm_without_reviewed_by_raises(self):
        from app.services.estimate_service import confirm_estimate

        with patch(
            "app.services.estimate_service.frappe_get", new_callable=AsyncMock
        ) as mock_get:
            mock_get.return_value = {
                "data": {
                    "name": "EST-002",
                    "status": "Approved",
                    "reviewed_by": "",
                    "ai_result": "test",
                }
            }

            with self.assertRaises(ValueError) as ctx:
                _run(confirm_estimate(sid="sid", name="EST-002"))

            self.assertIn(
                "estimate must be approved and reviewed before confirmation",
                str(ctx.exception),
            )

    def test_confirm_draft_estimate_raises(self):
        from app.services.estimate_service import confirm_estimate

        with patch(
            "app.services.estimate_service.frappe_get", new_callable=AsyncMock
        ) as mock_get:
            mock_get.return_value = {
                "data": {
                    "name": "EST-003",
                    "status": "Draft",
                    "reviewed_by": "eng@riad.fun",
                    "ai_result": "test",
                }
            }

            with self.assertRaises(ValueError) as ctx:
                _run(confirm_estimate(sid="sid", name="EST-003"))

            self.assertIn(
                "estimate must be approved and reviewed before confirmation",
                str(ctx.exception),
            )

    def test_confirm_neither_approved_nor_reviewed_raises(self):
        from app.services.estimate_service import confirm_estimate

        with patch(
            "app.services.estimate_service.frappe_get", new_callable=AsyncMock
        ) as mock_get:
            mock_get.return_value = {
                "data": {
                    "name": "EST-005",
                    "status": "Rejected",
                    "reviewed_by": "",
                    "ai_result": "",
                }
            }

            with self.assertRaises(ValueError) as ctx:
                _run(confirm_estimate(sid="sid", name="EST-005"))

            self.assertIn("RIAD-VALIDATION", str(ctx.exception))


class TestEstimateReview(unittest.TestCase):
    """Tests for review_estimate() — sets reviewed_by and status."""

    def test_review_sets_reviewed_by_and_status(self):
        from app.services.estimate_service import review_estimate

        with patch(
            "app.services.estimate_service.frappe_get", new_callable=AsyncMock
        ) as mock_get, patch(
            "app.services.estimate_service.frappe_put", new_callable=AsyncMock
        ) as mock_put:
            mock_get.return_value = {
                "data": {
                    "name": "EST-004",
                    "origin": "ai_primary",
                    "ai_result": "test",
                }
            }
            mock_put.return_value = {"data": {}}

            result = _run(
                review_estimate(
                    sid="sid",
                    name="EST-004",
                    decision="approved",
                    user_id="eng@riad.fun",
                )
            )

            self.assertEqual(result["status"], "Approved")
            self.assertEqual(result["reviewed_by"], "eng@riad.fun")

    def test_review_rejected_sets_status(self):
        from app.services.estimate_service import review_estimate

        with patch(
            "app.services.estimate_service.frappe_get", new_callable=AsyncMock
        ) as mock_get, patch(
            "app.services.estimate_service.frappe_put", new_callable=AsyncMock
        ) as mock_put:
            mock_get.return_value = {
                "data": {
                    "name": "EST-006",
                    "origin": "ai_fallback",
                    "ai_result": "some result",
                }
            }
            mock_put.return_value = {"data": {}}

            result = _run(
                review_estimate(
                    sid="sid",
                    name="EST-006",
                    decision="rejected",
                    user_id="manager@riad.fun",
                )
            )

            self.assertEqual(result["status"], "Rejected")
            self.assertEqual(result["reviewed_by"], "manager@riad.fun")

    def test_review_manual_origin_raises(self):
        from app.services.estimate_service import review_estimate

        with patch(
            "app.services.estimate_service.frappe_get", new_callable=AsyncMock
        ) as mock_get:
            mock_get.return_value = {
                "data": {
                    "name": "EST-007",
                    "origin": "manual",
                    "ai_result": "test",
                }
            }

            with self.assertRaises(ValueError) as ctx:
                _run(
                    review_estimate(
                        sid="sid",
                        name="EST-007",
                        decision="approved",
                        user_id="eng@riad.fun",
                    )
                )

            self.assertIn(
                "estimate must be AI-generated with ai_result",
                str(ctx.exception),
            )

    def test_review_empty_ai_result_raises(self):
        from app.services.estimate_service import review_estimate

        with patch(
            "app.services.estimate_service.frappe_get", new_callable=AsyncMock
        ) as mock_get:
            mock_get.return_value = {
                "data": {
                    "name": "EST-008",
                    "origin": "ai_primary",
                    "ai_result": "",
                }
            }

            with self.assertRaises(ValueError) as ctx:
                _run(
                    review_estimate(
                        sid="sid",
                        name="EST-008",
                        decision="approved",
                        user_id="eng@riad.fun",
                    )
                )

            self.assertIn(
                "estimate must be AI-generated with ai_result",
                str(ctx.exception),
            )


class TestEstimateLifecycle(unittest.TestCase):
    """End-to-end: review → confirm → quotation created."""

    def test_review_then_confirm_creates_quotation(self):
        from app.services.estimate_service import confirm_estimate, review_estimate

        with patch(
            "app.services.estimate_service.frappe_get", new_callable=AsyncMock
        ) as mock_get, patch(
            "app.services.estimate_service.frappe_put", new_callable=AsyncMock
        ) as mock_put, patch(
            "app.services.estimate_service.frappe_post", new_callable=AsyncMock
        ) as mock_post:
            est_data = {
                "name": "EST-100",
                "origin": "ai_primary",
                "ai_result": '{"items": []}',
                "status": "Draft",
                "reviewed_by": "",
            }

            def _get(path, sid=""):
                return {"data": dict(est_data)}

            def _put(path, data=None, sid=""):
                est_data.update(data)
                return {"data": {}}

            mock_get.side_effect = _get
            mock_put.side_effect = _put
            mock_post.return_value = {"message": "QTN-100"}

            review_result = _run(
                review_estimate(
                    sid="sid",
                    name="EST-100",
                    decision="approved",
                    user_id="eng@riad.fun",
                )
            )
            self.assertEqual(review_result["status"], "Approved")
            self.assertEqual(est_data["status"], "Approved")
            self.assertEqual(est_data["reviewed_by"], "eng@riad.fun")

            confirm_result = _run(confirm_estimate(sid="sid", name="EST-100"))
            self.assertEqual(confirm_result["quotation_name"], "QTN-100")
            mock_post.assert_called_once()

    def test_manual_origin_cannot_be_reviewed(self):
        from app.services.estimate_service import review_estimate

        with patch(
            "app.services.estimate_service.frappe_get", new_callable=AsyncMock
        ) as mock_get:
            mock_get.return_value = {
                "data": {
                    "name": "EST-M1",
                    "origin": "manual",
                    "ai_result": "some content",
                }
            }

            with self.assertRaises(ValueError):
                _run(
                    review_estimate(
                        sid="sid",
                        name="EST-M1",
                        decision="approved",
                        user_id="eng@riad.fun",
                    )
                )


if __name__ == "__main__":
    unittest.main()
