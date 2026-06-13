from datetime import datetime, timedelta, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update
from app.models.ticket import (
    Ticket, TicketStatus, TicketPriority, SLAEvent,
    SLA_HOURS,
)
import nats
import json
import logging

logger = logging.getLogger(__name__)


def calculate_sla_deadlines(priority: TicketPriority, created_at: datetime) -> dict:
    hours = SLA_HOURS.get(priority.value, SLA_HOURS["medium"])
    return {
        "sla_response_due": created_at + timedelta(hours=hours["response"]),
        "sla_arrival_due": created_at + timedelta(hours=hours["arrival"]),
        "sla_resolution_due": created_at + timedelta(hours=hours["resolution"]),
    }


SLA_PAUSABLE_STATUSES = {TicketStatus.WAITING_PARTS}


async def pause_sla(db: AsyncSession, ticket: Ticket):
    if ticket.status in SLA_PAUSABLE_STATUSES and ticket.sla_paused_at is None:
        ticket.sla_paused_at = datetime.now(timezone.utc)
        event = SLAEvent(
            ticket_id=ticket.id,
            event_type="paused",
            timer_type="resolution",
            details=f"Paused in status {ticket.status.value}",
        )
        db.add(event)
        await db.commit()


async def resume_sla(db: AsyncSession, ticket: Ticket):
    if ticket.sla_paused_at is not None:
        paused_duration = (datetime.now(timezone.utc) - ticket.sla_paused_at).total_seconds() / 60
        ticket.sla_pause_minutes = (ticket.sla_pause_minutes or 0) + int(paused_duration)
        ticket.sla_paused_at = None

        if ticket.sla_resolution_due:
            ticket.sla_resolution_due = ticket.sla_resolution_due + timedelta(minutes=paused_duration)

        event = SLAEvent(
            ticket_id=ticket.id,
            event_type="resumed",
            timer_type="resolution",
            details=f"Resumed, paused for {int(paused_duration)} minutes",
        )
        db.add(event)
        await db.commit()


async def check_sla_breaches(db: AsyncSession, nats_client):
    now = datetime.now(timezone.utc)

    result = await db.execute(
        select(Ticket).where(
            Ticket.is_active == True,
            Ticket.status.notin_([TicketStatus.CLOSED, TicketStatus.CANCELLED, TicketStatus.RESOLVED]),
            Ticket.sla_paused_at.is_(None),
        )
    )
    tickets = result.scalars().all()

    breaches = []

    for ticket in tickets:
        if not ticket.sla_response_breached and ticket.sla_response_due and now > ticket.sla_response_due:
            ticket.sla_response_breached = True
            event = SLAEvent(
                ticket_id=ticket.id,
                event_type="breached",
                timer_type="response",
                details=f"Response SLA breached at {now.isoformat()}",
            )
            db.add(event)
            breaches.append({"ticket_id": str(ticket.id), "ticket_number": ticket.ticket_number, "type": "response", "priority": ticket.priority.value})

        if not ticket.sla_arrival_breached and ticket.sla_arrival_due and now > ticket.sla_arrival_due:
            ticket.sla_arrival_breached = True
            event = SLAEvent(
                ticket_id=ticket.id,
                event_type="breached",
                timer_type="arrival",
                details=f"Arrival SLA breached at {now.isoformat()}",
            )
            db.add(event)
            breaches.append({"ticket_id": str(ticket.id), "ticket_number": ticket.ticket_number, "type": "arrival", "priority": ticket.priority.value})

        if not ticket.sla_resolution_breached and ticket.sla_resolution_due and now > ticket.sla_resolution_due:
            ticket.sla_resolution_breached = True
            event = SLAEvent(
                ticket_id=ticket.id,
                event_type="breached",
                timer_type="resolution",
                details=f"Resolution SLA breached at {now.isoformat()}",
            )
            db.add(event)
            breaches.append({"ticket_id": str(ticket.id), "ticket_number": ticket.ticket_number, "type": "resolution", "priority": ticket.priority.value})

    if breaches:
        await db.commit()
        for breach in breaches:
            try:
                await nats_client.publish(
                    "fsm.sla.breached",
                    json.dumps(breach).encode(),
                )
            except Exception as e:
                logger.error(f"Failed to publish SLA breach event: {e}")

    return breaches
