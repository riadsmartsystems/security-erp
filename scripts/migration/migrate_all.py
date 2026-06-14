#!/usr/bin/env python3
"""
Master Migration Script — Run all waves in sequence
Usage: python run_all.sh
Or: python migrate_all.py --waves 1,2,3,4
"""
import argparse
import subprocess
import sys
import os


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))


def run_wave(wave_num, csv_path=None):
    scripts = {
        1: "migrate_customers.py",
        2: "migrate_objects.py",
        3: "migrate_equipment.py",
        4: "migrate_tickets.py",
    }

    if wave_num not in scripts:
        print(f"Unknown wave: {wave_num}")
        return False

    script = os.path.join(SCRIPT_DIR, scripts[wave_num])
    if not os.path.exists(script):
        print(f"Script not found: {script}")
        return False

    if not csv_path:
        csv_path = os.path.join(SCRIPT_DIR, f"sample_wave{wave_num}.csv")

    if not os.path.exists(csv_path):
        print(f"CSV not found: {csv_path}")
        print(f"Create sample CSV first or provide --input")
        return False

    print(f"\n{'='*50}")
    print(f"Wave {wave_num}: Running {scripts[wave_num]}")
    print(f"{'='*50}")

    result = subprocess.run(
        [sys.executable, script, "--input", csv_path],
        cwd=SCRIPT_DIR
    )
    return result.returncode == 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run all migration waves")
    parser.add_argument("--waves", default="1,2,3,4", help="Comma-separated wave numbers")
    parser.add_argument("--input", help="Base CSV directory")
    args = parser.parse_args()

    waves = [int(w.strip()) for w in args.waves.split(",")]

    print("Security ERP Data Migration")
    print("="*50)

    results = {}
    for wave in waves:
        csv_path = None
        if args.input:
            csv_path = os.path.join(args.input, f"wave{wave}.csv")
        results[wave] = run_wave(wave, csv_path)

    print("\n" + "="*50)
    print("Migration Summary")
    print("="*50)
    for wave, success in results.items():
        status = "OK" if success else "FAILED"
        print(f"  Wave {wave}: {status}")
