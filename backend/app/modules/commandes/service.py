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

import asyncio
import time
from dataclasses import replace
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal
from typing import Any, Optional
from zoneinfo import ZoneInfo

from loguru import logger
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.pool import NullPool

from app.core.config import settings

from app.modules.commandes.repository import CommandesRepository
from app.services import indicateurs_stock as ind
from app.services.prevision.donnees import Donnees, charger
from app.services.prevision import generiques as g
from app.services.prevision.du_jour import appliquer_generiques, proposer_tous
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
# Calcul en cours : les requêtes qui arrivent pendant ce temps l'attendent au
# lieu d'en lancer un second.
_en_cours: dict[tuple, asyncio.Future] = {}


def vider_cache() -> None:
    _cache.clear()


def _charger_dans_un_fil(jour: date) -> Donnees:
    """Charge les données dans un fil à part, avec sa propre connexion : le
    calcul (30 à 60 s sur la base réelle, surtout du calcul Python) ne bloque
    plus le serveur, qui continue de répondre aux autres écrans."""
    async def _charger() -> Donnees:
        moteur = create_async_engine(settings.database_url, poolclass=NullPool)
        try:
            async with AsyncSession(moteur) as db:
                return await charger(db, jour, jours_rejeu=1)
        finally:
            await moteur.dispose()

    return asyncio.run(_charger())


async def donnees_du_calcul(jour: date, donnees_du) -> Donnees:
    """Données du calcul du jour, en cache ; calculées une seule fois même si
    plusieurs écrans les demandent en même temps."""
    cle = (jour, donnees_du)
    if cle in _cache:
        return _cache[cle]
    tache = _en_cours.get(cle)
    if tache is None:
        depart = time.monotonic()

        async def _calculer() -> Donnees:
            try:
                donnees = await asyncio.to_thread(_charger_dans_un_fil, jour)
                _cache.clear()
                _cache[cle] = donnees
                logger.info(f"[commandes] données du calcul chargées en {time.monotonic() - depart:.1f} s "
                            f"({len(donnees.produits)} produits)")
                return donnees
            finally:
                _en_cours.pop(cle, None)

        tache = _en_cours[cle] = asyncio.ensure_future(_calculer())
    return await asyncio.shield(tache)


def _regle_para(decisions: dict[int, Decision], infos: dict[int, dict], fournisseurs: dict[int, dict]
                ) -> dict[int, Decision]:
    """Parapharmacie (arrêté le 2026-11-16) : on ne garde en stock que les
    classes A et B. Un produit de classe C (ou non classé) dont le
    fournisseur principal est parapharmaceutique n'est plus proposé — il se
    commande à la main — sauf s'il est en tension confirmée."""
    resultat = {}
    for i, dec in decisions.items():
        info = infos.get(i, {})
        f = fournisseurs.get(info.get("id_fournisseur"))
        if (f and f.get("type") == "para" and (info.get("segment_abc") or "").upper() not in ("A", "B")
                and not dec.tension and dec.quantite > 0):
            dec = replace(dec, quantite=0, sur_demande=True,
                          motif="Parapharmacie de classe C : gardée en stock seulement en classes A et B")
        resultat[i] = dec
    return resultat


