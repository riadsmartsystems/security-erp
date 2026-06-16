import json
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from app.core.database import frappe_get, frappe_post, frappe_put
from app.auth.dependencies import get_current_user, CurrentUser
from app.auth.permissions import Permission

router = APIRouter(prefix="/api/v2", tags=["doctypes"])

_settings_cache = None


async def get_settings():
    global _settings_cache
    if _settings_cache:
        return _settings_cache
    try:
        result = await frappe_get("/api/resource/Security ERP Settings/Security ERP Settings")
        _settings_cache = result.get("data", {})
    except Exception:
        _settings_cache = {
            "default_discount": 20,
            "company_name": "RIAD SMART SYSTEM",
            "currency": "UAH",
        }
    return _settings_cache


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


@router.get("/settings")
async def read_settings(current_user: CurrentUser = Depends(get_current_user)):
    settings = await get_settings()
    return {"success": True, "data": settings}


@router.put("/settings")
async def update_settings(body: dict, current_user: CurrentUser = Depends(get_current_user)):
    global _settings_cache
    try:
        result = await frappe_put("/api/resource/Security ERP Settings/Security ERP Settings", data=body)
        _settings_cache = None
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/items/search")
async def search_items(
    q: str = Query(..., min_length=1),
    limit: int = Query(20, le=50),
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        filters = json.dumps([["item_name", "like", f"%{q}%"]])
        result = await frappe_get("/api/resource/Item", params={
            "fields": '["name","item_code","item_name","retail_price","item_group"]',
            "filters": filters,
            "limit_page_length": limit,
        })
        items = result.get("data", [])
        return {"success": True, "data": items}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


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


@router.post("/purchase-order")
async def create_purchase_order(body: dict, current_user: CurrentUser = Depends(get_current_user)):
    try:
        settings = await get_settings()
        discount = float(settings.get("default_discount", 20)) / 100
        company = settings.get("company_name", "RIAD SMART SYSTEM")
        currency = settings.get("currency", "UAH")

        items = body.get("items", [])
        supplier = body.get("supplier", "")

        total_retail = 0
        total_wholesale = 0

        for item in items:
            item_code = item.get("item_code")
            qty = item.get("qty", 1)
            retail_price = item.get("rate", 0)

            if item_code:
                try:
                    result = await frappe_get(f"/api/resource/Item/{item_code}")
                    retail_from_db = float(result.get("data", {}).get("retail_price") or 0)
                    if retail_from_db > 0:
                        retail_price = retail_from_db
                except Exception:
                    pass

            wholesale_price = round(retail_price * (1 - discount), 2)
            item["retail_price"] = retail_price
            item["retail_amount"] = round(retail_price * qty, 2)
            item["rate"] = wholesale_price
            item["amount"] = round(wholesale_price * qty, 2)
            item["item_margin"] = round((retail_price - wholesale_price) * qty, 2)

            total_retail += item["retail_amount"]
            total_wholesale += item["amount"]

        total_margin = total_retail - total_wholesale
        margin_percent = round((total_margin / total_retail * 100) if total_retail > 0 else 0, 1)

        data = {
            "supplier": supplier,
            "title": supplier,
            "transaction_date": body.get("transaction_date", ""),
            "schedule_date": body.get("schedule_date", body.get("transaction_date", "")),
            "company": company,
            "currency": currency,
            "conversion_rate": 1,
            "naming_series": "PO-.YYYY.-",
            "items": items,
            "total_retail": total_retail,
            "total_margin": total_margin,
            "margin_percent": margin_percent,
        }
        result = await frappe_post("/api/resource/Purchase Order", data=data)

        po = result.get("data", {})
        po["total_retail"] = total_retail
        po["total_margin"] = total_margin
        po["margin_percent"] = margin_percent

        return {"success": True, "data": po}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/sales-invoice")
async def create_sales_invoice(body: dict, current_user: CurrentUser = Depends(get_current_user)):
    try:
        settings = await get_settings()
        company = settings.get("company_name", "RIAD SMART SYSTEM")
        currency = settings.get("currency", "UAH")

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
            "company": company,
            "currency": currency,
            "conversion_rate": 1,
            "naming_series": "SI-.YYYY.-",
            "items": items,
        }
        result = await frappe_post("/api/resource/Sales Invoice", data=data)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/purchase-order/{po_name}/create-invoice")
async def create_invoice_from_po(po_name: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    try:
        settings = await get_settings()
        company = settings.get("company_name", "RIAD SMART SYSTEM")
        currency = settings.get("currency", "UAH")
        payment_terms = settings.get("payment_terms", "")
        delivery_terms = settings.get("delivery_terms", "")
        warranty_terms = settings.get("warranty_terms", "")

        po_result = await frappe_get(f"/api/resource/Purchase Order/{po_name}")
        po = po_result.get("data", {})

        if not po:
            raise HTTPException(status_code=404, detail="Purchase Order not found")

        customer = body.get("customer", "")
        if not customer:
            raise HTTPException(status_code=400, detail="customer required")

        si_items = []
        for item in po.get("items", []):
            retail_price = float(item.get("retail_price") or 0)
            if retail_price == 0:
                retail_price = float(item.get("price_list_rate") or 0)
            if retail_price == 0:
                discount = float(settings.get("default_discount", 20)) / 100
                retail_price = float(item.get("rate") or 0) / (1 - discount)

            si_items.append({
                "item_code": item.get("item_code"),
                "qty": item.get("qty"),
                "rate": round(retail_price, 2),
            })

        si_data = {
            "customer": customer,
            "company": company,
            "currency": currency,
            "conversion_rate": 1,
            "naming_series": "SI-.YYYY.-",
            "items": si_items,
        }
        si_result = await frappe_post("/api/resource/Sales Invoice", data=si_data)
        si = si_result.get("data", {})

        wholesale_total = float(po.get("grand_total") or 0)
        retail_total = float(si.get("grand_total") or 0)
        margin = retail_total - wholesale_total

        return {
            "success": True,
            "data": {
                "purchase_order": po_name,
                "sales_invoice": si.get("name"),
                "customer": customer,
                "wholesale_total": wholesale_total,
                "retail_total": retail_total,
                "margin": round(margin, 2),
                "link": f"https://erp.riad.fun/app/sales-invoice/{si.get('name')}",
                "terms": {
                    "payment": payment_terms,
                    "delivery": delivery_terms,
                    "warranty": warranty_terms,
                },
            },
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/pricing/calculate")
async def calculate_pricing(
    item_code: str,
    qty: int = Query(1, ge=1),
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        settings = await get_settings()
        discount = float(settings.get("default_discount", 20)) / 100

        result = await frappe_get(f"/api/resource/Item/{item_code}")
        item = result.get("data", {})
        retail_price = float(item.get("retail_price") or 0)
        if retail_price == 0:
            return {"success": False, "error": "No retail_price set for this item"}

        wholesale_price = round(retail_price * (1 - discount), 2)
        return {
            "success": True,
            "data": {
                "item_code": item_code,
                "item_name": item.get("item_name"),
                "retail_price": retail_price,
                "wholesale_price": wholesale_price,
                "discount_percent": round(discount * 100),
                "qty": qty,
                "retail_total": retail_price * qty,
                "wholesale_total": round(wholesale_price * qty, 2),
                "margin": round((retail_price - wholesale_price) * qty, 2),
            },
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


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
        margin_percent = (margin / si_total * 100) if si_total > 0 else 0

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
