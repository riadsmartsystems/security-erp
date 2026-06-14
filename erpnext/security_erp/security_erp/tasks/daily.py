import frappe
from frappe.utils import now_datetime
from datetime import timedelta


def check_sla_compliance():
    total = frappe.db.count("Service Ticket", {"is_active": 1})
    if total == 0:
        return

    breached = frappe.db.count("Service Ticket", {
        "is_active": 1,
        "sla_resolution_breached": 1,
    })

    compliance = ((total - breached) / total * 100) if total > 0 else 100

    frappe.get_doc({
        "doctype": "Communication",
        "communication_type": "Communication",
        "subject": f"Daily SLA Report: {compliance:.0f}% compliance ({breached}/{total} breached)",
        "content": f"SLA Compliance: {compliance:.1f}%\nTotal tickets: {total}\nBreached: {breached}",
        "sent_or_received": "Received",
        "reference_doctype": "Service Ticket",
    }).insert(ignore_permissions=True)

    frappe.db.commit()


def check_warranty_expiry():
    soon = now_datetime().date() + timedelta(days=30)
    today = now_datetime().date()

    expiring = frappe.get_all(
        "Equipment",
        filters={
            "warranty_end_date": ["between", [today, soon]],
            "status": ["not in", ["Retired", "Replaced"]],
        },
        fields=["name", "equipment_code", "model", "warranty_end_date", "security_object"],
    )

    for eq in expiring:
        try:
            frappe.get_doc({
                "doctype": "ToDo",
                "description": f"Warranty expiring for {eq.equipment_code} ({eq.model}) on {eq.warranty_end_date}",
                "reference_type": "Equipment",
                "reference_name": eq.name,
                "assigned_by": "Administrator",
            }).insert(ignore_permissions=True)
        except Exception:
            pass

    frappe.db.commit()
