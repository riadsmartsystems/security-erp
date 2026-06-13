import logging
import httpx
from telegram import Update, BotCommand
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
from app.config import settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

API_URL = settings.security_api_url

BOT_TOKEN = None


async def login_as_bot():
    global BOT_TOKEN
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(f"{API_URL}/api/v1/auth/login", json={
            "username": "admin",
            "password": "admin123",
        })
        if resp.status_code == 200:
            data = resp.json()
            BOT_TOKEN = data.get("access_token")
            logger.info("Bot authenticated successfully")
        else:
            logger.error(f"Bot auth failed: {resp.status_code} {resp.text}")


async def api_get(path: str) -> dict:
    headers = {}
    if BOT_TOKEN:
        headers["Authorization"] = f"Bearer {BOT_TOKEN}"

    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.get(f"{API_URL}{path}", headers=headers)
        if resp.status_code == 401:
            await login_as_bot()
            if BOT_TOKEN:
                headers["Authorization"] = f"Bearer {BOT_TOKEN}"
                resp = await client.get(f"{API_URL}{path}", headers=headers)
        return resp.json()


async def api_post(path: str, data: dict = None) -> dict:
    headers = {}
    if BOT_TOKEN:
        headers["Authorization"] = f"Bearer {BOT_TOKEN}"

    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(f"{API_URL}{path}", headers=headers, json=data)
        if resp.status_code == 401:
            await login_as_bot()
            if BOT_TOKEN:
                headers["Authorization"] = f"Bearer {BOT_TOKEN}"
                resp = await client.post(f"{API_URL}{path}", headers=headers, json=data)
        return resp.json()


async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "Security ERP Bot\n\n"
        "Доступні команди:\n"
        "/mytickets - Мої заявки\n"
        "/visit_start {id} - Почати виїзд\n"
        "/visit_finish {id} - Завершити виїзд\n"
        "/object {code} - Картка об'єкта\n"
        "/newticket - Нова заявка\n"
        "/sla - Статус SLA\n"
        "/kpi - KPI дашборд\n"
        "/help - Допомога",
    )


async def cmd_help(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "Довідка по командах\n\n"
        "/mytickets - Список ваших відкритих заявок\n"
        "/visit_start {id} - GPS чекін та старт виїзду\n"
        "/visit_finish {id} - GPS чекаут та завершення\n"
        "/object {code} - Інформація про об'єкт\n"
        "/newticket - Створити нову заявку\n"
        "/sla - Поточний статус SLA\n"
        "/kpi - KPI дашборд",
    )


