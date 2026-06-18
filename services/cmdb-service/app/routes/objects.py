from datetime import datetime, timezone, date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from uuid import UUID

from app.core.database import get_db
from app.models.equipment import (
    SecurityObject, ObjectStatus,
    Building, Floor, Room,
    Vendor, EquipmentType,
    Equipment, EquipmentStatus,
    EquipmentRelation, RelationType,
)
from app.schemas.equipment import (
    ObjectCreate, ObjectResponse,
    VendorCreate,
    EquipmentTypeCreate,
    EquipmentCreate, EquipmentResponse,
    RelationCreate,
    InstallEquipment,
)

router = APIRouter(prefix="/api/v1", tags=["cmdb"])


# --- OBJECTS ---

@router.get("/objects")
async def list_objects(
    customer_id: UUID | None = None,
    status: str | None = None,
    limit: int = Query(50, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
):
    query = select(SecurityObject).where(SecurityObject.is_active == True)
    if customer_id:
        query = query.where(SecurityObject.customer_id == customer_id)
    if status:
        query = query.where(SecurityObject.status == status)

    query = query.order_by(SecurityObject.created_at.desc()).offset(offset).limit(limit)
    result = await db.execute(query)
    objects = result.scalars().all()

    count_q = select(func.count()).select_from(SecurityObject).where(SecurityObject.is_active == True)
    total = (await db.execute(count_q)).scalar() or 0

    return {
        "success": True,
        "data": [ObjectResponse.model_validate(o) for o in objects],
        "total": total,
    }


@router.post("/objects")
async def create_object(
    body: ObjectCreate,
    db: AsyncSession = Depends(get_db),
):
    count = (await db.execute(select(func.count()).select_from(SecurityObject))).scalar() or 0
    obj = SecurityObject(
        object_code=f"OBJ-{count + 1:06d}",
        customer_id=body.customer_id,
        name=body.name,
        address=body.address,
        gps_lat=body.gps_lat,
        gps_lon=body.gps_lon,
        object_type=body.object_type,
        service_level=body.service_level,
        notes=body.notes,
    )
    db.add(obj)
    await db.commit()
    await db.refresh(obj)

    return {"success": True, "data": ObjectResponse.model_validate(obj)}


@router.get("/objects/{object_id}")
async def get_object(object_id: UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(SecurityObject).where(SecurityObject.id == object_id, SecurityObject.is_active == True))
    obj = result.scalar_one_or_none()
    if not obj:
        raise HTTPException(status_code=404, detail="Object not found")

    equip_result = await db.execute(
        select(Equipment).where(Equipment.object_id == object_id, Equipment.is_active == True)
    )
    equipment = equip_result.scalars().all()

    return {
        "success": True,
        "data": {
            **ObjectResponse.model_validate(obj).model_dump(),
            "equipment_count": len(equipment),
        },
    }


@router.get("/objects/{object_id}/equipment")
async def get_object_equipment(
    object_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Equipment).where(Equipment.object_id == object_id, Equipment.is_active == True)
    )
    equipment = result.scalars().all()
    return {"success": True, "data": [EquipmentResponse.model_validate(e) for e in equipment]}


@router.get("/objects/{object_id}/timeline")
async def get_object_timeline(
    object_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    obj_result = await db.execute(select(SecurityObject).where(SecurityObject.id == object_id))
    obj = obj_result.scalar_one_or_none()
    if not obj:
        raise HTTPException(status_code=404, detail="Object not found")

    equip_result = await db.execute(
        select(Equipment).where(Equipment.object_id == object_id, Equipment.is_active == True)
    )
    equipment = equip_result.scalars().all()

    timeline = []
    timeline.append({"type": "object_created", "date": obj.created_at.isoformat(), "description": f"Object {obj.object_code} created"})
    for eq in equipment:
        if eq.install_date:
            timeline.append({"type": "equipment_installed", "date": eq.install_date.isoformat(), "description": f"Equipment {eq.equipment_code} ({eq.model}) installed"})
    timeline.sort(key=lambda x: x["date"], reverse=True)

    return {"success": True, "data": timeline}


# --- VENDORS ---

@router.get("/vendors")
async def list_vendors(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Vendor).where(Vendor.is_active == True))
    vendors = result.scalars().all()
    return {"success": True, "data": vendors}


@router.post("/vendors")
async def create_vendor(body: VendorCreate, db: AsyncSession = Depends(get_db)):
    vendor = Vendor(name=body.name, code=body.code, website=body.website, support_email=body.support_email, support_phone=body.support_phone)
    db.add(vendor)
    await db.commit()
    return {"success": True, "data": vendor}


