from __future__ import annotations

import base64
import json
from datetime import datetime, timezone
from typing import Any

from app.core.database import frappe_get, frappe_post, frappe_put
from app.schemas.sync import (
    SyncAdditiveResult,
    SyncConflictInfo,
    SyncPullChange,
    SyncPullRequest,
    SyncPullResponse,
    SyncPushItem,
    SyncPushItemResult,
    SyncPushRequest,
    SyncPushResponse,
    SyncResolveRequest,
    SyncResolveResponse,
)

# ---------------------------------------------------------------------------
# Syncable DocType registry
# ---------------------------------------------------------------------------

SYNCABLE_DOCTYPES = ["Visit", "Media Asset", "Checklist Instance", "Installation Map"]

# Scalar fields included in pull response (excludes sync-meta and child tables)
SYNCABLE_SCALAR_FIELDS: dict[str, list[str]] = {
    "Visit": [
        "status", "visit_type", "summary", "notes", "engineer", "service_ticket",
        "planned_start", "actual_start", "actual_finish", "travel_minutes",
        "work_minutes", "gps_checkin_lat", "gps_checkin_lon",
        "gps_checkout_lat", "gps_checkout_lon",
    ],
    "Media Asset": [
        "drive_file_id", "media_type", "tag", "parent_doctype", "parent_name",
        "transcription", "ai_allowed",
    ],
    "Checklist Instance": ["template", "visit", "passport", "status"],
    "Installation Map": ["passport", "map_kind", "approved_by", "approved_at"],
}

# Maps push-payload key → Frappe child table field name + UUID field name on each row
# structure: {push_key: {"frappe_field": str, "uuid_field": str}}
ADDITIVE_COLLECTIONS: dict[str, dict[str, dict[str, str]]] = {
    "Visit": {
        "visit_material": {"frappe_field": "materials", "uuid_field": "client_uuid"},
        "visit_photo": {"frappe_field": "photos", "uuid_field": "client_uuid"},
    },
    "Checklist Instance": {
        "checklist_instance_item": {
            "frappe_field": "instance_items",
            "uuid_field": "item_uuid",
        },
    },
    "Installation Map": {
        "mount_point": {"frappe_field": "mount_points", "uuid_field": "point_uuid"},
        "cable_route": {"frappe_field": "cable_routes", "uuid_field": "route_uuid"},
    },
}

# ---------------------------------------------------------------------------
# Watermark helpers
# ---------------------------------------------------------------------------


def _encode_watermark(ts: str) -> str:
    return base64.b64encode(json.dumps({"ts": ts}).encode()).decode()


def _decode_watermark(wm: str) -> str:
    try:
        data = json.loads(base64.b64decode(wm.encode()).decode())
        return data.get("ts", "1970-01-01 00:00:00")
    except Exception:
        return "1970-01-01 00:00:00"


def _now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S.%f")


# ---------------------------------------------------------------------------
# Pull
# ---------------------------------------------------------------------------


async def pull_changes(request: SyncPullRequest, sid: str) -> SyncPullResponse:
    since_ts = _decode_watermark(request.watermark) if request.watermark else "1970-01-01 00:00:00"
    changes: list[SyncPullChange] = []

    for doctype in SYNCABLE_DOCTYPES:
        scalar_fields = SYNCABLE_SCALAR_FIELDS.get(doctype, [])
        all_fields = ["name", "modified", "riad_version", "riad_deleted", "riad_deleted_at"] + scalar_fields

        # Child table field names to also include in the initial fetch
        child_field_names = [
            m["frappe_field"]
            for m in ADDITIVE_COLLECTIONS.get(doctype, {}).values()
        ]

        params: dict[str, Any] = {
            "filters": json.dumps([["modified", ">", since_ts]]),
            "fields": json.dumps(all_fields + child_field_names),
            "limit_page_length": 500,
        }

        try:
            result = await frappe_get(f"/api/resource/{doctype}", params=params, sid=sid)
        except Exception:
            continue

        for record in result.get("data", []):
            name = record.get("name")
            if not name:
                continue

            # Build additive section from the fetched child rows
            additive: dict[str, list[dict[str, Any]]] = {}
            for push_key, mapping in ADDITIVE_COLLECTIONS.get(doctype, {}).items():
                additive[push_key] = record.get(mapping["frappe_field"], [])

            # Scalar fields only (no sync-meta, no child table fields)
            child_field_set = set(child_field_names)
            meta_fields = {"name", "modified", "riad_version", "riad_deleted", "riad_deleted_at"}
            fields_dict = {
                k: v
                for k, v in record.items()
                if k not in meta_fields and k not in child_field_set
            }

            changes.append(
                SyncPullChange(
                    doctype=doctype,
                    name=name,
                    riad_version=int(record.get("riad_version") or 0),
                    riad_deleted=bool(record.get("riad_deleted")),
                    riad_deleted_at=record.get("riad_deleted_at"),
                    fields=fields_dict,
                    additive=additive,
                )
            )

    return SyncPullResponse(changes=changes, next_watermark=_encode_watermark(_now_iso()))


