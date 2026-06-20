import json
import frappe
import anthropic


@frappe.whitelist()
def generate_ai_estimate(doc_name):
    doc = frappe.get_doc("Estimate", doc_name)
    tz = doc.get("tz_text") or ""
    if not tz:
        frappe.throw("Заповніть поле «Технічне завдання» перед генерацією.")

    api_key = frappe.conf.get("anthropic_api_key")
    if not api_key:
        frappe.throw("anthropic_api_key не налаштовано в site_config.json")

    client = anthropic.Anthropic(api_key=api_key)
    prompt = (
        "Ти — інженер з безпеки. На основі ТЗ нижче склади мінімальний "
        "кошторис у форматі JSON-масиву: "
        '[{"item_name":"...", "qty":1, "rate":0}]. '
        "Тільки JSON, без пояснень.\nТЗ: " + tz
    )

    msg = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1000,
        messages=[{"role": "user", "content": prompt}],
    )

    items = json.loads(msg.content[0].text)
    for it in items:
        doc.append("items", {
            "item_name": it.get("item_name", ""),
            "qty": it.get("qty", 1),
            "rate": it.get("rate", 0),
        })

    doc.calculate_totals()
    doc.save(ignore_permissions=True)
    return "OK"
