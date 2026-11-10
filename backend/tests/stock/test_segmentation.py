"""
Classement ABC / XYZ — résultats calculés à la main.

Chaque produit du jeu de données existe pour un cas précis ; le commentaire
donne le calcul attendu.
"""
from __future__ import annotations

from sqlalchemy import text

from app.services.stock_segmentation import compute_abc, compute_xyz

# Jour du mois où tombent les ventes « mensuelles » : loin des bords de mois.
_VENTE = """
    INSERT INTO sorties_produits (id, id_nom, date, qte_sortie, prix_vente, type_sortie)
    VALUES (:id, :id_nom, (date_trunc('month', CURRENT_DATE) - make_interval(months => :il_y_a))::date + 9,
            :qte, :prix, 'V')
"""


async def _produits(db, *ids, archive=()):
    for i in ids:
        await db.execute(text(
            "INSERT INTO nomenclature (id, nom, archive, segment_abc, segment_xyz) "
            "VALUES (:id, :nom, :archive, :abc, :xyz)"),
            {"id": i, "nom": f"P{i}", "archive": i in archive,
             # 7 porte une classe périmée, pour vérifier qu'elle est effacée
             "abc": "A" if i == 7 else None, "xyz": "X" if i == 7 else None})


class _Ventes:
    def __init__(self, db):
        self.db, self.n = db, 0

    async def __call__(self, id_nom, il_y_a, qte, prix=10):
        self.n += 1
        await self.db.execute(text(_VENTE), {"id": self.n, "id_nom": id_nom,
                                             "il_y_a": il_y_a, "qte": qte, "prix": prix})


async def _classes(db, colonne):
    lignes = await db.execute(text(f"SELECT id, {colonne} FROM nomenclature ORDER BY id"))
    return {i: c for i, c in lignes}


async def test_abc(db):
    await _produits(db, 1, 2, 3, 4, 5, 6, 7, 8, archive={5})
    vente = _Ventes(db)
    # Chiffre d'affaires sur 12 mois : 700 + 150 + 100 + 50 = 1 000
    await vente(1, 2, 70)        # 700 → cumul avant 0 %   → A
    await vente(2, 2, 15)        # 150 → cumul avant 70 %  → A (il fait franchir 80 %)
    await vente(3, 2, 10)        # 100 → cumul avant 85 %  → B
    await vente(4, 2, 5)         #  50 → cumul avant 95 %  → C
    await vente(5, 2, 900)       # archivé : ni classé, ni compté dans le total
    #        6                   # jamais vendu → pas de classe
    await vente(7, 20, 500)      # vendu il y a 20 mois seulement → classe A effacée
    await vente(8, 3, 40)        # vendu 40…
    await vente(8, 2, -40)       # …puis retourné : net 0 → pas de classe
    await vente(999, 2, 5000)    # produit absent de la nomenclature : ignoré
    await db.commit()

    assert await compute_abc(db) == 4
    assert await _classes(db, "segment_abc") == {
        1: "A", 2: "A", 3: "B", 4: "C", 5: None, 6: None, 7: None, 8: None}

    # Rejouer ne change rien.
    assert await compute_abc(db) == 4


async def test_xyz(db):
    await _produits(db, 1, 2, 3, 4, 5, 6, 7)
    vente = _Ventes(db)
    for mois in range(1, 13):                    # les 12 derniers mois complets
        await vente(1, mois, 10)                 # 10 chaque mois → CV 0 → X
        await vente(3, mois, 5 if mois % 2 else 15)   # 5/15 alternés : moyenne 10, σ 5, CV 0,5 → Y
    for mois in (2, 6, 10):
        await vente(2, mois, 40)                 # 3 mois sur 12 : moyenne 10, σ ≈ 17,3, CV ≈ 1,73 → Z
    for mois in (1, 2):
        await vente(4, mois, 10)                 # 2 mois d'historique seulement → Z
    await vente(5, 0, 10)                        # vendu ce mois-ci uniquement : pas de mois complet → Z
    #        6                                   # jamais vendu → pas de classe
    await vente(7, 20, 10)                       # vendu il y a 20 mois → classe X effacée
    await db.commit()

    assert await compute_xyz(db) == 5
    assert await _classes(db, "segment_xyz") == {
        1: "X", 2: "Z", 3: "Y", 4: "Z", 5: "Z", 6: None, 7: None}


async def test_abc_et_xyz_classent_les_memes_produits(db):
    await _produits(db, 1, 2, 3)
    vente = _Ventes(db)
    await vente(1, 3, 10)
    await vente(2, 0, 10)        # seulement ce mois-ci
    await db.commit()

    await compute_abc(db)
    await compute_xyz(db)
    lignes = await db.execute(text(
        "SELECT id, segment_abc IS NULL, segment_xyz IS NULL FROM nomenclature ORDER BY id"))
    assert [tuple(l) for l in lignes] == [(1, False, False), (2, False, False), (3, True, True)]
