"""
erpnext/security_erp/security_erp/ai/adapters/base.py

AbstractAIAdapter + AIResult + timed_call.

Two execution paths:
  - Async (FastAPI / orchestrator): await provider.complete(task, payload, params)
  - Sync  (RQ / gevent):           provider.complete_sync(task, payload, params)

timed_call() is sync — used by _run_orchestrator_sync() in ai_estimate.py.
The async orchestrator calls provider.complete() directly.
"""

import time
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class AIResult:
    status: str = "ok"
    content: str = ""
    tokens: int = 0
    latency_ms: float = 0.0
    provider: str = ""
    raw_meta: dict = field(default_factory=dict)


class AbstractAIAdapter(ABC):
    """Base class for all AI provider adapters."""

    provider_name: str = "abstract"

    @abstractmethod
    def name(self) -> str:
        ...

    @abstractmethod
    async def complete(self, task: str, payload: dict, params: Optional[dict] = None) -> AIResult:
        """Async version — used by AIOrchestrator.execute() (FastAPI path)."""
        ...

    def complete_sync(self, task: str, payload: dict, params: Optional[dict] = None) -> AIResult:
        """Sync version — used in RQ/gevent context (no event loop).
        Override in adapters that need to run in RQ workers.
        """
        raise NotImplementedError(f"{self.__class__.__name__}.complete_sync() not implemented")

    async def health_check(self) -> str:
        return "unknown"


def timed_call(adapter: AbstractAIAdapter, task: str, payload: dict, params: Optional[dict]) -> AIResult:
    """Sync timed wrapper — called from _run_orchestrator_sync() (RQ path)."""
    start = time.monotonic()
    result = adapter.complete_sync(task, payload, params)
    result.latency_ms = (time.monotonic() - start) * 1000
    return result


TASK_PROJECT_BUILDER = "project_builder"
TASK_INSPECTION_REPORT = "inspection_report"
