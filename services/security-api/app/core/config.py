from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Security ERP API Gateway"
    debug: bool = False

    redis_url: str = ""
    nats_url: str = ""

    secret_key: str = "change-this-to-random-64-chars-in-production"
    jwt_algorithm: str = "HS256"
    jwt_access_ttl: int = 900
    jwt_refresh_ttl: int = 604800

    frappe_url: str = "http://erpnext-backend:8000"
    ai_service_url: str = ""

    anthropic_api_key: str = ""

    # API key for legacy v1 proxy — must NOT be Administrator's key
    frappe_api_key: str = ""
    frappe_api_secret: str = ""

    # TTL for per-user Frappe SID cached in Redis; must match Frappe site session_expiry
    frappe_session_ttl: int = 21600  # 6 hours

    rate_limit_default: int = 1000
    rate_limit_window: int = 60

    class Config:
        env_file = ".env"


settings = Settings()
