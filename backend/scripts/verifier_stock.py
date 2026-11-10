"""
Vérification du module stock sur les données réelles.

    cd docker
    docker compose build api
    docker compose run --rm api python -m scripts.verifier_stock --rafraichir

Deux parties :

1. **Données** — des requêtes de comptage sur la base : la vue du stock
   est-elle calculée, les formats de péremption, les produits sans segment,
   les lots périmés encore en stock, les lignes orphelines…
2. **Routes** — chaque route GET de `/api/v1/stock` est appelée dans le
   processus (sans réseau, sans mot de passe) ; on note le code de retour, la
   durée et la *forme* de la réponse.

Le rapport ne contient **aucune valeur textuelle** issue des tables (ni nom
de client, ni nom de produit) : seulement des noms de champs, des comptages
et des agrégats numériques. Il peut être partagé.

Le script ne modifie rien, sauf avec `--rafraichir`, qui recalcule la vue
matérialisée `mv_stock_produits` (donnée dérivée, sans risque). Les routes
qui écrivent (segmentation, auto-catégorisation, réimport) ne sont pas
appelées.

Rapport écrit sur la sortie standard et dans `logs/rapport_stock.md`.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import time
from datetime import date
from decimal import Decimal
from pathlib import Path
from typing import Any
from urllib.parse import urlencode

from sqlalchemy import text

from app.core.database import AsyncSessionLocal
from app.core.security import get_current_user
from app.main import app

PREFIXE = "/api/v1/stock"
lignes: list[str] = []


def ecrire(texte: str = "") -> None:
    print(texte)
    lignes.append(texte)


# ── Partie 1 : données ────────────────────────────────────────────────────────

async def sql(requete: str, **params) -> list:
    """Chaque requête a sa session : une colonne absente ne casse pas la suite."""
    async with AsyncSessionLocal() as db:
        return (await db.execute(text(requete), params)).all()


async def verifier(titre: str, requete: str, **params) -> list | None:
    """Exécute un contrôle et l'écrit en tableau ; une erreur est rapportée, pas levée."""
    ecrire(f"\n**{titre}**\n")
    try:
        resultat = await sql(requete, **params)
    except Exception as erreur:
        ecrire(f"- ERREUR : `{str(erreur).splitlines()[0][:200]}`")
        return None
    if not resultat:
        ecrire("- (aucune ligne)")
        return resultat
    colonnes = list(resultat[0]._mapping.keys())
    ecrire("| " + " | ".join(colonnes) + " |")
    ecrire("|" + "---|" * len(colonnes))
    for ligne in resultat[:40]:
        ecrire("| " + " | ".join("∅" if v is None else str(v) for v in ligne) + " |")
    return resultat


# Classe une péremption textuelle par sa forme, sans jamais l'afficher.
_FORME_PEREMPTION = """
    CASE
        WHEN {c} IS NULL OR btrim({c}) = '' THEN 'vide'
        WHEN {c} ~ '^[0-9]{{2}}/[0-9]{{2}}$' THEN 'MM/YY'
        WHEN {c} ~ '^[0-9]{{2}}/[0-9]{{4}}$' THEN 'MM/YYYY'
        WHEN {c} ~ '^[0-9]{{2}}/[0-9]{{2}}/[0-9]{{4}}$' THEN 'DD/MM/YYYY'
        WHEN {c} ~ '^[0-9]{{4}}-[0-9]{{2}}' THEN 'YYYY-MM…'
        ELSE 'autre (longueur ' || length({c}) || ')'
    END
"""


