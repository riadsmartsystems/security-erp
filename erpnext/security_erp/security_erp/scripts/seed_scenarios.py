#!/usr/bin/env python3
"""Seed Security Scenarios via Frappe REST API.

Usage:
    bench --site <site> execute security_erp.scripts.seed_scenarios.run

Or directly with requests:
    python scripts/seed_scenarios.py --url https://<site> --token <api_key>:<api_secret>
"""

import json
import sys

try:
    import requests
except ImportError:
    print("Install requests: pip install requests")
    sys.exit(1)


SCENARIOS = [
    {
        "scenario_name": "CCTV Аналог 4 кам.",
        "security_type": "CCTV Analog",
        "description": "Базовий аналоговий комплект відеоспостереження на 4 камери",
        "is_active": 1,
        "items": [
            {"item_code": "TODO_DVR_4CH", "qty": 1, "is_optional": 0},
            {"item_code": "TODO_CAMERA_ANALOG", "qty": 4, "qty_formula": "cameras_count", "is_optional": 0},
            {"item_code": "TODO_CABLE_RG59_100M", "qty": 2, "is_optional": 0},
            {"item_code": "TODO_CONNECTOR_BNC", "qty": 8, "is_optional": 0},
            {"item_code": "TODO_HDD_1TB", "qty": 1, "is_optional": 0},
            {"item_code": "TODO_PSU_12V_5A", "qty": 1, "is_optional": 0},
            {"item_code": "TODO_JUNCTION_BOX", "qty": 1, "is_optional": 0},
            {"item_code": "TODO_POWER_STRIP", "qty": 1, "is_optional": 0},
            {"item_code": "TODO_MOUNT_BOX", "qty": 4, "qty_formula": "cameras_count", "is_optional": 0},
            {"item_code": "TODO_CABLE_TRAY", "qty": 1, "is_optional": 1, "option_group": "Кабелепровід"},
            {"item_code": "TODO_CONDUIT_METAL", "qty": 1, "is_optional": 1, "option_group": "Кабелепровід"},
            {"item_code": "TODO_CONDUIT_PLASTIC", "qty": 1, "is_optional": 1, "option_group": "Кабелепровід"},
            {"item_code": "TODO_UPS_600VA", "qty": 1, "is_optional": 1, "option_group": "Резервне живлення"},
        ],
    },
    {
        "scenario_name": "CCTV IP до 4 кам.",
        "security_type": "CCTV IP",
        "description": "IP-система відеоспостереження до 4 камер з локальним зберіганням",
        "is_active": 1,
        "items": [
            {"item_code": "TODO_CAMERA_IP", "qty": 4, "is_optional": 0},
            {"item_code": "TODO_POE_INJECTOR", "qty": 4, "is_optional": 0},
            {"item_code": "TODO_MICROSD_128GB", "qty": 4, "is_optional": 0},
            {"item_code": "TODO_CABLE_UTP_CAT5E_100M", "qty": 2, "is_optional": 0},
            {"item_code": "TODO_CONNECTOR_RJ45", "qty": 16, "is_optional": 0},
            {"item_code": "TODO_MOUNT_BOX", "qty": 4, "is_optional": 0},
            {"item_code": "TODO_POWER_STRIP", "qty": 1, "is_optional": 0},
            {"item_code": "TODO_UPS_600VA", "qty": 1, "is_optional": 1, "option_group": "Резервне живлення"},
        ],
    },
    {
        "scenario_name": "CCTV IP 5+ кам. з NVR",
        "security_type": "CCTV IP",
        "description": "IP-система відеоспостереження 5+ камер з мережевим відеореєстратором",
        "is_active": 1,
        "items": [
            {"item_code": "TODO_CAMERA_IP", "qty": 8, "is_optional": 0},
            {"item_code": "TODO_POE_SWITCH", "qty": 1, "is_optional": 0},
            {"item_code": "TODO_NVR", "qty": 1, "is_optional": 0},
            {"item_code": "TODO_HDD_2TB", "qty": 1, "is_optional": 0},
            {"item_code": "TODO_MICROSD_64GB", "qty": 8, "is_optional": 0},
            {"item_code": "TODO_CABLE_UTP_CAT5E_100M", "qty": 4, "is_optional": 0},
            {"item_code": "TODO_CONNECTOR_RJ45", "qty": 32, "is_optional": 0},
            {"item_code": "TODO_MOUNT_BOX", "qty": 8, "is_optional": 0},
            {"item_code": "TODO_UPS_1000VA", "qty": 1, "is_optional": 1, "option_group": "Резервне живлення"},
        ],
    },
]


def run():
    """Run via bench execute — uses frappe client directly."""
    import frappe

    for sc in SCENARIOS:
        doc = frappe.get_doc(
            {
                "doctype": "Security Scenario",
                "scenario_name": sc["scenario_name"],
                "security_type": sc["security_type"],
                "description": sc["description"],
                "is_active": sc["is_active"],
                "items": [],
            }
        )
        for item in sc["items"]:
            doc.append(
                "items",
                {
                    "item_code": item["item_code"],
                    "qty": item.get("qty", 1),
                    "qty_formula": item.get("qty_formula", ""),
                    "is_optional": item.get("is_optional", 0),
                    "option_group": item.get("option_group", ""),
                },
            )
        doc.insert(ignore_permissions=True)
        print(f"Created: {doc.name} — {sc['scenario_name']}")

    frappe.db.commit()
    _print_placeholders()


def run_rest(base_url: str, token: str):
    """Run via REST API (standalone script)."""
    headers = {
        "Authorization": f"token {token}",
        "Content-Type": "application/json",
    }

    for sc in SCENARIOS:
        payload = {
            "scenario_name": sc["scenario_name"],
            "security_type": sc["security_type"],
            "description": sc["description"],
            "is_active": sc["is_active"],
            "items": [],
        }
        for item in sc["items"]:
            payload["items"].append(
                {
                    "item_code": item["item_code"],
                    "qty": item.get("qty", 1),
                    "qty_formula": item.get("qty_formula", ""),
                    "is_optional": item.get("is_optional", 0),
                    "option_group": item.get("option_group", ""),
                }
            )

        resp = requests.post(
            f"{base_url}/api/resource/Security Scenario",
            headers=headers,
            json=payload,
        )
        if resp.status_code == 200:
            name = resp.json()["data"]["name"]
            print(f"Created: {name} — {sc['scenario_name']}")
        else:
            print(f"ERROR creating '{sc['scenario_name']}': {resp.status_code} — {resp.text}")

    _print_placeholders()


def _print_placeholders():
    placeholders = sorted(
        {
            item["item_code"]
            for sc in SCENARIOS
            for item in sc["items"]
            if item["item_code"].startswith("TODO_")
        }
    )
    print("\n" + "=" * 60)
    print("PLACEHOLDERS — replace with real Item codes from ERPNext:")
    print("=" * 60)
    for p in placeholders:
        print(f"  {p}")
    print("=" * 60)
    print(f"Total: {len(placeholders)} placeholders to replace")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Seed Security Scenarios")
    parser.add_argument("--url", required=True, help="Frappe site URL")
    parser.add_argument("--token", required=True, help="API key:secret")
    args = parser.parse_args()
    run_rest(args.url, args.token)
