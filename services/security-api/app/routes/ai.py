"""
services/security-api/app/routes/ai.py

FIX 2.5: Remove direct security_erp.* imports from security-api container.
security_erp package is NOT installed in security-api Docker image (only in Dockerfile.backend).
Solution: thin proxy pattern — delegate to Frappe @whitelist method via frappe_post(),
exactly like vault.py does for all vault operations.
"""

from fastapi import APIRouter, Depends, HTTPException
from app.auth.dependencies import get_current_user
from app.core.database import frappe_post
from app.core.redis import get_redis
from app.services.ai_orchestrator_service import (
    _anonymize_payload,
    get_provider_degradation,
    sync_provider_health,
    write_ai_request_log,
)
from app.schemas.ai import AIExecuteRequest, AIExecuteResponse, AIDegradationResponse

router = APIRouter(prefix="/api/v2/ai")


@router.post("/execute", response_model=AIExecuteResponse)
async def execute_ai(
    request: AIExecuteRequest,
    current_user=Depends(get_current_user),
):
    """Thin proxy: anonymize PII, delegate to Frappe @whitelist API."""
    anonymized_payload = _anonymize_payload(request.task, request.payload)

    try:
        result = await frappe_post(
            "/api/method/security_erp.ai.api.execute_ai",
            data={
                "task": request.task,
                "payload": anonymized_payload,
                "params": request.params or {},
            },
        )
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail={
                "error": "ai_unavailable",
                "message": "AI service temporarily unavailable. Use manual mode.",
                "manual_fallback": True,
            },
        )

    return AIExecuteResponse(
        status=result.get("status", "ok"),
        content=result.get("result", ""),
        tokens=result.get("tokens_used", 0),
        latency_ms=result.get("latency_ms", 0.0),
        origin=result.get("provider_used", ""),
        raw_meta=result.get("raw_meta", {}),
    )


@router.get("/providers/health")
async def get_providers_health(
    current_user=Depends(get_current_user),
):
    """Check health of all configured AI providers via Circuit Breaker state in Redis."""
    r = await get_redis()
    sid = getattr(current_user, "frappe_sid", "")
    return await sync_provider_health(r, sid)


@router.get("/degradation", response_model=AIDegradationResponse)
async def get_degradation(
    current_user=Depends(get_current_user),
    r=Depends(get_redis),
):
    """AI degradation level for UI badges."""
    sid = getattr(current_user, "frappe_sid", "")

    try:
        providers = await get_provider_degradation(sid=sid)
    except Exception:
        return AIDegradationResponse(
            level="manual",
            providers=[],
            message="Неможливо отримати стан провайдерів. Ручний режим.",
        )
    open_count = 0
    half_open_count = 0
    result_providers = []

    for p in providers:
        name = p.get("provider_name", "")
        cb_key = f"cb:provider:{name}"
        raw = await r.hgetall(cb_key)
        cb_state = raw.get("state", "closed") if raw else "closed"

        health_map = {"closed": "healthy", "half_open": "degraded", "open": "down"}
        health = health_map.get(cb_state, "healthy")

        if cb_state == "open":
            open_count += 1
        elif cb_state == "half_open":
            half_open_count += 1

        result_providers.append({
            "name": name,
            "health": health,
            "priority": p.get("priority", 0),
        })

    total = len(providers)
    if open_count == total and total > 0:
        level = "manual"
        message = "Всі AI-провайдери недоступні. Перейдіть на ручний режим."
    elif half_open_count > 0 or open_count > 0:
        level = "fallback"
        message = "Частково доступні AI-провайдери. Використовується резервний."
    else:
        level = "primary"
        message = "Всі AI-провайдери працюють нормально."

    return AIDegradationResponse(
        level=level,
        providers=result_providers,
        message=message,
    )
