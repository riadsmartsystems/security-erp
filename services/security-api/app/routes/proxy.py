import json
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, Request, Response
from app.core.database import frappe_get, frappe_post, frappe_put
from app.auth.dependencies import get_current_user, CurrentUser
from app.auth.permissions import Permission, has_permission

router = APIRouter(tags=["proxy"])

FRAPPE_DOCTYPE_MAP = {
    "/api/v1/tickets": "Service Ticket",
    "/api/v1/visits": "Visit",
    "/api/v1/maintenance": "Maintenance Plan",
    "/api/v1/warranty": "Warranty Case",
    "/api/v1/objects": "Security Object",
    "/api/v1/equipment": "Equipment",
    "/api/v1/equipment-types": "Equipment Type",
    "/api/v1/vendors": "Vendor",
    "/api/v1/topology": "Equipment Relation",
}

PERMISSION_MAP = {
    "/api/v1/tickets": [Permission.FSM_FULL, Permission.FSM_OWN],
    "/api/v1/visits": [Permission.FSM_FULL, Permission.FSM_OWN],
    "/api/v1/maintenance": [Permission.FSM_FULL],
    "/api/v1/warranty": [Permission.FSM_FULL],
    "/api/v1/objects": [Permission.CMDB_FULL, Permission.CMDB_READ],
    "/api/v1/equipment": [Permission.CMDB_FULL, Permission.CMDB_READ],
    "/api/v1/equipment-types": [Permission.CMDB_FULL, Permission.CMDB_READ],
    "/api/v1/vendors": [Permission.CMDB_FULL, Permission.CMDB_READ],
    "/api/v1/topology": [Permission.CMDB_FULL, Permission.CMDB_READ],
    "/api/v1/checklists": [Permission.FSM_FULL, Permission.FSM_OWN],
    "/api/v1/photos": [Permission.CMDB_FULL, Permission.CMDB_READ, Permission.FSM_FULL, Permission.FSM_OWN],
    "/api/v1/ai": [Permission.AI_FULL, Permission.AI_LIMITED, Permission.AI_OWN],
    "/api/v1/backups": [Permission.CMDB_FULL],
    "/api/v1/topology": [Permission.CMDB_FULL, Permission.CMDB_READ],
}

ACTION_MAP = {
    "assign": {"field": "assigned_engineer", "status": "Assigned"},
    "status": {},
    "close": {"status": "Closed"},
    "start": {},
    "finish": {},
    "materials": {},
}


def _has_access(current_user: CurrentUser, path: str) -> bool:
    for prefix, perms in PERMISSION_MAP.items():
        if path.startswith(prefix):
            return any(has_permission(current_user.role, p) for p in perms)
    return True


def _get_doctype(path: str) -> str | None:
    for prefix, dt in FRAPPE_DOCTYPE_MAP.items():
        if path.startswith(prefix):
            return dt
    return None


def _translate_filters(params: dict, doctype: str) -> list:
    filters = []
    if params.get("status"):
        filters.append([doctype, "status", "=", params["status"]])
    if params.get("priority"):
        filters.append([doctype, "priority", "=", params["priority"]])
    if params.get("assigned_engineer_id"):
        filters.append([doctype, "assigned_engineer", "=", params["assigned_engineer_id"]])
    if params.get("customer_id"):
        filters.append([doctype, "customer", "=", params["customer_id"]])
    if params.get("ticket_id"):
        filters.append([doctype, "ticket", "=", params["ticket_id"]])
    if params.get("object_id"):
        filters.append([doctype, "security_object", "=", params["object_id"]])
    return filters


def _translate_ticket(doc: dict) -> dict:
    return {
        "id": doc.get("name"),
        "ticket_number": doc.get("ticket_number") or doc.get("name"),
        "customer_id": doc.get("customer"),
        "object_id": doc.get("security_object"),
        "contract_id": doc.get("contract"),
        "ticket_type": (doc.get("ticket_type") or "").lower().replace(" ", "_"),
        "priority": (doc.get("priority") or "").lower(),
        "status": (doc.get("status") or "").lower().replace(" ", "_"),
        "title": doc.get("title"),
        "description": doc.get("description"),
        "assigned_engineer_id": doc.get("assigned_engineer"),
        "sla_response_due": doc.get("sla_response_due"),
        "sla_arrival_due": doc.get("sla_arrival_due"),
        "sla_resolution_due": doc.get("sla_resolution_due"),
        "sla_response_breached": doc.get("sla_response_breached", 0),
        "sla_resolution_breached": doc.get("sla_resolution_breached", 0),
        "created_at": doc.get("creation"),
        "updated_at": doc.get("modified"),
    }


