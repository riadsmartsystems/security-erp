import frappe


def contract_has_permission(doc, user=None, permission_type=None):
    """
    Custom permission check for Contract doctype.
    Returns True to allow access if user has standard 'read' permission on Contract.
    """
    if not user:
        user = frappe.session.user

    if frappe.has_permission("Contract", ptype=permission_type or "read", doc=doc, user=user):
        return True

    return False
