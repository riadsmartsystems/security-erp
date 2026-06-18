import frappe
from frappe.model.document import Document
from frappe.utils import add_months, formatdate


class WarrantyLetter(Document):
    def validate(self):
        self.calculate_expiry()

    def calculate_expiry(self):
        if self.issue_date and self.warranty_months:
            self.expiry_date = add_months(self.issue_date, self.warranty_months)
