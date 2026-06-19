import frappe
from frappe.contacts.doctype.address.address import Address


class CustomAddress(Address):
    """Monkey-patch for ERPNext Address bug.

    erpnext/accounts/custom/address.py accesses self.is_your_company_address
    which may not exist on the Address doctype, causing AttributeError.
    """

    def validate(self):
        # Ensure the attribute exists before ERPNext code touches it
        if not hasattr(self, "is_your_company_address"):
            self.is_your_company_address = 0
        super().validate()
