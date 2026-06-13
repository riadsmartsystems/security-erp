from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID
import json

from app.core.database import get_db
from app.models.ticket import (
    Ticket, TicketStatus, TicketPriority, TicketType,
    Visit, VisitStatus, VisitPhoto, VisitMaterial,
    SLAEvent, MaintenancePlan, WarrantyCase,
)
from app.schemas.ticket import (
    TicketCreate, TicketResponse, TicketAssign, TicketStatusUpdate,
    VisitCreate, VisitResponse, VisitCheckin, VisitMaterialCreate,
    MaintenancePlanCreate,
)
from app.services.sla_engine import calculate_sla_deadlines, pause_sla, resume_sla

router = APIRouter(prefix="/api/v1", tags=["tickets"])


def _get_user_id(headers: dict) -> str | None:
    return headers.get("x-user-id")


# --- TICKETS ---

@router.get("/tickets")
async def list_tickets(
    status: str | None = None,
    priority: str | None = None,
    assigned_engineer_id: UUID | None = None,
    limit: int = Query(50, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
):
    query = select(Ticket).where(Ticket.is_active == True)

    if status:
        query = query.where(Ticket.status == status)
    if priority:
        query = query.where(Ticket.priority == priority)
    if assigned_engineer_id:
        query = query.where(Ticket.assigned_engineer_id == assigned_engineer_id)

    query = query.order_by(Ticket.created_at.desc()).offset(offset).limit(limit)
    result = await db.execute(query)
    tickets = result.scalars().all()

    count_q = select(func.count()).select_from(Ticket).where(Ticket.is_active == True)
    if status:
        count_q = count_q.where(Ticket.status == status)
    total = (await db.execute(count_q)).scalar() or 0

    return {
        "success": True,
        "data": [TicketResponse.model_validate(t) for t in tickets],
        "total": total,
        "limit": limit,
        "offset": offset,
    }


@router.post("/tickets")
async def create_ticket(
    body: TicketCreate,
    db: AsyncSession = Depends(get_db),
):
    now = datetime.now(timezone.utc)
    count = (await db.execute(select(func.count()).select_from(Ticket))).scalar() or 0
    ticket_number = f"TKT-{count + 1:06d}"

    deadlines = calculate_sla_deadlines(
        TicketPriority(body.priority), now
    )

    ticket = Ticket(
        ticket_number=ticket_number,
        customer_id=body.customer_id,
        object_id=body.object_id,
        contract_id=body.contract_id,
        ticket_type=TicketType(body.ticket_type),
        priority=TicketPriority(body.priority),
        status=TicketStatus.NEW,
        title=body.title,
        description=body.description,
        assigned_engineer_id=body.assigned_engineer_id,
        **deadlines,
    )

    if body.assigned_engineer_id:
        ticket.status = TicketStatus.ASSIGNED

    db.add(ticket)
    await db.flush()

    event = SLAEvent(
        ticket_id=ticket.id,
        event_type="started",
        timer_type="response",
        details="SLA timers started on ticket creation",
    )
    db.add(event)
    await db.commit()
    await db.refresh(ticket)

    return {"success": True, "data": TicketResponse.model_validate(ticket)}


@router.get("/tickets/{ticket_id}")
async def get_ticket(ticket_id: UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Ticket).where(Ticket.id == ticket_id, Ticket.is_active == True))
    ticket = result.scalar_one_or_none()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    return {"success": True, "data": TicketResponse.model_validate(ticket)}


@router.post("/tickets/{ticket_id}/assign")
async def assign_ticket(
    ticket_id: UUID,
    body: TicketAssign,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Ticket).where(Ticket.id == ticket_id, Ticket.is_active == True))
    ticket = result.scalar_one_or_none()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    ticket.assigned_engineer_id = body.engineer_id
    ticket.status = TicketStatus.ASSIGNED
    ticket.updated_at = datetime.now(timezone.utc)
    await db.commit()

    return {"success": True, "data": TicketResponse.model_validate(ticket)}


@router.post("/tickets/{ticket_id}/status")
async def update_ticket_status(
    ticket_id: UUID,
    body: TicketStatusUpdate,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Ticket).where(Ticket.id == ticket_id, Ticket.is_active == True))
    ticket = result.scalar_one_or_none()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    new_status = TicketStatus(body.status)
    old_status = ticket.status

    if new_status == TicketStatus.WAITING_PARTS:
        await pause_sla(db, ticket)
    elif old_status == TicketStatus.WAITING_PARTS:
        await resume_sla(db, ticket)

    ticket.status = new_status
    ticket.updated_at = datetime.now(timezone.utc)

    if new_status == TicketStatus.RESOLVED:
        ticket.resolved_at = datetime.now(timezone.utc)
    elif new_status == TicketStatus.CLOSED:
        ticket.closed_at = datetime.now(timezone.utc)

    await db.commit()
    return {"success": True, "data": TicketResponse.model_validate(ticket)}


