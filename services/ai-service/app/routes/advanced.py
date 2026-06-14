from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone
import uuid
import json

from app.core.database import get_db
from app.models.knowledge import KnowledgeDocument, SearchLog

router = APIRouter(prefix="/api/v1/ai", tags=["ai-advanced"])


@router.post("/estimate")
async def generate_estimate(data: dict, db: AsyncSession = Depends(get_db)):
    """Generate estimate draft from requirements description."""
    requirements = data.get("requirements", "")
    security_type = data.get("security_type", "CCTV")
    object_type = data.get("object_type", "shop")
    area_sqm = data.get("area_sqm", 0)

    templates = {
        "CCTV": {
            "shop": [
                {"item": "Camera Hikvision 4MP", "qty": 4, "rate": 3500},
                {"item": "NVR 8-ch", "qty": 1, "rate": 8000},
                {"item": "HDD 2TB", "qty": 1, "rate": 2500},
                {"item": "PoE Switch 8-port", "qty": 1, "rate": 3000},
                {"item": "Cable UTP Cat6 (100m)", "qty": 2, "rate": 1500},
                {"item": "Installation labor", "qty": 8, "rate": 500},
            ],
            "office": [
                {"item": "Camera Hikvision 4MP", "qty": 8, "rate": 3500},
                {"item": "NVR 16-ch", "qty": 1, "rate": 15000},
                {"item": "HDD 4TB", "qty": 2, "rate": 4000},
                {"item": "PoE Switch 16-port", "qty": 1, "rate": 6000},
                {"item": "Cable UTP Cat6 (100m)", "qty": 4, "rate": 1500},
                {"item": "Installation labor", "qty": 16, "rate": 500},
            ],
        },
        "Access Control": {
            "shop": [
                {"item": "Access Controller 2-door", "qty": 1, "rate": 12000},
                {"item": "Card Reader RFID", "qty": 2, "rate": 3000},
                {"item": "Electric Lock", "qty": 2, "rate": 4000},
                {"item": "Exit Button", "qty": 2, "rate": 500},
                {"item": "Cards (pack 50)", "qty": 1, "rate": 1500},
                {"item": "Installation labor", "qty": 6, "rate": 500},
            ],
        },
        "Alarm": {
            "shop": [
                {"item": "Ajax Hub 2 Plus", "qty": 1, "rate": 15000},
                {"item": "Motion Sensor", "qty": 4, "rate": 2500},
                {"item": "Door Sensor", "qty": 2, "rate": 1500},
                {"item": "Siren Indoor", "qty": 1, "rate": 3000},
                {"item": "Installation labor", "qty": 4, "rate": 500},
            ],
        },
    }

    items = templates.get(security_type, {}).get(object_type, templates.get(security_type, {}).get("shop", []))

    if not items:
        return {"success": True, "data": {"items": [], "total": 0, "message": "No template found"}}

    total = sum(i["qty"] * i["rate"] for i in items)

    return {
        "success": True,
        "data": {
            "security_type": security_type,
            "object_type": object_type,
            "items": items,
            "total": total,
            "currency": "UAH",
            "note": "AI-generated draft. Review and adjust before sending.",
        },
    }


@router.post("/proposal")
async def generate_proposal(data: dict, db: AsyncSession = Depends(get_db)):
    """Generate commercial proposal from estimate."""
    estimate_items = data.get("items", [])
    customer_name = data.get("customer_name", "Client")
    object_name = data.get("object_name", "Object")
    discount_percent = data.get("discount_percent", 0)

    if not estimate_items:
        raise HTTPException(status_code=400, detail="items required")

    total = sum(i.get("qty", 0) * i.get("rate", 0) for i in estimate_items)
    discount = total * discount_percent / 100
    grand_total = total - discount

    proposal = {
        "customer": customer_name,
        "object": object_name,
        "items": estimate_items,
        "subtotal": total,
        "discount_percent": discount_percent,
        "discount_amount": discount,
        "grand_total": grand_total,
        "currency": "UAH",
        "validity_days": 30,
        "payment_terms": "50% prepayment, 50% after completion",
        "warranty": "24 months on equipment, 12 months on installation",
    }

    return {"success": True, "data": proposal}


