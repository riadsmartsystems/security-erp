import frappe
import json


@frappe.whitelist()
def generate_ai_estimate(doc_name):
    doc = frappe.get_doc("Estimate", doc_name)
    tz = doc.get("tz_text") or ""
    if not tz:
        frappe.throw("Заповніть поле «Технічне завдання» перед генерацією.")

    api_key = frappe.conf.get("anthropic_api_key") or frappe.db.get_single_value(
        "Security ERP Settings", "anthropic_api_key"
    )
    if not api_key:
        frappe.throw("API ключ Anthropic не налаштований.")

    import anthropic
    client = anthropic.Anthropic(api_key=api_key)
    prompt = (
        f"Ти — інженер з безпеки. На основі ТЗ нижче склади мінімальний "
        f"кошторис у форматі JSON-масиву: "
        f'[{{"item_name":"...", "qty":1, "rate":0, "unit":"шт"}}]. '
        f"Тільки JSON, без пояснень.\nТЗ: {tz}"
    )
    msg = client.messages.create(
        model="claude-sonnet-4-6", max_tokens=1000,
        messages=[{"role": "user", "content": prompt}]
    )
    items = json.loads(msg.content[0].text)
    for it in items:
        doc.append("items", it)
    doc.calculate_totals()
    doc.save(ignore_permissions=True)
    return "OK"