@router.post("/tickets/{ticket_id}/close")
async def close_ticket(
    ticket_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Ticket).where(Ticket.id == ticket_id, Ticket.is_active == True))
    ticket = result.scalar_one_or_none()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    ticket.status = TicketStatus.CLOSED
    ticket.closed_at = datetime.now(timezone.utc)
    ticket.updated_at = datetime.now(timezone.utc)
    await db.commit()

    return {"success": True, "data": TicketResponse.model_validate(ticket)}


# --- VISITS ---

@router.get("/visits")
async def list_visits(
    ticket_id: UUID | None = None,
    engineer_id: UUID | None = None,
    status: str | None = None,
    limit: int = Query(50, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
):
    query = select(Visit).where(Visit.is_active == True)
    if ticket_id:
        query = query.where(Visit.ticket_id == ticket_id)
    if engineer_id:
        query = query.where(Visit.engineer_id == engineer_id)
    if status:
        query = query.where(Visit.status == status)

    query = query.order_by(Visit.created_at.desc()).offset(offset).limit(limit)
    result = await db.execute(query)
    visits = result.scalars().all()

    return {"success": True, "data": [VisitResponse.model_validate(v) for v in visits]}


@router.post("/visits")
async def create_visit(
    body: VisitCreate,
    db: AsyncSession = Depends(get_db),
):
    count = (await db.execute(select(func.count()).select_from(Visit))).scalar() or 0
    visit_number = f"VIS-{count + 1:06d}"

    visit = Visit(
        visit_number=visit_number,
        ticket_id=body.ticket_id,
        engineer_id=body.engineer_id,
        planned_start=body.planned_start,
        status=VisitStatus.PLANNED,
    )
    db.add(visit)
    await db.commit()
    await db.refresh(visit)

    return {"success": True, "data": VisitResponse.model_validate(visit)}


@router.post("/visits/{visit_id}/start")
async def start_visit(
    visit_id: UUID,
    body: VisitCheckin,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Visit).where(Visit.id == visit_id, Visit.is_active == True))
    visit = result.scalar_one_or_none()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    visit.status = VisitStatus.ARRIVED
    visit.actual_start = datetime.now(timezone.utc)
    visit.gps_checkin_lat = body.lat
    visit.gps_checkin_lon = body.lon
    visit.updated_at = datetime.now(timezone.utc)
    await db.commit()

    return {"success": True, "data": VisitResponse.model_validate(visit)}


@router.post("/visits/{visit_id}/finish")
async def finish_visit(
    visit_id: UUID,
    body: VisitCheckin,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Visit).where(Visit.id == visit_id, Visit.is_active == True))
    visit = result.scalar_one_or_none()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    now = datetime.now(timezone.utc)
    visit.status = VisitStatus.COMPLETED
    visit.actual_finish = now
    visit.gps_checkout_lat = body.lat
    visit.gps_checkout_lon = body.lon
    visit.updated_at = now

    if visit.actual_start:
        visit.work_minutes = int((now - visit.actual_start).total_seconds() / 60)

    await db.commit()
    return {"success": True, "data": VisitResponse.model_validate(visit)}


@router.post("/visits/{visit_id}/materials")
async def add_material(
    visit_id: UUID,
    body: VisitMaterialCreate,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Visit).where(Visit.id == visit_id, Visit.is_active == True))
    visit = result.scalar_one_or_none()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    material = VisitMaterial(
        visit_id=visit_id,
        item_code=body.item_code,
        item_name=body.item_name,
        serial_number=body.serial_number,
        quantity=body.quantity,
        uom=body.uom,
    )
    db.add(material)
    await db.commit()

    return {"success": True, "message": "Material added"}


# --- MAINTENANCE ---

@router.get("/maintenance")
async def list_maintenance_plans(
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(MaintenancePlan).where(MaintenancePlan.is_active == True))
    plans = result.scalars().all()
    return {"success": True, "data": plans}


@router.post("/maintenance")
async def create_maintenance_plan(
    body: MaintenancePlanCreate,
    db: AsyncSession = Depends(get_db),
):
    plan = MaintenancePlan(
        object_id=body.object_id,
        customer_id=body.customer_id,
        name=body.name,
        frequency=body.frequency,
        next_due_date=body.next_due_date,
    )
    db.add(plan)
    await db.commit()

    return {"success": True, "data": plan}


# --- WARRANTY ---

@router.get("/warranty")
async def list_warranty_cases(
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(WarrantyCase).order_by(WarrantyCase.created_at.desc()))
    cases = result.scalars().all()
    return {"success": True, "data": cases}
