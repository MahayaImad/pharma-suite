from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import URL


class Settings(BaseSettings):
    """Réglages lus dans l'environnement (ou `.env`). Les secrets n'ont pas de
    valeur par défaut : ils viennent de `docker/.env`, jamais du code."""

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
    db_password: str = ""

    # JWT
    secret_key: str = ""
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    # Sync agent credentials
    sync_agent_username: str = "sync_agent"
    sync_agent_password: str = ""

    # Claude API (chatbot) : vide = chatbot désactivé
    anthropic_api_key: str = ""

    # Origines autorisées à appeler l'API depuis un navigateur (CORS), séparées
    # par des virgules. Vide : aucune. L'application web passe par nginx sur la
    # même adresse et n'en a pas besoin ; utile en développement seulement
    # (ex. http://localhost:5000).
    cors_origins: str = ""

    @property
    def origines_cors(self) -> list[str]:
        return [o.strip().rstrip("/") for o in self.cors_origins.split(",") if o.strip()]

    def secrets_manquants(self) -> list[str]:
        """Variables d'environnement obligatoires absentes ou trop faibles.

        Aucun secret n'a de valeur par défaut : sans elles l'API ne démarre pas
        (voir `main.lifespan`), plutôt que de tourner avec une valeur connue."""
        manquants = []
        if not self.db_password:
            manquants.append("DB_PASSWORD")
        if len(self.secret_key) < 32:
            manquants.append("SECRET_KEY (32 caractères au moins : openssl rand -hex 32)")
        if not self.sync_agent_password:
            manquants.append("SYNC_AGENT_PASSWORD")
        return manquants

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