async def partie_donnees(rafraichir: bool) -> bool:
    ecrire("## 1. Données\n")

    peuplee = (await sql(
        "SELECT relispopulated FROM pg_class WHERE relname = 'mv_stock_produits'"))
    est_peuplee = bool(peuplee and peuplee[0][0])
    ecrire(f"- Vue `mv_stock_produits` calculée : **{'oui' if est_peuplee else 'NON'}**")
    if not est_peuplee and rafraichir:
        debut = time.monotonic()
        async with AsyncSessionLocal() as db:
            # Premier calcul : CONCURRENTLY est refusé sur une vue jamais peuplée.
            await db.execute(text("REFRESH MATERIALIZED VIEW mv_stock_produits"))
            await db.commit()
        est_peuplee = True
        ecrire(f"- Vue recalculée par `--rafraichir` en {time.monotonic() - debut:.1f}s")
    elif est_peuplee and rafraichir:
        async with AsyncSessionLocal() as db:
            await db.execute(text("REFRESH MATERIALIZED VIEW CONCURRENTLY mv_stock_produits"))
            await db.commit()
        ecrire("- Vue rafraîchie par `--rafraichir`")
    if not est_peuplee:
        ecrire("- ⚠️ Toutes les routes qui lisent le stock vont échouer. "
               "Relancer avec `--rafraichir`.")

    await verifier("Volumes", """
        SELECT 'nomenclature' AS table, count(*) AS lignes FROM nomenclature
        UNION ALL SELECT 'entrees_produits (lots)', count(*) FROM entrees_produits
        UNION ALL SELECT 'sorties_produits', count(*) FROM sorties_produits
        UNION ALL SELECT 'instance_produits', count(*) FROM instance_produits
        UNION ALL SELECT 'inventaires', count(*) FROM inventaires
        UNION ALL SELECT 'inventaires_produits', count(*) FROM inventaires_produits
        UNION ALL SELECT 'nomenclature_classification', count(*) FROM nomenclature_classification
        UNION ALL SELECT 'historique_stock_jour', count(*) FROM historique_stock_jour
        UNION ALL SELECT 'parametres_stock', count(*) FROM parametres_stock
        UNION ALL SELECT 'previsions_demande', count(*) FROM previsions_demande
    """)

    await verifier("Périodes couvertes", """
        SELECT 'sorties_produits.date' AS colonne, min(date) AS debut, max(date) AS fin,
               count(*) FILTER (WHERE date IS NULL) AS sans_date FROM sorties_produits
        UNION ALL
        SELECT 'entrees_produits.date_entree', min(date_entree), max(date_entree),
               count(*) FILTER (WHERE date_entree IS NULL) FROM entrees_produits
    """)

    if est_peuplee:
        await verifier("Stock (vue mv_stock_produits)", """
            SELECT count(*) AS produits,
                   count(*) FILTER (WHERE stock_actuel > 0) AS en_stock,
                   count(*) FILTER (WHERE stock_actuel = 0) AS a_zero,
                   count(*) FILTER (WHERE stock_actuel < 0) AS negatifs,
                   sum(stock_actuel) AS unites,
                   round(sum(stock_actuel * prix_moyen_pondere), 2) AS valeur_achat
            FROM mv_stock_produits
        """)
        await verifier("Produits actifs (en stock, ou vendus dans les 12 mois)", """
            SELECT count(*) FILTER (WHERE actif) AS actifs,
                   count(*) FILTER (WHERE actif AND stock_actuel > 0) AS actifs_en_stock,
                   count(*) FILTER (WHERE actif AND stock_actuel = 0) AS actifs_en_rupture,
                   count(*) FILTER (WHERE NOT actif) AS inactifs,
                   count(*) FILTER (WHERE stock_actuel > 0 AND qte_vendue_12m <= 0) AS en_stock_sans_vente_12m,
                   count(*) FILTER (WHERE derniere_vente IS NULL) AS jamais_vendus
            FROM mv_stock_produits
        """)
        await verifier("Prix de vente (pris sur les lots)", """
            SELECT count(*) FILTER (WHERE prix_vente > 0) AS avec_prix,
                   count(*) FILTER (WHERE prix_vente = 0) AS sans_prix,
                   count(*) FILTER (WHERE prix_vente = 0 AND actif) AS actifs_sans_prix,
                   count(*) FILTER (WHERE prix_vente = 0 AND stock_actuel > 0) AS en_stock_sans_prix,
                   round(sum(valeur_achat), 2) AS valeur_stock_achat,
                   round(sum(valeur_vente), 2) AS valeur_stock_vente
            FROM mv_stock_produits
        """)
        await verifier(
            "Stock de la fiche produit (nomenclature.stock) contre somme des lots", """
            SELECT count(*) FILTER (WHERE COALESCE(n.stock, 0) = mv.stock_actuel) AS identiques,
                   count(*) FILTER (WHERE COALESCE(n.stock, 0) <> mv.stock_actuel) AS differents,
                   round(sum(abs(COALESCE(n.stock, 0) - mv.stock_actuel)), 0) AS ecart_total_unites
            FROM nomenclature n JOIN mv_stock_produits mv ON mv.id_nom = n.id
        """)

    await verifier("Lots (entrees_produits)", """
        SELECT count(*) AS lots,
               count(*) FILTER (WHERE stock > 0) AS avec_stock,
               count(*) FILTER (WHERE stock < 0) AS stock_negatif,
               count(*) FILTER (WHERE stock > 0 AND bloque = 1) AS en_stock_bloques,
               count(*) FILTER (WHERE stock > 0 AND peremption_date IS NULL) AS en_stock_sans_date_peremption,
               count(*) FILTER (WHERE stock > 0 AND peremption_date < CURRENT_DATE) AS en_stock_perimes,
               count(*) FILTER (WHERE stock > 0 AND peremption_date BETWEEN CURRENT_DATE
                                AND CURRENT_DATE + INTERVAL '3 months') AS en_stock_perimant_3_mois
        FROM entrees_produits
    """)

    for table in ("entrees_produits", "sorties_produits", "instance_produits"):
        forme = _FORME_PEREMPTION.format(c="peremption")
        await verifier(f"Format de `{table}.peremption`", f"""
            SELECT {forme} AS forme, count(*) AS lignes
            FROM {table} GROUP BY 1 ORDER BY 2 DESC
        """)

    await verifier("`entrees_produits` : peremption (texte) contre peremption_date", """
        SELECT count(*) FILTER (WHERE peremption_date IS NOT NULL) AS date_remplie,
               count(*) FILTER (WHERE peremption_date IS NULL
                                AND peremption IS NOT NULL AND btrim(peremption) <> '') AS texte_seul,
               count(*) FILTER (WHERE peremption_date IS NULL
                                AND (peremption IS NULL OR btrim(peremption) = '')) AS aucune
        FROM entrees_produits
    """)

    await verifier("Lignes orphelines (produit absent de la nomenclature)", """
        SELECT 'entrees_produits' AS table,
               count(*) FILTER (WHERE ep.id_nom IS NULL) AS sans_id_nom,
               count(*) FILTER (WHERE ep.id_nom IS NOT NULL AND n.id IS NULL) AS id_nom_inconnu
        FROM entrees_produits ep LEFT JOIN nomenclature n ON n.id = ep.id_nom
        UNION ALL
        SELECT 'sorties_produits',
               count(*) FILTER (WHERE sp.id_nom IS NULL),
               count(*) FILTER (WHERE sp.id_nom IS NOT NULL AND n.id IS NULL)
        FROM sorties_produits sp LEFT JOIN nomenclature n ON n.id = sp.id_nom
    """)

    await verifier("Types de sortie (sorties_produits.type_sortie)", """
        SELECT COALESCE(type_sortie, '∅') AS type_sortie, count(*) AS lignes
        FROM sorties_produits GROUP BY 1 ORDER BY 2 DESC
    """)

    await verifier("Fiches produit : champs de pilotage", """
        SELECT count(*) AS produits,
               count(*) FILTER (WHERE archive) AS archives,
               count(*) FILTER (WHERE segment_abc IS NULL OR segment_abc = '') AS sans_segment_abc,
               count(*) FILTER (WHERE segment_xyz IS NULL OR segment_xyz = '') AS sans_segment_xyz,
               count(*) FILTER (WHERE disponibilite IS NULL OR disponibilite = '') AS sans_disponibilite,
               count(*) FILTER (WHERE categorie IS NULL OR categorie = '') AS sans_categorie,
               count(*) FILTER (WHERE etagere IS NULL OR etagere = '') AS sans_etagere,
               count(*) FILTER (WHERE COALESCE(qte_alerte, 0) > 0) AS avec_seuil_alerte,
               count(*) FILTER (WHERE psychotrope = 1) AS psychotropes,
               count(*) FILTER (WHERE de_equiv IS NULL OR de_equiv = '') AS sans_de_equiv
        FROM nomenclature
    """)
    for colonne in ("segment_abc", "segment_xyz", "disponibilite", "categorie"):
        await verifier(f"Répartition `nomenclature.{colonne}`", f"""
            SELECT COALESCE(NULLIF({colonne}, ''), '∅') AS valeur, count(*) AS produits
            FROM nomenclature GROUP BY 1 ORDER BY 2 DESC
        """)

    await verifier("Format des heures de vente (attendu HH:MM:SS)", """
        SELECT count(*) FILTER (WHERE heure ~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}$') AS conformes,
               count(*) FILTER (WHERE heure IS NULL OR heure = '') AS vides,
               count(*) FILTER (WHERE heure <> '' AND heure !~ '^[0-9]{2}:[0-9]{2}:[0-9]{2}$') AS autres
        FROM sorties
    """)

    await verifier("Inventaires", """
        SELECT (SELECT count(*) FROM inventaires) AS inventaires,
               (SELECT count(*) FROM inventaires WHERE etat = 1) AS inventaires_valides,
               count(*) AS lignes,
               count(DISTINCT id_inventaire) AS inventaires_references,
               count(*) FILTER (WHERE id_nom IS NOT NULL) AS avec_id_nom,
               count(*) FILTER (WHERE id_produit IS NOT NULL) AS avec_id_produit,
               count(*) FILTER (WHERE stock_reel IS NOT NULL) AS avec_stock_reel,
               count(*) FILTER (WHERE quantite_physique IS NOT NULL) AS avec_quantite_physique
        FROM inventaires_produits
    """)

    await verifier("Laboratoires", """
        SELECT count(*) AS laboratoires,
               count(*) FILTER (WHERE is_generique) AS marques_generiques
        FROM laboratoires
    """)
    return est_peuplee


