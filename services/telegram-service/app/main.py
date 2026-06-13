import logging
import httpx
from telegram import Update, BotCommand, ReplyKeyboardMarkup, ReplyKeyboardRemove
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
from app.config import settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

API_URL = settings.security_api_url
BOT_TOKEN = None

# Conversation states
STATES = {}


async def login_as_bot():
    global BOT_TOKEN
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(f"{API_URL}/api/v1/auth/login", json={
            "username": "admin", "password": "admin123",
        })
        if resp.status_code == 200:
            BOT_TOKEN = resp.json().get("access_token")
            logger.info("Bot authenticated")


async def api_get(path: str) -> dict:
    headers = {"Authorization": f"Bearer {BOT_TOKEN}"} if BOT_TOKEN else {}
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(f"{API_URL}{path}", headers=headers)
        if resp.status_code == 401:
            await login_as_bot()
            headers = {"Authorization": f"Bearer {BOT_TOKEN}"} if BOT_TOKEN else {}
            resp = await client.get(f"{API_URL}{path}", headers=headers)
        return resp.json()


async def api_post(path: str, data: dict = None) -> dict:
    headers = {"Authorization": f"Bearer {BOT_TOKEN}"} if BOT_TOKEN else {}
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(f"{API_URL}{path}", headers=headers, json=data)
        if resp.status_code == 401:
            await login_as_bot()
            headers = {"Authorization": f"Bearer {BOT_TOKEN}"} if BOT_TOKEN else {}
            resp = await client.post(f"{API_URL}{path}", headers=headers, json=data)
        return resp.json()


# =============================================================================
# /start
# =============================================================================
async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "🔧 Security ERP Bot\n\n"
        "📋 /mytickets — Мої заявки\n"
        "📝 /newticket — Нова заявка\n"
        "🚗 /visit_start {id} — Почати виїзд\n"
        "🏁 /visit_finish {id} — Завершити виїзд\n"
        "📸 /photo {visit_id} — Фотозвіт\n"
        "📦 /materials {visit_id} — Матеріали\n"
        "🏢 /object {code} — Картка об'єкта\n"
        "📊 /sla — Статус SLA\n"
        "📈 /kpi — KPI дашборд\n"
        "❓ /help — Допомога",
    )


async def cmd_help(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "📋 Довідка по командах\n\n"
        "🔹 /mytickets — Список ваших відкритих заявок\n\n"
        "🔹 /newticket — Створити заявку (5 кроків):\n"
        "   Назва → Адреса → Контакт → Опис → Пріоритет\n\n"
        "🔹 /visit_start {id} — GPS чекін та старт виїзду\n"
        "🔹 /visit_finish {id} — GPS чекаут та завершення\n\n"
        "🔹 /photo {visit_id} — Завантажити фото (before/after/problem)\n"
        "🔹 /materials {visit_id} — Додати використані матеріали\n\n"
        "🔹 /object {code} — Повна картка об'єкта:\n"
        "   Обладнання, активні заявки, адреса\n\n"
        "🔹 /sla — Поточний статус SLA:\n"
        "   Комплаєнс, порушення, відкриті заявки\n\n"
        "🔹 /kpi — KPI дашборд:\n"
        "   Об'єкти, заявки, пріоритети, SLA",
    )


