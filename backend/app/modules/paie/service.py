"""Paie du mois : part fixe (règle 7) + part variable (prime de rendement) = brut.

Réservé au titulaire : les salaires sont confidentiels. Le calcul se fait à
chaque lecture ; « Valider » fige un bulletin (nouvelle version à chaque
validation, aucune n'est écrasée).
"""
from __future__ import annotations

import calendar
from datetime import date
from decimal import Decimal
from typing import Optional

from app.api.v1 import grh_presence
from app.modules.paie.repository import PaieRepository
from app.services.paie import part_fixe
from app.services.paie.part_fixe import CENTIME


class ErreurPaie(Exception):
    def __init__(self, code: str, message: str, statut: int = 400):
        self.code, self.message, self.statut = code, message, statut


LIBELLES = {
    "salaire_base": "Salaire de base",
    "anciennete": "Prime d'ancienneté",
    "transport": "Prime de transport",
    "panier": "Prime de panier",
    "heures_sup": "Heures supplémentaires",
    "retenue_absences": "Retenue pour absence",
    "part_variable": "Prime de rendement",
}


def _criteres(calcul: dict[int, dict], kpis: dict[str, dict]) -> dict[int, list[dict]]:
    """Critères notés de chaque employé (poids > 0 pour son poste), avec son
    indice face à la moyenne de l'équipe : valeur retenue ÷ moyenne × 100
    (100 = moyenne ; la valeur retenue est ramenée aux jours de présence).
    La moyenne se calcule sur tous les employés du calcul."""
    valeurs: dict[str, list[Decimal]] = {}
    for ligne in calcul.values():
        for code, k in (ligne["kpis"] or {}).items():
            if not code.startswith("_") and isinstance(k, dict):
                valeurs.setdefault(code, []).append(Decimal(str(k.get("valeur_retenue") or 0)))
    moyennes = {c: sum(v, Decimal(0)) / len(v) for c, v in valeurs.items() if v}
    resultat: dict[int, list[dict]] = {}
    for e, ligne in calcul.items():
        liste = []
        for code, k in (ligne["kpis"] or {}).items():
            if code.startswith("_") or not isinstance(k, dict) or Decimal(str(k.get("poids") or 0)) <= 0:
                continue
            retenue, moy = Decimal(str(k.get("valeur_retenue") or 0)), moyennes.get(code, Decimal(0))
            liste.append({"code": code, "libelle": (kpis.get(code) or {}).get("libelle", code),
                          "unite": (kpis.get(code) or {}).get("unite"), "valeur": k.get("valeur"),
                          "poids": Decimal(str(k.get("poids"))),
                          "indice": int((retenue / moy * 100).quantize(Decimal(1))) if moy > 0 else None})
        resultat[e] = sorted(liste, key=lambda x: -x["poids"])
    return resultat


