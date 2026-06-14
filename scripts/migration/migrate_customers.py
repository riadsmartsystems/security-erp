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


def run_bench_query(site, query):
    escaped = query.replace("'", "'\\''")
    cmd = f"cd /home/frappe/frappe-bench && bench --site {site} mariadb -e '{escaped}'"
    result = subprocess.run(
        ["docker", "exec", "erpnext-backend", "bash", "-c", cmd],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Error: {result.stderr[:200]}")
        return None
    return result.stdout


def sql_str(val):
    return val.replace("'", "''")


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
            errors.append("Row skipped: empty name")
            continue

        customer_type = row.get("type", "Company").strip()
        edrpou = row.get("edrpou", "").strip()
        phone = row.get("phone", "").strip()
        email = row.get("email", "").strip()
        service_level = row.get("service_level", "Standard").strip()
        contact_name = row.get("contact_name", "").strip()
        contact_phone = row.get("contact_phone", "").strip()
        contact_email = row.get("contact_email", "").strip()

        safe_name = sql_str(name)
        safe_type = sql_str(customer_type)

        check = run_bench_query(site,
            f"SELECT name FROM tabCustomer WHERE customer_name='{safe_name}' LIMIT 1")
        if check and safe_name in check:
            print(f"  Skip (exists): {name}")
            continue

        customer_id = f"CUST-{success+1:04d}"
        query = f"""INSERT IGNORE INTO tabCustomer
            (name, customer_name, customer_type, creation, modified, modified_by, owner, docstatus)
            VALUES ('{customer_id}', '{safe_name}', '{safe_type}', NOW(), NOW(), 'Administrator', 'Administrator', 0)"""

        result = run_bench_query(site, query)
        if result is not None:
            if edrpou:
                run_bench_query(site,
                    f"UPDATE tabCustomer SET edrpou_code='{sql_str(edrpou)}' WHERE name='{customer_id}'")
            if phone:
                run_bench_query(site,
                    f"UPDATE tabCustomer SET primary_phone='{sql_str(phone)}' WHERE name='{customer_id}'")
            if email:
                run_bench_query(site,
                    f"UPDATE tabCustomer SET primary_email='{sql_str(email)}' WHERE name='{customer_id}'")
            if service_level:
                run_bench_query(site,
                    f"UPDATE tabCustomer SET service_level='{sql_str(service_level)}' WHERE name='{customer_id}'")
            print(f"  OK: {name} ({customer_id})")
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
