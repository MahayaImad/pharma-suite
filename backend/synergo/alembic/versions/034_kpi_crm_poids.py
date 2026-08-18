"""KPI CRM — nouveaux_clients + clients_recuperes, révision des poids, désactivation KPIs redondants

Revision ID: 034
Revises: 033
Create Date: 2026-04-26
"""
from alembic import op
import sqlalchemy as sa

revision = "034"
down_revision = "033"
branch_labels = None
depends_on = None

# Nouveaux KPIs CRM à insérer
_NEW_KPIS = [
    ("nouveaux_clients",  "Nouveaux clients",    "crm", "nb", "Clients dont c'est la première visite ce mois (jamais achetés avant)", 10),
    ("clients_recuperes", "Clients récupérés",   "crm", "nb", "Clients absents >180 jours qui reviennent ce mois",                   10),
]

# Nouveaux poids pour les KPIs existants (total avec CRM = 100)
_POIDS_UPDATE = {
    "ca_realise":          25,
    "nb_ventes":           15,
    "panier_moyen":        10,
    "ca_complement_alim":  10,
    "ventes_peremption_3": 10,
    "taux_recouvrement":    5,
}

# KPIs redondants à désactiver (actif=false) — ne disparaissent pas de l'historique
_DESACTIVER = [
    "nb_lignes",
    "ventes_peremption_6",
    "ventes_peremption_9",
    "montant_instances_30j",
    "encaissements_mois",
    "nb_clients_credit",
    "montant_creances_impayees_30j",
]


def upgrade():
    conn = op.get_bind()

    # 1. Insérer les KPIs CRM
    for code, libelle, categorie, unite, description, poids in _NEW_KPIS:
        conn.execute(sa.text("""
            INSERT INTO kpi_definitions (code, libelle, categorie, unite, description, poids, actif)
            VALUES (:code, :libelle, :categorie, :unite, :description, :poids, TRUE)
            ON CONFLICT (code) DO UPDATE SET
                poids  = EXCLUDED.poids,
                actif  = TRUE
        """), {"code": code, "libelle": libelle, "categorie": categorie,
               "unite": unite, "description": description, "poids": poids})

    # 2. Mettre à jour les poids des KPIs existants
    for code, poids in _POIDS_UPDATE.items():
        conn.execute(sa.text(
            "UPDATE kpi_definitions SET poids = :poids WHERE code = :code"
        ), {"code": code, "poids": poids})

    # 3. Désactiver les KPIs redondants
    conn.execute(sa.text(
        "UPDATE kpi_definitions SET actif = FALSE WHERE code = ANY(:codes)"
    ), {"codes": _DESACTIVER})


def downgrade():
    conn = op.get_bind()

    # Supprimer les KPIs CRM ajoutés
    conn.execute(sa.text(
        "DELETE FROM kpi_definitions WHERE code IN ('nouveaux_clients', 'clients_recuperes')"
    ))

    # Réactiver les KPIs désactivés
    conn.execute(sa.text(
        "UPDATE kpi_definitions SET actif = TRUE WHERE code = ANY(:codes)"
    ), {"codes": _DESACTIVER})

    # Remettre les poids d'origine (migration 008/009)
    original = {
        "ca_realise": 30, "nb_ventes": 20, "panier_moyen": 10,
        "ca_complement_alim": 15, "ventes_peremption_3": 20, "taux_recouvrement": 0,
    }
    for code, poids in original.items():
        conn.execute(sa.text(
            "UPDATE kpi_definitions SET poids = :poids WHERE code = :code"
        ), {"code": code, "poids": poids})
