import anthropic, json
from app.core.config import settings
from app.core.database import frappe_get

class AIService:
    def __init__(self):
        self.api_key = settings.anthropic_api_key

    async def generate_estimate(self, ta: str) -> dict:
        catalog = await self._catalog(ta)
        client = anthropic.Anthropic(api_key=self.api_key)
        system_prompt = (
            "Ти - досвідчений проектувальник систем безпеки в Україні.\n"
            "На основі ТЗ і каталогу товарів створи кошторис.\n"
            "Відповідай ТІЛЬКИ валідним JSON без markdown.\n"
            'Формат: {"items":[{"item_code":"...","item_name":"...","qty":1,"rate":0,"reason":"коротко"}],'
            '"missing_items":["чого немає"],"engineer_notes":"коментар"}'
        )
        msg = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=2000,
            system=system_prompt,
            messages=[{"role": "user", "content": f"ТЗ: {ta}\n\nКаталог (код|назва|ціна грн):\n{catalog}"}]
        )
        return json.loads(msg.content[0].text)

    async def _catalog(self, ta: str) -> str:
        kw_map = {
            "камер": "%камер%", "cctv": "%камер%", "відеонагляд": "%камер%",
            "dvr": "%реєстратор%", "nvr": "%реєстратор%", "poe": "%PoE%",
            "ajax": "%Ajax%", "сигналіз": "%сигналіз%", "кабель": "%кабел%"
        }
        ta_l = ta.lower()
        filt = next((v for k, v in kw_map.items() if k in ta_l), "%камер%")
        r = await frappe_get("/api/resource/Item", params={
            "fields": '["item_code","item_name","retail_price"]',
            "filters": f'[["item_name","like","{filt}"],["retail_price","!=","0"]]',
            "limit_page_length": 80
        })
        items = r.get("data", [])
        if len(items) < 10:
            r2 = await frappe_get("/api/resource/Item", params={
                "fields": '["item_code","item_name","retail_price"]',
                "filters": '[["retail_price","!=","0"]]',
                "limit_page_length": 60
            })
            seen = {i["item_code"] for i in items}
            items += [x for x in r2.get("data", []) if x["item_code"] not in seen]
        return "\n".join(
            f"{i['item_code']}|{i['item_name']}|{i.get('retail_price','?')} грн"
            for i in items[:80]
        )

ai_service = AIService()
