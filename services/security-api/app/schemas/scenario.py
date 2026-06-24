from pydantic import BaseModel, Field
from typing import Optional


class ScenarioUpsertRequest(BaseModel):
    name: Optional[str] = None
    scenario_name: str = Field(..., min_length=1, max_length=140)
    description: str = ""


class ScenarioItemUpsertRequest(BaseModel):
    item_code: str = Field(..., min_length=1, max_length=140)
    item_name: str = ""
    qty: float = 1.0
    qty_rule: str = Field(default="fixed", pattern="^(fixed|per_camera|per_100m2|per_point)$")
    qty_factor: float = 1.0
    rate: float = 0.0
    description: str = ""


class ScenarioResponse(BaseModel):
    name: str
    scenario_name: str = ""
    description: str = ""


class ScenarioListResponse(BaseModel):
    scenarios: list[ScenarioResponse]
