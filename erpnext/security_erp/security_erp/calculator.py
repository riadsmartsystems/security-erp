"""Public calculator — deterministic scenario matching (no live AI).

@frappe.whitelist(allow_guest=True)
submit() is called by security-api /api/v2/calculator/submit.
PII (contact_*) never enters AI Request Log.
"""

import frappe


def _match_scenario(object_type, area_m2, cameras_count, archive_days):
    """Find best Security Scenario for given parameters.

    Returns (scenario_name, estimated_total) or (None, 0).
    """
    scenarios = frappe.get_all(
        "Security Scenario",
        filters={"security_type": object_type, "is_active": 1},
        fields=["name", "scenario_name"],
    )
    if not scenarios:
        return None, 0

    scenario = scenarios[0]
    items = frappe.get_all(
        "Security Scenario Item",
        filters={"parent": scenario.name},
        fields=["item_code", "item_name", "qty"],
    )

    total = 0.0
    for item in items:
        qty = item.qty or 1

        try:
            item_doc = frappe.get_doc("Item", item.item_code)
            rate = item_doc.valuation_rate or item_doc.standard_rate or 0
        except Exception:
            rate = 0

        total += qty * rate

    return scenario.name, total


@frappe.whitelist(allow_guest=True)
def submit(
    object_type,
    area_m2,
    cameras_count,
    archive_days,
    contact_name,
    contact_phone,
    contact_email="",
    source_ip="",
    captcha_passed=0,
):
    """Submit calculator form. Deterministic matching, no live AI.

    Returns dict with name, estimated_total, matched_scenario, status.
    PII (contact_*) is stored in the DocType but never sent to AI.
    """
    matched_scenario, estimated_total = _match_scenario(
        object_type, float(area_m2), int(cameras_count), int(archive_days)
    )

    status = "новий"

    doc = frappe.get_doc({
        "doctype": "Calculator Submission",
        "object_type": object_type,
        "area_m2": float(area_m2),
        "cameras_count": int(cameras_count),
        "archive_days": int(archive_days),
        "contact_name": contact_name,
        "contact_phone": contact_phone,
        "contact_email": contact_email,
        "estimated_total": estimated_total,
        "matched_scenario": matched_scenario,
        "status": status,
        "source_ip": source_ip,
        "captcha_passed": int(captcha_passed),
    })
    doc.insert(ignore_permissions=True)
    frappe.db.commit()

    return {
        "name": doc.name,
        "estimated_total": estimated_total,
        "matched_scenario": matched_scenario,
        "status": status,
    }
