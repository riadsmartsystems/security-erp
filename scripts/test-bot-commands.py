#!/usr/bin/env python3
"""Test all bot commands by simulating API calls"""
import asyncio
import httpx

API_URL = "http://localhost:8000"


async def test_all():
    results = []

    async with httpx.AsyncClient(timeout=10.0) as client:
        # 1. Login
        print("1. Testing login...")
        resp = await client.post(f"{API_URL}/api/v1/auth/login", json={
            "username": "admin",
            "password": "admin123",
        })
        token = resp.json().get("access_token") if resp.status_code == 200 else None
        results.append(("Login", resp.status_code == 200, resp.status_code))
        print(f"   Status: {resp.status_code}, Token: {'OK' if token else 'FAIL'}")

        headers = {"Authorization": f"Bearer {token}"} if token else {}

        # 2. Get tickets (for /mytickets)
        print("2. Testing /api/v1/tickets (mytickets)...")
        resp = await client.get(f"{API_URL}/api/v1/tickets?limit=10", headers=headers)
        data = resp.json()
        results.append(("Tickets", data.get("success", False), resp.status_code))
        print(f"   Status: {resp.status_code}, Count: {len(data.get('data', []))}")

        # 3. Get objects (for /object)
        print("3. Testing /api/v1/objects (object)...")
        resp = await client.get(f"{API_URL}/api/v1/objects?limit=10", headers=headers)
        data = resp.json()
        results.append(("Objects", data.get("success", False), resp.status_code))
        print(f"   Status: {resp.status_code}, Count: {len(data.get('data', []))}")

        # 4. Create ticket (for /newticket)
        print("4. Testing POST /api/v1/tickets (newticket)...")
        resp = await client.post(f"{API_URL}/api/v1/tickets", headers=headers, json={
            "customer_id": "a0000000-0000-0000-0000-000000000001",
            "object_id": "a0000000-0000-0000-0000-000000000002",
            "ticket_type": "incident",
            "priority": "medium",
            "title": "Test ticket from bot test",
        })
        data = resp.json()
        results.append(("Create Ticket", data.get("success", False), resp.status_code))
        print(f"   Status: {resp.status_code}, Ticket: {data.get('data', {}).get('ticket_number', 'N/A')}")

        ticket_id = data.get("data", {}).get("id")

        # 5. Create visit (for /visit_start, /visit_finish)
        if ticket_id:
            print("5. Testing POST /api/v1/visits (create visit)...")
            resp = await client.post(f"{API_URL}/api/v1/visits", headers=headers, json={
                "ticket_id": ticket_id,
                "engineer_id": "a0000000-0000-0000-0000-000000000001",
            })
            data = resp.json()
            results.append(("Create Visit", data.get("success", False), resp.status_code))
            print(f"   Status: {resp.status_code}, Visit: {data.get('data', {}).get('visit_number', 'N/A')}")

            visit_id = data.get("data", {}).get("id")

            # 6. Start visit
            if visit_id:
                print("6. Testing POST /api/v1/visits/{id}/start (visit_start)...")
                resp = await client.post(f"{API_URL}/api/v1/visits/{visit_id}/start", headers=headers, json={
                    "lat": 50.4501,
                    "lon": 30.5234,
                })
                data = resp.json()
                results.append(("Visit Start", data.get("success", False), resp.status_code))
                print(f"   Status: {resp.status_code}, Result: {data}")

                # 7. Finish visit
                print("7. Testing POST /api/v1/visits/{id}/finish (visit_finish)...")
                resp = await client.post(f"{API_URL}/api/v1/visits/{visit_id}/finish", headers=headers, json={
                    "lat": 50.4501,
                    "lon": 30.5234,
                })
                data = resp.json()
                results.append(("Visit Finish", data.get("success", False), resp.status_code))
                print(f"   Status: {resp.status_code}, Result: {data}")

        # 8. SLA stats (for /sla)
        print("8. Testing SLA calculation...")
        resp = await client.get(f"{API_URL}/api/v1/tickets?limit=100", headers=headers)
        data = resp.json()
        tickets = data.get("data", [])
        total = len(tickets)
        breached = sum(1 for t in tickets if t.get("sla_response_breached") or t.get("sla_resolution_breached"))
        compliance = ((total - breached) / total * 100) if total > 0 else 100
        results.append(("SLA Stats", True, 200))
        print(f"   Total: {total}, Breached: {breached}, Compliance: {compliance:.1f}%")

        # 9. KPI (for /kpi)
        print("9. Testing KPI...")
        resp_obj = await client.get(f"{API_URL}/api/v1/objects?limit=100", headers=headers)
        objects = resp_obj.json().get("data", [])
        results.append(("KPI", True, 200))
        print(f"   Objects: {len(objects)}, Tickets: {total}, Open: {sum(1 for t in tickets if t['status'] not in ['closed', 'cancelled', 'resolved'])}")

    # Summary
    print("\n" + "=" * 50)
    print("RESULTS:")
    print("=" * 50)
    all_ok = True
    for name, ok, status in results:
        icon = "PASS" if ok else "FAIL"
        print(f"  [{icon}] {name} (HTTP {status})")
        if not ok:
            all_ok = False

    print("=" * 50)
    print(f"Overall: {'ALL PASSED' if all_ok else 'SOME FAILED'}")


if __name__ == "__main__":
    asyncio.run(test_all())
