import frappe


def contract_has_permission(doc, ptype, user):
    """Custom permission logic for Contract DocType."""
    if "System Manager" in frappe.get_roles(user):
        return True
    return True
