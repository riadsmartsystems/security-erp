from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Telegram Service"
    telegram_bot_token: str = ""
    viber_bot_token: str = ""
    security_api_url: str = "http://security-api:8000"
    nats_url: str = "nats://nats:nats_secret@nats:4222"
    redis_url: str = "redis://:redis_secret@redis:6379/0"
    notification_telegram_chat_ids: str = ""
    notification_viber_user_ids: str = ""
    bot_api_username: str = ""
    bot_api_password: str = ""

    class Config:
        env_file = ".env"


settings = Settings()