# --- EQUIPMENT TYPES ---

@router.get("/equipment-types")
async def list_equipment_types(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(EquipmentType).where(EquipmentType.is_active == True))
    types = result.scalars().all()
    return {"success": True, "data": types}


@router.post("/equipment-types")
async def create_equipment_type(body: EquipmentTypeCreate, db: AsyncSession = Depends(get_db)):
    et = EquipmentType(name=body.name, code=body.code, category=body.category, parent_id=body.parent_id)
    db.add(et)
    await db.commit()
    return {"success": True, "data": et}


# --- EQUIPMENT ---

@router.get("/equipment")
async def list_equipment(
    object_id: UUID | None = None,
    status: str | None = None,
    limit: int = Query(50, le=200),
    offset: int = Query(0, ge=0),
    db: AsyncSession = Depends(get_db),
):
    query = select(Equipment).where(Equipment.is_active == True)
    if object_id:
        query = query.where(Equipment.object_id == object_id)
    if status:
        query = query.where(Equipment.status == status)

    query = query.order_by(Equipment.created_at.desc()).offset(offset).limit(limit)
    result = await db.execute(query)
    equipment = result.scalars().all()

    return {"success": True, "data": [EquipmentResponse.model_validate(e) for e in equipment]}


@router.post("/equipment")
async def create_equipment(
    body: EquipmentCreate,
    db: AsyncSession = Depends(get_db),
):
    count = (await db.execute(select(func.count()).select_from(Equipment))).scalar() or 0
    eq = Equipment(
        equipment_code=f"CI-{count + 1:06d}",
        object_id=body.object_id,
        room_id=body.room_id,
        equipment_type_id=body.equipment_type_id,
        vendor_id=body.vendor_id,
        model=body.model,
        serial_number=body.serial_number,
        firmware_version=body.firmware_version,
        ip_address=body.ip_address,
        mac_address=body.mac_address,
        install_date=body.install_date,
        warranty_end_date=body.warranty_end_date,
        status=EquipmentStatus(body.status),
        notes=body.notes,
    )
    db.add(eq)
    await db.commit()
    await db.refresh(eq)

    return {"success": True, "data": EquipmentResponse.model_validate(eq)}


@router.post("/equipment/install")
async def install_equipment(
    body: InstallEquipment,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Equipment).where(Equipment.id == body.equipment_id))
    eq = result.scalar_one_or_none()
    if not eq:
        raise HTTPException(status_code=404, detail="Equipment not found")

    eq.object_id = body.object_id
    eq.room_id = body.room_id
    eq.status = EquipmentStatus.INSTALLED
    eq.install_date = body.install_date or date.today()
    if body.ip_address:
        eq.ip_address = body.ip_address
    eq.updated_at = datetime.now(timezone.utc)

    await db.commit()
    return {"success": True, "data": EquipmentResponse.model_validate(eq)}


# --- RELATIONS ---

@router.get("/topology/{object_id}")
async def get_topology(
    object_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    equip_result = await db.execute(
        select(Equipment.id).where(Equipment.object_id == object_id, Equipment.is_active == True)
    )
    equip_ids = [row[0] for row in equip_result.all()]

    if not equip_ids:
        return {"success": True, "data": {"nodes": [], "edges": []}}

    rel_result = await db.execute(
        select(EquipmentRelation).where(
            EquipmentRelation.source_equipment_id.in_(equip_ids),
            EquipmentRelation.is_active == True,
        )
    )
    relations = rel_result.scalars().all()

    nodes = [{"id": str(eid)} for eid in equip_ids]
    edges = [
        {
            "source": str(r.source_equipment_id),
            "target": str(r.target_equipment_id),
            "type": r.relation_type.value,
            "port": r.port_label,
        }
        for r in relations
    ]

    return {"success": True, "data": {"nodes": nodes, "edges": edges}}


@router.post("/topology")
async def create_relation(
    body: RelationCreate,
    db: AsyncSession = Depends(get_db),
):
    rel = EquipmentRelation(
        source_equipment_id=body.source_equipment_id,
        target_equipment_id=body.target_equipment_id,
        relation_type=RelationType(body.relation_type),
        port_label=body.port_label,
        notes=body.notes,
    )
    db.add(rel)
    await db.commit()

    return {"success": True, "message": "Relation created"}
