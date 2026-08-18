"""Module assistant achat — tables de cache et delai_livraison fournisseur

Revision ID: 024
Revises: 023
Create Date: 2026-04-11

Changements :
- fournisseurs.delai_livraison  : INTEGER (jours), nullable, saisi manuellement
- parametres_stock              : cache SS / ROP / EOQ par produit
- previsions_demande            : cache prévisions Croston/HW/OLS par produit
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision = "024"
down_revision = "023"
branch_labels = None
depends_on = None


def upgrade() -> None:
    conn = op.get_bind()

    # ── delai_livraison sur fournisseurs ──────────────────────────────────────
    has_col = conn.execute(sa.text("""
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'fournisseurs' AND column_name = 'delai_livraison'
    """)).fetchone()
    if not has_col:
        op.add_column(
            "fournisseurs",
            sa.Column(
                "delai_livraison", sa.Integer(), nullable=True,
                comment="Délai de livraison moyen en jours (saisi manuellement)",
            ),
        )

    # ── parametres_stock ──────────────────────────────────────────────────────
    if not conn.dialect.has_table(conn, "parametres_stock"):
        op.create_table(
            "parametres_stock",
            sa.Column("id_nom", sa.BigInteger(), primary_key=True,
                      comment="Référence nomenclature"),
            sa.Column("delai_moyen_j", sa.Numeric(8, 2), nullable=True,
                      comment="Délai moyen fournisseur principal (jours)"),
            sa.Column("demande_moy_j", sa.Numeric(10, 4), nullable=True,
                      comment="Demande journalière moyenne corrigée"),
            sa.Column("demande_std_j", sa.Numeric(10, 4), nullable=True,
                      comment="Écart-type demande journalière corrigée"),
            sa.Column("stock_securite", sa.Numeric(10, 2), nullable=True,
                      comment="Stock de sécurité calculé"),
            sa.Column("rop", sa.Numeric(10, 2), nullable=True,
                      comment="Point de reorder (ROP)"),
            sa.Column("eoq", sa.Numeric(10, 2), nullable=True,
                      comment="Quantité économique de commande (EOQ)"),
            sa.Column("holding_cost_pct", sa.Numeric(5, 4), nullable=True,
                      server_default="0.20",
                      comment="Taux de possession annuel (défaut 20%)"),
            sa.Column("updated_at", sa.DateTime(timezone=True),
                      server_default=sa.text("NOW()"), nullable=False),
        )

    # ── previsions_demande ────────────────────────────────────────────────────
    if not conn.dialect.has_table(conn, "previsions_demande"):
        op.create_table(
            "previsions_demande",
            sa.Column("id_nom", sa.BigInteger(), primary_key=True,
                      comment="Référence nomenclature"),
            sa.Column("modele", sa.String(30), nullable=True,
                      comment="Modèle retenu : croston | holt_winters | ols | moyenne_mobile"),
            sa.Column("prevision_30j", sa.Numeric(12, 2), nullable=True,
                      comment="Prévision cumulée sur 30 jours"),
            sa.Column("prevision_90j", sa.Numeric(12, 2), nullable=True,
                      comment="Prévision cumulée sur 90 jours"),
            sa.Column("mape_holdout", sa.Numeric(7, 4), nullable=True,
                      comment="MAPE sur les 30 derniers jours (holdout)"),
            sa.Column("serie_corrigee", JSONB, nullable=True,
                      comment="Série journalière corrigée (censored demand) en JSON"),
            sa.Column("updated_at", sa.DateTime(timezone=True),
                      server_default=sa.text("NOW()"), nullable=False),
        )


def downgrade() -> None:
    op.drop_table("previsions_demande")
    op.drop_table("parametres_stock")
    op.drop_column("fournisseurs", "delai_livraison")
