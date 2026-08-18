"""
Reconstitution du stock réel historique par produit.

Formule de base (on remonte depuis le stock actuel) :

    stock(D) = stock_actuel
             + Σ sorties(D+1 → aujourd'hui)           -- ce qui a quitté le stock APRÈS D
             + Σ echange_sorties(D+1 → aujourd'hui)  -- idem, sorties échange
             - Σ entrées(D+1 → aujourd'hui)            -- ce qui est entré APRÈS D
             - Σ ajustements_inventaire(D+1 → auj.)   -- ecart (peut être négatif)

Implémenté via window functions SQL (O(n) par produit).

Sources de mouvements :
    +  sorties_produits.qte_sortie         WHERE type_sortie = 'V'
    +  echange_sorties_produits.qte        (sorties de type échange)
    -  entrees_produits.qte_entree         WHERE type_entree NOT IN ('AV')
    +/-  inventaires_produits.ecart        (ajustement validé, ecart = reel - theorique)
         → si ecart > 0 : gain de stock (on avait plus que prévu)
         → si ecart < 0 : perte de stock (vol, casse, péremption)
         Dans la reconstitution, un ecart positif après D signifie que le stock
         avant D était plus bas qu'on ne croit → on soustrait l'ecart.
         Donc ecart entre D et now : contribution = -ecart (logique inversée)
"""

from __future__ import annotations

import logging
from typing import Any

logger = logging.getLogger(__name__)

# SQL de reconstitution pour UN produit donné
# Retourne (date, stock_eod) pour tous les jours avec mouvement
RECONSTITUTION_SQL = """
WITH mouvements AS (

    -- Ventes
    SELECT
        sp.date                      AS d,
        SUM(sp.qte_sortie)           AS delta   -- sortie = +delta (remonte le stock vers le passé)
    FROM sorties_produits sp
    WHERE sp.id_nom = :id_nom
      AND sp.type_sortie = 'V'
      AND sp.date >= :date_debut
    GROUP BY sp.date

    UNION ALL

    -- Sorties échange / rechange
    SELECT
        rsp.date_echange             AS d,
        SUM(rsp.qte)                 AS delta
    FROM echanges_sorties_produits rsp
    WHERE rsp.id_nom = :id_nom
      AND rsp.date_echange >= :date_debut
    GROUP BY rsp.date_echange

    UNION ALL

    -- Achats (entrent dans le stock → diminuent le stock passé)
    SELECT
        ep.date_entree               AS d,
        -SUM(ep.qte_entree)          AS delta
    FROM entrees_produits ep
    WHERE ep.id_nom = :id_nom
      AND ep.type_entree NOT IN ('AV')
      AND ep.date_entree >= :date_debut
    GROUP BY ep.date_entree

    UNION ALL

    -- Ajustements inventaire validés
    -- ecart = stock_reel - stock_theorique
    -- Dans la reconstitution vers le passé : on inverse le signe
    SELECT
        ip.date                      AS d,
        -SUM(ip.ecart)               AS delta
    FROM inventaires_produits ip
    JOIN inventaires inv ON inv.id = ip.id_inventaire AND inv.etat = 1
    WHERE ip.id_nom = :id_nom
      AND ip.date >= :date_debut
    GROUP BY ip.date

),
par_jour AS (
    SELECT d, SUM(delta) AS delta_jour
    FROM mouvements
    GROUP BY d
),
avec_cumul AS (
    SELECT
        d,
        delta_jour,
        -- Cumul des mouvements APRÈS ce jour (ordre décroissant)
        -- = ce qui s'est passé entre ce jour et aujourd'hui
        SUM(delta_jour) OVER (
            ORDER BY d DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS cumul_apres
    FROM par_jour
)
SELECT
    d                                                           AS date,
    :stock_actuel + COALESCE(cumul_apres, 0)                    AS stock_eod
FROM avec_cumul
ORDER BY d
"""


async def reconstituer_stock_produit(
    db: Any,          # AsyncSession
    id_nom: int,
    stock_actuel: float,
    date_debut: str,  # 'YYYY-MM-DD'
) -> list[dict]:
    """
    Retourne la liste [{date, stock_eod}, ...] pour un produit.
    stock_eod est le stock estimé en fin de journée.
    """
    from sqlalchemy import text
    from datetime import date as date_type

    # asyncpg exige un objet date, pas une string
    if isinstance(date_debut, str):
        date_debut_obj = date_type.fromisoformat(date_debut)
    else:
        date_debut_obj = date_debut

    rows = (await db.execute(text(RECONSTITUTION_SQL), {
        "id_nom":       id_nom,
        "stock_actuel": stock_actuel,
        "date_debut":   date_debut_obj,
    })).fetchall()

    return [
        {"date": r.date, "stock_eod": float(r.stock_eod)}
        for r in rows
    ]


async def reconstituer_et_sauvegarder(
    db: Any,
    id_nom: int,
    stock_actuel: float,
    date_debut: str,
) -> int:
    """
    Calcule et sauvegarde dans historique_stock_jour.
    Retourne le nombre de jours écrits.
    """
    from sqlalchemy import text

    lignes = await reconstituer_stock_produit(db, id_nom, stock_actuel, date_debut)
    if not lignes:
        return 0

    upsert_sql = text("""
        INSERT INTO historique_stock_jour (id_nom, date, stock_eod, updated_at)
        VALUES (:id_nom, :date, :stock_eod, NOW())
        ON CONFLICT (id_nom, date) DO UPDATE SET
            stock_eod  = EXCLUDED.stock_eod,
            updated_at = NOW()
    """)

    for ligne in lignes:
        await db.execute(upsert_sql, {
            "id_nom":    id_nom,
            "date":      ligne["date"],
            "stock_eod": ligne["stock_eod"],
        })

    return len(lignes)
