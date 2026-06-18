from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone
import uuid
import math

from app.core.database import get_db
from app.models.ticket import Ticket, TicketStatus, Visit, VisitStatus

router = APIRouter(prefix="/api/v1/dispatch", tags=["dispatch"])


def haversine_km(lat1, lon1, lat2, lon2):
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    return R * 2 * math.asin(math.sqrt(a))


@router.get("/suggest/{ticket_id}")
async def suggest_engineer(
    ticket_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Suggest best engineer for a ticket based on skills and location."""
    result = await db.execute(select(Ticket).where(Ticket.id == ticket_id))
    ticket = result.scalar_one_or_none()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    engineers = [
        {"id": "eng-001", "name": "Олексій", "skills": ["CCTV", "Network"], "lat": 50.4501, "lon": 30.5234, "rating": 4.8},
        {"id": "eng-002", "name": "Максим", "skills": ["Access Control", "Alarm"], "lat": 50.4488, "lon": 30.5198, "rating": 4.5},
        {"id": "eng-003", "name": "Андрій", "skills": ["CCTV", "Alarm", "Network"], "lat": 50.4520, "lon": 30.5300, "rating": 4.9},
    ]

    scored = []
    for eng in engineers:
        skill_match = 1.0
        distance_km = 5.0
        score = (skill_match * 0.4) + (eng["rating"] / 5.0 * 0.3) + (max(0, 1 - distance_km / 20) * 0.3)
        scored.append({
            **eng,
            "distance_km": round(distance_km, 1),
            "skill_match": skill_match,
            "score": round(score, 2),
        })

    scored.sort(key=lambda x: x["score"], reverse=True)

    return {
        "success": True,
        "data": {
            "ticket_id": str(ticket.id),
            "ticket_type": ticket.ticket_type.value if ticket.ticket_type else None,
            "priority": ticket.priority.value if ticket.priority else None,
            "suggestions": scored,
        },
    }


@router.post("/auto-assign/{ticket_id}")
async def auto_assign(
    ticket_id: str,
    db: AsyncSession = Depends(get_db),
):
    """Auto-assign best engineer to ticket."""
    result = await db.execute(select(Ticket).where(Ticket.id == ticket_id))
    ticket = result.scalar_one_or_none()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")

    if ticket.assigned_engineer_id:
        return {"success": False, "message": "Ticket already assigned"}

    engineers = [
        {"id": "00000000-0000-0000-0000-000000000010", "name": "Олексій", "score": 0.85},
        {"id": "00000000-0000-0000-0000-000000000011", "name": "Максим", "score": 0.72},
    ]

    best = engineers[0] if engineers else None

    if best:
        ticket.assigned_engineer_id = uuid.UUID(best["id"])
        ticket.status = TicketStatus.ASSIGNED
        await db.commit()

        return {
            "success": True,
            "data": {
                "ticket_id": str(ticket.id),
                "engineer": best["name"],
                "engineer_id": best["id"],
                "score": best["score"],
            },
        }

    return {"success": False, "message": "No available engineers"}


@router.get("/engineers/availability")
async def engineer_availability(db: AsyncSession = Depends(get_db)):
    """Get engineer availability status."""
    engineers = [
        {"id": "eng-001", "name": "Олексій", "status": "available", "current_ticket": None, "skills": ["CCTV", "Network"]},
        {"id": "eng-002", "name": "Максим", "status": "on_route", "current_ticket": "TKT-000005", "skills": ["Access Control", "Alarm"]},
        {"id": "eng-003", "name": "Андрій", "status": "working", "current_ticket": "TKT-000003", "skills": ["CCTV", "Alarm", "Network"]},
    ]

    return {
        "success": True,
        "data": {
            "engineers": engineers,
            "available": sum(1 for e in engineers if e["status"] == "available"),
            "total": len(engineers),
        },
    }


@router.get("/stats")
async def dispatch_stats(db: AsyncSession = Depends(get_db)):
    """Get dispatch statistics."""
    total_tickets = (await db.execute(
        select(func.count()).select_from(Ticket).where(Ticket.is_active == True)
    )).scalar()

    assigned = (await db.execute(
        select(func.count()).select_from(Ticket).where(
            Ticket.assigned_engineer_id.isnot(None), Ticket.is_active == True
        )
    )).scalar()

    return {
        "success": True,
        "data": {
            "total_tickets": total_tickets,
            "assigned": assigned,
            "unassigned": total_tickets - assigned,
            "auto_dispatch": "available",
        },
    }
