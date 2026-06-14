import uuid
import enum
from datetime import datetime, date, timezone
from sqlalchemy import (
    Column, String, Boolean, DateTime, Date, Integer, Text, Float,
    ForeignKey, Enum as SAEnum, UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID, INET, MACADDR
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class ObjectStatus(str, enum.Enum):
    ACTIVE = "active"
    SUSPENDED = "suspended"
    ARCHIVED = "archived"


class EquipmentStatus(str, enum.Enum):
    PLANNED = "planned"
    IN_STOCK = "in_stock"
    RESERVED = "reserved"
    INSTALLED = "installed"
    ACTIVE = "active"
    SERVICE = "service"
    REPAIR = "repair"
    REPLACED = "replaced"
    RETIRED = "retired"


class RelationType(str, enum.Enum):
    CONNECTED_TO = "connected_to"
    POWERED_BY = "powered_by"
    DEPENDS_ON = "depends_on"
    INSTALLED_IN = "installed_in"
    BACKUP_OF = "backup_of"


class SecurityObject(Base):
    __tablename__ = "objects"
    __table_args__ = {"schema": "cmdb"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    object_code = Column(String(20), unique=True, nullable=False, index=True)
    customer_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    address = Column(Text, nullable=True)
    gps_lat = Column(Float, nullable=True)
    gps_lon = Column(Float, nullable=True)
    object_type = Column(String(50), nullable=True)  # shop, office, warehouse, apartment, factory, school
    service_level = Column(String(20), default="standard")  # basic, standard, premium, platinum
    status = Column(SAEnum(ObjectStatus), nullable=False, default=ObjectStatus.ACTIVE)
    notes = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    created_by = Column(UUID(as_uuid=True), nullable=True)
    is_active = Column(Boolean, default=True)


class Building(Base):
    __tablename__ = "buildings"
    __table_args__ = {"schema": "cmdb"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    object_id = Column(UUID(as_uuid=True), ForeignKey("cmdb.objects.id"), nullable=False)
    name = Column(String(255), nullable=False)
    floors_count = Column(Integer, default=1)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    is_active = Column(Boolean, default=True)


class Floor(Base):
    __tablename__ = "floors"
    __table_args__ = {"schema": "cmdb"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    building_id = Column(UUID(as_uuid=True), ForeignKey("cmdb.buildings.id"), nullable=False)
    level = Column(Integer, nullable=False)
    name = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    is_active = Column(Boolean, default=True)


class Room(Base):
    __tablename__ = "rooms"
    __table_args__ = {"schema": "cmdb"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    floor_id = Column(UUID(as_uuid=True), ForeignKey("cmdb.floors.id"), nullable=False)
    name = Column(String(255), nullable=False)
    room_type = Column(String(50), nullable=True)
    area_sqm = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    is_active = Column(Boolean, default=True)


class Vendor(Base):
    __tablename__ = "vendors"
    __table_args__ = {"schema": "cmdb"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), unique=True, nullable=False)
    code = Column(String(50), unique=True, nullable=True)
    website = Column(String(500), nullable=True)
    support_email = Column(String(255), nullable=True)
    support_phone = Column(String(50), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    is_active = Column(Boolean, default=True)


class EquipmentType(Base):
    __tablename__ = "equipment_types"
    __table_args__ = {"schema": "cmdb"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    code = Column(String(50), unique=True, nullable=False)
    category = Column(String(100), nullable=False)  # CCTV, Network, ACS, Alarm, Server, UPS
    parent_id = Column(UUID(as_uuid=True), ForeignKey("cmdb.equipment_types.id"), nullable=True)
    checklist_template_id = Column(UUID(as_uuid=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    is_active = Column(Boolean, default=True)


class Equipment(Base):
    __tablename__ = "equipment"
    __table_args__ = {"schema": "cmdb"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    equipment_code = Column(String(20), unique=True, nullable=False, index=True)
    object_id = Column(UUID(as_uuid=True), ForeignKey("cmdb.objects.id"), nullable=False, index=True)
    room_id = Column(UUID(as_uuid=True), ForeignKey("cmdb.rooms.id"), nullable=True)
    equipment_type_id = Column(UUID(as_uuid=True), ForeignKey("cmdb.equipment_types.id"), nullable=False)
    vendor_id = Column(UUID(as_uuid=True), ForeignKey("cmdb.vendors.id"), nullable=False)
    model = Column(String(255), nullable=False)
    serial_number = Column(String(255), unique=True, nullable=True, index=True)
    firmware_version = Column(String(100), nullable=True)
    ip_address = Column(INET, nullable=True)
    mac_address = Column(MACADDR, nullable=True)
    install_date = Column(Date, nullable=True)
    warranty_end_date = Column(Date, nullable=True)
    status = Column(SAEnum(EquipmentStatus), nullable=False, default=EquipmentStatus.PLANNED)
    lifecycle_project_id = Column(UUID(as_uuid=True), nullable=True)
    notes = Column(Text, nullable=True)

    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    created_by = Column(UUID(as_uuid=True), nullable=True)
    is_active = Column(Boolean, default=True)


class EquipmentRelation(Base):
    __tablename__ = "equipment_relations"
    __table_args__ = {"schema": "cmdb"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    source_equipment_id = Column(UUID(as_uuid=True), ForeignKey("cmdb.equipment.id"), nullable=False)
    target_equipment_id = Column(UUID(as_uuid=True), ForeignKey("cmdb.equipment.id"), nullable=False)
    relation_type = Column(SAEnum(RelationType), nullable=False)
    port_label = Column(String(50), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    is_active = Column(Boolean, default=True)


class PhotoDocumentation(Base):
    __tablename__ = "photo_documentation"
    __table_args__ = {"schema": "cmdb"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    object_id = Column(UUID(as_uuid=True), ForeignKey("cmdb.objects.id"), nullable=True, index=True)
    equipment_id = Column(UUID(as_uuid=True), ForeignKey("cmdb.equipment.id"), nullable=True, index=True)
    photo_type = Column(String(50), nullable=False)  # survey, installation, maintenance, problem, solution
    file_path = Column(String(500), nullable=False)
    file_id = Column(UUID(as_uuid=True), nullable=False)
    caption = Column(String(500), nullable=True)
    description = Column(Text, nullable=True)
    gps_lat = Column(Float, nullable=True)
    gps_lon = Column(Float, nullable=True)
    taken_at = Column(DateTime(timezone=True), nullable=True)
    visit_id = Column(UUID(as_uuid=True), nullable=True)  # link to FSM visit
    ticket_id = Column(UUID(as_uuid=True), nullable=True)  # link to FSM ticket
    uploaded_by = Column(UUID(as_uuid=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class ObjectTimeline(Base):
    __tablename__ = "object_timeline"
    __table_args__ = {"schema": "cmdb"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    object_id = Column(UUID(as_uuid=True), ForeignKey("cmdb.objects.id"), nullable=False, index=True)
    event_type = Column(String(50), nullable=False)  # created, updated, equipment_installed, equipment_removed, maintenance, inspection
    entity_type = Column(String(50), nullable=True)  # equipment, photo, ticket, visit
    entity_id = Column(UUID(as_uuid=True), nullable=True)
    description = Column(Text, nullable=True)
    metadata_json = Column(Text, nullable=True)  # JSON for extra data
    created_by = Column(UUID(as_uuid=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
