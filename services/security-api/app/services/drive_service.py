"""Google Drive upload service using service account credentials."""

from __future__ import annotations

import logging
import os

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseUpload

from app.core.config import settings

logger = logging.getLogger("drive.service")

_SCOPES = ["https://www.googleapis.com/auth/drive.file"]


def _get_drive_service():
    """Build Google Drive API service from service account JSON."""
    sa_path = settings.google_service_account_json
    if not sa_path or not os.path.exists(sa_path):
        raise RuntimeError("Google service account JSON not configured or not found")

    creds = service_account.Credentials.from_service_account_file(sa_path, scopes=_SCOPES)
    return build("drive", "v3", credentials=creds, cache_discovery=False)


def upload_to_drive(
    file_content: bytes,
    filename: str,
    mime_type: str,
    folder_id: str | None = None,
) -> dict:
    """Upload file to Google Drive and return file metadata.

    Returns:
        {"drive_file_id": str, "size_bytes": int}
    """
    service = _get_drive_service()
    target_folder = folder_id or settings.google_drive_folder_id

    media = MediaIoBaseUpload(
        __import__("io").BytesIO(file_content),
        mimetype=mime_type,
        resumable=False,
    )

    file_metadata = {"name": filename}
    if target_folder:
        file_metadata["parents"] = [target_folder]

    created = (
        service.files()
        .create(body=file_metadata, media_body=media, fields="id,size")
        .execute()
    )

    return {
        "drive_file_id": created["id"],
        "size_bytes": int(created.get("size", len(file_content))),
    }
