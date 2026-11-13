"""Règles des commandes fournisseurs.

- La proposition du soir vient de `prevision.du_jour` : la méthode mesurée
  par le rejeu (politique retenue le 2026-11-12), produit par produit.
- Un panier par fournisseur principal (dernier achat hors avoirs et
  échanges), séparé en pharmaceutique et parapharmaceutique selon le type du
  grossiste. Les psychotropes se commandent dans EASYPHARM : ils sont listés
  à part, sans brouillon. Un produit sans fournisseur actif aussi.
- Pas de commande le vendredi (grossistes fermés) : ce jour-là, l'écran
  prépare celle du samedi.
- « Préparer » enregistre la proposition en brouillons, un par fournisseur ;
  tout utilisateur connecté peut préparer et corriger un brouillon.
- Valider : le titulaire (rôle admin) ou un employé désigné. Envoyer : une
  commande validée ; le bon est un texte prêt pour WhatsApp.
- Une commande validée ou envoyée compte « en cours » jusqu'à sa livraison
  prévue : elle n'est pas recommandée le lendemain.
"""
from __future__ import annotations

import time
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal
from typing import Any, Optional
from zoneinfo import ZoneInfo

from loguru import logger

from app.modules.commandes.repository import CommandesRepository
from app.services import indicateurs_stock as ind
from app.services.prevision.donnees import Donnees, charger
from app.services.prevision.du_jour import proposer_tous
from app.services.prevision.proposition import VENDREDI, Decision, jour_de_commande_suivant

ALGER = ZoneInfo("Africa/Algiers")
JOURS = ("lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche")


class ErreurCommandes(Exception):
    def __init__(self, code: str, message: str, statut: int = 422):
        super().__init__(message)
        self.code, self.message, self.statut = code, message, statut


def aujourdhui() -> date:
    return datetime.now(timezone.utc).astimezone(ALGER).date()


def jour_de_commande() -> date:
    """Aujourd'hui ; le vendredi (grossistes fermés), la commande à préparer
    est celle du samedi."""
    j = aujourdhui()
    return jour_de_commande_suivant(j - timedelta(days=1)) if j.weekday() == VENDREDI else j


# Données du calcul (lourdes : ventes depuis 2023), gardées jusqu'au prochain
# rafraîchissement du stock. Une seule entrée : la plus récente.
_cache: dict[tuple, Donnees] = {}


def vider_cache() -> None:
    _cache.clear()


def raison(dec: Decision) -> dict[str, Any]:
    return {"type": dec.type, "rythme": round(dec.rythme, 3), "jours_couverts": dec.jours_couverts,
            "prevu": round(dec.prevu, 2), "securite": round(dec.securite, 2), "cible": round(dec.cible, 2),
            "stock": dec.stock, "en_cours": dec.en_cours}


def _ordre(ligne: dict) -> tuple:
    """Ruptures d'abord, puis classe A, B, C, puis montant décroissant."""
    return (ligne["stock"] > 0, {"A": 0, "B": 1, "C": 2}.get(ligne.get("classe_abc") or "", 3),
            -ligne["montant"], ligne["nom"] or "")


def _total(lignes: list[dict]) -> dict:
    return {"nb_lignes": len(lignes), "boites": sum(l["qte"] for l in lignes),
            "montant": sum((l["montant"] for l in lignes), Decimal(0))}


