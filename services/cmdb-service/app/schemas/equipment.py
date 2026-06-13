from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import datetime, date


class ObjectCreate(BaseModel):
    customer_id: UUID
    name: str
    address: Optional[str] = None
    gps_lat: Optional[float] = None
    gps_lon: Optional[float] = None
    object_type: Optional[str] = None
    service_level: str = "standard"
    notes: Optional[str] = None


class ObjectResponse(BaseModel):
    id: UUID
    object_code: str
    customer_id: UUID
    name: str
    address: Optional[str]
    gps_lat: Optional[float]
    gps_lon: Optional[float]
    object_type: Optional[str]
    service_level: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


class VendorCreate(BaseModel):
    name: str
    code: Optional[str] = None
    website: Optional[str] = None
    support_email: Optional[str] = None
    support_phone: Optional[str] = None


class EquipmentTypeCreate(BaseModel):
    name: str
    code: str
    category: str
    parent_id: Optional[UUID] = None


class EquipmentCreate(BaseModel):
    object_id: UUID
    room_id: Optional[UUID] = None
    equipment_type_id: UUID
    vendor_id: UUID
    model: str
    serial_number: Optional[str] = None
    firmware_version: Optional[str] = None
    ip_address: Optional[str] = None
    mac_address: Optional[str] = None
    install_date: Optional[date] = None
    warranty_end_date: Optional[date] = None
    status: str = "planned"
    notes: Optional[str] = None


class EquipmentResponse(BaseModel):
    id: UUID
    equipment_code: str
    object_id: UUID
    room_id: Optional[UUID]
    equipment_type_id: UUID
    vendor_id: UUID
    model: str
    serial_number: Optional[str]
    firmware_version: Optional[str]
    ip_address: Optional[str]
    mac_address: Optional[str]
    install_date: Optional[date]
    warranty_end_date: Optional[date]
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


class RelationCreate(BaseModel):
    source_equipment_id: UUID
    target_equipment_id: UUID
    relation_type: str
    port_label: Optional[str] = None
    notes: Optional[str] = None


class InstallEquipment(BaseModel):
    object_id: UUID
    room_id: Optional[UUID] = None
    equipment_id: UUID
    install_date: date = None
    ip_address: Optional[str] = None
