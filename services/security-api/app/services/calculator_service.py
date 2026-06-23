"""Calculator service — Turnstile verification and Frappe submission proxy."""

import logging
import os

import httpx

logger = logging.getLogger("calculator.service")

TURNSTILE_VERIFY_URL = "https://challenges.cloudflare.com/turnstile/v0/siteverify"
TURNSTILE_SECRET_KEY = os.environ.get("TURNSTILE_SECRET_KEY", "")


async def verify_turnstile(token: str, client_ip: str) -> bool:
    """Verify Cloudflare Turnstile CAPTCHA token.

    Returns True if valid or if secret key is not configured (dev/test mode).
    """
    if not TURNSTILE_SECRET_KEY:
        logger.warning("TURNSTILE_SECRET_KEY not set — skipping verification (dev mode)")
        return True

    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(
            TURNSTILE_VERIFY_URL,
            data={
                "secret": TURNSTILE_SECRET_KEY,
                "response": token,
                "remoteip": client_ip,
            },
        )
        result = resp.json()
        return result.get("success", False)
