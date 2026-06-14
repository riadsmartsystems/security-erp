#!/usr/bin/env python3
"""
Wave 2: Migrate Security Objects to CMDB
Usage: python migrate_objects.py --input objects.csv
CSV columns: object_code, customer_name, name, address, gps_lat, gps_lon, object_type, service_level
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


def migrate_objects(csv_path):
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

        address = row.get("address", "").strip().replace("'", "''")
        gps_lat = row.get("gps_lat", "0").strip()
        gps_lon = row.get("gps_lon", "0").strip()
        obj_type = row.get("object_type", "office").strip()
        service_level = row.get("service_level", "standard").strip()

        check = run_postgres_query(
            f"SELECT object_code FROM cmdb.objects WHERE object_code='{code}' LIMIT 1")
        if code in check:
            print(f"  Skip (exists): {code}")
            continue

        query = f"""INSERT INTO cmdb.objects
            (object_code, name, address, gps_lat, gps_lon, object_type, service_level, status, created_at, updated_at)
            VALUES ('{code}', '{name}', '{address}', {gps_lat}, {gps_lon}, '{obj_type}', '{service_level}', 'active', NOW(), NOW())
            ON CONFLICT (object_code) DO NOTHING"""

        run_postgres_query(query)
        print(f"  OK: {code} - {name}")
        success += 1

    print(f"\nResult: {success} objects migrated")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Migrate objects to CMDB")
    parser.add_argument("--input", required=True, help="CSV file path")
    args = parser.parse_args()
    migrate_objects(args.input)
