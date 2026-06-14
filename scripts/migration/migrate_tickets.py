#!/usr/bin/env python3
"""
Wave 4: Migrate open Service Tickets to FSM
Usage: python migrate_tickets.py --input tickets.csv
CSV columns: ticket_number, customer_name, object_code, ticket_type, priority, status, description, created_at
"""
import argparse
import csv
import subprocess


def run_postgres_query(query):
    result = subprocess.run(
        ["docker", "exec", "postgres", "psql", "-U", "postgres", "-d", "security_erp", "-c", query],
        capture_output=True, text=True
    )
    return result.stdout


def migrate_tickets(csv_path):
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Found {len(rows)} tickets to migrate")
    success = 0

    for row in rows:
        number = row.get("ticket_number", "").strip()
        desc = row.get("description", "").strip().replace("'", "''")
        ticket_type = row.get("ticket_type", "service_request").strip()
        priority = row.get("priority", "medium").strip()
        status = row.get("status", "new").strip()
        created = row.get("created_at", "NOW()").strip()

        check = run_postgres_query(
            f"SELECT ticket_number FROM fsm.tickets WHERE ticket_number='{number}' LIMIT 1")
        if number in check:
            print(f"  Skip (exists): {number}")
            continue

        query = f"""INSERT INTO fsm.tickets
            (ticket_number, ticket_type, priority, status, description, created_at, updated_at)
            VALUES ('{number}', '{ticket_type}', '{priority}', '{status}', '{desc}', {created}, NOW())
            ON CONFLICT (ticket_number) DO NOTHING"""

        run_postgres_query(query)
        print(f"  OK: {number} ({ticket_type}/{priority})")
        success += 1

    print(f"\nResult: {success} tickets migrated")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Migrate tickets to FSM")
    parser.add_argument("--input", required=True, help="CSV file path")
    args = parser.parse_args()
    migrate_tickets(args.input)
