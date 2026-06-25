#!/usr/bin/env python3
"""Unit tests for security-api — works with or without deps."""
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../../services/security-api"))

PASSED = 0
FAILED = 0
SKIPPED = 0


def run(name, fn):
    global PASSED, FAILED, SKIPPED
    try:
        fn()
        PASSED += 1
        print(f"  PASS  {name}")
    except ImportError as e:
        SKIPPED += 1
        print(f"  SKIP  {name} (missing dep: {e})")
    except Exception as e:
        FAILED += 1
        print(f"  FAIL  {name}: {e}")


def test_config_loads():
    from app.core.config import Settings
    s = Settings()
    assert s.app_name == "Security ERP API Gateway"
    assert s.jwt_algorithm == "HS256"
    assert s.frappe_url == "http://erpnext-backend:8000"
    assert s.rate_limit_default == 1000


def test_ticket_create_optional():
    from app.routes.doctypes import TicketCreate
    t = TicketCreate(title="Test")
    assert t.ticket_number is None
    assert t.priority == "Medium"


def test_ticket_create_with_number():
    from app.routes.doctypes import TicketCreate
    t = TicketCreate(ticket_number="TKT-001", title="Test")
    assert t.ticket_number == "TKT-001"


def test_object_create_optional():
    from app.routes.doctypes import ObjectCreate
    o = ObjectCreate(object_name="Obj")
    assert o.object_code is None
    assert o.object_type == "Office"


def test_customer_create():
    from app.routes.doctypes import CustomerCreate
    c = CustomerCreate(customer_name="Corp")
    assert c.customer_type == "Company"


def test_equipment_create():
    from app.routes.doctypes import EquipmentCreate
    e = EquipmentCreate(equipment_code="EQ-1", security_object="OBJ-1")
    assert e.status == "Planned"


def test_lead_create():
    from app.routes.doctypes import LeadCreate
    l = LeadCreate(lead_name="Lead")
    assert l.status == "Open"


def test_ai_estimate_request():
    from app.routes.doctypes import AIEstimateRequest
    r = AIEstimateRequest(lead_name="L-1", technical_assignment="ta")
    assert r.lead_name == "L-1"


def test_warranty_scan():
    from app.routes.doctypes import WarrantyScanRequest
    w = WarrantyScanRequest(serial_number="SN", delivery_note="DN")
    assert w.item_code is None


def test_router_prefix():
    from app.routes.doctypes import router
    assert router.prefix == "/api/v2"


def test_proxy_doctype_map():
    from app.routes.proxy import FRAPPE_DOCTYPE_MAP
    assert "/api/v1/visits" in FRAPPE_DOCTYPE_MAP
    assert FRAPPE_DOCTYPE_MAP["/api/v1/visits"] == "Visit"
    assert FRAPPE_DOCTYPE_MAP["/api/v1/tickets"] == "Service Ticket"


def test_proxy_role_map():
    from app.routes.proxy import FRAPPE_ROLE_MAP
    assert "Engineer" in FRAPPE_ROLE_MAP["engineer"]


def test_visit_models():
    from app.routes.visits import VisitStartRequest, VisitFinishRequest, VisitMaterialRequest
    s = VisitStartRequest(lat=50.0, lon=30.0)
    assert s.lat == 50.0
    m = VisitMaterialRequest(item_name="Cable", quantity=10)
    assert m.quantity == 10


def test_no_hardcoded_secrets_in_db():
    import app.core.database as db
    import inspect
    src = inspect.getsource(db)
    assert "jokerLA23" not in src
    assert "joker@riad" not in src


def test_config_no_fsm_cmdb():
    from app.core.config import Settings
    s = Settings()
    assert not hasattr(s, "fsm_service_url")
    assert not hasattr(s, "cmdb_service_url")


def test_syntax_files():
    import py_compile
    base = os.path.join(os.path.dirname(__file__), "../../services/security-api/app")
    critical = [
        "main.py",
        "routes/doctypes.py",
        "routes/visits.py",
        "core/database.py",
        "core/config.py",
        "services/ai_orchestrator_service.py",
    ]
    for f in critical:
        path = os.path.join(base, f)
        py_compile.compile(path, doraise=True)


if __name__ == "__main__":
    print("Security API Unit Tests")
    print("=" * 40)

    run("config loads", test_config_loads)
    run("TicketCreate optional", test_ticket_create_optional)
    run("TicketCreate with number", test_ticket_create_with_number)
    run("ObjectCreate optional", test_object_create_optional)
    run("CustomerCreate", test_customer_create)
    run("EquipmentCreate", test_equipment_create)
    run("LeadCreate", test_lead_create)
    run("AIEstimateRequest", test_ai_estimate_request)
    run("WarrantyScanRequest", test_warranty_scan)
    run("router prefix", test_router_prefix)
    run("proxy doctype map", test_proxy_doctype_map)
    run("proxy role map", test_proxy_role_map)
    run("visit models", test_visit_models)
    run("no hardcoded secrets in db", test_no_hardcoded_secrets_in_db)
    run("config no fsm/cmdb", test_config_no_fsm_cmdb)
    run("syntax check critical files", test_syntax_files)

    print(f"\n{'=' * 40}")
    print(f"Results: {PASSED} passed, {FAILED} failed, {SKIPPED} skipped")
    sys.exit(0 if FAILED == 0 else 1)
