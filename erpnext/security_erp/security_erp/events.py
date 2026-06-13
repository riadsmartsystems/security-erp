import frappe
import json


def lead_on_update(doc, method):
    """When Lead status changes to Won, trigger automation."""
    if doc.has_value_changed("lead_status") and doc.lead_status == "Converted":
        frappe.publish_realtime(
            "security_erp:lead_won",
            {"lead": doc.name, "lead_name": doc.lead_name},
            after_commit=True,
        )


def customer_after_insert(doc, method):
    """After Customer is created, publish event for microservices."""
    frappe.publish_realtime(
        "security_erp:customer_created",
        {"customer": doc.name, "customer_name": doc.customer_name},
        after_commit=True,
    )


def quotation_on_update(doc, method):
    """Track Quotation status changes."""
    if doc.has_value_changed("status"):
        frappe.publish_realtime(
            "security_erp:quotation_status_changed",
            {"quotation": doc.name, "status": doc.status},
            after_commit=True,
        )


def sales_order_on_update(doc, method):
    """Track Sales Order status changes."""
    if doc.has_value_changed("status"):
        frappe.publish_realtime(
            "security_erp:sales_order_status_changed",
            {"sales_order": doc.name, "status": doc.status},
            after_commit=True,
        )


def project_on_update(doc, method):
    """Track Project status changes."""
    if doc.has_value_changed("status"):
        frappe.publish_realtime(
            "security_erp:project_status_changed",
            {"project": doc.name, "status": doc.status, "project_name": doc.project_name},
            after_commit=True,
        )
