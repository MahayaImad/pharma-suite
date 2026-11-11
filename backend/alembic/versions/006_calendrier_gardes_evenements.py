"""calendrier : gardes de la pharmacie et fêtes à date mobile

Deux tables pour la prévision de la demande (module Commandes) :

- `gardes` : un jour de garde par ligne. `type` :
    soiree  garde jusqu'à 23 h (ex. le 2026-11-07)
    24h     garde 24 h sur 24 (ex. le 2026-10-01) ; les ventes de la nuit
            sont datées du lendemain
    jour    ouverture un jour normalement fermé
  `source` : `saisie` (par l'officine) ou `detection` (retrouvée dans les
  heures de vente par `scripts/detecter_gardes.py`, à confirmer).

- `evenements_calendrier` : Ramadan et Aïd, dont la date avance d'environ
  11 jours chaque année. Dates de 2022 à 2027 pré-remplies d'après le
  calendrier lunaire ; l'annonce officielle peut décaler d'un jour, d'où
  `a_verifier`. Les jours fériés à date fixe restent dans `holidays`.

Revision ID: 006
Revises: 005
Create Date: 2026-11-12
"""
from datetime import date

import sqlalchemy as sa
from alembic import op

revision = "006"
down_revision = "005"
branch_labels = None
depends_on = None

# (type, début, fin) — fin incluse.
_EVENEMENTS = [
    ("ramadan", date(2022, 4, 2), date(2022, 5, 1)), ("aid_fitr", date(2022, 5, 2), date(2022, 5, 3)),
    ("aid_adha", date(2022, 7, 9), date(2022, 7, 10)),
    ("ramadan", date(2023, 3, 23), date(2023, 4, 20)), ("aid_fitr", date(2023, 4, 21), date(2023, 4, 22)),
    ("aid_adha", date(2023, 6, 28), date(2023, 6, 29)),
    ("ramadan", date(2024, 3, 11), date(2024, 4, 9)), ("aid_fitr", date(2024, 4, 10), date(2024, 4, 11)),
    ("aid_adha", date(2024, 6, 16), date(2024, 6, 17)),
    ("ramadan", date(2025, 3, 1), date(2025, 3, 29)), ("aid_fitr", date(2025, 3, 30), date(2025, 3, 31)),
    ("aid_adha", date(2025, 6, 6), date(2025, 6, 7)),
    ("ramadan", date(2026, 2, 18), date(2026, 3, 19)), ("aid_fitr", date(2026, 3, 20), date(2026, 3, 21)),
    ("aid_adha", date(2026, 5, 27), date(2026, 5, 28)),
    ("ramadan", date(2027, 2, 8), date(2027, 3, 9)), ("aid_fitr", date(2027, 3, 10), date(2027, 3, 11)),
    ("aid_adha", date(2027, 5, 16), date(2027, 5, 17)),
]


def upgrade() -> None:
    op.create_table(
        "gardes",
        sa.Column("date", sa.Date, primary_key=True),
        sa.Column("type", sa.String(10), nullable=False),
        sa.Column("source", sa.String(10), nullable=False, server_default="saisie"),
        sa.Column("confirme", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("note", sa.String(200)),
        sa.Column("modifie_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("modifie_par", sa.String(100)),
        sa.CheckConstraint("type IN ('soiree', '24h', 'jour')", name="ck_gardes_type"),
        sa.CheckConstraint("source IN ('saisie', 'detection')", name="ck_gardes_source"),
    )
    op.create_table(
        "evenements_calendrier",
        sa.Column("id", sa.Integer, primary_key=True, autoincrement=True),
        sa.Column("type", sa.String(20), nullable=False),
        sa.Column("date_debut", sa.Date, nullable=False),
        sa.Column("date_fin", sa.Date, nullable=False),
        sa.Column("a_verifier", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("modifie_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("modifie_par", sa.String(100)),
        sa.CheckConstraint("date_fin >= date_debut", name="ck_evenements_dates"),
        sa.UniqueConstraint("type", "date_debut", name="uq_evenements_type_debut"),
    )
    conn = op.get_bind()
    for type_, debut, fin in _EVENEMENTS:
        conn.execute(sa.text(
            "INSERT INTO evenements_calendrier (type, date_debut, date_fin) VALUES (:t, :d, :f)"),
            {"t": type_, "d": debut, "f": fin})
    # Les deux gardes données par l'officine le 2026-11-12.
    conn.execute(sa.text(
        "INSERT INTO gardes (date, type, source, confirme, note) VALUES "
        "('2026-11-07', 'soiree', 'saisie', true, 'donnée par l''officine'), "
        "('2026-10-01', '24h', 'saisie', true, 'donnée par l''officine')"))


def downgrade() -> None:
    op.drop_table("evenements_calendrier")
    op.drop_table("gardes")
