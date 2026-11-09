"""La migration 002 et les modèles doivent décrire les mêmes colonnes."""
import importlib.util
from pathlib import Path

from app.api.v1.sync import SYNC_REGISTRY

_CHEMIN = Path(__file__).resolve().parents[2] / "alembic/versions/002_colonnes_hfsql_manquantes.py"


def _migration():
    spec = importlib.util.spec_from_file_location("m002", _CHEMIN)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_chaque_colonne_migree_existe_dans_le_modele():
    m = _migration()
    assert (m.revision, m.down_revision) == ("002", "001")
    for table, colonnes in m.COLONNES.items():
        modele = {c.name: c for c in SYNC_REGISTRY[table].__table__.columns}
        for nom, type_ in colonnes:
            assert nom in modele, f"{table}.{nom} absent du modèle"
            assert type(modele[nom].type).__name__ == type(type_).__name__, f"{table}.{nom}"
