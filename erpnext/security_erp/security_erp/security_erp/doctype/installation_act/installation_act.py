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
        self.create_equipment_records()

    def on_cancel(self):
        self.status = "Rejected"

    def create_equipment_records(self):
        for item in self.items:
            if not item.serial_number:
                continue

            existing = frappe.db.exists("Equipment", {"serial_number": item.serial_number})
            if existing:
                equip = frappe.get_doc("Equipment", existing)
                equip.status = "Installed"
                equip.install_date = self.act_date
                equip.save()
            else:
                equip = frappe.get_doc({
                    "doctype": "Equipment",
                    "security_object": self.project,
                    "equipment_type": item.item_code,
                    "model": item.item_name or item.item_code,
                    "serial_number": item.serial_number,
                    "vendor": self.customer,
                    "status": "Installed",
                    "install_date": self.act_date,
                })
                equip.insert()

        frappe.msgprint("Equipment records created/updated")
