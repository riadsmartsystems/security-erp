import frappe
from frappe.model.document import Document


class Estimate(Document):
    def validate(self):
        self.calculate_totals()

    def calculate_totals(self):
        total = 0
        total_cost = 0
        for item in self.items:
            if item.qty and item.rate:
                item.amount = item.qty * item.rate
                total += item.amount
            if getattr(item, "purchase_rate", None) and item.qty:
                cost = item.purchase_rate * item.qty
                total_cost += cost
                item.profit = item.amount - cost
                item.margin_pct = (item.profit / item.amount * 100) if item.amount else 0
        self.total_amount = total
        self.total_cost = total_cost
        self.total_margin = total - total_cost
        if self.discount_percent:
            self.discount_amount = total * self.discount_percent / 100
            self.grand_total = total - self.discount_amount
        else:
            self.discount_amount = 0
            self.grand_total = total

    def on_submit(self):
        self.status = "Sent"

    @frappe.whitelist()
    def apply_template(self, template_name):
        template = frappe.get_doc("Estimate Template", template_name)
        if not template.items:
            frappe.msgprint("Template has no items")
            return

        for ti in template.items:
            self.append("items", {
                "item_code": ti.item_code,
                "item_name": ti.item_name,
                "qty": ti.qty or 1,
                "rate": ti.rate or 0,
                "description": ti.description,
            })

        self.save()
        frappe.msgprint(f"Applied template: {template_name}")

    @frappe.whitelist()
    def apply_scenario(self, scenario_name):
        scenario = frappe.get_doc("Security Scenario", scenario_name)
        if not scenario.items:
            frappe.msgprint("Scenario has no items")
            return

        for si in scenario.items:
            self.append("items", {
                "item_code": si.item_code,
                "item_name": si.item_name,
                "qty": si.qty or 1,
                "rate": 0,
            })

        self.save()
        frappe.msgprint(f"Applied scenario: {scenario_name}")

    def create_quotation(self):
        if self.status not in ("Approved", "Sent"):
            frappe.throw("Only Approved or Sent estimates can be converted to Quotation")
        qtn = frappe.get_doc({
            "doctype": "Quotation",
            "quotation_to": "Customer",
            "party_name": self.customer,
            "security_type": self.security_type,
            "object_address": self.object_address,
            "validity_days": self.validity_days,
        })
        for item in self.items:
            qtn.append("items", {
                "item_code": item.item_code,
                "item_name": item.item_name,
                "qty": item.qty,
                "rate": item.rate,
                "amount": item.amount,
            })
        qtn.insert()
        self.quotation = qtn.name
        self.status = "Converted to Quotation"
        self.save()
        return qtn.name
