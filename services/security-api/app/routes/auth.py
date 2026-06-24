import json
from datetime import datetime, timezone
from uuid import uuid4

import redis.asyncio as redis
from fastapi import APIRouter, Depends, HTTPException, Request, status

from app.auth.dependencies import get_current_user, CurrentUser
from app.auth.jwt import create_access_token, create_refresh_token, decode_token
from app.core.config import settings
from app.core.database import frappe_login, frappe_get, frappe_post
from app.core.rate_limit import check_rate_limit
from app.core.redis import get_redis
from app.schemas.auth import (
    DeviceSessionResponse,
    LoginRequest,
    LogoutRequest,
    RefreshRequest,
    TokenResponse,
    UserCreate,
)


async def _enforce_rate_limit(key: str, max_attempts: int, window: int) -> None:
    result = await check_rate_limit(key, max_attempts, window)
    if result.get("limited"):
        retry_after = result.get("retry_after", window)
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={"code": "RATE_LIMIT_EXCEEDED", "message": "Too many requests"},
            headers={"Retry-After": str(retry_after)},
        )

router = APIRouter(prefix="/api/v2/auth", tags=["auth"])

_FRAPPE_SID_KEY = "frappe:sid:{user_id}"
_RT_BL_KEY = "rt:bl:{jti}"
_RT_SESS_KEY = "rt:sess:{user_id}:{device_id}"
_RT_DEVICES_KEY = "rt:devices:{user_id}"


@router.post("/login", response_model=TokenResponse)
async def login(
    body: LoginRequest,
    request: Request,
    redis_client: redis.Redis = Depends(get_redis),
):
    await _enforce_rate_limit(
        f"rl:login:{request.client.host}",
        settings.rate_limit_login_max,
        settings.rate_limit_login_window,
    )

    result = await frappe_login(body.username, body.password)
    if not result:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    frappe_sid = result.get("sid")
    if not frappe_sid:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Frappe did not return a session")

    await redis_client.setex(
        _FRAPPE_SID_KEY.format(user_id=body.username),
        settings.frappe_session_ttl,
        frappe_sid,
    )

    try:
        user_info = await frappe_get(f"/api/resource/User/{body.username}", sid=frappe_sid)
        data = user_info.get("data", {})
        role = _map_frappe_role(data)
        frappe_roles = _extract_frappe_roles(data)
    except Exception:
        role = "viewer"
        frappe_roles = []

    device_id = body.device_id or str(uuid4())
    access_token = create_access_token(body.username, role, frappe_roles=frappe_roles)
    refresh_token = create_refresh_token(body.username, device_id)

    rt_payload = decode_token(refresh_token)
    jti = rt_payload["jti"]
    now_ts = datetime.now(timezone.utc).timestamp()
    ip = request.client.host or ""

    sess_data = json.dumps({"jti": jti, "created": now_ts, "last_seen": now_ts, "ip_address": ip})
    pipe = redis_client.pipeline()
    pipe.setex(_RT_SESS_KEY.format(user_id=body.username, device_id=device_id), settings.jwt_refresh_ttl, sess_data)
    pipe.sadd(_RT_DEVICES_KEY.format(user_id=body.username), device_id)
    await pipe.execute()

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.jwt_access_ttl,
        device_id=device_id,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    body: RefreshRequest,
    request: Request,
    redis_client: redis.Redis = Depends(get_redis),
):
    payload = decode_token(body.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "INVALID_REFRESH_TOKEN", "message": "Invalid or expired refresh token"},
        )

    user_id = payload.get("sub")
    jti = payload.get("jti")
    device_id = payload.get("did")

    if not jti or not device_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "TOKEN_UPGRADE_REQUIRED", "message": "Re-login required to upgrade session security"},
        )

    await _enforce_rate_limit(
        f"rl:refresh:{user_id}",
        settings.rate_limit_refresh_max,
        settings.rate_limit_refresh_window,
    )

    # Reuse detection: jti already in blacklist means RT was used after rotation
    blacklisted = await redis_client.get(_RT_BL_KEY.format(jti=jti))
    if blacklisted:
        await _revoke_all_user_sessions(redis_client, user_id)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "RIAD-AUTH-REFRESH-REUSE", "message": "Refresh token reuse detected. All sessions revoked."},
        )

    # Verify device session exists (not revoked)
    sess_key = _RT_SESS_KEY.format(user_id=user_id, device_id=device_id)
    sess_raw = await redis_client.get(sess_key)
    if not sess_raw:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "SESSION_REVOKED", "message": "Session revoked or expired"},
        )

    frappe_sid = await redis_client.get(_FRAPPE_SID_KEY.format(user_id=user_id))
    if not frappe_sid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "FRAPPE_SESSION_EXPIRED", "message": "Frappe session expired, please re-login"},
        )

    # Blacklist old jti for remaining TTL
    now = datetime.now(timezone.utc)
    exp = payload.get("exp", 0)
    remaining_ttl = max(1, int(exp - now.timestamp()))
    await redis_client.setex(_RT_BL_KEY.format(jti=jti), remaining_ttl, user_id)

    # Issue new refresh token with same device_id, new jti
    new_refresh_token = create_refresh_token(user_id, device_id)
    new_payload = decode_token(new_refresh_token)
    new_jti = new_payload["jti"]

    old_sess = json.loads(sess_raw)
    new_sess = json.dumps({
        "jti": new_jti,
        "created": old_sess.get("created", now.timestamp()),
        "last_seen": now.timestamp(),
        "ip_address": request.client.host or "",
    })
    await redis_client.setex(sess_key, settings.jwt_refresh_ttl, new_sess)

    try:
        user_info = await frappe_get(f"/api/resource/User/{user_id}", sid=str(frappe_sid))
        data = user_info.get("data", {})
        role = _map_frappe_role(data)
        frappe_roles = _extract_frappe_roles(data)
    except Exception:
        role = "viewer"
        frappe_roles = []

    access_token = create_access_token(user_id, role, frappe_roles=frappe_roles)
    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        expires_in=settings.jwt_access_ttl,
        device_id=device_id,
    )


