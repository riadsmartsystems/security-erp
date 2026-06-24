"""Scenario CRUD endpoints — /api/v2/scenarios/*.

Role gate: frappe_roles must contain 'RIAD Scenario Admin' OR 'System Manager'.
"""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException

from app.auth.dependencies import CurrentUser, get_current_user
from app.core.database import frappe_get, frappe_post, frappe_put
from app.schemas.scenario import (
    ScenarioUpsertRequest,
    ScenarioItemUpsertRequest,
    ScenarioResponse,
    ScenarioListResponse,
)

logger = logging.getLogger("scenarios.routes")

router = APIRouter(prefix="/api/v2/scenarios", tags=["scenarios"])

_REQUIRED_ROLE = "RIAD Scenario Admin"
_FALLBACK_ROLE = "System Manager"


def _require_scenario_admin(user: CurrentUser):
    if not user.has_frappe_role(_REQUIRED_ROLE) and not user.has_frappe_role(_FALLBACK_ROLE):
        raise HTTPException(
            status_code=403,
            detail={"code": "RIAD-PERM-DENIED", "message": f"Requires role: {_REQUIRED_ROLE}"},
        )


@router.get("", response_model=ScenarioListResponse)
async def list_scenarios(
    user: CurrentUser = Depends(get_current_user),
):
    _require_scenario_admin(user)
    try:
        result = await frappe_get(
            "/api/resource/Security Scenario",
            params={
                "fields": '["name", "scenario_name", "description"]',
                "limit_page_length": 100,
            },
            sid=user.frappe_sid,
        )
        scenarios = [
            ScenarioResponse(
                name=s.get("name", ""),
                scenario_name=s.get("scenario_name", ""),
                description=s.get("description", ""),
            )
            for s in result.get("data", [])
        ]
        return ScenarioListResponse(scenarios=scenarios)
    except Exception as exc:
        logger.error("list_scenarios failed: %s", exc)
        raise HTTPException(status_code=502, detail=str(exc))


@router.get("/{name}")
async def get_scenario(
    name: str,
    user: CurrentUser = Depends(get_current_user),
):
    _require_scenario_admin(user)
    try:
        scenario = await frappe_get(
            f"/api/resource/Security Scenario/{name}",
            sid=user.frappe_sid,
        )
        data = scenario.get("data", {})

        items_resp = await frappe_get(
            "/api/resource/Security Scenario Item",
            params={
                "filters": f'[["parent","=","{name}"]]',
                "fields": '["item_code","item_name","qty","qty_rule","qty_factor","rate","description"]',
                "limit_page_length": 500,
            },
            sid=user.frappe_sid,
        )
        data["items"] = items_resp.get("data", [])
        return data
    except Exception as exc:
        logger.error("get_scenario failed: %s", exc)
        raise HTTPException(status_code=502, detail=str(exc))


@router.post("")
async def upsert_scenario(
    body: ScenarioUpsertRequest,
    user: CurrentUser = Depends(get_current_user),
):
    _require_scenario_admin(user)
    payload = {
        "scenario_name": body.scenario_name,
        "description": body.description,
    }
    try:
        if body.name:
            result = await frappe_put(
                f"/api/resource/Security Scenario/{body.name}",
                data=payload,
                sid=user.frappe_sid,
            )
        else:
            payload["doctype"] = "Security Scenario"
            result = await frappe_post(
                "/api/resource/Security Scenario",
                data=payload,
                sid=user.frappe_sid,
            )
        return result.get("data", {})
    except Exception as exc:
        logger.error("upsert_scenario failed: %s", exc)
        raise HTTPException(status_code=502, detail=str(exc))


@router.post("/{name}/items")
async def upsert_scenario_item(
    name: str,
    body: ScenarioItemUpsertRequest,
    user: CurrentUser = Depends(get_current_user),
):
    _require_scenario_admin(user)
    try:
        await frappe_get(
            f"/api/resource/Security Scenario/{name}",
            sid=user.frappe_sid,
        )
    except Exception:
        raise HTTPException(status_code=404, detail={"code": "RIAD-NOTFOUND", "message": "Scenario not found"})

    try:
        scenario = await frappe_get(
            f"/api/resource/Security Scenario/{name}",
            sid=user.frappe_sid,
        )
        existing_items = scenario.get("data", {}).get("items", [])

        item_payload = {
            "item_code": body.item_code,
            "item_name": body.item_name,
            "qty": body.qty,
            "qty_rule": body.qty_rule,
            "qty_factor": body.qty_factor,
            "rate": body.rate,
            "description": body.description,
        }

        existing = next(
            (i for i in existing_items if i.get("item_code") == body.item_code),
            None,
        )

        if existing:
            await frappe_put(
                f"/api/resource/Security Scenario Item/{existing.get('name', '')}",
                data=item_payload,
                sid=user.frappe_sid,
            )
        else:
            item_payload["doctype"] = "Security Scenario Item"
            item_payload["parent"] = name
            item_payload["parenttype"] = "Security Scenario"
            item_payload["parentfield"] = "items"
            await frappe_post(
                "/api/resource/Security Scenario Item",
                data=item_payload,
                sid=user.frappe_sid,
            )

        return {"success": True}
    except Exception as exc:
        logger.error("upsert_scenario_item failed: %s", exc)
        raise HTTPException(status_code=502, detail=str(exc))
