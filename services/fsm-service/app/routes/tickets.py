from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID
import json
import math

from app.auth import get_current_user
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
from app.core.config import settings

router = APIRouter(prefix="/api/v1", tags=["tickets"])


def haversine_km(lat1, lon1, lat2, lon2):
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    return R * 2 * math.asin(math.sqrt(a))


# --- TICKETS ---

@router.get("/tickets")
async def list_tickets(
    status: str | None = None,
    priority: str | None = None,
    assigned_engineer_id: UUID | None = None,
    limit: int = Query(50, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
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
    current_user: dict = Depends(get_current_user),
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

    # Notify Telegram directly
    print(f"[NOTIFY] Sending Telegram notification for {ticket.ticket_number}", flush=True)
    try:
        import httpx
        if settings.telegram_bot_token:
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.post(
                    f"https://api.telegram.org/bot{settings.telegram_bot_token}/sendMessage",
                    json={
                        "chat_id": settings.telegram_chat_id,
                        "text": f"📋 Нова заявка!\n\nНомер: {ticket.ticket_number}\nПроблема: {ticket.title}\nПріоритет: {ticket.priority.value if hasattr(ticket.priority, 'value') else ticket.priority}",
                    }
                )
                print(f"[NOTIFY] Telegram response: {resp.status_code}", flush=True)
    except Exception as e:
        print(f"[NOTIFY] Error: {e}", flush=True)

    return {"success": True, "data": TicketResponse.model_validate(ticket)}


@router.get("/tickets/{ticket_id}")
async def get_ticket(ticket_id: UUID, db: AsyncSession = Depends(get_db), current_user: dict = Depends(get_current_user)):
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
    current_user: dict = Depends(get_current_user),
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
    current_user: dict = Depends(get_current_user),
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
    current_user: dict = Depends(get_current_user),
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
    current_user: dict = Depends(get_current_user),
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
    current_user: dict = Depends(get_current_user),
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
    current_user: dict = Depends(get_current_user),
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
    current_user: dict = Depends(get_current_user),
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

    if all([visit.gps_checkin_lat, visit.gps_checkin_lon, body.lat, body.lon]):
        distance = haversine_km(visit.gps_checkin_lat, visit.gps_checkin_lon, body.lat, body.lon)
        visit.notes = (visit.notes or "") + f"\nTravel distance: {distance:.2f} km"

    await db.commit()
    return {"success": True, "data": VisitResponse.model_validate(visit)}


@router.post("/visits/{visit_id}/materials")
async def add_material(
    visit_id: UUID,
    body: VisitMaterialCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
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
    current_user: dict = Depends(get_current_user),
):
    result = await db.execute(select(MaintenancePlan).where(MaintenancePlan.is_active == True))
    plans = result.scalars().all()
    return {"success": True, "data": plans}


@router.post("/maintenance")
async def create_maintenance_plan(
    body: MaintenancePlanCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
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
    current_user: dict = Depends(get_current_user),
):
    result = await db.execute(select(WarrantyCase).order_by(WarrantyCase.created_at.desc()))
    cases = result.scalars().all()
    return {"success": True, "data": cases}


# --- PHOTOS ---

@router.post("/visits/{visit_id}/photos")
async def upload_photo(
    visit_id: UUID,
    photo_type: str = Query("problem"),
    caption: str = Query(None),
    gps_lat: float = Query(None),
    gps_lon: float = Query(None),
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    result = await db.execute(select(Visit).where(Visit.id == visit_id, Visit.is_active == True))
    visit = result.scalar_one_or_none()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    import uuid
    file_id = uuid.uuid4()
    file_path = f"visits/{visit_id}/{file_id}_{file.filename}"

    photo = VisitPhoto(
        visit_id=visit_id,
        photo_type=photo_type,
        file_id=file_id,
        file_path=file_path,
        caption=caption,
        gps_lat=gps_lat,
        gps_lon=gps_lon,
    )
    db.add(photo)
    await db.commit()

    return {"success": True, "data": {"id": str(photo.id), "file_path": file_path}}


@router.get("/visits/{visit_id}/photos")
async def list_photos(
    visit_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
):
    result = await db.execute(
        select(VisitPhoto).where(VisitPhoto.visit_id == visit_id).order_by(VisitPhoto.created_at)
    )
    photos = result.scalars().all()
    return {"success": True, "data": photos}
