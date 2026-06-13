import frappe


def after_install():
    """Runs after app installation. Sets up roles, workspaces, etc."""
    create_roles()
    frappe.db.commit()


def create_roles():
    """Create Security ERP specific roles if they don't exist."""
    roles = [
        "Service Manager",
        "Engineer",
        "Warehouse Manager",
    ]
    for role in roles:
        if not frappe.db.exists("Role", role):
            frappe.get_doc(
                {"doctype": "Role", "role_name": role, "desk_access": 1}
            ).insert(ignore_permissions=True)
