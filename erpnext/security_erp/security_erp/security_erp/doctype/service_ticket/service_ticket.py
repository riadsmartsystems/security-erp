import frappe
from frappe.model.document import Document
from datetime import timedelta


SLA_HOURS = {
    "Critical": {"response": 0.5, "arrival": 2, "resolution": 8},
    "High": {"response": 2, "arrival": 8, "resolution": 24},
    "Medium": {"response": 8, "arrival": 24, "resolution": 72},
    "Low": {"response": 24, "arrival": 168, "resolution": 168},
}

SLA_PAUSABLE_STATUSES = {"Waiting Parts"}


class ServiceTicket(Document):
    def validate(self):
        self.set_sla_deadlines()

    def before_insert(self):
        if self.assigned_engineer and self.status == "New":
            self.status = "Assigned"

    def on_update(self):
        self.handle_status_change()

    def set_sla_deadlines(self):
        if self.is_new() and not self.sla_response_due:
            hours = SLA_HOURS.get(self.priority, SLA_HOURS["Medium"])
            now = frappe.utils.now_datetime()
            self.sla_response_due = now + timedelta(hours=hours["response"])
            self.sla_arrival_due = now + timedelta(hours=hours["arrival"])
            self.sla_resolution_due = now + timedelta(hours=hours["resolution"])

    def handle_status_change(self):
        if not self.has_value_changed("status"):
            return

        old_status = self.get_doc_before_save()
        old_val = old_status.status if old_status else None

        if self.status == "Waiting Parts" and old_val != "Waiting Parts":
            self.pause_sla()
        elif old_val == "Waiting Parts" and self.status != "Waiting Parts":
            self.resume_sla()

        if self.status == "Resolved" and not self.resolved_at:
            self.resolved_at = frappe.utils.now_datetime()
        elif self.status == "Closed" and not self.closed_at:
            self.closed_at = frappe.utils.now_datetime()

        frappe.publish_realtime(
            "security_erp:ticket_status_changed",
            {"ticket": self.name, "status": self.status},
            after_commit=True,
        )

    def pause_sla(self):
        self.sla_paused_at = frappe.utils.now_datetime()
        self.append("sla_events", {
            "event_type": "Paused",
            "timer_type": "Resolution",
            "occurred_at": frappe.utils.now_datetime(),
            "details": f"Paused in status {self.status}",
        })

    def resume_sla(self):
        if self.sla_paused_at:
            paused_minutes = (frappe.utils.now_datetime() - self.sla_paused_at).total_seconds() / 60
            self.sla_pause_minutes = (self.sla_pause_minutes or 0) + int(paused_minutes)
            if self.sla_resolution_due:
                self.sla_resolution_due = self.sla_resolution_due + timedelta(minutes=paused_minutes)
            self.sla_paused_at = None
            self.append("sla_events", {
                "event_type": "Resumed",
                "timer_type": "Resolution",
                "occurred_at": frappe.utils.now_datetime(),
                "details": f"Resumed, paused for {int(paused_minutes)} minutes",
            })
