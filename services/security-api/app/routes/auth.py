from fastapi import APIRouter, Depends, HTTPException, status, Request

from app.core.database import frappe_login, frappe_get, frappe_post
from app.schemas.auth import LoginRequest, TokenResponse, RefreshRequest, UserCreate
from app.auth.jwt import create_access_token, create_refresh_token, decode_token
from app.auth.dependencies import get_current_user, CurrentUser

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, request: Request):
    result = await frappe_login(body.username, body.password)
    if not result:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    frappe_user = body.username

    try:
        sid = result.get("sid")
        user_info = await frappe_get(f"/api/resource/User/{frappe_user}", sid=sid)
        role = _map_frappe_role(user_info.get("data", {}))
    except Exception:
        role = _default_role(body.username)

    access_token = create_access_token(frappe_user, role)
    refresh_token = create_refresh_token(frappe_user)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=900,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(body: RefreshRequest):
    payload = decode_token(body.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    user_id = payload.get("sub")
    try:
        user_info = await frappe_get(f"/api/resource/User/{user_id}")
        role = _map_frappe_role(user_info.get("data", {}))
    except Exception:
        role = "viewer"

    access_token = create_access_token(user_id, role)
    refresh_token = create_refresh_token(user_id)

    return TokenResponse(access_token=access_token, refresh_token=refresh_token, expires_in=900)


@router.post("/logout")
async def logout(current_user: CurrentUser = Depends(get_current_user)):
    return {"success": True}


@router.get("/me")
async def get_me(current_user: CurrentUser = Depends(get_current_user)):
    try:
        user_info = await frappe_get(f"/api/resource/User/{current_user.user_id}")
        data = user_info.get("data", {})
        return {
            "id": current_user.user_id,
            "email": data.get("email", ""),
            "username": current_user.user_id,
            "full_name": data.get("full_name", ""),
            "role": current_user.role.value,
            "is_active": data.get("enabled", 1),
        }
    except Exception:
        default_names = {
            "Administrator": "System Administrator",
            "joker": "Joker",
        }
        return {
            "id": current_user.user_id,
            "email": f"{current_user.user_id}@security-erp.local",
            "username": current_user.user_id,
            "full_name": default_names.get(current_user.user_id, current_user.user_id),
            "role": current_user.role.value,
            "is_active": True,
        }


@router.get("/users")
async def list_users(current_user: CurrentUser = Depends(get_current_user)):
    if current_user.role.value not in ["owner", "director"]:
        raise HTTPException(status_code=403, detail="Only owner/director can list users")

    try:
        result = await frappe_get("/api/resource/User", params={
            "filters": '[["enabled","=",1]]',
            "fields": '["name","email","full_name","enabled"]',
            "limit_page_length": 100,
        })
        users = result.get("data", [])
        return {"success": True, "data": users}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/users")
async def create_user(body: UserCreate, current_user: CurrentUser = Depends(get_current_user)):
    if current_user.role.value not in ["owner", "director"]:
        raise HTTPException(status_code=403, detail="Only owner/director can create users")

    try:
        result = await frappe_post("/api/resource/User", data={
            "email": body.email,
            "first_name": body.full_name,
            "new_password": body.password,
            "enabled": 1,
            "send_welcome_email": 0,
        })
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


def _map_frappe_role(user_data: dict) -> str:
    roles = user_data.get("roles", [])
    role_names = [r.get("role", "") for r in roles] if isinstance(roles, list) else []

    if "System Manager" in role_names:
        return "owner"
    if "Sales Manager" in role_names:
        return "sales_manager"
    if "Projects Manager" in role_names:
        return "project_manager"
    if "HR Manager" in role_names:
        return "service_manager"
    return "viewer"


def _default_role(username: str) -> str:
    defaults = {
        "Administrator": "owner",
        "joker": "owner",
    }
    return defaults.get(username, "viewer")
