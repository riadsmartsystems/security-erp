from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Security ERP API Gateway"
    debug: bool = False

    redis_url: str = "redis://:redis_secret@redis:6379/0"
    nats_url: str = "nats://nats:nats_secret@nats:4222"

    secret_key: str = "change-this-to-random-64-chars-in-production"
    jwt_algorithm: str = "HS256"
    jwt_access_ttl: int = 900
    jwt_refresh_ttl: int = 604800

    frappe_url: str = "http://erpnext-backend:8000"

    frappe_api_key: str = ""
    frappe_api_secret: str = ""

    rate_limit_default: int = 1000
    rate_limit_window: int = 60

    class Config:
        env_file = ".env"


settings = Settings()
