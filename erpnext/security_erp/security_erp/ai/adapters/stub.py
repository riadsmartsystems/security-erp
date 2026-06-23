"""
erpnext/security_erp/security_erp/ai/adapters/stub.py

FIX 2.5: Add complete_sync() to StubAdapter.
Used for testing and as final fallback when all real providers fail.
"""

from .base import AbstractAIAdapter, AIResult


class StubAdapter(AbstractAIAdapter):
    provider_name = "stub"

    def complete_sync(self, task: str, payload: dict, params: dict | None) -> AIResult:
        """Returns canned response — never fails, used as last-resort fallback in tests."""
        return AIResult(
            content=f"[STUB] Task '{task}' received. Manual review required.",
            tokens_used=0,
            provider=self.provider_name,
        )

    async def complete(self, task: str, payload: dict, params: dict | None) -> AIResult:
        return self.complete_sync(task, payload, params)