@router.post("/logout")
async def logout(
    body: LogoutRequest = LogoutRequest(),
    current_user: CurrentUser = Depends(get_current_user),
    redis_client: redis.Redis = Depends(get_redis),
):
    if body.refresh_token:
        rt_payload = decode_token(body.refresh_token)
        if rt_payload and rt_payload.get("type") == "refresh":
            old_jti = rt_payload.get("jti")
            old_did = rt_payload.get("did")
            exp = rt_payload.get("exp", 0)
            remaining = max(1, int(exp - datetime.now(timezone.utc).timestamp()))
            pipe = redis_client.pipeline()
            if old_jti:
                pipe.setex(_RT_BL_KEY.format(jti=old_jti), remaining, current_user.user_id)
            if old_did:
                pipe.delete(_RT_SESS_KEY.format(user_id=current_user.user_id, device_id=old_did))
                pipe.srem(_RT_DEVICES_KEY.format(user_id=current_user.user_id), old_did)
            await pipe.execute()

    await redis_client.delete(_FRAPPE_SID_KEY.format(user_id=current_user.user_id))
    return {"success": True}


@router.get("/sessions")
async def list_sessions(
    current_user: CurrentUser = Depends(get_current_user),
    redis_client: redis.Redis = Depends(get_redis),
):
    device_ids_raw = await redis_client.smembers(_RT_DEVICES_KEY.format(user_id=current_user.user_id))
    sessions = []
    for raw_did in device_ids_raw:
        did = raw_did.decode() if isinstance(raw_did, bytes) else raw_did
        sess_raw = await redis_client.get(_RT_SESS_KEY.format(user_id=current_user.user_id, device_id=did))
        if sess_raw:
            data = json.loads(sess_raw)
            sessions.append(DeviceSessionResponse(
                device_id=did,
                created=data.get("created"),
                last_seen=data.get("last_seen"),
                ip_address=data.get("ip_address", ""),
            ))
        else:
            # Stale entry in the SET — clean up
            await redis_client.srem(_RT_DEVICES_KEY.format(user_id=current_user.user_id), did)
    return {"success": True, "data": [s.model_dump() for s in sessions]}


@router.delete("/sessions/{device_id}")
async def revoke_session(
    device_id: str,
    current_user: CurrentUser = Depends(get_current_user),
    redis_client: redis.Redis = Depends(get_redis),
):
    sess_key = _RT_SESS_KEY.format(user_id=current_user.user_id, device_id=device_id)
    sess_raw = await redis_client.get(sess_key)
    if not sess_raw:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found")

    old_jti = json.loads(sess_raw).get("jti")
    pipe = redis_client.pipeline()
    pipe.delete(sess_key)
    pipe.srem(_RT_DEVICES_KEY.format(user_id=current_user.user_id), device_id)
    if old_jti:
        pipe.setex(_RT_BL_KEY.format(jti=old_jti), settings.jwt_refresh_ttl, current_user.user_id)
    await pipe.execute()

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
            "frappe_roles": current_user.frappe_roles,
            "is_active": data.get("enabled", 1),
        }
    except Exception:
        return {
            "id": current_user.user_id,
            "email": f"{current_user.user_id}@security-erp.local",
            "username": current_user.user_id,
            "full_name": current_user.user_id,
            "role": current_user.role.value,
            "frappe_roles": current_user.frappe_roles,
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


async def _revoke_all_user_sessions(redis_client: redis.Redis, user_id: str) -> None:
    device_ids_raw = await redis_client.smembers(_RT_DEVICES_KEY.format(user_id=user_id))
    pipe = redis_client.pipeline()
    for raw_did in device_ids_raw:
        did = raw_did.decode() if isinstance(raw_did, bytes) else raw_did
        pipe.delete(_RT_SESS_KEY.format(user_id=user_id, device_id=did))
    pipe.delete(_RT_DEVICES_KEY.format(user_id=user_id))
    pipe.delete(_FRAPPE_SID_KEY.format(user_id=user_id))
    await pipe.execute()


def _extract_frappe_roles(user_data: dict) -> list:
    roles = user_data.get("roles", [])
    return [r.get("role", "") for r in roles if isinstance(r, dict) and r.get("role")]


def _map_frappe_role(user_data: dict) -> str:
    return _map_frappe_role_from_names(_extract_frappe_roles(user_data))


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
    if "Engineer" in role_names or "Технік" in role_names:
        return "engineer"
    if "Директор" in role_names:
        return "director"
    if "Бухгалтер" in role_names:
        return "accountant"
    if "Склад" in role_names:
        return "warehouse"
    return "viewer"
