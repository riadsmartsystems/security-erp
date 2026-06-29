"""Push endpoints — /api/v2/push/*."""
from __future__ import annotations
import logging
from fastapi import APIRouter, Depends, HTTPException
from app.auth.dependencies import CurrentUser, get_current_user
from app.schemas.push import (
    PushSendRequest, PushSendResponse,
    PushTokenRegisterRequest, PushTokenRegisterResponse,
    PushTokenRevokeRequest, PushTokenRevokeResponse,
)
from app.services.push_service import register_token, revoke_token, send_push

logger = logging.getLogger("push.routes")
router = APIRouter(prefix="/api/v2/push", tags=["push"])


@router.post("/token", response_model=PushTokenRegisterResponse)
async def push_token_register(body: PushTokenRegisterRequest, user: CurrentUser = Depends(get_current_user)) -> PushTokenRegisterResponse:
    await register_token(user_id=user.user_id, device_id=body.device_id, fcm_token=body.fcm_token, platform=body.platform, sid=user.frappe_sid)
    return PushTokenRegisterResponse(device_id=body.device_id)


@router.delete("/token", response_model=PushTokenRevokeResponse)
async def push_token_revoke(body: PushTokenRevokeRequest, user: CurrentUser = Depends(get_current_user)) -> PushTokenRevokeResponse:
    revoked = await revoke_token(user_id=user.user_id, device_id=body.device_id)
    return PushTokenRevokeResponse(revoked=revoked)


@router.post("/send", response_model=PushSendResponse)
async def push_send_test(body: PushSendRequest, user: CurrentUser = Depends(get_current_user)) -> PushSendResponse:
    is_admin = "System Manager" in getattr(user, "frappe_roles", [])
    if body.user_id != user.user_id and not is_admin:
        raise HTTPException(status_code=403, detail="Можна надсилати тестовий push лише собі")
    result = await send_push(user_id=body.user_id, title=body.title, body=body.body, data=body.data)
    return PushSendResponse(**result)
