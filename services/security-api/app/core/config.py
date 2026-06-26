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

    # R4: per-endpoint rate limits (sliding window via Redis sorted set)
    rate_limit_login_max: int = 5
    rate_limit_login_window: int = 900  # 15 min
    rate_limit_refresh_max: int = 30
    rate_limit_refresh_window: int = 900  # 15 min

    # V3: Vault MFA session TTL
    vault_mfa_ttl: int = 300  # 5 min

    # C1: calculator rate limit
    rate_limit_calc_max: int = 5
    rate_limit_calc_window: int = 3600  # 1 hour

    # S3: Google Drive service account for media upload
    google_service_account_json: str = ""  # path to service account JSON key
    google_drive_folder_id: str = ""  # target folder ID in Drive

    # Firebase Cloud Messaging — path to service account JSON key
    firebase_credentials_json: str = ""

    class Config:
        env_file = ".env"
        extra = "ignore"


settings = Settings()
