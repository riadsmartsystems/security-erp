"""AI Admin endpoints — /api/v2/ai-admin/*.

Role gate: frappe_roles must contain 'RIAD AI Admin' OR 'System Manager'.
"""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException

from app.auth.dependencies import CurrentUser, get_current_user
from app.schemas.ai_admin import (
    AIProviderUpsertRequest,
    AIProviderResponse,
    AIRequestLogEntry,
    AIRequestLogListResponse,
)
from app.services import ai_admin_service

logger = logging.getLogger("ai_admin.routes")

router = APIRouter(prefix="/api/v2/ai-admin", tags=["ai-admin"])

_REQUIRED_ROLE = "RIAD AI Admin"
_FALLBACK_ROLE = "System Manager"


def _require_ai_admin(user: CurrentUser):
    if not user.has_frappe_role(_REQUIRED_ROLE) and not user.has_frappe_role(_FALLBACK_ROLE):
        raise HTTPException(
            status_code=403,
            detail={"code": "RIAD-PERM-DENIED", "message": f"Requires role: {_REQUIRED_ROLE}"},
        )


@router.get("/providers", response_model=list[AIProviderResponse])
async def list_providers(
    user: CurrentUser = Depends(get_current_user),
):
    _require_ai_admin(user)
    try:
        providers = await ai_admin_service.list_providers(sid=user.frappe_sid)
        return [AIProviderResponse(**p) for p in providers]
    except Exception as exc:
        logger.error("list_providers failed: %s", exc)
        raise HTTPException(status_code=502, detail=str(exc))


@router.post("/providers")
async def upsert_provider(
    body: AIProviderUpsertRequest,
    user: CurrentUser = Depends(get_current_user),
):
    _require_ai_admin(user)
    try:
        return await ai_admin_service.upsert_provider(
            sid=user.frappe_sid,
            name=body.name,
            provider_name=body.provider_name,
            priority=body.priority,
            is_enabled=body.is_enabled,
            health_status=body.health_status,
        )
    except Exception as exc:
        logger.error("upsert_provider failed: %s", exc)
        raise HTTPException(status_code=502, detail=str(exc))


@router.get("/request-logs", response_model=AIRequestLogListResponse)
async def list_request_logs(
    page: int = 1,
    page_size: int = 20,
    user: CurrentUser = Depends(get_current_user),
):
    _require_ai_admin(user)
    try:
        data = await ai_admin_service.list_request_logs(
            sid=user.frappe_sid, page=page, page_size=page_size
        )
        logs = [AIRequestLogEntry(**entry) for entry in data["logs"]]
        return AIRequestLogListResponse(logs=logs, total=data["total"])
    except Exception as exc:
        logger.error("list_request_logs failed: %s", exc)
        raise HTTPException(status_code=502, detail=str(exc))
