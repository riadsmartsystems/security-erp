#!/usr/bin/env python3
"""
Shared Frappe API client for migration scripts.
Uses REST API with session-based authentication.
"""
import os
import sys
import json
import http.client
import urllib.parse


FRAPPE_HOST = os.environ.get("FRAPPE_HOST", "localhost:80")
FRAPPE_USER = os.environ.get("FRAPPE_USER", "Administrator")
FRAPPE_PASSWORD = os.environ.get("FRAPPE_PASSWORD", "jokerLA23")

_sid = None


def _get_sid():
    global _sid
    if _sid:
        return _sid

    conn = http.client.HTTPConnection(FRAPPE_HOST, timeout=30)
    body = json.dumps({"usr": FRAPPE_USER, "pwd": FRAPPE_PASSWORD})
    conn.request("POST", "/api/method/login", body=body,
                 headers={"Content-Type": "application/json", "Host": "erp.localhost"})
    resp = conn.getresponse()
    resp.read()

    for header, value in resp.getheaders():
        if header.lower() == "set-cookie" and "sid=" in value:
            _sid = value.split("sid=")[1].split(";")[0]
            break

    conn.close()
    if not _sid:
        print("ERROR: Failed to get Frappe session")
        sys.exit(1)
    return _sid


def _encode_path(path):
    parts = path.split("?")
    base = parts[0]
    query = f"?{parts[1]}" if len(parts) > 1 else ""
    encoded_base = urllib.parse.quote(base, safe="/:")
    return encoded_base + query


def _request(method, path, body=None):
    sid = _get_sid()
    conn = http.client.HTTPConnection(FRAPPE_HOST, timeout=30)
    headers = {
        "Content-Type": "application/json",
        "Host": "erp.localhost",
        "Cookie": f"sid={sid}",
    }
    encoded_path = _encode_path(path)
    conn.request(method, encoded_path, body=body, headers=headers)
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
    print(f"  API Error GET {doctype}: {status} {data[:200]}")
    return None


def frappe_create(doctype, data):
    path = f"/api/resource/{doctype}"
    body = json.dumps(data)
    status, resp_data = _request("POST", path, body=body)
    if status in (200, 201):
        return json.loads(resp_data).get("data", {})
    print(f"  API Error CREATE {doctype}: {status} {resp_data[:300]}")
    return None


def frappe_update(doctype, name, data):
    encoded_name = urllib.parse.quote(name, safe="")
    path = f"/api/resource/{doctype}/{encoded_name}"
    body = json.dumps(data)
    status, resp_data = _request("PUT", path, body=body)
    if status == 200:
        return json.loads(resp_data).get("data", {})
    print(f"  API Error UPDATE {doctype}/{name}: {status} {resp_data[:300]}")
    return None


def exists(doctype, name):
    encoded_name = urllib.parse.quote(name, safe="")
    path = f"/api/resource/{doctype}/{encoded_name}"
    status, _ = _request("GET", path)
    return status == 200


def exists_by_filter(doctype, field, value):
    results = frappe_get(doctype, filters=[[field, "=", value]], fields=["name"], limit=1)
    if results and len(results) > 0:
        return results[0].get("name")
    return None
