"""Inventaire tournant : liste du jour, comptages, écarts à corriger.

PharmaSuite ne modifie jamais le stock d'EASYPHARM. Un comptage garde le
stock d'EASYPHARM au moment où il est saisi ; s'il diffère, l'écart reste
dans « à corriger dans EASYPHARM » jusqu'à ce que quelqu'un le marque
corrigé (après l'avoir reporté là-bas).
"""
from __future__ import annotations

import uuid
from datetime import date
from decimal import Decimal
from typing import Optional

from app.modules.commandes.service import aujourdhui
from app.modules.inventaire.repository import InventaireRepository
from app.modules.inventaire.selection import choisir


class ErreurInventaire(Exception):
    def __init__(self, code: str, message: str, statut: int = 400):
        self.code, self.message, self.statut = code, message, statut


class InventaireService:
    def __init__(self, repo: InventaireRepository, utilisateur: dict):
        self.repo = repo
        self.qui = utilisateur.get("username") or "inconnu"

    async def _preparer(self, jour: date) -> None:
        """Fige la liste du jour à la première lecture."""
        if await self.repo.liste_existe(jour):
            return
        reglages = await self.repo.reglages()
        produits = choisir(await self.repo.candidats(), jour, reglages["par_jour"], reglages)
        await self.repo.ecrire_liste(jour, produits)
        await self.repo.commit()

    async def journee(self) -> dict:
        jour = aujourdhui()
        await self._preparer(jour)
        reglages = await self.repo.reglages()
        comptages = await self.repo.comptages_du_jour(jour)
        comptes = {c["id_nom"] for c in comptages}
        liste = await self.repo.liste(jour)
        a_corriger = await self.repo.a_corriger()
        return {
            "jour": jour,
            "a_compter": [l for l in liste if l["id_nom"] not in comptes],
            "comptes": comptages,
            "progression": {"total": len(liste), "comptes": sum(1 for l in liste if l["id_nom"] in comptes),
                            "ecarts": sum(1 for c in comptages if c["ecart"] != 0)},
            "exactitude": await self.repo.exactitude(jour, reglages["A"]) | {"a_corriger": len(a_corriger)},
            "a_corriger": a_corriger,
        }

    async def compter(self, id_nom: int, stock_compte: int, cause: Optional[str],
                      client_uuid: Optional[uuid.UUID] = None) -> dict:
        """Enregistre le comptage d'un produit (de la liste ou non). Le stock
        théorique est celui d'EASYPHARM à cet instant."""
        if client_uuid is not None:
            deja = await self.repo.par_uuid(client_uuid)
            if deja is not None:
                return await self.repo.comptage(deja)
        produit = await self.repo.produit(id_nom)
        if produit is None:
            raise ErreurInventaire("produit", "Produit inconnu.", 404)
        theorique = int(produit["stock"])
        ecart = stock_compte - theorique
        valeur = (Decimal(produit["prix"] or 0) * ecart).quantize(Decimal("0.01"))
        id_ = await self.repo.enregistrer(aujourdhui(), id_nom, theorique, stock_compte, valeur,
                                          cause if ecart != 0 else None, self.qui, client_uuid)
        await self.repo.commit()
        return await self.repo.comptage(id_)

    async def annuler(self, id_: int) -> None:
        """Annule un comptage du jour (erreur de saisie) : le produit revient dans la liste."""
        c = await self.repo.comptage(id_)
        if c is None:
            raise ErreurInventaire("introuvable", "Comptage introuvable.", 404)
        if c["jour"] != aujourdhui():
            raise ErreurInventaire("ancien", "Seul un comptage du jour peut être annulé.", 409)
        await self.repo.supprimer(id_)
        await self.repo.commit()

    async def corriger(self, id_: int, corrige: bool) -> dict:
        """Marque un écart comme reporté dans EASYPHARM (ou l'inverse)."""
        c = await self.repo.comptage(id_)
        if c is None:
            raise ErreurInventaire("introuvable", "Comptage introuvable.", 404)
        if c["ecart"] == 0:
            raise ErreurInventaire("sans_ecart", "Ce comptage n'a pas d'écart à corriger.", 409)
        await self.repo.marquer_corrige(id_, corrige, self.qui)
        await self.repo.commit()
        return await self.repo.comptage(id_)
