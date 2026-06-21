import httpx
from app.core.config import settings

FRAPPE_HOST = "erp.localhost"

_client: httpx.AsyncClient | None = None


def _get_client() -> httpx.AsyncClient:
    global _client
    if _client is None or _client.is_closed:
        _client = httpx.AsyncClient(
            base_url=settings.frappe_url,
            timeout=30.0,
            limits=httpx.Limits(
                max_connections=50,
                max_keepalive_connections=20,
                keepalive_expiry=30,
            ),
        )
    return _client


def _headers_with_host() -> dict:
    return {"Host": FRAPPE_HOST}


async def frappe_get(path: str, params: dict = None, sid: str = "") -> dict:
    cookies = {"sid": sid} if sid else None
    resp = await _get_client().get(path, params=params, cookies=cookies, headers=_headers_with_host())
    resp.raise_for_status()
    return resp.json()


async def frappe_post(path: str, data: dict = None, sid: str = "") -> dict:
    cookies = {"sid": sid} if sid else None
    resp = await _get_client().post(path, json=data, cookies=cookies, headers=_headers_with_host())
    resp.raise_for_status()
    return resp.json()


async def frappe_put(path: str, data: dict = None, sid: str = "") -> dict:
    cookies = {"sid": sid} if sid else None
    resp = await _get_client().put(path, json=data, cookies=cookies, headers=_headers_with_host())
    resp.raise_for_status()
    return resp.json()


async def frappe_delete(path: str, sid: str = "") -> dict:
    cookies = {"sid": sid} if sid else None
    resp = await _get_client().delete(path, cookies=cookies, headers=_headers_with_host())
    resp.raise_for_status()
    return resp.json()


async def frappe_login(username: str, password: str) -> dict | None:
    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.post(
            f"{settings.frappe_url}/api/method/login",
            data={"usr": username, "pwd": password},
            headers={"Host": FRAPPE_HOST},
            follow_redirects=False,
        )
        if resp.status_code == 200:
            try:
                body = resp.json()
            except Exception:
                body = {}
            return {
                "sid": resp.cookies.get("sid"),
                "full_name": body.get("full_name", username),
            }
    return None


async def close_client():
    global _client
    if _client and not _client.is_closed:
        await _client.aclose()
        _client = None
