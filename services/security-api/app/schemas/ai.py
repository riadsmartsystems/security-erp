from pydantic import BaseModel, Field


class AIExecuteRequest(BaseModel):
    task: str = Field(..., min_length=1, max_length=100)
    payload: dict = Field(default_factory=dict)
    params: dict | None = None


class AIExecuteResponse(BaseModel):
    status: str
    content: str = ""
    tokens: int = 0
    latency_ms: float = 0.0
    origin: str = ""
    raw_meta: dict = Field(default_factory=dict)


class AIProviderInfo(BaseModel):
    name: str
    health: str
    priority: int = 0


class AIDegradationResponse(BaseModel):
    level: str
    providers: list[dict]
    message: str = ""
