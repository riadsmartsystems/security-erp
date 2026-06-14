#!/usr/bin/env python3
"""
Wave 4: Migrate open Service Tickets to ERPNext (MariaDB)
Usage: python migrate_tickets.py --input tickets.csv --site erp.localhost
CSV columns: ticket_number, customer_name, object_code, ticket_type, priority, status, description, created_at
"""
import argparse
import csv
import subprocess


def run_bench_query(site, query):
    escaped = query.replace("'", "'\\''")
    cmd = f"cd /home/frappe/frappe-bench && bench --site {site} mariadb -e '{escaped}'"
    result = subprocess.run(
        ["docker", "exec", "erpnext-backend", "bash", "-c", cmd],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"  Error: {result.stderr[:200]}")
        return None
    return result.stdout


def sql_str(val):
    return val.replace("'", "''")


def migrate_tickets(csv_path, site="erp.localhost"):
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Found {len(rows)} tickets to migrate")
    success = 0

    for row in rows:
        number = row.get("ticket_number", "").strip()
        desc = sql_str(row.get("description", "").strip())
        ticket_type = row.get("ticket_type", "Incident").strip().replace("_", " ").title()
        priority = row.get("priority", "Medium").strip().title()
        status = row.get("status", "New").strip().replace("_", " ").title()
        title = sql_str(row.get("title", number).strip())
        created = row.get("created_at", "NOW()").strip()

        check = run_bench_query(site,
            f"SELECT name FROM `tabService Ticket` WHERE ticket_number='{number}' LIMIT 1")
        if check and number in check:
            print(f"  Skip (exists): {number}")
            continue

        created_val = f"'{created}'" if created != "NOW()" else "NOW()"

        query = f"""INSERT INTO `tabService Ticket`
            (name, ticket_number, ticket_type, priority, status, title, description, creation, modified, modified_by, owner, docstatus)
            VALUES ('{number}', '{number}', '{ticket_type}', '{priority}', '{status}', '{title}', '{desc}', {created_val}, NOW(), 'Administrator', 'Administrator', 0)
            ON DUPLICATE KEY UPDATE modified=NOW()"""

        result = run_bench_query(site, query)
        if result is not None:
            print(f"  OK: {number} ({ticket_type}/{priority})")
            success += 1
        else:
            print(f"  FAIL: {number}")

    print(f"\nResult: {success} tickets migrated")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Migrate tickets to ERPNext")
    parser.add_argument("--input", required=True, help="CSV file path")
    parser.add_argument("--site", default="erp.localhost", help="ERPNext site name")
    args = parser.parse_args()
    migrate_tickets(args.input, args.site)