# ── Partie 2 : routes ─────────────────────────────────────────────────────────

def _est_nombre(v: Any) -> bool:
    return isinstance(v, (int, float, Decimal)) and not isinstance(v, bool)


def decrire(valeur: Any, profondeur: int = 0) -> str:
    """Forme d'une réponse JSON : clés, tailles, agrégats numériques. Jamais de texte."""
    if isinstance(valeur, list):
        if not valeur:
            return "liste vide"
        premier = valeur[0]
        if isinstance(premier, dict) and profondeur < 2:
            champs = []
            for cle in premier:
                colonne = [e.get(cle) for e in valeur if isinstance(e, dict)]
                nuls = sum(1 for v in colonne if v is None)
                nombres = [v for v in colonne if _est_nombre(v)]
                detail = cle
                if nombres and len(nombres) == len(colonne) - nuls:
                    detail += f" [{min(nombres):g}…{max(nombres):g}]"
                if nuls:
                    detail += f" ({nuls} nul{'s' if nuls > 1 else ''})"
                champs.append(detail)
            return f"liste de {len(valeur)} × {{{', '.join(champs)}}}"
        return f"liste de {len(valeur)} {type(premier).__name__}"
    if isinstance(valeur, dict):
        if profondeur >= 2:
            return f"objet à {len(valeur)} clés"
        parties = []
        for cle, v in valeur.items():
            if isinstance(v, (list, dict)):
                parties.append(f"{cle}: {decrire(v, profondeur + 1)}")
            elif _est_nombre(v):
                parties.append(f"{cle}={v:g}")
            elif v is None:
                parties.append(f"{cle}=∅")
            elif isinstance(v, bool):
                parties.append(f"{cle}={v}")
            else:
                parties.append(f"{cle}: texte")
        return "{" + "; ".join(parties) + "}"
    return type(valeur).__name__


