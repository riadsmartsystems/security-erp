import base64
from fastapi import APIRouter, Depends, HTTPException, Request, UploadFile, File, Form
from pydantic import BaseModel
from typing import Optional
from app.core.database import frappe_get, frappe_post, frappe_put
from app.auth.dependencies import get_current_user, CurrentUser

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
async def start_visit_v1(visit_id: str, body: VisitStartRequest, current_user: CurrentUser = Depends(get_current_user)):
    try:
        data = {
            "status": "On Route",
            "gps_checkin_lat": body.lat,
            "gps_checkin_lon": body.lon,
        }
        result = await frappe_put(f"/api/resource/Visit/{visit_id}", data=data)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/api/v1/visits/{visit_id}/finish")
async def finish_visit_v1(visit_id: str, body: VisitFinishRequest, current_user: CurrentUser = Depends(get_current_user)):
    try:
        data = {
            "status": "Completed",
            "gps_checkout_lat": body.lat,
            "gps_checkout_lon": body.lon,
        }
        result = await frappe_put(f"/api/resource/Visit/{visit_id}", data=data)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/api/v1/visits/{visit_id}/materials")
async def add_material_v1(visit_id: str, body: VisitMaterialRequest, current_user: CurrentUser = Depends(get_current_user)):
    try:
        data = {
            "parent": visit_id,
            "parenttype": "Visit",
            "item_code": body.item_code,
            "item_name": body.item_name,
            "qty": body.quantity,
            "rate": body.unit_price,
        }
        result = await frappe_post("/api/resource/Visit Material", data=data)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/api/v2/visits/{visit_id}/start")
async def start_visit_v2(visit_id: str, body: VisitStartRequest, current_user: CurrentUser = Depends(get_current_user)):
    return await start_visit_v1(visit_id, body, current_user)


@router.post("/api/v2/visits/{visit_id}/finish")
async def finish_visit_v2(visit_id: str, body: VisitFinishRequest, current_user: CurrentUser = Depends(get_current_user)):
    return await finish_visit_v1(visit_id, body, current_user)


@router.post("/api/v2/visits/{visit_id}/materials")
async def add_material_v2(visit_id: str, body: VisitMaterialRequest, current_user: CurrentUser = Depends(get_current_user)):
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
        file_b64 = base64.b64encode(contents).decode()

        data = {
            "parent": visit_id,
            "parenttype": "Visit",
            "photo_type": type,
            "caption": caption,
            "image": f"data:{file.content_type};base64,{file_b64}",
        }
        result = await frappe_post("/api/resource/Visit Photo", data=data)
        return {"success": True, "data": result.get("data", {})}
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
