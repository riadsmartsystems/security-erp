import frappe
from frappe.model.document import Document


class InstallationAct(Document):
    def validate(self):
        self.validate_items()
        self.calculate_totals()

    def validate_items(self):
        if not self.items or len(self.items) == 0:
            frappe.throw("At least one installed item is required")

    def calculate_totals(self):
        total = 0
        for item in self.items:
            if item.qty and item.rate:
                item.amount = item.qty * item.rate
                total += item.amount
        self.total_amount = total

    def on_submit(self):
        self.status = "Pending Approval"
        for item in self.items:
            if not item.serial_number:
                continue
            if frappe.db.exists("Equipment", {"serial_number": item.serial_number}):
                eq = frappe.get_doc("Equipment", {"serial_number": item.serial_number})
            else:
                eq = frappe.new_doc("Equipment")
                eq.serial_number = item.serial_number
            eq.item_code = item.item_code
            eq.status = "Installed"
            eq.installation_act = self.name
            eq.security_object = self.security_object
            eq.save(ignore_permissions=True)
        self.save(ignore_permissions=True)

    def on_cancel(self):
        self.status = "Rejected"
