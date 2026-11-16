"""Aucun secret par défaut : l'API refuse de démarrer sans eux, et le CORS est une liste fermée."""
import re
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.core.config import Settings

SANS_ENV = dict(_env_file=None)


def _reglages(monkeypatch, **valeurs):
    for cle in ("DB_PASSWORD", "SECRET_KEY", "SYNC_AGENT_PASSWORD", "ANTHROPIC_API_KEY", "CORS_ORIGINS"):
        monkeypatch.delenv(cle, raising=False)
    return Settings(**SANS_ENV, **valeurs)


def test_aucun_secret_n_a_de_valeur_par_defaut(monkeypatch):
    s = _reglages(monkeypatch)
    assert (s.db_password, s.secret_key, s.sync_agent_password, s.anthropic_api_key) == ("", "", "", "")
    assert len(s.secrets_manquants()) == 3


def test_secrets_complets_et_cle_de_signature_assez_longue(monkeypatch):
    s = _reglages(monkeypatch, db_password="x", secret_key="a" * 32, sync_agent_password="y")
    assert s.secrets_manquants() == []
    court = _reglages(monkeypatch, db_password="x", secret_key="trop-court", sync_agent_password="y")
    assert [m.split()[0] for m in court.secrets_manquants()] == ["SECRET_KEY"]


def test_origines_cors_liste_fermee(monkeypatch):
    assert _reglages(monkeypatch).origines_cors == []
    s = _reglages(monkeypatch, cors_origins="http://localhost:5000/, https://officine.example ,")
    assert s.origines_cors == ["http://localhost:5000", "https://officine.example"]


def test_pas_de_cle_api_en_dur_dans_le_code():
    racine = Path(__file__).resolve().parents[2] / "app"
    for fichier in racine.rglob("*.py"):
        assert not re.search(r"sk-ant-[A-Za-z0-9_-]{20,}", fichier.read_text(encoding="utf-8")), fichier


def test_l_api_ne_demarre_pas_sans_secrets_et_n_ouvre_pas_le_cors(monkeypatch):
    from app import main

    monkeypatch.setattr(main.settings, "secret_key", "")
    with pytest.raises(RuntimeError, match="SECRET_KEY"):
        with TestClient(main.app):
            pass
    cors = next(m for m in main.app.user_middleware if m.cls.__name__ == "CORSMiddleware")
    assert cors.kwargs["allow_origins"] == main.settings.origines_cors and "*" not in cors.kwargs["allow_origins"]