def raison(dec: Decision) -> dict[str, Any]:
    r = {"type": dec.type, "rythme": round(dec.rythme, 3), "jours_couverts": dec.jours_couverts,
         "prevu": round(dec.prevu, 2), "securite": round(dec.securite, 2), "cible": round(dec.cible, 2),
         "stock": dec.stock, "en_cours": dec.en_cours}
    if dec.maxi > 0 or dec.mini > 0:
        r |= {"mini": round(dec.mini, 1), "maxi": round(dec.maxi, 1), "couverture": dec.couverture,
              "ordonnance": dec.ordonnance, "lot": dec.lot, "tension": dec.tension,
              "sur_demande": dec.sur_demande, "motif": dec.motif}
    if dec.groupe:
        r |= {"groupe": dec.groupe, "part": dec.part, "stock_groupe": dec.stock_groupe,
              "maxi_groupe": round(dec.maxi_groupe, 1)}
    return r


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
        return await donnees_du_calcul(jour, await self.repo.donnees_du())

    async def _propositions(self, jour: date) -> tuple[dict[int, Decision], dict[int, dict], dict[int, list[int]]]:
        """Décisions du soir, infos produits, et pour chaque marque gardée les
        marques épuisées dont elle reprend la demande (règle des génériques)."""
        donnees = await self._donnees(jour)
        ids = [p.id for p in donnees.produits]
        infos = await self.repo.produits(ids)
        stocks = {i: float(x["stock"]) for i, x in infos.items()}
        produits, statuts = await asyncio.to_thread(appliquer_generiques, donnees, stocks)
        reprises: dict[int, list[int]] = {}
        for id_nom, st in statuts.items():
            if not st.garde and stocks.get(id_nom, 0) <= 0:
                for k in st.parts:
                    reprises.setdefault(k, []).append(id_nom)
        en_cours = await self.repo.en_cours(jour)
        decisions = await asyncio.to_thread(proposer_tous, replace(donnees, produits=produits), stocks, en_cours,
                                            None, False, statuts)
        return _regle_para(decisions, infos, await self.repo.fournisseurs(jour)), infos, reprises

    async def _statuts_generiques(self, jour: date):
        donnees = await self._donnees(jour)
        infos = await self.repo.produits([p.id for p in donnees.produits])
        stocks = {i: float(x["stock"]) for i, x in infos.items()}
        return donnees, infos, appliquer_generiques(donnees, stocks)[1]

    def _ligne(self, id_nom: int, info: dict, qte: int, qte_proposee: Optional[int],
               prix: Decimal, raison_: Optional[dict]) -> dict:
        return {"id_nom": id_nom, "nom": info.get("nom"), "famille": info.get("famille"),
                "classe_abc": info.get("segment_abc"), "stock": int(info.get("stock") or 0),
                "code_dci": g.normaliser(info.get("de_equiv")),
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
        fournisseurs = await self.repo.fournisseurs(jour)
        commandes = {c["id_fournisseur"]: c for c in await self.repo.commandes_du_jour(jour)}
        lignes_enregistrees: dict[int, list[dict]] = {}
        if commandes:
            for l in await self.repo.lignes([c["id"] for c in commandes.values()]):
                lignes_enregistrees.setdefault(l["id_commande"], []).append(l)

        decisions: dict[int, Decision] = {}
        infos: dict[int, dict] = {}
        reprises: dict[int, list[int]] = {}
        if not vue["ferme"]:
            decisions, infos, reprises = await self._propositions(jour)
        ids_enregistres = [l["id_nom"] for ls in lignes_enregistrees.values() for l in ls]
        manquants = [i for i in ids_enregistres if i not in infos]
        if manquants:
            infos.update(await self.repo.produits(manquants))

        proposes: dict[int, list[dict]] = {}
        for id_nom, dec in decisions.items():
            if dec.quantite <= 0:
                continue
            info = infos.get(id_nom, {})
            r = raison(dec)
            if reprises.get(id_nom):
                r["reprend"] = sorted((infos.get(i, {}).get("nom") or f"Produit {i}") for i in reprises[id_nom])
            ligne = self._ligne(id_nom, info, dec.quantite, dec.quantite, Decimal(info.get("prix_achat") or 0), r)
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
                                "whatsapp": f.get("whatsapp") or f.get("mobile")},
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
            await self._enregistrer(jour, panier)
        await self.repo.commit()
        return await self.journee(jour)

    async def _enregistrer(self, jour: date, panier: dict) -> Optional[int]:
        """Crée le brouillon d'un panier proposé, avec toutes ses lignes."""
        id_c = await self.repo.creer_commande(jour, panier["fournisseur"]["id"], panier["livraison_prevue"], self.qui)
        if id_c is not None:
            for l in panier["lignes"]:
                await self.repo.ecrire_ligne(id_c, l["id_nom"], l["qte"], l["qte_proposee"], l["prix_achat"],
                                             l["raison"], self.qui)
        return id_c

    async def _brouillon(self, jour: date, id_f: int, fournisseurs: dict) -> int:
        """Brouillon du jour d'un fournisseur ; préparé avec son panier proposé
        s'il n'existe pas encore. Refus si la commande est déjà validée."""
        f = fournisseurs.get(id_f)
        if f is None:
            raise ErreurCommandes("introuvable", "Fournisseur inconnu.", 404)
        commande = next((c for c in await self.repo.commandes_du_jour(jour) if c["id_fournisseur"] == id_f), None)
        if commande:
            if commande["statut"] != "brouillon":
                raise ErreurCommandes(
                    "statut", f"La commande du jour chez {f['nom']} est déjà {commande['statut']} : rouvrez-la d'abord.",
                    409)
            return commande["id"]
        panier = next((p for p in (await self.journee(jour))["paniers"] if p["fournisseur"]["id"] == id_f), None)
        id_c = await self._enregistrer(jour, panier) if panier and panier["lignes"] else None
        return id_c or await self.repo.creer_commande(jour, id_f, self._livraison(jour, f), self.qui)

    async def deplacer(self, id_nom: int, de: int, vers: int) -> dict:
        """Change le grossiste d'une ligne : elle quitte le brouillon du jour
        de [de] pour celui de [vers], avec sa quantité et sa raison. Les deux
        paniers sont préparés au besoin."""
        if de == vers:
            raise ErreurCommandes("meme_fournisseur", "C'est déjà ce fournisseur.")
        jour = jour_de_commande()
        fournisseurs = await self.repo.fournisseurs(jour)
        source = await self._brouillon(jour, de, fournisseurs)
        ligne = next((l for l in await self.repo.lignes([source]) if l["id_nom"] == id_nom), None)
        if ligne is None:
            raise ErreurCommandes("introuvable", "Ce produit n'est pas dans ce panier.", 404)
        cible = await self._brouillon(jour, vers, fournisseurs)
        existante = next((l for l in await self.repo.lignes([cible]) if l["id_nom"] == id_nom), None)
        qte = ligne["qte"] + (existante["qte"] if existante else 0)
        await self.repo.ecrire_ligne(cible, id_nom, qte, ligne["qte_proposee"], Decimal(ligne["prix_achat"]),
                                     ligne["raison"], self.qui)
        await self.repo.retirer_ligne(source, id_nom)
        await self.repo.commit()
        return await self.journee(jour)

    async def remplacer(self, id_commande: int, id_nom: int, par: int) -> dict:
        """Change de générique : la ligne passe à une autre marque de même code
        DCI, même quantité, dans le même panier (au dernier prix d'achat de la
        nouvelle marque)."""
        await self._commande(id_commande, ("brouillon",))
        ligne = next((l for l in await self.repo.lignes([id_commande]) if l["id_nom"] == id_nom), None)
        if ligne is None:
            raise ErreurCommandes("introuvable", "Ce produit n'est pas dans ce panier.", 404)
        infos = await self.repo.produits([id_nom, par])
        if par not in infos:
            raise ErreurCommandes("produit", "Produit inconnu.", 404)
        codes = {i: g.normaliser(await self.repo.code_dci(i)) for i in (id_nom, par)}
        if not codes[id_nom] or codes[id_nom] != codes[par]:
            raise ErreurCommandes("dci", "Ce n'est pas un générique de la même DCI.", 409)
        if infos[par].get("psychotrope"):
            raise ErreurCommandes("psychotrope", "Psychotrope : à commander dans EASYPHARM (bon spécial).", 409)
        raison_ = dict(ligne["raison"] or {})
        raison_["remplace"] = infos[id_nom].get("nom")
        existante = next((l for l in await self.repo.lignes([id_commande]) if l["id_nom"] == par), None)
        qte = ligne["qte"] + (existante["qte"] if existante else 0)
        await self.repo.retirer_ligne(id_commande, id_nom)
        await self.repo.ecrire_ligne(id_commande, par, qte, None, Decimal(infos[par].get("prix_achat") or 0), raison_,
                                     self.qui)
        await self.repo.commit()
        return await self.journee(jour_de_commande())

    async def ajouter_produit(self, id_nom: int, qte: Optional[int] = None) -> dict:
        """« Commander » depuis le Stock : ajoute le produit au brouillon du
        jour de son fournisseur principal (créé au besoin). Sans quantité, la
        quantité proposée ce soir, au moins 1 ; un produit déjà dans le
        brouillon garde sa quantité."""
        jour = jour_de_commande()
        info = (await self.repo.produits([id_nom])).get(id_nom)
        if info is None:
            raise ErreurCommandes("produit", "Produit inconnu.", 404)
        if info.get("psychotrope"):
            raise ErreurCommandes("psychotrope", "Psychotrope : à commander dans EASYPHARM (bon spécial).", 409)
        id_f = info.get("id_fournisseur")
        fournisseurs = await self.repo.fournisseurs(jour)
        if id_f is None or id_f not in fournisseurs:
            raise ErreurCommandes("sans_fournisseur", "Aucun achat connu : fournisseur introuvable.", 409)
        f = fournisseurs[id_f]
        commande = next((c for c in await self.repo.commandes_du_jour(jour) if c["id_fournisseur"] == id_f), None)
        if commande and commande["statut"] != "brouillon":
            raise ErreurCommandes(
                "statut", f"La commande du jour chez {f['nom']} est déjà {commande['statut']} : rouvrez-la d'abord.", 409)
        if commande:
            id_c = commande["id"]
        else:
            # Pas encore de brouillon chez ce fournisseur : on prépare d'abord
            # tout son panier proposé, pour ne pas perdre les autres lignes.
            panier = next((p for p in (await self.journee(jour))["paniers"] if p["fournisseur"]["id"] == id_f), None)
            id_c = await self._enregistrer(jour, panier) if panier and panier["lignes"] else None
            if id_c is None:
                id_c = await self.repo.creer_commande(jour, id_f, self._livraison(jour, f), self.qui)
        existante = next((l for l in await self.repo.lignes([id_c]) if l["id_nom"] == id_nom), None)
        if existante and qte is None:
            quantite, proposee, r = existante["qte"], existante["qte_proposee"], existante["raison"]
        else:
            dec = None
            if qte is None:
                decisions, _, _ = await self._propositions(jour)
                dec = decisions.get(id_nom)
            quantite = qte or max(1, dec.quantite if dec else 1)
            proposee = dec.quantite if dec and dec.quantite > 0 else None
            r = raison(dec) if dec and dec.quantite > 0 else None
            await self.repo.ecrire_ligne(id_c, id_nom, quantite, proposee, Decimal(info.get("prix_achat") or 0), r,
                                         self.qui)
        await self.repo.commit()
        return {"id_commande": id_c, "id_fournisseur": id_f, "fournisseur": f["nom"], "qte": quantite,
                "deja_present": existante is not None, "jour": jour}

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
        f = (await self.repo.fournisseurs(aujourdhui())).get(c["id_fournisseur"], {})
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
        """Tous les fournisseurs : actifs d'abord. `auto` : pas encore réglé
        par le titulaire (actif s'il a livré dans les 30 derniers jours)."""
        tous = (await self.repo.fournisseurs(aujourdhui())).values()
        return sorted(
            ({"id": f["id"], "nom": f["nom"], "type": f["type"], "actif": f["actif"], "auto": not f["regle"],
              "whatsapp": f["whatsapp"] or f["mobile"], "telephone": f["telephone"],
              "derniere_commande": f["derniere_commande"], "delai_livraison": f["delai_livraison"]}
             for f in tous),
            key=lambda f: (not f["actif"], (f["nom"] or "").lower()))

    async def regler_fournisseur(self, id_fournisseur: int, type_: str, actif: bool,
                                 whatsapp: Optional[str]) -> None:
        qui = self._admin()
        if id_fournisseur not in await self.repo.fournisseurs(aujourdhui()):
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

    # ── Génériques ──
    async def generiques(self, id_nom: int) -> dict:
        """Groupe DCI d'un produit : mode (toutes les marques ou quelques-unes),
        et pour chaque marque ses ventes sur 12 mois, sa disponibilité, si
        elle est gardée et le choix forcé du titulaire."""
        jour = jour_de_commande()
        donnees, infos, statuts = await self._statuts_generiques(jour)
        produit = next((p for p in donnees.produits if p.id == id_nom), None)
        code = g.normaliser(produit.code_dci) if produit else None
        if not code:
            return {"code": None, "membres": []}
        membres = [p for p in donnees.produits if g.normaliser(p.code_dci) == code]
        n = len(donnees.dates) - 1
        st0 = statuts.get(id_nom)
        mode = st0.mode if st0 else g.mode_du_groupe(code, donnees.classes_chroniques, donnees.modes_forces.get(code))
        return {
            "code": code, "classe": g.classe(code), "mode": mode,
            "mode_force": donnees.modes_forces.get(code),
            "chronique": g.classe(code) in donnees.classes_chroniques,
            "nombre_gardes": donnees.nombre_generiques,
            "membres": sorted(({
                "id_nom": p.id, "nom": infos.get(p.id, {}).get("nom"),
                "stock": int(infos.get(p.id, {}).get("stock") or 0),
                "ventes_12m": float(p.demande[max(0, n - 365):n].sum()),
                "garde": statuts[p.id].garde if p.id in statuts else True,
                "choix": p.choix,
            } for p in membres), key=lambda x: (not x["garde"], -x["ventes_12m"], x["nom"] or "")),
        }

    async def choisir_generique(self, id_nom: int, choix: Optional[str]) -> dict:
        qui = self._admin()
        await self.repo.choix_generique(id_nom, choix, qui)
        await self.repo.commit()
        vider_cache()
        return await self.generiques(id_nom)

    async def mode_groupe(self, id_nom: int, mode: Optional[str]) -> dict:
        qui = self._admin()
        actuel = await self.generiques(id_nom)
        if not actuel["code"]:
            raise ErreurCommandes("sans_dci", "Ce produit n'a pas de code DCI.", 409)
        await self.repo.mode_groupe(actuel["code"], mode, qui)
        await self.repo.commit()
        vider_cache()
        return await self.generiques(id_nom)

    # ── Détail d'un calcul ──
    async def calcul(self, id_nom: int) -> dict:
        """Pourquoi cette quantité : d'où vient le rythme (fenêtre, jours
        ouverts, jours exclus pour rupture, ventes reprises d'un générique),
        à comparer à la moyenne sur 12 mois, et la décision du soir."""
        import numpy as np
        from app.services.prevision import modele as m
        from app.services.prevision.rejeu import censure

        jour_c = jour_de_commande()
        donnees = await self._donnees(jour_c)
        infos = await self.repo.produits([p.id for p in donnees.produits])
        stocks = {i: float(x["stock"]) for i, x in infos.items()}
        produits, statuts = appliquer_generiques(donnees, stocks)
        p = next((x for x in produits if x.id == id_nom), None)
        if p is None:
            raise ErreurCommandes("introuvable", "Produit hors du calcul (archivé, inactif ou consommable).", 404)
        n = len(donnees.dates) - 1
        propre = (p.demande if p.demande_propre is None else p.demande_propre).copy()
        propre[n] = 0.0
        serie = p.serie_prevision(n).copy()
        serie[n] = 0.0
        cens = censure(serie, p.stock_hist)
        cens[n] = True
        ventes_idx = np.flatnonzero(serie[:n] > 0)
        premiere = int(ventes_idx[0]) if ventes_idx.size else None
        classe = m.classer(serie, cens, premiere, n)
        fenetre = m.FENETRE_COURTE if classe.type in ("regulier", "irregulier") else m.FENETRE_LONGUE
        debut = max(0, n - fenetre)
        if classe.type == "nouveau" and premiere is not None:
            debut = max(debut, premiere)
        ouv = donnees.ouvert[debut:n]
        cw = cens[debut:n]
        garde = (~cw) & ouv
        stock_w = p.stock_hist[debut:n]
        an = slice(max(0, n - 365), n)
        jours_ouverts_an = int(donnees.ouvert[an].sum())
        ventes_an = float(propre[an].sum())
        reprises = []
        for h, j in p.reports:
            if n >= j:
                reprises.append(float(h[debut:n][garde].sum()))
        dec = _regle_para(proposer_tous(replace(donnees, produits=produits), stocks, await self.repo.en_cours(jour_c),
                                        generiques=False, statuts=statuts),
                          infos, await self.repo.fournisseurs(jour_c)).get(id_nom)
        grands = sorted(((donnees.dates[debut + i], float(v)) for i, v in enumerate(serie[debut:n]) if v > 0),
                        key=lambda x: -x[1])[:5]
        st = statuts.get(id_nom)
        return {
            "id_nom": id_nom, "nom": infos.get(id_nom, {}).get("nom"), "type": classe.type,
            "jours_vente_12m": classe.jours_vente,
            "fenetre_jours": n - debut, "debut_fenetre": donnees.dates[debut],
            "jours_ouverts": int(ouv.sum()),
            "jours_exclus_rupture": int((cw & ouv).sum()),
            "jours_retenus": int(garde.sum()),
            "jours_stock_nul": int(np.nansum(stock_w <= 0)),
            "jours_sans_historique": int(np.isnan(stock_w).sum()),
            "vendu_fenetre": float(propre[debut:n].sum()),
            "vendu_jours_retenus": float(propre[debut:n][garde].sum()),
            "repris_generiques": round(sum(reprises), 2),
            "rythme": 0.0 if classe.type == "lent" else round(
                m.rythme(serie, cens, donnees.ouvert, n, classe.type, premiere), 3),
            "moyenne_hors_ruptures": round(float(serie[debut:n][garde].mean()) if garde.any() else 0.0, 3),
            "moyenne_brute": round(float(serie[debut:n][ouv].mean()) if ouv.any() else 0.0, 3),
            "ventes_12m": ventes_an,
            "moyenne_12m_jour_ouvert": round(ventes_an / jours_ouverts_an, 3) if jours_ouverts_an else 0.0,
            "cmm": round(ventes_an / 12, 1),
            "plus_grosses_ventes": [{"date": d, "qte": q} for d, q in grands],
            "generique": None if st is None else {"code": st.code, "mode": st.mode, "garde": st.garde},
            "decision": None if dec is None else raison(dec) | {"quantite": dec.quantite},
        }

    # ── Produits en tension ──
    async def tensions(self) -> list[dict]:
        """Détecte puis liste : à confirmer d'abord, puis les décidés."""
        await self.repo.detecter_tensions(aujourdhui())
        await self.repo.commit()
        return await self.repo.tensions()

    async def tension(self, id_nom: int) -> dict:
        return await self.repo.tension(id_nom) or {"id_nom": id_nom, "tension": False, "confirme": False}

    async def regler_tension(self, id_nom: int, tension: bool) -> dict:
        qui = self._admin()
        await self.repo.regler_tension(id_nom, tension, qui)
        await self.repo.commit()
        vider_cache()
        return await self.tension(id_nom)
