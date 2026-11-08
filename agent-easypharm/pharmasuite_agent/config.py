"""Chargement de la configuration TOML."""
from __future__ import annotations

import tomllib
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class SourceConfig:
    dsn: str
    user: str = ""
    password: str = ""
    fetch_size: int = 500


@dataclass(frozen=True)
class ApiConfig:
    base_url: str
    username: str
    password: str
    timeout_seconds: int = 60
    batch_size: int = 500


@dataclass(frozen=True)
class AgentConfig:
    interval_seconds: int = 300
    full_resync_every: int = 12
    state_file: str = "agent_state.json"
    log_file: str = "agent.log"
    respecter_intervalles: bool = True  # Utilise les intervalles par table


@dataclass(frozen=True)
class Config:
    source: SourceConfig
    api: ApiConfig
    agent: AgentConfig

    @classmethod
    def charger(cls, chemin: str | Path) -> "Config":
        donnees = tomllib.loads(Path(chemin).read_text(encoding="utf-8"))
        return cls(
            source=SourceConfig(**donnees["source"]),
            api=ApiConfig(**donnees["api"]),
            agent=AgentConfig(**donnees.get("agent", {})),
        )
