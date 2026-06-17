import json
from app.core.database import frappe_get, frappe_post, frappe_put

class ScenarioService:
    async def list_scenarios(self):
        """Fetch all security scenarios from ERPNext."""
        try:
            result = await frappe_get("/api/resource/Security Scenario", params={"fields": '["name", "scenario_name", "description"]'})
            return {"success": True, "data": result.get("data", [])}
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def get_scenario_items(self, scenario_name: str):
        """Fetch items associated with a specific scenario."""
        try:
            result = await frappe_get("/api/resource/Security Scenario Item", params={
                "filters": f'[["parent", "=", "{scenario_name}"]]',
                "fields": '["item_code", "qty"]'
            })
            return {"success": True, "data": result.get("data", [])}
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def apply_scenario_to_lead(self, lead_name: str, scenario_name: str):
        """
        Add items from a scenario to a lead's AI estimate result.
        This merges scenario items with any existing AI-generated items.
        """
        try:
            # 1. Get current AI estimate from lead
            lead_data = await frappe_get(f"/api/resource/Lead/{lead_name}")
            lead = lead_data.get("data", {})
            current_result_json = lead.get("ai_estimate_result")
            
            current_result = json.loads(current_result_json) if current_result_json else {
                "items": [], "total_estimated_cost": 0, "engineer_comments": ""
            }

            # 2. Get scenario items
            items_res = await self.get_scenario_items(scenario_name)
            if not items_res["success"]:
                return items_res

            scenario_items = items_res["data"]

            # 3. Merge items
            # In a real app, we would fetch actual prices from Item DocType
            # For now, we add them to the list and mark them as 'Scenario'
            for s_item in scenario_items:
                # Try to find if item already exists in estimate
                existing = next((i for i in current_result["items"] if i["item_code"] == s_item["item_code"]), None)
                if existing:
                    existing["quantity"] += float(s_item["qty"])
                else:
                    current_result["items"].append({
                        "item_code": s_item["item_code"],
                        "quantity": float(s_item["qty"]),
                        "price": 0, # Price will be updated by a separate price-refresh call
                        "reason": "Added via scenario"
                    })

            # 4. Update lead
            await frappe_put(f"/api/resource/Lead/{lead_name}", data={
                "ai_estimate_result": json.dumps(current_result)
            })

            return {"success": True, "data": current_result}
        except Exception as e:
            return {"success": False, "error": str(e)}

scenario_service = ScenarioService()
