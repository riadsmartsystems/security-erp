import json
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from pydantic import BaseModel
from app.core.database import frappe_get, frappe_post, frappe_put
from app.auth.dependencies import get_current_user, CurrentUser
from app.auth.permissions import Permission
from app.services.ai_service import ai_service

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
    q: str = Query(None),
    category: str = Query(None),
    brand: str = Query(None),
    camera_type: str = Query(None),
    megapixels: str = Query(None),
    limit: int = Query(20, le=100),
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        filters = []
        if q:
            filters.append(["item_name", "like", f"%{q}%"])
        if category:
            filters.append(["item_group", "=", category])
        if brand:
            filters.append(["item_name", "like", f"%{brand}%"])
        if camera_type == "ip":
            filters.append(["item_name", "like", "%IP%"])
        elif camera_type == "analog":
            filters.append(["item_name", "like", "%CVI%"])
        if megapixels:
            filters.append(["item_name", "like", f"%{megapixels}МП%"])
        
        if not filters:
            filters = [["retail_price", ">", 0]]
        
        filter_str = json.dumps(filters) if filters else None
        params = {
            "fields": '["name","item_code","item_name","retail_price","item_group"]',
            "limit_page_length": limit,
        }
        if filter_str:
            params["filters"] = filter_str
        
        result = await frappe_get("/api/resource/Item", params=params)
        items = result.get("data", [])
        return {"success": True, "data": items}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/items/categories")
