#!/usr/bin/env python3
"""
Wave 4: Migrate Service Tickets to ERPNext via REST API
Usage: python migrate_tickets.py --input tickets.csv
CSV columns: ticket_number, customer_name, object_code, ticket_type, priority, status, description, created_at
"""
import argparse
import csv
import sys
from frappe_client import frappe_get, frappe_create, exists_by_filter

TICKET_TYPE_MAP = {
    "incident": "Incident",
    "service_request": "Service Request",
    "maintenance": "Preventive Maintenance",
    "preventive_maintenance": "Preventive Maintenance",
    "installation": "Installation",
    "warranty": "Warranty",
    "inspection": "Inspection",
    "emergency": "Emergency",
}


def _map_ticket_type(raw):
    key = raw.lower().replace(" ", "_")
    return TICKET_TYPE_MAP.get(key, raw.title())


def migrate_tickets(csv_path):
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Found {len(rows)} tickets to migrate")
    success = 0
    errors = []

    for row in rows:
        number = row.get("ticket_number", "").strip()
        if not number:
            errors.append("Row skipped: missing ticket_number")
            continue

        existing = exists_by_filter("Service Ticket", "ticket_number", number)
        if existing:
            print(f"  Skip (exists): {number} -> {existing}")
            continue

        customer_name = row.get("customer_name", "").strip()
        customer_id = None
        if customer_name:
            customers = frappe_get("Customer",
                filters=[["customer_name", "=", customer_name]],
                fields=["name"], limit=1)
            if customers:
                customer_id = customers[0].get("name")

        object_code = row.get("object_code", "").strip()
        object_name = None
        if object_code:
            object_name = exists_by_filter("Security Object", "object_code", object_code)

        data = {
            "ticket_number": number,
            "ticket_type": _map_ticket_type(row.get("ticket_type", "Incident").strip()),
            "priority": row.get("priority", "Medium").strip().title(),
            "status": row.get("status", "New").strip().replace("_", " ").title(),
            "title": row.get("title", number).strip(),
            "description": row.get("description", "").strip(),
        }
        if customer_id:
            data["customer"] = customer_id
        if object_name:
            data["security_object"] = object_name

        result = frappe_create("Service Ticket", data)
        if result:
            ticket_type = data["ticket_type"]
            priority = data["priority"]
            print(f"  OK: {number} ({ticket_type}/{priority})")
            success += 1
        else:
            errors.append(f"Failed: {number}")

    print(f"\nResult: {success} migrated, {len(errors)} errors")
    for e in errors:
        print(f"  ERROR: {e}")
    return len(errors) == 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Migrate tickets to ERPNext")
    parser.add_argument("--input", required=True, help="CSV file path")
    args = parser.parse_args()
    success = migrate_tickets(args.input)
    sys.exit(0 if success else 1)
