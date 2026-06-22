from typing import Optional
from pydantic import BaseModel


class MfaVerifyRequest(BaseModel):
    code: str


class VaultDecryptRequest(BaseModel):
    name: str
    fields: list[str]
    vault_session_token: str


class VaultUpsertRequest(BaseModel):
    name: Optional[str] = None
    fields: dict[str, str]
    vault_session_token: str
    meta: Optional[dict] = None


class ActOtpRequest(BaseModel):
    otp: str


class ActGenerateRequest(BaseModel):
    act_name: str
    vault_session_token: str
