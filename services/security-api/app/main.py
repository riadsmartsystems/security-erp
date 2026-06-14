from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app

from app.routes.auth import router as auth_router
from app.routes.proxy import router as proxy_router
from app.routes.banking import router as banking_router
from app.routes.signatures import router as signatures_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(
    title="Security ERP API Gateway",
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

app.include_router(auth_router)
app.include_router(banking_router)
app.include_router(signatures_router)
app.include_router(proxy_router)


@app.get("/health")
async def health():
    return {"status": "ok", "version": "2.0.0", "backend": "frappe"}
