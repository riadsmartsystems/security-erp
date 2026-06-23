"""Calculator submission schemas."""

from pydantic import BaseModel, Field
from typing import Optional


class CalcSubmitRequest(BaseModel):
    object_type: str
    area_m2: float = Field(gt=0)
    cameras_count: int = Field(ge=0)
    archive_days: int = Field(ge=0)
    contact_name: str
    contact_phone: str
    contact_email: str = ""
    captcha_token: str


class CalcSubmitResponse(BaseModel):
    submission_name: str
    estimated_total: float
    matched_scenario: Optional[str] = None
    status: str
