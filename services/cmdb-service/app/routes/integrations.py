from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone
import uuid

from app.core.database import get_db
from app.models.equipment import Equipment, SecurityObject

router = APIRouter(prefix="/api/v1/integrations", tags=["integrations"])


@router.get("/mikrotik/status/{equipment_id}")
async def mikrotik_status(equipment_id: str, db: AsyncSession = Depends(get_db)):
    """Get MikroTik router status via API."""
    result = await db.execute(select(Equipment).where(Equipment.id == equipment_id))
    equip = result.scalar_one_or_none()
    if not equip:
        raise HTTPException(status_code=404, detail="Equipment not found")

    return {
        "success": True,
        "data": {
            "equipment_id": str(equip.id),
            "model": equip.model,
            "ip_address": str(equip.ip_address) if equip.ip_address else None,
            "status": "offline",
            "message": "MikroTik API not configured. Set MIKROTIK_API_URL, MIKROTIK_USER, MIKROTIK_PASSWORD",
            "capabilities": [
                "interface_list",
                "firewall_rules",
                "dhcp_leases",
                "system_resources",
                "backup_config",
            ],
        },
    }


@router.post("/mikrotik/backup/{equipment_id}")
async def mikrotik_backup(equipment_id: str, db: AsyncSession = Depends(get_db)):
    """Backup MikroTik configuration."""
    result = await db.execute(select(Equipment).where(Equipment.id == equipment_id))
    equip = result.scalar_one_or_none()
    if not equip:
        raise HTTPException(status_code=404, detail="Equipment not found")

    return {
        "success": True,
        "message": "MikroTik backup not configured",
        "data": {"equipment_id": str(equip.id), "status": "not_configured"},
    }


@router.get("/unifi/devices/{object_id}")
async def unifi_devices(object_id: str, db: AsyncSession = Depends(get_db)):
    """Get UniFi devices for an object."""
    result = await db.execute(select(SecurityObject).where(SecurityObject.id == object_id))
    obj = result.scalar_one_or_none()
    if not obj:
        raise HTTPException(status_code=404, detail="Object not found")

    return {
        "success": True,
        "data": {
            "object_id": str(obj.id),
            "devices": [],
            "message": "UniFi API not configured. Set UNIFI_CONTROLLER_URL, UNIFI_API_KEY",
            "capabilities": [
                "device_list",
                "client_list",
                "network_stats",
                "device_restart",
                "firmware_update",
            ],
        },
    }


@router.get("/hikvision/status/{equipment_id}")
async def hikvision_status(equipment_id: str, db: AsyncSession = Depends(get_db)):
    """Get Hikvision camera status."""
    result = await db.execute(select(Equipment).where(Equipment.id == equipment_id))
    equip = result.scalar_one_or_none()
    if not equip:
        raise HTTPException(status_code=404, detail="Equipment not found")

    return {
        "success": True,
        "data": {
            "equipment_id": str(equip.id),
            "model": equip.model,
            "serial_number": equip.serial_number,
            "ip_address": str(equip.ip_address) if equip.ip_address else None,
            "status": "offline",
            "message": "Hikvision ISAPI not configured. Set HIKVISION_USER, HIKVISION_PASSWORD",
            "capabilities": [
                "device_info",
                "stream_status",
                "storage_status",
                "motion_detection",
                "firmware_version",
            ],
        },
    }


@router.post("/hikvision/reboot/{equipment_id}")
async def hikvision_reboot(equipment_id: str, db: AsyncSession = Depends(get_db)):
    """Reboot Hikvision camera."""
    result = await db.execute(select(Equipment).where(Equipment.id == equipment_id))
    equip = result.scalar_one_or_none()
    if not equip:
        raise HTTPException(status_code=404, detail="Equipment not found")

    return {
        "success": True,
        "message": "Hikvision API not configured",
        "data": {"equipment_id": str(equip.id), "status": "not_configured"},
    }


@router.get("/ajax/status/{equipment_id}")
async def ajax_status(equipment_id: str, db: AsyncSession = Depends(get_db)):
    """Get Ajax alarm system status."""
    result = await db.execute(select(Equipment).where(Equipment.id == equipment_id))
    equip = result.scalar_one_or_none()
    if not equip:
        raise HTTPException(status_code=404, detail="Equipment not found")

    return {
        "success": True,
        "data": {
            "equipment_id": str(equip.id),
            "model": equip.model,
            "status": "offline",
            "message": "Ajax API not configured. Set AJAX_API_TOKEN",
            "capabilities": [
                "hub_status",
                "device_list",
                "arm_disarm",
                "event_log",
                "battery_status",
            ],
        },
    }


@router.get("/stats")
async def integration_stats(db: AsyncSession = Depends(get_db)):
    """Get integration status summary."""
    return {
        "success": True,
        "data": {
            "mikrotik": {"status": "not_configured", "devices": 0},
            "unifi": {"status": "not_configured", "devices": 0},
            "hikvision": {"status": "not_configured", "devices": 0},
            "ajax": {"status": "not_configured", "devices": 0},
            "message": "Configure API credentials in environment variables to enable integrations",
        },
    }