async def requete_asgi(chemin: str, params: dict) -> tuple[int, bytes]:
    """
    Appelle l'application FastAPI directement par son interface ASGI : ni
    réseau, ni client HTTP à installer dans l'image.
    """
    scope = {
        "type": "http", "asgi": {"version": "3.0"}, "http_version": "1.1",
        "method": "GET", "scheme": "http", "path": chemin, "raw_path": chemin.encode(),
        "query_string": urlencode(params).encode(),
        "headers": [(b"host", b"verification")],
        "client": ("127.0.0.1", 0), "server": ("verification", 80), "root_path": "",
    }
    code = 500
    corps = bytearray()
    recu = False

    async def receive():
        nonlocal recu
        if not recu:
            recu = True
            return {"type": "http.request", "body": b"", "more_body": False}
        await asyncio.sleep(3600)   # jamais de déconnexion pendant l'appel

    async def send(message):
        nonlocal code
        if message["type"] == "http.response.start":
            code = message["status"]
        elif message["type"] == "http.response.body":
            corps.extend(message.get("body", b""))

    await app(scope, receive, send)
    return code, bytes(corps)


async def appeler(chemin: str, **params) -> dict:
    libelle = chemin + ("?" + "&".join(f"{k}={v}" for k, v in params.items()) if params else "")
    debut = time.monotonic()
    try:
        code, corps = await asyncio.wait_for(requete_asgi(PREFIXE + chemin, params), timeout=120)
        duree = time.monotonic() - debut
        if code == 200:
            return {"route": libelle, "code": 200, "duree": duree,
                    "detail": decrire(json.loads(corps))}
        return {"route": libelle, "code": code, "duree": duree,
                "detail": corps.decode("utf-8", errors="replace")[:300]}
    except asyncio.TimeoutError:
        return {"route": libelle, "code": 504, "duree": time.monotonic() - debut,
                "detail": "aucune réponse en 120 s"}
    except Exception as erreur:
        # Exception non gérée dans la route : ce serait un 500 pour un client.
        message = str(erreur).splitlines()[0][:300] if str(erreur) else ""
        return {"route": libelle, "code": 500, "duree": time.monotonic() - debut,
                "detail": f"{type(erreur).__name__}: {message}"}


