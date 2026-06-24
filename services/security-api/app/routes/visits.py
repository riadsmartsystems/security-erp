from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
from typing import Optional

from app.auth.dependencies import get_current_user, CurrentUser
from app.services import visit_service

router = APIRouter(tags=["visits"])


class VisitStartRequest(BaseModel):
    lat: float = 0.0
    lon: float = 0.0


class VisitFinishRequest(BaseModel):
    lat: float = 0.0
    lon: float = 0.0


class VisitMaterialRequest(BaseModel):
    item_code: Optional[str] = None
    item_name: str
    quantity: int = 1
    unit_price: float = 0.0


@router.post("/api/v1/visits/{visit_id}/start")
async def start_visit_v1(
    visit_id: str,
    body: VisitStartRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        data = await visit_service.start_visit(
            sid=current_user.frappe_sid, visit_id=visit_id, lat=body.lat, lon=body.lon
        )
        return {"success": True, "data": data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/api/v1/visits/{visit_id}/finish")
async def finish_visit_v1(
    visit_id: str,
    body: VisitFinishRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        data = await visit_service.finish_visit(
            sid=current_user.frappe_sid, visit_id=visit_id, lat=body.lat, lon=body.lon
        )
        return {"success": True, "data": data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/api/v1/visits/{visit_id}/materials")
async def add_material_v1(
    visit_id: str,
    body: VisitMaterialRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        data = await visit_service.add_material(
            sid=current_user.frappe_sid,
            visit_id=visit_id,
            item_code=body.item_code,
            item_name=body.item_name,
            quantity=body.quantity,
            unit_price=body.unit_price,
        )
        return {"success": True, "data": data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/api/v2/visits/{visit_id}/start")
async def start_visit_v2(
    visit_id: str,
    body: VisitStartRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    return await start_visit_v1(visit_id, body, current_user)


@router.post("/api/v2/visits/{visit_id}/finish")
async def finish_visit_v2(
    visit_id: str,
    body: VisitFinishRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    return await finish_visit_v1(visit_id, body, current_user)


@router.post("/api/v2/visits/{visit_id}/materials")
async def add_material_v2(
    visit_id: str,
    body: VisitMaterialRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    return await add_material_v1(visit_id, body, current_user)


@router.post("/api/v1/visits/{visit_id}/photos")
async def upload_photo_v1(
    visit_id: str,
    file: UploadFile = File(...),
    type: str = Form("after"),
    caption: str = Form(""),
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        contents = await file.read()
        data = await visit_service.upload_photo(
            sid=current_user.frappe_sid,
            visit_id=visit_id,
            file_bytes=contents,
            content_type=file.content_type,
            photo_type=type,
            caption=caption,
        )
        return {"success": True, "data": data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/api/v2/visits/{visit_id}/photos")
async def upload_photo_v2(
    visit_id: str,
    file: UploadFile = File(...),
    type: str = Form("after"),
    caption: str = Form(""),
    current_user: CurrentUser = Depends(get_current_user),
):
    return await upload_photo_v1(visit_id, file, type, caption, current_user)
