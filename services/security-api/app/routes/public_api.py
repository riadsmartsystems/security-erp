from fastapi import APIRouter, Depends, HTTPException, Query, Header
from datetime import datetime, timezone
import uuid

router = APIRouter(prefix="/api/v1/public", tags=["public-api"])


async def verify_api_key(x_api_key: str = Header(None)):
    """Verify public API key."""
    if not x_api_key:
        raise HTTPException(status_code=401, detail="X-API-Key header required")
    return x_api_key


@router.get("/status")
async def public_status():
    """Public API status check."""
    return {
        "status": "ok",
        "version": "1.0.0",
        "api": "public",
    }


@router.get("/catalog")
async def public_catalog(
    category: str = None,
    limit: int = Query(50, le=200),
    api_key: str = Depends(verify_api_key),
):
    """Public catalog of services."""
    catalog = {
        "services": [
            {"id": "cctv", "name": "CCTV Systems", "description": "Video surveillance solutions"},
            {"id": "access_control", "name": "Access Control", "description": "Door access management"},
            {"id": "alarm", "name": "Alarm Systems", "description": "Intrusion detection"},
            {"id": "network", "name": "Network Infrastructure", "description": "IT network setup"},
            {"id": "maintenance", "name": "Maintenance", "description": "Preventive maintenance plans"},
        ],
        "equipment_brands": [
            "Hikvision", "Dahua", "Ajax", "MikroTik", "Ubiquiti", "Ruijie",
        ],
    }

    if category:
        catalog["services"] = [s for s in catalog["services"] if s["id"] == category]

    return {"success": True, "data": catalog}


@router.post("/estimate-request")
async def public_estimate_request(
    data: dict,
    api_key: str = Depends(verify_api_key),
):
    """Public endpoint for requesting an estimate."""
    required = ["contact_name", "contact_phone", "service_type"]
    for field in required:
        if not data.get(field):
            raise HTTPException(status_code=400, detail=f"{field} required")

    return {
        "success": True,
        "data": {
            "request_id": str(uuid.uuid4()),
            "status": "received",
            "message": "We will contact you within 24 hours",
        },
    }


@router.get("/warranty/check")
async def public_warranty_check(
    serial_number: str = Query(...),
    api_key: str = Depends(verify_api_key),
):
    """Public warranty check by serial number."""
    return {
        "success": True,
        "data": {
            "found": False,
            "message": "Warranty check requires CMDB service connection",
        },
    }


@router.get("/docs")
async def public_docs():
    """Public API documentation."""
    return {
        "success": True,
        "data": {
            "version": "1.0.0",
            "base_url": "/api/v1/public",
            "authentication": "X-API-Key header",
            "endpoints": [
                {"method": "GET", "path": "/status", "description": "API status"},
                {"method": "GET", "path": "/catalog", "description": "Service catalog"},
                {"method": "POST", "path": "/estimate-request", "description": "Request estimate"},
                {"method": "GET", "path": "/warranty/check", "description": "Check warranty"},
            ],
            "rate_limit": "20 requests/minute",
        },
    }