def _translate_visit(doc: dict) -> dict:
    return {
        "id": doc.get("name"),
        "visit_number": doc.get("visit_number") or doc.get("name"),
        "ticket_id": doc.get("parent") or doc.get("ticket"),
        "engineer_id": doc.get("engineer"),
        "status": (doc.get("status") or "").lower().replace(" ", "_"),
        "planned_start": doc.get("planned_start"),
        "actual_start": doc.get("actual_start"),
        "actual_finish": doc.get("actual_finish"),
        "created_at": doc.get("creation"),
    }


def _translate_object(doc: dict) -> dict:
    return {
        "id": doc.get("name"),
        "object_code": doc.get("object_code") or doc.get("name"),
        "customer_id": doc.get("customer"),
        "name": doc.get("object_name") or doc.get("name"),
        "address": doc.get("address"),
        "gps_lat": doc.get("gps_lat"),
        "gps_lon": doc.get("gps_lon"),
        "object_type": (doc.get("object_type") or "").lower().replace(" ", "_"),
        "service_level": (doc.get("service_level") or "").lower(),
        "status": (doc.get("status") or "").lower(),
        "created_at": doc.get("creation"),
    }


def _translate_equipment(doc: dict) -> dict:
    return {
        "id": doc.get("name"),
        "equipment_code": doc.get("equipment_code") or doc.get("name"),
        "object_id": doc.get("security_object"),
        "room_id": doc.get("room"),
        "equipment_type_id": doc.get("equipment_type"),
        "vendor_id": doc.get("vendor"),
        "model": doc.get("model"),
        "serial_number": doc.get("serial_number"),
        "firmware_version": doc.get("firmware_version"),
        "ip_address": doc.get("ip_address"),
        "mac_address": doc.get("mac_address"),
        "install_date": doc.get("install_date"),
        "warranty_end_date": doc.get("warranty_end_date"),
        "status": (doc.get("status") or "").lower().replace(" ", "_"),
        "created_at": doc.get("creation"),
    }


def _translate_maintenance_plan(doc: dict) -> dict:
    return {
        "id": doc.get("name"),
        "name": doc.get("plan_name"),
        "object_id": doc.get("security_object"),
        "customer_id": doc.get("customer"),
        "frequency": (doc.get("frequency") or "").lower().replace("-", "_"),
        "next_due_date": doc.get("next_due_date"),
        "last_executed": doc.get("last_executed"),
        "is_active": doc.get("is_active", 1),
        "created_at": doc.get("creation"),
    }


def _translate_warranty_case(doc: dict) -> dict:
    return {
        "id": doc.get("name"),
        "case_number": doc.get("case_number") or doc.get("name"),
        "ticket_id": doc.get("ticket"),
        "equipment_id": doc.get("equipment"),
        "customer_id": doc.get("customer"),
        "description": doc.get("description"),
        "status": (doc.get("status") or "").lower(),
        "resolution": doc.get("resolution"),
        "manufacturer_claim": doc.get("manufacturer_claim", 0),
        "created_at": doc.get("creation"),
    }


def _translate_equipment_type(doc: dict) -> dict:
    return {
        "id": doc.get("name"),
        "name": doc.get("type_name"),
        "code": doc.get("type_code"),
        "category": doc.get("category"),
        "parent_id": doc.get("parent_type"),
        "is_active": doc.get("is_active", 1),
    }


def _translate_vendor(doc: dict) -> dict:
    return {
        "id": doc.get("name"),
        "name": doc.get("vendor_name"),
        "code": doc.get("vendor_code"),
        "website": doc.get("website"),
        "support_email": doc.get("support_email"),
        "support_phone": doc.get("support_phone"),
        "is_active": doc.get("is_active", 1),
    }


def _translate_relation(doc: dict) -> dict:
    return {
        "id": doc.get("name"),
        "source_equipment_id": doc.get("source_equipment"),
        "target_equipment_id": doc.get("target_equipment"),
        "relation_type": (doc.get("relation_type") or "").lower().replace(" ", "_"),
        "port_label": doc.get("port_label"),
        "notes": doc.get("notes"),
        "is_active": doc.get("is_active", 1),
    }


TRANSLATORS = {
    "Service Ticket": _translate_ticket,
    "Visit": _translate_visit,
    "Security Object": _translate_object,
    "Equipment": _translate_equipment,
    "Maintenance Plan": _translate_maintenance_plan,
    "Warranty Case": _translate_warranty_case,
    "Equipment Type": _translate_equipment_type,
    "Vendor": _translate_vendor,
    "Equipment Relation": _translate_relation,
}


