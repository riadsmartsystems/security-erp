from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import datetime


class TicketCreate(BaseModel):
    customer_id: UUID
    object_id: UUID
    contract_id: Optional[UUID] = None
    ticket_type: str = "incident"
    priority: str = "medium"
    title: str
    description: Optional[str] = None
    assigned_engineer_id: Optional[UUID] = None


class TicketResponse(BaseModel):
    id: UUID
    ticket_number: str
    customer_id: UUID
    object_id: UUID
    contract_id: Optional[UUID]
    ticket_type: str
    priority: str
    status: str
    title: str
    description: Optional[str]
    assigned_engineer_id: Optional[UUID]
    sla_response_due: Optional[datetime]
    sla_arrival_due: Optional[datetime]
    sla_resolution_due: Optional[datetime]
    sla_response_breached: bool
    sla_resolution_breached: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class TicketAssign(BaseModel):
    engineer_id: UUID


class TicketStatusUpdate(BaseModel):
    status: str


class VisitCreate(BaseModel):
    ticket_id: UUID
    engineer_id: UUID
    planned_start: Optional[datetime] = None


class VisitResponse(BaseModel):
    id: UUID
    visit_number: str
    ticket_id: UUID
    engineer_id: UUID
    status: str
    planned_start: Optional[datetime]
    actual_start: Optional[datetime]
    actual_finish: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True


class VisitCheckin(BaseModel):
    lat: float
    lon: float


class VisitMaterialCreate(BaseModel):
    item_code: str
    item_name: str
    serial_number: Optional[str] = None
    quantity: float = 1
    uom: str = "pcs"


class MaintenancePlanCreate(BaseModel):
    object_id: UUID
    customer_id: UUID
    name: str
    frequency: str = "monthly"
    next_due_date: datetime
