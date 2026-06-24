"""AI Admin service — provider CRUD and request log queries via Frappe REST API.

All Frappe calls use delegated SID (B1). No Administrator access.
Role gates (_require_ai_admin) remain in the route layer.
"""

from __future__ import annotations

import logging

from app.core.database import frappe_get, frappe_post, frappe_put

logger = logging.getLogger("ai_admin.service")


async def list_providers(*, sid: str) -> list[dict]:
    """Return list of AI Provider dicts from Frappe."""
    result = await frappe_get(
        "/api/resource/AI Provider",
        params={
            "fields": '["name","provider_name","priority","is_enabled","health_status"]',
            "limit_page_length": 50,
        },
        sid=sid,
    )
    return [
        {
            "name": p.get("name", ""),
            "provider_name": p.get("provider_name", ""),
            "priority": p.get("priority", 0),
            "is_enabled": bool(p.get("is_enabled", 1)),
            "health_status": p.get("health_status", ""),
        }
        for p in result.get("data", [])
    ]


async def upsert_provider(
    *,
    sid: str,
    name: str | None,
    provider_name: str,
    priority: int,
    is_enabled: bool,
    health_status: str,
) -> dict:
    """Create or update an AI Provider in Frappe. Returns data dict."""
    payload = {
        "provider_name": provider_name,
        "priority": priority,
        "is_enabled": 1 if is_enabled else 0,
        "health_status": health_status,
    }
    if name:
        result = await frappe_put(
            f"/api/resource/AI Provider/{name}",
            data=payload,
            sid=sid,
        )
    else:
        payload["doctype"] = "AI Provider"
        result = await frappe_post(
            "/api/resource/AI Provider",
            data=payload,
            sid=sid,
        )
    return result.get("data", {})


async def list_request_logs(*, sid: str, page: int, page_size: int) -> dict:
    """Return paginated AI Request Log entries."""
    offset = (page - 1) * page_size
    result = await frappe_get(
        "/api/resource/AI Request Log",
        params={
            "fields": '["name","anonymized_payload","provider","latency_ms","tokens","status","error_message","creation"]',
            "limit_page_length": page_size,
            "limit_start": offset,
            "order_by": "creation desc",
        },
        sid=sid,
    )
    logs = [
        {
            "name": entry.get("name", ""),
            "anonymized_payload": entry.get("anonymized_payload", ""),
            "provider": entry.get("provider", ""),
            "latency_ms": entry.get("latency_ms", 0),
            "tokens": entry.get("tokens", 0),
            "status": entry.get("status", ""),
            "error_message": entry.get("error_message", ""),
            "creation": entry.get("creation", ""),
        }
        for entry in result.get("data", [])
    ]
    return {"logs": logs, "total": len(logs)}
