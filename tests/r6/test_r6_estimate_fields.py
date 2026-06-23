"""FIX-3 / R6 — AI Estimate DocType field schema + permlevel tests.

Tests run against JSON files only — no Frappe runtime required.
All assertions must pass after bench migrate is run.
"""
import json
import pathlib

import pytest

BASE = pathlib.Path(__file__).parent.parent.parent
ESTIMATE_JSON = (
    BASE
    / "erpnext/security_erp/security_erp/security_erp/doctype/ai_estimate/estimate.json"
)
ESTIMATE_ITEM_JSON = (
    BASE
    / "erpnext/security_erp/security_erp/security_erp/doctype/ai_estimate_item/estimate_item.json"
)


def _field(fields, name):
    return next((f for f in fields if f["fieldname"] == name), None)


def _perm(perms, role, permlevel):
    return any(
        p.get("role") == role and p.get("permlevel") == permlevel for p in perms
    )


@pytest.fixture(scope="module")
def estimate():
    return json.loads(ESTIMATE_JSON.read_text())


@pytest.fixture(scope="module")
def estimate_item():
    return json.loads(ESTIMATE_ITEM_JSON.read_text())


# ---------------------------------------------------------------------------
# DocType identity (DECISIONS B1 Вісь 3)
# ---------------------------------------------------------------------------


class TestDocTypeNames:
    def test_estimate_name_is_ai_estimate(self, estimate):
        assert estimate["name"] == "AI Estimate"

    def test_estimate_item_name_is_ai_estimate_item(self, estimate_item):
        assert estimate_item["name"] == "AI Estimate Item"

    def test_estimate_items_table_references_ai_estimate_item(self, estimate):
        tbl = _field(estimate["fields"], "items")
        assert tbl is not None
        assert tbl["options"] == "AI Estimate Item"


# ---------------------------------------------------------------------------
# New header fields on AI Estimate (permlevel=0 unless stated)
# ---------------------------------------------------------------------------


class TestEstimateNewFields:
    def test_origin_field_exists(self, estimate):
        f = _field(estimate["fields"], "origin")
        assert f is not None, "Field 'origin' missing"
        assert f["fieldtype"] == "Select"
        assert "manual" in f["options"]
        assert "ai" in f["options"]
        assert "imported" in f["options"]

    def test_variant_field_exists(self, estimate):
        f = _field(estimate["fields"], "variant")
        assert f is not None, "Field 'variant' missing"
        assert f["fieldtype"] == "Data"

    def test_reviewed_by_permlevel1(self, estimate):
        f = _field(estimate["fields"], "reviewed_by")
        assert f is not None, "Field 'reviewed_by' missing"
        assert f["fieldtype"] == "Link"
        assert f.get("options") == "User"
        assert f.get("permlevel") == 1

    def test_reviewed_at_permlevel1(self, estimate):
        f = _field(estimate["fields"], "reviewed_at")
        assert f is not None, "Field 'reviewed_at' missing"
        assert f["fieldtype"] == "Datetime"
        assert f.get("permlevel") == 1

    def test_total_cost_permlevel1(self, estimate):
        f = _field(estimate["fields"], "total_cost")
        assert f is not None, "Field 'total_cost' missing"
        assert f["fieldtype"] == "Currency"
        assert f.get("permlevel") == 1

    def test_total_margin_permlevel1(self, estimate):
        f = _field(estimate["fields"], "total_margin")
        assert f is not None, "Field 'total_margin' missing"
        assert f["fieldtype"] == "Currency"
        assert f.get("permlevel") == 1


# ---------------------------------------------------------------------------
# Permlevel=1 grants on AI Estimate (H7: Director/billing see costs)
# ---------------------------------------------------------------------------


class TestEstimatePermissions:
    def test_system_manager_has_permlevel1(self, estimate):
        assert _perm(estimate["permissions"], "System Manager", 1), (
            "System Manager must have permlevel=1 read access"
        )

    def test_sales_manager_has_permlevel1(self, estimate):
        assert _perm(estimate["permissions"], "Sales Manager", 1), (
            "Sales Manager must have permlevel=1 read access"
        )

    def test_service_manager_no_permlevel1(self, estimate):
        assert not _perm(estimate["permissions"], "Service Manager", 1), (
            "Service Manager (engineer) must NOT have permlevel=1 access — H7"
        )


# ---------------------------------------------------------------------------
# New item fields on AI Estimate Item
# ---------------------------------------------------------------------------


class TestEstimateItemNewFields:
    def test_purchase_rate_permlevel1(self, estimate_item):
        f = _field(estimate_item["fields"], "purchase_rate")
        assert f is not None, "Field 'purchase_rate' missing"
        assert f["fieldtype"] == "Currency"
        assert f.get("permlevel") == 1

    def test_profit_permlevel1(self, estimate_item):
        f = _field(estimate_item["fields"], "profit")
        assert f is not None, "Field 'profit' missing"
        assert f["fieldtype"] == "Currency"
        assert f.get("permlevel") == 1

    def test_margin_pct_permlevel1(self, estimate_item):
        f = _field(estimate_item["fields"], "margin_pct")
        assert f is not None, "Field 'margin_pct' missing"
        assert f["fieldtype"] == "Percent"
        assert f.get("permlevel") == 1

    def test_line_source_field_exists(self, estimate_item):
        f = _field(estimate_item["fields"], "line_source")
        assert f is not None, "Field 'line_source' missing"
        assert f["fieldtype"] == "Select"
        assert "manual" in f["options"]
        assert "catalog" in f["options"]
        assert "ai" in f["options"]
