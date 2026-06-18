from fastapi import Depends, HTTPException, Header, status
import httpx
from app.core.config import settings

async def get_current_user(authorization: str = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization header"
        )
    
    token = authorization.split(" ")[1]
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            # Verify token with Security API
            resp = await client.get(
                f"{settings.security_api_url}/api/v1/auth/me",
                headers={"Authorization": f"Bearer {token}"}
            )
            
            if resp.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid or expired token"
                )
            
            user_data = resp.json().get("data", {})
            return user_data
    except httpx.RequestError as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Authentication service unavailable: {str(e)}"
        )