class CommandesService:
    def __init__(self, repo: CommandesRepository, utilisateur: dict):
        self.repo = repo
        self.utilisateur = utilisateur

    @property
    def qui(self) -> str:
        return self.utilisateur.get("username") or "?"

    def _admin(self) -> str:
        if self.utilisateur.get("role") != "admin":
            raise ErreurCommandes("interdit", "Réglage réservé au titulaire (administrateur).", 403)
        return self.qui

    async def peut_valider(self) -> bool:
        return self.utilisateur.get("role") == "admin" or self.qui in await self.repo.valideurs()

    # ── Calcul ──
    async def _donnees(self, jour: date) -> Donnees:
        cle = (jour, await self.repo.donnees_du())
        if cle not in _cache:
            depart = time.monotonic()
            donnees = await charger(self.repo.db, jour, jours_rejeu=1)
            _cache.clear()
            _cache[cle] = donnees
            logger.info(f"[commandes] données du calcul chargées en {time.monotonic() - depart:.1f} s "
                        f"({len(donnees.produits)} produits)")
        return _cache[cle]

    async def _propositions(self, jour: date) -> tuple[dict[int, Decision], dict[int, dict]]:
        donnees = await self._donnees(jour)
        ids = [p.id for p in donnees.produits]
        infos = await self.repo.produits(ids)
        stocks = {i: float(x["stock"]) for i, x in infos.items()}
        decisions = proposer_tous(donnees, stocks, await self.repo.en_cours(jour))
        return decisions, infos

    def _ligne(self, id_nom: int, info: dict, qte: int, qte_proposee: Optional[int],
               prix: Decimal, raison_: Optional[dict]) -> dict:
        return {"id_nom": id_nom, "nom": info.get("nom"), "famille": info.get("famille"),
                "classe_abc": info.get("segment_abc"), "stock": int(info.get("stock") or 0),
                "qte": qte, "qte_proposee": qte_proposee, "prix_achat": prix,
                "montant": (prix * qte).quantize(Decimal("0.01")), "raison": raison_}

    def _livraison(self, jour: date, fournisseur: Optional[dict], defaut: int = 1) -> date:
        delai = (fournisseur or {}).get("delai_livraison")
        return ind.date_livraison(jour, int(delai) if delai is not None else defaut)

    # ── Vue du jour ──
    async def journee(self, jour: Optional[date] = None) -> dict:
        jour = jour or jour_de_commande()
        budget = await self.repo.budget(jour)
        vue: dict[str, Any] = {
            "jour": jour, "donnees_du": await self.repo.donnees_du(),
            "peut_valider": await self.peut_valider(), "ferme": jour.weekday() == VENDREDI,
            "paniers": [], "psychotropes": [], "sans_fournisseur": [],
        }
        fournisseurs = await self.repo.fournisseurs()
        commandes = {c["id_fournisseur"]: c for c in await self.repo.commandes_du_jour(jour)}
        lignes_enregistrees: dict[int, list[dict]] = {}
        if commandes:
            for l in await self.repo.lignes([c["id"] for c in commandes.values()]):
                lignes_enregistrees.setdefault(l["id_commande"], []).append(l)

        decisions: dict[int, Decision] = {}
        infos: dict[int, dict] = {}
        if not vue["ferme"]:
            decisions, infos = await self._propositions(jour)
        ids_enregistres = [l["id_nom"] for ls in lignes_enregistrees.values() for l in ls]
        manquants = [i for i in ids_enregistres if i not in infos]
        if manquants:
            infos.update(await self.repo.produits(manquants))

        proposes: dict[int, list[dict]] = {}
        for id_nom, dec in decisions.items():
            if dec.quantite <= 0:
                continue
            info = infos.get(id_nom, {})
            ligne = self._ligne(id_nom, info, dec.quantite, dec.quantite,
                                Decimal(info.get("prix_achat") or 0), raison(dec))
            f = fournisseurs.get(info.get("id_fournisseur"))
            ligne["id_fournisseur"] = info.get("id_fournisseur")
            ligne["fournisseur"] = f["nom"] if f else None
            if info.get("psychotrope"):
                vue["psychotropes"].append(ligne)
            elif f is None or not f["actif"]:
                vue["sans_fournisseur"].append(ligne)
            else:
                proposes.setdefault(f["id"], []).append(ligne)

        for id_f in sorted(set(proposes) | set(commandes),
                           key=lambda i: (fournisseurs.get(i, {}).get("nom") or "")):
            f = fournisseurs.get(id_f, {"id": id_f, "nom": None, "type": "pharma", "whatsapp": None,
                                        "delai_livraison": None})
            c = commandes.get(id_f)
            if c:
                lignes = [self._ligne(l["id_nom"], infos.get(l["id_nom"], {}), l["qte"], l["qte_proposee"],
                                      Decimal(l["prix_achat"]), l["raison"])
                          for l in lignes_enregistrees.get(c["id"], [])]
            else:
                lignes = proposes.get(id_f, [])
            lignes.sort(key=_ordre)
            vue["paniers"].append({
                "fournisseur": {"id": id_f, "nom": f.get("nom"), "type": f.get("type", "pharma"),
                                "whatsapp": f.get("whatsapp")},
                "commande": c, "livraison_prevue": c["livraison_prevue"] if c else self._livraison(jour, f),
                "lignes": lignes, **_total(lignes),
            })
        for cle in ("psychotropes", "sans_fournisseur"):
            vue[cle].sort(key=_ordre)
        propose = sum((p["montant"] for p in vue["paniers"] if not p["commande"]), Decimal(0))
        vue["budget"] = {**budget, "propose": propose,
                         "reste": (budget["budget"] - budget["recu"] - budget["engage"]) if budget["budget"] else None}
        return vue

    async def preparer(self, jour: Optional[date] = None) -> dict:
        """Enregistre en brouillons les paniers proposés qui n'ont pas encore
        de commande aujourd'hui."""
        jour = jour or jour_de_commande()
        if jour.weekday() == VENDREDI:
            raise ErreurCommandes("ferme", "Pas de commande le vendredi : les grossistes sont fermés.", 409)
        vue = await self.journee(jour)
        for panier in vue["paniers"]:
            if panier["commande"] or not panier["lignes"]:
                continue
            id_c = await self.repo.creer_commande(jour, panier["fournisseur"]["id"], panier["livraison_prevue"],
                                                  self.qui)
            if id_c is None:
                continue
            for l in panier["lignes"]:
                await self.repo.ecrire_ligne(id_c, l["id_nom"], l["qte"], l["qte_proposee"], l["prix_achat"],
                                             l["raison"], self.qui)
        await self.repo.commit()
        return await self.journee(jour)

    # ── Une commande ──
    async def _commande(self, id_commande: int, statuts: tuple[str, ...]) -> dict:
        c = await self.repo.commande(id_commande)
        if c is None:
            raise ErreurCommandes("introuvable", "Commande introuvable.", 404)
        if c["statut"] not in statuts:
            raise ErreurCommandes("statut", f"Impossible : la commande est « {c['statut']} ».", 409)
        return c

    async def modifier_ligne(self, id_commande: int, id_nom: int, qte: int) -> None:
        """Quantité d'un produit dans un brouillon ; 0 retire la ligne, un
        produit absent est ajouté (ajout manuel, au dernier prix d'achat)."""
        await self._commande(id_commande, ("brouillon",))
        if qte <= 0:
            await self.repo.retirer_ligne(id_commande, id_nom)
        else:
            info = (await self.repo.produits([id_nom])).get(id_nom)
            if info is None:
                raise ErreurCommandes("produit", "Produit inconnu.", 404)
            await self.repo.ecrire_ligne(id_commande, id_nom, qte, None, Decimal(info.get("prix_achat") or 0),
                                         None, self.qui)
        await self.repo.commit()

    async def valider(self, id_commande: int) -> None:
        if not await self.peut_valider():
            raise ErreurCommandes("interdit", "Validation réservée au titulaire et aux employés désignés.", 403)
        await self._commande(id_commande, ("brouillon",))
        if not await self.repo.lignes([id_commande]):
            raise ErreurCommandes("vide", "La commande n'a aucune ligne.")
        await self.repo.changer_statut(id_commande, "brouillon", "validee", self.qui)
        await self.repo.commit()

    async def rouvrir(self, id_commande: int) -> None:
        """Repasse une commande validée (pas encore envoyée) en brouillon."""
        if not await self.peut_valider():
            raise ErreurCommandes("interdit", "Réservé au titulaire et aux employés désignés.", 403)
        await self._commande(id_commande, ("validee",))
        await self.repo.changer_statut(id_commande, "validee", "brouillon", self.qui)
        await self.repo.commit()

    async def envoyer(self, id_commande: int) -> dict:
        """Marque la commande envoyée et rend le bon à coller dans WhatsApp."""
        await self._commande(id_commande, ("validee",))
        bon = await self.bon(id_commande)
        await self.repo.changer_statut(id_commande, "validee", "envoyee", self.qui)
        await self.repo.commit()
        return bon

    async def annuler(self, id_commande: int) -> None:
        c = await self._commande(id_commande, ("brouillon", "validee"))
        if c["statut"] == "validee" and not await self.peut_valider():
            raise ErreurCommandes("interdit", "Réservé au titulaire et aux employés désignés.", 403)
        await self.repo.changer_statut(id_commande, c["statut"], "annulee", self.qui)
        await self.repo.commit()

    async def bon(self, id_commande: int) -> dict:
        """Bon de commande en texte : produit et boîtes, sans prix (le
        grossiste applique les siens)."""
        c = await self._commande(id_commande, ("brouillon", "validee", "envoyee"))
        lignes = await self.repo.lignes([id_commande])
        infos = await self.repo.produits([l["id_nom"] for l in lignes]) if lignes else {}
        f = (await self.repo.fournisseurs()).get(c["id_fournisseur"], {})
        noms = sorted(((infos.get(l["id_nom"], {}).get("nom") or f"Produit {l['id_nom']}"), l["qte"]) for l in lignes)
        j = c["jour"]
        texte = "\n".join(
            [f"Bon de commande du {JOURS[j.weekday()]} {j:%d/%m/%Y}", f"Fournisseur : {f.get('nom') or '?'}", ""]
            + [f"{i}. {nom} — {q}" for i, (nom, q) in enumerate(noms, 1)]
            + ["", f"{len(noms)} produits, {sum(q for _, q in noms)} boîtes. Merci."])
        return {"id_commande": id_commande, "fournisseur": f.get("nom"), "whatsapp": f.get("whatsapp") or f.get("mobile"),
                "texte": texte}

    # ── Réglages ──
    async def fournisseurs(self) -> list[dict]:
        """Fournisseurs réglés ou livrés : type, actif, WhatsApp."""
        return [{"id": f["id"], "nom": f["nom"], "type": f["type"], "actif": f["actif"],
                 "whatsapp": f["whatsapp"] or f["mobile"], "delai_livraison": f["delai_livraison"]}
                for f in (await self.repo.fournisseurs()).values() if f["regle"]]

    async def regler_fournisseur(self, id_fournisseur: int, type_: str, actif: bool,
                                 whatsapp: Optional[str]) -> None:
        qui = self._admin()
        if id_fournisseur not in await self.repo.fournisseurs():
            raise ErreurCommandes("introuvable", "Fournisseur inconnu.", 404)
        await self.repo.regler_fournisseur(id_fournisseur, type_, actif, whatsapp, qui)
        await self.repo.commit()

    async def valideurs(self) -> list[str]:
        return await self.repo.valideurs()

    async def ajouter_valideur(self, username: str) -> None:
        await self.repo.ajouter_valideur(username, self._admin())
        await self.repo.commit()

    async def retirer_valideur(self, username: str) -> None:
        self._admin()
        if not await self.repo.retirer_valideur(username):
            raise ErreurCommandes("introuvable", "Cet employé n'est pas valideur.", 404)
        await self.repo.commit()
