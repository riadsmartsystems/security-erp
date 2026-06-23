"""AI Orchestrator — failover across providers with circuit breaker awareness.

For each provider: check CB → if open, skip; if half_open, try probe → call complete().
Success → return AIResult + origin.
Failure/timeout → record_failure in CB → next provider.
All exhausted → return {"status": "manual", "reason": "all_providers_open"}.
"""

from __future__ import annotations

import asyncio
import logging
from dataclasses import dataclass

from security_erp.ai.adapters.base import AIResult, AbstractAIAdapter, timed_call
from security_erp.ai.circuit_breaker import CBState, CircuitBreaker

logger = logging.getLogger("ai.orchestrator")


@dataclass
class OrchestratorResult:
    result: AIResult
    origin: str


class AIOrchestrator:
    def __init__(self, providers: list[AbstractAIAdapter], cb: CircuitBreaker):
        self._providers = providers
        self._cb = cb

    async def execute(self, task: str, payload: dict, params: dict | None = None) -> dict:
        """Try providers in order. Returns dict with status, content, origin."""
        for provider in self._providers:
            name = provider.name()

            if await self._cb.should_skip(name):
                logger.info("Skipping %s — CB open", name)
                continue

            cb_state = await self._cb.get_state(name)
            is_probe = cb_state.state == "half_open"
            if is_probe:
                logger.info("Half-open probe for %s", name)

            try:
                result = await asyncio.wait_for(timed_call(provider, task, payload, params), timeout=30.0)
            except asyncio.TimeoutError:
                logger.warning("Timeout for %s", name)
                await self._cb.record_failure(name)
                continue
            except Exception as exc:
                logger.warning("Error from %s: %s", name, exc)
                await self._cb.record_failure(name)
                continue

            if result.status == "error":
                logger.warning("Error status from %s: %s", name, result.content)
                await self._cb.record_failure(name)
                continue

            await self._cb.record_success(name)
            logger.info("Success from %s (latency=%.0fms)", name, result.latency_ms)
            return {
                "status": result.status,
                "content": result.content,
                "tokens": result.tokens,
                "latency_ms": result.latency_ms,
                "origin": name,
                "raw_meta": result.raw_meta,
            }

        return {"status": "manual", "reason": "all_providers_open"}
