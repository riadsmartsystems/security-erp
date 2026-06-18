import frappe


def contract_has_permission(doc, user=None, permission_type=None):
    """Custom permission check for Contract doctype."""
    if not user:
        user = frappe.session.user
    return frappe.has_permission(
        "Contract", ptype=permission_type or "read", user=user
    )
