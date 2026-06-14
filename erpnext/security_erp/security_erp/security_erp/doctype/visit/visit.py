import frappe
from frappe.model.document import Document


class Visit(Document):
    def validate(self):
        if self.actual_start and self.actual_finish:
            self.work_minutes = int((self.actual_finish - self.actual_start).total_seconds() / 60)
