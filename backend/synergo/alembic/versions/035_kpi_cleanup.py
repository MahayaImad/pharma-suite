"""KPI cleanup — désactivation des KPIs globaux (stock, achats) et redondants

Revision ID: 035
Revises: 034
Create Date: 2026-04-26
"""
from alembic import op
import sqlalchemy as sa

revision = "035"
down_revision = "034"
branch_labels = None
depends_on = None

# KPIs non attribuables à un employé individuel ou redondants
_DESACTIVER = [
    # Ventes — redondants avec ca_realise ou montant_retours
    "nb_retours",
    "ca_comptoir",
    "ca_chifa",
    # Recouvrement global magasin (non par employé)
    "creances_total",
    "nb_clients_debiteurs",
    "creances_30j",
    "creances_90j",
    "creances_180j",
    "remboursements_clients",
    # Stock — responsabilité magasin entière
    "valeur_stock",
    "nb_ruptures",
    "nb_alertes",
    "nb_references",
    "nb_peremption_3m",
    "nb_peremption_6m",
    "nb_lots_bloques",
    "valeur_perimes",
    # Achats — rôle approvisionnement, pas vendeurs
    "ca_achats",
    "nb_bons_livraison",
    "nb_fournisseurs_actifs",
    "panier_moyen_achat",
    "dettes_fournisseurs",
    "paiements_fournisseurs",
    "avoirs_fournisseurs",
]


def upgrade():
    op.get_bind().execute(
        sa.text("UPDATE kpi_definitions SET actif = FALSE WHERE code = ANY(:codes)"),
        {"codes": _DESACTIVER},
    )


def downgrade():
    op.get_bind().execute(
        sa.text("UPDATE kpi_definitions SET actif = TRUE WHERE code = ANY(:codes)"),
        {"codes": _DESACTIVER},
    )
