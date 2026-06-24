import frappe
from frappe.model.document import Document


class RIADDeviceSession(Document):
    def before_insert(self):
        if not self.created_at:
            self.created_at = frappe.utils.now_datetime()
        if not self.last_seen_at:
            self.last_seen_at = self.created_at

    def revoke(self, reason):
        self.revoked = 1
        self.revoke_reason = reason
        self.revoked_at = frappe.utils.now_datetime()
        self.save(ignore_permissions=True)
