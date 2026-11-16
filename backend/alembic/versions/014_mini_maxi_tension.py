"""stratégie mini / maxi et produits en tension

Arrêtée avec l'officine le 2026-11-16 (app/services/prevision/proposition.py,
`decider_minmax`) : on ne commande que sous le mini, et alors jusqu'au maxi ;
le maxi couvre une durée visée selon la classe ABC, plus longue pour un
produit en tension (quota chez les grossistes, pénurie).

- réglages `couverture_a_jours` 15, `couverture_b_jours` 21,
  `couverture_c_jours` 30, `couverture_tension_jours` 60 ;
- `produits_tension` : produits en tension détectés (longue rupture sans
  livraison malgré une demande régulière, ou `disponibilite = 'quota'`) à
  confirmer par le titulaire, ou marqués par lui. Seuls les confirmés
  comptent dans le calcul.

Revision ID: 014
Revises: 013
Create Date: 2026-11-16
"""
import sqlalchemy as sa
from alembic import op

revision = "014"
down_revision = "013"
branch_labels = None
depends_on = None

_REGLAGES = [
    ("couverture_a_jours", 15, "Couverture visée, classe A (jours)"),
    ("couverture_b_jours", 21, "Couverture visée, classe B (jours)"),
    ("couverture_c_jours", 30, "Couverture visée, classe C (jours)"),
    ("couverture_tension_jours", 60, "Couverture visée, produit en tension (jours)"),
]


def upgrade() -> None:
    op.create_table(
        "produits_tension",
        sa.Column("id_nom", sa.BigInteger, primary_key=True),
        sa.Column("tension", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("confirme", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("source", sa.String(10), nullable=False, server_default="detection"),
        sa.Column("motif", sa.String(200)),
        sa.Column("detecte_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("modifie_le", sa.DateTime(timezone=True)),
        sa.Column("modifie_par", sa.String(100)),
        sa.CheckConstraint("source IN ('detection', 'saisie')", name="ck_produits_tension_source"),
    )
    conn = op.get_bind()
    for cle, valeur, description in _REGLAGES:
        conn.execute(sa.text("INSERT INTO reglages_stock (cle, valeur, description) VALUES (:c, :v, :d) "
                             "ON CONFLICT (cle) DO NOTHING"), {"c": cle, "v": valeur, "d": description})


def downgrade() -> None:
    op.drop_table("produits_tension")
    op.execute("DELETE FROM reglages_stock WHERE cle IN ('couverture_a_jours', 'couverture_b_jours', "
               "'couverture_c_jours', 'couverture_tension_jours')")
