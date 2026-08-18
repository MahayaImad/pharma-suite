from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # App
    app_name: str = "Synergo API"
    api_prefix: str = "/api/v1"
    debug: bool = False

    # Database
    db_host: str = "postgres"
    db_port: int = 5432
    db_name: str = "synergo"
    db_user: str = "synergo"
    db_password: str = "synergo_secret"

    # JWT
    secret_key: str = "change-me-in-production-use-openssl-rand-hex-32"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    # Sync agent credentials
    sync_agent_username: str = "sync_agent"
    sync_agent_password: str = "sync_secret_2024"

    # Claude API
    anthropic_api_key: str = "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"

    @property
    def database_url(self) -> str:
        return (
            f"postgresql+asyncpg://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )

    @property
    def sync_database_url(self) -> str:
        """URL synchrone pour Alembic"""
        return (
            f"postgresql+psycopg2://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
