import frappe


def get_count(*args, **kwargs):
    """Override get_count for custom filtering."""
    return frappe.client.get_count(*args, **kwargs)
