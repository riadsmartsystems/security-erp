"""Push notification service — FCM via firebase-admin + Redis token storage."""
from __future__ import annotations
import asyncio
import json
import logging
import os
from app.core.redis import get_redis

logger = logging.getLogger("push.service")
_firebase_initialized = False
_background_tasks: set[asyncio.Task] = set()


def _ensure_firebase():
    global _firebase_initialized
    if _firebase_initialized:
        return
    from app.core.config import settings
    cred_path = settings.firebase_credentials_json
    if not cred_path or not os.path.exists(cred_path):
        logger.warning("Firebase credentials not found at '%s' — push disabled", cred_path)
        return
    try:
        from firebase_admin import credentials, initialize_app
        cred = credentials.Certificate(cred_path)
        initialize_app(cred)
        _firebase_initialized = True
        logger.info("Firebase initialized from %s", cred_path)
    except ValueError as e:
        # Hot-reload (наприклад uvicorn --reload) може повторно виконати цей
        # модуль, поки firebase_admin вже зберігає раніше створений app.
        if "already exists" in str(e):
            _firebase_initialized = True
            logger.info("Firebase app already initialized, reusing existing app")
        else:
            logger.error("Firebase init failed: %s", e)
    except Exception as e:
        logger.error("Firebase init failed: %s", e)


async def register_token(*, user_id: str, device_id: str, fcm_token: str, platform: str = "android") -> bool:
    r = await get_redis()
    await r.setex(f"push:{user_id}:{device_id}", 60 * 60 * 24 * 90, json.dumps({"token": fcm_token, "platform": platform}))
    await r.sadd(f"push:devices:{user_id}", device_id)
    logger.info("Registered push token user=%s device=%s", user_id, device_id)
    return True


async def revoke_token(*, user_id: str, device_id: str) -> str:
    r = await get_redis()
    await r.delete(f"push:{user_id}:{device_id}")
    await r.srem(f"push:devices:{user_id}", device_id)
    logger.info("Revoked push token user=%s device=%s", user_id, device_id)
    return device_id


async def _get_user_tokens(*, user_id: str) -> list[tuple[str, str]]:
    """Повертає пари (device_id, token).

    Самостійно лікує push:devices:{user}: якщо TTL токена вже спливло (ключ
    push:{user}:{device} зник), device_id прибирається з SET — інакше
    застарілі записи накопичувались би там назавжди.
    """
    r = await get_redis()
    devices = await r.smembers(f"push:devices:{user_id}")
    pairs: list[tuple[str, str]] = []
    for device_id in devices:
        did = device_id.decode() if isinstance(device_id, bytes) else device_id
        data = await r.get(f"push:{user_id}:{did}")
        if data:
            parsed = json.loads(data.decode() if isinstance(data, bytes) else data)
            pairs.append((did, parsed["token"]))
        else:
            await r.srem(f"push:devices:{user_id}", did)
    return pairs


async def send_push(*, user_id: str, title: str, body: str, data: dict | None = None) -> dict:
    _ensure_firebase()
    if not _firebase_initialized:
        return {"ok": False, "sent": 0, "failed": 0, "reason": "firebase_not_initialized"}
    pairs = await _get_user_tokens(user_id=user_id)
    if not pairs:
        return {"ok": True, "sent": 0, "failed": 0}

    from firebase_admin import messaging
    total_sent, total_failed = 0, 0
    try:
        # FCM обмежує мультикаст 500 токенами на виклик — чанкуємо про всяк випадок.
        for i in range(0, len(pairs), 500):
            chunk = pairs[i:i + 500]
            chunk_device_ids = [d for d, _ in chunk]
            chunk_tokens = [t for _, t in chunk]
            message = messaging.MulticastMessage(
                notification=messaging.Notification(title=title, body=body),
                data={k: str(v) for k, v in (data or {}).items()},
                tokens=chunk_tokens,
            )
            # ВИПРАВЛЕНО: send_each() приймає list[Message], а НЕ MulticastMessage.
            # Для MulticastMessage потрібен саме send_each_for_multicast().
            response = messaging.send_each_for_multicast(message)
            total_sent += response.success_count
            total_failed += response.failure_count
            for device_id, resp in zip(chunk_device_ids, response.responses):
                if not resp.success and isinstance(resp.exception, messaging.UnregisteredError):
                    # Токен більше не валідний (наприклад, застосунок видалено) —
                    # відкликаємо, щоб не слати на нього вічно.
                    await revoke_token(user_id=user_id, device_id=device_id)
        logger.info("Push sent: user=%s sent=%d failed=%d", user_id, total_sent, total_failed)
        return {"ok": True, "sent": total_sent, "failed": total_failed}
    except Exception as e:
        logger.error("Push failed user=%s: %s", user_id, e)
        return {"ok": False, "sent": total_sent, "failed": len(pairs) - total_sent, "error": str(e)}


def fire_and_forget_push(*, user_id: str, title: str, body: str, data: dict | None = None) -> None:
    """Планує send_push() у фоні БЕЗ блокування викликача.

    Використовуй це з route-тригерів, де потрібен справжній fire-and-forget:
    `await send_push(...)` всередині try/except все одно блокує HTTP-відповідь
    на час мережевого виклику до FCM/Redis — ця функція ні.
    """
    task = asyncio.create_task(send_push(user_id=user_id, title=title, body=body, data=data))
    _background_tasks.add(task)
    task.add_done_callback(_background_tasks.discard)
