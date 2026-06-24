"""Warehouse routes — /api/v2/warehouse/* (JWT required).

Delegates Frappe queries to warehouse_service (service layer, B1).
"""

import httpx
from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.auth.dependencies import CurrentUser, get_current_user
from app.schemas.maps_warehouse import (
    WarehouseStockDetailResponse,
    WarehouseStockResponse,
    WarehouseSerialsResponse,
)
from app.services import warehouse_service

router = APIRouter(prefix="/api/v2/warehouse", tags=["warehouse"])


def _map_frappe_error(exc: httpx.HTTPStatusError) -> HTTPException:
    try:
        body = exc.response.json()
        msg = body.get("message", str(exc))
    except Exception:
        msg = str(exc)
    http_code = exc.response.status_code
    if http_code == 403:
        return HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail={"code": "RIAD-PERM-DENIED", "message": msg},
        )
    if http_code == 404:
        return HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "RIAD-NOTFOUND", "message": msg},
        )
    return HTTPException(
        status_code=status.HTTP_502_BAD_GATEWAY,
        detail={"code": "RIAD-UPSTREAM-ERROR", "message": msg},
    )


@router.get("/serials", response_model=WarehouseSerialsResponse)
async def list_serials(
    q: str = Query("", description="Search by serial_no or item name"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: CurrentUser = Depends(get_current_user),
):
    """List Serial No records with pagination and optional search."""
    try:
        return await warehouse_service.list_serials(
            sid=current_user.frappe_sid, q=q, page=page, page_size=page_size
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)


@router.get("/stock", response_model=WarehouseStockResponse)
async def list_stock(
    current_user: CurrentUser = Depends(get_current_user),
):
    """List stock balances by Item."""
    try:
        return await warehouse_service.list_stock(sid=current_user.frappe_sid)
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)


@router.get("/stock/{item}", response_model=WarehouseStockDetailResponse)
async def stock_detail(
    item: str,
    current_user: CurrentUser = Depends(get_current_user),
):
    """Get stock detail for a specific Item including its serial numbers."""
    try:
        return await warehouse_service.stock_detail(
            sid=current_user.frappe_sid, item=item
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
