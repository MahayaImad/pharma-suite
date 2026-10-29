"""baseline — schéma complet PharmaSuite

Écrase les 39 migrations incrémentales 001→039 de l'ère « synergo ». Le schéma
et les données de référence sont figés dans deux fichiers SQL voisins, obtenus
en rejouant les 39 migrations sur une base vierge puis en la dumpant.

Bases existantes : ne PAS lancer cette migration. Raccorder d'un
    alembic stamp 001
la base est déjà dans cet état.

Revision ID: 001
Revises:
Create Date: 2026-08-19
"""
from pathlib import Path

from alembic import op

revision = "001"
down_revision = None
branch_labels = None
depends_on = None

_SQL = Path(__file__).parent / "baseline"


def _run(nom: str) -> None:
    """
    Exécute un fichier SQL d'un bloc, via le curseur DBAPI.

    Sans second argument, psycopg2 n'interprète pas les `%` — les seeds en
    contiennent (« 100% »), ils doivent passer littéralement.
    """
    sql = (_SQL / nom).read_text(encoding="utf-8")
    cursor = op.get_bind().connection.cursor()
    try:
        cursor.execute(sql)
    finally:
        cursor.close()


def upgrade() -> None:
    _run("schema.sql")
    _run("seeds.sql")


def downgrade() -> None:
    # Une baseline ne se redescend pas : ce serait vider la base.
    raise NotImplementedError("Le downgrade de la baseline n'est pas supporté.")
