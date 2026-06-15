#!/usr/bin/env python3
"""
Wave 1: Migrate Customers & Contacts to ERPNext via REST API
Usage: python migrate_customers.py --input customers.csv
CSV columns: name, type, edrpou, phone, email, service_level, contact_name, contact_phone, contact_email
"""
import argparse
import csv
import sys
from frappe_client import frappe_get, frappe_create, exists_by_filter


def migrate_customers(csv_path):
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Found {len(rows)} customers to migrate")
    success = 0
    errors = []

    for row in rows:
        name = row.get("name", "").strip()
        if not name:
            errors.append("Row skipped: empty name")
            continue

        existing = exists_by_filter("Customer", "customer_name", name)
        if existing:
            print(f"  Skip (exists): {name} -> {existing}")
            continue

        customer_type = row.get("type", "Company").strip()
        edrpou = row.get("edrpou", "").strip()
        phone = row.get("phone", "").strip()
        email = row.get("email", "").strip()
        service_level = row.get("service_level", "Standard").strip()

        data = {
            "customer_name": name,
            "customer_type": customer_type,
            "customer_group": "All Customer Groups",
            "territory": "All Territories",
        }
        if edrpou:
            data["edrpou_code"] = edrpou
        if phone:
            data["primary_phone"] = phone
        if email:
            data["primary_email"] = email
        if service_level:
            data["service_level"] = service_level

        result = frappe_create("Customer", data)
        if result:
            customer_id = result.get("name", "unknown")
            print(f"  OK: {name} ({customer_id})")
            success += 1

            contact_name = row.get("contact_name", "").strip()
            if contact_name:
                contact_data = {
                    "first_name": contact_name,
                    "links": [{"link_doctype": "Customer", "link_name": customer_id}],
                }
                contact_phone = row.get("contact_phone", "").strip()
                contact_email = row.get("contact_email", "").strip()
                if contact_phone:
                    contact_data["phone_nos"] = [{"phone": contact_phone}]
                if contact_email:
                    contact_data["email_ids"] = [{"email_id": contact_email}]
                frappe_create("Contact", contact_data)
        else:
            errors.append(f"Failed: {name}")

    print(f"\nResult: {success} migrated, {len(errors)} errors")
    for e in errors:
        print(f"  ERROR: {e}")
    return len(errors) == 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Migrate customers to ERPNext")
    parser.add_argument("--input", required=True, help="CSV file path")
    args = parser.parse_args()
    success = migrate_customers(args.input)
    sys.exit(0 if success else 1)
