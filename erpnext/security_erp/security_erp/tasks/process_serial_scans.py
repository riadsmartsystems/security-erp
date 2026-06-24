"""RQ task: process serial scans after sync push.

Enqueued when Visit Materials with media_type=serial are synced.
Calls serial_scan.record_serial_scan via Frappe whitelisted method.
"""

import frappe


def process_serial_scans(visit_name):
    """Process serial scans from a Visit's materials after sync push.

    Args:
        visit_name: Frappe name of the Visit document.
    """
    try:
        materials = frappe.get_all(
            "Visit Material",
            filters={"parent": visit_name, "media_type": "serial"},
            fields=["serial_no", "item", "client_uuid"],
        )
        for mat in materials:
            if not mat.serial_no:
                continue
            frappe.get_doc({
                "doctype": "Serial No",
                "serial_no": mat.serial_no,
                "item": mat.item,
            }).insert(ignore_permissions=True)
        frappe.db.commit()
    except Exception:
        frappe.log_error("process_serial_scans failed", "serial_scan")
