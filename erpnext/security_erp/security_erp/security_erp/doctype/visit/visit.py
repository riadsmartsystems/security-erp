import frappe
from frappe.model.document import Document


class Visit(Document):
    def validate(self):
        if self.actual_start and self.actual_finish:
            from datetime import datetime
            try:
                start = self.actual_start if isinstance(self.actual_start, datetime) else datetime.fromisoformat(str(self.actual_start))
                finish = self.actual_finish if isinstance(self.actual_finish, datetime) else datetime.fromisoformat(str(self.actual_finish))
                self.work_minutes = int((finish - start).total_seconds() / 60)
            except Exception:
                pass
