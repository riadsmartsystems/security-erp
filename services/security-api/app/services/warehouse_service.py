"""Warehouse service — Serial No and Stock queries via Frappe REST API.

All Frappe calls use delegated SID (B1). No Administrator access.
"""

from __future__ import annotations

import json

from app.core.database import frappe_get


def _unwrap(result: dict) -> dict:
    return result.get("message", result)


async def list_serials(
    *, sid: str, q: str = "", page: int = 1, page_size: int = 20
) -> dict:
    filters: list = []
    if q:
        filters.append(["Serial No", "serial_no", "like", f"%{q}%"])

    result = await frappe_get(
        "/api/resource/Serial No",
        params={
            "fields": '["name","serial_no","item","item_name","status","warehouse"]',
            "filters": json.dumps(filters) if filters else "[]",
            "limit_page_length": str(page_size),
            "limit_start": str((page - 1) * page_size),
            "order_by": "creation desc",
        },
        sid=sid,
    )

    data = _unwrap(result)
    items_raw = data.get("data", []) if isinstance(data, dict) else data
    total = (
        data.get("total", len(items_raw)) if isinstance(data, dict) else len(items_raw)
    )

    serials = [
        {
            "name": s.get("name", ""),
            "serial_no": s.get("serial_no", ""),
            "item": s.get("item"),
            "item_name": s.get("item_name"),
            "status": s.get("status"),
            "warehouse": s.get("warehouse"),
        }
        for s in items_raw
    ]

    return {"items": serials, "total": total, "page": page, "page_size": page_size}


async def list_stock(*, sid: str) -> dict:
    result = await frappe_get(
        "/api/method/frappe.client.get_list",
        params={
            "doctype": "Bin",
            "fields": '["item_code","item_name","actual_qty","warehouse"]',
            "group_by": "item_code",
            "limit_page_length": "200",
        },
        sid=sid,
    )

    data = _unwrap(result)
    bins = data.get("message", data) if isinstance(data, dict) else data

    items_map: dict[str, dict] = {}
    for b in bins:
        code = b.get("item_code", "")
        if code in items_map:
            items_map[code]["qty"] += b.get("actual_qty", 0)
        else:
            items_map[code] = {
                "item_code": code,
                "item_name": b.get("item_name"),
                "qty": b.get("actual_qty", 0),
                "warehouse": b.get("warehouse"),
            }

    return {"items": list(items_map.values())}


async def stock_detail(*, sid: str, item: str) -> dict:
    bin_result = await frappe_get(
        "/api/method/frappe.client.get_list",
        params={
            "doctype": "Bin",
            "fields": '["item_code","item_name","actual_qty","warehouse"]',
            "filters": json.dumps([["Bin", "item_code", "=", item]]),
        },
        sid=sid,
    )

    bin_data = _unwrap(bin_result)
    bins = bin_data.get("message", bin_data) if isinstance(bin_data, dict) else bin_data

    total_qty = sum(b.get("actual_qty", 0) for b in bins)
    item_name = bins[0].get("item_name") if bins else None
    warehouse = bins[0].get("warehouse") if bins else None

    sn_result = await frappe_get(
        "/api/resource/Serial No",
        params={
            "fields": '["name","serial_no","item","item_name","status","warehouse"]',
            "filters": json.dumps([["Serial No", "item", "=", item]]),
            "limit_page_length": "200",
        },
        sid=sid,
    )

    sn_data = _unwrap(sn_result)
    sn_raw = sn_data.get("data", []) if isinstance(sn_data, dict) else sn_data

    serials = [
        {
            "name": s.get("name", ""),
            "serial_no": s.get("serial_no", ""),
            "item": s.get("item"),
            "item_name": s.get("item_name"),
            "status": s.get("status"),
            "warehouse": s.get("warehouse"),
        }
        for s in sn_raw
    ]

    return {
        "item_code": item,
        "item_name": item_name,
        "qty": total_qty,
        "warehouse": warehouse,
        "serials": serials,
    }
