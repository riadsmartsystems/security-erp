"""
erpnext/security_erp/security_erp/ai/circuit_breaker.py

FIX 2.5: Add sync methods (is_available_sync, record_success_sync, etc.)
alongside existing async methods. Uses same Redis Lua scripts for atomicity.

ROOT CAUSE: Async methods (is_available, record_success) use aioredis —
not callable in gevent/RQ context without event loop.
Sync methods use redis.Redis (sync client, gevent-safe via socket patching).
"""

import time
from enum import Enum
from typing import Optional

# Existing Lua scripts — reused by both sync and async methods
_LUA_CHECK = """
local key = KEYS[1]
local now = tonumber(ARGV[1])
local state = redis.call('HGET', key, 'state')
if state == 'open' then
    local reset_at = tonumber(redis.call('HGET', key, 'reset_at') or '0')
    if now >= reset_at then
        redis.call('HSET', key, 'state', 'half_open')
        return 'half_open'
    end
    return 'open'
end
return state or 'closed'
"""

_LUA_RECORD = """
local key = KEYS[1]
local result = ARGV[1]
local now = tonumber(ARGV[2])
local fail_threshold = tonumber(ARGV[3])
local reset_timeout = tonumber(ARGV[4])
if result == 'success' then
    redis.call('HSET', key, 'state', 'closed', 'failures', '0')
    return 'closed'
end
local failures = tonumber(redis.call('HINCRBY', key, 'failures', 1))
if failures >= fail_threshold then
    redis.call('HSET', key, 'state', 'open', 'reset_at', tostring(now + reset_timeout))
    return 'open'
end
return 'closed'
"""


class CBState(str, Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"


class CircuitBreaker:
    def __init__(
        self,
        redis_client,  # can be redis.Redis (sync) or aioredis.Redis (async)
        provider_name: str,
        fail_threshold: int = 5,
        reset_timeout: int = 60,
    ):
        self.r = redis_client
        self.key = f"cb:{provider_name}"
        self.fail_threshold = fail_threshold
        self.reset_timeout = reset_timeout

    # ── SYNC methods (gevent-safe) ──────────────────────────────────────────

    def is_available_sync(self) -> bool:
        """Check if provider is available. Safe in gevent/RQ context."""
        state = self.get_state_sync()
        return state != CBState.OPEN

    def get_state_sync(self) -> CBState:
        script = self.r.register_script(_LUA_CHECK)
        state = script(keys=[self.key], args=[int(time.time())])
        return CBState(state or "closed")

    def record_success_sync(self):
        script = self.r.register_script(_LUA_RECORD)
        script(
            keys=[self.key],
            args=["success", int(time.time()), self.fail_threshold, self.reset_timeout],
        )

    def record_failure_sync(self):
        script = self.r.register_script(_LUA_RECORD)
        script(
            keys=[self.key],
            args=["failure", int(time.time()), self.fail_threshold, self.reset_timeout],
        )

    # ── ASYNC methods (for potential future async contexts) ─────────────────

    async def is_available(self) -> bool:
        state = await self.get_state()
        return state != CBState.OPEN

    async def get_state(self) -> CBState:
        script = self.r.register_script(_LUA_CHECK)
        state = await script(keys=[self.key], args=[int(time.time())])
        return CBState(state or "closed")

    async def record_success(self):
        script = self.r.register_script(_LUA_RECORD)
        await script(
            keys=[self.key],
            args=["success", int(time.time()), self.fail_threshold, self.reset_timeout],
        )

    async def record_failure(self):
        script = self.r.register_script(_LUA_RECORD)
        await script(
            keys=[self.key],
            args=["failure", int(time.time()), self.fail_threshold, self.reset_timeout],
        )
