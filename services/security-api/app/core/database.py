import httpx
from app.core.config import settings

_sid: str | None = None

FRAPPE_HOST = "erp.localhost"


async def _get_sid() -> str:
    global _sid
    if _sid:
        return _sid
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(
            f"{settings.frappe_url}/api/method/login",
            json={"usr": "Administrator", "pwd": "jokerLA23"},
            headers={"Host": FRAPPE_HOST},
        )
        if resp.status_code == 200:
            _sid = resp.cookies.get("sid")
    return _sid or ""


_client: httpx.AsyncClient | None = None
_client_no_auth: httpx.AsyncClient | None = None


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


def _get_client_no_auth() -> httpx.AsyncClient:
    global _client_no_auth
    if _client_no_auth is None or _client_no_auth.is_closed:
        _client_no_auth = httpx.AsyncClient(
            base_url=settings.frappe_url,
            timeout=10.0,
            limits=httpx.Limits(max_connections=20, max_keepalive_connections=10),
        )
    return _client_no_auth


def _headers_with_host() -> dict:
    return {"Host": FRAPPE_HOST}


async def frappe_get(path: str, params: dict = None, sid: str = None) -> dict:
    if not sid:
        sid = await _get_sid()
    cookies = {"sid": sid} if sid else None
    client = _get_client()
    resp = await client.get(path, params=params, cookies=cookies, headers=_headers_with_host())
    resp.raise_for_status()
    return resp.json()


async def frappe_post(path: str, data: dict = None) -> dict:
    sid = await _get_sid()
    cookies = {"sid": sid} if sid else None
    client = _get_client()
    resp = await client.post(path, json=data, cookies=cookies, headers=_headers_with_host())
    resp.raise_for_status()
    return resp.json()


async def frappe_put(path: str, data: dict = None) -> dict:
    sid = await _get_sid()
    cookies = {"sid": sid} if sid else None
    client = _get_client()
    resp = await client.put(path, json=data, cookies=cookies, headers=_headers_with_host())
    resp.raise_for_status()
    return resp.json()


async def frappe_delete(path: str) -> dict:
    sid = await _get_sid()
    cookies = {"sid": sid} if sid else None
    client = _get_client()
    resp = await client.delete(path, cookies=cookies, headers=_headers_with_host())
    resp.raise_for_status()
    return resp.json()


async def frappe_login(username: str, password: str) -> dict | None:
    client = _get_client_no_auth()
    resp = await client.post(
        "/api/method/login",
        json={"usr": username, "pwd": password},
        headers=_headers_with_host(),
    )
    if resp.status_code == 200:
        return {
            "sid": resp.cookies.get("sid"),
            "full_name": resp.json().get("full_name"),
        }
    return None


async def close_client():
    global _client, _client_no_auth
    if _client and not _client.is_closed:
        await _client.aclose()
        _client = None
    if _client_no_auth and not _client_no_auth.is_closed:
        await _client_no_auth.aclose()
        _client_no_auth = None
