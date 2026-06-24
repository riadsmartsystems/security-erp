"""E4 Integration Test — push → conflict → resolve → pull

Run:
  cd "/home/joker/RIAD CRM"
  python -m unittest tests.s1.test_s1_sync_integration -v
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
    return asyncio.run(coro)


class TestSyncIntegration(unittest.TestCase):
    def test_push_conflict_resolve_pull_cycle(self):
        from app.schemas.sync import (
            SyncPullRequest,
            SyncPushItem,
            SyncPushRequest,
            SyncResolveRequest,
        )
        from app.services.sync_service import (
            encode_watermark,
            pull_changes,
            push_batch,
            resolve_conflict,
        )

        existing_doc = {
            "data": {
                "name": "uuid-visit-1",
                "riad_version": 3,
                "riad_deleted": 0,
                "status": "Server",
                "engineer": "eng@riad.fun",
                "materials": [],
                "photos": [],
            }
        }
        conflict_doc = {
            "data": {
                "name": "SC-001",
                "conflict_doctype": "Visit",
                "conflict_docname": "uuid-visit-1",
                "conflict_field": "status",
                "server_value": "Server",
                "client_value": "Client",
                "resolved": 0,
            }
        }
        updated_visit = {
            "data": {
                "name": "uuid-visit-1",
                "riad_version": 4,
                "riad_deleted": 0,
                "status": "Client",
                "engineer": "eng@riad.fun",
                "materials": [],
                "photos": [],
            }
        }

        state = {"resolved": False}

        visit_record = {
            "name": "uuid-visit-1",
            "riad_version": 3,
            "riad_deleted": 0,
            "status": "Server",
            "engineer": "eng@riad.fun",
            "materials": [],
            "photos": [],
        }

        def _get(path, params=None, sid=""):
            if "Sync Conflict" in path:
                return conflict_doc
            if "Visit/uuid-visit-1" in path:
                return updated_visit if state["resolved"] else existing_doc
            if "Visit" in path:
                return {"data": [visit_record]}
            return {"data": []}

        async def _put(path, data=None, sid=""):
            if "Visit/uuid-visit-1" in path:
                state["resolved"] = True
            return {"data": {}}

        with patch(
            "app.services.sync_service.frappe_get", side_effect=_get
        ), patch(
            "app.services.sync_service.frappe_post", new_callable=AsyncMock
        ) as mock_post, patch(
            "app.services.sync_service.frappe_put", side_effect=_put
        ):
            mock_post.return_value = {"data": {"name": "SC-001"}}

            push_req = SyncPushRequest(
                device_id="d1",
                batch=[
                    SyncPushItem(
                        doctype="Visit",
                        name="uuid-visit-1",
                        op="upsert",
                        client_base_version=2,
                        scalars={"status": "Client"},
                    )
                ],
            )
            push_result = _run(push_batch(push_req, user_id="eng", sid="sid"))
            self.assertEqual(push_result.results[0].status, "conflict")

            resolve_req = SyncResolveRequest(
                conflict_id="SC-001", chosen="client"
            )
            resolve_result = _run(
                resolve_conflict(resolve_req, user_id="eng", sid="sid")
            )
            self.assertEqual(resolve_result.status, "resolved")

            pull_req = SyncPullRequest(
                device_id="d1",
                watermark=encode_watermark("2020-01-01 00:00:00.000000"),
            )
            pull_result = _run(pull_changes(pull_req, sid="sid"))
            self.assertTrue(pull_result.next_watermark)

    def test_encode_watermark_is_public_alias(self):
        from app.services.sync_service import encode_watermark, _encode_watermark

        self.assertIs(encode_watermark, _encode_watermark)
        result = encode_watermark("2025-01-01 00:00:00")
        self.assertIsInstance(result, str)
        self.assertTrue(len(result) > 0)


if __name__ == "__main__":
    unittest.main()
