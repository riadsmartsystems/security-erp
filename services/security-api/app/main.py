import time
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app

from app.core.config import settings
from app.core.redis import get_redis
from app.core.database import close_client
from app.routes.auth import router as auth_router
from app.routes.proxy import router as proxy_router
from app.routes.banking import router as banking_router
from app.routes.signatures import router as signatures_router
from app.routes.portal import router as portal_router
from app.routes.public_api import router as public_router
from app.routes.mobile import router as mobile_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    await close_client()


app = FastAPI(
    title="Security ERP API Gateway",
    version="2.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    if request.url.path in ("/health", "/metrics"):
        return await call_next(request)

    client_ip = request.client.host if request.client else "unknown"
    key = f"rl:{client_ip}"
    try:
        r = await get_redis()
        current = await r.incr(key)
        if current == 1:
            await r.expire(key, settings.rate_limit_window)
        if current > settings.rate_limit_default:
            return Response(
                content='{"success":false,"error":"Rate limit exceeded"}',
                status_code=429,
                media_type="application/json",
            )
    except Exception:
        pass

    response = await call_next(request)
    return response


@app.middleware("http")
async def add_timing_header(request: Request, call_next):
    start = time.monotonic()
    response = await call_next(request)
    elapsed = time.monotonic() - start
    response.headers["X-Response-Time"] = f"{elapsed:.4f}"
    return response


metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

app.include_router(auth_router)
app.include_router(banking_router)
app.include_router(signatures_router)
app.include_router(portal_router)
app.include_router(public_router)
app.include_router(mobile_router)
app.include_router(proxy_router)


@app.get("/health")
async def health():
    return {"status": "ok", "version": "2.1.0", "backend": "frappe"}