def _translate_result(doctype: str, doc: dict) -> dict:
    translator = TRANSLATORS.get(doctype)
    if translator:
        return translator(doc)
    return doc


@router.api_route("/api/v1/{path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE"], include_in_schema=False)
async def proxy(
    path: str,
    request: Request,
    current_user: CurrentUser = Depends(get_current_user),
):
    full_path = f"/api/v1/{path}"
    doctype = _get_doctype(full_path)

    if not doctype:
        return Response(
            status_code=404,
            content=json.dumps({"success": False, "error": "Route not found"}),
            media_type="application/json",
        )

    if not _has_access(current_user, full_path):
        return Response(
            status_code=403,
            content=json.dumps({"success": False, "error": "Access denied"}),
            media_type="application/json",
        )

    parts = path.split("/")
    params = dict(request.query_params)
    body = None
    if request.method in ("POST", "PUT", "PATCH"):
        try:
            body = await request.json()
        except Exception:
            body = {}

    try:
        if request.method == "GET":
            if len(parts) == 1:
                return await _handle_list(doctype, params)
            elif len(parts) == 2:
                return await _handle_get(doctype, parts[1])
            elif len(parts) == 3 and parts[2] == "equipment":
                return await _handle_child_list("Equipment", "security_object", parts[1])
            elif len(parts) == 3 and parts[2] == "timeline":
                return await _handle_timeline(parts[1])
            else:
                return await _handle_get(doctype, parts[1])

        elif request.method == "POST":
            if len(parts) >= 3 and parts[2] in ACTION_MAP:
                return await _handle_action(doctype, parts[1], parts[2], body)
            else:
                return await _handle_create(doctype, body, current_user)

        elif request.method in ("PUT", "PATCH"):
            if len(parts) >= 2:
                return await _handle_update(doctype, parts[1], body)
            return Response(
                status_code=400,
                content=json.dumps({"success": False, "error": "Missing resource name"}),
                media_type="application/json",
            )

    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response(
            status_code=502,
            content=json.dumps({"success": False, "error": str(e)}),
            media_type="application/json",
        )


async def _handle_list(doctype: str, params: dict) -> Response:
    filters = _translate_filters(params, doctype)
    limit = int(params.get("limit", 50))
    offset = int(params.get("offset", 0))

    frappe_params = {
        "limit_page_length": limit,
        "limit_start": offset,
        "order_by": "modified desc",
    }
    if filters:
        frappe_params["filters"] = json.dumps(filters)

    result = await frappe_get(f"/api/resource/{doctype}", params=frappe_params)
    docs = result.get("data", [])
    translated = [_translate_result(doctype, d) for d in docs]

    count_result = await frappe_get(f"/api/method/frappe.client.get_count", params={
        "doctype": doctype,
        "filters": json.dumps(filters) if filters else "{}",
    })
    total = count_result.get("message", len(translated))

    return Response(
        content=json.dumps({
            "success": True,
            "data": translated,
            "total": total,
            "limit": limit,
            "offset": offset,
        }),
        media_type="application/json",
    )


async def _handle_get(doctype: str, name: str) -> Response:
    result = await frappe_get(f"/api/resource/{doctype}/{name}")
    doc = result.get("data", {})
    translated = _translate_result(doctype, doc)
    return Response(
        content=json.dumps({"success": True, "data": translated}),
        media_type="application/json",
    )


async def _handle_create(doctype: str, body: dict, current_user: CurrentUser) -> Response:
    frappe_body = _reverse_translate(body, doctype)
    result = await frappe_post(f"/api/resource/{doctype}", data=frappe_body)
    doc = result.get("data", {})
    translated = _translate_result(doctype, doc)
    return Response(
        content=json.dumps({"success": True, "data": translated}),
        media_type="application/json",
    )


async def _handle_update(doctype: str, name: str, body: dict) -> Response:
    frappe_body = _reverse_translate(body, doctype)
    result = await frappe_put(f"/api/resource/{doctype}/{name}", data=frappe_body)
    doc = result.get("data", {})
    translated = _translate_result(doctype, doc)
    return Response(
        content=json.dumps({"success": True, "data": translated}),
        media_type="application/json",
    )