# =============================================================================
# /mytickets
# =============================================================================
async def cmd_mytickets(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("🔄 Завантажую заявки...")
    try:
        result = await api_get("/api/v1/tickets?limit=20")
        if not result.get("success"):
            await update.message.reply_text("❌ Помилка отримання заявок")
            return

        tickets = result.get("data", [])
        if not tickets:
            await update.message.reply_text("📭 Немає відкритих заявок")
            return

        text = f"📋 Ваші заявки ({len(tickets)}):\n\n"
        for t in tickets:
            emoji = {"new": "🆕", "triage": "🔍", "assigned": "👤", "accepted": "✅",
                     "on_route": "🚗", "working": "🔧", "waiting_parts": "⏳",
                     "resolved": "✔️", "closed": "🔒"}.get(t["status"], "❓")
            text += (
                f"{emoji} {t['ticket_number']}\n"
                f"   {t['title']}\n"
                f"   {t['priority']} | {t['status']}\n\n"
            )
        await update.message.reply_text(text)
    except Exception as e:
        await update.message.reply_text(f"❌ Помилка: {e}")


# =============================================================================
# /newticket — 5-step conversation
# =============================================================================
PRIORITY_KB = [["🟢 Low", "🟡 Medium"], ["🟠 High", "🔴 Critical"]]


async def cmd_newticket(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    STATES[chat_id] = {"cmd": "newticket", "step": "title", "data": {}}
    await update.message.reply_text(
        "📝 Створення заявки (крок 1/5)\n\n"
        "Введіть коротку назву проблеми:"
    )


async def _newticket_step(update: Update, chat_id: int, text: str) -> bool:
    state = STATES.get(chat_id)
    if not state or state.get("cmd") != "newticket":
        return False

    step = state["step"]
    data = state["data"]

    if step == "title":
        data["title"] = text
        state["step"] = "address"
        await update.message.reply_text("📍 Адреса об'єкта (крок 2/5)\n\nВведіть адресу:")
        return True

    if step == "address":
        data["address"] = text
        state["step"] = "contact"
        await update.message.reply_text("👤 Контактна особа (крок 3/5)\n\nПІБ + телефон:")
        return True

    if step == "contact":
        data["contact"] = text
        state["step"] = "description"
        await update.message.reply_text("📋 Опис проблеми (крок 4/5)\n\nДетально опишіть що сталось:")
        return True

    if step == "description":
        data["description"] = text
        state["step"] = "priority"
        await update.message.reply_text(
            "⚡ Пріоритет (крок 5/5)\n\nОберіть:",
            reply_markup=ReplyKeyboardMarkup(PRIORITY_KB, one_time_keyboard=True, resize_keyboard=True),
        )
        return True

    if step == "priority":
        pm = {"low": "low", "🟢 low": "low", "medium": "medium", "🟡 medium": "medium",
              "high": "high", "🟠 high": "high", "critical": "critical", "🔴 critical": "critical"}
        data["priority"] = pm.get(text.lower(), "medium")
        del STATES[chat_id]

        await update.message.reply_text("⏳ Створюю заявку...", reply_markup=ReplyKeyboardRemove())
        title = data["title"]
        if data.get("address"):
            title += f" | {data['address']}"
        if data.get("contact"):
            title += f" | {data['contact']}"

        result = await api_post("/api/v1/tickets", {
            "customer_id": "a0000000-0000-0000-0000-000000000001",
            "object_id": "a0000000-0000-0000-0000-000000000002",
            "ticket_type": "service_request",
            "priority": data["priority"],
            "title": title,
            "description": data.get("description", ""),
        })
        if result.get("success"):
            t = result["data"]
            await update.message.reply_text(
                f"✅ Заявку створено!\n\n"
                f"Номер: {t['ticket_number']}\n"
                f"Проблема: {data['title']}\n"
                f"Адреса: {data.get('address', '—')}\n"
                f"Контакт: {data.get('contact', '—')}\n"
                f"Пріоритет: {data['priority']}\n"
                f"Статус: {t['status']}\n"
                f"SLA до: {t.get('sla_response_due', '—')[:16]}"
            )
        else:
            await update.message.reply_text(f"❌ Помилка: {result}")
        return True

    return False


# =============================================================================
# /visit_start
# =============================================================================
async def cmd_visit_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("Використання: /visit_start {visit_id}")
        return

    visit_id = context.args[0]
    await update.message.reply_text(f"🚗 Старт виїзду {visit_id}...")
    try:
        result = await api_post(f"/api/v1/visits/{visit_id}/start", {"lat": 0.0, "lon": 0.0})
        if result.get("success"):
            await update.message.reply_text(f"✅ Виїзд {visit_id} розпочато!\nGPS чекін зафіксовано.")
        else:
            await update.message.reply_text(f"❌ Помилка: {result}")
    except Exception as e:
        await update.message.reply_text(f"❌ Помилка: {e}")


# =============================================================================
# /visit_finish
# =============================================================================
async def cmd_visit_finish(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("Використання: /visit_finish {visit_id}")
        return

    visit_id = context.args[0]
    await update.message.reply_text(f"🏁 Завершення виїзду {visit_id}...")
    try:
        result = await api_post(f"/api/v1/visits/{visit_id}/finish", {"lat": 0.0, "lon": 0.0})
        if result.get("success"):
            v = result["data"]
            mins = v.get("work_minutes", "—")
            await update.message.reply_text(f"✅ Виїзд {visit_id} завершено!\nЧас роботи: {mins} хв")
        else:
            await update.message.reply_text(f"❌ Помилка: {result}")
    except Exception as e:
        await update.message.reply_text(f"❌ Помилка: {e}")


# =============================================================================
# /photo
# =============================================================================
async def cmd_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text(
            "📸 Фотозвіт\n\n"
            "Використання: /photo {visit_id}\n"
            "Після цього надішліть фото з підписом (before/after/problem)"
        )
        return

    visit_id = context.args[0]
    chat_id = update.effective_chat.id
    STATES[chat_id] = {"cmd": "photo", "visit_id": visit_id}
    await update.message.reply_text(
        f"📸 Надішліть фото для виїзду {visit_id}\n\n"
        "Підпишіть фото одним з:\n"
        "• before — до роботи\n"
        "• after — після роботи\n"
        "• problem — проблема\n"
        "• equipment — обладнання"
    )


async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    state = STATES.get(chat_id, {})
    visit_id = state.get("visit_id", "unknown")
    caption = update.message.caption or "after"

    await update.message.reply_text(
        f"📸 Фото отримано!\n\n"
        f"Виїзд: {visit_id}\n"
        f"Тип: {caption}\n\n"
        f"(Завантаження в MinIO буде реалізовано)"
    )
    if chat_id in STATES:
        del STATES[chat_id]


# =============================================================================
# /materials
# =============================================================================
async def cmd_materials(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text(
            "📦 Матеріали\n\n"
            "Використання: /materials {visit_id}\n"
            "Після цього введіть матеріали у форматі:\n"
            "Код | Назва | Кількість | Серійний\n\n"
            "Приклад:\n"
            "UTP-CAT6 | Кабель UTP Cat6 | 50м | —\n"
            "HIK-2043 | Камера Hikvision | 2шт | DS2CD2043-001"
        )
        return

    visit_id = context.args[0]
    chat_id = update.effective_chat.id
    STATES[chat_id] = {"cmd": "materials", "visit_id": visit_id}
    await update.message.reply_text(
        f"📦 Додайте матеріали для виїзду {visit_id}\n\n"
        "Введіть кожен матеріал з нового рядка:\n"
        "Код | Назва | Кількість\n\n"
        "Напишіть /done коли закінчите"
    )


async def _materials_step(update: Update, chat_id: int, text: str) -> bool:
    state = STATES.get(chat_id)
    if not state or state.get("cmd") != "materials":
        return False

    if text.lower() == "/done":
        del STATES[chat_id]
        await update.message.reply_text("✅ Матеріали збережено!")
        return True

    visit_id = state["visit_id"]
    parts = [p.strip() for p in text.split("|")]
    if len(parts) < 3:
        await update.message.reply_text("❌ Формат: Код | Назва | Кількість")
        return True

    result = await api_post(f"/api/v1/visits/{visit_id}/materials", {
        "item_code": parts[0],
        "item_name": parts[1],
        "quantity": float(parts[2]) if parts[2].replace(".", "").isdigit() else 1,
        "serial_number": parts[3] if len(parts) > 3 else None,
    })
    if result.get("success"):
        await update.message.reply_text(f"✅ Додано: {parts[1]} ({parts[2]})")
    else:
        await update.message.reply_text(f"❌ Помилка: {result}")
    return True


# =============================================================================
# /object — detailed object card
# =============================================================================
async def cmd_object(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("Використання: /object {code}\nПриклад: /object OBJ-000001")
        return

    obj_code = context.args[0]
    await update.message.reply_text(f"🔍 Пошук {obj_code}...")
    try:
        result = await api_get("/api/v1/objects?limit=100")
        if not result.get("success"):
            await update.message.reply_text("❌ Помилка пошуку")
            return

        found = None
        for obj in result.get("data", []):
            if obj.get("object_code") == obj_code:
                found = obj
                break

        if not found:
            await update.message.reply_text(f"❌ Об'єкт {obj_code} не знайдено")
            return

        # Get equipment
        equip_result = await api_get(f"/api/v1/equipment?limit=50")
        equipment = [e for e in equip_result.get("data", []) if str(e.get("object_id")) == str(found["id"])]

        # Get tickets for this object
        tickets_result = await api_get("/api/v1/tickets?limit=50")
        tickets = [t for t in tickets_result.get("data", []) if str(t.get("object_id")) == str(found["id"])]
        open_tickets = [t for t in tickets if t["status"] not in ["closed", "cancelled"]]

        text = (
            f"🏢 {found['name']}\n"
            f"Код: {found['object_code']}\n"
            f"Тип: {found.get('object_type', '—')}\n"
            f"Адреса: {found.get('address', '—')}\n"
            f"Сервіс: {found['service_level']}\n"
            f"Статус: {found['status']}\n\n"
            f"📦 Обладнання: {len(equipment)} од.\n"
        )
        for eq in equipment[:5]:
            text += f"  • {eq['model']} ({eq.get('serial_number', '—')}) — {eq['status']}\n"

        if open_tickets:
            text += f"\n📋 Активні заявки: {len(open_tickets)}\n"
            for t in open_tickets[:3]:
                text += f"  • {t['ticket_number']}: {t['title'][:30]} ({t['status']})\n"

        await update.message.reply_text(text)
    except Exception as e:
        await update.message.reply_text(f"❌ Помилка: {e}")


# =============================================================================
# /sla — detailed SLA stats
# =============================================================================
async def cmd_sla(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("📊 Завантажую SLA...")
    try:
        result = await api_get("/api/v1/tickets?limit=100")
        if not result.get("success"):
            await update.message.reply_text("❌ Помилка")
            return

        tickets = result.get("data", [])
        total = len(tickets)
        if total == 0:
            await update.message.reply_text("📊 Немає заявок для аналізу")
            return

        open_t = [t for t in tickets if t["status"] not in ["closed", "cancelled", "resolved"]]
        response_breached = sum(1 for t in tickets if t.get("sla_response_breached"))
        resolution_breached = sum(1 for t in tickets if t.get("sla_resolution_breached"))
        total_breached = sum(1 for t in tickets if t.get("sla_response_breached") or t.get("sla_resolution_breached"))
        compliance = ((total - total_breached) / total * 100)

        by_priority = {}
        for t in tickets:
            p = t["priority"]
            by_priority[p] = by_priority.get(p, 0) + 1

        text = (
            f"📊 SLA Статус\n\n"
            f"Всього заявок: {total}\n"
            f"Відкритих: {len(open_t)}\n"
            f"Закритих: {total - len(open_t)}\n\n"
            f"⚠️ Порушення SLA:\n"
            f"  Реакція: {response_breached}\n"
            f"  Вирішення: {resolution_breached}\n"
            f"  Всього: {total_breached}\n\n"
            f"✅ Комплаєнс: {compliance:.1f}%\n\n"
            f"📋 По пріоритетах:\n"
        )
        for p, count in sorted(by_priority.items()):
            text += f"  {p}: {count}\n"

        await update.message.reply_text(text)
    except Exception as e:
        await update.message.reply_text(f"❌ Помилка: {e}")


# =============================================================================
# /kpi — dashboard
# =============================================================================
async def cmd_kpi(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("📈 Завантажую KPI...")
    try:
        tickets_r = await api_get("/api/v1/tickets?limit=100")
        objects_r = await api_get("/api/v1/objects?limit=100")
        visits_r = await api_get("/api/v1/visits?limit=100")

        tickets = tickets_r.get("data", []) if tickets_r.get("success") else []
        objects = objects_r.get("data", []) if objects_r.get("success") else []
        visits = visits_r.get("data", []) if visits_r.get("success") else []

        total = len(tickets)
        open_t = sum(1 for t in tickets if t["status"] not in ["closed", "cancelled", "resolved"])
        critical = sum(1 for t in tickets if t["priority"] == "critical" and t["status"] not in ["closed", "cancelled"])
        high = sum(1 for t in tickets if t["priority"] == "high" and t["status"] not in ["closed", "cancelled"])
        breached = sum(1 for t in tickets if t.get("sla_response_breached") or t.get("sla_resolution_breached"))
        compliance = ((total - breached) / total * 100) if total > 0 else 100
        completed_visits = sum(1 for v in visits if v.get("status") == "completed")

        text = (
            f"📈 KPI Дашборд\n\n"
            f"🏢 Об'єктів: {len(objects)}\n"
            f"📋 Всього заявок: {total}\n"
            f"📂 Відкритих: {open_t}\n"
            f"🔴 Критичних: {critical}\n"
            f"🟠 Високих: {high}\n\n"
            f"🚗 Виїздів: {len(visits)}\n"
            f"✅ Завершених: {completed_visits}\n\n"
            f"📊 SLA комплаєнс: {compliance:.1f}%\n"
            f"⚠️ Порушень: {breached}"
        )
        await update.message.reply_text(text)
    except Exception as e:
        await update.message.reply_text(f"❌ Помилка: {e}")


# =============================================================================
# Text message handler (conversations)
# =============================================================================
async def handle_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    text = update.message.text

    if chat_id not in STATES:
        return

    state = STATES[chat_id]
    cmd = state.get("cmd")

    if cmd == "newticket":
        await _newticket_step(update, chat_id, text)
    elif cmd == "materials":
        await _materials_step(update, chat_id, text)


# =============================================================================
# Bot init
# =============================================================================
async def post_init(application: Application):
    await login_as_bot()
    await application.bot.set_my_commands([
        BotCommand("start", "Старт"),
        BotCommand("mytickets", "Мої заявки"),
        BotCommand("newticket", "Нова заявка"),
        BotCommand("visit_start", "Почати виїзд"),
        BotCommand("visit_finish", "Завершити виїзд"),
        BotCommand("photo", "Фотозвіт"),
        BotCommand("materials", "Матеріали"),
        BotCommand("object", "Картка об'єкта"),
        BotCommand("sla", "Статус SLA"),
        BotCommand("kpi", "KPI дашборд"),
        BotCommand("help", "Допомога"),
    ])
    logger.info("Bot commands registered")


def main():
    if not settings.telegram_bot_token:
        logger.error("TELEGRAM_BOT_TOKEN not set!")
        return

    app = Application.builder().token(settings.telegram_bot_token).post_init(post_init).build()

    app.add_handler(CommandHandler("start", cmd_start))
    app.add_handler(CommandHandler("help", cmd_help))
    app.add_handler(CommandHandler("mytickets", cmd_mytickets))
    app.add_handler(CommandHandler("newticket", cmd_newticket))
    app.add_handler(CommandHandler("visit_start", cmd_visit_start))
    app.add_handler(CommandHandler("visit_finish", cmd_visit_finish))
    app.add_handler(CommandHandler("photo", cmd_photo))
    app.add_handler(CommandHandler("materials", cmd_materials))
    app.add_handler(CommandHandler("object", cmd_object))
    app.add_handler(CommandHandler("sla", cmd_sla))
    app.add_handler(CommandHandler("kpi", cmd_kpi))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text))

    logger.info("Starting Telegram bot...")
    app.run_polling(drop_pending_updates=False)


if __name__ == "__main__":
    main()
