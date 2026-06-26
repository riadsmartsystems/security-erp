import time
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
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
from app.routes.doctypes import router as doctypes_router
from app.routes.visits import router as visits_router
from app.routes.vault import router as vault_router
from app.routes.act import act_router, public_router as act_public_router
from app.routes.ai import router as ai_router
from app.routes.estimates import router as estimates_router
from app.routes.media import router as media_router
from app.routes.scenarios import router as scenarios_router
from app.routes.ai_admin import router as ai_admin_router
from app.routes.sync import router as sync_router
from app.routes.serial import router as serial_router
from app.routes.maps import router as maps_router
from app.routes.warehouse import router as warehouse_router
from app.routes.calculator import router as calculator_router
from app.routes.push import router as push_router


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
    allow_origins=[
        "https://erp.riad.fun",
        "https://api.riad.fun",
        "https://grafana.riad.fun",
        "https://mimo.riad.fun",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://10.0.2.2:3000",
    ],
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
app.include_router(estimates_router)
app.include_router(media_router)
app.include_router(scenarios_router)
app.include_router(ai_admin_router)
app.include_router(doctypes_router)
app.include_router(visits_router)
app.include_router(vault_router)
app.include_router(act_router)
app.include_router(act_public_router)
app.include_router(ai_router)
app.include_router(sync_router)
app.include_router(serial_router)
app.include_router(maps_router)
app.include_router(warehouse_router)
app.include_router(calculator_router)
app.include_router(push_router)
app.include_router(proxy_router)


@app.get("/health")
async def health():
    return {"status": "ok", "version": "2.1.0", "backend": "frappe"}


@app.get("/order")
async def order_page():
    return FileResponse("/app/app/static/order.html", headers={"Cache-Control": "no-cache, no-store, must-revalidate"})


@app.get("/test")
async def test_page():
    return FileResponse("/app/app/static/test.html", headers={"Cache-Control": "no-cache, no-store, must-revalidate"})


@app.get("/act/{token}")
async def act_page(token: str):
    return FileResponse("/app/app/static/act.html", headers={"Cache-Control": "no-cache, no-store, must-revalidate"})


@app.get("/")
async def root():
    return {
        "name": "Security ERP API Gateway",
        "version": "2.1.0",
        "status": "ok",
        "endpoints": {
            "health": "/health",
            "login": "/api/v2/auth/login",
            "docs": "/docs",
            "tickets": "/api/v2/tickets",
            "objects": "/api/v2/objects",
            "equipment": "/api/v2/equipment",
            "visits": "/api/v2/visits",
        }
    }
