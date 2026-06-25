"""S3 backend tests for POST /api/v2/media/upload."""

import io
import os
import sys
import types
import json
import pytest
import asyncio
from unittest.mock import patch, MagicMock, AsyncMock

_services_root = os.path.join(
    os.path.dirname(__file__), "..", "..", "services", "security-api"
)
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)

if "google" not in sys.modules:
    _g = types.ModuleType("google")
    sys.modules["google"] = _g
    _g_oauth2 = types.ModuleType("google.oauth2")
    sys.modules["google.oauth2"] = _g_oauth2
    _g_oauth2.service_account = types.ModuleType("google.oauth2.service_account")
    sys.modules["google.oauth2.service_account"] = _g_oauth2.service_account

if "googleapiclient" not in sys.modules:
    _ga = types.ModuleType("googleapiclient")
    sys.modules["googleapiclient"] = _ga
    _ga_discovery = types.ModuleType("googleapiclient.discovery")
    _ga_discovery.build = MagicMock()
    sys.modules["googleapiclient.discovery"] = _ga_discovery
    _ga_http = types.ModuleType("googleapiclient.http")
    _ga_http.MediaIoBaseUpload = MagicMock()
    sys.modules["googleapiclient.http"] = _ga_http

from app.services import drive_service, media_service


# --- Test 1: upload_success ---
@patch.object(drive_service, "_get_drive_service")
def test_upload_success(mock_get_drive):
    mock_service = MagicMock()
    mock_service.files().create().execute.return_value = {"id": "drive-123", "size": "1024"}
    mock_get_drive.return_value = mock_service

    result = drive_service.upload_to_drive(b"file content", "photo.jpg", "image/jpeg", "folder-id")
    assert result["drive_file_id"] == "drive-123"
    assert result["size_bytes"] == 1024


# --- Test 2: upload_sets_ai_allowed_false ---
@patch.object(media_service, "frappe_post", new_callable=AsyncMock)
@patch.object(media_service, "frappe_get", new_callable=AsyncMock)
@patch.object(drive_service, "_get_drive_service")
def test_upload_sets_ai_allowed_false(mock_get_drive, mock_frappe_get, mock_frappe_post):
    mock_service = MagicMock()
    mock_service.files().create().execute.return_value = {"id": "drive-456", "size": "2048"}
    mock_get_drive.return_value = mock_service

    mock_frappe_get.side_effect = Exception("not found")
    mock_frappe_post.return_value = {"name": "media-uuid-1"}

    from app.routes.media import media_upload
    from fastapi import UploadFile

    file = UploadFile(filename="test.jpg", file=io.BytesIO(b"content"))
    mock_user = MagicMock()
    mock_user.frappe_sid = "test-sid"

    loop = asyncio.new_event_loop()
    try:
        loop.run_until_complete(
            media_upload(
                file=file,
                client_uuid="uuid-1",
                media_type="photo",
                tag="до",
                parent_doctype="",
                parent_name="",
                user=mock_user,
            )
        )
        call_kwargs = mock_frappe_post.call_args
        data = call_kwargs[1]["data"] if "data" in call_kwargs[1] else call_kwargs[0][1]
        assert data["ai_allowed"] == 0
    finally:
        loop.close()


# --- Test 3: upload_drive_unavailable ---
@patch.object(drive_service, "_get_drive_service")
def test_upload_drive_unavailable(mock_get_drive):
    mock_get_drive.side_effect = RuntimeError("Drive API unavailable")

    with pytest.raises(RuntimeError, match="Drive API unavailable"):
        drive_service.upload_to_drive(b"content", "file.jpg", "image/jpeg")


# --- Test 4: upload_jwt_required ---
def test_upload_jwt_required():
    from fastapi.testclient import TestClient
    from app.main import app

    client = TestClient(app, raise_server_exceptions=False)
    response = client.post("/api/v2/media/upload")
    assert response.status_code in (401, 403, 422)