# ---------------------------------------------------------------------------
# Push
# ---------------------------------------------------------------------------


async def push_batch(request: SyncPushRequest, user_id: str, sid: str) -> SyncPushResponse:
    results: list[SyncPushItemResult] = []

    for item in request.batch:
        result = await _process_push_item(item, request.device_id, user_id, sid)
        results.append(result)

    return SyncPushResponse(results=results)


async def _process_push_item(
    item: SyncPushItem, device_id: str, user_id: str, sid: str
) -> SyncPushItemResult:
    # Try to fetch the existing document
    server_doc: dict[str, Any] | None = None
    try:
        resp = await frappe_get(f"/api/resource/{item.doctype}/{item.name}", sid=sid)
        server_doc = resp.get("data")
    except Exception:
        pass  # 404 or network error → treat as not existing

    # --- op=delete (tombstone) ---
    if item.op == "delete":
        if server_doc is None:
            # Already gone — idempotent
            return SyncPushItemResult(name=item.name, status="tombstoned", server_version=0)

        server_version = int(server_doc.get("riad_version") or 0)
        if server_doc.get("riad_deleted"):
            return SyncPushItemResult(name=item.name, status="tombstoned", server_version=server_version)

        new_version = server_version + 1
        await frappe_put(
            f"/api/resource/{item.doctype}/{item.name}",
            {
                "riad_deleted": 1,
                "riad_deleted_at": _now_iso(),
                "riad_version": new_version,
            },
            sid=sid,
        )
        return SyncPushItemResult(name=item.name, status="tombstoned", server_version=new_version)

    # --- op=upsert: create ---
    if server_doc is None:
        payload: dict[str, Any] = {
            "name": item.name,
            "riad_version": 1,
            **item.scalars,
        }
        # Set the client_uuid field so autoname=field:client_uuid produces the right name
        if item.doctype == "Visit":
            payload["client_uuid"] = item.name

        # Flatten additive rows into Frappe child table fields
        for push_key, mapping in ADDITIVE_COLLECTIONS.get(item.doctype, {}).items():
            incoming_rows = item.additive.get(push_key, [])
            payload[mapping["frappe_field"]] = incoming_rows

        await frappe_post(f"/api/resource/{item.doctype}", data=payload, sid=sid)

        # Build additive result: all rows are "added"
        additive_result: dict[str, SyncAdditiveResult] = {}
        for push_key in ADDITIVE_COLLECTIONS.get(item.doctype, {}).keys():
            rows = item.additive.get(push_key, [])
            additive_result[push_key] = SyncAdditiveResult(
                added=[r.get("_uuid", "") for r in rows],
                already_present=[],
            )

        return SyncPushItemResult(
            name=item.name,
            status="applied",
            server_version=1,
            additive=additive_result,
        )

    # --- op=upsert: update existing document ---
    server_version = int(server_doc.get("riad_version") or 0)

    # Idempotency check: if client thinks it's creating (base=0) and doc exists at v1
    # with matching scalars → already_present
    if item.client_base_version == 0 and server_version == 1:
        all_match = all(
            str(server_doc.get(k, "")) == str(v)
            for k, v in item.scalars.items()
        )
        if all_match:
            additive_result = {}
            for push_key, mapping in ADDITIVE_COLLECTIONS.get(item.doctype, {}).items():
                existing_rows = server_doc.get(mapping["frappe_field"], [])
                uuid_field = mapping["uuid_field"]
                existing_uuids = {r.get(uuid_field) for r in existing_rows if r.get(uuid_field)}
                incoming_rows = item.additive.get(push_key, [])
                already = [r.get("_uuid", "") for r in incoming_rows if r.get("_uuid") in existing_uuids]
                added = [r.get("_uuid", "") for r in incoming_rows if r.get("_uuid") not in existing_uuids]
                additive_result[push_key] = SyncAdditiveResult(added=added, already_present=already)
            return SyncPushItemResult(
                name=item.name,
                status="ignored_duplicate",
                server_version=server_version,
                additive=additive_result,
            )

    # Scalar conflict detection
    conflicts: list[SyncConflictInfo] = []
    safe_scalars: dict[str, Any] = {}

    for field, client_value in item.scalars.items():
        server_value = server_doc.get(field)
        if (
            item.client_base_version < server_version
            and str(client_value) != str(server_value)
        ):
            # Create Sync Conflict record in Frappe
            conflict_resp = await frappe_post(
                "/api/resource/Sync Conflict",
                {
                    "conflict_doctype": item.doctype,
                    "conflict_docname": item.name,
                    "conflict_field": field,
                    "server_value": str(server_value),
                    "client_value": str(client_value),
                    "server_version": server_version,
                    "client_base_version": item.client_base_version,
                    "device_id": device_id,
                    "resolved": 0,
                },
                sid=sid,
            )
            conflict_name = conflict_resp.get("data", {}).get("name", "")
            conflicts.append(
                SyncConflictInfo(
                    field=field,
                    server_value=server_value,
                    client_value=client_value,
                    conflict_id=conflict_name,
                )
            )
        else:
            safe_scalars[field] = client_value

    # Union-merge additive child rows
    additive_result = {}
    merged_children: dict[str, list[dict[str, Any]]] = {}

    for push_key, mapping in ADDITIVE_COLLECTIONS.get(item.doctype, {}).items():
        frappe_field = mapping["frappe_field"]
        uuid_field = mapping["uuid_field"]

        existing_rows: list[dict[str, Any]] = server_doc.get(frappe_field, [])
        existing_uuids = {r.get(uuid_field): r for r in existing_rows if r.get(uuid_field)}

        incoming_rows = item.additive.get(push_key, [])
        added_uuids: list[str] = []
        already_present_uuids: list[str] = []

        rows_to_write = list(existing_rows)  # keep all existing rows (with Frappe name field)

        for row in incoming_rows:
            row_uuid = row.get("_uuid") or row.get(uuid_field)
            if row_uuid and row_uuid in existing_uuids:
                already_present_uuids.append(row_uuid)
            else:
                # New row — include without Frappe internal `name` so Frappe auto-assigns
                new_row = {k: v for k, v in row.items() if k != "name"}
                if row_uuid:
                    new_row[uuid_field] = row_uuid
                rows_to_write.append(new_row)
                if row_uuid:
                    added_uuids.append(row_uuid)

        merged_children[frappe_field] = rows_to_write
        additive_result[push_key] = SyncAdditiveResult(
            added=added_uuids, already_present=already_present_uuids
        )

    # Determine final version and status
    new_version = server_version + 1
    has_changes = bool(safe_scalars or any(ar.added for ar in additive_result.values()))

    if not has_changes and not conflicts:
        return SyncPushItemResult(
            name=item.name,
            status="ignored_duplicate",
            server_version=server_version,
            additive=additive_result,
        )

    put_payload: dict[str, Any] = {"riad_version": new_version, **safe_scalars, **merged_children}
    await frappe_put(f"/api/resource/{item.doctype}/{item.name}", put_payload, sid=sid)

    status = "conflict" if conflicts else ("merged" if merged_children else "applied")
    return SyncPushItemResult(
        name=item.name,
        status=status,
        server_version=new_version,
        additive=additive_result,
        conflicts=conflicts,
    )


