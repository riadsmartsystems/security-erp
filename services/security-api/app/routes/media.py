"""Media endpoints — /api/v2/media/*.

POST /api/v2/media/upload              — multipart upload to Drive + create/update Media Asset
POST /api/v2/media/{name}/transcribe   — RQ enqueue transcription
POST /api/v2/media/{name}/transcription — manual text entry (degradation)
"""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form

from app.auth.dependencies import CurrentUser, get_current_user
from app.schemas.media import MediaUploadResponse, TranscriptionManualRequest, TranscriptionResponse
from app.services import media_service

logger = logging.getLogger("media.routes")

router = APIRouter(prefix="/api/v2/media", tags=["media"])


@router.post("/upload", response_model=MediaUploadResponse)
async def media_upload(
    file: UploadFile = File(...),
    client_uuid: str = Form(...),
    media_type: str = Form(...),
    tag: str = Form(""),
    parent_doctype: str = Form(""),
    parent_name: str = Form(""),
    user: CurrentUser = Depends(get_current_user),
):
    """Upload media file to Google Drive and create/update Media Asset in Frappe.

    ai_allowed is always 0 (ІНВАРІАНТ — конституція п.4).
    """
    content = await file.read()
    if not content:
        raise HTTPException(status_code=422, detail={"code": "RIAD-VALIDATION", "message": "Empty file"})

    mime_type = file.content_type or "application/octet-stream"
    filename = file.filename or f"{client_uuid}_{media_type}"

    try:
        from app.services.drive_service import upload_to_drive
        result = upload_to_drive(content, filename, mime_type)
    except Exception as exc:
        logger.error("Drive upload failed: %s", exc)
        raise HTTPException(
            status_code=503,
            detail={"code": "RIAD-DRIVE-UNAVAILABLE", "message": "Drive upload failed, retry later"},
        )

    drive_file_id = result["drive_file_id"]
    size_bytes = result["size_bytes"]

    try:
        await media_service.upsert_media_asset(
            sid=user.frappe_sid,
            client_uuid=client_uuid,
            drive_file_id=drive_file_id,
            media_type=media_type,
            tag=tag,
            parent_doctype=parent_doctype,
            parent_name=parent_name,
        )
    except Exception as exc:
        logger.error("Frappe Media Asset upsert failed: %s", exc)
        raise HTTPException(status_code=502, detail={"code": "RIAD-INTERNAL", "message": "Media Asset creation failed"})

    return MediaUploadResponse(
        client_uuid=client_uuid,
        drive_file_id=drive_file_id,
        size_bytes=size_bytes,
    )


@router.post("/{name}/transcribe", response_model=TranscriptionResponse)
async def media_transcribe(
    name: str,
    user: CurrentUser = Depends(get_current_user),
):
    """Enqueue RQ task for Whisper transcription (A3)."""
    try:
        await media_service.enqueue_transcription(sid=user.frappe_sid, name=name)
    except Exception as exc:
        status_code = getattr(getattr(exc, "response", None), "status_code", None)
        if status_code == 404:
            raise HTTPException(status_code=404, detail={"code": "RIAD-NOTFOUND", "message": "Media Asset not found"})
        logger.error("media.transcribe enqueue failed: %s", exc)
        raise HTTPException(status_code=502, detail=f"Transcription enqueue failed: {exc}")

    return TranscriptionResponse(status="queued")


@router.post("/{name}/transcription", response_model=TranscriptionResponse)
async def media_transcription_manual(
    name: str,
    body: TranscriptionManualRequest,
    user: CurrentUser = Depends(get_current_user),
):
    """Manual transcription text entry — degradation when Whisper unavailable."""
    try:
        await media_service.save_manual_transcription(sid=user.frappe_sid, name=name, text=body.text)
    except Exception as exc:
        status_code = getattr(getattr(exc, "response", None), "status_code", None)
        if status_code == 404:
            raise HTTPException(status_code=404, detail={"code": "RIAD-NOTFOUND", "message": "Media Asset not found"})
        logger.error("media.transcription manual failed: %s", exc)
        raise HTTPException(status_code=502, detail=f"Manual transcription failed: {exc}")

    try:
        from app.services.push_service import fire_and_forget_push
        fire_and_forget_push(user_id=user.user_id, title="Транскрипція готова", body=f"Транскрипція для {name} готова.", data={"type": "transcription_ready", "name": name})
    except Exception as e:
        logger.warning("Push schedule failed for transcription_ready: %s", e)

    return TranscriptionResponse(status="manual")
