from __future__ import annotations
from pydantic import BaseModel, Field

class PushTokenRegisterRequest(BaseModel):
    device_id: str = Field(..., min_length=1, max_length=128)
    fcm_token: str = Field(..., min_length=1, max_length=512)
    # ПРИМІТКА: pattern дозволяє ios/web, але Task 5 наразі налаштовує лише
    # Android у Firebase Console. Якщо iOS/Web не в планах найближчим часом —
    # звуж до pattern="^(android)$", інакше такі токени мовчки не доставлятимуть.
    platform: str = Field(default="android", pattern="^(android|ios|web)$")

class PushTokenRegisterResponse(BaseModel):
    ok: bool = True
    device_id: str

class PushTokenRevokeRequest(BaseModel):
    device_id: str = Field(..., min_length=1, max_length=128)

class PushTokenRevokeResponse(BaseModel):
    ok: bool = True
    revoked: str

class PushSendRequest(BaseModel):
    user_id: str = Field(..., min_length=1)
    title: str = Field(..., min_length=1, max_length=100)
    body: str = Field(..., min_length=1, max_length=500)
    data: dict = Field(default_factory=dict)

class PushSendResponse(BaseModel):
    ok: bool
    sent: int = 0
    failed: int = 0
