from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone
import uuid

from app.core.database import get_db
from app.models.equipment import ConfigBackup, ConfigBackupSchedule, Equipment

router = APIRouter(prefix="/api/v1/backups", tags=["backups"])


@router.get("/configs")
async def list_config_backups(
    equipment_id: str = None,
    object_id: str = None,
    limit: int = Query(50, le=200),
    db: AsyncSession = Depends(get_db),
):
    query = select(ConfigBackup)
    if equipment_id:
        query = query.where(ConfigBackup.equipment_id == equipment_id)
    if object_id:
        query = query.where(ConfigBackup.object_id == object_id)
    query = query.order_by(ConfigBackup.created_at.desc()).limit(limit)

    result = await db.execute(query)
    backups = result.scalars().all()
    return {"success": True, "data": backups}


@router.post("/configs")
async def create_config_backup(data: dict, db: AsyncSession = Depends(get_db)):
    backup = ConfigBackup(
        id=uuid.uuid4(),
        equipment_id=uuid.UUID(data.get("equipment_id")),
        object_id=uuid.UUID(data["object_id"]) if data.get("object_id") else None,
        backup_type=data.get("backup_type", "full"),
        file_path=data.get("file_path", ""),
        file_size_bytes=data.get("file_size_bytes"),
        checksum_sha256=data.get("checksum_sha256"),
        firmware_version=data.get("firmware_version"),
        status=data.get("status", "success"),
        triggered_by=data.get("triggered_by", "manual"),
    )
    db.add(backup)
    await db.commit()
    return {"success": True, "data": {"id": str(backup.id)}}


@router.get("/configs/{backup_id}")
async def get_config_backup(backup_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(ConfigBackup).where(ConfigBackup.id == backup_id))
    backup = result.scalar_one_or_none()
    if not backup:
        raise HTTPException(status_code=404, detail="Backup not found")
    return {"success": True, "data": backup}


@router.get("/configs/{backup_id}/diff")
async def get_config_diff(backup_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(ConfigBackup).where(ConfigBackup.id == backup_id))
    backup = result.scalar_one_or_none()
    if not backup:
        raise HTTPException(status_code=404, detail="Backup not found")
    return {"success": True, "data": {"diff": backup.config_diff}}


@router.post("/schedules")
async def create_backup_schedule(data: dict, db: AsyncSession = Depends(get_db)):
    schedule = ConfigBackupSchedule(
        id=uuid.uuid4(),
        equipment_id=uuid.UUID(data.get("equipment_id")),
        frequency=data.get("frequency", "weekly"),
        next_run=datetime.fromisoformat(data.get("next_run")),
    )
    db.add(schedule)
    await db.commit()
    return {"success": True, "data": {"id": str(schedule.id)}}


@router.get("/schedules")
async def list_backup_schedules(
    equipment_id: str = None,
    db: AsyncSession = Depends(get_db),
):
    query = select(ConfigBackupSchedule).where(ConfigBackupSchedule.is_active == True)
    if equipment_id:
        query = query.where(ConfigBackupSchedule.equipment_id == equipment_id)
    result = await db.execute(query)
    schedules = result.scalars().all()
    return {"success": True, "data": schedules}


@router.get("/stats")
async def get_backup_stats(db: AsyncSession = Depends(get_db)):
    total = (await db.execute(select(func.count()).select_from(ConfigBackup))).scalar()
    success = (await db.execute(
        select(func.count()).select_from(ConfigBackup).where(ConfigBackup.status == "success")
    )).scalar()
    failed = (await db.execute(
        select(func.count()).select_from(ConfigBackup).where(ConfigBackup.status == "failed")
    )).scalar()

    return {
        "success": True,
        "data": {
            "total": total,
            "success": success,
            "failed": failed,
            "schedules": (await db.execute(
                select(func.count()).select_from(ConfigBackupSchedule).where(ConfigBackupSchedule.is_active == True)
            )).scalar(),
        },
    }
