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


async def get_settings(sid: str = "") -> dict:
    global _settings_cache
    if _settings_cache:
        return _settings_cache
    try:
        result = await frappe_get("/api/resource/Security ERP Settings/Security ERP Settings", sid=sid)
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
    object_code: Optional[str] = None
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
    ticket_number: Optional[str] = None
    customer: Optional[str] = None
    security_object: Optional[str] = None
    ticket_type: str = "Incident"
    priority: str = "Medium"
    title: str
    description: Optional[str] = None


class LeadCreate(BaseModel):
    lead_name: str
    mobile_no: Optional[str] = None
    object_address: Optional[str] = None
    technical_assignment: Optional[str] = None
    status: str = "Open"


class AIEstimateRequest(BaseModel):
    lead_name: str
    technical_assignment: str


class WarrantyScanRequest(BaseModel):
    serial_number: str
    delivery_note: str
    item_code: Optional[str] = None


@router.get("/settings")
async def read_settings(current_user: CurrentUser = Depends(get_current_user)):
    data = await get_settings(current_user.frappe_sid)
    return {"success": True, "data": data}


@router.put("/settings")
async def update_settings(body: dict, current_user: CurrentUser = Depends(get_current_user)):
    global _settings_cache
    try:
        result = await frappe_put(
            "/api/resource/Security ERP Settings/Security ERP Settings",
            data=body,
            sid=current_user.frappe_sid,
        )
        _settings_cache = None
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/quotations/{name}")
async def get_quotation_by_name(name: str, current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get(f"/api/resource/Quotation/{name}", sid=current_user.frappe_sid)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.put("/quotations/{name}")
async def update_quotation_discount(name: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    try:
        discount = float(body.get("discount_percentage", 0))
        payload = {"additional_discount_percentage": discount}
        result = await frappe_put(f"/api/resource/Quotation/{name}", data=payload, sid=current_user.frappe_sid)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.post("/contracts")
async def create_contract(body: dict, current_user: CurrentUser = Depends(get_current_user)):
    try:
        payload = {
            "customer": body.get("customer"),
            "contract_type": body.get("contract_type"),
            "start_date": body.get("start_date"),
            "end_date": body.get("end_date"),
            "notes": body.get("notes"),
        }
        result = await frappe_post("/api/resource/Contract", data=payload, sid=current_user.frappe_sid)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.post("/installation-acts")
async def create_installation_act(body: dict, current_user: CurrentUser = Depends(get_current_user)):
    try:
        items_list = []
        for item in body.get("items", []):
            items_list.append({
                "item_code": item.get("item_code"),
                "qty": float(item.get("qty", 1)),
                "rate": float(item.get("rate", 0)),
                "serial_number": item.get("serial_number"),
                "location": item.get("location"),
            })
        payload = {
            "customer": body.get("customer"),
            "project": body.get("project"),
            "object_address": body.get("object_address"),
            "labor_hours": float(body.get("labor_hours", 0)),
            "notes": body.get("notes"),
            "items": items_list,
        }
        result = await frappe_post("/api/resource/Installation Act", data=payload, sid=current_user.frappe_sid)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.post("/warranty-cards")
async def create_warranty_card(body: dict, current_user: CurrentUser = Depends(get_current_user)):
    try:
        items_list = []
        for item in body.get("items", []):
            items_list.append({
                "item_code": item.get("item_code"),
                "serial_number": item.get("serial_number"),
                "warranty_months": int(item.get("warranty_months", 24)),
            })
        payload = {
            "customer": body.get("customer"),
            "sales_invoice": body.get("sales_invoice"),
            "items": items_list,
        }
        result = await frappe_post("/api/resource/Warranty Card", data=payload, sid=current_user.frappe_sid)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/purchase-orders/{name}/items")
async def get_po_items(name: str, current_user: CurrentUser = Depends(get_current_user)):
    try:
        r = await frappe_get(f"/api/resource/Purchase Order/{name}", sid=current_user.frappe_sid)
        return {"success": True, "data": r.get("data", {}).get("items", [])}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.get("/scenarios")
async def get_scenarios(current_user: CurrentUser = Depends(get_current_user)):
    try:
        result = await frappe_get("/api/resource/Security Scenario", params={
            "fields": '["name","scenario_name","security_type","description"]',
            "limit_page_length": 50
        }, sid=current_user.frappe_sid)
        return {"success": True, "data": result.get("data", [])}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.post("/scenarios/{scenario_id}/apply")
async def apply_scenario(scenario_id: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    sid = current_user.frappe_sid
    try:
        items_result = await frappe_get(
            "/api/resource/Security Scenario Item",
            params={"filters": f'[["parent","=","{scenario_id}"]]'},
            sid=sid,
        )
        scenario_items = items_result.get("data", [])
        if not scenario_items:
            raise HTTPException(status_code=404, detail="No items found for this scenario")
        quotation_name = body.get("quotation")
        if quotation_name:
            return {"success": True, "items": scenario_items}
        lead_name = body.get("lead_name")
        if lead_name:
            lead_res = await frappe_get(f"/api/resource/Lead/{lead_name}", sid=sid)
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
            await frappe_put(
                f"/api/resource/Lead/{lead_name}",
                data={"ai_estimate_result": json.dumps(current_estimate)},
                sid=sid,
            )
            return {"success": True, "data": current_estimate}
        raise HTTPException(status_code=400, detail="Either 'quotation' or 'lead_name' is required")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/warranty/scan")
async def scan_serial_number(body: WarrantyScanRequest, current_user: CurrentUser = Depends(get_current_user)):
    sid = current_user.frappe_sid
    try:
        warranty_card_name = f"WARR-{body.delivery_note}"
        card_exists = await frappe_get(f"/api/resource/Warranty Card/{warranty_card_name}", sid=sid)
        if not card_exists.get("data"):
            await frappe_post("/api/resource/Warranty Card", data={
                "name": warranty_card_name,
                "sales_invoice": body.delivery_note,
                "status": "Active"
            }, sid=sid)
        await frappe_post("/api/resource/Warranty Card Item", data={
            "parent": warranty_card_name,
            "item_code": body.item_code,
            "serial_number": body.serial_number,
            "warranty_expiry": "2027-06-17"
        }, sid=sid)
        return {"success": True, "message": f"Serial {body.serial_number} registered"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/warranty/card/{card_id}")
async def get_warranty_card(card_id: str, current_user: CurrentUser = Depends(get_current_user)):
    sid = current_user.frappe_sid
    try:
        result = await frappe_get(f"/api/resource/Warranty Card/{card_id}", sid=sid)
        items = await frappe_get("/api/resource/Warranty Card Item", params={
            "filters": f'[["parent","=","{card_id}"]]'
        }, sid=sid)
        return {"success": True, "data": result.get("data"), "items": items.get("data", [])}
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


# =========================================================================
# BUSINESS FLOW: Quotation -> PO -> SI
# =========================================================================

async def _get_retail_prices(items, sid: str):
    total_retail = 0
    for item in items:
        item_code = item.get("item_code")
        qty = item.get("qty", 1)
        retail_price = item.get("rate", 0)
        if item_code:
            try:
                result = await frappe_get(f"/api/resource/Item/{item_code}", sid=sid)
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
    sid = current_user.frappe_sid
    try:
        erp_settings = await get_settings(sid)
        company = erp_settings.get("company_name", "RIAD SMART SYSTEM")
        currency = erp_settings.get("currency", "UAH")

        items = body.get("items", [])
        items, total_retail = await _get_retail_prices(items, sid)

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
            "terms": erp_settings.get("payment_terms", ""),
        }
        result = await frappe_post("/api/resource/Quotation", data=data, sid=sid)
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
    try:
        params = {
            "fields": '["name","party_name","grand_total","status","transaction_date"]',
            "limit_page_length": limit,
            "order_by": "creation desc",
        }
        if status:
            params["filters"] = f'[["status","=","{status}"]]'
        result = await frappe_get("/api/resource/Quotation", params=params, sid=current_user.frappe_sid)
        return {"success": True, "data": result.get("data", [])}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/quotation/{qt_name}/create-order")
async def create_order_from_quotation(qt_name: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    sid = current_user.frappe_sid
    try:
        erp_settings = await get_settings(sid)
        company = erp_settings.get("company_name", "RIAD SMART SYSTEM")
        currency = erp_settings.get("currency", "UAH")

        qt_result = await frappe_get(f"/api/resource/Quotation/{qt_name}", sid=sid)
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
        result = await frappe_post("/api/resource/Sales Order", data=data, sid=sid)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/quotation/{qt_name}/create-po")
async def create_po_from_quotation(qt_name: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    sid = current_user.frappe_sid
    try:
        erp_settings = await get_settings(sid)
        discount = float(erp_settings.get("default_discount", 20)) / 100
        company = erp_settings.get("company_name", "RIAD SMART SYSTEM")
        currency = erp_settings.get("currency", "UAH")
        supplier = body.get("supplier", "")

        qt_result = await frappe_get(f"/api/resource/Quotation/{qt_name}", sid=sid)
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
        result = await frappe_post("/api/resource/Purchase Order", data=data, sid=sid)
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
    sid = current_user.frappe_sid
    try:
        erp_settings = await get_settings(sid)
        company = erp_settings.get("company_name", "RIAD SMART SYSTEM")
        currency = erp_settings.get("currency", "UAH")

        po_result = await frappe_get(f"/api/resource/Purchase Order/{po_name}", sid=sid)
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
                discount = float(erp_settings.get("default_discount", 20)) / 100
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
        si_result = await frappe_post("/api/resource/Sales Invoice", data=si_data, sid=sid)
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


@router.post("/sales-invoice/{si_name}/create-act")
async def create_act_from_invoice(si_name: str, body: dict, current_user: CurrentUser = Depends(get_current_user)):
    sid = current_user.frappe_sid
    try:
        si_result = await frappe_get(f"/api/resource/Sales Invoice/{si_name}", sid=sid)
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
        result = await frappe_post("/api/resource/Installation Act", data=data, sid=sid)
        return {"success": True, "data": result.get("data", {})}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/pricing/calculate")
async def calculate_pricing(
    item_code: str,
    qty: int = Query(1, ge=1),
    current_user: CurrentUser = Depends(get_current_user),
):
    sid = current_user.frappe_sid
    try:
        erp_settings = await get_settings(sid)
        discount = float(erp_settings.get("default_discount", 20)) / 100

        result = await frappe_get(f"/api/resource/Item/{item_code}", sid=sid)
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
    sid = current_user.frappe_sid
    try:
        po_result = await frappe_get(f"/api/resource/Purchase Order/{po_name}", sid=sid)
        po = po_result.get("data", {})
        po_total = float(po.get("grand_total") or 0)

        si_result = await frappe_get(f"/api/resource/Sales Invoice/{si_name}", sid=sid)
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


@router.post("/scenarios/{scenario_name}/calculate")
async def calculate_scenario(
    scenario_name: str,
    body: dict,
    current_user: CurrentUser = Depends(get_current_user),
):
    cameras_count = int(body.get("cameras_count", 4))
    cable_meters = float(body.get("cable_meters", 20))
    total_watts = float(body.get("total_watts", 0))

    try:
        r = await frappe_get(f"/api/resource/Security Scenario/{scenario_name}", sid=current_user.frappe_sid)
        scenario_data = r.get("data", {})
        items = scenario_data.get("items", [])
        calculated = []

        for item in items:
            qty = float(item.get("qty", 1))
            formula = item.get("qty_formula")
            if formula:
                try:
                    safe_vars = {"cameras_count": cameras_count, "cable_meters": cable_meters}
                    qty = float(eval(formula, {"__builtins__": {}}, safe_vars))
                except Exception:
                    pass
            qty = max(0, round(qty))
            if qty == 0 and not item.get("is_optional"):
                continue
            calculated.append({
                "item_code": item.get("item_code"),
                "item_name": item.get("item_name"),
                "qty": qty,
                "is_optional": item.get("is_optional", 0),
                "option_group": item.get("option_group"),
            })

        if total_watts > 0:
            va = total_watts * 1.3 / 0.85
            size = next((s for s in [300, 600, 1000, 1500, 2000, 3000] if s >= va), 3000)
            calculated.append({
                "item_code": f"UPS_{size}VA",
                "item_name": f"ДБЖ {size} ВА (розрахунковий)",
                "qty": 1,
                "is_optional": 1,
                "option_group": "Резервне живлення",
                "required_va": round(va),
            })

        return {
            "success": True,
            "data": {
                "scenario": scenario_name,
                "items": calculated,
                "params": {
                    "cameras_count": cameras_count,
                    "cable_meters": cable_meters,
                    "total_watts": total_watts,
                },
            },
        }
    except Exception as e:
        raise HTTPException(500, str(e))
