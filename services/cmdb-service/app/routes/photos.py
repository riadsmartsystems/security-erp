from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone
import uuid

from app.core.database import get_db
from app.models.equipment import PhotoDocumentation, ObjectTimeline, SecurityObject, Equipment

router = APIRouter(prefix="/api/v1/photos", tags=["photos"])


@router.post("/objects/{object_id}")
async def upload_object_photo(
    object_id: str,
    photo_type: str = Query("survey"),
    caption: str = Query(None),
    description: str = Query(None),
    gps_lat: float = Query(None),
    gps_lon: float = Query(None),
    visit_id: str = Query(None),
    ticket_id: str = Query(None),
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(SecurityObject).where(SecurityObject.id == object_id))
    obj = result.scalar_one_or_none()
    if not obj:
        raise HTTPException(status_code=404, detail="Object not found")

    file_id = uuid.uuid4()
    file_path = f"objects/{object_id}/{file_id}_{file.filename}"

    photo = PhotoDocumentation(
        id=uuid.uuid4(),
        object_id=uuid.UUID(object_id),
        photo_type=photo_type,
        file_path=file_path,
        file_id=file_id,
        caption=caption,
        description=description,
        gps_lat=gps_lat,
        gps_lon=gps_lon,
        visit_id=uuid.UUID(visit_id) if visit_id else None,
        ticket_id=uuid.UUID(ticket_id) if ticket_id else None,
    )
    db.add(photo)

    timeline = ObjectTimeline(
        id=uuid.uuid4(),
        object_id=uuid.UUID(object_id),
        event_type="photo_added",
        entity_type="photo",
        entity_id=photo.id,
        description=caption or f"Photo added: {photo_type}",
    )
    db.add(timeline)

    await db.commit()
    return {"success": True, "data": {"id": str(photo.id), "file_path": file_path}}


@router.get("/objects/{object_id}")
async def list_object_photos(
    object_id: str,
    photo_type: str = None,
    db: AsyncSession = Depends(get_db),
):
    try:
        obj_uuid = uuid.UUID(object_id)
    except ValueError:
        return {"success": True, "data": []}

    query = select(PhotoDocumentation).where(PhotoDocumentation.object_id == obj_uuid)
    if photo_type:
        query = query.where(PhotoDocumentation.photo_type == photo_type)
    query = query.order_by(PhotoDocumentation.created_at.desc())

    result = await db.execute(query)
    photos = result.scalars().all()
    return {"success": True, "data": photos}


@router.post("/equipment/{equipment_id}")
async def upload_equipment_photo(
    equipment_id: str,
    photo_type: str = Query("installation"),
    caption: str = Query(None),
    description: str = Query(None),
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Equipment).where(Equipment.id == equipment_id))
    equip = result.scalar_one_or_none()
    if not equip:
        raise HTTPException(status_code=404, detail="Equipment not found")

    file_id = uuid.uuid4()
    file_path = f"equipment/{equipment_id}/{file_id}_{file.filename}"

    photo = PhotoDocumentation(
        id=uuid.uuid4(),
        equipment_id=uuid.UUID(equipment_id),
        object_id=equip.object_id,
        photo_type=photo_type,
        file_path=file_path,
        file_id=file_id,
        caption=caption,
        description=description,
    )
    db.add(photo)

    if equip.object_id:
        timeline = ObjectTimeline(
            id=uuid.uuid4(),
            object_id=equip.object_id,
            event_type="equipment_photo_added",
            entity_type="photo",
            entity_id=photo.id,
            description=caption or f"Equipment photo: {equip.model}",
        )
        db.add(timeline)

    await db.commit()
    return {"success": True, "data": {"id": str(photo.id), "file_path": file_path}}


@router.get("/equipment/{equipment_id}")
async def list_equipment_photos(
    equipment_id: str,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(PhotoDocumentation)
        .where(PhotoDocumentation.equipment_id == equipment_id)
        .order_by(PhotoDocumentation.created_at.desc())
    )
    photos = result.scalars().all()
    return {"success": True, "data": photos}


@router.get("/timeline/{object_id}")
async def get_object_timeline(
    object_id: str,
    limit: int = Query(50, le=200),
    db: AsyncSession = Depends(get_db),
):
    try:
        obj_uuid = uuid.UUID(object_id)
    except ValueError:
        return {"success": True, "data": []}

    result = await db.execute(
        select(ObjectTimeline)
        .where(ObjectTimeline.object_id == obj_uuid)
        .order_by(ObjectTimeline.created_at.desc())
        .limit(limit)
    )
    timeline = result.scalars().all()
    return {"success": True, "data": timeline}
