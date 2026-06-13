from pydantic import BaseModel, EmailStr
from typing import Optional
from uuid import UUID
from datetime import datetime


class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshRequest(BaseModel):
    refresh_token: str


class UserCreate(BaseModel):
    email: str
    username: str
    full_name: str
    password: str
    role: str = "viewer"
    employee_id: Optional[UUID] = None


class UserResponse(BaseModel):
    id: UUID
    email: str
    username: str
    full_name: str
    role: str
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class HealthResponse(BaseModel):
    status: str
    version: str
    services: dict[str, str]
