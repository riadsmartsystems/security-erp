from fastapi import APIRouter, HTTPException, Query
from datetime import datetime, timezone
import uuid

router = APIRouter(prefix="/api/v1/portal", tags=["customer-portal"])


@router.get("/dashboard")
async def portal_dashboard(
    customer_id: str = Query(...),
):
    """Customer portal: dashboard summary."""
    return {
        "success": True,
        "data": {
            "objects": 0,
            "total_tickets": 0,
            "open_tickets": 0,
            "message": "Connect to FSM/CMDB services for live data",
        },
    }


@router.get("/tickets")
async def portal_tickets(
    customer_id: str = Query(...),
    status: str = None,
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
):
    """Customer portal: list tickets."""
    return {
        "success": True,
        "data": [],
        "message": "Proxy to FSM service",
    }


@router.get("/tickets/{ticket_id}")
async def portal_ticket_detail(
    ticket_id: str,
    customer_id: str = Query(...),
):
    """Customer portal: get ticket details."""
    return {
        "success": True,
        "data": {"id": ticket_id},
        "message": "Proxy to FSM service",
    }


@router.post("/tickets")
async def portal_create_ticket(
    data: dict,
    customer_id: str = Query(...),
):
    """Customer portal: create a new ticket."""
    return {
        "success": True,
        "data": {
            "id": str(uuid.uuid4()),
            "ticket_number": f"TKT-{uuid.uuid4().hex[:6].upper()}",
            "status": "new",
        },
    }


@router.get("/objects")
async def portal_objects(
    customer_id: str = Query(...),
):
    """Customer portal: list objects."""
    return {
        "success": True,
        "data": [],
        "message": "Proxy to CMDB service",
    }


@router.get("/equipment")
async def portal_equipment(
    object_id: str = Query(...),
    customer_id: str = Query(...),
):
    """Customer portal: list equipment."""
    return {
        "success": True,
        "data": [],
        "message": "Proxy to CMDB service",
    }
