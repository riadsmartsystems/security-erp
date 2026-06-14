#!/usr/bin/env python3
"""
Wave 1: Migrate Customers & Contacts to ERPNext
Usage: python migrate_customers.py --input customers.csv --site erp.localhost
CSV columns: name, type, edrpou, phone, email, service_level, contact_name, contact_phone, contact_email
"""
import argparse
import csv
import sys
import subprocess
import json


def run_bench_query(site, query):
    result = subprocess.run(
        ["docker", "exec", "erpnext-backend", "bash", "-c",
         f"cd /home/frappe/frappe-bench && bench --site {site} mariadb -e \"{query}\""],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
        return None
    return result.stdout


def migrate_customers(csv_path, site="erp.localhost"):
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Found {len(rows)} customers to migrate")

    success = 0
    errors = []

    for row in rows:
        name = row.get("name", "").strip()
        if not name:
            errors.append(f"Row skipped: empty name")
            continue

        customer_type = row.get("type", "Company").strip()
        edrpou = row.get("edrpou", "").strip()
        phone = row.get("phone", "").strip()
        email = row.get("email", "").strip()
        service_level = row.get("service_level", "Standard").strip()

        check = run_bench_query(site,
            f'SELECT name FROM tabCustomer WHERE customer_name="{name}" LIMIT 1')
        if check and name in check:
            print(f"  Skip (exists): {name}")
            continue

        query = f"""INSERT IGNORE INTO tabCustomer
            (name, customer_name, customer_type, creation, modified, modified_by, owner, docstatus)
            VALUES ("{name}", "{name}", "{customer_type}", NOW(), NOW(), "Administrator", "Administrator", 0)"""

        result = run_bench_query(site, query)
        if result is not None:
            if edrpou:
                run_bench_query(site,
                    f'UPDATE tabCustomer SET customer_name="{name}" WHERE name="{name}"')
            print(f"  OK: {name}")
            success += 1
        else:
            errors.append(f"Failed: {name}")

    print(f"\nResult: {success} migrated, {len(errors)} errors")
    for e in errors:
        print(f"  ERROR: {e}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Migrate customers to ERPNext")
    parser.add_argument("--input", required=True, help="CSV file path")
    parser.add_argument("--site", default="erp.localhost", help="ERPNext site name")
    args = parser.parse_args()
    migrate_customers(args.input, args.site)
