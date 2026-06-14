import httpx
from app.core.config import settings


async def frappe_get(path: str, params: dict = None, sid: str = None) -> dict:
    headers = _frappe_headers()
    cookies = {}
    if sid:
        cookies["sid"] = sid
    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.get(f"{settings.frappe_url}{path}", headers=headers, params=params, cookies=cookies)
        resp.raise_for_status()
        return resp.json()


async def frappe_post(path: str, data: dict = None) -> dict:
    headers = _frappe_headers()
    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.post(f"{settings.frappe_url}{path}", headers=headers, json=data)
        resp.raise_for_status()
        return resp.json()


async def frappe_put(path: str, data: dict = None) -> dict:
    headers = _frappe_headers()
    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.put(f"{settings.frappe_url}{path}", headers=headers, json=data)
        resp.raise_for_status()
        return resp.json()


async def frappe_delete(path: str) -> dict:
    headers = _frappe_headers()
    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.delete(f"{settings.frappe_url}{path}", headers=headers)
        resp.raise_for_status()
        return resp.json()


async def frappe_login(username: str, password: str) -> dict | None:
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(
            f"{settings.frappe_url}/api/method/login",
            json={"usr": username, "pwd": password},
        )
        if resp.status_code == 200:
            return {
                "sid": resp.cookies.get("sid"),
                "full_name": resp.json().get("full_name"),
            }
        return None


def _frappe_headers() -> dict:
    headers = {"Content-Type": "application/json"}
    if settings.frappe_api_key and settings.frappe_api_secret:
        headers["Authorization"] = f"token {settings.frappe_api_key}:{settings.frappe_api_secret}"
    return headers
