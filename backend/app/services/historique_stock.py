"""
Reconstituer l'historique du stock de tous les produits, par lot.

Méthode retenue (docs/BUSINESS_LOGIC.md §3.4) : chaque lot existe à partir de
sa date d'entrée ; à rebours, stock(veille) = stock(jour) + sorties du jour
(ventes, avoirs fournisseur, échanges vers une autre pharmacie) − ajustements
d'inventaire du jour. Le stock d'un produit est la somme de ses lots. Un
numéro de lot vide regroupe les lots sans numéro du produit.

Le stock de fin de journée de chaque produit actif ou en stock, chaque jour
de [debut] à aujourd'hui, va dans `historique_stock_jour` avec
`source = 'reconstitution'` ; une **photo** du soir (exacte) n'est jamais
remplacée. Un stock reconstitué négatif (impossible : mouvement manquant) est
ramené à 0 et compté dans le rapport.

Toutes les données sont lues en cinq requêtes, puis regroupées en mémoire.
"""
from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass, field
from datetime import date, timedelta
from typing import Optional

from loguru import logger
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.reconstitution_stock import LotHistorique, par_lot

TAILLE_LOT_ECRITURE = 5000

# Une ligne d'inventaire désigne sa ligne de stock par le code-barres, unique
# par lot dans EASYPHARM (id_nom y est vide) : on en tire le produit et le
# numéro de lot ; à défaut de code-barres, id_nom et lot de la ligne.
INVENTAIRE_RESOLU = """
    SELECT ip.date, ip.ecart, ip.motif, ip.prix_achat_ttc,
           COALESCE(e.id_nom, ip.id_nom) AS id_nom,
           COALESCE(e.lot, ip.lot) AS lot
    FROM inventaires_produits ip
    LEFT JOIN LATERAL (
        SELECT id_nom, lot FROM entrees_produits
        WHERE code_barre = ip.code_barre AND NULLIF(trim(ip.code_barre), '') IS NOT NULL
        ORDER BY id DESC LIMIT 1
    ) e ON true
"""


@dataclass
class Rapport:
    debut: date
    fin: date
    produits: int = 0
    jours_ecrits: int = 0
    jours_negatifs: int = 0
    produits_avec_negatif: int = 0
    jours_en_rupture: int = 0
    photos_preservees: int = 0
    erreurs: list[str] = field(default_factory=list)

    def resume(self) -> dict:
        jours = self.produits * ((self.fin - self.debut).days + 1)
        return {
            "debut": self.debut.isoformat(), "fin": self.fin.isoformat(),
            "produits": self.produits, "jours_ecrits": self.jours_ecrits,
            "part_jours_negatifs": round(self.jours_negatifs / jours, 4) if jours else 0,
            "produits_avec_negatif": self.produits_avec_negatif,
            "part_jours_en_rupture": round(self.jours_en_rupture / jours, 4) if jours else 0,
            "photos_preservees": self.photos_preservees,
        }


def _cle(lot: Optional[str]) -> str:
    return (lot or "").strip()


