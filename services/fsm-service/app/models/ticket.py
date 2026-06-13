import uuid
import enum
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, Integer, Text, Float, ForeignKey, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class TicketType(str, enum.Enum):
    INCIDENT = "incident"
    SERVICE_REQUEST = "service_request"
    PREVENTIVE_MAINTENANCE = "preventive_maintenance"
    INSTALLATION = "installation"
    WARRANTY = "warranty"
    INSPECTION = "inspection"
    EMERGENCY = "emergency"


class TicketPriority(str, enum.Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class TicketStatus(str, enum.Enum):
    NEW = "new"
    TRIAGE = "triage"
    ASSIGNED = "assigned"
    ACCEPTED = "accepted"
    ON_ROUTE = "on_route"
    WORKING = "working"
    WAITING_PARTS = "waiting_parts"
    RESOLVED = "resolved"
    CLOSED = "closed"
    CANCELLED = "cancelled"


class VisitStatus(str, enum.Enum):
    PLANNED = "planned"
    ACCEPTED = "accepted"
    ON_ROUTE = "on_route"
    ARRIVED = "arrived"
    WORKING = "working"
    COMPLETED = "completed"


SLA_HOURS = {
    "critical": {"response": 0.5, "arrival": 2, "resolution": 8},
    "high": {"response": 2, "arrival": 8, "resolution": 24},
    "medium": {"response": 8, "arrival": 24, "resolution": 72},
    "low": {"response": 24, "arrival": 168, "resolution": 168},
}


class Ticket(Base):
    __tablename__ = "tickets"
    __table_args__ = {"schema": "fsm"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ticket_number = Column(String(20), unique=True, nullable=False, index=True)
    customer_id = Column(UUID(as_uuid=True), nullable=False)
    object_id = Column(UUID(as_uuid=True), nullable=False)
    contract_id = Column(UUID(as_uuid=True), nullable=True)
    ticket_type = Column(SAEnum(TicketType), nullable=False, default=TicketType.INCIDENT)
    priority = Column(SAEnum(TicketPriority), nullable=False, default=TicketPriority.MEDIUM)
    status = Column(SAEnum(TicketStatus), nullable=False, default=TicketStatus.NEW)
    title = Column(String(500), nullable=False)
    description = Column(Text, nullable=True)
    assigned_engineer_id = Column(UUID(as_uuid=True), nullable=True)

    sla_response_due = Column(DateTime(timezone=True), nullable=True)
    sla_arrival_due = Column(DateTime(timezone=True), nullable=True)
    sla_resolution_due = Column(DateTime(timezone=True), nullable=True)
    sla_paused_at = Column(DateTime(timezone=True), nullable=True)
    sla_pause_minutes = Column(Integer, default=0)
    sla_response_breached = Column(Boolean, default=False)
    sla_arrival_breached = Column(Boolean, default=False)
    sla_resolution_breached = Column(Boolean, default=False)

    resolved_at = Column(DateTime(timezone=True), nullable=True)
    closed_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    created_by = Column(UUID(as_uuid=True), nullable=True)
    is_active = Column(Boolean, default=True)


class Visit(Base):
    __tablename__ = "visits"
    __table_args__ = {"schema": "fsm"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    visit_number = Column(String(20), unique=True, nullable=False)
    ticket_id = Column(UUID(as_uuid=True), ForeignKey("fsm.tickets.id"), nullable=False)
    engineer_id = Column(UUID(as_uuid=True), nullable=False)
    status = Column(SAEnum(VisitStatus), nullable=False, default=VisitStatus.PLANNED)
    planned_start = Column(DateTime(timezone=True), nullable=True)
    actual_start = Column(DateTime(timezone=True), nullable=True)
    actual_finish = Column(DateTime(timezone=True), nullable=True)
    gps_checkin_lat = Column(Float, nullable=True)
    gps_checkin_lon = Column(Float, nullable=True)
    gps_checkout_lat = Column(Float, nullable=True)
    gps_checkout_lon = Column(Float, nullable=True)
    travel_minutes = Column(Integer, nullable=True)
    work_minutes = Column(Integer, nullable=True)
    notes = Column(Text, nullable=True)
    customer_signature_file = Column(UUID(as_uuid=True), nullable=True)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    created_by = Column(UUID(as_uuid=True), nullable=True)
    is_active = Column(Boolean, default=True)


class VisitPhoto(Base):
    __tablename__ = "visit_photos"
    __table_args__ = {"schema": "fsm"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    visit_id = Column(UUID(as_uuid=True), ForeignKey("fsm.visits.id"), nullable=False)
    photo_type = Column(String(50), nullable=False)  # before, after, problem, equipment
    file_id = Column(UUID(as_uuid=True), nullable=False)
    file_path = Column(String(500), nullable=False)
    caption = Column(String(500), nullable=True)
    gps_lat = Column(Float, nullable=True)
    gps_lon = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(UUID(as_uuid=True), nullable=True)


class VisitMaterial(Base):
    __tablename__ = "visit_materials"
    __table_args__ = {"schema": "fsm"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    visit_id = Column(UUID(as_uuid=True), ForeignKey("fsm.visits.id"), nullable=False)
    item_code = Column(String(100), nullable=False)
    item_name = Column(String(255), nullable=False)
    serial_number = Column(String(255), nullable=True)
    quantity = Column(Float, nullable=False, default=1)
    uom = Column(String(50), default="pcs")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(UUID(as_uuid=True), nullable=True)


class SLAEvent(Base):
    __tablename__ = "sla_events"
    __table_args__ = {"schema": "fsm"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    ticket_id = Column(UUID(as_uuid=True), ForeignKey("fsm.tickets.id"), nullable=False)
    event_type = Column(String(50), nullable=False)  # started, paused, resumed, breached, resolved
    timer_type = Column(String(50), nullable=False)  # response, arrival, resolution
    occurred_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    details = Column(Text, nullable=True)


class MaintenancePlan(Base):
    __tablename__ = "maintenance_plans"
    __table_args__ = {"schema": "fsm"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    object_id = Column(UUID(as_uuid=True), nullable=False)
    customer_id = Column(UUID(as_uuid=True), nullable=False)
    name = Column(String(255), nullable=False)
    frequency = Column(String(50), nullable=False)  # monthly, quarterly, semi_annual, annual
    next_due_date = Column(DateTime(timezone=True), nullable=False)
    last_executed = Column(DateTime(timezone=True), nullable=True)
    checklist_template_id = Column(UUID(as_uuid=True), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class WarrantyCase(Base):
    __tablename__ = "warranty_cases"
    __table_args__ = {"schema": "fsm"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    case_number = Column(String(20), unique=True, nullable=False)
    ticket_id = Column(UUID(as_uuid=True), ForeignKey("fsm.tickets.id"), nullable=True)
    equipment_id = Column(UUID(as_uuid=True), nullable=False)
    customer_id = Column(UUID(as_uuid=True), nullable=False)
    description = Column(Text, nullable=False)
    status = Column(String(50), default="open")  # open, verified, approved, rejected, repair, replacement, closed
    resolution = Column(Text, nullable=True)
    manufacturer_claim = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    created_by = Column(UUID(as_uuid=True), nullable=True)
