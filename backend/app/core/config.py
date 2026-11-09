from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import URL


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # App
    app_name: str = "PharmaSuite API"
    api_prefix: str = "/api/v1"
    debug: bool = False

    # Database
    db_host: str = "postgres"
    db_port: int = 5432
    db_name: str = "pharmasuite"
    db_user: str = "pharmasuite"
    db_password: str = "pharmasuite_secret"

    # JWT
    secret_key: str = "change-me-in-production-use-openssl-rand-hex-32"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    # Sync agent credentials
    sync_agent_username: str = "sync_agent"
    sync_agent_password: str = "sync_secret_2024"

    # Claude API
    anthropic_api_key: str = "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"

    def _url(self, driver: str) -> str:
        """
        URL de connexion avec utilisateur et mot de passe échappés.

        Un mot de passe contenant `@`, `/`, `#` ou `:` cassait l'URL écrite en
        f-string : l'hôte devenait `@postgres` et la connexion échouait.
        """
        return URL.create(
            driver,
            username=self.db_user,
            password=self.db_password,
            host=self.db_host,
            port=self.db_port,
            database=self.db_name,
        ).render_as_string(hide_password=False)

    @property
    def database_url(self) -> str:
        return self._url("postgresql+asyncpg")

    @property
    def sync_database_url(self) -> str:
        """URL synchrone pour Alembic"""
        return self._url("postgresql+psycopg2")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
