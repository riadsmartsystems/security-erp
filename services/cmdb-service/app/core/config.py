from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "CMDB Service"
    debug: bool = False
    database_url: str = "postgresql+asyncpg://cmdb_user:cmdb_secret@postgres:5432/security_erp"
    redis_url: str = ""
    nats_url: str = ""
    minio_endpoint: str = "minio:9000"
    minio_access_key: str = "minioadmin"
    minio_secret_key: str = ""
    schema_name: str = "cmdb"

    class Config:
        env_file = ".env"


settings = Settings()
