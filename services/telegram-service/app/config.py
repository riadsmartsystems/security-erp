from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Telegram Service"
    telegram_bot_token: str = ""
    security_api_url: str = "http://security-api:8000"
    nats_url: str = "nats://nats:nats_secret@nats:4222"
    redis_url: str = "redis://:redis_secret@redis:6379/0"

    class Config:
        env_file = ".env"


settings = Settings()
