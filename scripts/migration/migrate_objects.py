#!/usr/bin/env python3
"""
Wave 2: Migrate Security Objects to ERPNext (MariaDB)
Usage: python migrate_objects.py --input objects.csv --site erp.localhost
CSV columns: object_code, customer_name, name, address, gps_lat, gps_lon, object_type, service_level
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


def migrate_objects(csv_path, site="erp.localhost"):
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Found {len(rows)} objects to migrate")
    success = 0

    for row in rows:
        code = row.get("object_code", "").strip()
        name = row.get("name", "").strip()
        if not code or not name:
            continue

        address = sql_str(row.get("address", "").strip())
        gps_lat = row.get("gps_lat", "0").strip() or "0"
        gps_lon = row.get("gps_lon", "0").strip() or "0"
        obj_type = sql_str(row.get("object_type", "Office").strip())
        service_level = row.get("service_level", "Standard").strip()
        customer_name = sql_str(row.get("customer_name", "").strip())

        check = run_bench_query(site,
            f"SELECT name FROM `tabSecurity Object` WHERE object_code='{code}' LIMIT 1")
        if check and code in check:
            print(f"  Skip (exists): {code}")
            continue

        query = f"""INSERT INTO `tabSecurity Object`
            (name, object_code, object_name, address, gps_lat, gps_lon, object_type, service_level, status, creation, modified, modified_by, owner, docstatus)
            VALUES ('{code}', '{code}', '{sql_str(name)}', '{address}', {gps_lat}, {gps_lon}, '{obj_type}', '{service_level}', 'Active', NOW(), NOW(), 'Administrator', 'Administrator', 0)
            ON DUPLICATE KEY UPDATE modified=NOW()"""

        result = run_bench_query(site, query)
        if result is not None:
            print(f"  OK: {code} - {name}")
            success += 1
        else:
            print(f"  FAIL: {code}")

    print(f"\nResult: {success} objects migrated")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Migrate objects to ERPNext")
    parser.add_argument("--input", required=True, help="CSV file path")
    parser.add_argument("--site", default="erp.localhost", help="ERPNext site name")
    args = parser.parse_args()
    migrate_objects(args.input, args.site)
