#!/usr/bin/env python3
"""
Wave 2: Migrate Security Objects to ERPNext via REST API
Usage: python migrate_objects.py --input objects.csv
CSV columns: object_code, customer_name, name, address, gps_lat, gps_lon, object_type, service_level
"""
import argparse
import csv
import sys
from frappe_client import frappe_get, frappe_create, exists_by_filter


def migrate_objects(csv_path):
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Found {len(rows)} objects to migrate")
    success = 0
    errors = []

    for row in rows:
        code = row.get("object_code", "").strip()
        obj_name = row.get("name", "").strip()
        if not code or not obj_name:
            errors.append(f"Row skipped: missing code or name")
            continue

        existing = exists_by_filter("Security Object", "object_code", code)
        if existing:
            print(f"  Skip (exists): {code} -> {existing}")
            continue

        customer_name = row.get("customer_name", "").strip()
        customer_id = None
        if customer_name:
            customers = frappe_get("Customer",
                filters=[["customer_name", "=", customer_name]],
                fields=["name"], limit=1)
            if customers:
                customer_id = customers[0].get("name")

        data = {
            "object_code": code,
            "object_name": obj_name,
            "object_type": row.get("object_type", "Office").strip().title(),
            "service_level": row.get("service_level", "Standard").strip(),
            "status": "Active",
            "address": row.get("address", "").strip(),
        }
        if customer_id:
            data["customer"] = customer_id
        gps_lat = row.get("gps_lat", "").strip()
        gps_lon = row.get("gps_lon", "").strip()
        if gps_lat:
            data["gps_lat"] = float(gps_lat)
        if gps_lon:
            data["gps_lon"] = float(gps_lon)

        result = frappe_create("Security Object", data)
        if result:
            print(f"  OK: {code} - {obj_name}")
            success += 1
        else:
            errors.append(f"Failed: {code}")

    print(f"\nResult: {success} migrated, {len(errors)} errors")
    for e in errors:
        print(f"  ERROR: {e}")
    return len(errors) == 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Migrate objects to ERPNext")
    parser.add_argument("--input", required=True, help="CSV file path")
    args = parser.parse_args()
    success = migrate_objects(args.input)
    sys.exit(0 if success else 1)
