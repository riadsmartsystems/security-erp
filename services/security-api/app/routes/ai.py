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
from app.services.ai_orchestrator_service import (
    _anonymize_payload,
    sync_provider_health,
    write_ai_request_log,
)
from app.schemas.ai import AIExecuteRequest, AIExecuteResponse

router = APIRouter()


@router.post("/execute", response_model=AIExecuteResponse)
async def execute_ai(
    request: AIExecuteRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Thin proxy: security-api receives request, anonymizes PII,
    then delegates to Frappe process via @whitelist API.

    Frappe process has security_erp on PYTHONPATH (via Dockerfile.backend .pth file),
    runs orchestrator in its own sync context (gevent-safe), returns result.

    This pattern is identical to how vault.py calls security_erp.vault.api.*
    """
    # 1. Anonymize PII before any external call (principle 6)
    anonymized_payload = _anonymize_payload(request.payload)

    # 2. Delegate to Frappe process — it has security_erp installed
    #    Frappe's @whitelist handles sync execution in gevent context correctly
    try:
        result = await frappe_post(
            "/api/method/security_erp.ai.api.execute_ai",
            data={
                "task": request.task,
                "payload": anonymized_payload,
                "params": request.params or {},
                "provider_preference": request.provider_preference,
            },
        )
    except Exception as e:
        # Graceful degradation: log failure, return manual mode signal
        await write_ai_request_log(
            task=request.task,
            provider="none",
            status="error",
            error=str(e),
            user=current_user.get("name"),
        )
        raise HTTPException(
            status_code=503,
            detail={
                "error": "ai_unavailable",
                "message": "AI service temporarily unavailable. Use manual mode.",
                "manual_fallback": True,
            },
        )

    # 3. Log the request (provider used, tokens, latency — returned by Frappe)
    await write_ai_request_log(
        task=request.task,
        provider=result.get("provider_used", "unknown"),
        status=result.get("status", "ok"),
        tokens_used=result.get("tokens_used"),
        latency_ms=result.get("latency_ms"),
        user=current_user.get("name"),
    )

    return AIExecuteResponse(
        result=result.get("result"),
        provider_used=result.get("provider_used"),
        status=result.get("status", "ok"),
        manual_fallback=result.get("manual_fallback", False),
    )


@router.get("/providers/health")
async def get_providers_health(
    current_user: dict = Depends(get_current_user),
):
    """Check health of all configured AI providers via Circuit Breaker state in Redis."""
    return await sync_provider_health()
