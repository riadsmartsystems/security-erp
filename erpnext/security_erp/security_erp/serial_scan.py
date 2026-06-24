"""Frappe whitelisted method: record a serial scan from field sync.

Called from RQ task after sync push, or from FastAPI proxy via delegated user.
Finds or creates Serial No in ERPNext, links to Item, logs in Visit Material.
"""

import frappe


@frappe.whitelist()
def record_serial_scan(serial_no, item=None, visit_uuid=None):
    """Record a serial scan into ERPNext.

    Args:
        serial_no: Serial number string (required).
        item: Item name/link (optional). Links Serial No to Item if provided.
        visit_uuid: Visit client UUID (optional). Creates Visit Material log entry.

    Returns:
        dict: {serial_no, created, linked_item}
    """
    if not serial_no or not str(serial_no).strip():
        frappe.throw("serial_no is required")

    serial_no = str(serial_no).strip()
    created = False

    sn_name = frappe.db.get_value("Serial No", {"serial_no": serial_no}, "name")
    if sn_name:
        sn = frappe.get_doc("Serial No", sn_name)
    else:
        sn = frappe.get_doc({
            "doctype": "Serial No",
            "serial_no": serial_no,
        })
        if item:
            sn.item = item
        sn.insert(ignore_permissions=True)
        created = True

    linked_item = None
    if item and not sn.item:
        frappe.db.set_value("Serial No", sn.name, "item", item, update_modified=False)
        linked_item = item
    elif sn.item:
        linked_item = sn.item

    if visit_uuid:
        _log_visit_material(serial_no, item or linked_item, visit_uuid)

    frappe.db.commit()

    return {
        "serial_no": serial_no,
        "created": created,
        "linked_item": linked_item,
    }


def _log_visit_material(serial_no, item, visit_uuid):
    """Create a Visit Material entry with media_type=serial for audit trail."""
    try:
        visit_name = frappe.db.get_value("Visit", {"client_uuid": visit_uuid}, "name")
        if not visit_name:
            return

        frappe.get_doc({
            "doctype": "Visit Material",
            "parent": visit_name,
            "parenttype": "Visit",
            "parentfield": "materials",
            "client_uuid": frappe.utils.cstr(frappe.utils.uuid.uuid4()),
            "item": item,
            "serial_no": serial_no,
            "media_type": "serial",
            "quantity": 1,
        }).insert(ignore_permissions=True)
    except Exception:
        frappe.log_error("serial_scan._log_visit_material failed", "serial_scan")