class PaieService:
    def __init__(self, repo: PaieRepository, utilisateur: dict):
        self.repo = repo
        self.utilisateur = utilisateur
        self.qui = utilisateur.get("username") or "inconnu"

    def _titulaire(self) -> None:
        if self.utilisateur.get("role") != "admin":
            raise ErreurPaie("interdit", "La paie est réservée au titulaire.", 403)

    @staticmethod
    def _mois(annee: int, mois: int) -> None:
        if not (2000 <= annee <= 2100 and 1 <= mois <= 12):
            raise ErreurPaie("mois", "Mois invalide.", 422)

    async def mois(self, annee: int, mois: int) -> dict:
        self._titulaire()
        self._mois(annee, mois)
        regles = await self.repo.regles()
        employes = await self.repo.employes()
        grille = await grh_presence.grille_presence(self.repo.db, annee, mois)
        jours_de = {e["id"]: [(date.fromisoformat(j), c["statut"]) for j, c in e["jours"].items()]
                    for e in grille["employes"]}
        hs = await self.repo.heures_sup(annee, mois)
        variables = await self.repo.parts_variables(annee, mois)
        bulletins = await self.repo.derniers_bulletins(annee, mois)
        calcul = await self.repo.dernier_calcul_primes(annee, mois)
        criteres_de = _criteres(calcul, await self.repo.kpis())
        fin = date(annee, mois, calendar.monthrange(annee, mois)[1])

        lignes = []
        for e in sorted(employes.values(), key=lambda x: (x["nom"] or "", x["prenom"] or "")):
            if e["date_entree"] and e["date_entree"] > fin:
                continue
            p = part_fixe.calculer(annee, mois, e["salaire_base"] or 0, jours_de.get(e["id"], []),
                                   e["date_entree"], e["date_sortie"],
                                   (hs.get(e["id"]) or {}).get("heures", 0), regles)
            v = variables.get(e["id"])
            pv = Decimal(v["prime_calculee"] or 0).quantize(CENTIME) if v else Decimal(0)
            a_verifier = []
            if not e["poste_code"]:
                a_verifier.append("Poste à renseigner : pas de salaire de base.")
            if e["date_entree"] is None:
                a_verifier.append("Date d'entrée inconnue : pas d'ancienneté.")
            if p.a_confirmer:
                a_verifier.append(f"{p.a_confirmer} jour{'s' if p.a_confirmer > 1 else ''} de présence à confirmer "
                                  "(sans transport ni panier tant qu'ils ne sont pas corrigés).")
            if v is None:
                a_verifier.append("Prime de rendement pas encore calculée pour ce mois.")
            b = bulletins.get(e["id"])
            lignes.append({
                "employe": {"id": e["id"], "nom": e["nom"], "prenom": e["prenom"], "poste_code": e["poste_code"],
                            "poste": e["poste_libelle"] or e["poste"], "date_entree": e["date_entree"],
                            "date_sortie": e["date_sortie"]},
                "jours": {"mois": p.jours_mois, "contrat": p.jours_contrat, "presence": p.presence_effective,
                          "absences": p.absences, "a_confirmer": p.a_confirmer},
                "anciennete_annees": p.annees_anciennete,
                "heures_sup": p.heures_sup,
                "lignes": [{"code": k, "libelle": LIBELLES[k], "montant": m} for k, m in p.lignes.items()],
                "part_fixe": p.total,
                "part_variable": pv,
                "prime": None if e["id"] not in calcul else {
                    "plancher": calcul[e["id"]]["plancher"], "merite": calcul[e["id"]]["merite"],
                    "calculee_le": calcul[e["id"]]["calcule_le"], "enveloppe": calcul[e["id"]]["enveloppe"],
                    "criteres": criteres_de.get(e["id"], []),
                },
                "prime_validee": bool(v and v["valide"]),
                "brut": p.total + pv,
                "a_verifier": a_verifier,
                "bulletin": None if b is None else {"version": b["version"], "brut": b["brut"],
                                                    "valide_le": b["valide_le"], "valide_par": b["valide_par"],
                                                    "a_jour": b["brut"] == p.total + pv},
            })
        enveloppe = next(iter(calcul.values()))["enveloppe"] if calcul else None
        return {
            "annee": annee, "mois": mois, "employes": lignes, "enveloppe": enveloppe,
            "totaux": {"part_fixe": sum((l["part_fixe"] for l in lignes), Decimal(0)),
                       "part_variable": sum((l["part_variable"] for l in lignes), Decimal(0)),
                       "brut": sum((l["brut"] for l in lignes), Decimal(0))},
            "regles": {"transport_jour": regles.transport_jour, "panier_jour": regles.panier_jour,
                       "anciennete_an": regles.anciennete_an, "anciennete_plafond": regles.anciennete_plafond,
                       "majoration_hs": regles.majoration_hs, "heures_mois": regles.heures_mois},
        }

    async def saisir_heures_sup(self, employe_id: int, annee: int, mois: int, heures: Decimal,
                                note: Optional[str]) -> dict:
        self._titulaire()
        self._mois(annee, mois)
        if await self.repo.employe(employe_id) is None:
            raise ErreurPaie("introuvable", "Employé introuvable.", 404)
        await self.repo.saisir_heures_sup(employe_id, annee, mois, part_fixe.arrondi_quart_heure(heures), note,
                                          self.qui)
        await self.repo.commit()
        return {"employe_id": employe_id, "heures": part_fixe.arrondi_quart_heure(heures)}

    async def modifier_employe(self, employe_id: int, valeurs: dict) -> None:
        self._titulaire()
        if await self.repo.employe(employe_id) is None:
            raise ErreurPaie("introuvable", "Employé introuvable.", 404)
        code = valeurs.get("poste_code")
        if code and not await self.repo.poste_existe(code):
            raise ErreurPaie("poste", "Poste inconnu.", 422)
        if valeurs.get("date_entree") and valeurs.get("date_sortie") and valeurs["date_sortie"] < valeurs["date_entree"]:
            raise ErreurPaie("dates", "La date de sortie précède la date d'entrée.", 422)
        await self.repo.modifier_employe(employe_id, valeurs)
        await self.repo.commit()

    async def postes(self) -> list[dict]:
        self._titulaire()
        return await self.repo.postes()

    async def valider(self, annee: int, mois: int) -> dict:
        """Fige le bulletin brut de chaque employé (nouvelle version)."""
        vue = await self.mois(annee, mois)
        versions = {}
        for l in vue["employes"]:
            detail = {"lignes": l["lignes"] + [{"code": "part_variable", "libelle": LIBELLES["part_variable"],
                                                 "montant": l["part_variable"]}],
                      "jours": l["jours"], "anciennete_annees": l["anciennete_annees"],
                      "heures_sup": l["heures_sup"], "poste": l["employe"]["poste"],
                      "prime_validee": l["prime_validee"], "a_verifier": l["a_verifier"], "regles": vue["regles"]}
            versions[l["employe"]["id"]] = await self.repo.enregistrer_bulletin(
                l["employe"]["id"], annee, mois, detail, l["part_fixe"], l["part_variable"], l["brut"], self.qui)
        await self.repo.commit()
        return {"annee": annee, "mois": mois, "bulletins": len(versions), "brut": vue["totaux"]["brut"]}

    async def bulletins(self, employe_id: int, annee: int, mois: int) -> list[dict]:
        self._titulaire()
        return await self.repo.bulletins(employe_id, annee, mois)
