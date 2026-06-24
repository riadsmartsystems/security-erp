"""
erpnext/security_erp/security_erp/ai/circuit_breaker.py

Multi-provider Circuit Breaker backed by Redis.
Key format: cb:provider:{name}  (one hash per provider)
Fields: state (closed/open/half_open), failures (int), opened_at (unix float)

Two API surfaces:
  Async — for AIOrchestrator.execute() (FastAPI path)
  Sync  — for _run_orchestrator_sync() in ai_estimate.py (RQ / gevent path)
"""

import time
from dataclasses import dataclass
from enum import Enum


class CBState(str, Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"


@dataclass
class CBStateData:
    state: str
    failures: int


class CircuitBreaker:
    def __init__(self, redis_client, fail_threshold: int = 5, reset_timeout: int = 60):
        self.r = redis_client
        self.fail_threshold = fail_threshold
        self.reset_timeout = reset_timeout

    def _key(self, name: str) -> str:
        return f"cb:provider:{name}"

    # ── ASYNC methods (FastAPI / AIOrchestrator path) ──────────────────────────

    async def get_state(self, name: str) -> CBStateData:
        raw = await self.r.hgetall(self._key(name))
        state = raw.get("state", "closed")
        failures = int(raw.get("failures", 0))
        return CBStateData(state=state, failures=failures)

    async def should_skip(self, name: str) -> bool:
        """True when CB is open AND reset timeout has not elapsed (don't probe yet)."""
        raw = await self.r.hgetall(self._key(name))
        state = raw.get("state", "closed")
        if state == "open":
            opened_at = float(raw.get("opened_at", 0))
            if time.time() - opened_at >= self.reset_timeout:
                return False  # allow probe attempt
        return state == "open"

    async def try_probe(self, name: str) -> str:
        """Transition open→half_open when reset timeout has elapsed; return new state."""
        key = self._key(name)
        raw = await self.r.hgetall(key)
        state = raw.get("state", "closed")
        if state == "open":
            opened_at = float(raw.get("opened_at", 0))
            if time.time() - opened_at >= self.reset_timeout:
                await self.r.hset(key, "state", "half_open")
                return "half_open"
            return "open"
        return state

    async def record_failure(self, name: str) -> None:
        key = self._key(name)
        failures = await self.r.hincrby(key, "failures", 1)
        if int(failures) >= self.fail_threshold:
            await self.r.hset(key, mapping={"state": "open", "opened_at": str(time.time())})

    async def record_success(self, name: str) -> None:
        await self.r.hset(self._key(name), mapping={"state": "closed", "failures": "0"})

    # ── SYNC methods (RQ / gevent path in ai_estimate.py) ─────────────────────

    def is_available_sync(self, name: str) -> bool:
        raw = self.r.hgetall(self._key(name))
        state = raw.get("state", "closed")
        if state == "open":
            opened_at = float(raw.get("opened_at", 0))
            if time.time() - opened_at >= self.reset_timeout:
                return True  # allow probe
        return state != "open"

    def record_failure_sync(self, name: str) -> None:
        key = self._key(name)
        failures = self.r.hincrby(key, "failures", 1)
        if int(failures) >= self.fail_threshold:
            self.r.hset(key, mapping={"state": "open", "opened_at": str(time.time())})

    def record_success_sync(self, name: str) -> None:
        self.r.hset(self._key(name), mapping={"state": "closed", "failures": "0"})
