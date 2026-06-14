import frappe
import json
import httpx


def after_install():
    frappe.get_doc({
        "doctype": "Role",
        "role_name": "Service Manager",
        "desk_access": 1,
        "is_custom": 0,
    }).insert(ignore_permissions=True)

    frappe.get_doc({
        "doctype": "Role",
        "role_name": "Engineer",
        "desk_access": 0,
        "is_custom": 0,
    }).insert(ignore_permissions=True)

    frappe.db.commit()


def lead_on_update(doc, method):
    if doc.has_value_changed("lead_status") and doc.lead_status == "Converted":
        frappe.publish_realtime(
            "security_erp:lead_won",
            {"lead": doc.name, "lead_name": doc.lead_name},
            after_commit=True,
        )


def customer_after_insert(doc, method):
    frappe.publish_realtime(
        "security_erp:customer_created",
        {"customer": doc.name, "customer_name": doc.customer_name},
        after_commit=True,
    )


def quotation_on_update(doc, method):
    if doc.has_value_changed("status"):
        frappe.publish_realtime(
            "security_erp:quotation_status_changed",
            {"quotation": doc.name, "status": doc.status},
            after_commit=True,
        )


def sales_order_on_update(doc, method):
    if doc.has_value_changed("status"):
        frappe.publish_realtime(
            "security_erp:sales_order_status_changed",
            {"sales_order": doc.name, "status": doc.status},
            after_commit=True,
        )


def project_on_update(doc, method):
    if doc.has_value_changed("status"):
        frappe.publish_realtime(
            "security_erp:project_status_changed",
            {"project": doc.name, "status": doc.status, "project_name": doc.project_name},
            after_commit=True,
        )


def ticket_on_update(doc, method):
    if doc.has_value_changed("status"):
        frappe.publish_realtime(
            "security_erp:ticket_status_changed",
            {"ticket": doc.name, "ticket_number": doc.ticket_number, "status": doc.status},
            after_commit=True,
        )

        _notify_n8n("new-ticket", {
            "ticket_number": doc.ticket_number,
            "title": doc.title,
            "priority": doc.priority,
            "status": doc.status,
            "object_name": doc.security_object,
            "customer_name": doc.customer_name,
        })


def ticket_after_insert(doc, method):
    frappe.publish_realtime(
        "security_erp:ticket_created",
        {"ticket": doc.name, "ticket_number": doc.ticket_number, "priority": doc.priority},
        after_commit=True,
    )

    _notify_n8n("new-ticket", {
        "ticket_number": doc.ticket_number,
        "title": doc.title,
        "priority": doc.priority,
        "status": doc.status,
        "object_name": doc.security_object,
        "customer_name": doc.customer_name,
    })

    if doc.priority == "Critical":
        _notify_n8n("emergency-ticket", {
            "ticket_number": doc.ticket_number,
            "title": doc.title,
            "address": doc.description,
            "contact": doc.customer_name,
        })


def _notify_n8n(webhook_path, data):
    try:
        n8n_url = frappe.conf.get("n8n_url", "http://n8n:5678")
        httpx.post(
            f"{n8n_url}/webhook/{webhook_path}",
            json=data,
            timeout=5.0,
        )
    except Exception:
        pass
