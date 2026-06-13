import frappe
from frappe.model.document import Document


class MaterialReservation(Document):
    def validate(self):
        self.validate_items()

    def validate_items(self):
        if not self.items or len(self.items) == 0:
            frappe.throw("At least one item is required")

    def on_submit(self):
        self.status = "Reserved"

    def on_cancel(self):
        self.status = "Cancelled"