async def reconstituer(
    db: AsyncSession, debut: date, fin: date, ids: Optional[list[int]] = None, ecrire: bool = True,
) -> Rapport:
    filtre_ids = "AND n.id = ANY(:ids)" if ids else ""
    params = {"debut": debut, "fin": fin, "ids": ids}
    produits = [r.id for r in await db.execute(text(f"""
        SELECT n.id FROM nomenclature n JOIN mv_stock_produits mv ON mv.id_nom = n.id
        WHERE n.archive = false AND (mv.actif OR mv.stock_actuel <> 0) {filtre_ids}
    """), params)]
    rapport = Rapport(debut, fin, produits=len(produits))
    if not produits:
        return rapport
    params["ids"] = produits

    # Lots : achats et échanges reçus (pas les avoirs, qui sont des sorties).
    lots: dict[int, dict[str, LotHistorique]] = defaultdict(dict)
    for r in await db.execute(text("""
        SELECT id_nom, COALESCE(trim(lot), '') AS lot, min(date_entree) AS entree, sum(stock) AS stock
        FROM entrees_produits
        WHERE id_nom = ANY(:ids) AND COALESCE(type_entree, '') <> 'AV' AND date_entree IS NOT NULL
        GROUP BY 1, 2
    """), params):
        lots[r.id_nom][r.lot] = LotHistorique(r.entree, float(r.stock or 0))

    def sortie(id_nom: int, lot: str, jour: date, qte) -> None:
        cible = lots[id_nom].get(_cle(lot))
        if cible is not None and qte:
            cible.ajouter_sortie(jour, float(qte))

    # Mouvements après [debut] : seuls ceux-là changent les jours reconstitués.
    for r in await db.execute(text("""
        SELECT id_nom, lot, date, sum(qte_sortie) AS q FROM sorties_produits
        WHERE id_nom = ANY(:ids) AND date > :debut GROUP BY 1, 2, 3"""), params):
        sortie(r.id_nom, r.lot, r.date, r.q)
    for r in await db.execute(text("""
        SELECT id_nom, lot, date_entree AS date, sum(abs(qte_entree)) AS q FROM entrees_produits
        WHERE id_nom = ANY(:ids) AND type_entree = 'AV' AND date_entree > :debut GROUP BY 1, 2, 3"""), params):
        sortie(r.id_nom, r.lot, r.date, r.q)
    for r in await db.execute(text("""
        SELECT id_nom::bigint AS id_nom, lot, date_echange AS date, sum(qte) AS q FROM echanges_sorties_produits
        WHERE id_nom::bigint = ANY(:ids) AND date_echange > :debut GROUP BY 1, 2, 3"""), params):
        sortie(r.id_nom, r.lot, r.date, r.q)
    for r in await db.execute(text(f"""
        SELECT id_nom, lot, date, sum(ecart) AS q FROM ({INVENTAIRE_RESOLU}) ir
        WHERE id_nom = ANY(:ids) AND date > :debut AND ecart <> 0 GROUP BY 1, 2, 3"""), params):
        cible = lots[r.id_nom].get(_cle(r.lot))
        if cible is not None:
            cible.ajouter_ajustement(r.date, float(r.q))

    photos = {(r.id_nom, r.date) for r in await db.execute(text("""
        SELECT id_nom, date FROM historique_stock_jour
        WHERE source = 'photo' AND date BETWEEN :debut AND :fin AND id_nom = ANY(:ids)"""), params)}

    tampon: list[dict] = []

    async def vider() -> None:
        if tampon and ecrire:
            await db.execute(text("""
                INSERT INTO historique_stock_jour (id_nom, date, stock_eod, updated_at, source)
                VALUES (:id_nom, :date, :stock, now(), 'reconstitution')
                ON CONFLICT (id_nom, date) DO UPDATE SET stock_eod = EXCLUDED.stock_eod, updated_at = now(),
                    source = 'reconstitution'
                WHERE historique_stock_jour.source <> 'photo'
            """), tampon)
        rapport.jours_ecrits += len(tampon)
        tampon.clear()

    for id_nom in produits:
        serie = par_lot(list(lots[id_nom].values()), debut, fin)
        negatifs = sum(1 for v in serie.values() if v < -0.5)
        rapport.jours_negatifs += negatifs
        rapport.produits_avec_negatif += 1 if negatifs else 0
        for jour, stock in serie.items():
            stock = max(0.0, stock)
            rapport.jours_en_rupture += 1 if stock <= 0.5 else 0
            if (id_nom, jour) in photos:
                rapport.photos_preservees += 1
                continue
            tampon.append({"id_nom": id_nom, "date": jour, "stock": round(stock, 2)})
        if len(tampon) >= TAILLE_LOT_ECRITURE:
            await vider()
    await vider()
    if ecrire:
        await db.commit()
    logger.info(f"[Historique stock] reconstitution par lot : {rapport.resume()}")
    return rapport
