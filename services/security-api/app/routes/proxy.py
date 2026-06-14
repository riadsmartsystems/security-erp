import json
import httpx
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, Request, Response
from app.core.config import settings
from app.auth.dependencies import get_current_user, CurrentUser
from app.auth.permissions import Permission, has_permission

router = APIRouter(tags=["proxy"])

# Map API paths to Frappe DocType resources
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
    "/api/v1/backups": "Config Backup",
    "/api/v1/integrations": "Vendor",
    "/api/v1/dispatch": "Service Ticket",
    "/api/v1/ai": "Service Ticket",
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
    "/api/v1/photos": [Permission.CMDB_FULL, Permission.CMDB_READ],
    "/api/v1/backups": [Permission.CMDB_FULL],
    "/api/v1/integrations": [Permission.CMDB_FULL],
    "/api/v1/dispatch": [Permission.FSM_FULL],
    "/api/v1/ai": [Permission.AI_FULL, Permission.AI_LIMITED, Permission.AI_OWN],
}


def _has_access(current_user: CurrentUser, path: str) -> bool:
    """Check access using Frappe role-based model"""
    # Map Frappe roles to permissions
    frappe_role_permissions = {
        "/api/v1/tickets": ["Service Manager", "System Manager", "Projects Manager"],
        "/api/v1/visits": ["Service Manager", "System Manager", "Projects Manager"],
        "/api/v1/maintenance": ["Service Manager", "System Manager", "Projects Manager"],
        "/api/v1/warranty": ["Service Manager", "System Manager", "Projects Manager"],
        "/api/v1/objects": ["Service Manager", "System Manager", "Projects Manager", "Warehouse Manager"],
        "/api/v1/equipment": ["Service Manager", "System Manager", "Projects Manager", "Warehouse Manager"],
        "/api/v1/equipment-types": ["Service Manager", "System Manager", "Projects Manager", "Warehouse Manager"],
        "/api/v1/vendors": ["Service Manager", "System Manager", "Projects Manager", "Warehouse Manager"],
        "/api/v1/topology": ["Service Manager", "System Manager", "Projects Manager", "Warehouse Manager"],
        "/api/v1/photos": ["Service Manager", "System Manager", "Projects Manager", "Warehouse Manager"],
        "/api/v1/backups": ["Service Manager", "System Manager"],
        "/api/v1/integrations": ["Service Manager", "System Manager"],
        "/api/v1/dispatch": ["Service Manager", "System Manager"],
        "/api/v1/ai": ["Service Manager", "System Manager"],
    }
    
    # Map our internal roles to Frappe roles
    frappe_roles = {
        "owner": ["System Manager", "Service Manager", "Projects Manager", "Warehouse Manager"],
        "director": ["System Manager", "Service Manager", "Projects Manager", "Warehouse Manager"],
        "service_manager": ["Service Manager"],
        "project_manager": ["Projects Manager", "Service Manager"],
        "engineer": ["Engineer"],
        "warehouse": ["Warehouse Manager"],
        "sales_manager": ["Sales Manager"],
        "accountant": ["Accounts Manager"],
        "viewer": [],
    }
    
    user_roles = frappe_roles.get(current_user.role, [])
    
    for prefix, required_roles in frappe_role_permissions.items():
        if path.startswith(prefix):
            return any(role in required_roles for role in user_roles)
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

    frappe_url = f"{settings.frappe_url}/api/resource/{doctype.replace(' ', '%20')}"

    body = None
    if request.method in ("POST", "PUT", "PATCH"):
        try:
            body = await request.body()
        except Exception:
            body = None

    headers = {
        "Content-Type": request.headers.get("content-type", "application/json"),
        "Authorization": f"token {settings.frappe_api_key}:{settings.frappe_api_secret}",
    }

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            resp = await client.request(
                method=request.method,
                url=frappe_url,
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
