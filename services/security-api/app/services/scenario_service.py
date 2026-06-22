import json
from app.core.database import frappe_get, frappe_post, frappe_put


class ScenarioService:
    async def list_scenarios(self, sid: str) -> dict:
        try:
            result = await frappe_get(
                "/api/resource/Security Scenario",
                params={"fields": '["name", "scenario_name", "description"]'},
                sid=sid,
            )
            return {"success": True, "data": result.get("data", [])}
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def get_scenario_items(self, scenario_name: str, sid: str) -> dict:
        try:
            result = await frappe_get(
                "/api/resource/Security Scenario Item",
                params={
                    "filters": f'[["parent", "=", "{scenario_name}"]]',
                    "fields": '["item_code", "qty"]',
                },
                sid=sid,
            )
            return {"success": True, "data": result.get("data", [])}
        except Exception as e:
            return {"success": False, "error": str(e)}

    async def apply_scenario_to_lead(self, lead_name: str, scenario_name: str, sid: str) -> dict:
        try:
            lead_data = await frappe_get(f"/api/resource/Lead/{lead_name}", sid=sid)
            lead = lead_data.get("data", {})
            current_result_json = lead.get("ai_estimate_result")

            current_result = json.loads(current_result_json) if current_result_json else {
                "items": [], "total_estimated_cost": 0, "engineer_comments": ""
            }

            items_res = await self.get_scenario_items(scenario_name, sid)
            if not items_res["success"]:
                return items_res

            for s_item in items_res["data"]:
                existing = next(
                    (i for i in current_result["items"] if i["item_code"] == s_item["item_code"]),
                    None,
                )
                if existing:
                    existing["quantity"] += float(s_item["qty"])
                else:
                    current_result["items"].append({
                        "item_code": s_item["item_code"],
                        "quantity": float(s_item["qty"]),
                        "price": 0,
                        "reason": "Added via scenario",
                    })

            await frappe_put(
                f"/api/resource/Lead/{lead_name}",
                data={"ai_estimate_result": json.dumps(current_result)},
                sid=sid,
            )

            return {"success": True, "data": current_result}
        except Exception as e:
            return {"success": False, "error": str(e)}


scenario_service = ScenarioService()
