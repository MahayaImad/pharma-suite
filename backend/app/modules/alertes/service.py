"""Alertes : ce qui demande une action, du plus urgent au moins urgent.

Rien n'est stocké : la liste est recalculée à chaque lecture à partir du
Stock (`/stock/a-traiter`), du suivi des livraisons, des produits en tension
et des propositions à confirmer. Une alerte disparaît quand sa cause
disparaît. Chaque alerte porte une action (commander, ouvrir un écran,
confirmer une tension).

Niveaux :
    aujourdhui   rupture, rupture sous 2 jours, commande non livrée,
                 lots périmés ou qui périment ce mois, synchronisation en retard
    semaine      produits sous le point de commande, tension à confirmer,
                 lots à 3 mois, stock qui ne sera pas vendu avant péremption
    surveiller   surstock, consommables et gardes à confirmer
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Any, Optional

from app.api.v1 import stock
from app.modules.alertes.repository import AlertesRepository
from app.modules.commandes import service as commandes
from app.modules.commandes.repository import CommandesRepository

AUJOURDHUI, SEMAINE, SURVEILLER = "aujourdhui", "semaine", "surveiller"
RUPTURES_DETAILLEES = 5      # ruptures montrées une par une, les autres regroupées
JOURS_AVANT_RUPTURE = 2      # couverture en jours sous laquelle une rupture est imminente
SYNCHRO_EN_RETARD = timedelta(hours=3)
_MOIS = ("janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre",
         "novembre", "décembre")


def _s(n: int) -> str:
    return "s" if n > 1 else ""


def _da(montant: Any) -> str:
    return f"{int(round(float(montant))):,}".replace(",", " ") + " DA"


def _rythme(cmm: float) -> str:
    """« 9 ventes par jour » ou « 3 ventes par mois » (26 jours ouverts par mois)."""
    par_jour = cmm / 26
    if par_jour >= 1:
        return f"{round(par_jour)} vente{_s(round(par_jour))} par jour"
    return f"{round(cmm)} vente{_s(round(cmm))} par mois" if cmm >= 1 else "ventes rares"


def _nom(brut: Optional[str]) -> str:
    """Nom de grossiste lisible dans une phrase : « MEDI-EST DISTRIBUTION » → « Medi-Est Distribution »."""
    return (brut or "le grossiste").title() if (brut or "").isupper() else (brut or "le grossiste")


def _jm(jour) -> str:
    return f"{jour.day:02d}/{jour.month:02d}"


class AlertesService:
    def __init__(self, db, utilisateur: dict):
        self.db = db
        self.utilisateur = utilisateur
        self.repo = AlertesRepository(db)
        self.commandes = commandes.CommandesService(CommandesRepository(db), utilisateur)

    async def liste(self) -> dict:
        jour = commandes.aujourdhui()
        donnees_du = await self.commandes.repo.donnees_du()
        a_traiter = await stock.a_traiter(limite=50, db=self.db, _=self.utilisateur)
        suivi = await self.commandes.suivi(14)
        tensions = [t for t in await self.commandes.tensions() if not t["confirme"]]
        peremption = await self.repo.peremption(jour)
        a_confirmer = await self.repo.a_confirmer()
        budget = await self.commandes.repo.budget(jour)
        admin = self.utilisateur.get("role") == "admin"
        compte = a_traiter["compteurs"]

        manquants: dict[int, dict] = {}     # produit → sa commande non livrée la plus récente
        attendus: dict[int, dict] = {}
        for c in suivi["commandes"]:
            for l in c["lignes"]:
                if l["etat"] in ("manquante", "partielle"):
                    manquants.setdefault(l["id_nom"], c)
                elif l["etat"] == "attendue":
                    attendus.setdefault(l["id_nom"], c)

        alertes: list[dict] = []

        def ajouter(id_: str, type_: str, niveau: str, icone: str, titre: str, detail: str, action: dict,
                    id_nom: Optional[int] = None, sujet: Optional[str] = None) -> None:
            # `sujet` : nom du produit ou du grossiste, tel qu'EASYPHARM l'écrit ;
            # l'application l'affiche devant le titre, dans sa propre casse.
            alertes.append({"id": id_, "type": type_, "niveau": niveau, "icone": icone, "sujet": sujet,
                            "titre": titre, "detail": detail, "id_nom": id_nom, "action": action})

        # ── Synchronisation ──
        if donnees_du is None or datetime.now(timezone.utc) - donnees_du > SYNCHRO_EN_RETARD:
            ajouter("synchro", "stock", AUJOURDHUI, "synchro", "Synchronisation avec EASYPHARM en retard",
                    "Les chiffres affichés peuvent être anciens : vérifiez l'agent sur le PC de l'officine.",
                    {"sorte": "aucune", "libelle": ""})

        # ── Ruptures et ruptures imminentes ──
        ruptures = [p for p in a_traiter["a_commander"] if p["stock"] <= 0]
        for p in ruptures[:RUPTURES_DETAILLEES]:
            c = manquants.get(p["id"])
            suite = (f"non livré par {_nom(c['fournisseur']['nom'])} le {_jm(c['livraison_prevue'])}" if c
                     else (f"en cours chez {_nom(attendus[p['id']]['fournisseur']['nom'])}" if p["id"] in attendus
                           else "rien en cours"))
            ajouter(f"rupture-{p['id']}", "stock", AUJOURDHUI, "rupture", "en rupture",
                    f"{_rythme(p['cmm'])} · {suite}", {"sorte": "commander", "libelle": "Commander"}, p["id"],
                    p["nom"])
        reste = compte["ruptures"] - min(len(ruptures), RUPTURES_DETAILLEES)
        if reste > 0:
            ajouter("ruptures-autres", "stock", AUJOURDHUI, "rupture",
                    f"{reste} autre{_s(reste)} produit{_s(reste)} en rupture",
                    "produits actifs sans stock", {"sorte": "ouvrir", "libelle": "Voir", "route": "/stock"})
        imminentes = [p for p in a_traiter["a_commander"]
                      if p["stock"] > 0 and p["couverture_jours"] is not None
                      and p["couverture_jours"] <= JOURS_AVANT_RUPTURE and p["id"] not in attendus]
        for p in imminentes[:RUPTURES_DETAILLEES]:
            j = p["couverture_jours"]
            quand = "aujourd'hui" if j <= 0 else ("demain" if j == 1 else f"dans {j} jours")
            ajouter(f"imminente-{p['id']}", "stock", AUJOURDHUI, "rupture", f"en rupture {quand}",
                    f"stock {int(p['stock'])} · {_rythme(p['cmm'])} · rien en cours",
                    {"sorte": "commander", "libelle": "Commander"}, p["id"], p["nom"])

        # ── Livraisons ──
        non_livrees = [c for c in suivi["commandes"] if c["etat"] in ("manquante", "partielle")]
        for c in non_livrees:
            nom, n = c["fournisseur"]["nom"], len(c["lignes"])
            if c["etat"] == "manquante":
                titre = f"rien reçu de la commande du {_jm(c['jour'])}"
            else:
                k = c["compte"]["manquante"] + c["compte"]["partielle"]
                titre = f"{k} produit{_s(k)} non livré{_s(k)} de la commande du {_jm(c['jour'])}"
            ajouter(f"livraison-{c['id']}", "livraison", AUJOURDHUI, "livraison", titre,
                    f"{n} ligne{_s(n)} · {_da(c['montant'] - c['montant_recu'])} non reçus · "
                    f"prévue le {_jm(c['livraison_prevue'])}",
                    {"sorte": "ouvrir", "libelle": "Voir la livraison",
                     "route": f"/commandes/livraisons/commandes/{c['id']}"}, sujet=nom)

        # ── Péremption ──
        if peremption["perimes"]:
            n = peremption["perimes"]
            ajouter("perimes", "peremption", AUJOURDHUI, "peremption",
                    f"{n} lot{_s(n)} périmé{_s(n)} encore en stock",
                    f"{_da(peremption['valeur_perimes'])} · à retirer du rayon",
                    {"sorte": "ouvrir", "libelle": "Voir", "route": "/stock"})
        if peremption["ce_mois"]:
            n = peremption["ce_mois"]
            ajouter("peremption-mois", "peremption", AUJOURDHUI, "peremption",
                    f"{n} lot{_s(n)} périme{'nt' if n > 1 else ''} fin {_MOIS[jour.month - 1]}",
                    f"{_da(peremption['valeur_ce_mois'])} · retour, échange ou mise en avant",
                    {"sorte": "ouvrir", "libelle": "Voir", "route": "/stock"})
        for p in a_traiter["a_risque"][:3]:
            q = int(p["qte_a_risque"])
            ajouter(f"risque-{p['id']}", "peremption", SEMAINE, "peremption",
                    f"{q} boîte{_s(q)} ne ser{'ont' if q > 1 else 'a'} pas vendue{_s(q)} à temps",
                    f"{_da(p['valeur_a_risque'])} à risque · stock {int(p['stock'])} · {_rythme(p['cmm'])}",
                    {"sorte": "ouvrir", "libelle": "Voir les lots", "route": f"/stock/{p['id']}"}, p["id"], p["nom"])
        if peremption["trois_mois"]:
            n = peremption["trois_mois"]
            ajouter("peremption-3-mois", "peremption", SEMAINE, "peremption",
                    f"{n} lot{_s(n)} périme{'nt' if n > 1 else ''} dans 3 mois",
                    f"{_da(peremption['valeur_trois_mois'])} · retour, échange ou mise en avant",
                    {"sorte": "ouvrir", "libelle": "Voir", "route": "/stock"})

        # ── À commander ce soir ──
        if compte["sous_seuil"]:
            n = compte["sous_seuil"]
            ajouter("sous-seuil", "stock", SEMAINE, "seuil",
                    f"{n} produit{_s(n)} sous le point de commande",
                    "proposés dans les paniers de ce soir" if a_traiter["aligne_commandes"]
                    else "sous le seuil d'alerte d'EASYPHARM",
                    {"sorte": "ouvrir", "libelle": "Ouvrir les commandes", "route": "/commandes"})

        # ── À confirmer ──
        for t in tensions[:RUPTURES_DETAILLEES]:
            ajouter(f"tension-{t['id_nom']}", "confirmer", SEMAINE, "tension", "en tension ?",
                    t["motif"] or "détecté automatiquement",
                    {"sorte": "tension", "libelle": "Confirmer"} if admin
                    else {"sorte": "ouvrir", "libelle": "Voir", "route": f"/stock/{t['id_nom']}"}, t["id_nom"], t["nom"])
        if len(tensions) > RUPTURES_DETAILLEES:
            n = len(tensions) - RUPTURES_DETAILLEES
            ajouter("tensions-autres", "confirmer", SEMAINE, "tension",
                    f"{n} autre{_s(n)} produit{_s(n)} en tension à confirmer", "détectés automatiquement",
                    {"sorte": "ouvrir", "libelle": "Décider", "route": "/preferences/tensions"})
        if a_confirmer["consommables"]:
            n = a_confirmer["consommables"]
            ajouter("consommables", "confirmer", SURVEILLER, "confirmer", f"{n} consommable{_s(n)} à confirmer",
                    "proposés d'après leurs sorties sans vente",
                    {"sorte": "ouvrir", "libelle": "Décider", "route": "/preferences/consommables"})
        if a_confirmer["gardes"]:
            n = a_confirmer["gardes"]
            ajouter("gardes", "confirmer", SURVEILLER, "confirmer", f"{n} garde{_s(n)} détectée{_s(n)} à confirmer",
                    "repérées d'après les heures de vente",
                    {"sorte": "ouvrir", "libelle": "Décider", "route": "/preferences/reglages"})

        # ── Stock qui dort ──
        if compte["surstock"]:
            n = compte["surstock"]
            ajouter("surstock", "stock", SURVEILLER, "surstock", f"{n} produit{_s(n)} en surstock",
                    f"{_da(compte['valeur_surstock'])} immobilisés au-dessus du maximum",
                    {"sorte": "ouvrir", "libelle": "Voir", "route": "/stock"})

        ordre = {AUJOURDHUI: 0, SEMAINE: 1, SURVEILLER: 2}
        alertes.sort(key=lambda a: ordre[a["niveau"]])   # tri stable : l'ordre d'ajout est gardé
        depense = budget["recu"] + budget["engage"]
        return {
            "jour": jour, "donnees_du": donnees_du, "peut_decider": admin, "alertes": alertes,
            "bref": {
                "ruptures": compte["ruptures"],
                "ruptures_imminentes": len(imminentes),
                "valeur_a_risque": compte["valeur_a_risque"],
                "commandes_non_livrees": len(non_livrees),
                "budget_pct": round(100 * depense / budget["budget"]) if budget["budget"] else None,
            },
        }