# ---------------------------------------------------------------------------
# Resolve
# ---------------------------------------------------------------------------


async def resolve_conflict(
    request: SyncResolveRequest, user_id: str, sid: str
) -> SyncResolveResponse:
    conflict_resp = await frappe_get(
        f"/api/resource/Sync Conflict/{request.conflict_id}", sid=sid
    )
    conflict = conflict_resp.get("data", {})

    if request.chosen == "client":
        target_doctype = conflict.get("conflict_doctype")
        target_docname = conflict.get("conflict_docname")
        field = conflict.get("conflict_field")
        client_value = conflict.get("client_value")

        doc_resp = await frappe_get(
            f"/api/resource/{target_doctype}/{target_docname}", sid=sid
        )
        doc = doc_resp.get("data", {})
        server_ver = int(doc.get("riad_version") or 0)

        await frappe_put(
            f"/api/resource/{target_doctype}/{target_docname}",
            {field: client_value, "riad_version": server_ver + 1},
            sid=sid,
        )

    await frappe_put(
        f"/api/resource/Sync Conflict/{request.conflict_id}",
        {"resolved": 1, "chosen": request.chosen, "resolved_by": user_id},
        sid=sid,
    )

    return SyncResolveResponse(
        conflict_id=request.conflict_id,
        status="resolved",
        chosen=request.chosen,
    )
