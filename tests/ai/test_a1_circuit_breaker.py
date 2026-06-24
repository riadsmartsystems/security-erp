"""A1 Circuit Breaker + Orchestrator failover tests.

Uses 3 mock adapters (primary, secondary, tertiary) with a real Redis
circuit breaker to verify failover chain and CB state transitions.
"""

import asyncio
import os
import sys
import unittest

from fakeredis import FakeAsyncRedis as FakeRedis

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "erpnext", "security_erp"))

from security_erp.ai.adapters.base import AIResult, AbstractAIAdapter
from security_erp.ai.circuit_breaker import CircuitBreaker
from security_erp.ai.orchestrator import AIOrchestrator


class FailAdapter(AbstractAIAdapter):
    def __init__(self, provider_name: str):
        self._name = provider_name

    def name(self) -> str:
        return self._name

    async def complete(self, task: str, payload: dict, params: dict | None = None) -> AIResult:
        return AIResult(status="error", content=f"{self._name} failed", provider=self._name)

    async def health_check(self):
        return "down"


class SuccessAdapter(AbstractAIAdapter):
    def __init__(self, provider_name: str):
        self._name = provider_name

    def name(self) -> str:
        return self._name

    async def complete(self, task: str, payload: dict, params: dict | None = None) -> AIResult:
        return AIResult(status="ok", content=f"{self._name} ok", tokens=10, latency_ms=5.0, provider=self._name)

    async def health_check(self):
        return "healthy"


class CounterAdapter(AbstractAIAdapter):
    def __init__(self, provider_name: str):
        self._name = provider_name
        self.call_count = 0

    def name(self) -> str:
        return self._name

    async def complete(self, task: str, payload: dict, params: dict | None = None) -> AIResult:
        self.call_count += 1
        return AIResult(status="error", content=f"{self._name} fail #{self.call_count}", provider=self._name)

    async def health_check(self):
        return "down"


class TestCircuitBreakerFailover(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.r = FakeRedis(decode_responses=True)

    async def asyncTearDown(self):
        await self.r.aclose()

    def _make_cb(self):
        return CircuitBreaker(self.r)

    async def _seed_failures(self, cb: CircuitBreaker, name: str, count: int):
        for _ in range(count):
            await cb.record_failure(name)

    async def test_primary_fails_5_times_cb_opens_failover_to_secondary(self):
        """Pre-load 4 failures → orchestrator triggers 5th → CB opens → failover to secondary."""
        primary = FailAdapter("primary")
        secondary = SuccessAdapter("secondary")
        tertiary = SuccessAdapter("tertiary")
        cb = self._make_cb()

        await self._seed_failures(cb, "primary", 4)
        self.assertEqual((await cb.get_state("primary")).failures, 4)
        self.assertEqual((await cb.get_state("primary")).state, "closed")

        orch = AIOrchestrator([primary, secondary, tertiary], cb)
        result = await orch.execute("test", {"prompt": "hello"})

        self.assertEqual(result["origin"], "secondary")
        self.assertEqual(result["status"], "ok")
        self.assertEqual((await cb.get_state("primary")).state, "open")

    async def test_secondary_also_fails_failover_to_tertiary(self):
        """Pre-load both primary and secondary with 4 failures each → both open → tertiary succeeds."""
        primary = FailAdapter("primary")
        secondary = FailAdapter("secondary")
        tertiary = SuccessAdapter("tertiary")
        cb = self._make_cb()

        await self._seed_failures(cb, "primary", 4)
        await self._seed_failures(cb, "secondary", 4)

        orch = AIOrchestrator([primary, secondary, tertiary], cb)
        result = await orch.execute("test", {"prompt": "hello"})

        self.assertEqual(result["origin"], "tertiary")
        self.assertEqual(result["status"], "ok")
        self.assertEqual((await cb.get_state("primary")).state, "open")
        self.assertEqual((await cb.get_state("secondary")).state, "open")

    async def test_secondary_not_called_after_cb_open(self):
        """After primary and secondary CB open, secondary.complete() is NOT called — tertiary succeeds."""
        primary = FailAdapter("primary")
        counter = CounterAdapter("secondary")
        tertiary = SuccessAdapter("tertiary")
        cb = self._make_cb()

        await self._seed_failures(cb, "primary", 5)
        await self._seed_failures(cb, "secondary", 5)
        self.assertEqual((await cb.get_state("primary")).state, "open")
        self.assertEqual((await cb.get_state("secondary")).state, "open")

        orch = AIOrchestrator([primary, counter, tertiary], cb)
        result = await orch.execute("test", {"prompt": "hello"})

        self.assertEqual(result["origin"], "tertiary")
        self.assertEqual(counter.call_count, 0)

    async def test_all_open_returns_manual(self):
        """All 3 providers CB open → orchestrator returns manual status."""
        primary = FailAdapter("primary")
        secondary = FailAdapter("secondary")
        tertiary = FailAdapter("tertiary")
        cb = self._make_cb()

        for name in ["primary", "secondary", "tertiary"]:
            await self._seed_failures(cb, name, 5)

        self.assertEqual((await cb.get_state("primary")).state, "open")
        self.assertEqual((await cb.get_state("secondary")).state, "open")
        self.assertEqual((await cb.get_state("tertiary")).state, "open")

        orch = AIOrchestrator([primary, secondary, tertiary], cb)
        result = await orch.execute("test", {"prompt": "hello"})

        self.assertEqual(result["status"], "manual")
        self.assertEqual(result["reason"], "all_providers_open")

    async def test_cb_half_open_success_closes(self):
        """half_open + success → closed, failures reset to 0."""
        cb = self._make_cb()
        await self._seed_failures(cb, "gemini", 5)
        self.assertEqual((await cb.get_state("gemini")).state, "open")

        # Force opened_at to 0 so probe transitions to half_open immediately
        await self.r.hset("cb:provider:gemini", "opened_at", "0")
        probe = await cb.try_probe("gemini")
        self.assertEqual(probe, "half_open")

        await cb.record_success("gemini")
        state = await cb.get_state("gemini")
        self.assertEqual(state.state, "closed")
        self.assertEqual(state.failures, 0)

    async def test_cb_half_open_failure_reopens(self):
        """half_open + failure → open again."""
        cb = self._make_cb()
        await self._seed_failures(cb, "gemini", 5)
        await self.r.hset("cb:provider:gemini", "opened_at", "0")
        self.assertEqual(await cb.try_probe("gemini"), "half_open")

        await cb.record_failure("gemini")
        state = await cb.get_state("gemini")
        self.assertEqual(state.state, "open")


if __name__ == "__main__":
    unittest.main()
