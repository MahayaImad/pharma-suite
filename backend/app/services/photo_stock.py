"""
Photo du stock de chaque soir, dans `historique_stock_jour` (source `photo`).

Le stock d'EASYPHARM est un champ (`entrees_produits.stock`), lu par la vue
`mv_stock_produits` après chaque passe de l'agent. Le relever chaque soir
donne un historique exact, sans calcul — la base des jours de rupture, de la
rotation et du stock moyen.

Sont relevés les produits non archivés actifs ou en stock (≈ 3 600 lignes par
jour). Une photo prise deux fois le même jour remplace la première.
"""
from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Optional

from loguru import logger
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

# Au-delà, la photo est prise mais signalée : l'agent ne tourne peut-être plus.
FRAICHEUR_MAX = timedelta(hours=6)


async def prendre_photo(db: AsyncSession, jour: date) -> dict:
    donnees_du: Optional[datetime] = (await db.execute(text(
        "SELECT last_sync_at FROM sync_status WHERE table_name = 'mv_stock_produits'"))).scalar()
    r = await db.execute(text("""
        INSERT INTO historique_stock_jour (id_nom, date, stock_eod, updated_at, source)
        SELECT mv.id_nom, :jour, mv.stock_actuel, now(), 'photo'
        FROM mv_stock_produits mv
        JOIN nomenclature n ON n.id = mv.id_nom
        WHERE n.archive = false AND (mv.actif OR mv.stock_actuel <> 0)
        ON CONFLICT (id_nom, date) DO UPDATE SET
            stock_eod = EXCLUDED.stock_eod, updated_at = now(), source = 'photo'
    """), {"jour": jour})
    await db.commit()
    perimee = donnees_du is None or datetime.now(timezone.utc) - donnees_du > FRAICHEUR_MAX
    if perimee:
        logger.warning(f"[Photo stock] {jour} : données du {donnees_du} — l'agent a-t-il tourné aujourd'hui ?")
    logger.info(f"[Photo stock] {jour} : {r.rowcount} produits relevés")
    return {
        "jour": jour.isoformat(),
        "produits": r.rowcount,
        "donnees_du": donnees_du.isoformat() if donnees_du else None,
        "donnees_anciennes": perimee,
    }
