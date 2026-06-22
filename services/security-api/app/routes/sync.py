from fastapi import APIRouter, Depends

from app.auth.dependencies import CurrentUser, get_current_user
from app.schemas.sync import (
    SyncPullRequest,
    SyncPullResponse,
    SyncPushRequest,
    SyncPushResponse,
    SyncResolveRequest,
    SyncResolveResponse,
)
from app.services.sync_service import pull_changes, push_batch, resolve_conflict

router = APIRouter(prefix="/api/v2/sync", tags=["sync"])


@router.post("/pull", response_model=SyncPullResponse)
async def sync_pull(
    request: SyncPullRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> SyncPullResponse:
    return await pull_changes(request, sid=current_user.frappe_sid)


@router.post("/push", response_model=SyncPushResponse)
async def sync_push(
    request: SyncPushRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> SyncPushResponse:
    return await push_batch(request, user_id=current_user.user_id, sid=current_user.frappe_sid)


@router.post("/resolve", response_model=SyncResolveResponse)
async def sync_resolve(
    request: SyncResolveRequest,
    current_user: CurrentUser = Depends(get_current_user),
) -> SyncResolveResponse:
    return await resolve_conflict(request, user_id=current_user.user_id, sid=current_user.frappe_sid)