async def list_categories(current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get("/api/resource/Item Group", params={
            "fields": '["name","parent_item_group"]',
            "limit_page_length": 200,
        })
        groups = result.get("data", [])
        top_level = [g["name"] for g in groups if g.get("parent_item_group") == "All Item Groups"]
        return {"success": True, "data": top_level}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/items/brands")
async def list_brands(current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get("/api/resource/Item", params={
            "fields": '["item_name"]',
            "limit_page_length": 0,
        })
        items = result.get("data", [])
        brands = set()
        for item in items:
            name = item.get("item_name", "")
            for brand in ["Hikvision", "Dahua", "Imou", "Ajax", "MikroTik", "TP-Link", "Ubiquiti", 
                         "Avtech", "GeoVision", "Vivotek", "Uniview", "KBVision", "Forteza",
                         "Tecumseh", "Maxxter", "Ewind", "Dnipro", "Hyundai", "Samsung"]:
                if brand.lower() in name.lower():
                    brands.add(brand)
        return {"success": True, "data": sorted(brands)}
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


class LeadCreate(BaseModel):
    lead_name: str
    mobile_no: Optional[str] = None
    object_address: Optional[str] = None
    technical_assignment: Optional[str] = None
    status: str = "Open"

@router.post("/leads")
async def create_lead(body: LeadCreate, current_user: CurrentUser = Depends(get_current_user)):
    try:
        data = body.model_dump(exclude_none=True)
        result = await frappe_post("/api/resource/Lead", data=data)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/leads")
async def list_leads(
    limit: int = Query(20, le=100),
    filters: Optional[str] = None,
    current_user: CurrentUser = Depends(get_current_user),
):
    try:
        params = {
            "fields": '["name","lead_name","mobile_no","status","technical_assignment"]',
            "limit_page_length": limit,
        }
        if filters:
            params["filters"] = filters
        result = await frappe_get("/api/resource/Lead", params=params)
        return {"success": True, "data": result.get("data", [])}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/leads/{name}")
async def get_lead(name: str, current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get(f"/api/resource/Lead/{name}")
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Lead not found: {name}")

@router.post("/ai/estimate")
async def create_ai_estimate(body: AIEstimateRequest, current_user: CurrentUser = Depends(get_current_user)):
    try:
        estimate = await ai_service.generate_estimate(body.technical_assignment)
        await frappe_put(f"/api/resource/Lead/{body.lead_name}", data={
            "technical_assignment": body.technical_assignment,
            "ai_estimate_result": json.dumps(estimate)
        })
        return {"success": True, "data": estimate}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/scenarios")
async def list_scenarios(current_user: CurrentUser = Depends(get_//Current User logic here),
):
    try:
        result = await frappe_get("/api/resource/Security Scenario", params={"fields": '["name","scenario_name","description"]'})
        return {"success": True, "data": result.get("data", [])}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/scenarios/{scenario_id}/apply")
async def apply_scenario(scenario_id: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    try:
        items_result = await frappe_get(
            f"/api/resource/Security Scenario Item", 
            params={"filters": f'[["parent","=","{scenario_id}"]]'}
        )
        scenario_items = items_result.get("data", [])
        if not scenario_items:
            raise HTTPException(status_code=404, detail="No items found for this scenario")
        quotation_name = body.get("quotation")
        if quotation_name:
            return {"success": True, "items": scenario_items}
        lead_name = body.get("lead_name")
        if lead_name:
            lead_res = await frappe_get(f"/api/resource/Lead/{lead_name}")
            lead_data = lead_res.get("data", {})
            current_estimate = json.loads(lead_data.get("ai_estimate_result", "{}"))
            existing_items = current_estimate.get("items", [])
            for s_item in scenario_items:
                existing_items.append({
                    "item_code": s_item["item_code"],
                    "quantity": s_item["qty"],
                    "price": 0,
                    "reason": "Added via scenario"
                })
            current_estimate["items"] = existing_items
            await frappe_put(f"/api/resource/Lead/{lead_//Lead name here}", data={"ai_estimate_result": json.dumps(current_estimate)})
            return {"success": True, "data": current_estimate}
        raise HTTPException(status_code=400, detail="Either 'quotation' or 'lead_name' is required")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class WarrantyScanRequest(BaseModel):
    serial_number: str
    delivery_note: str
    item_code: Optional[str] = None

@router.post("/warranty/scan")
async def scan_serial_number(body: WarrantyScanRequest, current_user: CurrentUser = Depends(get_current_user)):
    try:
        warranty_card_name = f"WARR-{body.delivery_note}"
        card_exists = await frappe_get(f"/api/resource/Warranty Card/{warranty_card_name}")
        if not card_exists.get("data"):
            await frappe_post("/api/resource/Warranty Card", data={
                "name": warranty_card_name,
                "sales_invoice": body.delivery_note,
                "status": "Active"
            })
        await frappe_post("/api/resource/Warranty Card Item", data={
            "parent": warranty_card_name,
            "item_code": body.item_code,
            "serial_number": body.serial_number,
            "warranty_expiry": "2027-06-17"
        })
        return {"success": True, "message": f"Serial {body.serial_number} registered"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/warranty/card/{card_id}")
async def get_warranty_card(card_id: str, current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get(f"/api/resource/Warranty Card/{card_id}")
        items = await frappe_get("/api/resource/Warranty Card Item", params={
            "filters": f'[["parent","=","{card_id}"]]'
        })
        return {"success": True, "data": result.get("data"), "items": items.get("data", [])}
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/leads/{name}")
async def get_lead(name: str, current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get(f"/api/resource/Lead/{name}")
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Lead not found: {name}")

@router.post("/ai/estimate")
async def create_ai_estimate(body: AIEstimateRequest, current_user: CurrentUser = Depends(get_current_user)):
    try:
        estimate = await ai_service.generate_estimate(body.technical_assignment)
        await frappe_put(f"/api/resource/Lead/{body.lead_name}", data={
            "technical_assignment": body.technical_assignment,
            "ai_estimate_result": json.dumps(estimate)
        })
        return {"success": True, "data": estimate}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/scenarios")
async def list_scenarios(current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get("/api/resource/Security Scenario", params={"fields": '["name","scenario_name","description"]'})
        return {"success": True, "data": result.get("data", [])}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/scenarios/{scenario_id}/apply")
async def apply_scenario(scenario_id: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    try:
        items_result = await frappe_get(
            f"/api/resource/Security Scenario Item", 
            params={"filters": f'[["parent","=","{scenario_id}"]]'}
        )
        scenario_items = items_result.get("data", [])
        if not scenario_items:
            raise HTTPException(status_code=404, detail="No items found for this scenario")
        quotation_name = body.get("quotation")
        if quotation_name:
            return {"success": True, "items": scenario_items}
        lead_name = body.get("lead_name")
        if lead_name:
            lead_res = await frappe_get(f"/api/resource/Lead/{lead_name}")
            lead_data = lead_res.get("data", {})
            current_estimate = json.loads(lead_data.get("ai_estimate_result", "{}"))
            existing_items = current_estimate.get("items", [])
            for s_item in scenario_items:
                existing_items.append({
                    "item_code": s_item["item_code"],
                    "quantity": s_item["qty"],
                    "price": 0,
                    "reason": "Added via scenario"
                })
            current_estimate["items"] = existing_items
            await frappe_put(f"/api/resource/Lead/{lead_name}", data={"ai_estimate_result": json.dumps(current_estimate)})
            return {"success": True, "data": current_estimate}
        raise HTTPException(status_code=400, detail="Either 'quotation' or 'lead_name' is required")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/leads/{name}")
async def get_lead(name: str, current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get(f"/api/resource/Lead/{name}")
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Lead not found: {name}")

@router.post("/ai/estimate")
async def create_ai_estimate(body: AIEstimateRequest, current_user: CurrentUser = Depends(get_current_user)):
    try:
        estimate = await ai_service.generate_estimate(body.technical_assignment)
        await frappe_put(f"/api/resource/Lead/{body.lead_name}", data={
            "technical_assignment": body.technical_assignment,
            "ai_estimate_result": json.dumps(estimate)
        })
        return {"success": True, "data": estimate}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/scenarios")
async def list_scenarios(current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get("/api/resource/Security Scenario", params={"fields": '["name","scenario_name","description"]'})
        return {"success": True, "data": result.get("data", [])}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/scenarios/{scenario_id}/apply")
async def apply_scenario(scenario_id: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    try:
        items_result = await frappe_get(
            f"/api/resource/Security Scenario Item", 
            params={"filters": f'[["parent","=","{scenario_id}"]]'}
        )
        scenario_items = items_result.get("data", [])
        if not scenario_items:
            raise HTTPException(status_code=404, detail="No items found for this scenario")
        quotation_name = body.get("quotation")
        if quotation_name:
            return {"success": True, "items": scenario_items}
        lead_name = body.get("lead_name")
        if lead_name:
            lead_res = await frappe_get(f"/api/resource/Lead/{lead_name}")
            lead_data = lead_res.get("data", {})
            current_estimate = json.loads(lead_data.get("ai_estimate_result", "{}"))
            existing_items = current_estimate.get("items", [])
            for s_item in scenario_items:
                existing_items.append({
                    "item_code": s_item["item_code"],
                    "quantity": s_item["qty"],
                    "price": 0,
                    "reason": "Added via scenario"
                })
            current_estimate["items"] = existing_items
            await frappe_put(f"/api/resource/Lead/{lead_name}", data={"ai_estimate_result": json.dumps(current_estimate)})
            return {"success": True, "data": current_estimate}
        raise HTTPException(status_code=400, detail="Either 'quotation' or 'lead_name' is required")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))



# =========================================================================
# BUSINESS FLOW: Quotation → PO → SI
# =========================================================================

async def _get_retail_prices(items):
    """Get retail prices for items from DB."""
    total_retail = 0
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
        item["retail_price"] = retail_price
        item["retail_amount"] = round(retail_price * qty, 2)
        total_retail += item["retail_amount"]
    return items, total_retail


@router.post("/quotation")
async def create_quotation(body: dict, current_user: CurrentUser = Depends(get_current_user)):
    """Step 1: Create Quotation for customer with retail prices."""
    try:
        settings = await get_settings()
        company = settings.get("company_name", "RIAD SMART SYSTEM")
        currency = settings.get("currency", "UAH")

        items = body.get("items", [])
        items, total_retail = await _get_retail_prices(items)

        for item in items:
            item["rate"] = item["retail_price"]
            item["amount"] = item["retail_amount"]

        data = {
            "quotation_to": "Customer",
            "party_name": body.get("customer", ""),
            "company": company,
            "currency": currency,
            "conversion_rate": 1,
            "naming_series": "QTN-.YYYY.-",
            "items": items,
            "terms": settings.get("payment_terms", ""),
        }
        result = await frappe_post("/api/resource/Quotation", data=data)
        quotation = result.get("data", {})
        quotation["total_retail"] = total_retail
        return {"success": True, "data": quotation}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/quotations")
async def list_quotations(
    status: str = Query(None),
    limit: int = Query(20, le=100),
    current_user: CurrentUser = Depends(get_current_user),
):
    """List quotations."""
    try:
        params = {
            "fields": '["name","party_name","grand_total","status","transaction_date"]',
            "limit_page_length": limit,
            "order_by": "creation desc",
        }
        if status:
            params["filters"] = f'[["status","=","{status}"]]'
        result = await frappe_get("/api/resource/Quotation", params=params)
        return {"success": True, "data": result.get("data", [])}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/quotation/{qt_name}/create-order")
async def create_order_from_quotation(qt_name: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    """Step 2: Convert approved Quotation to Sales Order."""
    try:
        settings = await get_settings()
        company = settings.get("company_name", "RIAD SMART SYSTEM")
        currency = settings.get("currency", "UAH")
        
        qt_result = await frappe_get(f"/api/resource/Quotation/{qt_name}")
        quotation = qt_result.get("data", {})
        if not quotation:
            raise HTTPException(status_code=404, detail="Quotation not found")
        
        data = {
            "customer": quotation.get("party_name"),
            "company": company,
            "currency": currency,
            "conversion_rate": 1,
            "naming_series": "SO-.YYYY.-",
            "items": quotation.get("items", []),
            "transaction_date": body.get("transaction_date", ""),
        }
        result = await frappe_post("/api/resource/Sales Order", data=data)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/quotation/{qt_name}/create-po")
async def create_po_from_quotation(qt_name: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    """Step 2: After customer approves, create Purchase Order with wholesale prices."""
    try:
        settings = await get_settings()
        discount = float(settings.get("default_discount", 20)) / 100
        company = settings.get("company_name", "RIAD SMART SYSTEM")
        currency = settings.get("currency", "UAH")
        supplier = body.get("supplier", "")

        qt_result = await frappe_get(f"/api/resource/Quotation/{qt_name}")
        quotation = qt_result.get("data", {})
        if not quotation:
            raise HTTPException(status_code=404, detail="Quotation not found")

        po_items = []
        total_retail = 0
        total_wholesale = 0

        for item in quotation.get("items", []):
            retail_price = float(item.get("rate") or 0)
            qty = float(item.get("qty") or 1)
            wholesale_price = round(retail_price * (1 - discount), 2)

            po_items.append({
                "item_code": item.get("item_code"),
                "qty": qty,
                "rate": wholesale_price,
                "retail_price": retail_price,
                "retail_amount": round(retail_price * qty, 2),
                "item_margin": round((retail_price - wholesale_price) * qty, 2),
            })
            total_retail += round(retail_price * qty, 2)
            total_wholesale += round(wholesale_price * qty, 2)

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
            "items": po_items,
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
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/purchase-order/{po_name}/create-invoice")
async def create_invoice_from_po(po_name: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    """Step 3: After receiving goods, create Sales Invoice for customer."""
    try:
        settings = await get_settings()
        company = settings.get("company_name", "RIAD SMART SYSTEM")
        currency = settings.get("currency", "UAH")

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
            },
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
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

@router.post("/sales-invoice/{si_name}/create-act")
async def create_act_from_invoice(si_name: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    """Final Step: Create Installation Act from Sales Invoice."""
    try:
        si_result = await frappe_get(f"/api/resource/Sales Invoice/{si_name}")
        si = si_result.get("data", {})
        if not si:
            raise HTTPException(status_code=404, detail="Sales Invoice not found")
        
        data = {
            "customer": si.get("customer"),
            "company": si.get("company"),
            "transaction_date": body.get("date", ""),
            "items": si.get("items", []),
            "naming_series": "ACT-.YYYY.-",
        }
        result = await frappe_post("/api/resource/Installation Act", data=data)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/pricing/calculate")


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
