from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone
import uuid

from app.core.database import get_db
from app.models.ticket import (
    ChecklistTemplate, ChecklistTemplateItem,
    VisitChecklist, VisitChecklistItem, Visit
)

router = APIRouter(prefix="/api/v1/checklists", tags=["checklists"])


# === Templates ===

@router.get("/templates")
async def list_templates(
    equipment_type: str = None,
    security_type: str = None,
    db: AsyncSession = Depends(get_db)
):
    query = select(ChecklistTemplate).where(ChecklistTemplate.is_active == True)
    if equipment_type:
        query = query.where(ChecklistTemplate.equipment_type == equipment_type)
    if security_type:
        query = query.where(ChecklistTemplate.security_type == security_type)
    result = await db.execute(query)
    templates = result.scalars().all()
    return {"success": True, "data": [t.__dict__ for t in templates]}


@router.post("/templates")
async def create_template(data: dict, db: AsyncSession = Depends(get_db)):
    template = ChecklistTemplate(
        id=uuid.uuid4(),
        name=data.get("name"),
        description=data.get("description"),
        equipment_type=data.get("equipment_type"),
        security_type=data.get("security_type"),
    )
    db.add(template)
    await db.commit()
    return {"success": True, "data": {"id": str(template.id)}}


@router.get("/templates/{template_id}")
async def get_template(template_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(ChecklistTemplate).where(ChecklistTemplate.id == template_id)
    )
    template = result.scalar_one_or_none()
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")

    items_result = await db.execute(
        select(ChecklistTemplateItem)
        .where(ChecklistTemplateItem.template_id == template_id)
        .order_by(ChecklistTemplateItem.item_order)
    )
    items = items_result.scalars().all()

    data = template.__dict__
    data["items"] = [i.__dict__ for i in items]
    return {"success": True, "data": data}


@router.post("/templates/{template_id}/items")
async def add_template_item(template_id: str, data: dict, db: AsyncSession = Depends(get_db)):
    item = ChecklistTemplateItem(
        id=uuid.uuid4(),
        template_id=uuid.UUID(template_id),
        item_order=data.get("item_order", 1),
        question=data.get("question"),
        item_type=data.get("item_type", "checkbox"),
        options=data.get("options"),
        is_required=data.get("is_required", True),
    )
    db.add(item)
    await db.commit()
    return {"success": True, "data": {"id": str(item.id)}}


# === Visit Checklists ===

@router.post("/visit/{visit_id}")
async def create_visit_checklist(visit_id: str, data: dict, db: AsyncSession = Depends(get_db)):
    template_id = data.get("template_id")
    if not template_id:
        raise HTTPException(status_code=400, detail="template_id required")

    visit_result = await db.execute(select(Visit).where(Visit.id == visit_id))
    visit = visit_result.scalar_one_or_none()
    if not visit:
        raise HTTPException(status_code=404, detail="Visit not found")

    checklist = VisitChecklist(
        id=uuid.uuid4(),
        visit_id=uuid.UUID(visit_id),
        template_id=uuid.UUID(template_id),
        status="pending",
    )
    db.add(checklist)

    template_items_result = await db.execute(
        select(ChecklistTemplateItem)
        .where(ChecklistTemplateItem.template_id == template_id)
        .order_by(ChecklistTemplateItem.item_order)
    )
    template_items = template_items_result.scalars().all()

    for ti in template_items:
        item = VisitChecklistItem(
            id=uuid.uuid4(),
            checklist_id=checklist.id,
            template_item_id=ti.id,
            item_order=ti.item_order,
            question=ti.question,
            item_type=ti.item_type,
        )
        db.add(item)

    await db.commit()
    return {"success": True, "data": {"id": str(checklist.id)}}


@router.get("/visit/{visit_id}")
async def get_visit_checklists(visit_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(VisitChecklist).where(VisitChecklist.visit_id == visit_id)
    )
    checklists = result.scalars().all()

    data = []
    for cl in checklists:
        items_result = await db.execute(
            select(VisitChecklistItem)
            .where(VisitChecklistItem.checklist_id == cl.id)
            .order_by(VisitChecklistItem.item_order)
        )
        items = items_result.scalars().all()
        cl_data = cl.__dict__
        cl_data["items"] = [i.__dict__ for i in items]
        data.append(cl_data)

    return {"success": True, "data": data}


@router.put("/items/{item_id}")
async def update_checklist_item(item_id: str, data: dict, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(VisitChecklistItem).where(VisitChecklistItem.id == item_id)
    )
    item = result.scalar_one_or_none()
    if not item:
        raise HTTPException(status_code=404, detail="Checklist item not found")

    if "answer" in data:
        item.answer = data["answer"]
    if "is_checked" in data:
        item.is_checked = data["is_checked"]
        if data["is_checked"]:
            item.checked_at = datetime.now(timezone.utc)
    if "notes" in data:
        item.notes = data["notes"]
    if "photo_file_id" in data:
        item.photo_file_id = uuid.UUID(data["photo_file_id"]) if data["photo_file_id"] else None

    await db.commit()

    checklist_result = await db.execute(
        select(VisitChecklist).where(VisitChecklist.id == item.checklist_id)
    )
    checklist = checklist_result.scalar_one_or_none()
    if checklist:
        all_items_result = await db.execute(
            select(VisitChecklistItem).where(VisitChecklistItem.checklist_id == checklist.id)
        )
        all_items = all_items_result.scalars().all()
        if all(i.is_checked for i in all_items):
            checklist.status = "completed"
            checklist.completed_at = datetime.now(timezone.utc)
        elif any(i.is_checked for i in all_items):
            checklist.status = "in_progress"
            if not checklist.started_at:
                checklist.started_at = datetime.now(timezone.utc)
        await db.commit()

    return {"success": True, "data": {"id": str(item.id)}}
