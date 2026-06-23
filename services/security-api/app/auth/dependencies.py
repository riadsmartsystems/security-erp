from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.auth.jwt import decode_token
from app.auth.permissions import Role, Permission, has_permission
import redis.asyncio as redis
from app.core.redis import get_redis

security = HTTPBearer()

_FRAPPE_SID_KEY = "frappe:sid:{user_id}"


class CurrentUser:
    def __init__(self, user_id: str, role: Role, frappe_sid: str, frappe_roles: list | None = None):
        self.user_id = user_id
        self.role = role
        self.frappe_sid = frappe_sid
        self.frappe_roles = frappe_roles or []

    def has(self, permission: Permission) -> bool:
        return has_permission(self.role, permission)

    def require(self, permission: Permission):
        if not self.has(permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission denied: {permission.value}",
            )

    def has_frappe_role(self, role_name: str) -> bool:
        return role_name in self.frappe_roles


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

    frappe_sid = await redis_client.get(_FRAPPE_SID_KEY.format(user_id=user_id))
    if not frappe_sid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "FRAPPE_SESSION_EXPIRED", "message": "Frappe session expired, please re-login"},
        )

    role_str = payload.get("role", "viewer")
    try:
        role = Role(role_str)
    except ValueError:
        role = Role.VIEWER

    frappe_roles = payload.get("frappe_roles", [])

    return CurrentUser(
        user_id=user_id,
        role=role,
        frappe_sid=str(frappe_sid),
        frappe_roles=frappe_roles,
    )
