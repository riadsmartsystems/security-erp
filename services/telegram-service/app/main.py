from fastapi import FastAPI
from contextlib import asynccontextmanager

app = FastAPI(title="Telegram Service", version="1.0.0")


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(
    title="Telegram Service",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/health")
async def health():
    return {"status": "ok", "version": "1.0.0"}


@app.post("/api/v1/telegram/webhook")
async def telegram_webhook(update: dict):
    return {"ok": True}
