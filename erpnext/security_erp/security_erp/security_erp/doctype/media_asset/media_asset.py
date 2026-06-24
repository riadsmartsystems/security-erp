import frappe
from frappe.model.document import Document


class MediaAsset(Document):
    def before_save(self):
        if self.riad_deleted and not self.riad_deleted_at:
            self.riad_deleted_at = frappe.utils.now_datetime()
