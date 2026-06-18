from fastapi import Depends, HTTPException, Header, status
from typing import Optional
import httpx
from app.core.config import settings

async def get_current_user(authorization: Optional[str] = Header(None)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid authorization header",
        )
    
    token = authorization.split(" ")[1]
    
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            # We call the security-api (or ERPNext) to validate the token
            # The prompt specifically mentions /api/v1/auth/me
            response = await client.get(
                f"{settings.security_api_url}/api/v1/auth/me",
                headers={"Authorization": f"Bearer {token}"},
            )
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid or expired token",
                )
            
            user_data = response.json()
            return user_data
            
    except httpx.RequestError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service unavailable",
        )
