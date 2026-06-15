import json
import httpx
from fastapi import APIRouter, Depends, Request, Response
from app.core.config import settings
from app.auth.dependencies import get_current_user, CurrentUser
from app.auth.permissions import Permission, has_permission

router = APIRouter(tags=["proxy"])

# Global client for proxy
_proxy_client = httpx.AsyncClient(
    timeout=30.0,
    limits=httpx.Limits(
        max_connections=50,
        max_keepalive_connections=20,
        keepalive_expiry=30,
    ),
)

# Frappe API key header
_frappe_auth = f"token {settings.frappe_api_key}:{settings.frappe_api_secret}" if settings.frappe_api_key else ""

FRAPPE_DOCTYPE_MAP = {
    "/api/v1/tickets": "Service Ticket",
    "/api/v1/visits": "Visit",
    "/api/v1/maintenance": "Maintenance Plan",
    "/api/v1/warranty": "Warranty Case",
    "/api/v1/objects": "Security Object",
    "/api/v1/equipment": "Equipment",
    "/api/v1/equipment-types": "Equipment Type",
    "/api/v1/vendors": "Vendor",
    "/api/v1/topology": "Equipment Relation",
    "/api/v1/photos": "Visit Photo",
}

FRAPPE_ROLE_MAP = {
    "owner": ["System Manager", "Service Manager", "Projects Manager", "Warehouse Manager"],
    "director": ["System Manager", "Service Manager", "Projects Manager"],
    "service_manager": ["Service Manager"],
    "project_manager": ["Projects Manager", "Service Manager"],
    "engineer": ["Engineer"],
    "warehouse": ["Warehouse Manager"],
    "sales_manager": ["Sales Manager"],
    "accountant": ["Accounts Manager"],
    "viewer": [],
}

ROLE_PATH_PERMISSIONS = {
    "/api/v1/tickets": ["Service Manager", "System Manager", "Projects Manager", "Engineer"],
    "/api/v1/visits": ["Service Manager", "System Manager", "Projects Manager", "Engineer"],
    "/api/v1/maintenance": ["Service Manager", "System Manager"],
    "/api/v1/warranty": ["Service Manager", "System Manager"],
    "/api/v1/objects": ["Service Manager", "System Manager", "Projects Manager", "Warehouse Manager"],
    "/api/v1/equipment": ["Service Manager", "System Manager", "Projects Manager", "Warehouse Manager"],
    "/api/v1/vendors": ["Service Manager", "System Manager", "Projects Manager", "Warehouse Manager"],
}


def _has_access(current_user: CurrentUser, path: str) -> bool:
    user_roles = FRAPPE_ROLE_MAP.get(current_user.role, [])
    for prefix, allowed_roles in ROLE_PATH_PERMISSIONS.items():
        if path.startswith(prefix):
            return any(r in allowed_roles for r in user_roles)
    return True


def _get_doctype(path: str) -> str | None:
    for prefix, doctype in FRAPPE_DOCTYPE_MAP.items():
        if path.startswith(prefix):
            return doctype
    return None


@router.api_route("/api/v1/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"], include_in_schema=False)
async def proxy(
    path: str,
    request: Request,
    current_user: CurrentUser = Depends(get_current_user),
):
    full_path = f"/api/v1/{path}"
    doctype = _get_doctype(full_path)

    if not doctype:
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

    frappe_url = f"/api/resource/{doctype.replace(' ', '%20')}"
    headers = {"Authorization": _frappe_auth}

    body = None
    if request.method in ("POST", "PUT", "PATCH"):
        body = await request.body()

    try:
        resp = await _proxy_client.request(
            method=request.method,
            url=f"{settings.frappe_url}{frappe_url}",
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
            content=json.dumps({"success": False, "error": "Frappe unavailable"}),
            media_type="application/json",
        )
    except Exception as e:
        return Response(
            status_code=500,
            content=json.dumps({"success": False, "error": str(e)}),
            media_type="application/json",
        )
