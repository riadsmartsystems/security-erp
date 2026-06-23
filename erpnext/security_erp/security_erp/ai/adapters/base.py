"""
erpnext/security_erp/security_erp/ai/adapters/base.py

FIX 2.5: Add complete_sync() to AbstractAIAdapter.

ROOT CAUSE: _run_orchestrator_sync() in ai_estimate.py calls provider.complete_sync()
which doesn't exist. hasattr() always returns False → falls to asyncio.run() fallback
→ gevent deadlock.

SOLUTION: Add complete_sync() as abstract method. Each adapter implements it using
httpx (sync HTTP client) instead of aiohttp/httpx async.
"""

import time
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional


@dataclass
class AIResult:
    content: str
    tokens_used: Optional[int] = None
    latency_ms: Optional[int] = None
    provider: Optional[str] = None


class AbstractAIAdapter(ABC):
    """Base class for all AI provider adapters."""

    provider_name: str = "abstract"

    @abstractmethod
    async def complete(self, task: str, payload: dict, params: Optional[dict]) -> AIResult:
        """Async version — used when called from async context."""
        ...

    @abstractmethod
    def complete_sync(self, task: str, payload: dict, params: Optional[dict]) -> AIResult:
        """
        Sync version — used in:
        - Frappe @whitelist handlers (gevent, no event loop)
        - RQ workers (gevent, no event loop)

        Implement using httpx.post() (sync), NOT aiohttp or async httpx.
        """
        ...


def timed_call(adapter, task, payload, params):
    """
    Sync timed wrapper for complete_sync().
    Replaces the async _timed_call() used with asyncio.run().
    """
    start = time.monotonic()
    result = adapter.complete_sync(task, payload, params)
    result.latency_ms = int((time.monotonic() - start) * 1000)
    return result
