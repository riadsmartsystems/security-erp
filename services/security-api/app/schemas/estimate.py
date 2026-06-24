from pydantic import BaseModel, Field


class EstimateBuildRequest(BaseModel):
    site_brief_name: str = Field(..., min_length=1, max_length=140)
    variant: str = Field(default="optimal", pattern="^(budget|optimal|premium)$")


class EstimateBuildResponse(BaseModel):
    name: str = ""
    status: str = "pending"
    origin: str = ""


class EstimateReviewRequest(BaseModel):
    decision: str = Field(..., pattern="^(approved|rejected)$")


class EstimateReviewResponse(BaseModel):
    name: str
    status: str
    reviewed_by: str


class EstimateConfirmResponse(BaseModel):
    quotation_name: str
