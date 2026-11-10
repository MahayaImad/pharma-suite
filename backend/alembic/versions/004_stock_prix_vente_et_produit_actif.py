"""vue du stock : prix de vente pris sur les lots, et produit actif

Constats du rapport du 2026-11-10 sur la base réelle :

- `nomenclature.prix_vente` vaut 0 pour tous les produits : EASYPHARM tient
  le prix sur chaque lot (`entrees_produits.prix_vente`). Toutes les listes
  affichaient donc un prix nul, et les valeurs de stock au prix de vente
  aussi.
- 6 780 produits sur 9 184 sont à stock nul, pour l'essentiel des références
  du catalogue jamais ou plus vendues : « rupture » n'a de sens que pour un
  **produit actif**.

La vue `mv_stock_produits` garde ses quatre colonnes et en gagne six :

    prix_vente      prix du lot de référence : le plus récent ayant du stock,
                    à défaut le plus récent tout court (hors avoirs 'AV')
    valeur_achat    Σ stock du lot × prix d'achat du lot
    valeur_vente    Σ stock du lot × prix de vente du lot
    derniere_vente  date de la dernière vente (quantité positive)
    qte_vendue_12m  quantité nette vendue sur 12 mois (retours déduits :
                    leur qte_sortie est négative)
    actif           non archivé ET (en stock OU vendu dans les 12 mois)

« 12 mois » se compte à la date du recalcul de la vue, c'est-à-dire après
chaque passe de synchronisation.

La vue est recréée **calculée** (la baseline la créait vide, ce qui faisait
échouer toute lecture jusqu'au premier recalcul).

Revision ID: 004
Revises: 003
Create Date: 2026-11-10
"""
from alembic import op

revision = "004"
down_revision = "003"
branch_labels = None
depends_on = None

_VUE = """
CREATE MATERIALIZED VIEW mv_stock_produits AS
WITH lots AS (
    SELECT id_nom,
           sum(stock)                        AS stock_actuel,
           sum(qte_entree)                   AS qte_entree_totale,
           sum(stock::numeric * prix_achat)  AS valeur_achat,
           sum(stock::numeric * prix_vente)  AS valeur_vente
    FROM entrees_produits
    WHERE stock > 0
    GROUP BY id_nom
),
lot_reference AS (
    SELECT DISTINCT ON (id_nom) id_nom, prix_vente
    FROM entrees_produits
    WHERE prix_vente > 0
      AND COALESCE(type_entree, '') <> 'AV'
    ORDER BY id_nom, (stock > 0) DESC, id DESC
),
ventes AS (
    SELECT id_nom,
           max(date) FILTER (WHERE qte_sortie > 0) AS derniere_vente,
           COALESCE(sum(qte_sortie) FILTER (
               WHERE date >= CURRENT_DATE - INTERVAL '12 months'), 0) AS qte_vendue_12m
    FROM sorties_produits
    GROUP BY id_nom
)
SELECT n.id                                                   AS id_nom,
       COALESCE(l.stock_actuel, 0)::bigint                    AS stock_actuel,
       COALESCE(l.qte_entree_totale, 0)::bigint               AS qte_entree_totale,
       COALESCE(l.valeur_achat / NULLIF(l.stock_actuel, 0), 0)::numeric(15,4)
                                                              AS prix_moyen_pondere,
       COALESCE(r.prix_vente, 0)::numeric(15,4)               AS prix_vente,
       COALESCE(l.valeur_achat, 0)::numeric(18,4)             AS valeur_achat,
       COALESCE(l.valeur_vente, 0)::numeric(18,4)             AS valeur_vente,
       v.derniere_vente,
       COALESCE(v.qte_vendue_12m, 0)::bigint                  AS qte_vendue_12m,
       (NOT n.archive AND (
            COALESCE(l.stock_actuel, 0) > 0
            OR COALESCE(v.derniere_vente >= CURRENT_DATE - INTERVAL '12 months', false)
       ))                                                     AS actif
FROM nomenclature n
LEFT JOIN lots l          ON l.id_nom = n.id
LEFT JOIN lot_reference r ON r.id_nom = n.id
LEFT JOIN ventes v        ON v.id_nom = n.id
"""

_VUE_D_ORIGINE = """
CREATE MATERIALIZED VIEW mv_stock_produits AS
SELECT n.id AS id_nom,
       (COALESCE(sum(ep.stock), 0::numeric))::bigint AS stock_actuel,
       (COALESCE(sum(ep.qte_entree), 0::numeric))::bigint AS qte_entree_totale,
       (COALESCE(sum(ep.stock::numeric * ep.prix_achat) / NULLIF(sum(ep.stock), 0::numeric),
                 0::numeric))::numeric(15,4) AS prix_moyen_pondere
FROM nomenclature n
LEFT JOIN entrees_produits ep ON ep.id_nom = n.id AND ep.stock > 0
GROUP BY n.id
"""

_INDEX = "CREATE UNIQUE INDEX uix_mv_stock_produits_id_nom ON mv_stock_produits (id_nom)"


def upgrade() -> None:
    op.execute("DROP MATERIALIZED VIEW IF EXISTS mv_stock_produits")
    op.execute(_VUE + " WITH DATA")
    op.execute(_INDEX)
    # Sert au recalcul : dernière vente et ventes sur 12 mois par produit.
    op.execute("CREATE INDEX IF NOT EXISTS ix_sorties_produits_id_nom_date "
               "ON sorties_produits (id_nom, date)")


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_sorties_produits_id_nom_date")
    op.execute("DROP MATERIALIZED VIEW IF EXISTS mv_stock_produits")
    op.execute(_VUE_D_ORIGINE + " WITH DATA")
    op.execute(_INDEX)
