from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "FSM Service"
    debug: bool = False
    database_url: str = "postgresql+asyncpg://fsm_user:fsm_secret@postgres:5432/security_erp"
    redis_url: str = "redis://:redis_secret@redis:6379/0"
    nats_url: str = "nats://nats:nats_secret@nats:4222"
    erp_api_url: str = "http://erpnext-backend:8000"
    security_api_url: str = "http://security-api:8000"
    schema_name: str = "fsm"

    class Config:
        env_file = ".env"


settings = Settings()
