import frappe
from frappe.utils import now_datetime


def get_sla_status(ticket_name):
    """Get SLA status for a ticket (Jinja method)."""
    try:
        ticket = frappe.get_doc("Service Ticket", ticket_name)
        now = now_datetime()

        if ticket.sla_resolution_breached:
            return "Breached"
        if ticket.sla_resolution_due and now > ticket.sla_resolution_due:
            return "Breached"
        if ticket.sla_resolution_due:
            diff = (ticket.sla_resolution_due - now).total_seconds() / 3600
            if diff < 4:
                return "Warning"
        return "OK"
    except Exception:
        return "Unknown"
