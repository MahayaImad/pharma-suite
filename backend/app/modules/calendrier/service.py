"""Règles du calendrier de l'officine.

- Lecture pour tout utilisateur connecté ; écriture réservée aux
  administrateurs (le titulaire).
- Une fête dure au plus 31 jours (Ramadan : 29 ou 30) et ne finit pas avant
  de commencer ; pas deux fois la même fête le même jour.
- Un jour férié n'est saisi qu'une fois.
"""
from __future__ import annotations

from datetime import date, timedelta
from typing import Optional

from app.modules.calendrier import schemas as s
from app.modules.calendrier.repository import CalendrierRepository
from app.modules.calendrier.rotation import GardeConnue, proposer


class ErreurCalendrier(Exception):
    def __init__(self, code: str, message: str, statut: int = 422):
        super().__init__(message)
        self.code, self.message, self.statut = code, message, statut


DUREE_MAX_EVENEMENT = 31


class CalendrierService:
    def __init__(self, repo: CalendrierRepository, utilisateur: dict):
        self.repo = repo
        self.utilisateur = utilisateur

    def _admin(self) -> str:
        if self.utilisateur.get("role") != "admin":
            raise ErreurCalendrier("interdit", "Réglage réservé au titulaire (administrateur).", 403)
        return self.utilisateur.get("username") or "?"

    # Gardes
    async def gardes(self, annee: Optional[int]) -> list[s.Garde]:
        if annee:
            debut, fin = date(annee, 1, 1), date(annee, 12, 31)
        else:  # par défaut : l'année écoulée et les six mois à venir
            aujourdhui = date.today()
            debut, fin = aujourdhui - timedelta(days=365), aujourdhui + timedelta(days=183)
        return [s.Garde(**g) for g in await self.repo.gardes(debut, fin)]

    async def enregistrer_garde(self, jour: date, saisie: s.GardeSaisie) -> s.Garde:
        qui = self._admin()
        return s.Garde(**await self.repo.enregistrer_garde(jour, saisie.type, saisie.note, qui))

    async def proposer_gardes(self, mois: int) -> list[s.Garde]:
        """Ajoute les gardes des [mois] prochains mois d'après la rotation,
        à confirmer."""
        qui = self._admin()
        connues = [GardeConnue(g["date"], g["type"], g["source"], g["annulee"])
                   for g in await self.repo.toutes_les_gardes()]
        propositions = proposer(connues, date.today(), horizon_jours=round(mois * 30.5))
        return [s.Garde(**g) for g in await self.repo.ajouter_propositions(propositions, qui)]

    async def annuler_garde(self, jour: date) -> None:
        """Écarte une garde détectée ou proposée qui n'a pas eu lieu."""
        qui = self._admin()
        if not await self.repo.annuler_garde(jour, qui):
            raise ErreurCalendrier(
                "non_annulable", "Seule une garde détectée ou proposée, pas encore confirmée, s'annule.", 409)

    async def supprimer_garde(self, jour: date) -> None:
        self._admin()
        if not await self.repo.supprimer_garde(jour):
            raise ErreurCalendrier("introuvable", "Aucune garde ce jour-là.", 404)

    # Fêtes
    async def evenements(self) -> list[s.Evenement]:
        return [s.Evenement(**e) for e in await self.repo.evenements()]

    def _verifier_dates(self, saisie: s.EvenementSaisie) -> None:
        if saisie.date_fin < saisie.date_debut:
            raise ErreurCalendrier("dates", "La fin est avant le début.")
        if (saisie.date_fin - saisie.date_debut).days + 1 > DUREE_MAX_EVENEMENT:
            raise ErreurCalendrier("dates", f"Une fête dure au plus {DUREE_MAX_EVENEMENT} jours.")

    async def creer_evenement(self, saisie: s.EvenementSaisie) -> s.Evenement:
        qui = self._admin()
        self._verifier_dates(saisie)
        if await self.repo.evenement_existe(saisie.type, saisie.date_debut):
            raise ErreurCalendrier("doublon", "Cette fête est déjà saisie à cette date.", 409)
        return s.Evenement(**await self.repo.creer_evenement(saisie.type, saisie.date_debut, saisie.date_fin, qui))

    async def modifier_evenement(self, id_: int, saisie: s.EvenementSaisie) -> s.Evenement:
        qui = self._admin()
        self._verifier_dates(saisie)
        if await self.repo.evenement_existe(saisie.type, saisie.date_debut, sauf=id_):
            raise ErreurCalendrier("doublon", "Cette fête est déjà saisie à cette date.", 409)
        ligne = await self.repo.modifier_evenement(id_, saisie.type, saisie.date_debut, saisie.date_fin, qui)
        if ligne is None:
            raise ErreurCalendrier("introuvable", "Fête introuvable.", 404)
        return s.Evenement(**ligne)

    async def supprimer_evenement(self, id_: int) -> None:
        self._admin()
        if not await self.repo.supprimer_evenement(id_):
            raise ErreurCalendrier("introuvable", "Fête introuvable.", 404)

    # Jours fériés
    async def feries(self) -> list[s.Ferie]:
        return [s.Ferie(**f) for f in await self.repo.feries()]

    async def creer_ferie(self, saisie: s.FerieSaisie) -> s.Ferie:
        self._admin()
        if await self.repo.ferie_existe(saisie.date):
            raise ErreurCalendrier("doublon", "Ce jour férié est déjà saisi.", 409)
        return s.Ferie(**await self.repo.creer_ferie(saisie.date, saisie.label.strip()))

    async def supprimer_ferie(self, id_: int) -> None:
        self._admin()
        if not await self.repo.supprimer_ferie(id_):
            raise ErreurCalendrier("introuvable", "Jour férié introuvable.", 404)
