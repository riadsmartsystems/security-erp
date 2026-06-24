"""Visit lifecycle service — start/finish/materials/photos via Frappe REST API.

All Frappe calls use delegated SID (B1). No Administrator access.
"""

from __future__ import annotations

import base64

from app.core.database import frappe_post, frappe_put


async def start_visit(*, sid: str, visit_id: str, lat: float, lon: float) -> dict:
    result = await frappe_put(
        f"/api/resource/Visit/{visit_id}",
        data={"status": "On Route", "gps_checkin_lat": lat, "gps_checkin_lon": lon},
        sid=sid,
    )
    return result.get("data", {})


async def finish_visit(*, sid: str, visit_id: str, lat: float, lon: float) -> dict:
    result = await frappe_put(
        f"/api/resource/Visit/{visit_id}",
        data={"status": "Completed", "gps_checkout_lat": lat, "gps_checkout_lon": lon},
        sid=sid,
    )
    return result.get("data", {})


async def add_material(
    *,
    sid: str,
    visit_id: str,
    item_code: str | None,
    item_name: str,
    quantity: int,
    unit_price: float,
) -> dict:
    result = await frappe_post(
        "/api/resource/Visit Material",
        data={
            "parent": visit_id,
            "parenttype": "Visit",
            "item_code": item_code,
            "item_name": item_name,
            "qty": quantity,
            "rate": unit_price,
        },
        sid=sid,
    )
    return result.get("data", {})


async def upload_photo(
    *,
    sid: str,
    visit_id: str,
    file_bytes: bytes,
    content_type: str,
    photo_type: str,
    caption: str,
) -> dict:
    file_b64 = base64.b64encode(file_bytes).decode()
    result = await frappe_post(
        "/api/resource/Visit Photo",
        data={
            "parent": visit_id,
            "parenttype": "Visit",
            "photo_type": photo_type,
            "caption": caption,
            "image": f"data:{content_type};base64,{file_b64}",
        },
        sid=sid,
    )
    return result.get("data", {})
