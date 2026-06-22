import time
import uuid

from app.core.redis import get_redis


async def check_rate_limit(
    key: str,
    max_attempts: int,
    window_seconds: int,
) -> dict:
    """Sliding window rate limit via Redis sorted set.

    Returns {"limited": bool, "retry_after": int|None}.
    """
    r = await get_redis()
    now = time.time()
    window_start = now - window_seconds

    pipe = r.pipeline(transaction=True)
    pipe.zremrangebyscore(key, "-inf", window_start)
    pipe.zadd(key, {f"{uuid.uuid4()}": now})
    pipe.zcard(key)
    pipe.expire(key, window_seconds)
    results = await pipe.execute()

    count = results[2]
    if count > max_attempts:
        oldest = await zrange_oldest(r, key)
        retry_after = int(oldest + window_seconds - now) + 1 if oldest else window_seconds
        return {"limited": True, "retry_after": max(retry_after, 1)}

    return {"limited": False, "retry_after": None}


async def zrange_oldest(r, key: str) -> float | None:
    """Get the score of the oldest element in the sorted set."""
    result = await r.zrange(key, 0, 0, withscores=True)
    if result:
        return result[0][1]
    return None
