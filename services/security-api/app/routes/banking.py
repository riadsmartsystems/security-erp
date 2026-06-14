from fastapi import APIRouter, Query
import uuid

router = APIRouter(prefix="/api/v1/banking", tags=["banking"])


@router.get("/accounts")
async def list_bank_accounts():
    return {"success": True, "data": [], "message": "Bank integration not configured"}


@router.get("/transactions")
async def list_transactions(
    account_id: str = None,
    from_date: str = None,
    to_date: str = None,
    limit: int = Query(50, le=200),
):
    return {"success": True, "data": [], "message": "Bank integration not configured"}


@router.post("/sync")
async def sync_transactions(data: dict = None):
    return {"success": True, "message": "Bank sync not configured. Set MONOBANK_TOKEN or PRIVATBANK_TOKEN"}


@router.get("/reconciliation")
async def get_reconciliation(
    from_date: str = None,
    to_date: str = None,
):
    return {"success": True, "data": {"matched": 0, "unmatched": 0, "total": 0}}
