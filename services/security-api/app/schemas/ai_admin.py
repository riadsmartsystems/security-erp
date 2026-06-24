from pydantic import BaseModel, Field
from typing import Optional


class AIProviderUpsertRequest(BaseModel):
    name: Optional[str] = None
    provider_name: str = Field(..., min_length=1, max_length=140)
    priority: int = 0
    is_enabled: bool = True
    health_status: str = "healthy"


class AIProviderResponse(BaseModel):
    name: str
    provider_name: str = ""
    priority: int = 0
    is_enabled: bool = True
    health_status: str = ""


class AIRequestLogEntry(BaseModel):
    name: str
    anonymized_payload: str = ""
    provider: str = ""
    latency_ms: float = 0
    tokens: int = 0
    status: str = ""
    error_message: str = ""
    creation: str = ""


class AIRequestLogListResponse(BaseModel):
    logs: list[AIRequestLogEntry]
    total: int = 0


class AIDegradationResponse(BaseModel):
    level: str
    providers: list[dict]
    message: str = ""
