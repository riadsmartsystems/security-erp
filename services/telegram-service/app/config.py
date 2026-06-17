from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Telegram Service"
    telegram_bot_token: str = ""
    viber_bot_token: str = ""
    security_api_url: str = "http://security-api:8000"
    nats_url: str = ""
    redis_url: str = ""
    notification_telegram_chat_ids: str = ""
    notification_viber_user_ids: str = ""
    frappe_username: str = ""
    frappe_password: str = ""

    class Config:
        env_file = ".env"


settings = Settings()
