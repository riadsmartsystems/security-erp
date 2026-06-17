#!/usr/bin/env python3
"""
Import Viatek XML product catalog into ERPNext.
Usage: python import-viatek-catalog.py --input "Viatek product_info_a_uk.xml"
"""
import argparse
import csv
import json
import os
import sys
import xml.etree.ElementTree as ET
import urllib.request
import urllib.error
import urllib.parse
import time

FRAPPE_HOST = "localhost:80"
FRAPPE_SITE = "erp.localhost"
FRAPPE_USER = "Administrator"
FRAPPE_PWD = os.environ.get("FRAPPE_PASSWORD", "")
_sid = None


def _get_sid():
    global _sid
    if _sid:
        return _sid
    import http.client
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


def _request(method, path, body=None):
    import http.client
    sid = _get_sid()
    conn = http.client.HTTPConnection(FRAPPE_HOST, timeout=30)
    headers = {
        "Content-Type": "application/json",
        "Host": FRAPPE_SITE,
        "Cookie": f"sid={sid}",
    }
    safe_path = path.replace(" ", "%20")
    conn.request(method, safe_path, body=body, headers=headers)
    resp = conn.getresponse()
    data = resp.read().decode()
    conn.close()
    return resp.status, data


def frappe_get(doctype, filters=None, fields=None, limit=100):
    params = {"limit_page_length": limit}
    if filters:
        params["filters"] = json.dumps(filters)
    if fields:
        params["fields"] = json.dumps(fields)
    qs = urllib.parse.urlencode(params)
    path = f"/api/resource/{doctype}?{qs}"
    status, data = _request("GET", path)
    if status == 200:
        return json.loads(data).get("data", [])
    return None


def frappe_create(doctype, data):
    path = f"/api/resource/{doctype}"
    body = json.dumps(data)
    status, resp_data = _request("POST", path, body=body)
    if status in (200, 201):
        return json.loads(resp_data).get("data", {})
    print(f"  ERROR CREATE {doctype}: {status} {resp_data[:200]}")
    return None


def frappe_get_or_create(doctype, filters, data):
    existing = frappe_get(doctype, filters=filters, fields=["name"], limit=1)
    if existing:
        return existing[0].get("name")
    result = frappe_create(doctype, data)
    if result:
        return result.get("name")
    print(f"  WARN: Failed to create {doctype}: {data.get('item_group_name', data.get('item_code', '?'))}")
    return None


def parse_xml(xml_path):
    print(f"Parsing XML: {xml_path}")
    tree = ET.parse(xml_path)
    root = tree.getroot()

    categories = {}
    for cat in root.findall(".//categories/category"):
        cat_id = cat.findtext("id", "")
        title = cat.findtext("title", "")
        parent_id = cat.findtext("parent_id", "0")
        if cat_id:
            categories[cat_id] = {"title": title, "parent_id": parent_id}

    products = []
    for prod in root.findall(".//products/product"):
        product = {
            "id": prod.findtext("id", ""),
            "category_id": prod.findtext("category_id", ""),
            "code": prod.findtext("code", ""),
            "brand": prod.findtext("brand", ""),
            "model": prod.findtext("model", ""),
            "title": prod.findtext("title", ""),
            "name": prod.findtext("name", ""),
            "image": prod.findtext("image", ""),
            "description": prod.findtext("descr", ""),
            "price_usd": prod.findtext("price", ""),
            "price_uah": prod.findtext("price_uah", ""),
            "url": prod.findtext("url", ""),
            "stock": prod.findtext("stock", ""),
        }
        products.append(product)

    print(f"Found {len(categories)} categories, {len(products)} products")
    return categories, products


def build_category_tree(categories):
    tree = {}
    for cat_id, cat in categories.items():
        parent_id = cat["parent_id"]
        if parent_id == "0" or parent_id not in categories:
            parent_id = None
        tree[cat_id] = {"title": cat["title"], "parent": parent_id, "children": []}
        if parent_id and parent_id in tree:
            tree[parent_id]["children"].append(cat_id)
    return tree


def import_categories(categories, tree):
    print("\nImporting categories as Item Groups...")
    category_map = {}
    imported = 0

    for cat_id in sorted(categories.keys(), key=lambda x: len(categories[x]["title"])):
        cat = categories[cat_id]
        parent_name = None
        if cat["parent_id"] and cat["parent_id"] in category_map:
            parent_name = category_map[cat["parent_id"]]

        group_name = frappe_get_or_create(
            "Item Group",
            filters=[["item_group_name", "=", cat["title"]]],
            data={
                "item_group_name": cat["title"],
                "parent_item_group": parent_name or "All Item Groups",
            }
        )
        if group_name:
            category_map[cat_id] = group_name
            imported += 1

    print(f"  Imported {imported} categories")
    return category_map


def import_products(products, category_map):
    print("\nImporting products as Items...")
    imported = 0
    errors = 0
    skipped = 0

    for i, prod in enumerate(products):
        if not prod["model"] and not prod["name"]:
            skipped += 1
            continue

        item_name = prod["model"] or prod["code"] or f"VIA-{prod['id']}"
        item_name = item_name.strip()[:140]

        category_name = category_map.get(prod["category_id"])

        existing = frappe_get("Item", filters=[["item_code", "=", item_name]], fields=["name"], limit=1)
        if existing:
            if (i + 1) % 100 == 0:
                print(f"  [{i+1}/{len(products)}] Processing... (skipped {skipped}, errors {errors})")
            continue

        price_uah = 0
        try:
            price_uah = float(prod["price_uah"]) if prod["price_uah"] else 0
        except ValueError:
            pass

        data = {
            "item_code": item_name,
            "item_name": prod["name"][:140] if prod["name"] else item_name,
            "item_group": category_name or "All Item Groups",
            "description": prod["description"],
            "stock_uom": "Nos",
            "is_stock_item": 1 if prod["stock"] == "yes" else 0,
            "is_fixed_asset": 0,
        }

        result = frappe_create("Item", data)
        if result:
            imported += 1
        else:
            errors += 1

        if (imported + errors) % 50 == 0:
            print(f"  [{i+1}/{len(products)}] imported={imported}, errors={errors}, skipped={skipped}")
            time.sleep(0.1)

    print(f"\n  Result: {imported} imported, {errors} errors, {skipped} skipped")
    return imported


def main():
    parser = argparse.ArgumentParser(description="Import Viatek XML catalog into ERPNext")
    parser.add_argument("--input", required=True, help="Path to XML file")
    parser.add_argument("--import-items", action="store_true", help="Import items (default: categories only)")
    parser.add_argument("--limit", type=int, default=0, help="Limit number of products to import (0=all)")
    args = parser.parse_args()

    categories, products = parse_xml(args.input)
    tree = build_category_tree(categories)
    category_map = import_categories(categories, tree)

    if args.import_items:
        if args.limit > 0:
            products = products[:args.limit]
        import_products(products, category_map)


if __name__ == "__main__":
    main()
