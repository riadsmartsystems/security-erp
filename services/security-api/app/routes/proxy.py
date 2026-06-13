from fastapi import APIRouter, Depends, Request, Response
from fastapi.responses import StreamingResponse
import httpx
from tenacity import retry, stop_after_attempt, wait_fixed, retry_if_exception_type

from app.core.config import settings
from app.auth.dependencies import get_current_user, CurrentUser
from app.auth.permissions import Permission

router = APIRouter(tags=["proxy"])

BACKEND_MAP = {
    "/api/v1/tickets": settings.fsm_service_url,
    "/api/v1/visits": settings.fsm_service_url,
    "/api/v1/maintenance": settings.fsm_service_url,
    "/api/v1/warranty": settings.fsm_service_url,
    "/api/v1/objects": settings.cmdb_service_url,
    "/api/v1/equipment": settings.cmdb_service_url,
    "/api/v1/topology": settings.cmdb_service_url,
    "/api/v1/configurations": settings.cmdb_service_url,
}

PERMISSION_MAP = {
    "/api/v1/tickets": Permission.FSM_FULL,
    "/api/v1/visits": Permission.FSM_FULL,
    "/api/v1/maintenance": Permission.FSM_FULL,
    "/api/v1/warranty": Permission.FSM_FULL,
    "/api/v1/objects": Permission.CMDB_READ,
    "/api/v1/equipment": Permission.CMDB_READ,
    "/api/v1/topology": Permission.CMDB_READ,
    "/api/v1/configurations": Permission.CMDB_READ,
}


def _get_backend(path: str) -> str | None:
    for prefix, url in BACKEND_MAP.items():
        if path.startswith(prefix):
            return url
    return None


async def _proxy_request(method: str, url: str, headers: dict, body: bytes | None):
    async with httpx.AsyncClient(timeout=30.0) as client:
        return await client.request(method=method, url=url, headers=headers, content=body)


@router.api_route("/api/v1/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"], include_in_schema=False)
async def proxy(
    path: str,
    request: Request,
    current_user: CurrentUser = Depends(get_current_user),
):
    full_path = f"/api/v1/{path}"
    backend_url = _get_backend(full_path)

    if not backend_url:
        return Response(status_code=404, content='{"success":false,"error":{"code":"NOT_FOUND","message":"Route not found"}}')

    permission = PERMISSION_MAP.get(full_path.split("?")[0].rstrip("/"))
    for prefix, perm in PERMISSION_MAP.items():
        if full_path.startswith(prefix):
            permission = perm
            break

    if permission:
        current_user.require(permission)

    target_url = f"{backend_url}{full_path}"
    headers = dict(request.headers)
    headers["X-User-Id"] = current_user.user_id
    headers["X-User-Role"] = current_user.role.value
    headers.pop("host", None)

    body = await request.body()

    try:
        resp = await _proxy_request(request.method, target_url, headers, body if body else None)
        return Response(
            content=resp.content,
            status_code=resp.status_code,
            headers=dict(resp.headers),
        )
    except httpx.ConnectError:
        return Response(
            status_code=503,
            content='{"success":false,"error":{"code":"SERVICE_UNAVAILABLE","message":"Backend service unavailable"}}',
        )
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response(
            status_code=502,
            content=f'{{"success":false,"error":{{"code":"BAD_GATEWAY","message":"{str(e)}"}}}}',
        )
