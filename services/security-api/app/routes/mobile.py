from fastapi import APIRouter, HTTPException, Query
from datetime import datetime, timezone
import uuid

router = APIRouter(prefix="/api/v1/mobile", tags=["mobile"])


@router.get("/dashboard")
async def mobile_dashboard(
    engineer_id: str = Query(...),
):
    """Mobile dashboard for engineer."""
    return {
        "success": True,
        "data": {
            "my_tickets": 0,
            "today_visits": 0,
            "pending_photos": 0,
            "unread_notifications": 0,
        },
    }


@router.get("/my-tasks")
async def mobile_my_tasks(
    engineer_id: str = Query(...),
    status: str = None,
    limit: int = Query(20, le=50),
):
    """Mobile: list tasks for engineer."""
    return {
        "success": True,
        "data": [],
    }


@router.post("/upload-chunk")
async def mobile_upload_chunk(
    data: dict,
):
    """Mobile: chunked file upload for large photos."""
    chunk_id = data.get("chunk_id", str(uuid.uuid4()))
    return {
        "success": True,
        "data": {
            "chunk_id": chunk_id,
            "received": True,
        },
    }


@router.post("/sync")
async def mobile_sync(
    data: dict,
):
    """Mobile: offline sync endpoint."""
    changes = data.get("changes", [])
    return {
        "success": True,
        "data": {
            "synced": len(changes),
            "server_time": datetime.now(timezone.utc).isoformat(),
            "conflicts": [],
        },
    }


@router.get("/offline-data")
async def mobile_offline_data(
    engineer_id: str = Query(...),
):
    """Mobile: get data for offline mode."""
    return {
        "success": True,
        "data": {
            "tickets": [],
            "sync_time": datetime.now(timezone.utc).isoformat(),
        },
    }


@router.post("/gps-location")
async def mobile_gps_location(
    data: dict,
):
    """Mobile: report GPS location."""
    return {
        "success": True,
        "data": {
            "received": True,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        },
    }


@router.get("/notifications")
async def mobile_notifications(
    engineer_id: str = Query(...),
    limit: int = Query(20, le=50),
):
    """Mobile: get notifications."""
    return {
        "success": True,
        "data": [],
    }
