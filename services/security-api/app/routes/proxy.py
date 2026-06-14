import json
import httpx
from fastapi import APIRouter, Depends, Request, Response
from app.core.config import settings
from app.auth.dependencies import get_current_user, CurrentUser
from app.auth.permissions import Permission, has_permission

router = APIRouter(tags=["proxy"])

SERVICE_MAP = {
    "/api/v1/tickets": settings.fsm_service_url,
    "/api/v1/visits": settings.fsm_service_url,
    "/api/v1/maintenance": settings.fsm_service_url,
    "/api/v1/warranty": settings.fsm_service_url,
    "/api/v1/checklists": settings.fsm_service_url,
    "/api/v1/dispatch": settings.fsm_service_url,
    "/api/v1/objects": settings.cmdb_service_url,
    "/api/v1/equipment": settings.cmdb_service_url,
    "/api/v1/equipment-types": settings.cmdb_service_url,
    "/api/v1/vendors": settings.cmdb_service_url,
    "/api/v1/topology": settings.cmdb_service_url,
    "/api/v1/photos": settings.cmdb_service_url,
    "/api/v1/backups": settings.cmdb_service_url,
    "/api/v1/integrations": settings.cmdb_service_url,
    "/api/v1/ai": settings.ai_service_url,
}

PERMISSION_MAP = {
    "/api/v1/tickets": [Permission.FSM_FULL, Permission.FSM_OWN],
    "/api/v1/visits": [Permission.FSM_FULL, Permission.FSM_OWN],
    "/api/v1/maintenance": [Permission.FSM_FULL],
    "/api/v1/warranty": [Permission.FSM_FULL],
    "/api/v1/objects": [Permission.CMDB_FULL, Permission.CMDB_READ],
    "/api/v1/equipment": [Permission.CMDB_FULL, Permission.CMDB_READ],
    "/api/v1/equipment-types": [Permission.CMDB_FULL, Permission.CMDB_READ],
    "/api/v1/vendors": [Permission.CMDB_FULL, Permission.CMDB_READ],
    "/api/v1/topology": [Permission.CMDB_FULL, Permission.CMDB_READ],
    "/api/v1/checklists": [Permission.FSM_FULL, Permission.FSM_OWN],
    "/api/v1/photos": [Permission.CMDB_FULL, Permission.CMDB_READ],
    "/api/v1/backups": [Permission.CMDB_FULL],
    "/api/v1/integrations": [Permission.CMDB_FULL],
    "/api/v1/dispatch": [Permission.FSM_FULL],
    "/api/v1/ai": [Permission.AI_FULL, Permission.AI_LIMITED, Permission.AI_OWN],
}


def _has_access(current_user: CurrentUser, path: str) -> bool:
    for prefix, perms in PERMISSION_MAP.items():
        if path.startswith(prefix):
            return any(has_permission(current_user.role, p) for p in perms)
    return True


def _get_service_url(path: str) -> str | None:
    for prefix, url in SERVICE_MAP.items():
        if path.startswith(prefix):
            return url
    return None


@router.api_route("/api/v1/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"], include_in_schema=False)
async def proxy(
    path: str,
    request: Request,
    current_user: CurrentUser = Depends(get_current_user),
):
    full_path = f"/api/v1/{path}"
    service_url = _get_service_url(full_path)

    if not service_url:
        return Response(
            status_code=404,
            content=json.dumps({"success": False, "error": "Route not found"}),
            media_type="application/json",
        )

    if not _has_access(current_user, full_path):
        return Response(
            status_code=403,
            content=json.dumps({"success": False, "error": "Access denied"}),
            media_type="application/json",
        )

    target_url = f"{service_url}{request.url.path}"
    if request.url.query:
        target_url += f"?{request.url.query}"

    body = None
    if request.method in ("POST", "PUT", "PATCH"):
        try:
            body = await request.body()
        except Exception:
            body = None

    headers = {
        "Content-Type": request.headers.get("content-type", "application/json"),
        "X-User-Id": current_user.user_id,
        "X-User-Role": current_user.role.value,
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.request(
                method=request.method,
                url=target_url,
                content=body,
                headers=headers,
            )

        return Response(
            status_code=resp.status_code,
            content=resp.content,
            media_type="application/json",
        )
    except httpx.ConnectError:
        return Response(
            status_code=502,
            content=json.dumps({"success": False, "error": f"Service unavailable: {service_url}"}),
            media_type="application/json",
        )
    except Exception as e:
        return Response(
            status_code=500,
            content=json.dumps({"success": False, "error": str(e)}),
            media_type="application/json",
        )
