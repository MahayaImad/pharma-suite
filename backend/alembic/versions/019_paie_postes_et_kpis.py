"""paie : postes, poids des KPIs par poste, KPIs ramenés aux jours de présence

Arbitrages du 2026-11-18 (poids par poste, KPIs de volume ramenés aux jours
de présence) et règle 3 du 2026-08-19 (nouveaux KPIs, poids à 100).

- `postes_travail` : code, libellé, salaire de base (règles convenues : pharmacien
  assistant 42 000, caissier 40 000, préparateur 35 000 DA), et
  `vend_au_comptoir` (la table `postes`, elle, est le miroir des postes de
  caisse d'EASYPHARM). Un poste qui ne vend pas n'a pas de présence déduite
  des ventes : ses jours sans vente sont « à confirmer », pas « absent ».
- `employes.poste_code` : rattachement à un poste, deviné d'après le texte
  libre `employes.poste` (à vérifier dans l'application).
- `kpi_poids_poste` : poids de chaque KPI par poste. Sans ligne pour son
  poste, un employé garde les poids globaux de `kpi_definitions.poids`.
- `kpi_definitions.volume` : KPI de quantité (CA, nombre de ventes,
  clients…), ramené aux jours de présence avant le score. Un ratio (panier
  moyen) ne l'est pas.
- Nouveaux KPIs : `taches_completees` (tâches terminées dans les délais),
  `ponctualite` (jours à l'heure), `comptages_inventaire` (produits comptés).
- Recouvrement : `encaissements_mois` (montant encaissé) remplace
  `taux_recouvrement` dans le score. Un pourcentage ne s'additionne pas entre
  employés et fausse le calcul distributif ; le taux reste affiché.

Revision ID: 019
Revises: 018
Create Date: 2026-11-18
"""
import sqlalchemy as sa
from alembic import op

revision = "019"
down_revision = "018"
branch_labels = None
depends_on = None

_POSTES = (
    ("pharmacien_assistant", "Pharmacien assistant", 42000, True, 1),
    ("caissier", "Caissier", 40000, True, 2),
    ("preparateur", "Préparateur", 35000, False, 3),
)

_NOUVEAUX = (
    ("taches_completees", "Tâches terminées dans les délais",
     "Tâches assignées du mois marquées faites au plus tard le jour prévu", "equipe", "nb"),
    ("ponctualite", "Jours à l'heure",
     "Jours de présence sans retard de plus de 45 minutes", "discipline", "nb"),
    ("comptages_inventaire", "Produits comptés (inventaire)",
     "Produits comptés dans l'inventaire tournant ce mois", "stock", "nb"),
)

# Poids globaux (règle 3, recouvrement en montant) et poids des postes au comptoir.
_COMPTOIR = {
    "ca_realise": 20, "taches_completees": 20, "nb_ventes": 12, "ponctualite": 10, "panier_moyen": 7,
    "ca_complement_alim": 7, "ventes_peremption_3": 7, "nouveaux_clients": 7, "clients_recuperes": 7,
    "encaissements_mois": 3,
}
# Le préparateur vend peu : il est noté sur ce qu'il fait.
_PREPARATEUR = {"taches_completees": 40, "ponctualite": 25, "comptages_inventaire": 35}

_VOLUME = ("ca_realise", "nb_ventes", "ca_complement_alim", "ventes_peremption_3", "nouveaux_clients",
           "clients_recuperes", "encaissements_mois", "taches_completees", "ponctualite", "comptages_inventaire",
           "nb_lignes", "benefice_brut")


def upgrade() -> None:
    op.create_table(
        "postes_travail",
        sa.Column("code", sa.String(30), primary_key=True),
        sa.Column("libelle", sa.String(100), nullable=False),
        sa.Column("salaire_base", sa.Numeric(14, 2), nullable=False),
        sa.Column("vend_au_comptoir", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("ordre", sa.Integer, nullable=False, server_default="0"),
        sa.Column("modifie_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("modifie_par", sa.String(100)),
    )
    op.add_column("employes", sa.Column("poste_code", sa.String(30), sa.ForeignKey("postes_travail.code")))
    op.create_table(
        "kpi_poids_poste",
        sa.Column("poste_code", sa.String(30), sa.ForeignKey("postes_travail.code", ondelete="CASCADE"), primary_key=True),
        sa.Column("kpi_code", sa.String(50), primary_key=True),
        sa.Column("poids", sa.Numeric(5, 2), nullable=False),
        sa.CheckConstraint("poids >= 0", name="ck_kpi_poids_poste_poids"),
    )
    op.add_column("kpi_definitions", sa.Column("volume", sa.Boolean, nullable=False, server_default=sa.false()))

    conn = op.get_bind()
    for code, libelle, salaire, comptoir, ordre in _POSTES:
        conn.execute(sa.text(
            "INSERT INTO postes_travail (code, libelle, salaire_base, vend_au_comptoir, ordre) VALUES (:c, :l, :s, :v, :o)"),
            {"c": code, "l": libelle, "s": salaire, "v": comptoir, "o": ordre})
    conn.execute(sa.text("""
        UPDATE employes SET poste_code = CASE
            WHEN poste ILIKE '%pharmacien%' THEN 'pharmacien_assistant'
            WHEN poste ILIKE '%caiss%' OR poste ILIKE '%vend%' THEN 'caissier'
            WHEN poste ILIKE '%pr_par%' THEN 'preparateur'
        END
    """))
    for code, libelle, description, categorie, unite in _NOUVEAUX:
        conn.execute(sa.text("""
            INSERT INTO kpi_definitions (code, libelle, description, categorie, unite, poids, actif)
            VALUES (:c, :l, :d, :cat, :u, 0, true) ON CONFLICT (code) DO NOTHING
        """), {"c": code, "l": libelle, "d": description, "cat": categorie, "u": unite})
    conn.execute(sa.text("UPDATE kpi_definitions SET volume = true WHERE code = ANY(:c)"), {"c": list(_VOLUME)})
    conn.execute(sa.text("UPDATE kpi_definitions SET poids = 0 WHERE poids IS NOT NULL AND code <> ALL(:c)"),
                 {"c": list(_COMPTOIR)})
    for code, poids in _COMPTOIR.items():
        conn.execute(sa.text("UPDATE kpi_definitions SET poids = :p, actif = true WHERE code = :c"),
                     {"p": poids, "c": code})
    for poste, poids_ in (("pharmacien_assistant", _COMPTOIR), ("caissier", _COMPTOIR), ("preparateur", _PREPARATEUR)):
        for code, poids in poids_.items():
            conn.execute(sa.text("INSERT INTO kpi_poids_poste (poste_code, kpi_code, poids) VALUES (:p, :k, :w)"),
                         {"p": poste, "k": code, "w": poids})


def downgrade() -> None:
    op.drop_table("kpi_poids_poste")
    op.drop_column("kpi_definitions", "volume")
    op.drop_column("employes", "poste_code")
    op.drop_table("postes_travail")
    op.execute("DELETE FROM kpi_definitions WHERE code IN ('taches_completees', 'ponctualite', 'comptages_inventaire')")
