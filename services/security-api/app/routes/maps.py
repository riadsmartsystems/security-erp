"""Map routes — /api/v2/maps/* (JWT required).

Proxies to Frappe for Installation Map CRUD via map_service.
"""

import httpx
from fastapi import APIRouter, Depends, HTTPException, status

from app.auth.dependencies import CurrentUser, get_current_user
from app.auth.permissions import Role
from app.schemas.maps_warehouse import (
    CableRouteDto,
    MapApproveResponse,
    MapPointRequest,
    MapPointResponse,
    MapResponse,
    MountPointDto,
)
from app.services import map_service

router = APIRouter(prefix="/api/v2/maps", tags=["maps"])


def _map_frappe_error(exc: httpx.HTTPStatusError) -> HTTPException:
    try:
        body = exc.response.json()
        msg = body.get("message", str(exc))
    except Exception:
        msg = str(exc)
    http_code = exc.response.status_code
    if http_code == 403:
        return HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail={"code": "RIAD-PERM-DENIED", "message": msg})
    if http_code == 404:
        return HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"code": "RIAD-NOTFOUND", "message": msg})
    return HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail={"code": "RIAD-UPSTREAM-ERROR", "message": msg})


@router.get("/{name}", response_model=MapResponse)
async def get_map(
    name: str,
    current_user: CurrentUser = Depends(get_current_user),
):
    """Get Installation Map with child mount_points and cable_routes."""
    try:
        data = await map_service.get_map(sid=current_user.frappe_sid, name=name)
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)

    mount_points = [
        MountPointDto(**{k: v for k, v in row.items() if k in MountPointDto.model_fields})
        for row in (data.get("mount_points") or [])
    ]
    cable_routes = [
        CableRouteDto(**{k: v for k, v in row.items() if k in CableRouteDto.model_fields})
        for row in (data.get("cable_routes") or [])
    ]

    return MapResponse(
        name=data.get("name", name),
        passport=data.get("passport"),
        map_kind=data.get("map_kind", "територія"),
        base_plan_media=data.get("base_plan_media"),
        approved_by=data.get("approved_by"),
        approved_at=data.get("approved_at"),
        mount_points=mount_points,
        cable_routes=cable_routes,
    )


@router.post("/{name}/points", response_model=MapPointResponse)
async def add_mount_point(
    name: str,
    body: MapPointRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    """Add a Mount Point to an Installation Map (idempotent by point_uuid)."""
    point_data = body.model_dump(exclude_none=True)
    try:
        result_status = await map_service.add_mount_point(
            sid=current_user.frappe_sid,
            name=name,
            point_uuid=body.point_uuid,
            point_data=point_data,
        )
    except ValueError as exc:
        raise HTTPException(status_code=422, detail={"code": "RIAD-VALIDATION", "message": str(exc)})
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)

    return MapPointResponse(point_uuid=body.point_uuid, status=result_status)


@router.post("/{name}/approve", response_model=MapApproveResponse)
async def approve_map(
    name: str,
    current_user: CurrentUser = Depends(get_current_user),
):
    """Approve an Installation Map. Only engineer role allowed."""
    if not current_user.has_frappe_role("Технік") and current_user.role != Role.ENGINEER:
        raise HTTPException(status_code=403, detail={"code": "RIAD-PERM-DENIED", "message": "Only engineers can approve maps"})

    try:
        approved_at = await map_service.approve_map(
            sid=current_user.frappe_sid,
            name=name,
            user_id=current_user.user_id,
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)

    return MapApproveResponse(name=name, approved_by=current_user.user_id, approved_at=approved_at)