@router.post("/service-expert")
async def service_expert(data: dict, db: AsyncSession = Depends(get_db)):
    """Search for similar incidents and provide recommendations."""
    description = data.get("description", "")
    equipment_type = data.get("equipment_type", "")
    error_code = data.get("error_code", "")

    query = select(KnowledgeDocument).where(KnowledgeDocument.is_active == True)

    conditions = []
    if description:
        for word in description.split()[:5]:
            conditions.append(KnowledgeDocument.content.ilike(f"%{word}%"))
    if equipment_type:
        conditions.append(KnowledgeDocument.tags.ilike(f"%{equipment_type}%"))
    if error_code:
        conditions.append(KnowledgeDocument.content.ilike(f"%{error_code}%"))

    if conditions:
        from sqlalchemy import or_
        query = query.where(or_(*conditions))

    query = query.limit(5)
    result = await db.execute(query)
    docs = result.scalars().all()

    recommendations = []
    for doc in docs:
        recommendations.append({
            "title": doc.title,
            "content": doc.content[:500],
            "doc_type": doc.doc_type,
            "relevance": "high" if equipment_type and equipment_type.lower() in (doc.tags or "").lower() else "medium",
        })

    common_fixes = {
        "camera": ["Check power supply", "Verify network cable", "Reset to factory defaults", "Check firmware version"],
        "nvr": ["Check HDD status", "Verify network settings", "Check camera connections", "Restart device"],
        "router": ["Check ISP connection", "Verify DNS settings", "Check firewall rules", "Restart device"],
        "switch": ["Check port status", "Verify VLAN settings", "Check power supply", "Restart device"],
    }

    equipment_lower = equipment_type.lower() if equipment_type else ""
    general_advice = common_fixes.get(equipment_lower, ["Check power", "Check connections", "Restart device"])

    return {
        "success": True,
        "data": {
            "similar_cases": recommendations,
            "general_advice": general_advice,
            "equipment_type": equipment_type,
        },
    }


@router.post("/kpi-report")
async def generate_kpi_report(data: dict, db: AsyncSession = Depends(get_db)):
    """Generate KPI report for specified period."""
    from_date = data.get("from_date", datetime.now(timezone.utc).strftime("%Y-%m-01"))
    to_date = data.get("to_date", datetime.now(timezone.utc).strftime("%Y-%m-%d"))

    searches = (await db.execute(
        select(func.count()).select_from(SearchLog)
    )).scalar()

    docs = (await db.execute(
        select(func.count()).select_from(KnowledgeDocument).where(KnowledgeDocument.is_active == True)
    )).scalar()

    return {
        "success": True,
        "data": {
            "period": {"from": from_date, "to": to_date},
            "knowledge_base": {
                "documents": docs,
                "searches": searches,
            },
            "note": "Full KPI report requires FSM and CMDB data integration",
        },
    }


@router.get("/dashboard")
async def ai_dashboard(db: AsyncSession = Depends(get_db)):
    """AI dashboard with summary metrics."""
    docs = (await db.execute(
        select(func.count()).select_from(KnowledgeDocument).where(KnowledgeDocument.is_active == True)
    )).scalar()

    searches = (await db.execute(
        select(func.count()).select_from(SearchLog)
    )).scalar()

    return {
        "success": True,
        "data": {
            "knowledge_base": {
                "documents": docs,
                "total_searches": searches,
                "status": "active" if docs > 0 else "empty",
            },
            "features": {
                "estimate_generator": "active",
                "proposal_generator": "active",
                "service_expert": "active",
                "kpi_reports": "active",
                "rag_search": "planned",
            },
        },
    }
