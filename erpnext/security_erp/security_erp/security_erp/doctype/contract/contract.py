import frappe
from frappe.model.document import Document


class Contract(Document):
    def validate(self):
        self.validate_dates()

    def validate_dates(self):
        if self.start_date and self.end_date:
            if self.start_date > self.end_date:
                frappe.throw("End Date must be after Start Date")

    def before_insert(self):
        if not self.contract_number:
            self.contract_number = self.name

    def on_update(self):
        if self.has_value_changed("status"):
            frappe.publish_realtime(
                "security_erp:contract_status_changed",
                {"contract": self.name, "status": self.status},
                after_commit=True,
            )