async def un_id(requete: str) -> Any:
    try:
        resultat = await sql(requete)
        return resultat[0][0] if resultat else None
    except Exception:
        return None


async def partie_routes() -> tuple[int, int]:
    ecrire("\n## 2. Routes GET de /api/v1/stock\n")

    produit = await un_id(
        "SELECT id_nom FROM entrees_produits WHERE stock > 0 "
        "GROUP BY id_nom ORDER BY count(*) DESC LIMIT 1")
    psychotrope = await un_id("SELECT id FROM nomenclature WHERE psychotrope = 1 LIMIT 1")
    prefixe = await un_id("SELECT prefix FROM nomenclature_classification LIMIT 1")
    aujourd_hui = date.today()

    appels: list[tuple[str, dict]] = [
        ("/products", {}),
        ("/products", {"in_stock_only": "true", "limit": 200}),
        ("/products", {"segment_abc": "A"}),
        ("/products", {"disponibilite": "rupture"}),
        ("/products", {"actif": "true"}),
        ("/products", {"actif": "false"}),
        ("/products", {"psychotrope": 1}),
        ("/instances", {}),
        ("/alerts", {"alert_type": "all"}),
        ("/alerts", {"alert_type": "rupture"}),
        ("/alerts", {"alert_type": "alerte"}),
        ("/familles", {}),
        ("/formes", {}),
        ("/classifications", {}),
        ("/classifications/etageres", {}),
        ("/laboratoires", {}),
        ("/kpis/rotation", {}),
        ("/kpis/rotation", {"annee": aujourd_hui.year, "mois": aujourd_hui.month}),
        ("/kpis/segments", {}),
        ("/kpis/categories", {}),
        ("/kpis/performance-categories", {}),
        ("/psychotropes/historique", {}),
        ("/psychotropes/snapshot", {"date": aujourd_hui.isoformat()}),
    ]
    for type_ in ("rupture", "alerte", "peremption_3m", "peremption_6m", "peremption_9m", "surstock"):
        appels.append(("/dashboard/lots", {"type": type_}))
    if produit is not None:
        appels += [(f"/products/{produit}", {}),
                   (f"/products/{produit}/lots", {}),
                   (f"/products/{produit}/lots", {"in_stock_only": "false"})]
    else:
        ecrire("- Aucun lot en stock : routes `/products/{id}` non testées.")
    if psychotrope is not None:
        appels.append(("/psychotropes/historique", {"id_nom": psychotrope}))
    if prefixe is not None:
        appels.append((f"/classifications/{prefixe}/products", {}))
    else:
        ecrire("- `nomenclature_classification` vide : `/classifications/{prefix}/products` non testée.")

    # Pas de jeton : l'identité est fournie directement à la dépendance.
    app.dependency_overrides[get_current_user] = lambda: {"username": "verification", "role": "admin"}
    resultats = []
    try:
        for chemin, params in appels:
            resultats.append(await appeler(chemin, **params))
    finally:
        app.dependency_overrides.clear()

    ecrire("| Route | Code | Durée | Réponse |")
    ecrire("|---|---|---|---|")
    for r in resultats:
        etat = "✅ 200" if r["code"] == 200 else f"❌ {r['code']}"
        lent = " 🐢" if r["duree"] > 2 else ""
        detail = r["detail"].replace("|", "\\|").replace("\n", " ")
        ecrire(f"| `{r['route']}` | {etat} | {r['duree']:.2f}s{lent} | {detail} |")

    ecrire("\nRoutes non appelées, parce qu'elles écrivent : `POST /refresh-cache`, "
           "`POST /segmentation/run`, `POST /classifications/reimport`, "
           "`POST /classifications/auto-categorize`, et les trois `PATCH`.")
    ok = sum(1 for r in resultats if r["code"] == 200)
    return ok, len(resultats)


async def main() -> int:
    parseur = argparse.ArgumentParser(description="Vérifie le module stock sur les données réelles.")
    parseur.add_argument("--rafraichir", action="store_true",
                         help="recalcule la vue matérialisée mv_stock_produits avant les tests")
    parseur.add_argument("--sortie", default="logs/rapport_stock.md")
    args = parseur.parse_args()

    ecrire(f"# Vérification du module stock — {date.today().isoformat()}\n")
    await partie_donnees(args.rafraichir)
    ok, total = await partie_routes()
    ecrire(f"\n## Bilan\n\n**{ok} route(s) sur {total} répondent 200.**")

    try:
        chemin = Path(args.sortie)
        chemin.parent.mkdir(parents=True, exist_ok=True)
        chemin.write_text("\n".join(lignes) + "\n", encoding="utf-8")
        print(f"\nRapport écrit dans {chemin}")
    except OSError as erreur:
        print(f"\nRapport non écrit ({erreur}) ; il est complet ci-dessus.")
    return 0 if ok == total else 1


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
