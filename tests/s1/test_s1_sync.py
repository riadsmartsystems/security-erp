"""S1 Sync backend tests — pull/push/resolve.

Run:
  cd "/home/joker/RIAD CRM"
  python -m unittest tests.s1.test_s1_sync -v
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


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _run(coro):
    return asyncio.get_event_loop().run_until_complete(coro)


def _make_client(mock_user=None):
    from fastapi.testclient import TestClient
    from app.main import app
    from app.auth.dependencies import get_current_user
    from app.core.redis import get_redis
    from app.auth.permissions import Role

    if mock_user is None:
        from app.auth.dependencies import CurrentUser
        mock_user = CurrentUser(
            user_id="test@test.com",
            role=Role.ENGINEER,
            frappe_sid="test-sid",
            frappe_roles=[],
        )

    mock_redis = AsyncMock()
    mock_redis.incr = AsyncMock(return_value=1)
    mock_redis.expire = AsyncMock()
    mock_redis.get = AsyncMock(return_value=None)

    async def _redis():
        return mock_redis

    async def _user():
        return mock_user

    app.dependency_overrides[get_redis] = _redis
    app.dependency_overrides[get_current_user] = _user
    return TestClient(app, raise_server_exceptions=False)


# ---------------------------------------------------------------------------
# Test 1: pull returns changes after watermark
# ---------------------------------------------------------------------------

class TestSyncPull(unittest.TestCase):
    def test_pull_returns_changes_after_watermark(self):
        import base64

        from app.services.sync_service import _encode_watermark

        watermark = _encode_watermark("2026-01-01 00:00:00.000000")

        mock_visit_list = {
            "data": [
                {
                    "name": "uuid-visit-1",
                    "modified": "2026-06-22 10:00:00",
                    "riad_version": 3,
                    "riad_deleted": 0,
                    "riad_deleted_at": None,
                    "status": "Working",
                    "visit_type": "Service",
                    "summary": "Fixed camera",
                    "engineer": "tech@riad.fun",
                    "service_ticket": None,
                    "materials": [
                        {"name": "row1", "client_uuid": "mat-uuid-1", "item_code": "CAM", "quantity": 1.0}
                    ],
                    "photos": [],
                }
            ]
        }

        # Other doctypes return empty
        def _frappe_get_side_effect(path, params=None, sid=""):
            if "Visit" in path and "resource/Visit" in path and "/" not in path.replace("/api/resource/Visit", ""):
                return mock_visit_list
            return {"data": []}

        with patch("app.services.sync_service.frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.side_effect = _frappe_get_side_effect

            from app.schemas.sync import SyncPullRequest
            from app.services.sync_service import pull_changes

            req = SyncPullRequest(device_id="device-1", watermark=watermark)
            result = _run(pull_changes(req, sid="test-sid"))

        self.assertEqual(len(result.changes), 1)
        change = result.changes[0]
        self.assertEqual(change.name, "uuid-visit-1")
        self.assertEqual(change.riad_version, 3)
        self.assertFalse(change.riad_deleted)
        self.assertIn("visit_material", change.additive)
        self.assertEqual(len(change.additive["visit_material"]), 1)
        self.assertTrue(result.next_watermark)  # non-empty opaque token

    def test_pull_no_watermark_returns_all(self):
        from app.schemas.sync import SyncPullRequest
        from app.services.sync_service import pull_changes

        with patch("app.services.sync_service.frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = {"data": []}
            req = SyncPullRequest(device_id="device-1", watermark=None)
            result = _run(pull_changes(req, sid="test-sid"))

        # All doctypes queried with since_ts = epoch
        self.assertEqual(mock_get.call_count, 4)  # 4 SYNCABLE_DOCTYPES
        for call in mock_get.call_args_list:
            params = call.kwargs.get("params") or (call.args[1] if len(call.args) > 1 else {})
            filters_str = (params or {}).get("filters", "")
            self.assertIn("1970-01-01", filters_str)


# ---------------------------------------------------------------------------
# Test 2: push create → riad_version=1
# ---------------------------------------------------------------------------

class TestSyncPushCreate(unittest.TestCase):
    def test_push_create_returns_applied_version_1(self):
        from app.schemas.sync import SyncPushItem, SyncPushRequest
        from app.services.sync_service import push_batch

        with patch("app.services.sync_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.sync_service.frappe_post", new_callable=AsyncMock) as mock_post:

            mock_get.side_effect = Exception("404 Not Found")
            mock_post.return_value = {"data": {"name": "uuid-visit-new"}}

            req = SyncPushRequest(
                device_id="device-1",
                batch=[
                    SyncPushItem(
                        doctype="Visit",
                        name="uuid-visit-new",
                        op="upsert",
                        client_base_version=0,
                        scalars={"status": "Working", "engineer": "eng@riad.fun"},
                    )
                ],
            )
            result = _run(push_batch(req, user_id="eng@riad.fun", sid="test-sid"))

        self.assertEqual(len(result.results), 1)
        r = result.results[0]
        self.assertEqual(r.name, "uuid-visit-new")
        self.assertEqual(r.status, "applied")
        self.assertEqual(r.server_version, 1)
        self.assertEqual(r.conflicts, [])

        # Verify POST was called with riad_version=1 and name=uuid
        post_call = mock_post.call_args
        payload = post_call.kwargs.get("data") or post_call.args[1]
        self.assertEqual(payload["riad_version"], 1)
        self.assertEqual(payload["name"], "uuid-visit-new")


# ---------------------------------------------------------------------------
# Test 3: push update no conflict → version+1
# ---------------------------------------------------------------------------

class TestSyncPushUpdate(unittest.TestCase):
    def test_push_update_no_conflict_increments_version(self):
        from app.schemas.sync import SyncPushItem, SyncPushRequest
        from app.services.sync_service import push_batch

        existing_doc = {
            "data": {
                "name": "uuid-visit-1",
                "riad_version": 2,
                "riad_deleted": 0,
                "status": "Working",
                "engineer": "eng@riad.fun",
                "materials": [],
                "photos": [],
            }
        }

        with patch("app.services.sync_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.sync_service.frappe_put", new_callable=AsyncMock) as mock_put:

            mock_get.return_value = existing_doc
            mock_put.return_value = {"data": {}}

            req = SyncPushRequest(
                device_id="device-1",
                batch=[
                    SyncPushItem(
                        doctype="Visit",
                        name="uuid-visit-1",
                        op="upsert",
                        client_base_version=2,  # matches server version
                        scalars={"status": "Completed"},
                    )
                ],
            )
            result = _run(push_batch(req, user_id="eng@riad.fun", sid="test-sid"))

        r = result.results[0]
        self.assertEqual(r.status, "applied")
        self.assertEqual(r.server_version, 3)  # 2 + 1
        self.assertEqual(r.conflicts, [])

        put_call = mock_put.call_args
        put_payload = put_call.kwargs.get("data") or put_call.args[1]
        self.assertEqual(put_payload["riad_version"], 3)
        self.assertEqual(put_payload["status"], "Completed")


# ---------------------------------------------------------------------------
# Test 4: push update with scalar conflict → Sync Conflict created
# ---------------------------------------------------------------------------

class TestSyncPushConflict(unittest.TestCase):
    def test_push_update_scalar_conflict_creates_sync_conflict(self):
        from app.schemas.sync import SyncPushItem, SyncPushRequest
        from app.services.sync_service import push_batch

        existing_doc = {
            "data": {
                "name": "uuid-visit-1",
                "riad_version": 5,   # server is at v5
                "riad_deleted": 0,
                "status": "Completed",  # server value
                "engineer": "eng@riad.fun",
                "materials": [],
                "photos": [],
            }
        }

        with patch("app.services.sync_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.sync_service.frappe_post", new_callable=AsyncMock) as mock_post, \
             patch("app.services.sync_service.frappe_put", new_callable=AsyncMock) as mock_put:

            mock_get.return_value = existing_doc
            mock_post.return_value = {"data": {"name": "SCONF-000001"}}
            mock_put.return_value = {"data": {}}

            req = SyncPushRequest(
                device_id="device-1",
                batch=[
                    SyncPushItem(
                        doctype="Visit",
                        name="uuid-visit-1",
                        op="upsert",
                        client_base_version=2,  # client based on v2, server is at v5 → conflict
                        scalars={"status": "Working"},  # client says Working, server says Completed
                    )
                ],
            )
            result = _run(push_batch(req, user_id="eng@riad.fun", sid="test-sid"))

        r = result.results[0]
        self.assertEqual(r.status, "conflict")
        self.assertEqual(len(r.conflicts), 1)
        conflict = r.conflicts[0]
        self.assertEqual(conflict.field, "status")
        self.assertEqual(conflict.server_value, "Completed")
        self.assertEqual(conflict.client_value, "Working")
        self.assertEqual(conflict.conflict_id, "SCONF-000001")

        # Verify Sync Conflict POST was called
        post_call = mock_post.call_args
        payload = post_call.kwargs.get("data") or post_call.args[1]
        self.assertEqual(payload["conflict_doctype"], "Visit")
        self.assertEqual(payload["conflict_field"], "status")
        self.assertEqual(payload["device_id"], "device-1")
        self.assertEqual(payload["resolved"], 0)


# ---------------------------------------------------------------------------
# Test 5: push delete → tombstone
# ---------------------------------------------------------------------------

class TestSyncPushTombstone(unittest.TestCase):
    def test_push_delete_sets_tombstone(self):
        from app.schemas.sync import SyncPushItem, SyncPushRequest
        from app.services.sync_service import push_batch

        existing_doc = {
            "data": {
                "name": "uuid-media-1",
                "riad_version": 2,
                "riad_deleted": 0,
                "drive_file_id": "gdrive-abc",
            }
        }

        with patch("app.services.sync_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.sync_service.frappe_put", new_callable=AsyncMock) as mock_put:

            mock_get.return_value = existing_doc
            mock_put.return_value = {"data": {}}

            req = SyncPushRequest(
                device_id="device-1",
                batch=[
                    SyncPushItem(
                        doctype="Media Asset",
                        name="uuid-media-1",
                        op="delete",
                        client_base_version=2,
                    )
                ],
            )
            result = _run(push_batch(req, user_id="eng@riad.fun", sid="test-sid"))

        r = result.results[0]
        self.assertEqual(r.status, "tombstoned")
        self.assertEqual(r.server_version, 3)

        put_call = mock_put.call_args
        payload = put_call.kwargs.get("data") or put_call.args[1]
        self.assertEqual(payload["riad_deleted"], 1)
        self.assertIn("riad_deleted_at", payload)
        self.assertEqual(payload["riad_version"], 3)


# ---------------------------------------------------------------------------
# Test 6: push idempotent create → ignored_duplicate
# ---------------------------------------------------------------------------

class TestSyncPushIdempotent(unittest.TestCase):
    def test_push_idempotent_create_returns_ignored_duplicate(self):
        from app.schemas.sync import SyncPushItem, SyncPushRequest
        from app.services.sync_service import push_batch

        existing_doc = {
            "data": {
                "name": "uuid-visit-2",
                "riad_version": 1,
                "riad_deleted": 0,
                "status": "Working",
                "engineer": "eng@riad.fun",
                "materials": [],
                "photos": [],
            }
        }

        with patch("app.services.sync_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.sync_service.frappe_post", new_callable=AsyncMock) as mock_post:

            mock_get.return_value = existing_doc

            req = SyncPushRequest(
                device_id="device-1",
                batch=[
                    SyncPushItem(
                        doctype="Visit",
                        name="uuid-visit-2",
                        op="upsert",
                        client_base_version=0,  # create attempt
                        # Same values as server → idempotent
                        scalars={"status": "Working", "engineer": "eng@riad.fun"},
                    )
                ],
            )
            result = _run(push_batch(req, user_id="eng@riad.fun", sid="test-sid"))

        r = result.results[0]
        self.assertEqual(r.status, "ignored_duplicate")
        self.assertEqual(r.server_version, 1)
        # POST should NOT have been called (no new document created)
        mock_post.assert_not_called()


# ---------------------------------------------------------------------------
# Test 7: union-merge additive child rows by _uuid
# ---------------------------------------------------------------------------

class TestSyncPushUnionMerge(unittest.TestCase):
    def test_union_merge_adds_new_rows_preserves_existing(self):
        from app.schemas.sync import SyncPushItem, SyncPushRequest
        from app.services.sync_service import push_batch

        existing_doc = {
            "data": {
                "name": "uuid-visit-3",
                "riad_version": 2,
                "riad_deleted": 0,
                "status": "Working",
                "materials": [
                    {"name": "frappe-row-1", "client_uuid": "mat-uuid-existing",
                     "item_code": "CAM", "quantity": 1.0}
                ],
                "photos": [],
            }
        }

        with patch("app.services.sync_service.frappe_get", new_callable=AsyncMock) as mock_get, \
             patch("app.services.sync_service.frappe_put", new_callable=AsyncMock) as mock_put:

            mock_get.return_value = existing_doc
            mock_put.return_value = {"data": {}}

            req = SyncPushRequest(
                device_id="device-1",
                batch=[
                    SyncPushItem(
                        doctype="Visit",
                        name="uuid-visit-3",
                        op="upsert",
                        client_base_version=2,
                        scalars={},
                        additive={
                            "visit_material": [
                                # existing row → already_present
                                {"_uuid": "mat-uuid-existing", "item_code": "CAM", "quantity": 1.0},
                                # new row → added
                                {"_uuid": "mat-uuid-new", "item_code": "CABLE", "quantity": 5.0},
                            ]
                        },
                    )
                ],
            )
            result = _run(push_batch(req, user_id="eng@riad.fun", sid="test-sid"))

        r = result.results[0]
        # Union merge: merged or applied (has additive changes)
        self.assertIn(r.status, ("merged", "applied"))
        self.assertIn("visit_material", r.additive)
        am = r.additive["visit_material"]
        self.assertIn("mat-uuid-new", am.added)
        self.assertIn("mat-uuid-existing", am.already_present)

        # Verify PUT was called with both rows in materials
        put_call = mock_put.call_args
        payload = put_call.kwargs.get("data") or put_call.args[1]
        materials = payload.get("materials", [])
        uuids = [r.get("client_uuid") for r in materials]
        self.assertIn("mat-uuid-existing", uuids)
        self.assertIn("mat-uuid-new", uuids)
        self.assertEqual(len(materials), 2)


# ---------------------------------------------------------------------------
# Test 8: resolve → chosen value applied
# ---------------------------------------------------------------------------

class TestSyncResolve(unittest.TestCase):
    def test_resolve_client_applies_client_value(self):
        from app.schemas.sync import SyncResolveRequest
        from app.services.sync_service import resolve_conflict

        conflict_doc = {
            "data": {
                "name": "SCONF-000001",
                "conflict_doctype": "Visit",
                "conflict_docname": "uuid-visit-1",
                "conflict_field": "status",
                "server_value": "Completed",
                "client_value": "Working",
                "resolved": 0,
            }
        }
        visit_doc = {
            "data": {
                "name": "uuid-visit-1",
                "riad_version": 5,
                "status": "Completed",
            }
        }

        async def _frappe_get(path, params=None, sid=""):
            if "Sync Conflict" in path:
                return conflict_doc
            return visit_doc

        with patch("app.services.sync_service.frappe_get", side_effect=_frappe_get), \
             patch("app.services.sync_service.frappe_put", new_callable=AsyncMock) as mock_put:

            mock_put.return_value = {"data": {}}

            req = SyncResolveRequest(conflict_id="SCONF-000001", chosen="client")
            result = _run(resolve_conflict(req, user_id="eng@riad.fun", sid="test-sid"))

        self.assertEqual(result.conflict_id, "SCONF-000001")
        self.assertEqual(result.status, "resolved")
        self.assertEqual(result.chosen, "client")

        # Two PUT calls: one for the visit doc, one for the conflict doc
        self.assertEqual(mock_put.call_count, 2)
        visit_put = mock_put.call_args_list[0]
        visit_payload = visit_put.kwargs.get("data") or visit_put.args[1]
        self.assertEqual(visit_payload["status"], "Working")  # client_value
        self.assertEqual(visit_payload["riad_version"], 6)    # 5 + 1

        conflict_put = mock_put.call_args_list[1]
        conflict_payload = conflict_put.kwargs.get("data") or conflict_put.args[1]
        self.assertEqual(conflict_payload["resolved"], 1)
        self.assertEqual(conflict_payload["chosen"], "client")
        self.assertEqual(conflict_payload["resolved_by"], "eng@riad.fun")


if __name__ == "__main__":
    unittest.main()
