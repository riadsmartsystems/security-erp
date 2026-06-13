from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.auth.jwt import decode_token
from app.auth.permissions import Role, Permission, has_permission
import redis.asyncio as redis
from app.core.redis import get_redis

security = HTTPBearer()


class CurrentUser:
    def __init__(self, user_id: str, role: Role):
        self.user_id = user_id
        self.role = role

    def has(self, permission: Permission) -> bool:
        return has_permission(self.role, permission)

    def require(self, permission: Permission):
        if not self.has(permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission denied: {permission.value}",
            )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    redis_client: redis.Redis = Depends(get_redis),
) -> CurrentUser:
    token = credentials.credentials
    payload = decode_token(token)

    if payload is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    if payload.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")

    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token payload")

    is_blacklisted = await redis_client.get(f"token:blacklist:{token}")
    if is_blacklisted:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token revoked")

    role_str = payload.get("role", "viewer")
    try:
        role = Role(role_str)
    except ValueError:
        role = Role.VIEWER

    return CurrentUser(user_id=user_id, role=role)
