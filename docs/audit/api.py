"""
erpnext/security_erp/security_erp/ai/api.py

FIX 2.5: Replace asyncio.run() in Frappe @whitelist context.

ROOT CAUSE:
- Frappe runs on Gunicorn + gevent workers (WSGI, monkey-patched)
- asyncio.run() in gevent context = unpredictable: deadlock or silent failure
- orchestrator.py is fully async, uses aioredis — incompatible with sync gevent context

SOLUTION:
- execute_ai() calls adapters via complete_sync() (new sync method using httpx)
- No asyncio.run() anywhere in Frappe process
- Circuit Breaker uses sync Redis client (redis.Redis, not aioredis)
- RQ workers also use complete_sync() — they run under gevent too
"""

import json
import time
import frappe
import redis
from .adapters.gemini import GeminiAdapter
from .adapters.stub import StubAdapter
from .circuit_breaker import CircuitBreaker


def _get_redis_sync():
    """Sync Redis client — safe in gevent context (gevent patches socket)."""
    redis_url = frappe.conf.get("redis_cache") or "redis://localhost:6379"
    return redis.Redis.from_url(redis_url, decode_responses=True)


def _get_providers():
    """Load active AI providers from DB, return adapter instances."""
    providers_data = frappe.get_all(
        "AI Provider",
        filters={"is_active": 1},
        fields=["name", "provider_type", "api_key_enc", "model", "priority", "base_url"],
        order_by="priority asc",
    )

    adapters = []
    for p in providers_data:
        api_key = _decrypt_provider_key(p.get("api_key_enc", ""))
        if p["provider_type"] == "gemini":
            adapters.append(GeminiAdapter(api_key=api_key, model=p.get("model")))
        elif p["provider_type"] == "openai":
            from .adapters.openai import OpenAIAdapter
            adapters.append(OpenAIAdapter(api_key=api_key, model=p.get("model")))
        elif p["provider_type"] == "stub":
            adapters.append(StubAdapter())
        # Add more providers as needed
    return adapters


def _decrypt_provider_key(encrypted: str) -> str:
    """Decrypt AI provider API key. Vault isolation: this is NOT vault._crypto."""
    if not encrypted:
        return ""
    # AI Provider keys use a separate lightweight encryption, not Vault AES-256-GCM
    # Implementation: frappe.local.conf master key + Fernet
    try:
        from cryptography.fernet import Fernet
        key = frappe.conf.get("ai_provider_key", "").encode()
        return Fernet(key).decrypt(encrypted.encode()).decode()
    except Exception:
        frappe.log_error("Failed to decrypt AI provider key", "AI API")
        return ""


@frappe.whitelist()
def execute_ai(task: str, payload: str, params: str = "{}", provider_preference: str = None):
    """
    Main AI execution endpoint — called by security-api thin proxy.
    Runs in Frappe process (gevent context). Uses sync adapters only.
    """
    payload_dict = json.loads(payload) if isinstance(payload, str) else payload
    params_dict = json.loads(params) if isinstance(params, str) else (params or {})

    r = _get_redis_sync()
    providers = _get_providers()

    if not providers:
        return {
            "status": "manual_fallback",
            "manual_fallback": True,
            "result": None,
            "provider_used": None,
            "error": "No active AI providers configured",
        }

    last_error = None
    for adapter in providers:
        cb = CircuitBreaker(redis_client=r, provider_name=adapter.provider_name)

        if not cb.is_available_sync():
            continue  # Circuit open — skip this provider

        start = time.monotonic()
        try:
            result = adapter.complete_sync(task, payload_dict, params_dict)
            latency_ms = int((time.monotonic() - start) * 1000)
            cb.record_success_sync()

            return {
                "status": "ok",
                "result": result.content,
                "provider_used": adapter.provider_name,
                "tokens_used": result.tokens_used,
                "latency_ms": latency_ms,
                "manual_fallback": False,
            }
        except Exception as e:
            latency_ms = int((time.monotonic() - start) * 1000)
            cb.record_failure_sync()
            last_error = str(e)
            frappe.log_error(
                f"AI provider {adapter.provider_name} failed: {e}", "AI API"
            )
            continue  # Try next provider

    # All providers failed — graceful degradation to manual mode
    return {
        "status": "manual_fallback",
        "manual_fallback": True,
        "result": None,
        "provider_used": None,
        "error": last_error or "All providers unavailable",
    }


@frappe.whitelist()
def get_provider_health():
    """Return Circuit Breaker state for all configured providers."""
    r = _get_redis_sync()
    providers = frappe.get_all(
        "AI Provider",
        filters={"is_active": 1},
        fields=["name", "provider_type", "priority"],
    )
    result = {}
    for p in providers:
        cb = CircuitBreaker(redis_client=r, provider_name=p["name"])
        result[p["name"]] = {
            "state": cb.get_state_sync(),
            "provider_type": p["provider_type"],
        }
    return result
