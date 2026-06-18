import frappe
from frappe.model.document import Document


class Estimate(Document):
    def validate(self):
        self.calculate_totals()

    def calculate_totals(self):
        total = 0.0
        for item in self.get("items", []):
            item.amount = (item.qty or 1) * (item.rate or 0)
            total += item.amount
        self.total_amount = total

    @frappe.whitelist()
    def create_quotation(self):
        """Створює ERPNext Quotation з поточного Estimate."""
        qtn = frappe.new_doc("Quotation")
        qtn.quotation_to = "Customer"
        qtn.party_name = self.customer
        qtn.transaction_date = frappe.utils.today()
        qtn.valid_till = frappe.utils.add_days(frappe.utils.today(), 30)

        for item in self.get("items", []):
            qtn.append("items", {
                "item_code": item.item_code,
                "item_name": item.item_name,
                "description": item.get("description"),
                "qty": item.qty or 1,
                "rate": item.rate or 0,
                "amount": item.amount or 0,
            })

        qtn.insert(ignore_permissions=True)

        frappe.db.set_value("Estimate", self.name, "quotation", qtn.name)

        return qtn.name

    @frappe.whitelist()
    def apply_template(self, template_name):
        """Переносить позиції з EstimateTemplate до поточного Estimate."""
        template = frappe.get_doc("Estimate Template", template_name)
        for t_item in template.get("items", []):
            self.append("items", {
                "item_code": t_item.item_code,
                "item_name": t_item.item_name,
                "description": t_item.get("description"),
                "qty": t_item.qty or 1,
                "rate": t_item.rate or 0,
                "unit": t_item.get("unit"),
            })
        self.calculate_totals()
        self.save()
        return True

    @frappe.whitelist()
    def apply_scenario(self, scenario_name):
        """Додає позиції з SecurityScenario до поточного Estimate."""
        scenario = frappe.get_doc("Security Scenario", scenario_name)
        for s_item in scenario.get("items", []):
            self.append("items", {
                "item_code": s_item.item_code,
                "item_name": s_item.item_name,
                "description": s_item.get("description"),
                "qty": s_item.qty or 1,
                "rate": s_item.rate or 0,
                "unit": s_item.get("unit"),
            })
        self.calculate_totals()
        self.save()
        return True
