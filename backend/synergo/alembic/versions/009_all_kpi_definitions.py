"""Seed complet de kpi_definitions — tous domaines

Revision ID: 009
Revises: 008
Create Date: 2026-03-30
"""
from alembic import op
import sqlalchemy as sa

revision = "009"
down_revision = "008"
branch_labels = None
depends_on = None

# (code, libelle, categorie, unite, description, poids_defaut)
ALL_KPIS = [
    # ── Ventes ─────────────────────────────────────────────────────────────
    ("ca_realise",         "CA réalisé",                  "ventes",        "DA",  "Chiffre d'affaires total hors retours",                         30),
    ("benefice_brut",      "Bénéfice brut",               "ventes",        "DA",  "Somme des bénéfices sur les ventes du mois",                     0),
    ("nb_ventes",          "Nombre de ventes",            "ventes",        "nb",  "Nombre de tickets de vente (hors retours)",                     20),
    ("nb_lignes",          "Nombre de lignes",            "ventes",        "nb",  "Nombre de lignes articles vendues",                              5),
    ("panier_moyen",       "Panier moyen",                "ventes",        "DA",  "CA / nombre de ventes",                                         10),
    ("taux_remise",        "Taux de remise",              "ventes",        "%",   "Remises accordées / CA brut × 100",                              0),
    ("retours_montant",    "Montant retours",             "ventes",        "DA",  "Valeur des avoirs / retours du mois",                            0),
    ("nb_retours",         "Nombre de retours",           "ventes",        "nb",  "Nombre de tickets de retour",                                    0),
    ("ca_comptoir",        "CA comptoir",                 "ventes",        "DA",  "CA hors ventes Chifa (clients 1,2,3)",                           0),
    ("ca_chifa",           "CA Chifa",                    "ventes",        "DA",  "CA Chifa — caisses sociales CNAS/CAAT/CVM",                      0),
    ("ca_complement_alim", "CA Compléments alim.",        "ventes",        "DA",  "CA sur famille complément alimentaire / parapharmacy",          15),
    ("ventes_peremption_3","Ventes péremption < 3 mois",  "ventes",        "nb",  "Boîtes vendues dont péremption dans < 90 jours",                20),
    ("ventes_peremption_6","Ventes péremption < 6 mois",  "ventes",        "nb",  "Boîtes vendues dont péremption dans < 180 jours",                0),
    ("ventes_peremption_9","Ventes péremption < 9 mois",  "ventes",        "nb",  "Boîtes vendues dont péremption dans < 270 jours",                0),

    # ── Recouvrement ───────────────────────────────────────────────────────
    ("creances_total",        "Créances totales",         "recouvrement",  "DA",  "Encours client non soldé (hors Chifa)",                          0),
    ("encaissements_mois",    "Encaissements du mois",    "recouvrement",  "DA",  "Versements clients reçus dans le mois",                          0),
    ("taux_recouvrement",     "Taux de recouvrement",     "recouvrement",  "%",   "Encaissements mois / créances émises mois × 100",                0),
    ("nb_clients_debiteurs",  "Clients débiteurs",        "recouvrement",  "nb",  "Nombre de clients avec solde impayé",                            0),
    ("creances_30j",          "Créances > 30 jours",      "recouvrement",  "DA",  "Encours sur factures de plus de 30 jours",                       0),
    ("creances_90j",          "Créances > 90 jours",      "recouvrement",  "DA",  "Encours sur factures de plus de 90 jours — risque moyen",         0),
    ("creances_180j",         "Créances > 180 jours",     "recouvrement",  "DA",  "Encours sur factures de plus de 180 jours — risque élevé",        0),
    ("remboursements_clients","Remboursements clients",   "recouvrement",  "DA",  "Remboursements effectués aux clients dans le mois",               0),

    # ── Stock ───────────────────────────────────────────────────────────────
    ("valeur_stock",      "Valeur du stock",              "stock",         "DA",  "Stock actuel × prix moyen pondéré",                              0),
    ("nb_ruptures",       "Produits en rupture",          "stock",         "nb",  "Produits avec stock = 0",                                        0),
    ("nb_alertes",        "Produits en alerte",           "stock",         "nb",  "Produits avec stock entre 1 et 5",                               0),
    ("nb_references",     "Références en stock",          "stock",         "nb",  "Produits avec au moins 1 unité en stock",                         0),
    ("nb_peremption_3m",  "Lots péremption < 3 mois",     "stock",         "nb",  "Lots avec péremption dans moins de 90 jours",                     0),
    ("nb_peremption_6m",  "Lots péremption < 6 mois",     "stock",         "nb",  "Lots avec péremption dans moins de 180 jours",                    0),
    ("nb_lots_bloques",   "Lots bloqués",                 "stock",         "nb",  "Lots marqués bloqués avec stock restant",                         0),
    ("valeur_perimes",    "Valeur à risque péremption",   "stock",         "DA",  "Valeur des lots expirant dans < 90 jours",                        0),

    # ── Recouvrement par employé ────────────────────────────────────────────
    ("creances_generees",   "Créances générées",        "recouvrement",  "DA",  "Ventes à crédit laissées impayées par cet employé ce mois",      0),
    ("nb_clients_credit",   "Clients en crédit",        "recouvrement",  "nb",  "Nombre de clients laissés en crédit par cet employé",            0),

    # ── Achats ─────────────────────────────────────────────────────────────
    ("ca_achats",              "CA achats",               "achats",        "DA",  "Total achats TTC du mois",                                       0),
    ("nb_bons_livraison",      "Bons de livraison",       "achats",        "nb",  "Nombre de réceptions du mois",                                    0),
    ("nb_fournisseurs_actifs", "Fournisseurs actifs",     "achats",        "nb",  "Nombre de fournisseurs ayant livré ce mois",                      0),
    ("panier_moyen_achat",     "Panier moyen achat",      "achats",        "DA",  "CA achats / nombre de BL",                                       0),
    ("dettes_fournisseurs",    "Dettes fournisseurs",     "achats",        "DA",  "Encours fournisseurs non réglés du mois",                          0),
    ("paiements_fournisseurs", "Paiements fournisseurs",  "achats",        "DA",  "Versements fournisseurs effectués dans le mois",                  0),
    ("avoirs_fournisseurs",    "Avoirs fournisseurs",     "achats",        "DA",  "Avoirs reçus des fournisseurs dans le mois",                      0),
]


def upgrade():
    conn = op.get_bind()
    for code, libelle, categorie, unite, description, poids in ALL_KPIS:
        conn.execute(sa.text("""
            INSERT INTO kpi_definitions
                (code, libelle, categorie, unite, description, poids, actif)
            VALUES
                (:code, :libelle, :categorie, :unite, :description, :poids, TRUE)
            ON CONFLICT (code) DO UPDATE SET
                libelle     = EXCLUDED.libelle,
                categorie   = EXCLUDED.categorie,
                unite       = EXCLUDED.unite,
                description = EXCLUDED.description
        """), {
            "code": code, "libelle": libelle, "categorie": categorie,
            "unite": unite, "description": description, "poids": poids,
        })


def downgrade():
    # Supprimer uniquement les KPIs ajoutés par cette migration
    codes = [r[0] for r in ALL_KPIS]
    op.get_bind().execute(
        sa.text("DELETE FROM kpi_definitions WHERE code = ANY(:codes)"),
        {"codes": codes},
    )
