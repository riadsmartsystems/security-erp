"""
erpnext/security_erp/security_erp/ai/adapters/gemini.py

FIX 2.5: Add complete_sync() using httpx (sync HTTP) instead of async client.
"""

import json
import httpx
from .base import AbstractAIAdapter, AIResult

GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"
DEFAULT_MODEL = "gemini-1.5-flash"


class GeminiAdapter(AbstractAIAdapter):
    provider_name = "gemini"

    def __init__(self, api_key: str, model: str = None):
        self.api_key = api_key
        self.model = model or DEFAULT_MODEL
        self._url = GEMINI_API_URL.format(model=self.model)

    def _build_body(self, task: str, payload: dict, params: dict | None) -> dict:
        prompt = f"Task: {task}\n\nData: {json.dumps(payload, ensure_ascii=False)}"
        return {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "maxOutputTokens": (params or {}).get("max_tokens", 2048),
                "temperature": (params or {}).get("temperature", 0.3),
            },
        }

    def complete_sync(self, task: str, payload: dict, params: dict | None) -> AIResult:
        """Sync HTTP call via httpx — safe in gevent/RQ context."""
        body = self._build_body(task, payload, params)
        with httpx.Client(timeout=30.0) as client:
            response = client.post(
                self._url,
                params={"key": self.api_key},
                json=body,
                headers={"Content-Type": "application/json"},
            )
        response.raise_for_status()
        data = response.json()

        candidates = data.get("candidates", [])
        if not candidates:
            raise ValueError("Gemini returned no candidates")

        text = candidates[0]["content"]["parts"][0]["text"]
        usage = data.get("usageMetadata", {})
        tokens = usage.get("totalTokenCount")

        return AIResult(
            content=text,
            tokens_used=tokens,
            provider=self.provider_name,
        )

    async def complete(self, task: str, payload: dict, params: dict | None) -> AIResult:
        """Async version — kept for potential future async contexts."""
        import httpx as _httpx
        body = self._build_body(task, payload, params)
        async with _httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                self._url,
                params={"key": self.api_key},
                json=body,
                headers={"Content-Type": "application/json"},
            )
        response.raise_for_status()
        data = response.json()
        candidates = data.get("candidates", [])
        if not candidates:
            raise ValueError("Gemini returned no candidates")
        text = candidates[0]["content"]["parts"][0]["text"]
        tokens = data.get("usageMetadata", {}).get("totalTokenCount")
        return AIResult(content=text, tokens_used=tokens, provider=self.provider_name)
