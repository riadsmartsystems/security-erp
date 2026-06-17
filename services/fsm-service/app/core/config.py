from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "FSM Service"
    debug: bool = False
    database_url: str = "postgresql+asyncpg://fsm_user:fsm_secret@postgres:5432/security_erp"
    redis_url: str = ""
    nats_url: str = ""
    erp_api_url: str = "http://erpnext-backend:8000"
    security_api_url: str = "http://security-api:8000"
    schema_name: str = "fsm"
    telegram_bot_token: str = ""
    telegram_chat_id: str = ""

    class Config:
        env_file = ".env"


settings = Settings()
