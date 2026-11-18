"""présence : heure de début, retard détecté d'après la première vente

Arbitrage du 2026-11-18 : en attendant une pointeuse, le retard se déduit de
l'heure de la première vente du jour. Un jour est « retard » quand la
première vente arrive plus de `paie_tolerance_retard_min` minutes après
l'heure de début de l'employé.

- `employes.heure_debut` : heure de début propre à un employé (sinon le
  réglage général).
- réglages (minutes depuis minuit, dans `reglages_stock`) :
  `paie_heure_debut` (8 h 30), `paie_heure_debut_ramadan` (même heure tant
  qu'on ne la change pas), `paie_tolerance_retard_min` (45).

Revision ID: 022
Revises: 021
Create Date: 2026-11-18
"""
import sqlalchemy as sa
from alembic import op

revision = "022"
down_revision = "021"
branch_labels = None
depends_on = None

_REGLAGES = (
    ("paie_heure_debut", 510, "Présence : heure de début de journée, en minutes depuis minuit (510 = 8 h 30)"),
    ("paie_heure_debut_ramadan", 510, "Présence : heure de début pendant le Ramadan, en minutes depuis minuit"),
    ("paie_tolerance_retard_min", 45, "Présence : minutes de tolérance avant qu'un jour compte comme retard"),
)


def upgrade() -> None:
    op.add_column("employes", sa.Column("heure_debut", sa.Time))
    conn = op.get_bind()
    for cle, valeur, description in _REGLAGES:
        conn.execute(sa.text(
            "INSERT INTO reglages_stock (cle, valeur, description) VALUES (:c, :v, :d) ON CONFLICT (cle) DO NOTHING"),
            {"c": cle, "v": valeur, "d": description})


def downgrade() -> None:
    op.drop_column("employes", "heure_debut")
    op.execute("DELETE FROM reglages_stock WHERE cle IN "
               "('paie_heure_debut', 'paie_heure_debut_ramadan', 'paie_tolerance_retard_min')")
