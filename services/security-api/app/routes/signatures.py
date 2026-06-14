from fastapi import APIRouter, Query
import uuid

router = APIRouter(prefix="/api/v1/signatures", tags=["signatures"])


@router.get("/requests")
async def list_signature_requests(
    status: str = None,
    limit: int = Query(50, le=200),
):
    return {"success": True, "data": [], "message": "Digital signature not configured"}


@router.post("/requests")
async def create_signature_request(data: dict = None):
    return {
        "success": True,
        "message": "Digital signature not configured. Set VCHASNO_TOKEN or DIA_TOKEN",
        "data": {"id": str(uuid.uuid4()), "status": "pending"},
    }


@router.get("/requests/{request_id}")
async def get_signature_status(request_id: str):
    return {"success": True, "data": {"id": request_id, "status": "pending"}}


@router.post("/requests/{request_id}/callback")
async def signature_callback(request_id: str, data: dict = None):
    return {"success": True, "message": "Callback received"}