async def _handle_action(doctype: str, name: str, action: str, body: dict) -> Response:
    update_data = {}

    if action == "assign" and body.get("engineer_id"):
        update_data["assigned_engineer"] = body["engineer_id"]
        update_data["status"] = "Assigned"
    elif action == "status" and body.get("status"):
        update_data["status"] = body["status"].replace("_", " ").title()
    elif action == "close":
        update_data["status"] = "Closed"
    elif action == "start":
        update_data["status"] = "Arrived"
        update_data["actual_start"] = datetime.now(timezone.utc).isoformat()
        if body.get("lat") is not None:
            update_data["gps_checkin_lat"] = body["lat"]
        if body.get("lon") is not None:
            update_data["gps_checkin_lon"] = body["lon"]
    elif action == "finish":
        update_data["status"] = "Completed"
        update_data["actual_finish"] = datetime.now(timezone.utc).isoformat()
        if body.get("lat") is not None:
            update_data["gps_checkout_lat"] = body["lat"]
        if body.get("lon") is not None:
            update_data["gps_checkout_lon"] = body["lon"]
    elif action == "materials":
        update_data["materials"] = [body] if body else []

    result = await frappe_put(f"/api/resource/{doctype}/{name}", data=update_data)
    doc = result.get("data", {})
    translated = _translate_result(doctype, doc)
    return Response(
        content=json.dumps({"success": True, "data": translated}),
        media_type="application/json",
    )


async def _handle_child_list(doctype: str, parent_field: str, parent_name: str) -> Response:
    filters = [[parent_field, "=", parent_name]]
    result = await frappe_get(f"/api/resource/{doctype}", params={
        "filters": json.dumps(filters),
        "limit_page_length": 100,
    })
    docs = result.get("data", [])
    translated = [_translate_result(doctype, d) for d in docs]
    return Response(
        content=json.dumps({"success": True, "data": translated}),
        media_type="application/json",
    )


async def _handle_timeline(object_id: str) -> Response:
    obj_result = await frappe_get(f"/api/resource/Security Object/{object_id}")
    obj = obj_result.get("data", {})

    eq_result = await frappe_get(f"/api/resource/Equipment", params={
        "filters": json.dumps([["security_object", "=", object_id]]),
        "limit_page_length": 100,
    })
    equipment = eq_result.get("data", [])

    timeline = [{"type": "object_created", "date": obj.get("creation"), "description": f"Object {obj.get('name')} created"}]
    for eq in equipment:
        if eq.get("install_date"):
            timeline.append({
                "type": "equipment_installed",
                "date": eq["install_date"],
                "description": f"Equipment {eq.get('equipment_code', eq.get('name'))} ({eq.get('model')}) installed",
            })
    timeline.sort(key=lambda x: x.get("date", ""), reverse=True)

    return Response(
        content=json.dumps({"success": True, "data": timeline}),
        media_type="application/json",
    )


def _reverse_translate(body: dict, doctype: str) -> dict:
    if not body:
        return {}

    field_map = {
        "Service Ticket": {
            "customer_id": "customer",
            "object_id": "security_object",
            "contract_id": "contract",
            "assigned_engineer_id": "assigned_engineer",
            "ticket_type": lambda v: v.replace("_", " ").title(),
            "priority": lambda v: v.title(),
            "status": lambda v: v.replace("_", " ").title(),
        },
        "Visit": {
            "ticket_id": "parent",
            "engineer_id": "engineer",
            "status": lambda v: v.replace("_", " ").title(),
        },
        "Security Object": {
            "customer_id": "customer",
            "object_type": lambda v: v.replace("_", " ").title() if v else v,
            "service_level": lambda v: v.title() if v else v,
        },
        "Equipment": {
            "object_id": "security_object",
            "room_id": "room",
            "equipment_type_id": "equipment_type",
            "vendor_id": "vendor",
            "status": lambda v: v.replace("_", " ").title(),
        },
        "Maintenance Plan": {
            "object_id": "security_object",
            "customer_id": "customer",
            "frequency": lambda v: v.replace("_", " ").title() if v else v,
        },
        "Warranty Case": {
            "ticket_id": "ticket",
            "equipment_id": "equipment",
            "customer_id": "customer",
        },
        "Equipment Type": {
            "parent_id": "parent_type",
        },
        "Vendor": {},
        "Equipment Relation": {
            "source_equipment_id": "source_equipment",
            "target_equipment_id": "target_equipment",
            "relation_type": lambda v: v.replace("_", " ").title(),
        },
    }

    mapping = field_map.get(doctype, {})
    result = {}
    for key, value in body.items():
        if key in mapping:
            target = mapping[key]
            if callable(target):
                result[key] = target(value)
            else:
                result[target] = value
        else:
            result[key] = value

    return result
