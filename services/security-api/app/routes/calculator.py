"""Calculator submission — public endpoint, no JWT required."""

import logging

from fastapi import APIRouter, HTTPException, Request, status

from app.core.config import settings
from app.core.database import frappe_guest_post
from app.core.rate_limit import check_rate_limit
from app.schemas.calculator import CalcSubmitRequest, CalcSubmitResponse
from app.services.calculator_service import verify_turnstile

logger = logging.getLogger("calculator.route")

router = APIRouter(prefix="/api/v2/calculator", tags=["calculator"])


@router.post("/submit", response_model=CalcSubmitResponse)
async def submit_calculator(body: CalcSubmitRequest, request: Request):
    """Public calculator submission with CAPTCHA + rate limiting."""
    client_ip = request.client.host if request.client else "unknown"

    # Rate limit
    rl = await check_rate_limit(
        f"rl:calc:{client_ip}",
        settings.rate_limit_calc_max,
        settings.rate_limit_calc_window,
    )
    if rl["limited"]:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "code": "RATE_LIMIT_EXCEEDED",
                "message": "Too many calculator submissions. Try again later.",
            },
            headers={"Retry-After": str(rl["retry_after"])},
        )

    # CAPTCHA
    if not await verify_turnstile(body.captcha_token, client_ip):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "CAPTCHA_FAILED", "message": "CAPTCHA verification failed"},
        )

    # Call Frappe calculator.submit
    try:
        result = await frappe_guest_post(
            "/api/method/security_erp.calculator.submit",
            data={
                "object_type": body.object_type,
                "area_m2": body.area_m2,
                "cameras_count": body.cameras_count,
                "archive_days": body.archive_days,
                "contact_name": body.contact_name,
                "contact_phone": body.contact_phone,
                "contact_email": body.contact_email,
                "source_ip": client_ip,
                "captcha_passed": 1,
            },
        )
    except Exception as e:
        logger.error("Frappe calculator.submit failed: %s", e)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": "FRAPPE_ERROR", "message": "Calculator service temporarily unavailable"},
        )

    data = result.get("message", result)
    return CalcSubmitResponse(
        submission_name=data.get("name", ""),
        estimated_total=data.get("estimated_total", 0),
        matched_scenario=data.get("matched_scenario"),
        status=data.get("status", "новий"),
    )
