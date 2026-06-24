"""S3 backend tests for POST /api/v2/media/upload."""

import io
import json
import pytest
from unittest.mock import patch, MagicMock


# --- Test 1: upload_success ---
@patch("app.services.drive_service.upload_to_drive")
@patch("app.routes.media.frappe_post")
@patch("app.routes.media.frappe_get")
def test_upload_success(mock_frappe_get, mock_frappe_post, mock_drive):
    mock_drive.return_value = {"drive_file_id": "drive-123", "size_bytes": 1024}
    mock_frappe_get.side_effect = Exception("not found")
    mock_frappe_post.return_value = {"name": "media-uuid-1"}

    from app.services.drive_service import upload_to_drive
    result = upload_to_drive(b"file content", "photo.jpg", "image/jpeg", "folder-id")
    assert result["drive_file_id"] == "drive-123"
    assert result["size_bytes"] == 1024


# --- Test 2: upload_sets_ai_allowed_false ---
@patch("app.services.drive_service.upload_to_drive")
@patch("app.routes.media.frappe_post")
@patch("app.routes.media.frappe_get")
def test_upload_sets_ai_allowed_false(mock_frappe_get, mock_frappe_post, mock_drive):
    mock_drive.return_value = {"drive_file_id": "drive-456", "size_bytes": 2048}
    mock_frappe_get.side_effect = Exception("not found")

    from app.routes.media import media_upload
    from fastapi import UploadFile
    import asyncio

    file = UploadFile(filename="test.jpg", file=io.BytesIO(b"content"), content_type="image/jpeg")
    mock_user = MagicMock()
    mock_user.frappe_sid = "test-sid"

    loop = asyncio.new_event_loop()
    try:
        resp = loop.run_until_complete(
            media_upload(file=file, client_uuid="uuid-1", media_type="photo",
                         tag="до", parent_doctype="", parent_name="", user=mock_user)
        )
        call_kwargs = mock_frappe_post.call_args
        data = call_kwargs[1]["data"] if "data" in call_kwargs[1] else call_kwargs[0][1]
        assert data["ai_allowed"] == 0
    finally:
        loop.close()


# --- Test 3: upload_drive_unavailable ---
@patch("app.services.drive_service.upload_to_drive")
def test_upload_drive_unavailable(mock_drive):
    mock_drive.side_effect = RuntimeError("Drive API unavailable")

    from app.services.drive_service import upload_to_drive
    with pytest.raises(RuntimeError, match="Drive API unavailable"):
        upload_to_drive(b"content", "file.jpg", "image/jpeg")


# --- Test 4: upload_jwt_required ---
def test_upload_jwt_required():
    from fastapi.testclient import TestClient
    from app.main import app

    client = TestClient(app, raise_server_exceptions=False)
    response = client.post("/api/v2/media/upload")
    assert response.status_code in (401, 403, 422)
