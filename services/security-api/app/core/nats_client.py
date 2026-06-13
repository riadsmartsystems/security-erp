import nats
from app.core.config import settings

_nc = None


async def get_nats():
    global _nc
    if _nc is None or _nc.is_closed:
        _nc = await nats.connect(settings.nats_url)
    return _nc


async def publish_event(subject: str, data: bytes):
    nc = await get_nats()
    await nc.publish(subject, data)
