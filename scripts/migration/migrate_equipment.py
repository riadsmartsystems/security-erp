#!/usr/bin/env python3
"""
Wave 3: Migrate Equipment to ERPNext via REST API
Usage: python migrate_equipment.py --input equipment.csv
CSV columns: equipment_code, object_code, equipment_type, vendor, model, serial_number, firmware, status, install_date, warranty_end
"""
import argparse
import csv
import sys
from frappe_client import frappe_get, frappe_create, exists_by_filter


def get_or_create_equipment_type(type_name):
    results = frappe_get("Equipment Type",
        filters=[["type_name", "=", type_name]],
        fields=["name"], limit=1)
    if results:
        return results[0].get("name")
    code = type_name[:3].upper()
    result = frappe_create("Equipment Type", {
        "type_name": type_name,
        "type_code": code,
        "category": "Other",
    })
    if result:
        return result.get("name")
    return None


def get_or_create_vendor(vendor_name):
    results = frappe_get("Vendor",
        filters=[["vendor_name", "=", vendor_name]],
        fields=["name"], limit=1)
    if results:
        return results[0].get("name")
    code = vendor_name.replace(" ", "_")[:10].upper()
    result = frappe_create("Vendor", {
        "vendor_name": vendor_name,
        "vendor_code": code,
    })
    if result:
        return result.get("name")
    return None


def migrate_equipment(csv_path):
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Found {len(rows)} equipment items to migrate")
    success = 0
    errors = []

    for row in rows:
        code = row.get("equipment_code", "").strip()
        obj_code = row.get("object_code", "").strip()
        if not code or not obj_code:
            errors.append(f"Row skipped: missing equipment_code or object_code")
            continue

        existing = exists_by_filter("Equipment", "equipment_code", code)
        if existing:
            print(f"  Skip (exists): {code} -> {existing}")
            continue

        object_name = exists_by_filter("Security Object", "object_code", obj_code)
        if not object_name:
            errors.append(f"Object not found: {obj_code} for equipment {code}")
            continue

        eq_type_name = row.get("equipment_type", "Other").strip()
        vendor_name = row.get("vendor", "").strip()

        eq_type_id = None
        if eq_type_name:
            eq_type_id = get_or_create_equipment_type(eq_type_name)
            if not eq_type_id:
                errors.append(f"Cannot create Equipment Type: {eq_type_name}")
                continue

        vendor_id = None
        if vendor_name:
            vendor_id = get_or_create_vendor(vendor_name)
            if not vendor_id:
                errors.append(f"Cannot create Vendor: {vendor_name}")
                continue

        data = {
            "equipment_code": code,
            "security_object": object_name,
            "status": row.get("status", "Planned").strip().replace("_", " ").title(),
        }
        if eq_type_id:
            data["equipment_type"] = eq_type_id
        if vendor_id:
            data["vendor"] = vendor_id
        model = row.get("model", "").strip()
        if model:
            data["model"] = model
        serial = row.get("serial_number", "").strip()
        if serial:
            data["serial_number"] = serial
        firmware = row.get("firmware", "").strip()
        if firmware:
            data["firmware_version"] = firmware
        install_date = row.get("install_date", "").strip()
        warranty_end = row.get("warranty_end", "").strip()
        if install_date:
            data["install_date"] = install_date
        if warranty_end:
            data["warranty_end_date"] = warranty_end

        result = frappe_create("Equipment", data)
        if result:
            print(f"  OK: {code} - {row.get('model', '')} ({row.get('serial_number', '')})")
            success += 1
        else:
            errors.append(f"Failed: {code}")

    print(f"\nResult: {success} migrated, {len(errors)} errors")
    for e in errors:
        print(f"  ERROR: {e}")
    return len(errors) == 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Migrate equipment to ERPNext")
    parser.add_argument("--input", required=True, help="CSV file path")
    args = parser.parse_args()
    success = migrate_equipment(args.input)
    sys.exit(0 if success else 1)
