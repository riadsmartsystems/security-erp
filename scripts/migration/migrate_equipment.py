#!/usr/bin/env python3
"""
Wave 3: Migrate Equipment to CMDB
Usage: python migrate_equipment.py --input equipment.csv
CSV columns: equipment_code, object_code, equipment_type, vendor, model, serial_number, firmware, status, install_date, warranty_end
"""
import argparse
import csv
import subprocess


def run_postgres_query(query):
    result = subprocess.run(
        ["docker", "exec", "postgres", "psql", "-U", "postgres", "-d", "security_erp", "-c", query],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"  PG Error: {result.stderr[:200]}")
    return result.stdout


def migrate_equipment(csv_path):
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Found {len(rows)} equipment items to migrate")
    success = 0

    for row in rows:
        code = row.get("equipment_code", "").strip()
        obj_code = row.get("object_code", "").strip()
        if not code or not obj_code:
            continue

        eq_type = row.get("equipment_type", "Other").strip()
        vendor = row.get("vendor", "").strip()
        model = row.get("model", "").strip().replace("'", "''")
        serial = row.get("serial_number", "").strip()
        firmware = row.get("firmware", "").strip()
        status = row.get("status", "active").strip()
        install_date = row.get("install_date", "NULL").strip()
        warranty_end = row.get("warranty_end", "NULL").strip()

        check = run_postgres_query(
            f"SELECT equipment_code FROM cmdb.equipment WHERE equipment_code='{code}' LIMIT 1")
        if code in check:
            print(f"  Skip (exists): {code}")
            continue

        obj_check = run_postgres_query(
            f"SELECT id FROM cmdb.objects WHERE object_code='{obj_code}' LIMIT 1")

        install_str = f"'{install_date}'" if install_date != "NULL" else "NULL"
        warranty_str = f"'{warranty_end}'" if warranty_end != "NULL" else "NULL"

        query = f"""INSERT INTO cmdb.equipment
            (equipment_code, equipment_type, vendor, model, serial_number, firmware_version, status, install_date, warranty_end_date, created_at, updated_at)
            VALUES ('{code}', '{eq_type}', '{vendor}', '{model}', '{serial}', '{firmware}', '{status}', {install_str}, {warranty_str}, NOW(), NOW())
            ON CONFLICT (equipment_code) DO NOTHING"""

        run_postgres_query(query)
        print(f"  OK: {code} - {model} ({serial})")
        success += 1

    print(f"\nResult: {success} equipment items migrated")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Migrate equipment to CMDB")
    parser.add_argument("--input", required=True, help="CSV file path")
    args = parser.parse_args()
    migrate_equipment(args.input)
