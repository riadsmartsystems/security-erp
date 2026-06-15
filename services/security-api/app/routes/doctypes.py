from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from app.core.database import frappe_get, frappe_post, frappe_put
from app.auth.dependencies import get_current_user, CurrentUser
from app.auth.permissions import Permission

router = APIRouter(prefix="/api/v2", tags=["doctypes"])


class ListParams(BaseModel):
    filters: Optional[list] = None
    fields: Optional[list] = None
    limit: int = 20
    offset: int = 0


class CustomerCreate(BaseModel):
    customer_name: str
    customer_type: str = "Company"
    edrpou_code: Optional[str] = None
    primary_phone: Optional[str] = None
    primary_email: Optional[str] = None
    service_level: str = "Standard"


class ObjectCreate(BaseModel):
    object_code: str
    object_name: str
    customer: Optional[str] = None
    object_type: str = "Office"
    address: Optional[str] = None
    gps_lat: Optional[float] = None
    gps_lon: Optional[float] = None
    service_level: str = "Standard"


class EquipmentCreate(BaseModel):
    equipment_code: str
    security_object: str
    equipment_type: Optional[str] = None
    vendor: Optional[str] = None
    model: Optional[str] = None
    serial_number: Optional[str] = None
    firmware_version: Optional[str] = None
    status: str = "Planned"


class TicketCreate(BaseModel):
    ticket_number: str
    customer: Optional[str] = None
    security_object: Optional[str] = None
    ticket_type: str = "Incident"
    priority: str = "Medium"
    title: str
    description: Optional[str] = None


def _build_filters(filters: Optional[list]) -> Optional[str]:
    if not filters:
        return None
    import json
    return json.dumps(filters)


