"""Catégories de prime : accès base (SQL brut, paramètres liés)."""
from __future__ import annotations

from decimal import Decimal
from typing import Optional

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

# Mêmes ventes que l'enveloppe (`performance._BASE_CA_SQL`) : lignes de vente
# du mois, hors type 'A'.
_VENTES_DU_MOIS = """
    FROM sorties_produits sp
    JOIN sorties s ON sp.id_sortie = s.id
    LEFT JOIN nomenclature n ON n.id = sp.id_nom
    WHERE EXTRACT(YEAR FROM s.date) = :annee AND EXTRACT(MONTH FROM s.date) = :mois
      AND s.type != 'A'
"""

# Marge moyenne d'un produit, en % du prix d'achat : lots en stock pondérés
# par le stock ; sans lot en stock, lots reçus depuis un an pondérés par la
# quantité reçue.
_MARGES = """
    marges AS (
        SELECT ep.id_nom,
               COALESCE(
                 SUM(ep.stock * (ep.prix_vente - ep.prix_achat) / ep.prix_achat) FILTER (WHERE ep.stock > 0)
                   / NULLIF(SUM(ep.stock) FILTER (WHERE ep.stock > 0), 0),
                 SUM(ep.qte_entree * (ep.prix_vente - ep.prix_achat) / ep.prix_achat)
                   FILTER (WHERE ep.date_entree >= CURRENT_DATE - 365)
                   / NULLIF(SUM(ep.qte_entree) FILTER (WHERE ep.date_entree >= CURRENT_DATE - 365), 0)
               ) * 100 AS marge
        FROM entrees_produits ep
        WHERE ep.prix_achat > 0 AND ep.prix_vente IS NOT NULL
        GROUP BY ep.id_nom
    )
"""


class CategoriesRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def commit(self) -> None:
        await self.db.commit()

    async def taux(self) -> dict[str, Decimal]:
        """Taux actifs des trois catégories (`prime_taux_config`), en %."""
        r = await self.db.execute(text(
            "SELECT filtre_famille, taux_pct FROM prime_taux_config WHERE actif AND filtre_famille LIKE 'gentype:%'"))
        cle = {"gentype:princeps": "princeps", "gentype:generique": "generique", "gentype:generique_remb": "generique++"}
        return {cle[x.filtre_famille]: Decimal(x.taux_pct) for x in r if x.filtre_famille in cle}

    async def ca_par_categorie(self, annee: int, mois: int) -> list[dict]:
        r = await self.db.execute(text(f"""
            SELECT n.categorie, COALESCE(SUM(sp.qte_sortie * sp.prix_vente), 0) AS ca,
                   COUNT(DISTINCT sp.id_nom) AS produits
            {_VENTES_DU_MOIS}
            GROUP BY n.categorie
        """), {"annee": annee, "mois": mois})
        return [dict(x._mapping) for x in r]

    async def seuil(self) -> Decimal:
        r = await self.db.execute(text(
            "SELECT valeur FROM reglages_stock WHERE cle = 'categories_seuil_generique_plus'"))
        v = r.scalar()
        return Decimal(v) if v is not None else Decimal(50)

    async def ecrire_seuil(self, seuil: Decimal, qui: str) -> None:
        await self.db.execute(text("""
            INSERT INTO reglages_stock (cle, valeur, description, modifie_par)
            VALUES ('categories_seuil_generique_plus', :v,
                    'Prime : marge moyenne des lots (%) au-delà de laquelle un produit est générique++', :q)
            ON CONFLICT (cle) DO UPDATE SET valeur = EXCLUDED.valeur, modifie_par = EXCLUDED.modifie_par,
                                            modifie_le = now()
        """), {"v": seuil, "q": qui})

    async def nb_sans_categorie(self) -> int:
        r = await self.db.execute(text(
            "SELECT COUNT(*) FROM nomenclature WHERE categorie IS NULL AND NOT archive"))
        return int(r.scalar() or 0)

    async def dernier_classement(self) -> Optional[dict]:
        r = await self.db.execute(text("""
            SELECT le, par, seuil_marge, tout_reclasser,
                   nb_princeps + nb_generique + nb_generique_plus AS produits
            FROM categories_classements ORDER BY le DESC, id DESC LIMIT 1
        """))
        x = r.first()
        return dict(x._mapping) if x else None

    async def laboratoires(self, annee: int, mois: int, q: Optional[str], limite: int) -> tuple[list[dict], int]:
        """Laboratoires triés par CA du mois, avec leur nombre de produits actifs."""
        filtre = "AND l.labo ILIKE :q" if q else ""
        params = {"annee": annee, "mois": mois, "limite": limite, "q": f"%{q}%" if q else None}
        r = await self.db.execute(text(f"""
            WITH ventes AS (
                SELECT lower(trim(n.labo)) AS cle, SUM(sp.qte_sortie * sp.prix_vente) AS ca
                {_VENTES_DU_MOIS} AND n.labo IS NOT NULL
                GROUP BY 1
            ), produits AS (
                SELECT lower(trim(labo)) AS cle, COUNT(*) AS nb
                FROM nomenclature WHERE NOT archive AND labo IS NOT NULL GROUP BY 1
            ), labos AS (
                SELECT l.id, trim(l.labo) AS labo, l.is_generique, COALESCE(v.ca, 0) AS ca, COALESCE(p.nb, 0) AS produits
                FROM laboratoires l
                LEFT JOIN ventes v ON v.cle = lower(trim(l.labo))
                LEFT JOIN produits p ON p.cle = lower(trim(l.labo))
                WHERE NULLIF(trim(l.labo), '') IS NOT NULL {filtre}
            )
            SELECT *, COUNT(*) OVER () AS total FROM labos
            ORDER BY ca DESC, produits DESC, labo
            LIMIT :limite
        """), params)
        lignes = [dict(x._mapping) for x in r]
        total = int(lignes[0].pop("total")) if lignes else 0
        for l in lignes[1:]:
            l.pop("total")
        return lignes, total

    async def ca_du_mois(self, annee: int, mois: int) -> Decimal:
        r = await self.db.execute(text(f"SELECT COALESCE(SUM(sp.qte_sortie * sp.prix_vente), 0) {_VENTES_DU_MOIS}"),
                                  {"annee": annee, "mois": mois})
        return Decimal(r.scalar() or 0)

    async def marquer_laboratoire(self, id_: int, generique: bool) -> Optional[str]:
        r = await self.db.execute(text(
            "UPDATE laboratoires SET is_generique = :g WHERE id = :id RETURNING labo"), {"g": generique, "id": id_})
        return r.scalar()

    async def produits_a_classer(self, annee: int, mois: int, limite: int) -> list[dict]:
        """Produits vendus dans le mois sans catégorie, ou classés à la main."""
        r = await self.db.execute(text(f"""
            SELECT n.id, n.nom, NULLIF(trim(n.labo), '') AS labo, n.categorie, n.categorie_manuelle AS manuelle,
                   SUM(sp.qte_sortie * sp.prix_vente) AS ca
            {_VENTES_DU_MOIS} AND (n.categorie IS NULL OR n.categorie_manuelle)
            GROUP BY n.id, n.nom, n.labo, n.categorie, n.categorie_manuelle
            ORDER BY ca DESC, n.nom
            LIMIT :limite
        """), {"annee": annee, "mois": mois, "limite": limite})
        return [dict(x._mapping) for x in r]

    async def choisir(self, id_nom: int, categorie: Optional[str]) -> bool:
        r = await self.db.execute(text("""
            UPDATE nomenclature SET categorie = :c, categorie_manuelle = (CAST(:c AS varchar) IS NOT NULL)
            WHERE id = :id RETURNING id
        """), {"c": categorie, "id": id_nom})
        return r.scalar() is not None

    async def classer(self, seuil: Decimal, tout: bool) -> dict[str, int]:
        """Classe les produits non archivés : générique++ si la marge moyenne
        dépasse `seuil`, générique si le laboratoire est générique, princeps
        sinon. Jamais un produit classé à la main ; sans `tout`, seulement
        ceux qui n'ont pas de catégorie."""
        restriction = "" if tout else "AND n.categorie IS NULL"
        r = await self.db.execute(text(f"""
            WITH {_MARGES},
            labos_generiques AS (
                SELECT DISTINCT lower(trim(labo)) AS cle FROM laboratoires WHERE is_generique AND labo IS NOT NULL
            ),
            maj AS (
                UPDATE nomenclature n SET categorie = CASE
                    WHEN m.marge > :seuil THEN 'generique++'
                    WHEN lg.cle IS NOT NULL THEN 'generique'
                    ELSE 'princeps' END
                FROM nomenclature n2
                LEFT JOIN marges m ON m.id_nom = n2.id
                LEFT JOIN labos_generiques lg ON lg.cle = lower(trim(n2.labo))
                WHERE n2.id = n.id AND NOT n.archive AND NOT n.categorie_manuelle {restriction}
                RETURNING n.categorie
            )
            SELECT categorie, COUNT(*) AS nb FROM maj GROUP BY categorie
        """), {"seuil": seuil})
        return {x.categorie: int(x.nb) for x in r}

    async def tracer_classement(self, qui: str, seuil: Decimal, tout: bool, nb: dict[str, int]) -> None:
        await self.db.execute(text("""
            INSERT INTO categories_classements
                (par, seuil_marge, tout_reclasser, nb_princeps, nb_generique, nb_generique_plus)
            VALUES (:q, :s, :t, :p, :g, :gp)
        """), {"q": qui, "s": seuil, "t": tout, "p": nb.get("princeps", 0), "g": nb.get("generique", 0),
               "gp": nb.get("generique++", 0)})
