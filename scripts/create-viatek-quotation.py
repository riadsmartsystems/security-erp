#!/usr/bin/env python3
"""
Create Supplier Quotations from Viatek XML for all items with prices.
Usage: python create-viatek-quotation.py
"""
import json
import os
import http.client
import xml.etree.ElementTree as ET
import urllib.parse

FRAPPE_HOST = "localhost:80"
FRAPPE_SITE = "erp.localhost"
FRAPPE_USER = "Administrator"
FRAPPE_PWD = os.environ.get("FRAPPE_PASSWORD", "")
_sid = None


def _get_sid():
    global _sid
    if _sid:
        return _sid
    conn = http.client.HTTPConnection(FRAPPE_HOST, timeout=30)
    body = json.dumps({"usr": FRAPPE_USER, "pwd": FRAPPE_PWD})
    conn.request("POST", "/api/method/login", body=body,
                 headers={"Content-Type": "application/json", "Host": FRAPPE_SITE})
    resp = conn.getresponse()
    resp.read()
    for header, value in resp.getheaders():
        if header.lower() == "set-cookie" and "sid=" in value:
            _sid = value.split("sid=")[1].split(";")[0]
            break
    conn.close()
    return _sid or ""


def api_call(method, path, data=None):
    sid = _get_sid()
    conn = http.client.HTTPConnection(FRAPPE_HOST, timeout=30)
    headers = {"Host": FRAPPE_SITE, "Cookie": f"sid={sid}", "Content-Type": "application/json"}
    body = json.dumps(data) if data else None
    conn.request(method, path.replace(" ", "%20"), body=body, headers=headers)
    resp = conn.getresponse()
    result = resp.read().decode()
    conn.close()
    return resp.status, json.loads(result)


def main():
    xml_path = "/home/joker/Downloads/Viatek product_info_a_uk.xml"
    print(f"Parsing {xml_path}...")
    tree = ET.parse(xml_path)
    root = tree.getroot()

    items_with_price = []
    for prod in root.findall(".//products/product"):
        model = prod.findtext("model", "").strip()
        price_uah = prod.findtext("price_uah", "").strip()
        name = prod.findtext("name", model).strip()[:140]
        if model and price_uah:
            try:
                price = float(price_uah)
                if price > 0:
                    items_with_price.append({"model": model, "price": price, "name": name})
            except ValueError:
                pass

    print(f"Items with prices: {len(items_with_price)}")

    BATCH_SIZE = 50
    batches = [items_with_price[i:i+BATCH_SIZE] for i in range(0, len(items_with_price), BATCH_SIZE)]
    print(f"Batches: {len(batches)}")

    created = 0
    for i, batch in enumerate(batches):
        items_for_sq = [
            {"item_code": it["model"], "qty": 1, "rate": it["price"]}
            for it in batch
        ]

        sq_data = {
            "supplier": "Viatek",
            "transaction_date": "2026-06-15",
            "items": items_for_sq,
        }

        status, result = api_call("POST", "/api/resource/Supplier%20Quotation", sq_data)
        if status == 200:
            sq_name = result.get("data", {}).get("name", "?")
            created += 1
            print(f"  [{i+1}/{len(batches)}] Created: {sq_name} ({len(batch)} items)")
        else:
            err = result.get("exception", str(result))[:100]
            print(f"  [{i+1}/{len(batches)}] ERROR: {err}")

    print(f"\nDone: {created} Supplier Quotations created")


if __name__ == "__main__":
    main()
