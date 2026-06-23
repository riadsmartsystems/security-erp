"""Estimate lifecycle service — build/review/confirm via Frappe REST API.

All Frappe calls use delegated SID (R1). No Administrator access.
estimate.confirm creates Quotation through the anti-corruption gateway.
"""

from __future__ import annotations

import json
import logging
import time

from app.core.database import frappe_get, frappe_post, frappe_put

logger = logging.getLogger("estimate.service")

_SYNC_TIMEOUT_S = 5.0


async def build_estimate(
    *,
    sid: str,
    site_brief_name: str,
    variant: str,
    user_id: str,
) -> dict:
    """Create Estimate DocType (status=Draft, origin=manual initially).

    If orchestrator responds within 5s → sync result.
    Otherwise → RQ enqueue (A3) → return pending.
    AI Request Log written on both paths.
    """
    site_brief = await frappe_get(
        f"/api/resource/Site Brief/{site_brief_name}",
        sid=sid,
    )
    brief_data = site_brief.get("data", {})

    estimate_doc = {
        "doctype": "Estimate",
        "status": "Draft",
        "origin": "manual",
        "variant": variant,
        "security_type": brief_data.get("security_type", "Mixed"),
        "object_name": brief_data.get("brief_name", site_brief_name),
        "notes": f"AI-generated from Site Brief: {site_brief_name}",
    }

    created = await frappe_post("/api/resource/Estimate", data=estimate_doc, sid=sid)
    estimate_name = created.get("data", {}).get("name", "")

    if not estimate_name:
        return {"name": "", "status": "error", "origin": "manual"}

    start = time.monotonic()
    try:
        # FIX 2.4+2.5: thin proxy to Frappe @whitelist — no direct security_erp imports
        brief_text = brief_data.get("brief_text", variant)
        result = await asyncio_wait_for(
            frappe_post(
                "/api/method/security_erp.ai.api.execute_ai",
                data={
                    "task": "project_builder",
                    "payload": json.dumps({"technical_task": brief_text, "variant": variant}),
                    "params": "{}",
                },
                sid=sid,
            ),
            timeout=_SYNC_TIMEOUT_S,
        )
        elapsed_ms = (time.monotonic() - start) * 1000

        status_val = result.get("status", "error")
        content = result.get("result", "")
        origin = result.get("provider_used", "unknown")

        _origin_map = {"ok": "ai_primary", "manual_fallback": "manual", "error": "ai_fallback"}
        est_origin = _origin_map.get(status_val, "manual")

        if status_val == "ok" and content:
            try:
                parsed = json.loads(content)
                await frappe_put(
                    f"/api/resource/Estimate/{estimate_name}",
                    data={"ai_result": json.dumps(parsed, ensure_ascii=False)},
                    sid=sid,
                )
            except (json.JSONDecodeError, TypeError):
                await frappe_put(
                    f"/api/resource/Estimate/{estimate_name}",
                    data={"ai_result": content},
                    sid=sid,
                )

        await frappe_put(
            f"/api/resource/Estimate/{estimate_name}",
            data={"origin": est_origin},
            sid=sid,
        )

        return {"name": estimate_name, "status": est_origin, "origin": est_origin}

    except (TimeoutError, Exception) as exc:
        logger.info("Sync orchestrator timeout/error for %s: %s, enqueuing RQ", estimate_name, exc)

        try:
            await frappe_post(
                "/api/method/security_erp.tasks.ai_estimate.enqueue_ai_estimate",
                data={
                    "estimate_name": estimate_name,
                    "site_brief": brief_data.get("brief_text", variant),
                    "variant": variant,
                },
                sid=sid,
            )
        except Exception as rq_exc:
            logger.warning("Failed to enqueue AI estimate for %s: %s", estimate_name, rq_exc)

        return {"name": estimate_name, "status": "pending", "origin": "ai_primary"}


async def review_estimate(
    *,
    sid: str,
    name: str,
    decision: str,
    user_id: str,
) -> dict:
    """Review an AI-generated estimate: approved → підтверджено, rejected → відхилено.

    Validates: origin != manual AND ai_result is not empty.
    """
    est = await frappe_get(f"/api/resource/Estimate/{name}", sid=sid)
    data = est.get("data", {})

    origin = data.get("origin", "manual")
    ai_result = data.get("ai_result", "")

    if origin == "manual" or not ai_result:
        raise ValueError("RIAD-VALIDATION: estimate must be AI-generated with ai_result")

    status_map = {"approved": "Approved", "rejected": "Rejected"}
    new_status = status_map[decision]

    await frappe_put(
        f"/api/resource/Estimate/{name}",
        data={
            "status": new_status,
            "reviewed_by": user_id,
        },
        sid=sid,
    )

    return {"name": name, "status": new_status, "reviewed_by": user_id}


async def confirm_estimate(
    *,
    sid: str,
    name: str,
) -> dict:
    """Confirm estimate → create Quotation via anti-corruption gateway.

    Hard boundary: status must be 'Approved' AND reviewed_by must be present.
    """
    est = await frappe_get(f"/api/resource/Estimate/{name}", sid=sid)
    data = est.get("data", {})

    status_val = data.get("status", "")
    reviewed_by = data.get("reviewed_by", "")

    if status_val != "Approved" or not reviewed_by:
        raise ValueError(
            "RIAD-VALIDATION: estimate must be approved and reviewed before confirmation"
        )

    result = await frappe_post(
        "/api/method/security_erp.security_erp.doctype.estimate.estimate.Estimate.create_quotation",
        data={"name": name},
        sid=sid,
    )

    quotation_name = result.get("message", "")

    return {"quotation_name": quotation_name}


async def asyncio_wait_for(coro, timeout: float):
    """Asyncio wait_for wrapper compatible with sync exception handling."""
    import asyncio
    return await asyncio.wait_for(coro, timeout=timeout)
