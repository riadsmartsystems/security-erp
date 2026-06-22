import anthropic, json
from app.core.config import settings
from app.core.database import frappe_get


class AIService:
    def __init__(self):
        self.api_key = settings.anthropic_api_key

    async def generate_estimate(self, ta: str, sid: str) -> dict:
        catalog = await self._catalog(ta, sid)
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

    async def _catalog(self, ta: str, sid: str) -> str:
        group_map = {
            "камер": "CCTV", "cctv": "CCTV", "відеонагляд": "CCTV",
            "dvr": "CCTV", "nvr": "CCTV", "реєстратор": "CCTV",
            "домофон": "ACS", "зчитувач": "ACS", "турнікет": "ACS",
            "замок": "ACS", "контроль доступу": "ACS", "СККД": "ACS",
            "сигналіз": "ALARM", "сповіщувач": "ALARM", "пкп": "ALARM",
            "сирен": "ALARM", "охорон": "ALARM", "ajax": "ALARM",
            "комутатор": "Network", "маршрутизатор": "Network",
            "точк": "Network", "switch": "Network", "router": "Network",
            "дбж": "Power", "ups": "Power", "блок живлення": "Power",
            "інвертор": "Power", "акумулятор": "Power",
            "кронштейн": "Mounting", "бокс монтаж": "Mounting",
            "інструмент": "Tools", "тестер": "Tools",
            "кабель": "CCTV",
        }
        ta_l = ta.lower()
        group = group_map.get(ta_l.split()[0], None) if ta_l.split() else None
        if not group:
            group = next(
                (v for k, v in group_map.items() if k in ta_l),
                None
            )

        if group:
            r = await frappe_get("/api/resource/Item", params={
                "fields": '["item_code","item_name","item_group","retail_price"]',
                "filters": f'[["item_group","like","{group}%"],["retail_price","!=","0"]]',
                "limit_page_length": 80
            }, sid=sid)
        else:
            r = await frappe_get("/api/resource/Item", params={
                "fields": '["item_code","item_name","item_group","retail_price"]',
                "filters": '[["retail_price","!=","0"]]',
                "limit_page_length": 80
            }, sid=sid)
        items = r.get("data", [])
        if len(items) < 10:
            r2 = await frappe_get("/api/resource/Item", params={
                "fields": '["item_code","item_name","item_group","retail_price"]',
                "filters": '[["retail_price","!=","0"]]',
                "limit_page_length": 60
            }, sid=sid)
            seen = {i["item_code"] for i in items}
            items += [x for x in r2.get("data", []) if x["item_code"] not in seen]
        return "\n".join(
            f"{i['item_code']}|{i['item_name']}|{i.get('item_group','?')}|{i.get('retail_price','?')} грн"
            for i in items[:80]
        )


ai_service = AIService()
