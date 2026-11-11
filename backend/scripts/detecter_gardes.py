"""
Retrouver les gardes passées dans les heures de vente d'EASYPHARM.

    cd docker
    docker compose run --rm api python -m scripts.detecter_gardes
    docker compose run --rm api python -m scripts.detecter_gardes --enregistrer

1. Montre le format du champ `sorties.heure` et les horaires habituels
   appris pour chaque jour de la semaine (nombres de tickets seulement).
2. Liste les gardes candidates (soirée, 24 h, jour de fermeture) et vérifie
   la détection sur les gardes déjà saisies dans la table `gardes`.
3. Donne les écarts les plus fréquents entre gardes (rotation).

Ne lit que des dates, des heures et des comptages : aucun nom, aucun
montant. Avec `--enregistrer`, ajoute les candidates à `gardes` avec
`source = 'detection'` et `confirme = false` ; les gardes saisies ne sont
jamais modifiées.

Rapport sur la sortie standard et dans `logs/rapport_gardes.md`.
"""
from __future__ import annotations

import argparse
import asyncio
import re
from collections import Counter
from datetime import date, timedelta
from pathlib import Path

from sqlalchemy import text

from app.core.database import AsyncSessionLocal
from app.services.gardes import detecter_gardes, ecarts_frequents, heure_de, horaires_habituels, jours_ouverts

JOURS = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]
lignes: list[str] = []


def ecrire(t: str = "") -> None:
    print(t)
    lignes.append(t)


def plages(heures: set[int]) -> str:
    """{8, 9, 10, 14, 15} → « 8 h–11 h, 14 h–16 h »."""
    if not heures:
        return "fermé"
    h = sorted(heures)
    morceaux, debut = [], h[0]
    for a, b in zip(h, h[1:] + [None]):
        if b != a + 1:
            morceaux.append(f"{debut} h–{a + 1} h")
            debut = b
    return ", ".join(morceaux)


def forme(heure: str) -> str:
    """Forme d'une valeur, sans la valeur : « 14:32:05 » → « 99:99:99 »."""
    return re.sub(r"\d", "9", heure.strip())


async def main() -> int:
    p = argparse.ArgumentParser(description="Retrouve les gardes passées dans les heures de vente.")
    p.add_argument("--mois", type=int, default=36, help="historique analysé (défaut : 36 mois)")
    p.add_argument("--enregistrer", action="store_true", help="ajouter les candidates à la table gardes")
    p.add_argument("--sortie", default="logs/rapport_gardes.md")
    a = p.parse_args()

    debut = date.today() - timedelta(days=30 * a.mois)
    async with AsyncSessionLocal() as db:
        formes = (await db.execute(text(
            "SELECT heure FROM sorties WHERE date >= :d AND heure IS NOT NULL LIMIT 2000"), {"d": debut})).scalars()
        compte_formes = Counter(forme(h) for h in formes)
        lignes_brutes = (await db.execute(text("""
            SELECT date, heure, count(*) AS n FROM sorties
            WHERE date >= :d AND heure IS NOT NULL
            GROUP BY date, heure
        """), {"d": debut})).all()
        saisies = {r.date: r.type for r in await db.execute(text(
            "SELECT date, type FROM gardes WHERE source = 'saisie'"))}
        ramadans = [(r.date_debut, r.date_fin) for r in await db.execute(text(
            "SELECT date_debut, date_fin FROM evenements_calendrier WHERE type = 'ramadan'"))]

    tickets: dict[tuple[date, int], int] = Counter()
    illisibles = 0
    for r in lignes_brutes:
        h = heure_de(r.heure)
        if h is None:
            illisibles += r.n
        else:
            tickets[(r.date, h)] += r.n

    ecrire("# Gardes retrouvées dans les heures de vente\n")
    ecrire(f"Historique : depuis le {debut} · tickets lus : {sum(tickets.values())} · heure illisible : {illisibles}\n")
    ecrire("## Format du champ `sorties.heure`\n")
    for f, n in compte_formes.most_common(5):
        ecrire(f"- `{f}` : {n}")
    if not tickets:
        ecrire("\n**Aucune heure lisible** : envoyez ce rapport, le format est à adapter.")
        Path(a.sortie).parent.mkdir(parents=True, exist_ok=True)
        Path(a.sortie).write_text("\n".join(lignes), encoding="utf-8")
        return 1

    ecrire("\n## Horaires habituels appris\n")
    habituelles, ouverts = horaires_habituels(tickets), jours_ouverts(tickets)
    for j in range(7):
        ecrire(f"- {JOURS[j]} : {plages(habituelles[j]) if j in ouverts else 'fermé'}")

    gardes = detecter_gardes(tickets, ramadans)
    ecrire(f"\nRamadan exclu des soirées et des nuits ({len(ramadans)} périodes).")
    ecrire(f"\n## Gardes candidates : {len(gardes)}\n")
    par_type = Counter(g.type for g in gardes)
    ecrire(" · ".join(f"{t} : {n}" for t, n in sorted(par_type.items())) or "aucune")

    ecrire("\n## Contrôle sur les gardes saisies\n")
    trouvees = {g.date: g.type for g in gardes}
    for d, t in sorted(saisies.items()):
        r = trouvees.get(d)
        ecrire(f"- {d} ({t}) : " + ("**retrouvée**" if r == t else f"retrouvée comme {r}" if r else "**non retrouvée**"))

    ecrire("\n## Rotation : écarts les plus fréquents entre gardes, par type\n")
    for t in ("soiree", "24h", "jour"):
        ecarts = ", ".join(f"{e} j ({n} fois)" for e, n in ecarts_frequents(gardes, type_=t))
        ecrire(f"- {t} : {ecarts or '—'}")

    ecrire("\n## Liste (12 derniers mois)\n")
    for g in gardes:
        if g.date >= date.today() - timedelta(days=365):
            ecrire(f"- {g.date} {JOURS[g.date.weekday()]} : {g.type} ({g.tickets_hors_horaires} tickets hors horaires)")

    if a.enregistrer:
        async with AsyncSessionLocal() as db:
            for g in gardes:
                await db.execute(text("""
                    INSERT INTO gardes (date, type, source, confirme, note)
                    VALUES (:d, :t, 'detection', false, :n)
                    ON CONFLICT (date) DO NOTHING
                """), {"d": g.date, "t": g.type, "n": f"{g.tickets_hors_horaires} tickets hors horaires"})
            await db.commit()
        ecrire(f"\n{len(gardes)} candidates enregistrées (non confirmées ; les saisies ne sont pas touchées).")

    Path(a.sortie).parent.mkdir(parents=True, exist_ok=True)
    Path(a.sortie).write_text("\n".join(lignes), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
