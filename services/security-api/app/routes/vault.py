"""Vault routes — /api/v2/vault/* (JWT required).

Thin proxy to Frappe @whitelist methods inside security_erp.vault.
FastAPI never decrypts or caches secrets — all crypto happens in Frappe process.
"""

import json

import httpx
from fastapi import APIRouter, Depends, HTTPException, status

from app.auth.dependencies import CurrentUser, get_current_user
from app.core.database import frappe_get, frappe_post
from app.schemas.vault import MfaVerifyRequest, VaultDecryptRequest, VaultUpsertRequest

router = APIRouter(prefix="/api/v2/vault", tags=["vault"])


def _frappe_vault(method: str) -> str:
    return f"/api/method/security_erp.vault.{method}"


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
        return HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail={"code": "RIAD-VAULT-FORBIDDEN", "message": msg})
    if http_code == 404 or "DoesNotExistError" in exc_type:
        return HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"code": "RIAD-VAULT-NOT-FOUND", "message": msg})
    return HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail={"code": "RIAD-VAULT-UPSTREAM-ERROR", "message": msg})


def _unwrap(result: dict):
    return result.get("message", result)


# ── MFA endpoints ─────────────────────────────────────────────────────────────


@router.post("/mfa/enroll")
async def mfa_enroll(current_user: CurrentUser = Depends(get_current_user)):
    """Begin TOTP enrollment — returns provisioning_uri for QR code."""
    try:
        result = await frappe_post(
            _frappe_vault("mfa.enroll_totp"),
            sid=current_user.frappe_sid,
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
    return _unwrap(result)


@router.post("/mfa/verify")
async def mfa_verify(
    body: MfaVerifyRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    """Verify TOTP code, create MFA session in Redis, return vault_session_token."""
    try:
        result = await frappe_post(
            _frappe_vault("mfa.verify_step_up"),
            data={"code": body.code},
            sid=current_user.frappe_sid,
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
    return _unwrap(result)


# ── Vault entry endpoints ─────────────────────────────────────────────────────


@router.post("/entry/decrypt")
async def entry_decrypt(
    body: VaultDecryptRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    """Decrypt specified fields of a Vault Entry.

    Requires fresh vault_session_token (MFA step-up, 5 min TTL).
    Decrypted values returned directly — FastAPI does NOT cache them.
    """
    try:
        result = await frappe_post(
            _frappe_vault("api.decrypt_vault_entry"),
            data={
                "name": body.name,
                "fields": json.dumps(body.fields),
                "vault_session_token": body.vault_session_token,
            },
            sid=current_user.frappe_sid,
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
    return _unwrap(result)


@router.post("/entry/upsert")
async def entry_upsert(
    body: VaultUpsertRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    """Create or update a Vault Entry with encrypted fields.

    Requires fresh vault_session_token (MFA step-up).
    Fields are encrypted server-side before storage.
    """
    try:
        data = {
            "fields": json.dumps(body.fields),
            "vault_session_token": body.vault_session_token,
        }
        if body.name:
            data["name"] = body.name
        if body.meta:
            data["meta"] = json.dumps(body.meta)

        result = await frappe_post(
            _frappe_vault("api.upsert_vault_entry"),
            data=data,
            sid=current_user.frappe_sid,
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
    return _unwrap(result)


# ── Audit endpoint ────────────────────────────────────────────────────────────


@router.get("/audit/verify")
async def audit_verify(current_user: CurrentUser = Depends(get_current_user)):
    """Verify the Vault Audit Log hash-chain integrity.

    System Manager only. Returns {ok: true} or {ok: false, broken: [...]}.
    """
    try:
        result = await frappe_get(
            _frappe_vault("api.verify_vault_chain"),
            sid=current_user.frappe_sid,
        )
    except httpx.HTTPStatusError as exc:
        raise _map_frappe_error(exc)
    return _unwrap(result)
