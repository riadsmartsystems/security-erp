from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import redis.asyncio as redis

from app.core.database import get_db
from app.core.redis import get_redis
from app.models.user import User
from app.schemas.auth import LoginRequest, TokenResponse, RefreshRequest, UserCreate, UserResponse
from app.auth.jwt import hash_password, verify_password, create_access_token, create_refresh_token, decode_token
from app.auth.dependencies import get_current_user, CurrentUser

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
async def login(
    body: LoginRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
    redis_client: redis.Redis = Depends(get_redis),
):
    result = await db.execute(select(User).where(User.username == body.username))
    user = result.scalar_one_or_none()

    if not user or not verify_password(body.password, user.hashed_password):
        if user:
            attempts = int(user.failed_login_attempts or "0") + 1
            user.failed_login_attempts = str(attempts)
            if attempts >= 5:
                from datetime import timedelta
                user.locked_until = datetime.now(timezone.utc) + timedelta(minutes=15)
            await db.commit()
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    if user.locked_until and user.locked_until > datetime.now(timezone.utc):
        raise HTTPException(status_code=status.HTTP_423_LOCKED, detail="Account locked. Try again later.")

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account disabled")

    user.failed_login_attempts = "0"
    user.locked_until = None
    user.last_login = datetime.now(timezone.utc)
    await db.commit()

    access_token = create_access_token(str(user.id), user.role)
    refresh_token = create_refresh_token(str(user.id))

    await redis_client.setex(f"session:{user.id}", 900, access_token)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=900,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    body: RefreshRequest,
    db: AsyncSession = Depends(get_db),
    redis_client: redis.Redis = Depends(get_redis),
):
    payload = decode_token(body.refresh_token)
    if not payload or payload.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token")

    user_id = payload.get("sub")
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    access_token = create_access_token(str(user.id), user.role)
    refresh_token = create_refresh_token(str(user.id))

    await redis_client.setex(f"session:{user.id}", 900, access_token)

    return TokenResponse(access_token=access_token, refresh_token=refresh_token, expires_in=900)


@router.post("/logout")
async def logout(
    current_user: CurrentUser = Depends(get_current_user),
    redis_client: redis.Redis = Depends(get_redis),
):
    await redis_client.delete(f"session:{current_user.user_id}")
    return {"success": True}


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == current_user.user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


# =============================================================================
# User Management (Owner/Director only)
# =============================================================================
@router.get("/users")
async def list_users(
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_user.role not in ["owner", "director"]:
        raise HTTPException(status_code=403, detail="Only owner/director can list users")

    result = await db.execute(select(User).order_by(User.created_at.desc()))
    users = result.scalars().all()
    return {
        "success": True,
        "data": [UserResponse.model_validate(u) for u in users],
    }


@router.post("/users")
async def create_user(
    body: UserCreate,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_user.role not in ["owner", "director"]:
        raise HTTPException(status_code=403, detail="Only owner/director can create users")

    # Check if username or email already exists
    existing = await db.execute(
        select(User).where((User.username == body.username) | (User.email == body.email))
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Username or email already exists")

    user = User(
        email=body.email,
        username=body.username,
        full_name=body.full_name,
        hashed_password=hash_password(body.password),
        role=body.role,
        employee_id=body.employee_id,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)

    return {"success": True, "data": UserResponse.model_validate(user)}


@router.put("/users/{user_id}")
async def update_user(
    user_id: str,
    body: dict,
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if current_user.role not in ["owner", "director"]:
        raise HTTPException(status_code=403, detail="Only owner/director can update users")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if "role" in body:
        user.role = body["role"]
    if "full_name" in body:
        user.full_name = body["full_name"]
    if "is_active" in body:
        user.is_active = body["is_active"]
    if "password" in body:
        user.hashed_password = hash_password(body["password"])

    user.updated_at = datetime.now(timezone.utc)
    await db.commit()

    return {"success": True, "data": UserResponse.model_validate(user)}