async def cmd_mytickets(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Завантажую заявки...")

    try:
        result = await api_get("/api/v1/tickets?limit=10")
        if result.get("success"):
            tickets = result.get("data", [])
            if not tickets:
                await update.message.reply_text("Немає відкритих заявок")
                return

            text = "Ваші заявки:\n\n"
            for t in tickets[:10]:
                status_emoji = {
                    "new": "🆕", "triage": "🔍", "assigned": "👤",
                    "accepted": "✅", "on_route": "🚗", "working": "🔧",
                    "waiting_parts": "⏳", "resolved": "✔️", "closed": "🔒",
                }.get(t["status"], "❓")

                text += (
                    f"{status_emoji} {t['ticket_number']}\n"
                    f"   {t['title']}\n"
                    f"   Пріоритет: {t['priority']} | Статус: {t['status']}\n\n"
                )

            await update.message.reply_text(text)
        else:
            await update.message.reply_text("Помилка отримання заявок")
    except Exception as e:
        logger.error(f"Error fetching tickets: {e}")
        await update.message.reply_text(f"Помилка: {e}")


async def cmd_visit_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("Використання: /visit_start {visit_id}")
        return

    visit_id = context.args[0]
    await update.message.reply_text(f"Старт виїзду {visit_id}...")

    try:
        result = await api_post(f"/api/v1/visits/{visit_id}/start", {
            "lat": 0.0,
            "lon": 0.0,
        })
        if result.get("success"):
            await update.message.reply_text(f"Виїзд {visit_id} розпочато!")
        else:
            await update.message.reply_text(f"Помилка: {result}")
    except Exception as e:
        await update.message.reply_text(f"Помилка: {e}")


async def cmd_visit_finish(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("Використання: /visit_finish {visit_id}")
        return

    visit_id = context.args[0]
    await update.message.reply_text(f"Завершення виїзду {visit_id}...")

    try:
        result = await api_post(f"/api/v1/visits/{visit_id}/finish", {
            "lat": 0.0,
            "lon": 0.0,
        })
        if result.get("success"):
            await update.message.reply_text(f"Виїзд {visit_id} завершено!")
        else:
            await update.message.reply_text(f"Помилка: {result}")
    except Exception as e:
        await update.message.reply_text(f"Помилка: {e}")


async def cmd_object(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("Використання: /object {code}")
        return

    obj_code = context.args[0]
    await update.message.reply_text(f"Пошук об'єкта {obj_code}...")

    try:
        result = await api_get("/api/v1/objects?limit=100")
        if result.get("success"):
            objects = result.get("data", [])
            found = None
            for obj in objects:
                if obj.get("object_code") == obj_code:
                    found = obj
                    break

            if found:
                text = (
                    f"{found['name']}\n"
                    f"Код: {found['object_code']}\n"
                    f"Тип: {found.get('object_type', '—')}\n"
                    f"Рівень сервісу: {found['service_level']}\n"
                    f"Статус: {found['status']}\n"
                    f"Адреса: {found.get('address', '—')}"
                )
                await update.message.reply_text(text)
            else:
                await update.message.reply_text(f"Об'єкт {obj_code} не знайдено")
        else:
            await update.message.reply_text("Помилка пошуку")
    except Exception as e:
        await update.message.reply_text(f"Помилка: {e}")


async def cmd_sla(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Завантажую SLA статус...")

    try:
        result = await api_get("/api/v1/tickets?limit=100")
        if result.get("success"):
            tickets = result.get("data", [])
            total = len(tickets)
            breached = sum(1 for t in tickets if t.get("sla_response_breached") or t.get("sla_resolution_breached"))
            open_tickets = sum(1 for t in tickets if t["status"] not in ["closed", "cancelled", "resolved"])
            compliance = ((total - breached) / total * 100) if total > 0 else 100

            text = (
                f"SLA Статус\n\n"
                f"Всього заявок: {total}\n"
                f"Відкритих: {open_tickets}\n"
                f"Порушено SLA: {breached}\n"
                f"Комплаєнс: {compliance:.1f}%"
            )
            await update.message.reply_text(text)
        else:
            await update.message.reply_text("Помилка отримання даних")
    except Exception as e:
        await update.message.reply_text(f"Помилка: {e}")


async def cmd_kpi(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Завантажую KPI...")

    try:
        tickets_result = await api_get("/api/v1/tickets?limit=100")
        objects_result = await api_get("/api/v1/objects?limit=100")

        tickets = tickets_result.get("data", []) if tickets_result.get("success") else []
        objects = objects_result.get("data", []) if objects_result.get("success") else []

        total_tickets = len(tickets)
        open_tickets = sum(1 for t in tickets if t["status"] not in ["closed", "cancelled", "resolved"])
        critical = sum(1 for t in tickets if t["priority"] == "critical" and t["status"] not in ["closed", "cancelled"])
        total_objects = len(objects)

        text = (
            f"KPI Дашборд\n\n"
            f"Об'єктів: {total_objects}\n"
            f"Всього заявок: {total_tickets}\n"
            f"Відкритих: {open_tickets}\n"
            f"Критичних: {critical}"
        )
        await update.message.reply_text(text)
    except Exception as e:
        await update.message.reply_text(f"Помилка: {e}")


async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Фото отримано! (Завантаження в MinIO буде реалізовано)")


# Conversation state for newticket
NEW_TICKET_STATES = {}


async def cmd_newticket(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id

    if not context.args:
        NEW_TICKET_STATES[chat_id] = {"step": "title"}
        await update.message.reply_text(
            "Створення нової заявки\n\n"
            "Введіть назву заявки (наприклад: Камера не працює на вході):"
        )
        return

    title = " ".join(context.args)
    await _create_ticket(update, title)


async def _create_ticket(update: Update, title: str):
    await update.message.reply_text("Створюю заявку...")

    try:
        result = await api_post("/api/v1/tickets", {
            "customer_id": "a0000000-0000-0000-0000-000000000001",
            "object_id": "a0000000-0000-0000-0000-000000000002",
            "ticket_type": "service_request",
            "priority": "medium",
            "title": title,
        })
        if result.get("success"):
            t = result["data"]
            await update.message.reply_text(
                f"Заявку створено!\n\n"
                f"Номер: {t['ticket_number']}\n"
                f"Назва: {t['title']}\n"
                f"Пріоритет: {t['priority']}\n"
                f"Статус: {t['status']}\n"
                f"SLA реакція до: {t.get('sla_response_due', '—')}"
            )
        else:
            await update.message.reply_text(f"Помилка: {result}")
    except Exception as e:
        await update.message.reply_text(f"Помилка: {e}")


async def handle_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    text = update.message.text

    if chat_id in NEW_TICKET_STATES:
        state = NEW_TICKET_STATES[chat_id]
        if state["step"] == "title":
            del NEW_TICKET_STATES[chat_id]
            await _create_ticket(update, text)
            return


async def post_init(application: Application):
    await login_as_bot()
    await application.bot.set_my_commands([
        BotCommand("start", "Старт"),
        BotCommand("mytickets", "Мої заявки"),
        BotCommand("newticket", "Нова заявка"),
        BotCommand("visit_start", "Почати виїзд"),
        BotCommand("visit_finish", "Завершити виїзд"),
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
    app.add_handler(CommandHandler("object", cmd_object))
    app.add_handler(CommandHandler("sla", cmd_sla))
    app.add_handler(CommandHandler("kpi", cmd_kpi))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text))

    logger.info("Starting Telegram bot...")
    app.run_polling(drop_pending_updates=False)


if __name__ == "__main__":
    main()
