"""S4 Backend tests — serial scan, maps, warehouse.

Run:
  cd "/home/joker/RIAD CRM"
  python -m unittest tests.s4.test_s4_gateway -v
"""

import asyncio
import os
import sys
import unittest
from unittest.mock import AsyncMock, MagicMock, patch

_services_root = os.path.join(os.path.dirname(__file__), "..", "..", "services", "security-api")
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)

# Ensure route modules are importable before patching
import app.routes.serial  # noqa: F401
import app.routes.maps  # noqa: F401
import app.routes.warehouse  # noqa: F401


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
# Test 1: record_serial_scan_creates_serial_no
# ---------------------------------------------------------------------------

class TestSerialScanCreate(unittest.TestCase):
    """record_serial_scan creates a new Serial No in ERPNext."""

    @patch("app.routes.serial.frappe_post")
    def test_record_serial_scan_creates_serial_no(self, mock_post):
        mock_post.return_value = {
            "message": {"serial_no": "SN-TEST-001", "created": True, "linked_item": None}
        }
        client = _make_client()
        resp = client.post("/api/v2/serial/record", json={"serial_no": "SN-TEST-001"})
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["serial_no"], "SN-TEST-001")
        self.assertTrue(data["created"])
        mock_post.assert_called_once()


# ---------------------------------------------------------------------------
# Test 2: record_serial_scan_links_to_item
# ---------------------------------------------------------------------------

class TestSerialScanLinkItem(unittest.TestCase):
    """record_serial_scan links Serial No to an Item."""

    @patch("app.routes.serial.frappe_post")
    def test_record_serial_scan_links_to_item(self, mock_post):
        mock_post.return_value = {
            "message": {"serial_no": "SN-TEST-002", "created": True, "linked_item": "CAM-IP-4MP"}
        }
        client = _make_client()
        resp = client.post("/api/v2/serial/record", json={
            "serial_no": "SN-TEST-002",
            "item": "CAM-IP-4MP",
        })
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["linked_item"], "CAM-IP-4MP")
        call_kwargs = mock_post.call_args
        self.assertEqual(call_kwargs[1]["data"]["item"], "CAM-IP-4MP")


# ---------------------------------------------------------------------------
# Test 3: serial_scan_proxy_requires_jwt
# ---------------------------------------------------------------------------

class TestSerialScanJWT(unittest.TestCase):
    """POST /api/v2/serial/record requires JWT."""

    def test_serial_scan_proxy_requires_jwt(self):
        from fastapi.testclient import TestClient
        from app.main import app
        from app.auth.dependencies import get_current_user
        from app.core.redis import get_redis

        app.dependency_overrides.pop(get_current_user, None)
        app.dependency_overrides.pop(get_redis, None)

        mock_redis = AsyncMock()
        mock_redis.incr = AsyncMock(return_value=1)
        mock_redis.expire = AsyncMock()
        mock_redis.get = AsyncMock(return_value=None)

        async def _redis():
            return mock_redis

        app.dependency_overrides[get_redis] = _redis

        client = TestClient(app, raise_server_exceptions=False)
        resp = client.post("/api/v2/serial/record", json={"serial_no": "SN-003"})
        self.assertIn(resp.status_code, [401, 403])


# ---------------------------------------------------------------------------
# Test 4: map_editor_loads_installation_map
# ---------------------------------------------------------------------------

class TestMapGet(unittest.TestCase):
    """GET /api/v2/maps/{name} loads installation map."""

    @patch("app.services.map_service.frappe_get")
    def test_map_editor_loads_installation_map(self, mock_get):
        mock_get.return_value = {
            "message": {
                "name": "MAP-001",
                "passport": "PASS-001",
                "map_kind": "план приміщення",
                "base_plan_media": "media-001",
                "approved_by": None,
                "approved_at": None,
                "mount_points": [
                    {"point_uuid": "pt-1", "type": "камера", "label": "Вхід", "x": 0.2, "y": 0.3},
                ],
                "cable_routes": [],
            }
        }
        client = _make_client()
        resp = client.get("/api/v2/maps/MAP-001")
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["map_kind"], "план приміщення")
        self.assertEqual(len(data["mount_points"]), 1)
        self.assertEqual(data["mount_points"][0]["point_uuid"], "pt-1")


# ---------------------------------------------------------------------------
# Test 5: map_editor_adds_mount_point
# ---------------------------------------------------------------------------

class TestMapAddPoint(unittest.TestCase):
    """POST /api/v2/maps/{name}/points adds mount point idempotently."""

    @patch("app.services.map_service.frappe_put")
    @patch("app.services.map_service.frappe_get")
    def test_map_editor_adds_mount_point(self, mock_get, mock_put):
        mock_get.return_value = {
            "message": {
                "name": "MAP-001",
                "map_kind": "територія",
                "mount_points": [],
                "cable_routes": [],
            }
        }
        mock_put.return_value = {"message": "ok"}
        client = _make_client()
        resp = client.post("/api/v2/maps/MAP-001/points", json={
            "point_uuid": "new-pt-1",
            "type": "камера",
            "label": "Вхід",
            "geo": "48.5,35.0",
        })
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["status"], "added")
        self.assertEqual(data["point_uuid"], "new-pt-1")


# ---------------------------------------------------------------------------
# Test 6: warehouse_serials_search
# ---------------------------------------------------------------------------

class TestWarehouseSerials(unittest.TestCase):
    """GET /api/v2/warehouse/serials with search."""

    @patch("app.services.warehouse_service.frappe_get")
    def test_warehouse_serials_search(self, mock_get):
        mock_get.return_value = {
            "message": {
                "data": [
                    {"name": "SN-001", "serial_no": "SN-001", "item": "CAM", "item_name": "Camera", "status": "Available", "warehouse": None},
                ],
                "total": 1,
            }
        }
        client = _make_client()
        resp = client.get("/api/v2/warehouse/serials", params={"q": "SN-001"})
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(len(data["items"]), 1)
        self.assertEqual(data["items"][0]["serial_no"], "SN-001")


# ---------------------------------------------------------------------------
# Test 7: warehouse_stock_list
# ---------------------------------------------------------------------------

class TestWarehouseStock(unittest.TestCase):
    """GET /api/v2/warehouse/stock lists stock balances."""

    @patch("app.services.warehouse_service.frappe_get")
    def test_warehouse_stock_list(self, mock_get):
        mock_get.return_value = {
            "message": {
                "message": [
                    {"item_code": "CAM-IP", "item_name": "IP Camera", "actual_qty": 10, "warehouse": "Main"},
                ]
            }
        }
        client = _make_client()
        resp = client.get("/api/v2/warehouse/stock")
        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertGreaterEqual(len(data["items"]), 1)


if __name__ == "__main__":
    unittest.main()
