"""Installation Map service — get/add_mount_point/approve via Frappe REST API.

All Frappe calls use delegated SID (B1). No Administrator access.
Union-merge logic for mount_points lives here, not in the route.
"""

from __future__ import annotations

from datetime import datetime, timezone

from app.core.database import frappe_get, frappe_put


def _unwrap(result: dict) -> dict:
    return result.get("message", result)


async def get_map(*, sid: str, name: str) -> dict:
    """Return raw Installation Map data dict from Frappe."""
    result = await frappe_get(f"/api/resource/Installation Map/{name}", sid=sid)
    return _unwrap(result)


async def add_mount_point(
    *,
    sid: str,
    name: str,
    point_uuid: str,
    point_data: dict,
) -> str:
    """Add a mount point to map with idempotency and mode validation.

    Returns 'added' or 'already_present'.
    Raises ValueError for mode constraint violations.
    Propagates httpx.HTTPStatusError from Frappe calls (route maps to HTTP).
    """
    existing = await frappe_get(f"/api/resource/Installation Map/{name}", sid=sid)
    existing_data = _unwrap(existing)
    map_kind = existing_data.get("map_kind", "територія")

    if map_kind == "план приміщення":
        if point_data.get("x") is None or point_data.get("y") is None:
            raise ValueError("Plan mode requires x/y")
        if point_data.get("geo"):
            raise ValueError("Plan mode does not use geo")
    elif map_kind == "територія":
        if not point_data.get("geo"):
            raise ValueError("Territory mode requires geo")

    points = existing_data.get("mount_points") or []
    for p in points:
        if p.get("point_uuid") == point_uuid:
            return "already_present"

    points.append(point_data)
    await frappe_put(
        f"/api/resource/Installation Map/{name}",
        data={"mount_points": points},
        sid=sid,
    )
    return "added"


async def approve_map(*, sid: str, name: str, user_id: str) -> str:
    """Set approved_by + approved_at on the map. Returns ISO timestamp."""
    now = datetime.now(timezone.utc).isoformat()
    await frappe_put(
        f"/api/resource/Installation Map/{name}",
        data={"approved_by": user_id, "approved_at": now},
        sid=sid,
    )
    return now
