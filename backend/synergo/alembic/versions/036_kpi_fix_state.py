"""KPI — correction des poids et insertion des KPIs manquants

Revision ID: 036
Revises: 035
Create Date: 2026-04-26
"""
from alembic import op
import sqlalchemy as sa

revision = "036"
down_revision = "035"
branch_labels = None
depends_on = None

# KPIs qui doivent exister avec poids > 0 (prime de rendement)
_ACTIFS = [
    ("ca_realise",         "CA réalisé",              "ventes",       "DA", 25),
    ("nb_ventes",          "Nombre de ventes",        "ventes",       "nb", 15),
    ("panier_moyen",       "Panier moyen",            "ventes",       "DA", 10),
    ("ca_complement_alim", "CA Compléments alim.",    "ventes",       "DA", 10),
    ("ventes_peremption_3","Péremption < 3 mois",     "ventes",       "nb", 10),
    ("nouveaux_clients",   "Nouveaux clients",        "crm",          "nb", 10),
    ("clients_recuperes",  "Clients récupérés",       "crm",          "nb", 10),
    ("taux_recouvrement",  "Taux de recouvrement",    "recouvrement", "%",   5),
]

# KPIs disponibles (poids=0) à garder comme réserve — insert si absents
_DISPONIBLES = [
    ("benefice_brut",   "Bénéfice brut",    "ventes",       "DA", "Bénéfice sur les ventes du mois"),
    ("taux_remise",     "Taux de remise",   "ventes",       "%",  "Remises accordées / CA brut × 100"),
    ("retours_montant", "Montant retours",  "ventes",       "DA", "Valeur des avoirs / retours du mois"),
    ("creances_generees","Créances générées","recouvrement","DA", "Ventes à crédit laissées impayées par cet employé"),
]


def upgrade():
    conn = op.get_bind()

    # 1. Upsert des KPIs actifs avec les bons poids
    for code, libelle, categorie, unite, poids in _ACTIFS:
        conn.execute(sa.text("""
            INSERT INTO kpi_definitions (code, libelle, categorie, unite, poids, actif)
            VALUES (:code, :libelle, :categorie, :unite, :poids, TRUE)
            ON CONFLICT (code) DO UPDATE SET
                poids  = EXCLUDED.poids,
                actif  = TRUE
        """), {"code": code, "libelle": libelle, "categorie": categorie,
               "unite": unite, "poids": poids})

    # 2. Insérer les KPIs disponibles s'ils sont absents (sans écraser les poids existants)
    for code, libelle, categorie, unite, description in _DISPONIBLES:
        conn.execute(sa.text("""
            INSERT INTO kpi_definitions (code, libelle, categorie, unite, poids, actif)
            VALUES (:code, :libelle, :categorie, :unite, 0, TRUE)
            ON CONFLICT (code) DO UPDATE SET
                actif = TRUE
        """), {"code": code, "libelle": libelle, "categorie": categorie, "unite": unite})

    # 3. S'assurer que les KPIs désactivés restent désactivés
    _desactiver = [
        "nb_lignes", "ventes_peremption_6", "ventes_peremption_9",
        "montant_instances_30j", "encaissements_mois", "nb_clients_credit",
        "montant_creances_impayees_30j", "nb_retours", "ca_comptoir", "ca_chifa",
        "creances_total", "nb_clients_debiteurs", "creances_30j", "creances_90j",
        "creances_180j", "remboursements_clients", "valeur_stock", "nb_ruptures",
        "nb_alertes", "nb_references", "nb_peremption_3m", "nb_peremption_6m",
        "nb_lots_bloques", "valeur_perimes", "ca_achats", "nb_bons_livraison",
        "nb_fournisseurs_actifs", "panier_moyen_achat", "dettes_fournisseurs",
        "paiements_fournisseurs", "avoirs_fournisseurs",
    ]
    conn.execute(
        sa.text("UPDATE kpi_definitions SET actif = FALSE WHERE code = ANY(:codes)"),
        {"codes": _desactiver},
    )


def downgrade():
    pass  # état avant trop complexe à reconstruire
