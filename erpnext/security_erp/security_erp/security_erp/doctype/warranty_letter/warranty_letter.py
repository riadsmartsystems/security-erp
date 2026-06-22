import frappe
from frappe.model.document import Document
from frappe.utils import add_months


class WarrantyLetter(Document):
    def validate(self):
        if self.issue_date and self.warranty_months:
            self.expiry_date = add_months(self.issue_date, self.warranty_months)

    def on_submit(self):
        self.status = "Issued"
