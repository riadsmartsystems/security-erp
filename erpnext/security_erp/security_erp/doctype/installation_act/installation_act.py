import frappe
from frappe.model.document import Document


class InstallationAct(Document):
    def validate(self):
        self.validate_items()
        self.calculate_totals()

    def validate_items(self):
        for item in self.get("items", []):
            if not item.item_code:
                frappe.throw(f"Рядок {item.idx}: вкажіть позицію (item_code)")

    def calculate_totals(self):
        total = 0.0
        for item in self.get("items", []):
            item.amount = (item.qty or 1) * (item.rate or 0)
            total += item.amount
        self.total_amount = total

    def on_submit(self):
        self.status = "Pending Approval"
        self._register_equipment()

    def _register_equipment(self):
        """
        Для кожної позиції акту з serial_number — створює або оновлює
        запис Equipment зі статусом 'Installed'.
        """
        for item in self.get("items", []):
            sn = item.get("serial_number")
            if not sn:
                continue

            existing = frappe.db.get_value(
                "Equipment", {"serial_number": sn}, "name"
            )

            if existing:
                equip = frappe.get_doc("Equipment", existing)
                equip.status = "Installed"
                equip.installation_date = self.act_date or frappe.utils.today()
                equip.installation_act = self.name
                equip.save(ignore_permissions=True)
            else:
                equip = frappe.new_doc("Equipment")
                equip.equipment_name = item.item_name or item.item_code
                equip.item_code = item.item_code
                equip.serial_number = sn
                equip.status = "Installed"
                equip.customer = self.customer
                equip.installation_date = self.act_date or frappe.utils.today()
                equip.installation_act = self.name
                equip.insert(ignore_permissions=True)

        frappe.db.commit()
