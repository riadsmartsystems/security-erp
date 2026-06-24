"""RQ task: transcribe_media — send audio to Whisper, write transcription to Media Asset.

Triggered by: voice note upload (Flutter/Web).
Degradation: status='pending' → manual text entry.
"""

from __future__ import annotations

import logging
import time

import frappe
import requests

logger = logging.getLogger("rq.task.transcribe")

WHISPER_URL = "http://whisper:8000/transcribe"
WHISPER_TIMEOUT = 120  # seconds


def on_media_asset_insert(doc, method=None):
    """after_insert hook: auto-enqueue transcription for audio Media Assets."""
    if not getattr(doc, "drive_file_id", None):
        return
    media_type = getattr(doc, "media_type", "") or ""
    if "audio" in media_type.lower() or "voice" in media_type.lower():
        enqueue_transcribe(doc.name)


def enqueue_transcribe(media_asset_name: str) -> None:
    """Public entry point: enqueue RQ job for async transcription.

    Called from hooks or API endpoint. Uses Frappe's built-in RQ.
    """
    frappe.enqueue(
        "security_erp.tasks.transcribe.transcribe_media",
        media_asset_name=media_asset_name,
        queue="long",
        timeout=600,
    )


def transcribe_media(media_asset_name: str) -> dict:
    """Download audio from Media Asset → POST to Whisper → write transcription.

    Returns: {"status": "done"|"error", "text": str, "language": str, "duration": float}
    """
    doc = frappe.get_doc("Media Asset", media_asset_name)
    if not doc.drive_file_id:
        _set_status(doc, "failed")
        return {"status": "error", "reason": "no_drive_file_id"}

    drive_id = doc.drive_file_id
    if drive_id.startswith("http"):
        audio_url = drive_id
    else:
        audio_url = f"https://drive.google.com/uc?export=download&id={drive_id}"

    _set_status(doc, "processing")

    try:
        audio_resp = requests.get(audio_url, timeout=30)
        audio_resp.raise_for_status()
    except Exception as exc:
        logger.error("Failed to download audio for %s: %s", media_asset_name, exc)
        _set_status(doc, "failed")
        return {"status": "error", "reason": f"download_failed: {exc}"}

    content_type = audio_resp.headers.get("content-type", "audio/ogg")
    ext = _ext_from_content_type(content_type)

    try:
        resp = requests.post(
            WHISPER_URL,
            files={"audio": (f"audio.{ext}", audio_resp.content, content_type)},
            timeout=WHISPER_TIMEOUT,
        )
        resp.raise_for_status()
    except requests.exceptions.ConnectionError:
        logger.warning("Whisper service unavailable for %s", media_asset_name)
        _set_status(doc, "pending")
        return {"status": "error", "reason": "whisper_unavailable"}
    except Exception as exc:
        logger.error("Whisper transcription failed for %s: %s", media_asset_name, exc)
        _set_status(doc, "failed")
        return {"status": "error", "reason": f"whisper_error: {exc}"}

    result = resp.json()
    text = result.get("text", "")
    language = result.get("language", "unknown")
    duration = result.get("duration", 0.0)

    doc.transcription = text
    doc.db_set("transcription", text, update_modified=False)
    _set_status(doc, "done")

    logger.info("Transcribed %s: lang=%s, duration=%.1fs, chars=%d",
                media_asset_name, language, duration, len(text))

    return {"status": "done", "text": text, "language": language, "duration": duration}


def _set_status(doc, status: str):
    """Set transcription_status field on Media Asset (best-effort)."""
    try:
        doc.db_set("transcription_status", status, update_modified=False)
        frappe.db.commit()
    except Exception:
        frappe.db.commit()


def _ext_from_content_type(ct: str) -> str:
    mapping = {
        "audio/ogg": "ogg",
        "audio/mpeg": "mp3",
        "audio/mp4": "m4a",
        "audio/wav": "wav",
        "audio/webm": "webm",
        "audio/x-m4a": "m4a",
    }
    for key, ext in mapping.items():
        if key in ct:
            return ext
    return "ogg"
