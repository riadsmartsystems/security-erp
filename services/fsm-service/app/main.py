from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app
from apscheduler.schedulers.asyncio import AsyncIOScheduler

from app.core.database import engine
from app.models.ticket import Base
from app.routes.tickets import router as tickets_router
from app.services.sla_engine import check_sla_breaches

scheduler = AsyncIOScheduler()


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    import nats
    nc = await nats.connect("nats://nats:nats_secret@nats:4222")

    async def sla_check_job():
        from app.core.database import async_session
        async with async_session() as db:
            await check_sla_breaches(db, nc)

    scheduler.add_job(sla_check_job, "interval", minutes=1, id="sla_check")
    scheduler.start()

    yield

    scheduler.shutdown()
    await nc.close()
    await engine.dispose()


app = FastAPI(
    title="FSM Service",
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

app.include_router(tickets_router)


@app.get("/health")
async def health():
    return {"status": "ok", "version": "1.0.0"}
