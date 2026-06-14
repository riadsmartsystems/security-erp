from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app

from app.core.database import engine
from app.models.equipment import Base
from app.routes.objects import router as objects_router
from app.routes.photos import router as photos_router
from app.routes.backups import router as backups_router
from app.routes.integrations import router as integrations_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


app = FastAPI(
    title="CMDB Service",
    version="1.0.0",
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

app.include_router(objects_router)
app.include_router(photos_router)
app.include_router(backups_router)
app.include_router(integrations_router)


@app.get("/health")
async def health():
    return {"status": "ok", "version": "1.0.0"}
