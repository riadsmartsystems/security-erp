"""
erpnext/security_erp/security_erp/tasks/ai_estimate.py

FIX 2.5: Replace asyncio.run() + missing complete_sync() with real sync calls.

ROOT CAUSE:
1. hasattr(provider, "complete_sync") was always False → result = None
2. asyncio.run(_timed_call(...)) in RQ worker = gevent deadlock
3. Circuit Breaker not used in RQ path (aioredis not available sync)

SOLUTION:
- Use provider.complete_sync() which now exists (see adapters/gemini.py, stub.py)
- Use CircuitBreaker sync methods with sync redis.Redis client
- Remove asyncio.run() entirely
"""

import json
import time
import frappe
import redis
from security_erp.ai.adapters.gemini import GeminiAdapter
from security_erp.ai.adapters.stub import StubAdapter
from security_erp.ai.circuit_breaker import CircuitBreaker
from security_erp.ai.adapters.base import AIResult, timed_call


def _get_redis_sync():
    redis_url = frappe.conf.get("redis_cache") or "redis://localhost:6379"
    return redis.Redis.from_url(redis_url, decode_responses=True)


def _get_providers_sync():
    """Load active providers — sync, safe in RQ context."""
    providers_data = frappe.get_all(
        "AI Provider",
        filters={"is_active": 1},
        fields=["name", "provider_type", "api_key_enc", "model", "priority"],
        order_by="priority asc",
    )
    adapters = []
    for p in providers_data:
        ptype = p["provider_type"]
        # Decrypt key inline (not Vault — AI Provider uses separate lightweight encryption)
        try:
            from cryptography.fernet import Fernet
            key = frappe.conf.get("ai_provider_key", "").encode()
            api_key = Fernet(key).decrypt(p.get("api_key_enc", "").encode()).decode()
        except Exception:
            api_key = ""

        if ptype == "gemini":
            adapters.append(GeminiAdapter(api_key=api_key, model=p.get("model")))
        elif ptype == "stub":
            adapters.append(StubAdapter())
    return adapters


def _run_orchestrator_sync(task: str, payload: dict, params: dict) -> AIResult:
    """
    Sync orchestrator for RQ worker context.
    Uses complete_sync() — no asyncio, no event loop, gevent-safe.
    Circuit Breaker uses sync Redis client.
    """
    r = _get_redis_sync()
    providers = _get_providers_sync()

    if not providers:
        return AIResult(
            content="[MANUAL] No AI providers configured.",
            provider="none",
        )

    last_error = None
    for adapter in providers:
        cb = CircuitBreaker(redis_client=r, provider_name=adapter.provider_name)

        if not cb.is_available_sync():
            continue  # Circuit open — skip

        try:
            result = timed_call(adapter, task, payload, params)  # sync, no asyncio.run()
            cb.record_success_sync()
            return result
        except Exception as e:
            cb.record_failure_sync()
            last_error = str(e)
            frappe.log_error(
                f"AI estimate: provider {adapter.provider_name} failed: {e}",
                "AI Estimate Task",
            )
            continue  # Try next

    # All failed — return manual fallback signal
    return AIResult(
        content=f"[MANUAL] All AI providers failed. Last error: {last_error}",
        provider="none",
    )


@frappe.whitelist()
def run_ai_estimate(estimate_name: str):
    """
    RQ entry point: generate AI estimate for a given Estimate document.
    Called via frappe.enqueue().
    """
    doc = frappe.get_doc("Estimate", estimate_name)

    if doc.status != "Draft":
        return

    # Build anonymized payload (no PII — §6 of constitution)
    payload = {
        "object_type": doc.object_type,
        "area_sqm": doc.area_sqm,
        "cameras_count": doc.cameras_count,
        "archive_days": doc.archive_days,
        "scenario_name": doc.scenario,
    }
    params = {"max_tokens": 1500, "temperature": 0.2}

    result = _run_orchestrator_sync(
        task="estimate_build",
        payload=payload,
        params=params,
    )

    is_manual_fallback = result.provider == "none" or result.content.startswith("[MANUAL]")

    frappe.db.set_value(
        "Estimate",
        estimate_name,
        {
            "ai_result": result.content,
            "ai_provider_used": result.provider,
            "origin": "manual" if is_manual_fallback else "ai_primary",
            "status": "AI Draft" if not is_manual_fallback else "Draft",
        },
    )
    frappe.db.commit()
