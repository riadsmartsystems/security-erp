"""Estimate lifecycle endpoints — /api/v2/estimates/*.

POST /api/v2/estimates/build         — create estimate (sync or RQ)
POST /api/v2/estimates/{name}/review — approve/reject
POST /api/v2/estimates/{name}/confirm — confirm → Quotation via gateway
"""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException

from app.auth.dependencies import CurrentUser, get_current_user
from app.schemas.estimate import (
    EstimateBuildRequest,
    EstimateBuildResponse,
    EstimateReviewRequest,
    EstimateReviewResponse,
    EstimateConfirmResponse,
)
from app.services.estimate_service import build_estimate, review_estimate, confirm_estimate

logger = logging.getLogger("estimates.routes")

router = APIRouter(prefix="/api/v2/estimates", tags=["estimates"])


@router.post("/build", response_model=EstimateBuildResponse)
async def estimate_build(
    body: EstimateBuildRequest,
    user: CurrentUser = Depends(get_current_user),
):
    """Build AI estimate from Site Brief. Sync if <5s, else RQ enqueue."""
    try:
        result = await build_estimate(
            sid=user.frappe_sid,
            site_brief_name=body.site_brief_name,
            variant=body.variant,
            user_id=user.user_id,
        )
    except Exception as exc:
        logger.error("estimate.build failed: %s", exc)
        raise HTTPException(status_code=502, detail=f"Estimate build failed: {exc}")

    return EstimateBuildResponse(
        name=result.get("name", ""),
        status=result.get("status", "error"),
        origin=result.get("origin", "manual"),
    )


@router.post("/{name}/review", response_model=EstimateReviewResponse)
async def estimate_review(
    name: str,
    body: EstimateReviewRequest,
    user: CurrentUser = Depends(get_current_user),
):
    """Review AI estimate: approved/rejected. Sets reviewed_by + status."""
    try:
        result = await review_estimate(
            sid=user.frappe_sid,
            name=name,
            decision=body.decision,
            user_id=user.user_id,
        )
    except ValueError as exc:
        code = str(exc)
        if "RIAD-VALIDATION" in code:
            raise HTTPException(status_code=422, detail={"code": "RIAD-VALIDATION", "message": code})
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        logger.error("estimate.review failed: %s", exc)
        raise HTTPException(status_code=502, detail=f"Estimate review failed: {exc}")

    return EstimateReviewResponse(
        name=result["name"],
        status=result["status"],
        reviewed_by=result["reviewed_by"],
    )


@router.post("/{name}/confirm", response_model=EstimateConfirmResponse)
async def estimate_confirm(
    name: str,
    user: CurrentUser = Depends(get_current_user),
):
    """Confirm estimate → create Quotation. Hard boundary: status=Approved + reviewed_by."""
    try:
        result = await confirm_estimate(
            sid=user.frappe_sid,
            name=name,
        )
    except ValueError as exc:
        code = str(exc)
        if "RIAD-VALIDATION" in code:
            raise HTTPException(status_code=422, detail={"code": "RIAD-VALIDATION", "message": code})
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception as exc:
        logger.error("estimate.confirm failed: %s", exc)
        raise HTTPException(status_code=502, detail=f"Estimate confirm failed: {exc}")

    return EstimateConfirmResponse(quotation_name=result["quotation_name"])
