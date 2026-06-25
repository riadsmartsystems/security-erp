"""AI Orchestrator service — orchestrates execute + logs to AI Request Log.

Runs inside security-api (FastAPI process). Orchestrator + adapters live in
security_erp package (Frappe process), so we call them via subprocess or
import directly. Since security-api and Frappe share the same container image
but NOT the same process, we use the orchestrator directly via import.

IMPORTANT: This module does NOT import security_erp.vault.* — enforced by CI.
"""

from __future__ import annotations

import logging
from typing import Any

from app.core.database import frappe_post, frappe_get, frappe_put

logger = logging.getLogger("ai.service")

# CB state → AI Provider.health mapping
_CB_HEALTH_MAP = {
    "closed": "healthy",
    "half_open": "degraded",
    "open": "down",
}


def _anonymize_payload(task: str, payload: dict) -> dict:
    """Return anonymized payload: task type + keys only (no values) + text length."""
    text_parts = []
    for v in payload.values():
        if isinstance(v, str):
            text_parts.append(len(v))
        elif isinstance(v, dict):
            text_parts.append(len(str(v)))
    return {
        "task": task,
        "payload_keys": sorted(payload.keys()),
        "text_lengths": text_parts,
    }


async def write_ai_request_log(
    *,
    sid: str,
    anonymized_payload: dict,
    provider: str,
    latency_ms: float,
    tokens: int,
    status: str,
    error_message: str = "",
) -> dict | None:
    """Write one row to AI Request Log via Frappe REST API (delegated SID)."""
    data = {
        "anonymized_payload": str(anonymized_payload),
        "provider": provider,
        "latency_ms": round(latency_ms, 2),
        "tokens": tokens,
        "status": status,
        "error_message": error_message[:500] if error_message else "",
    }
    try:
        return await frappe_post("/api/resource/AI Request Log", data=data, sid=sid)
    except Exception as exc:
        logger.warning("Failed to write AI Request Log: %s", exc)
        return None


async def sync_provider_health(r: Any, sid: str) -> list[dict]:
    """Read CB state from Redis → update AI Provider.health in Frappe.

    Returns list of {name, health, priority} for all enabled providers.
    Source of truth for CB state = Redis; Frappe AI Provider.health = cache for UI.
    """
    try:
        providers_resp = await frappe_get(
            "/api/resource/AI Provider",
            params={
                "fields": '["name", "provider_name", "health_status", "priority", "is_enabled"]',
                "filters": '[["is_enabled", "=", 1]]',
                "limit_page_length": 50,
            },
            sid=sid,
        )
    except Exception as exc:
        logger.warning("Failed to fetch AI Providers: %s", exc)
        return []

    providers = providers_resp.get("data", [])
    result = []

    for p in providers:
        name = p.get("provider_name", p.get("name", ""))
        cb_key = f"cb:provider:{name}"
        raw = await r.hgetall(cb_key)
        cb_state = raw.get("state", "closed") if raw else "closed"
        health = _CB_HEALTH_MAP.get(cb_state, "healthy")

        current_health = p.get("health_status", "")
        if current_health != health:
            try:
                await frappe_put(
                    f"/api/resource/AI Provider/{p['name']}",
                    data={"health_status": health},
                    sid=sid,
                )
            except Exception as exc:
                logger.warning("Failed to update AI Provider %s health: %s", name, exc)

        result.append({
            "name": name,
            "health": health,
            "priority": p.get("priority", 0),
        })

    return result


async def get_provider_degradation(sid: str) -> list[dict]:
    """Read AI Provider health status from Frappe."""
    providers_resp = await frappe_get(
        "/api/resource/AI Provider",
        params={
            "fields": '["name", "provider_name", "health_status", "priority"]',
            "filters": '[["is_enabled", "=", 1]]',
            "limit_page_length": 50,
        },
        sid=sid,
    )
    return providers_resp.get("data", [])
