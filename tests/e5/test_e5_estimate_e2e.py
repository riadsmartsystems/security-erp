"""E5 Integration Test — AI Estimate lifecycle: build → review → confirm"""
import asyncio
import os
import sys
import unittest
from unittest.mock import patch

_services_root = os.path.join(
    os.path.dirname(__file__), "..", "..", "services", "security-api"
)
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)


def _run(coro):
    return asyncio.run(coro)


class TestEstimateE2E(unittest.TestCase):
    def test_build_review_confirm_lifecycle(self):
        from app.services.estimate_service import (
            build_estimate,
            review_estimate,
            confirm_estimate,
        )

        brief_data = {"data": {"brief_name": "Test Object", "security_type": "CCTV", "brief_text": "Install 10 cameras"}}
        estimate_created = {"data": {"name": "EST-E2E-001"}}
        estimate_with_ai = {
            "data": {
                "name": "EST-E2E-001",
                "status": "Draft",
                "origin": "manual",
                "ai_result": '{"items": [{"name": "Camera", "qty": 10}]}',
                "reviewed_by": "",
            }
        }
        estimate_approved = {
            "data": {
                "name": "EST-E2E-001",
                "status": "Approved",
                "origin": "ai_primary",
                "ai_result": '{"items": [{"name": "Camera", "qty": 10}]}',
                "reviewed_by": "eng@riad.fun",
            }
        }
        quotation_result = {"message": "QTN-001"}

        call_count = {"get": 0, "put": 0}

        def _get(path, params=None, sid=""):
            call_count["get"] += 1
            if "Site Brief" in path:
                return brief_data
            if "AI Estimate" in path:
                if call_count["put"] >= 2:
                    return estimate_approved
                return estimate_with_ai
            return {"data": {}}

        async def _post(path, data=None, sid=""):
            if "AI Estimate" in path:
                return estimate_created
            if "execute_ai" in path:
                return {"status": "ok", "result": '{"items": [{"name": "Camera", "qty": 10}]}', "provider_used": "gemini"}
            if "enqueue_ai_estimate" in path:
                return {}
            if "create_quotation" in path:
                return quotation_result
            return {"data": {}}

        async def _put(path, data=None, sid=""):
            call_count["put"] += 1
            return {"data": {}}

        with patch("app.services.estimate_service.frappe_get", side_effect=_get), \
             patch("app.services.estimate_service.frappe_post", side_effect=_post), \
             patch("app.services.estimate_service.frappe_put", side_effect=_put):

            result = _run(build_estimate(
                sid="sid",
                site_brief_name="Test Brief",
                variant="standard",
                user_id="eng@riad.fun",
            ))
            self.assertEqual(result["name"], "EST-E2E-001")

            review_result = _run(review_estimate(
                sid="sid",
                name="EST-E2E-001",
                decision="approved",
                user_id="eng@riad.fun",
            ))
            self.assertEqual(review_result["status"], "Approved")

            confirm_result = _run(confirm_estimate(
                sid="sid",
                name="EST-E2E-001",
            ))
            self.assertEqual(confirm_result["quotation_name"], "QTN-001")

    def test_review_rejects_manual_estimate(self):
        from app.services.estimate_service import review_estimate

        estimate_manual = {
            "data": {"name": "EST-MANUAL-001", "origin": "manual", "ai_result": ""}
        }

        def _get(path, params=None, sid=""):
            if "AI Estimate" in path:
                return estimate_manual
            return {"data": {}}

        with patch("app.services.estimate_service.frappe_get", side_effect=_get):
            with self.assertRaises(ValueError) as ctx:
                _run(review_estimate(sid="sid", name="EST-MANUAL-001", decision="approved", user_id="eng@riad.fun"))
            self.assertIn("RIAD-VALIDATION", str(ctx.exception))

    def test_confirm_rejects_unapproved_estimate(self):
        from app.services.estimate_service import confirm_estimate

        estimate_draft = {
            "data": {"name": "EST-DRAFT-001", "status": "Draft", "reviewed_by": ""}
        }

        def _get(path, params=None, sid=""):
            if "AI Estimate" in path:
                return estimate_draft
            return {"data": {}}

        with patch("app.services.estimate_service.frappe_get", side_effect=_get):
            with self.assertRaises(ValueError) as ctx:
                _run(confirm_estimate(sid="sid", name="EST-DRAFT-001"))
            self.assertIn("RIAD-VALIDATION", str(ctx.exception))


if __name__ == "__main__":
    unittest.main()
