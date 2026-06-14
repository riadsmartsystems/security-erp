#!/usr/bin/env python3
"""
Wave 3: Migrate Equipment to ERPNext (MariaDB)
Usage: python migrate_equipment.py --input equipment.csv --site erp.localhost
CSV columns: equipment_code, object_code, equipment_type, vendor, model, serial_number, firmware, status, install_date, warranty_end
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


def migrate_equipment(csv_path, site="erp.localhost"):
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

        eq_type = sql_str(row.get("equipment_type", "Other").strip())
        vendor = sql_str(row.get("vendor", "").strip())
        model = sql_str(row.get("model", "").strip())
        serial = sql_str(row.get("serial_number", "").strip())
        firmware = sql_str(row.get("firmware", "").strip())
        status = row.get("status", "Active").strip().replace("_", " ").title()
        install_date = row.get("install_date", "").strip()
        warranty_end = row.get("warranty_end", "").strip()

        check = run_bench_query(site,
            f"SELECT name FROM `tabEquipment` WHERE equipment_code='{code}' LIMIT 1")
        if check and code in check:
            print(f"  Skip (exists): {code}")
            continue

        install_str = f"'{install_date}'" if install_date else "NULL"
        warranty_str = f"'{warranty_end}'" if warranty_end else "NULL"

        query = f"""INSERT INTO `tabEquipment`
            (name, equipment_code, security_object, equipment_type, vendor, model, serial_number, firmware_version, status, install_date, warranty_end_date, creation, modified, modified_by, owner, docstatus)
            VALUES ('{code}', '{code}', '{obj_code}', '{eq_type}', '{vendor}', '{model}', '{serial}', '{firmware}', '{status}', {install_str}, {warranty_str}, NOW(), NOW(), 'Administrator', 'Administrator', 0)
            ON DUPLICATE KEY UPDATE modified=NOW()"""

        result = run_bench_query(site, query)
        if result is not None:
            print(f"  OK: {code} - {model} ({serial})")
            success += 1
        else:
            print(f"  FAIL: {code}")

    print(f"\nResult: {success} equipment items migrated")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Migrate equipment to ERPNext")
    parser.add_argument("--input", required=True, help="CSV file path")
    parser.add_argument("--site", default="erp.localhost", help="ERPNext site name")
    args = parser.parse_args()
    migrate_equipment(args.input, args.site)
