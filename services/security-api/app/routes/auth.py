import redis.asyncio as redis
from fastapi import APIRouter, Depends, HTTPException, status, Request

from app.core.database import frappe_login, frappe_get, frappe_post
from app.core.config import settings
from app.core.redis import get_redis
from app.schemas.auth import LoginRequest, TokenResponse, RefreshRequest, UserCreate
from app.auth.jwt import create_access_token, create_refresh_token, decode_token
from app.auth.dependencies import get_current_user, CurrentUser

router = APIRouter(prefix="/api/v2/auth", tags=["auth"])

_FRAPPE_SID_KEY = "frappe:sid:{user_id}"


@router.post("/login", response_model=TokenResponse)
async def login(
    body: LoginRequest,
    request: Request,
    redis_client: redis.Redis = Depends(get_redis),
):
    result = await frappe_login(body.username, body.password)
    if not result:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    frappe_sid = result.get("sid")
    if not frappe_sid:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Frappe did not return a session")

    await redis_client.setex(_FRAPPE_SID_KEY.format(user_id=body.username), settings.frappe_session_ttl, frappe_sid)

    try:
        user_info = await frappe_get(f"/api/resource/User/{body.username}", sid=frappe_sid)
        role = _map_frappe_role(user_info.get("data", {}))
    except Exception:
        role = "viewer"

    access_token = create_access_token(body.username, role)
    refresh_token = create_refresh_token(body.username)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.jwt_access_ttl,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(body: RefreshRequest, redis_client: redis.Redis = Depends(get_redis)):
    payload = decode_token(body.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    user_id = payload.get("sub")

    frappe_sid = await redis_client.get(_FRAPPE_SID_KEY.format(user_id=user_id))
    if not frappe_sid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "FRAPPE_SESSION_EXPIRED", "message": "Frappe session expired, please re-login"},
        )

    try:
        user_info = await frappe_get(f"/api/resource/User/{user_id}", sid=str(frappe_sid))
        role = _map_frappe_role(user_info.get("data", {}))
    except Exception:
        role = "viewer"

    access_token = create_access_token(user_id, role)
    refresh_token = create_refresh_token(user_id)

    return TokenResponse(access_token=access_token, refresh_token=refresh_token, expires_in=settings.jwt_access_ttl)


@router.post("/logout")
async def logout(
    current_user: CurrentUser = Depends(get_current_user),
    redis_client: redis.Redis = Depends(get_redis),
):
    await redis_client.delete(_FRAPPE_SID_KEY.format(user_id=current_user.user_id))
    return {"success": True}


@router.get("/me")
async def get_me(current_user: CurrentUser = Depends(get_current_user)):
    try:
        user_info = await frappe_get(f"/api/resource/User/{current_user.user_id}", sid=current_user.frappe_sid)
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
        return {
            "id": current_user.user_id,
            "email": f"{current_user.user_id}@security-erp.local",
            "username": current_user.user_id,
            "full_name": current_user.user_id,
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
        }, sid=current_user.frappe_sid)
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
        }, sid=current_user.frappe_sid)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


def _map_frappe_role(user_data: dict) -> str:
    roles = user_data.get("roles", [])
    role_names = [r.get("role", "") for r in roles] if isinstance(roles, list) else []
    return _map_frappe_role_from_names(role_names)


def _map_frappe_role_from_names(role_names: list) -> str:
    if "System Manager" in role_names:
        return "owner"
    if "Service Manager" in role_names:
        return "service_manager"
    if "Sales Manager" in role_names:
        return "sales_manager"
    if "Projects Manager" in role_names:
        return "project_manager"
    if "HR Manager" in role_names:
        return "service_manager"
    if "Engineer" in role_names:
        return "engineer"
    return "viewer"
