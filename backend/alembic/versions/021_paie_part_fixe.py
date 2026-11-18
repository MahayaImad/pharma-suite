"""paie : part fixe (règle 7), heures supplémentaires saisies, bulletins validés

- `employes.date_sortie` : départ en cours de mois → part fixe au prorata.
- `paie_heures_sup` : heures supplémentaires du mois, saisies à la main par le
  titulaire (arbitrage du 2026-11-18 : rien ne mesure les heures).
- `paie_bulletins` : bulletin brut validé (part fixe ligne par ligne, part
  variable, brut). Chaque validation ajoute une version, aucune n'est écrasée
  (contestation).
- réglages `paie_*` dans `reglages_stock` : transport et panier par jour,
  ancienneté par an et plafond, majoration et heures mensuelles.

Revision ID: 021
Revises: 020
Create Date: 2026-11-18
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "021"
down_revision = "020"
branch_labels = None
depends_on = None

_REGLAGES = (
    ("paie_transport_jour", 300, "Paie : prime de transport par jour de présence effective (DA)"),
    ("paie_panier_jour", 600, "Paie : prime de panier par jour de présence effective (DA)"),
    ("paie_anciennete_an", 1000, "Paie : prime d'ancienneté par année révolue (DA)"),
    ("paie_anciennete_plafond", 15000, "Paie : plafond de la prime d'ancienneté (DA)"),
    ("paie_majoration_hs", 1.5, "Paie : majoration des heures supplémentaires (1,5 = +50 %)"),
    ("paie_heures_mois", 173.33, "Paie : heures mensuelles pour le taux horaire (40 h × 52 ÷ 12)"),
)


def upgrade() -> None:
    op.add_column("employes", sa.Column("date_sortie", sa.Date))
    op.create_table(
        "paie_heures_sup",
        sa.Column("employe_id", sa.Integer, sa.ForeignKey("employes.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("annee", sa.Integer, primary_key=True),
        sa.Column("mois", sa.Integer, primary_key=True),
        sa.Column("heures", sa.Numeric(6, 2), nullable=False),
        sa.Column("note", sa.String(200)),
        sa.Column("saisi_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("saisi_par", sa.String(100)),
        sa.CheckConstraint("heures >= 0", name="ck_paie_heures_sup_heures"),
    )
    op.create_table(
        "paie_bulletins",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("employe_id", sa.Integer, sa.ForeignKey("employes.id", ondelete="CASCADE"), nullable=False),
        sa.Column("annee", sa.Integer, nullable=False),
        sa.Column("mois", sa.Integer, nullable=False),
        sa.Column("version", sa.Integer, nullable=False),
        sa.Column("detail", postgresql.JSONB, nullable=False),
        sa.Column("part_fixe", sa.Numeric(14, 2), nullable=False),
        sa.Column("part_variable", sa.Numeric(14, 2), nullable=False),
        sa.Column("brut", sa.Numeric(14, 2), nullable=False),
        sa.Column("valide_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("valide_par", sa.String(100)),
        sa.UniqueConstraint("employe_id", "annee", "mois", "version", name="uq_paie_bulletins_version"),
    )
    conn = op.get_bind()
    for cle, valeur, description in _REGLAGES:
        conn.execute(sa.text(
            "INSERT INTO reglages_stock (cle, valeur, description) VALUES (:c, :v, :d) ON CONFLICT (cle) DO NOTHING"),
            {"c": cle, "v": valeur, "d": description})


def downgrade() -> None:
    op.drop_table("paie_bulletins")
    op.drop_table("paie_heures_sup")
    op.drop_column("employes", "date_sortie")
    op.execute("DELETE FROM reglages_stock WHERE cle LIKE 'paie\\_%'")
