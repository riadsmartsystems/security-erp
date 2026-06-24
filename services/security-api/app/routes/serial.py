"""Serial routes — /api/v2/serial/* (JWT required).

Thin proxy to Frappe whitelisted serial_scan.record_serial_scan.
"""

import json

import httpx
from fastapi import APIRouter, Depends, HTTPException, status

from app.auth.dependencies import CurrentUser, get_current_user
from app.core.database import frappe_post
from app.schemas.serial import SerialScanRequest, SerialScanResponse

router = APIRouter(prefix="/api/v2/serial", tags=["serial"])


def _map_frappe_error(exc: httpx.HTTPStatusError) -> HTTPException:
    try:
        body = exc.response.json()
        msg = body.get("message", str(exc))
    except Exception:
        msg = str(exc)
    http_code = exc.response.status_code
    if http_code == 403:
        return HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail={"code": "RIAD-PERM-DENIED", "message": msg})
    return HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail={"code": "RIAD-UPSTREAM-ERROR", "message": msg})


@router.post("/record", response_model=SerialScanResponse)
async def record_serial_scan(
    body: SerialScanRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    """Record a serial scan into ERPNext.

    Calls Frappe whitelisted serial_scan.record_serial_scan via delegated user.
    """
    data: dict = {"serial_no": body.serial_no}
    if body.item:
        data["item"] = body.item
    if body.visit_uuid:
        data["visit_uuid"] = body.visit_uuid

    try:
        result = await frappe_post(
            "/api/method/security_erp.serial_scan.record_serial_scan",
            data=data,
            sid=current_user.frappe_sid,
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)

    msg = result.get("message", result)
    return SerialScanResponse(
        serial_no=msg.get("serial_no", body.serial_no),
        created=msg.get("created", False),
        linked_item=msg.get("linked_item"),
    )