@router.get("/customers")
async def list_customers(
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        result = await frappe_get("/api/resource/Customer", params={
            "fields": '["name","customer_name","customer_type","edrpou_code","primary_phone","primary_email","service_level","creation"]',
            "limit_page_length": limit,
            "limit_start": offset,
        })
        return {"success": True, "data": result.get("data", []), "total": len(result.get("data", []))}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/customers/{name}")
async def get_customer(name: str, current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get(f"/api/resource/Customer/{name}")
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Customer not found: {name}")


@router.post("/customers")
async def create_customer(body: CustomerCreate, current_user: CurrentUser = Depends(get_current_user)):
    if not current_user.has(Permission.CMDB_FULL) and current_user.role.value not in ["owner", "director", "service_manager"]:
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    try:
        result = await frappe_post("/api/resource/Customer", data=body.model_dump(exclude_none=True))
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/customers/{name}")
async def update_customer(name: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    if not current_user.has(Permission.CMDB_FULL) and current_user.role.value not in ["owner", "director", "service_manager"]:
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    try:
        result = await frappe_put(f"/api/resource/Customer/{name}", data=body)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/objects")
async def list_objects(
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    customer: Optional[str] = None,
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        params = {
            "fields": '["name","object_code","customer","customer_name","object_name","object_type","address","gps_lat","gps_lon","service_level","status","creation"]',
            "limit_page_length": limit,
            "limit_start": offset,
        }
        if customer:
            params["filters"] = f'[["customer","=","{customer}"]]'
        result = await frappe_get("/api/resource/Security Object", params=params)
        return {"success": True, "data": result.get("data", [])}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/objects/{name}")
async def get_object(name: str, current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get(f"/api/resource/Security Object/{name}")
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Object not found: {name}")


@router.post("/objects")
async def create_object(body: ObjectCreate, current_user: CurrentUser = Depends(get_current_user)):
    if not current_user.has(Permission.CMDB_FULL):
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    try:
        result = await frappe_post("/api/resource/Security Object", data=body.model_dump(exclude_none=True))
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/equipment")
async def list_equipment(
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    object_code: Optional[str] = None,
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        params = {
            "fields": '["name","equipment_code","security_object","equipment_type","vendor","model","serial_number","status","install_date","warranty_end_date","creation"]',
            "limit_page_length": limit,
            "limit_start": offset,
        }
        if object_code:
            params["filters"] = f'[["security_object","=","{object_code}"]]'
        result = await frappe_get("/api/resource/Equipment", params=params)
        return {"success": True, "data": result.get("data", [])}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/equipment/{name}")
async def get_equipment(name: str, current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get(f"/api/resource/Equipment/{name}")
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Equipment not found: {name}")


@router.post("/equipment")
async def create_equipment(body: EquipmentCreate, current_user: CurrentUser = Depends(get_current_user)):
    if not current_user.has(Permission.CMDB_FULL):
        raise HTTPException(status_code=403, detail="Insufficient permissions")
    try:
        result = await frappe_post("/api/resource/Equipment", data=body.model_dump(exclude_none=True))
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/tickets")
async def list_tickets(
    limit: int = Query(20, le=100),
    offset: int = Query(0),
    status: Optional[str] = None,
    customer: Optional[str] = None,
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        params = {
            "fields": '["name","ticket_number","customer","customer_name","security_object","ticket_type","priority","status","title","assigned_engineer","creation"]',
            "limit_page_length": limit,
            "limit_start": offset,
        }
        filters = []
        if status:
            filters.append(["status", "=", status])
        if customer:
            filters.append(["customer", "=", customer])
        if filters:
            import json
            params["filters"] = json.dumps(filters)
        result = await frappe_get("/api/resource/Service Ticket", params=params)
        return {"success": True, "data": result.get("data", [])}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/tickets/{name}")
async def get_ticket(name: str, current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get(f"/api/resource/Service Ticket/{name}")
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Ticket not found: {name}")


@router.post("/tickets")
async def create_ticket(body: TicketCreate, current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_post("/api/resource/Service Ticket", data=body.model_dump(exclude_none=True))
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.put("/tickets/{name}")
async def update_ticket(name: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_put(f"/api/resource/Service Ticket/{name}", data=body)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/stats")
async def get_stats(current_user: CurrentUser = Depends(get_current_user)):
    try:
        customers = await frappe_get("/api/resource/Customer", params={"limit_page_length": 1})
        objects = await frappe_get("/api/resource/Security Object", params={"limit_page_length": 1})
        equipment = await frappe_get("/api/resource/Equipment", params={"limit_page_length": 1})
        tickets = await frappe_get("/api/resource/Service Ticket", params={
            "limit_page_length": 1,
            "filters": '[["status","!=","Closed"]]'
        })
        return {
            "success": True,
            "data": {
                "customers": len(customers.get("data", [])),
                "objects": len(objects.get("data", [])),
                "equipment": len(equipment.get("data", [])),
                "open_tickets": len(tickets.get("data", [])),
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


WHOLESALE_DISCOUNT = 0.80


@router.get("/pricing/calculate")
async def calculate_pricing(
    item_code: str,
    qty: int = Query(1, ge=1),
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        result = await frappe_get(f"/api/resource/Item/{item_code}")
        item = result.get("data", {})
        retail_price = float(item.get("retail_price") or 0)
        if retail_price == 0:
            return {"success": False, "error": "No retail_price set for this item"}

        wholesale_price = retail_price * WHOLESALE_DISCOUNT
        return {
            "success": True,
            "data": {
                "item_code": item_code,
                "item_name": item.get("item_name"),
                "retail_price": retail_price,
                "wholesale_price": round(wholesale_price, 2),
                "discount_percent": round((1 - WHOLESALE_DISCOUNT) * 100),
                "qty": qty,
                "retail_total": retail_price * qty,
                "wholesale_total": round(wholesale_price * qty, 2),
                "margin": round((retail_price - wholesale_price) * qty, 2),
            },
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/purchase-order")
async def create_purchase_order(body: dict, current_user: CurrentUser = Depends(get_current_user)):
    try:
        items = body.get("items", [])
        supplier = body.get("supplier", "")

        for item in items:
            item_code = item.get("item_code")
            qty = item.get("qty", 1)
            if item_code:
                try:
                    result = await frappe_get(f"/api/resource/Item/{item_code}")
                    retail = float(result.get("data", {}).get("retail_price") or 0)
                    if retail > 0:
                        item["rate"] = round(retail * WHOLESALE_DISCOUNT, 2)
                        item["amount"] = round(item["rate"] * qty, 2)
                except Exception:
                    pass

        data = {
            "supplier": supplier,
            "transaction_date": body.get("transaction_date", ""),
            "schedule_date": body.get("schedule_date", ""),
            "items": items,
        }
        result = await frappe_post("/api/resource/Purchase Order", data=data)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/sales-invoice")
async def create_sales_invoice(body: dict, current_user: CurrentUser = Depends(get_current_user)):
    try:
        items = body.get("items", [])

        for item in items:
            item_code = item.get("item_code")
            qty = item.get("qty", 1)
            if item_code:
                try:
                    result = await frappe_get(f"/api/resource/Item/{item_code}")
                    retail = float(result.get("data", {}).get("retail_price") or 0)
                    if retail > 0:
                        item["rate"] = retail
                        item["amount"] = round(retail * qty, 2)
                except Exception:
                    pass

        data = {
            "customer": body.get("customer", ""),
            "items": items,
        }
        result = await frappe_post("/api/resource/Sales Invoice", data=data)

        invoice = result.get("data", {})
        total_retail = sum(it.get("amount", 0) for it in invoice.get("items", []))

        return {
            "success": True,
            "data": invoice,
            "pricing": {
                "retail_total": total_retail,
                "note": "Use /api/v2/pricing/margin to calculate margin",
            },
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/pricing/margin")
async def calculate_margin(
    po_name: str = Query(...),
    si_name: str = Query(...),
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        po_result = await frappe_get(f"/api/resource/Purchase Order/{po_name}")
        po = po_result.get("data", {})
        po_total = float(po.get("grand_total") or 0)

        si_result = await frappe_get(f"/api/resource/Sales Invoice/{si_name}")
        si = si_result.get("data", {})
        si_total = float(si.get("grand_total") or 0)

        margin = si_total - po_total
        margin_percent = (margin / po_total * 100) if po_total > 0 else 0

        return {
            "success": True,
            "data": {
                "purchase_order": po_name,
                "sales_invoice": si_name,
                "wholesale_total": po_total,
                "retail_total": si_total,
                "margin": round(margin, 2),
                "margin_percent": round(margin_percent, 1),
            },
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
