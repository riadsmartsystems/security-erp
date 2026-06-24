"""FIX-6 Gateway discipline tests: visits + warehouse + maps + media + ai_admin.

RED phase: ImportError proves service modules don't exist yet.
GREEN after implementing services + updating routes.

Run:
  cd "/home/joker/RIAD CRM"
  python -m unittest tests.fix6.test_fix6_gateway_discipline -v
"""
import asyncio
import os
import sys
import unittest
from unittest.mock import AsyncMock, patch

_services_root = os.path.join(os.path.dirname(__file__), "..", "..", "services", "security-api")
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)


# =============================================================================
# Visit Service Tests
# =============================================================================


class TestVisitServiceStartVisit(unittest.TestCase):
    """start_visit updates Visit to On Route with GPS coordinates."""

    def test_start_visit_calls_frappe_put_with_on_route(self):
        try:
            from app.services import visit_service
        except ImportError:
            self.fail("visit_service not found — implement app/services/visit_service.py")
        with patch.object(visit_service, "frappe_put", new_callable=AsyncMock) as mock_put:
            mock_put.return_value = {"data": {"name": "VISIT-001", "status": "On Route"}}
            result = asyncio.run(
                visit_service.start_visit(sid="test-sid", visit_id="VISIT-001", lat=48.5, lon=35.0)
            )
        mock_put.assert_called_once()
        call_args = mock_put.call_args
        self.assertIn("/VISIT-001", call_args.args[0])
        self.assertEqual(call_args.kwargs["data"]["status"], "On Route")
        self.assertEqual(call_args.kwargs["data"]["gps_checkin_lat"], 48.5)
        self.assertEqual(call_args.kwargs["sid"], "test-sid")
        self.assertEqual(result.get("status"), "On Route")


class TestVisitServiceFinishVisit(unittest.TestCase):
    """finish_visit updates Visit to Completed with checkout GPS."""

    def test_finish_visit_calls_frappe_put_with_completed(self):
        try:
            from app.services import visit_service
        except ImportError:
            self.fail("visit_service not found — implement app/services/visit_service.py")
        with patch.object(visit_service, "frappe_put", new_callable=AsyncMock) as mock_put:
            mock_put.return_value = {"data": {"name": "VISIT-001", "status": "Completed"}}
            result = asyncio.run(
                visit_service.finish_visit(sid="test-sid", visit_id="VISIT-001", lat=48.6, lon=35.1)
            )
        mock_put.assert_called_once()
        call_args = mock_put.call_args
        self.assertEqual(call_args.kwargs["data"]["status"], "Completed")
        self.assertEqual(call_args.kwargs["data"]["gps_checkout_lat"], 48.6)
        self.assertEqual(call_args.kwargs["data"]["gps_checkout_lon"], 35.1)
        self.assertEqual(call_args.kwargs["sid"], "test-sid")
        self.assertEqual(result.get("status"), "Completed")


