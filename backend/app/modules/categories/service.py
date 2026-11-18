"""Catégories de prime (princeps, générique, générique++).

L'enveloppe de prime est Σ (CA du mois de la catégorie × taux). La catégorie
vit dans `nomenclature.categorie`, propre à PharmaSuite : cet écran la
remplit (laboratoires génériques, seuil de marge, choix à la main) et montre
ce que chaque catégorie apporte à l'enveloppe. Un produit sans catégorie
compte au taux princeps. Titulaire seulement.
"""
from __future__ import annotations

from decimal import ROUND_HALF_UP, Decimal
from typing import Optional

from app.api.v1.performance import _calc_enveloppe_prime
from app.modules.categories.repository import CategoriesRepository

CATEGORIES = ("princeps", "generique", "generique++")
_CENTIME = Decimal("0.01")


class ErreurCategories(Exception):
    def __init__(self, code: str, message: str, statut: int = 400):
        self.code, self.message, self.statut = code, message, statut


class CategoriesService:
    def __init__(self, repo: CategoriesRepository, utilisateur: dict):
        self.repo = repo
        self.utilisateur = utilisateur
        self.qui = utilisateur.get("username") or "inconnu"

    def _titulaire(self) -> None:
        if self.utilisateur.get("role") != "admin":
            raise ErreurCategories("interdit", "Les catégories de prime sont réservées au titulaire.", 403)

    @staticmethod
    def _mois(annee: int, mois: int) -> None:
        if not 1 <= mois <= 12 or not 2000 <= annee <= 2100:
            raise ErreurCategories("mois", "Mois invalide.", 422)

    async def mois(self, annee: int, mois: int) -> dict:
        """Enveloppe du mois et sa répartition par catégorie."""
        self._titulaire()
        self._mois(annee, mois)
        taux = await self.repo.taux()
        # Une valeur inconnue (ancienne « promotion »…) compte comme sans catégorie,
        # comme dans l'enveloppe.
        lignes: dict = {}
        for l in await self.repo.ca_par_categorie(annee, mois):
            c = l["categorie"] if l["categorie"] in CATEGORIES else None
            cumul = lignes.setdefault(c, {"ca": Decimal(0), "produits": 0})
            cumul["ca"] += Decimal(l["ca"] or 0)
            cumul["produits"] += int(l["produits"] or 0)
        categories = []
        for c in (*CATEGORIES, None):
            l = lignes.get(c, {})
            t = taux.get(c or "princeps", Decimal(0))
            ca = Decimal(l.get("ca") or 0)
            categories.append({
                "categorie": c, "taux_pct": t, "ca": ca, "produits": int(l.get("produits") or 0),
                "montant": (ca * t / 100).quantize(_CENTIME, rounding=ROUND_HALF_UP),
            })
        return {
            "annee": annee, "mois": mois,
            "enveloppe": await _calc_enveloppe_prime(self.repo.db, annee, mois),
            "ca": await self.repo.ca_du_mois(annee, mois),
            "categories": categories,
            "seuil_marge": await self.repo.seuil(),
            "sans_categorie_total": await self.repo.nb_sans_categorie(),
            "dernier_classement": await self.repo.dernier_classement(),
        }

    async def laboratoires(self, annee: int, mois: int, q: Optional[str], limite: int) -> dict:
        self._titulaire()
        self._mois(annee, mois)
        labos, total = await self.repo.laboratoires(annee, mois, (q or "").strip() or None, max(1, min(limite, 500)))
        ca = await self.repo.ca_du_mois(annee, mois)
        for l in labos:
            l["part_ca"] = float((Decimal(l["ca"]) / ca * 100).quantize(Decimal("0.1"))) if ca else 0.0
        return {"laboratoires": labos, "total": total}

    async def marquer_laboratoire(self, id_: int, generique: bool) -> dict:
        self._titulaire()
        nom = await self.repo.marquer_laboratoire(id_, generique)
        if nom is None:
            raise ErreurCategories("introuvable", "Laboratoire introuvable.", 404)
        await self.repo.commit()
        return {"id": id_, "labo": nom, "is_generique": generique}

    async def produits(self, annee: int, mois: int, limite: int) -> list[dict]:
        self._titulaire()
        self._mois(annee, mois)
        return await self.repo.produits_a_classer(annee, mois, max(1, min(limite, 100)))

    async def choisir(self, id_nom: int, categorie: Optional[str]) -> dict:
        self._titulaire()
        if not await self.repo.choisir(id_nom, categorie):
            raise ErreurCategories("introuvable", "Produit introuvable.", 404)
        await self.repo.commit()
        return {"id": id_nom, "categorie": categorie, "manuelle": categorie is not None}

    async def classer(self, seuil: Decimal, tout: bool) -> dict:
        """Classe les produits (sans catégorie, ou tous avec `tout`) et trace le classement."""
        self._titulaire()
        await self.repo.ecrire_seuil(seuil, self.qui)
        nb = await self.repo.classer(seuil, tout)
        await self.repo.tracer_classement(self.qui, seuil, tout, nb)
        await self.repo.commit()
        return {c: nb.get(c, 0) for c in CATEGORIES} | {"total": sum(nb.values())}
