import frappe
from frappe.utils import now_datetime
from datetime import timedelta


def check_sla_breaches():
    now = now_datetime()

    tickets = frappe.get_all(
        "Service Ticket",
        filters={
            "status": ["not in", ["Closed", "Cancelled", "Resolved"]],
            "is_active": 1,
            "sla_paused_at": ["is", "not set"],
        },
        fields=[
            "name", "ticket_number", "priority", "status",
            "sla_response_due", "sla_arrival_due", "sla_resolution_due",
            "sla_response_breached", "sla_arrival_breached", "sla_resolution_breached",
        ],
    )

    breaches = []
    for t in tickets:
        if not t.sla_response_breached and t.sla_response_due and now > t.sla_response_due:
            frappe.db.set_value("Service Ticket", t.name, "sla_response_breached", 1)
            _log_sla_event(t.name, "Breached", "Response", f"Response SLA breached at {now}")
            breaches.append({"ticket_number": t.ticket_number, "type": "response", "priority": t.priority})

        if not t.sla_arrival_breached and t.sla_arrival_due and now > t.sla_arrival_due:
            frappe.db.set_value("Service Ticket", t.name, "sla_arrival_breached", 1)
            _log_sla_event(t.name, "Breached", "Arrival", f"Arrival SLA breached at {now}")
            breaches.append({"ticket_number": t.ticket_number, "type": "arrival", "priority": t.priority})

        if not t.sla_resolution_breached and t.sla_resolution_due and now > t.sla_resolution_due:
            frappe.db.set_value("Service Ticket", t.name, "sla_resolution_breached", 1)
            _log_sla_event(t.name, "Breached", "Resolution", f"Resolution SLA breached at {now}")
            breaches.append({"ticket_number": t.ticket_number, "type": "resolution", "priority": t.priority})

    if breaches:
        frappe.db.commit()
        _notify_sla_breaches(breaches)

    return breaches


def _log_sla_event(ticket_name, event_type, timer_type, details):
    ticket = frappe.get_doc("Service Ticket", ticket_name)
    ticket.append("sla_events", {
        "event_type": event_type,
        "timer_type": timer_type,
        "occurred_at": now_datetime(),
        "details": details,
    })
    ticket.save(ignore_permissions=True)


def _notify_sla_breaches(breaches):
    for breach in breaches:
        try:
            frappe.publish_realtime(
                "security_erp:sla_breached",
                breach,
                after_commit=True,
            )
        except Exception:
            pass