class TestVisitServiceAddMaterial(unittest.TestCase):
    """add_material creates Visit Material child record in Frappe."""

    def test_add_material_calls_frappe_post_with_parent(self):
        try:
            from app.services import visit_service
        except ImportError:
            self.fail("visit_service not found — implement app/services/visit_service.py")
        with patch.object(visit_service, "frappe_post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = {"data": {"name": "VMAT-001"}}
            result = asyncio.run(
                visit_service.add_material(
                    sid="test-sid",
                    visit_id="VISIT-001",
                    item_code="CAM-001",
                    item_name="IP Camera",
                    quantity=2,
                    unit_price=1500.0,
                )
            )
        mock_post.assert_called_once()
        call_args = mock_post.call_args
        posted = call_args.kwargs["data"]
        self.assertEqual(posted["parent"], "VISIT-001")
        self.assertEqual(posted["parenttype"], "Visit")
        self.assertEqual(posted["qty"], 2)
        self.assertEqual(posted["rate"], 1500.0)
        self.assertEqual(call_args.kwargs["sid"], "test-sid")
        self.assertEqual(result.get("name"), "VMAT-001")


class TestVisitServiceUploadPhoto(unittest.TestCase):
    """upload_photo posts base64-encoded file bytes to Frappe."""

    def test_upload_photo_calls_frappe_post_with_base64(self):
        try:
            from app.services import visit_service
        except ImportError:
            self.fail("visit_service not found — implement app/services/visit_service.py")
        with patch.object(visit_service, "frappe_post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = {"data": {"name": "VPHOTO-001"}}
            result = asyncio.run(
                visit_service.upload_photo(
                    sid="test-sid",
                    visit_id="VISIT-001",
                    file_bytes=b"fake-image-bytes",
                    content_type="image/jpeg",
                    photo_type="after",
                    caption="Test caption",
                )
            )
        mock_post.assert_called_once()
        call_args = mock_post.call_args
        posted = call_args.kwargs["data"]
        self.assertEqual(posted["parent"], "VISIT-001")
        self.assertEqual(posted["parenttype"], "Visit")
        self.assertEqual(posted["photo_type"], "after")
        self.assertEqual(posted["caption"], "Test caption")
        self.assertIn("data:image/jpeg;base64,", posted["image"])
        self.assertEqual(call_args.kwargs["sid"], "test-sid")


# =============================================================================
# Warehouse Service Tests
# =============================================================================


class TestWarehouseServiceListSerials(unittest.TestCase):
    """list_serials fetches Serial No records and maps to DTO dicts."""

    def test_list_serials_maps_frappe_response_to_dtos(self):
        try:
            from app.services import warehouse_service
        except ImportError:
            self.fail("warehouse_service not found — implement app/services/warehouse_service.py")
        with patch.object(warehouse_service, "frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = {
                "message": {
                    "data": [
                        {
                            "name": "SN-001",
                            "serial_no": "SN-001",
                            "item": "CAM",
                            "item_name": "Camera",
                            "status": "Available",
                            "warehouse": "Main",
                        }
                    ],
                    "total": 1,
                }
            }
            result = asyncio.run(
                warehouse_service.list_serials(sid="test-sid", q="SN", page=1, page_size=20)
            )
        mock_get.assert_called_once()
        self.assertEqual(mock_get.call_args.kwargs["sid"], "test-sid")
        self.assertEqual(len(result["items"]), 1)
        self.assertEqual(result["items"][0]["serial_no"], "SN-001")
        self.assertEqual(result["total"], 1)
        self.assertEqual(result["page"], 1)
        self.assertEqual(result["page_size"], 20)


class TestWarehouseServiceListStock(unittest.TestCase):
    """list_stock aggregates Bin records by item_code."""

    def test_list_stock_aggregates_bins_by_item(self):
        try:
            from app.services import warehouse_service
        except ImportError:
            self.fail("warehouse_service not found — implement app/services/warehouse_service.py")
        with patch.object(warehouse_service, "frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = {
                "message": {
                    "message": [
                        {"item_code": "CAM-IP", "item_name": "IP Camera", "actual_qty": 5, "warehouse": "Main"},
                        {"item_code": "CAM-IP", "item_name": "IP Camera", "actual_qty": 3, "warehouse": "Branch"},
                    ]
                }
            }
            result = asyncio.run(warehouse_service.list_stock(sid="test-sid"))
        mock_get.assert_called_once()
        self.assertEqual(mock_get.call_args.kwargs["sid"], "test-sid")
        self.assertEqual(len(result["items"]), 1)
        self.assertEqual(result["items"][0]["item_code"], "CAM-IP")
        self.assertEqual(result["items"][0]["qty"], 8)  # 5 + 3 aggregated


class TestWarehouseServiceStockDetail(unittest.TestCase):
    """stock_detail calls Frappe twice: bins then Serial Nos."""

    def test_stock_detail_calls_frappe_twice_bins_and_serials(self):
        try:
            from app.services import warehouse_service
        except ImportError:
            self.fail("warehouse_service not found — implement app/services/warehouse_service.py")
        with patch.object(warehouse_service, "frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.side_effect = [
                # Call 1: bins
                {
                    "message": {
                        "message": [
                            {"item_code": "CAM", "item_name": "Camera", "actual_qty": 2, "warehouse": "Main"}
                        ]
                    }
                },
                # Call 2: Serial Nos
                {
                    "message": {
                        "data": [
                            {
                                "name": "SN-001",
                                "serial_no": "SN-001",
                                "item": "CAM",
                                "item_name": "Camera",
                                "status": "Active",
                                "warehouse": "Main",
                            }
                        ]
                    }
                },
            ]
            result = asyncio.run(warehouse_service.stock_detail(sid="test-sid", item="CAM"))
        self.assertEqual(mock_get.call_count, 2)
        self.assertEqual(result["item_code"], "CAM")
        self.assertEqual(result["qty"], 2)
        self.assertEqual(result["item_name"], "Camera")
        self.assertEqual(len(result["serials"]), 1)
        self.assertEqual(result["serials"][0]["serial_no"], "SN-001")


# =============================================================================
# Map Service Tests
# =============================================================================


class TestMapServiceGetMap(unittest.TestCase):
    """get_map fetches Installation Map from Frappe and returns raw data dict."""

    def test_get_map_calls_frappe_get_and_returns_data(self):
        try:
            from app.services import map_service
        except ImportError:
            self.fail("map_service not found — implement app/services/map_service.py")
        with patch.object(map_service, "frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = {
                "message": {
                    "name": "MAP-001",
                    "map_kind": "план приміщення",
                    "mount_points": [],
                    "cable_routes": [],
                }
            }
            result = asyncio.run(map_service.get_map(sid="test-sid", name="MAP-001"))
        mock_get.assert_called_once()
        self.assertEqual(mock_get.call_args.kwargs["sid"], "test-sid")
        self.assertIn("MAP-001", mock_get.call_args.args[0])
        self.assertEqual(result["name"], "MAP-001")
        self.assertEqual(result["map_kind"], "план приміщення")


class TestMapServiceAddMountPointTerritory(unittest.TestCase):
    """add_mount_point for territory mode — calls frappe_get then frappe_put with merged list."""

    def test_add_mount_point_territory_calls_put_with_merged_points(self):
        try:
            from app.services import map_service
        except ImportError:
            self.fail("map_service not found — implement app/services/map_service.py")
        with patch.object(map_service, "frappe_get", new_callable=AsyncMock) as mock_get, \
             patch.object(map_service, "frappe_put", new_callable=AsyncMock) as mock_put:
            mock_get.return_value = {
                "message": {"name": "MAP-001", "map_kind": "територія", "mount_points": []}
            }
            mock_put.return_value = {"message": "ok"}
            status = asyncio.run(map_service.add_mount_point(
                sid="test-sid",
                name="MAP-001",
                point_uuid="pt-new",
                point_data={"point_uuid": "pt-new", "type": "камера", "geo": "48.5,35.0"},
            ))
        mock_put.assert_called_once()
        put_data = mock_put.call_args.kwargs["data"]
        self.assertEqual(len(put_data["mount_points"]), 1)
        self.assertEqual(put_data["mount_points"][0]["point_uuid"], "pt-new")
        self.assertEqual(mock_put.call_args.kwargs["sid"], "test-sid")
        self.assertEqual(status, "added")


class TestMapServiceAddMountPointIdempotent(unittest.TestCase):
    """add_mount_point returns 'already_present' without PUT when uuid already exists."""

    def test_add_mount_point_idempotent_returns_already_present(self):
        try:
            from app.services import map_service
        except ImportError:
            self.fail("map_service not found — implement app/services/map_service.py")
        with patch.object(map_service, "frappe_get", new_callable=AsyncMock) as mock_get, \
             patch.object(map_service, "frappe_put", new_callable=AsyncMock) as mock_put:
            mock_get.return_value = {
                "message": {
                    "name": "MAP-001",
                    "map_kind": "територія",
                    "mount_points": [{"point_uuid": "pt-existing", "geo": "48.0,35.0"}],
                }
            }
            status = asyncio.run(map_service.add_mount_point(
                sid="test-sid",
                name="MAP-001",
                point_uuid="pt-existing",
                point_data={"point_uuid": "pt-existing", "geo": "48.0,35.0"},
            ))
        mock_put.assert_not_called()
        self.assertEqual(status, "already_present")


class TestMapServiceApproveMap(unittest.TestCase):
    """approve_map writes approved_by + approved_at to Frappe and returns ISO timestamp."""

    def test_approve_map_calls_frappe_put_with_user_and_timestamp(self):
        try:
            from app.services import map_service
        except ImportError:
            self.fail("map_service not found — implement app/services/map_service.py")
        with patch.object(map_service, "frappe_put", new_callable=AsyncMock) as mock_put:
            mock_put.return_value = {"message": "ok"}
            approved_at = asyncio.run(map_service.approve_map(
                sid="test-sid", name="MAP-001", user_id="engineer@test.com"
            ))
        mock_put.assert_called_once()
        put_data = mock_put.call_args.kwargs["data"]
        self.assertEqual(put_data["approved_by"], "engineer@test.com")
        self.assertIn("approved_at", put_data)
        self.assertEqual(mock_put.call_args.kwargs["sid"], "test-sid")
        self.assertIn("MAP-001", mock_put.call_args.args[0])
        self.assertIsNotNone(approved_at)


# =============================================================================
# Media Service Tests
# =============================================================================


class TestMediaServiceUpsertAssetNew(unittest.TestCase):
    """upsert_media_asset creates new Media Asset when GET returns 404."""

    def test_upsert_asset_creates_new_when_get_fails(self):
        try:
            from app.services import media_service
        except ImportError:
            self.fail("media_service not found — implement app/services/media_service.py")
        with patch.object(media_service, "frappe_get", new_callable=AsyncMock) as mock_get, \
             patch.object(media_service, "frappe_post", new_callable=AsyncMock) as mock_post, \
             patch.object(media_service, "frappe_put", new_callable=AsyncMock) as mock_put:
            mock_get.side_effect = Exception("not found")
            mock_post.return_value = {"data": {"name": "uuid-001"}}
            asyncio.run(media_service.upsert_media_asset(
                sid="test-sid",
                client_uuid="uuid-001",
                drive_file_id="drive-001",
                media_type="photo",
                tag="",
                parent_doctype="",
                parent_name="",
            ))
        mock_post.assert_called_once()
        posted = mock_post.call_args.kwargs["data"]
        self.assertEqual(posted["client_uuid"], "uuid-001")
        self.assertEqual(posted["drive_file_id"], "drive-001")
        self.assertEqual(posted["ai_allowed"], 0)
        self.assertEqual(mock_post.call_args.kwargs["sid"], "test-sid")
        mock_put.assert_not_called()


class TestMediaServiceUpsertAssetExisting(unittest.TestCase):
    """upsert_media_asset updates existing Media Asset with PUT when found."""

    def test_upsert_asset_updates_existing_when_found(self):
        try:
            from app.services import media_service
        except ImportError:
            self.fail("media_service not found — implement app/services/media_service.py")
        with patch.object(media_service, "frappe_get", new_callable=AsyncMock) as mock_get, \
             patch.object(media_service, "frappe_post", new_callable=AsyncMock) as mock_post, \
             patch.object(media_service, "frappe_put", new_callable=AsyncMock) as mock_put:
            mock_get.return_value = {"data": {"name": "uuid-001"}}
            mock_put.return_value = {"data": {"name": "uuid-001"}}
            asyncio.run(media_service.upsert_media_asset(
                sid="test-sid",
                client_uuid="uuid-001",
                drive_file_id="drive-001",
                media_type="photo",
                tag="",
                parent_doctype="",
                parent_name="",
            ))
        mock_put.assert_called_once()
        put_data = mock_put.call_args.kwargs["data"]
        self.assertEqual(put_data["drive_file_id"], "drive-001")
        self.assertEqual(put_data["ai_allowed"], 0)
        self.assertEqual(mock_put.call_args.kwargs["sid"], "test-sid")
        mock_post.assert_not_called()


class TestMediaServiceEnqueueTranscription(unittest.TestCase):
    """enqueue_transcription verifies asset exists then POSTs to transcribe method."""

    def test_enqueue_transcription_calls_frappe_get_then_post(self):
        try:
            from app.services import media_service
        except ImportError:
            self.fail("media_service not found — implement app/services/media_service.py")
        with patch.object(media_service, "frappe_get", new_callable=AsyncMock) as mock_get, \
             patch.object(media_service, "frappe_post", new_callable=AsyncMock) as mock_post:
            mock_get.return_value = {"data": {"name": "MA-001"}}
            mock_post.return_value = {"message": "queued"}
            asyncio.run(media_service.enqueue_transcription(sid="test-sid", name="MA-001"))
        mock_get.assert_called_once()
        self.assertEqual(mock_get.call_args.kwargs["sid"], "test-sid")
        mock_post.assert_called_once()
        self.assertIn("MA-001", str(mock_post.call_args))
        self.assertEqual(mock_post.call_args.kwargs["sid"], "test-sid")


class TestMediaServiceManualTranscription(unittest.TestCase):
    """save_manual_transcription verifies asset then PUTs transcription text."""

    def test_save_manual_transcription_calls_frappe_get_then_put(self):
        try:
            from app.services import media_service
        except ImportError:
            self.fail("media_service not found — implement app/services/media_service.py")
        with patch.object(media_service, "frappe_get", new_callable=AsyncMock) as mock_get, \
             patch.object(media_service, "frappe_put", new_callable=AsyncMock) as mock_put:
            mock_get.return_value = {"data": {"name": "MA-001"}}
            mock_put.return_value = {"data": {"name": "MA-001"}}
            asyncio.run(media_service.save_manual_transcription(
                sid="test-sid", name="MA-001", text="transcribed text"
            ))
        mock_get.assert_called_once()
        self.assertEqual(mock_get.call_args.kwargs["sid"], "test-sid")
        mock_put.assert_called_once()
        put_data = mock_put.call_args.kwargs["data"]
        self.assertEqual(put_data["transcription"], "transcribed text")
        self.assertEqual(put_data["transcription_status"], "manual")
        self.assertEqual(mock_put.call_args.kwargs["sid"], "test-sid")


# =============================================================================
# AI Admin Service Tests
# =============================================================================


class TestAIAdminServiceListProviders(unittest.TestCase):
    """list_providers calls frappe_get and maps response to list of dicts."""

    def test_list_providers_calls_frappe_get_and_returns_list(self):
        try:
            from app.services import ai_admin_service
        except ImportError:
            self.fail("ai_admin_service not found — implement app/services/ai_admin_service.py")
        with patch.object(ai_admin_service, "frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = {
                "data": [
                    {
                        "name": "PROV-001",
                        "provider_name": "anthropic",
                        "priority": 1,
                        "is_enabled": 1,
                        "health_status": "healthy",
                    }
                ]
            }
            result = asyncio.run(ai_admin_service.list_providers(sid="test-sid"))
        mock_get.assert_called_once()
        self.assertEqual(mock_get.call_args.kwargs["sid"], "test-sid")
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["name"], "PROV-001")
        self.assertEqual(result[0]["provider_name"], "anthropic")


class TestAIAdminServiceUpsertProviderNew(unittest.TestCase):
    """upsert_provider creates new AI Provider with POST when no name given."""

    def test_upsert_provider_creates_new_when_no_name(self):
        try:
            from app.services import ai_admin_service
        except ImportError:
            self.fail("ai_admin_service not found — implement app/services/ai_admin_service.py")
        with patch.object(ai_admin_service, "frappe_post", new_callable=AsyncMock) as mock_post, \
             patch.object(ai_admin_service, "frappe_put", new_callable=AsyncMock) as mock_put:
            mock_post.return_value = {"data": {"name": "PROV-NEW"}}
            result = asyncio.run(ai_admin_service.upsert_provider(
                sid="test-sid",
                name=None,
                provider_name="anthropic",
                priority=1,
                is_enabled=True,
                health_status="healthy",
            ))
        mock_post.assert_called_once()
        posted = mock_post.call_args.kwargs["data"]
        self.assertEqual(posted["provider_name"], "anthropic")
        self.assertEqual(posted["doctype"], "AI Provider")
        self.assertEqual(mock_post.call_args.kwargs["sid"], "test-sid")
        mock_put.assert_not_called()


class TestAIAdminServiceUpsertProviderExisting(unittest.TestCase):
    """upsert_provider updates existing AI Provider with PUT when name given."""

    def test_upsert_provider_updates_existing_when_name_given(self):
        try:
            from app.services import ai_admin_service
        except ImportError:
            self.fail("ai_admin_service not found — implement app/services/ai_admin_service.py")
        with patch.object(ai_admin_service, "frappe_put", new_callable=AsyncMock) as mock_put, \
             patch.object(ai_admin_service, "frappe_post", new_callable=AsyncMock) as mock_post:
            mock_put.return_value = {"data": {"name": "PROV-001"}}
            result = asyncio.run(ai_admin_service.upsert_provider(
                sid="test-sid",
                name="PROV-001",
                provider_name="anthropic",
                priority=1,
                is_enabled=True,
                health_status="healthy",
            ))
        mock_put.assert_called_once()
        self.assertIn("PROV-001", mock_put.call_args.args[0])
        self.assertEqual(mock_put.call_args.kwargs["sid"], "test-sid")
        mock_post.assert_not_called()


class TestAIAdminServiceListLogs(unittest.TestCase):
    """list_request_logs calls frappe_get with pagination and returns structured dict."""

    def test_list_request_logs_calls_frappe_get_with_pagination(self):
        try:
            from app.services import ai_admin_service
        except ImportError:
            self.fail("ai_admin_service not found — implement app/services/ai_admin_service.py")
        with patch.object(ai_admin_service, "frappe_get", new_callable=AsyncMock) as mock_get:
            mock_get.return_value = {
                "data": [
                    {
                        "name": "LOG-001",
                        "anonymized_payload": "{}",
                        "provider": "anthropic",
                        "latency_ms": 100,
                        "tokens": 50,
                        "status": "success",
                        "error_message": "",
                        "creation": "2026-01-01",
                    }
                ]
            }
            result = asyncio.run(ai_admin_service.list_request_logs(sid="test-sid", page=1, page_size=20))
        mock_get.assert_called_once()
        self.assertEqual(mock_get.call_args.kwargs["sid"], "test-sid")
        self.assertEqual(len(result["logs"]), 1)
        self.assertEqual(result["logs"][0]["name"], "LOG-001")
        self.assertEqual(result["total"], 1)


# =============================================================================
# Gateway Discipline Tests (grep routes for forbidden direct Frappe calls)
# =============================================================================


class TestGatewayDisciplineVisits(unittest.TestCase):
    """visits.py must NOT import or call frappe_get/post/put directly."""

    def test_visits_route_has_no_direct_frappe_calls(self):
        route_path = os.path.join(_services_root, "app", "routes", "visits.py")
        content = open(route_path).read()
        for fn in ("frappe_get", "frappe_post", "frappe_put"):
            self.assertNotIn(fn, content, f"visits.py still has direct {fn} — move to visit_service")


class TestGatewayDisciplineWarehouse(unittest.TestCase):
    """warehouse.py must NOT import or call frappe_get/post/put directly."""

    def test_warehouse_route_has_no_direct_frappe_calls(self):
        route_path = os.path.join(_services_root, "app", "routes", "warehouse.py")
        content = open(route_path).read()
        for fn in ("frappe_get", "frappe_post", "frappe_put"):
            self.assertNotIn(fn, content, f"warehouse.py still has direct {fn} — move to warehouse_service")


class TestGatewayDisciplineMaps(unittest.TestCase):
    """maps.py must NOT import or call frappe_get/post/put directly."""

    def test_maps_route_has_no_direct_frappe_calls(self):
        route_path = os.path.join(_services_root, "app", "routes", "maps.py")
        content = open(route_path).read()
        for fn in ("frappe_get", "frappe_post", "frappe_put"):
            self.assertNotIn(fn, content, f"maps.py still has direct {fn} — move to map_service")


class TestGatewayDisciplineMedia(unittest.TestCase):
    """media.py must NOT import or call frappe_get/post/put directly."""

    def test_media_route_has_no_direct_frappe_calls(self):
        route_path = os.path.join(_services_root, "app", "routes", "media.py")
        content = open(route_path).read()
        for fn in ("frappe_get", "frappe_post", "frappe_put"):
            self.assertNotIn(fn, content, f"media.py still has direct {fn} — move to media_service")


class TestGatewayDisciplineAIAdmin(unittest.TestCase):
    """ai_admin.py must NOT import or call frappe_get/post/put directly."""

    def test_ai_admin_route_has_no_direct_frappe_calls(self):
        route_path = os.path.join(_services_root, "app", "routes", "ai_admin.py")
        content = open(route_path).read()
        for fn in ("frappe_get", "frappe_post", "frappe_put"):
            self.assertNotIn(fn, content, f"ai_admin.py still has direct {fn} — move to ai_admin_service")


if __name__ == "__main__":
    unittest.main()
