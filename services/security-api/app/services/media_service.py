"""Media Asset service — upsert/transcribe/manual-transcription via Frappe REST API.

All Frappe calls use delegated SID (B1). No Administrator access.
ai_allowed is ALWAYS 0 — конституція п.4, незмінний інваріант.
"""

from __future__ import annotations

import logging

from app.core.database import frappe_get, frappe_post, frappe_put

logger = logging.getLogger("media.service")


async def upsert_media_asset(
    *,
    sid: str,
    client_uuid: str,
    drive_file_id: str,
    media_type: str,
    tag: str,
    parent_doctype: str,
    parent_name: str,
) -> None:
    """Create or update Media Asset in Frappe after successful Drive upload.

    Tries GET first; on any exception falls through to POST (create).
    ai_allowed is always 0.
    """
    try:
        await frappe_get(f"/api/resource/Media Asset/{client_uuid}", sid=sid)
        await frappe_put(
            f"/api/resource/Media Asset/{client_uuid}",
            data={
                "drive_file_id": drive_file_id,
                "media_type": media_type,
                "tag": tag,
                "parent_doctype": parent_doctype,
                "parent_name": parent_name,
                "ai_allowed": 0,
            },
            sid=sid,
        )
    except Exception:
        await frappe_post(
            "/api/resource/Media Asset",
            data={
                "client_uuid": client_uuid,
                "drive_file_id": drive_file_id,
                "media_type": media_type,
                "tag": tag,
                "parent_doctype": parent_doctype,
                "parent_name": parent_name,
                "ai_allowed": 0,
            },
            sid=sid,
        )


async def enqueue_transcription(*, sid: str, name: str) -> None:
    """Verify Media Asset exists then enqueue Whisper transcription via RQ."""
    await frappe_get(f"/api/resource/Media Asset/{name}", sid=sid)
    await frappe_post(
        "/api/method/security_erp.tasks.transcribe.enqueue_transcribe",
        data={"media_asset_name": name},
        sid=sid,
    )


async def save_manual_transcription(*, sid: str, name: str, text: str) -> None:
    """Verify Media Asset exists then save manual transcription text."""
    await frappe_get(f"/api/resource/Media Asset/{name}", sid=sid)
    await frappe_put(
        f"/api/resource/Media Asset/{name}",
        data={
            "transcription": text,
            "transcription_status": "manual",
        },
        sid=sid,
    )
