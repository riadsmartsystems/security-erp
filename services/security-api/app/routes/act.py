"""Act routes — /api/v2/act/public/* (no JWT) and /api/v2/vault/act/* (JWT).

Public endpoints authenticate via Redis one-time token + OTP hash.
FastAPI is a thin proxy: no decryption, no caching of secrets.
All crypto happens inside the Frappe process (vault/act.py).
"""

import json

import httpx
from fastapi import APIRouter, Depends, HTTPException, status

from app.auth.dependencies import CurrentUser, get_current_user
from app.core.database import frappe_guest_get, frappe_guest_post, frappe_post
from app.schemas.vault import ActGenerateRequest, ActOtpRequest

public_router = APIRouter(prefix="/api/v2/act/public", tags=["act-public"])
act_router = APIRouter(prefix="/api/v2/vault/act", tags=["act"])


def _frappe_act(method: str) -> str:
    return f"/api/method/security_erp.vault.act.{method}"


def _map_frappe_error(exc: httpx.HTTPStatusError) -> HTTPException:
    try:
        body = exc.response.json()
        exc_type = body.get("exc_type", "")
        msg = body.get("_server_messages", "") or body.get("message", str(exc))
        if isinstance(msg, str) and msg.startswith("["):
            try:
                parsed = json.loads(msg)
                msg = json.loads(parsed[0]).get("message", msg) if parsed else msg
            except Exception:
                pass
    except Exception:
        msg = str(exc)
        exc_type = ""

    http_code = exc.response.status_code
    if http_code == 403 or "PermissionError" in exc_type:
        return HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail={"code": "RIAD-ACT-FORBIDDEN", "message": msg})
    if http_code == 404 or "DoesNotExistError" in exc_type:
        return HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"code": "RIAD-ACT-NOT-FOUND", "message": msg})
    return HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail={"code": "RIAD-ACT-UPSTREAM-ERROR", "message": msg})


def _unwrap(result: dict):
    return result.get("message", result)


# ── Public endpoints (no JWT) ─────────────────────────────────────────────────


@public_router.get("/{token}")
async def act_get_meta(token: str):
    """Return non-sensitive act metadata. No OTP required.

    Client uses this to confirm the link is valid before entering OTP.
    Strict whitelist: no delivery_token, generated_by, or audit_ref.
    """
    try:
        result = await frappe_guest_get(
            _frappe_act("get_meta"),
            params={"token_hex": token},
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
    return _unwrap(result)


@public_router.post("/{token}/view")
async def act_view(token: str, body: ActOtpRequest):
    """Decrypt and return vault entry fields for the client.

    Requires valid OTP. Token is NOT burned after view — client may view
    multiple times. Decrypted data is never cached by FastAPI.
    """
    try:
        result = await frappe_guest_post(
            _frappe_act("serve"),
            data={"token_hex": token, "otp_code": body.otp},
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
    return _unwrap(result)


@public_router.post("/{token}/acknowledge")
async def act_acknowledge(token: str, body: ActOtpRequest):
    """Client acknowledges receipt. Burns the Redis token.

    After this call, the link is permanently invalid.
    """
    try:
        result = await frappe_guest_post(
            _frappe_act("acknowledge"),
            data={"token_hex": token, "otp_code": body.otp},
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
    return _unwrap(result)


# ── Protected endpoint (JWT required) ────────────────────────────────────────


@act_router.post("/generate")
async def act_generate(
    body: ActGenerateRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    """Generate a one-time delivery link + OTP for an Access Transfer Act.

    Requires JWT + fresh vault_session_token (V3 TOTP step-up).
    Returns {token, otp, link, expires_at}. OTP displayed once — never stored.
    """
    try:
        result = await frappe_post(
            _frappe_act("generate"),
            data={
                "act_name": body.act_name,
                "vault_session_token": body.vault_session_token,
            },
            sid=current_user.frappe_sid,
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
    return _unwrap(result)
