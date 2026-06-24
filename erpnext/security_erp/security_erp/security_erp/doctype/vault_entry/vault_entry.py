import frappe
from frappe.model.document import Document


class VaultEntry(Document):
    def before_save(self):
        from security_erp.vault._hooks import encrypt_doc_fields
        encrypt_doc_fields(self)
