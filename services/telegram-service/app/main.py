import logging
import json
import httpx
import nats
from telegram import Update, BotCommand, ReplyKeyboardMarkup, ReplyKeyboardRemove, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import Application, CommandHandler, MessageHandler, CallbackQueryHandler, filters, ContextTypes
from app.config import settings

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

API_URL = settings.security_api_url
BOT_TOKEN = None
NATS_CLIENT = None

STATES = {}


async def login_as_bot():
    global BOT_TOKEN
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(f"{API_URL}/api/v1/auth/login", json={
            "username": "joker@riad.fun", "password": "jokerLA23",
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


N8N_URL = "http://n8n:5678"


async def api_post_n8n(path: str, data: dict = None) -> dict:
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(f"{N8N_URL}{path}", json=data)
        return resp.json() if resp.status_code == 200 else {"error": resp.status_code}


MANAGER_CHAT_ID = "291657218"


async def send_notification(chat_id: int, text: str):
    """Send notification via Telegram Bot API"""
    bot_token = settings.telegram_bot_token
    async with httpx.AsyncClient(timeout=10.0) as client:
        await client.post(
            f"https://api.telegram.org/bot{bot_token}/sendMessage",
            json={"chat_id": str(chat_id), "text": text}
        )


def _parse_csv(raw: str) -> list[str]:
    return [item.strip() for item in (raw or "").split(",") if item.strip()]


def _default_notification_targets() -> tuple[list[str], list[str]]:
    telegram_ids = _parse_csv(settings.notification_telegram_chat_ids)
    viber_ids = _parse_csv(settings.notification_viber_user_ids)
    return telegram_ids, viber_ids


async def send_telegram_message(application: Application, chat_id: str, message: str) -> bool:
    try:
        await application.bot.send_message(chat_id=chat_id, text=message)
        return True
    except Exception as e:
        logger.error(f"Failed to send Telegram message to {chat_id}: {e}")
        return False


async def send_viber_message(user_id: str, message: str) -> bool:
    if not settings.viber_bot_token:
        logger.warning("Skipping Viber delivery: VIBER_BOT_TOKEN is empty")
        return False

    payload = {
        "receiver": user_id,
        "type": "text",
        "text": message,
        "min_api_version": 7,
    }
    headers = {
        "X-Viber-Auth-Token": settings.viber_bot_token,
        "Content-Type": "application/json",
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post("https://chatapi.viber.com/pa/send_message", headers=headers, json=payload)
        if resp.status_code != 200:
            logger.error(f"Viber send failed: {resp.status_code} {resp.text[:200]}")
            return False
        return True
    except Exception as e:
        logger.error(f"Failed to send Viber message to {user_id}: {e}")
        return False


async def process_notification_event(application: Application, payload: dict):
    message = payload.get("message") or payload.get("text")
    if not message:
        logger.warning("Notification dropped: message/text is missing")
        return

    channels = payload.get("channels")
    if isinstance(channels, str):
        channels = [channels]
    if not channels:
        channels = [payload.get("channel")] if payload.get("channel") else ["telegram"]

    default_tg_ids, default_viber_ids = _default_notification_targets()

    telegram_ids = payload.get("telegram_chat_ids") or []
    if payload.get("telegram_chat_id"):
        telegram_ids.append(payload["telegram_chat_id"])
    if not telegram_ids:
        telegram_ids = default_tg_ids

    viber_ids = payload.get("viber_user_ids") or []
    if payload.get("viber_user_id"):
        viber_ids.append(payload["viber_user_id"])
    if not viber_ids:
        viber_ids = default_viber_ids

    if "telegram" in channels:
        for chat_id in telegram_ids:
            await send_telegram_message(application, str(chat_id), message)

    if "viber" in channels:
        for user_id in viber_ids:
            await send_viber_message(str(user_id), message)


def _build_sla_message(payload: dict) -> str:
    ticket = payload.get("ticket_number", "unknown")
    timer_type = payload.get("type", "unknown")
    priority = payload.get("priority", "unknown")
    return (
        "SLA breach detected\n"
        f"Ticket: {ticket}\n"
        f"Type: {timer_type}\n"
        f"Priority: {priority}"
    )


async def start_nats_subscribers(application: Application):
    global NATS_CLIENT
    try:
        NATS_CLIENT = await nats.connect(settings.nats_url)
        logger.info(f"Connected to NATS at {settings.nats_url}")

        async def notifications_cb(msg):
            try:
                payload = json.loads(msg.data.decode())
                await process_notification_event(application, payload)
            except Exception as e:
                logger.error(f"notifications.send processing error: {e}")

        async def sla_breach_cb(msg):
            try:
                payload = json.loads(msg.data.decode())
                event_payload = {
                    "channels": ["telegram", "viber"],
                    "message": _build_sla_message(payload),
                }
                await process_notification_event(application, event_payload)
            except Exception as e:
                logger.error(f"fsm.sla.breached processing error: {e}")

        await NATS_CLIENT.subscribe("notifications.send", cb=notifications_cb)
        await NATS_CLIENT.subscribe("fsm.sla.breached", cb=sla_breach_cb)
        logger.info("Subscribed to NATS subjects: notifications.send, fsm.sla.breached")
    except Exception as e:
        logger.error(f"NATS subscriber startup failed: {e}")


async def stop_nats_subscribers():
    global NATS_CLIENT
    if NATS_CLIENT is None:
        return
    try:
        await NATS_CLIENT.drain()
    except Exception as e:
        logger.error(f"NATS drain failed: {e}")
    try:
        await NATS_CLIENT.close()
    except Exception as e:
        logger.error(f"NATS close failed: {e}")
    NATS_CLIENT = None


def status_emoji(status: str) -> str:
    return {"new": "🆕", "triage": "🔍", "assigned": "👤", "accepted": "✅",
            "on_route": "🚗", "working": "🔧", "waiting_parts": "⏳",
            "resolved": "✔️", "closed": "🔒", "cancelled": "❌",
            "planned": "📅", "arrived": "📍", "completed": "✅"}.get(status, "❓")


# =============================================================================
# /start
# =============================================================================
async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    logger.info(f"Chat ID: {chat_id} from {update.effective_user.first_name}")
    keyboard = [
        ["📋 Мої заявки", "📝 Нова заявка"],
        ["📊 SLA", "📈 KPI"],
    ]
    await update.message.reply_text(
        "🔧 Security ERP Bot\n\n"
        "Оберіть дію або використайте команду:",
        reply_markup=ReplyKeyboardMarkup(keyboard, resize_keyboard=True),
    )


async def cmd_help(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "📋 Як користуватись ботом\n\n"
        "📋 Мої заявки — показує ваші заявки. Натисніть на заявку щоб побачити деталі та дії.\n\n"
        "📝 Нова заявка — створення заявки покроково (назва, адреса, контакт, опис, пріоритет).\n\n"
        "📸 Фото / 📦 Матеріали — прив'язуються до виїзду. Спочатку оберіть заявку, потім виїзд.\n\n"
        "📊 SLA — статус виконання SLA по всіх заявках.\n\n"
        "📈 KPI — загальний дашборд.",
    )


# =============================================================================
# /mytickets — з кнопками
# =============================================================================
async def cmd_mytickets(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("🔄 Завантажую...")
    try:
        result = await api_get("/api/v1/tickets?limit=20")
        if not result.get("success"):
            await update.message.reply_text("❌ Помилка отримання заявок")
            return

        tickets = result.get("data", [])
        if not tickets:
            await update.message.reply_text("📭 Немає заявок")
            return

        for t in tickets:
            emoji = status_emoji(t["status"])
            text = (
                f"{emoji} {t['ticket_number']}\n"
                f"{t['title']}\n"
                f"Пріоритет: {t['priority']} | Статус: {t['status']}"
            )
            keyboard = [[
                InlineKeyboardButton("📋 Деталі", callback_data=f"ticket_{t['id']}"),
                InlineKeyboardButton("🚗 Створити виїзд", callback_data=f"newvisit_{t['id']}"),
            ]]
            await update.message.reply_text(text, reply_markup=InlineKeyboardMarkup(keyboard))

    except Exception as e:
        await update.message.reply_text(f"❌ Помилка: {e}")


# =============================================================================
# Callback: деталі заявки
# =============================================================================
async def callback_ticket(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    logger.info(f"callback_ticket called: data={query.data}")

    ticket_id = query.data.replace("ticket_", "")
    await query.edit_message_text("🔄 Завантажую деталі...")

    try:
        result = await api_get(f"/api/v1/tickets/{ticket_id}")
        if not result.get("success"):
            await query.edit_message_text("❌ Помилка")
            return

        t = result["data"]

        # Get visits for this ticket
        visits_r = await api_get(f"/api/v1/visits?ticket_id={ticket_id}")
        visits = visits_r.get("data", []) if visits_r.get("success") else []

        text = (
            f"📋 {t['ticket_number']}\n\n"
            f"Проблема: {t['title']}\n"
            f"Пріоритет: {t['priority']}\n"
            f"Статус: {t['status']}\n"
            f"SLA реакція до: {str(t.get('sla_response_due', '—'))[:16]}\n"
            f"SLA вирішення до: {str(t.get('sla_resolution_due', '—'))[:16]}\n"
        )

        if visits:
            text += f"\n🚗 Виїзди ({len(visits)}):\n"
            for v in visits:
                text += f"  {status_emoji(v['status'])} {v['visit_number']} — {v['status']}\n"

        buttons = []
        if t["status"] in ["new", "triage", "assigned"]:
            buttons.append([InlineKeyboardButton("✅ Прийняти", callback_data=f"accept_{ticket_id}")])

        if visits:
            for v in visits:
                if v["status"] in ["planned", "accepted"]:
                    buttons.append([InlineKeyboardButton(
                        f"🚗 Старт виїзду {v['visit_number']}",
                        callback_data=f"vstart_{v['id']}"
                    )])
                elif v["status"] in ["on_route", "arrived", "working"]:
                    buttons.append([
                        InlineKeyboardButton(f"📸 Фото {v['visit_number']}", callback_data=f"photo_{v['id']}"),
                        InlineKeyboardButton(f"📦 Матеріали", callback_data=f"mat_{v['id']}"),
                    ])
                    buttons.append([InlineKeyboardButton(
                        f"🏁 Завершити {v['visit_number']}",
                        callback_data=f"vfinish_{v['id']}"
                    )])

        buttons.append([InlineKeyboardButton("➕ Створити виїзд", callback_data=f"newvisit_{ticket_id}")])

        await query.edit_message_text(text, reply_markup=InlineKeyboardMarkup(buttons))

    except Exception as e:
        await query.edit_message_text(f"❌ Помилка: {e}")


# =============================================================================
# Callback: прийняти заявку
# =============================================================================
async def callback_accept(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    ticket_id = query.data.replace("accept_", "")
    try:
        result = await api_post(f"/api/v1/tickets/{ticket_id}/status", {"status": "accepted"})
        if result.get("success"):
            await query.edit_message_text("✅ Заявку прийнято!")
        else:
            await query.answer("Помилка", show_alert=True)
    except Exception as e:
        await query.answer(f"Помилка: {e}", show_alert=True)


# =============================================================================
# Callback: старт виїзду
# =============================================================================
async def callback_visit_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    visit_id = query.data.replace("vstart_", "")
    try:
        result = await api_post(f"/api/v1/visits/{visit_id}/start", {"lat": 0.0, "lon": 0.0})
        if result.get("success"):
            keyboard = [
                [InlineKeyboardButton("📸 Фото", callback_data=f"photo_{visit_id}"),
                 InlineKeyboardButton("📦 Матеріали", callback_data=f"mat_{visit_id}")],
                [InlineKeyboardButton("🏁 Завершити виїзд", callback_data=f"vfinish_{visit_id}")],
            ]
            await query.edit_message_text(
                f"🚗 Виїзд {visit_id} розпочато!\n\n"
                "Оберіть дію:",
                reply_markup=InlineKeyboardMarkup(keyboard),
            )
        else:
            await query.answer("Помилка", show_alert=True)
    except Exception as e:
        await query.answer(f"Помилка: {e}", show_alert=True)


# =============================================================================
# Callback: завершити виїзд
# =============================================================================
async def callback_visit_finish(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    visit_id = query.data.replace("vfinish_", "")
    try:
        result = await api_post(f"/api/v1/visits/{visit_id}/finish", {"lat": 0.0, "lon": 0.0})
        if result.get("success"):
            await query.edit_message_text(f"✅ Виїзд завершено!")
        else:
            await query.answer("Помилка", show_alert=True)
    except Exception as e:
        await query.answer(f"Помилка: {e}", show_alert=True)


# =============================================================================
# Callback: створити виїзд
# =============================================================================
async def callback_newvisit(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    ticket_id = query.data.replace("newvisit_", "")
    try:
        result = await api_post("/api/v1/visits", {
            "ticket_id": ticket_id,
            "engineer_id": "a0000000-0000-0000-0000-000000000001",
        })
        if result.get("success"):
            v = result["data"]
            keyboard = [
                [InlineKeyboardButton("🚗 Старт", callback_data=f"vstart_{v['id']}")],
            ]
            await query.edit_message_text(
                f"✅ Виїзд створено: {v['visit_number']}\n\n"
                "Натисніть Старт коли будете на об'єкті:",
                reply_markup=InlineKeyboardMarkup(keyboard),
            )
        else:
            await query.answer("Помилка", show_alert=True)
    except Exception as e:
        await query.answer(f"Помилка: {e}", show_alert=True)


# =============================================================================
# Callback: фото — запитуємо тип
# =============================================================================
async def callback_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    visit_id = query.data.replace("photo_", "")
    keyboard = [
        [InlineKeyboardButton("📸 До роботи", callback_data=f"phototype_{visit_id}_before"),
         InlineKeyboardButton("📸 Після роботи", callback_data=f"phototype_{visit_id}_after")],
        [InlineKeyboardButton("⚠️ Проблема", callback_data=f"phototype_{visit_id}_problem"),
         InlineKeyboardButton("🔧 Обладнання", callback_data=f"phototype_{visit_id}_equipment")],
    ]
    await query.edit_message_text(
        "📸 Оберіть тип фото:",
        reply_markup=InlineKeyboardMarkup(keyboard),
    )


async def callback_phototype(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    parts = query.data.replace("phototype_", "").split("_")
    visit_id = parts[0]
    photo_type = parts[1]

    chat_id = query.message.chat_id
    STATES[chat_id] = {"cmd": "photo", "visit_id": visit_id, "photo_type": photo_type}

    await query.edit_message_text(
        f"📸 Надішліть фото ({photo_type}) для виїзду {visit_id}\n\n"
        "Просто надішліть фото в чат:"
    )


async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    state = STATES.get(chat_id, {})

    if state.get("cmd") == "photo":
        visit_id = state.get("visit_id", "?")
        photo_type = state.get("photo_type", "after")

        try:
            photo = update.message.photo[-1]
            file = await context.bot.get_file(photo.file_id)
            photo_bytes = await file.download_as_bytearray()

            import io
            files = {"file": ("photo.jpg", io.BytesIO(photo_bytes), "image/jpeg")}
            data = {"photo_type": photo_type, "caption": f"Telegram photo ({photo_type})"}

            async with httpx.AsyncClient(timeout=30.0) as client:
                resp = await client.post(
                    f"{API_URL}/api/v1/visits/{visit_id}/photos",
                    headers={"Authorization": f"Bearer {BOT_TOKEN}"},
                    data=data,
                    files=files,
                )

            if resp.status_code == 200:
                result = resp.json()
                await update.message.reply_text(
                    f"✅ Фото збережено!\n\n"
                    f"Виїзд: {visit_id}\n"
                    f"Тип: {photo_type}\n"
                    f"File: {result.get('data', {}).get('file_path', 'N/A')}"
                )
            else:
                await update.message.reply_text(
                    f"⚠️ Фото прийнято, але не збережено на сервері\n"
                    f"Статус: {resp.status_code}"
                )
        except Exception as e:
            logger.error(f"Photo upload error: {e}")
            await update.message.reply_text(f"❌ Помилка збереження фото: {str(e)}")

        del STATES[chat_id]
    else:
        await update.message.reply_text("📸 Фото отримано. Щоб додати до виїзду — оберіть заявку через /mytickets")


# =============================================================================
# Callback: матеріали — простий вибір
# =============================================================================
async def callback_materials(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    visit_id = query.data.replace("mat_", "")
    chat_id = query.message.chat_id

    # Завантажуємо матеріали зі складу
    try:
        items_r = await api_get("/api/v1/items?limit=20")
        items = items_r.get("data", []) if items_r.get("success") else []
    except:
        items = []

    if items:
        keyboard = []
        for item in items[:10]:
            keyboard.append([InlineKeyboardButton(
                f"{item.get('item_name', item.get('item_code', '?'))}",
                callback_data=f"addmat_{visit_id}_{item.get('item_code', 'unknown')}"
            )])
        keyboard.append([InlineKeyboardButton("✏️ Ввести вручну", callback_data=f"matmanual_{visit_id}")])
        await query.edit_message_text(
            f"📦 Оберіть матеріал для виїзду {visit_id}:",
            reply_markup=InlineKeyboardMarkup(keyboard),
        )
    else:
        STATES[chat_id] = {"cmd": "materials", "visit_id": visit_id, "items": []}
        await query.edit_message_text(
            f"📦 Додайте матеріали для виїзду {visit_id}\n\n"
            "Введіть у форматі:\n"
            "Назва | Кількість\n\n"
            "Наприклад:\n"
            "Кабель UTP Cat6 | 50м\n"
            "Камера Hikvision 4MP | 2шт\n\n"
            "Кожен матеріал з нового рядка.\n"
            "Напишіть /done коли закінчите."
        )


async def callback_matmanual(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    visit_id = query.data.replace("matmanual_", "")
    chat_id = query.message.chat_id
    STATES[chat_id] = {"cmd": "materials", "visit_id": visit_id, "items": []}

    await query.edit_message_text(
        f"📦 Додайте матеріали для виїзду {visit_id}\n\n"
        "Введіть у форматі:\n"
        "Назва | Кількість\n\n"
        "Наприклад:\n"
        "Кабель UTP Cat6 | 50м\n"
        "Камера Hikvision 4MP | 2шт\n\n"
        "Кожен матеріал з нового рядка.\n"
        "Напишіть /done коли закінчите."
    )


async def callback_addmat(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    parts = query.data.replace("addmat_", "").split("_", 1)
    visit_id = parts[0]
    item_code = parts[1] if len(parts) > 1 else "unknown"

    try:
        result = await api_post(f"/api/v1/visits/{visit_id}/materials", {
            "item_code": item_code,
            "item_name": item_code,
            "quantity": 1,
        })
        if result.get("success"):
            await query.answer("✅ Матеріал додано!", show_alert=True)
        else:
            await query.answer("Помилка", show_alert=True)
    except Exception as e:
        await query.answer(f"Помилка: {e}", show_alert=True)


# =============================================================================
# /newticket — 5 кроків
# =============================================================================
PRIORITY_KB = [["🟢 Low", "🟡 Medium"], ["🟠 High", "🔴 Critical"]]


async def cmd_newticket(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    STATES[chat_id] = {"cmd": "newticket", "step": "title", "data": {}}
    await update.message.reply_text(
        "📝 Створення заявки (крок 1/5)\n\n"
        "Що сталось? Коротко опишіть проблему:",
        reply_markup=ReplyKeyboardRemove(),
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
        await update.message.reply_text("📍 Кде проблема? Введіть адресу об'єкта:")
        return True

    if step == "address":
        data["address"] = text
        state["step"] = "contact"
        await update.message.reply_text("👤 Хто повідомив? ПІБ + телефон:")
        return True

    if step == "contact":
        data["contact"] = text
        state["step"] = "description"
        await update.message.reply_text("📋 Детальніше опишіть що сталось:")
        return True

    if step == "description":
        data["description"] = text
        state["step"] = "priority"
        await update.message.reply_text(
            "⚡ Наскільки терміново?",
            reply_markup=ReplyKeyboardMarkup(PRIORITY_KB, one_time_keyboard=True, resize_keyboard=True),
        )
        return True

    if step == "priority":
        pm = {"low": "low", "🟢 low": "low", "medium": "medium", "🟡 medium": "medium",
              "high": "high", "🟠 high": "high", "critical": "critical", "🔴 critical": "critical"}
        data["priority"] = pm.get(text.lower(), "medium")
        del STATES[chat_id]

        await update.message.reply_text("⏳ Створюю заявку...", reply_markup=ReplyKeyboardRemove())

        title = f"{data['title']} | {data['address']} | {data['contact']}"
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

            # Send notification to manager
            try:
                notify_text = (
                    f"📋 Нова заявка!\n\n"
                    f"Номер: {t['ticket_number']}\n"
                    f"Проблема: {data['title']}\n"
                    f"Адреса: {data['address']}\n"
                    f"Контакт: {data['contact']}\n"
                    f"Пріоритет: {data['priority']}\n"
                    f"SLA до: {str(t.get('sla_response_due', '—'))[:16]}"
                )
                await send_notification(update.message.chat_id, notify_text)
            except Exception:
                pass

            keyboard = [
                [InlineKeyboardButton("🚗 Створити виїзд", callback_data=f"newvisit_{t['id']}")],
                [InlineKeyboardButton("📋 Мої заявки", callback_data="back_tickets")],
            ]
            await update.message.reply_text(
                f"✅ Заявку створено!\n\n"
                f"Номер: {t['ticket_number']}\n"
                f"Проблема: {data['title']}\n"
                f"Адреса: {data['address']}\n"
                f"Контакт: {data['contact']}\n"
                f"Пріоритет: {data['priority']}\n\n"
                f"SLA до: {str(t.get('sla_response_due', '—'))[:16]}",
                reply_markup=InlineKeyboardMarkup(keyboard),
            )
        else:
            await update.message.reply_text(f"❌ Помилка: {result}")
        return True

    return False


# =============================================================================
# /object
# =============================================================================
async def cmd_object(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        # Показуємо список об'єктів
        result = await api_get("/api/v1/objects?limit=10")
        if result.get("success") and result.get("data"):
            keyboard = []
            for obj in result["data"]:
                keyboard.append([InlineKeyboardButton(
                    f"{obj['object_code']} — {obj['name']}",
                    callback_data=f"obj_{obj['id']}"
                )])
            await update.message.reply_text("🏢 Оберіть об'єкт:", reply_markup=InlineKeyboardMarkup(keyboard))
        else:
            await update.message.reply_text("Немає об'єктів. Використання: /object {code}")
        return

    obj_code = context.args[0]
    await _show_object(update, obj_code)


async def callback_object(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    obj_id = query.data.replace("obj_", "")
    await _show_object_by_id(query, obj_id)


async def _show_object(update: Update, obj_code: str):
    result = await api_get("/api/v1/objects?limit=100")
    if not result.get("success"):
        await update.message.reply_text("❌ Помилка")
        return

    found = None
    for obj in result.get("data", []):
        if obj.get("object_code") == obj_code:
            found = obj
            break

    if not found:
        await update.message.reply_text(f"❌ Об'єкт {obj_code} не знайдено")
        return

    await _send_object_card(update.message, found)


async def _show_object_by_id(query, obj_id: str):
    result = await api_get(f"/api/v1/objects/{obj_id}")
    if not result.get("success"):
        await query.edit_message_text("❌ Помилка")
        return
    await _send_object_card_inline(query, result["data"])


async def _send_object_card(message, obj):
    equip_r = await api_get(f"/api/v1/equipment?limit=50")
    equipment = [e for e in equip_r.get("data", []) if str(e.get("object_id")) == str(obj["id"])]

    tickets_r = await api_get("/api/v1/tickets?limit=50")
    tickets = [t for t in tickets_r.get("data", []) if str(t.get("object_id")) == str(obj["id"])]
    open_t = [t for t in tickets if t["status"] not in ["closed", "cancelled"]]

    text = (
        f"🏢 {obj['name']}\n"
        f"Код: {obj['object_code']}\n"
        f"Адреса: {obj.get('address', '—')}\n"
        f"Тип: {obj.get('object_type', '—')}\n"
        f"Сервіс: {obj['service_level']}\n\n"
        f"📦 Обладнання: {len(equipment)} од.\n"
    )
    for eq in equipment[:5]:
        text += f"  • {eq['model']} ({eq.get('serial_number', '—')})\n"

    if open_t:
        text += f"\n📋 Активні заявки: {len(open_t)}\n"
        for t in open_t[:3]:
            text += f"  • {t['ticket_number']}: {t['title'][:40]}\n"

    keyboard = [[InlineKeyboardButton("📝 Нова заявка", callback_data=f"newticket_obj_{obj['id']}")]]
    await message.reply_text(text, reply_markup=InlineKeyboardMarkup(keyboard))


async def _send_object_card_inline(query, obj):
    equip_r = await api_get(f"/api/v1/equipment?limit=50")
    equipment = [e for e in equip_r.get("data", []) if str(e.get("object_id")) == str(obj["id"])]

    text = (
        f"🏢 {obj['name']}\n"
        f"Код: {obj['object_code']}\n"
        f"Адреса: {obj.get('address', '—')}\n"
        f"Тип: {obj.get('object_type', '—')}\n"
        f"Сервіс: {obj['service_level']}\n\n"
        f"📦 Обладнання: {len(equipment)} од.\n"
    )
    for eq in equipment[:5]:
        text += f"  • {eq['model']} ({eq.get('serial_number', '—')})\n"

    await query.edit_message_text(text)


# =============================================================================
# /sla
# =============================================================================
async def cmd_sla(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("📊 Завантажую...")
    try:
        result = await api_get("/api/v1/tickets?limit=100")
        if not result.get("success"):
            await update.message.reply_text("❌ Помилка")
            return

        tickets = result.get("data", [])
        total = len(tickets)
        if total == 0:
            await update.message.reply_text("📊 Немає заявок")
            return

        open_t = [t for t in tickets if t["status"] not in ["closed", "cancelled", "resolved"]]
        breached = sum(1 for t in tickets if t.get("sla_response_breached") or t.get("sla_resolution_breached"))
        compliance = ((total - breached) / total * 100)

        by_priority = {}
        for t in tickets:
            p = t["priority"]
            by_priority[p] = by_priority.get(p, 0) + 1

        text = (
            f"📊 SLA Статус\n\n"
            f"Всього: {total} | Відкритих: {len(open_t)}\n"
            f"Порушень: {breached} | Комплаєнс: {compliance:.0f}%\n\n"
            f"По пріоритетах:\n"
        )
        for p in ["critical", "high", "medium", "low"]:
            if p in by_priority:
                text += f"  {p}: {by_priority[p]}\n"

        await update.message.reply_text(text)
    except Exception as e:
        await update.message.reply_text(f"❌ Помилка: {e}")


# =============================================================================
# /kpi
# =============================================================================
async def cmd_kpi(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("📈 Завантажую...")
    try:
        t_r = await api_get("/api/v1/tickets?limit=100")
        o_r = await api_get("/api/v1/objects?limit=100")
        v_r = await api_get("/api/v1/visits?limit=100")

        tickets = t_r.get("data", []) if t_r.get("success") else []
        objects = o_r.get("data", []) if o_r.get("success") else []
        visits = v_r.get("data", []) if v_r.get("success") else []

        total = len(tickets)
        open_t = sum(1 for t in tickets if t["status"] not in ["closed", "cancelled", "resolved"])
        critical = sum(1 for t in tickets if t["priority"] == "critical" and t["status"] not in ["closed", "cancelled"])
        breached = sum(1 for t in tickets if t.get("sla_response_breached") or t.get("sla_resolution_breached"))
        compliance = ((total - breached) / total * 100) if total > 0 else 100

        await update.message.reply_text(
            f"📈 KPI Дашборд\n\n"
            f"🏢 Об'єктів: {len(objects)}\n"
            f"📋 Заявок: {total} (відкритих: {open_t})\n"
            f"🔴 Критичних: {critical}\n"
            f"🚗 Виїздів: {len(visits)}\n"
            f"📊 SLA: {compliance:.0f}%"
        )
    except Exception as e:
        await update.message.reply_text(f"❌ Помилка: {e}")


# =============================================================================
# Text handler
# =============================================================================
async def handle_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    chat_id = update.effective_chat.id
    text = update.message.text

    # Reply keyboard buttons
    if text == "📋 Мої заявки":
        await cmd_mytickets(update, context)
        return
    if text == "📝 Нова заявка":
        await cmd_newticket(update, context)
        return
    if text == "📊 SLA":
        await cmd_sla(update, context)
        return
    if text == "📈 KPI":
        await cmd_kpi(update, context)
        return

    if chat_id not in STATES:
        return

    state = STATES[chat_id]
    cmd = state.get("cmd")

    if cmd == "newticket":
        await _newticket_step(update, chat_id, text)
    elif cmd == "materials":
        if text.lower() == "/done":
            del STATES[chat_id]
            await update.message.reply_text("✅ Матеріали збережено!")
            return
        visit_id = state.get("visit_id")
        parts = [p.strip() for p in text.split("|")]
        if len(parts) >= 2:
            result = await api_post(f"/api/v1/visits/{visit_id}/materials", {
                "item_code": parts[0],
                "item_name": parts[0],
                "quantity": float(parts[1].replace("м", "").replace("шт", "").replace(" ", "")) if parts[1].replace("м", "").replace("шт", "").replace(".", "").replace(" ", "").isdigit() else 1,
            })
            if result.get("success"):
                await update.message.reply_text(f"✅ Додано: {parts[0]} ({parts[1]})\n\nНаступний матеріал або /done")
            else:
                await update.message.reply_text(f"❌ Помилка")
        else:
            await update.message.reply_text("❌ Формат: Назва | Кількість")


# =============================================================================
# Init
# =============================================================================
async def post_init(application: Application):
    await login_as_bot()
    await application.bot.set_my_commands([
        BotCommand("start", "Головне меню"),
        BotCommand("mytickets", "Мої заявки"),
        BotCommand("newticket", "Нова заявка"),
        BotCommand("object", "Об'єкти"),
        BotCommand("sla", "Статус SLA"),
        BotCommand("kpi", "KPI дашборд"),
        BotCommand("help", "Допомога"),
    ])
    await start_nats_subscribers(application)
    logger.info("Bot commands registered")


async def post_shutdown(application: Application):
    await stop_nats_subscribers()


def main():
    if not settings.telegram_bot_token:
        logger.error("TELEGRAM_BOT_TOKEN not set!")
        return

    app = Application.builder().token(settings.telegram_bot_token).post_init(post_init).post_shutdown(post_shutdown).build()

    app.add_handler(CommandHandler("start", cmd_start))
    app.add_handler(CommandHandler("help", cmd_help))
    app.add_handler(CommandHandler("mytickets", cmd_mytickets))
    app.add_handler(CommandHandler("newticket", cmd_newticket))
    app.add_handler(CommandHandler("object", cmd_object))
    app.add_handler(CommandHandler("sla", cmd_sla))
    app.add_handler(CommandHandler("kpi", cmd_kpi))

    # Callbacks
    app.add_handler(CallbackQueryHandler(callback_ticket, pattern="^ticket_"))
    app.add_handler(CallbackQueryHandler(callback_accept, pattern="^accept_"))
    app.add_handler(CallbackQueryHandler(callback_visit_start, pattern="^vstart_"))
    app.add_handler(CallbackQueryHandler(callback_visit_finish, pattern="^vfinish_"))
    app.add_handler(CallbackQueryHandler(callback_newvisit, pattern="^newvisit_"))
    app.add_handler(CallbackQueryHandler(callback_photo, pattern="^photo_"))
    app.add_handler(CallbackQueryHandler(callback_phototype, pattern="^phototype_"))
    app.add_handler(CallbackQueryHandler(callback_materials, pattern="^mat_"))
    app.add_handler(CallbackQueryHandler(callback_matmanual, pattern="^matmanual_"))
    app.add_handler(CallbackQueryHandler(callback_addmat, pattern="^addmat_"))
    app.add_handler(CallbackQueryHandler(callback_object, pattern="^obj_"))

    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text))

    # Error handler
    async def error_handler(update: object, context: ContextTypes.DEFAULT_TYPE) -> None:
        logger.error(f"Exception while handling an update: {context.error}", exc_info=context.error)
        if update and hasattr(update, 'callback_query') and update.callback_query:
            try:
                await update.callback_query.answer("❌ Сталася помилка", show_alert=True)
            except Exception:
                pass
        elif update and hasattr(update, 'message') and update.message:
            try:
                await update.message.reply_text("❌ Сталася помилка. Спробуйте ще раз.")
            except Exception:
                pass

    app.add_error_handler(error_handler)

    logger.info("Starting Telegram bot...")
    app.run_polling(drop_pending_updates=False)


if __name__ == "__main__":
    main()
