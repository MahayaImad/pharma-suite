"""Reconstitution de l'historique par lot, sur la base de test — calculée à la main."""
from datetime import date, timedelta

from sqlalchemy import text

from app.services.historique_stock import reconstituer

T = date.today()


def j(n: int) -> date:
    return T - timedelta(days=n)


async def _jeu(db):
    """Produit 1, deux lots :
       L1 entré il y a 10 j (20 u), vendu 2 u/j de j-9 à j0 → 0 aujourd'hui ;
          à j-5 : inventaire, 1 boîte cassée (écart −1) ; un retour client +1 à j-3 (qte −1) ;
       L2 entré il y a 4 j (12 u) ; avoir fournisseur de 2 u à j-1 ; 10 aujourd'hui.
    """
    await db.execute(text("INSERT INTO nomenclature (id, nom, archive) VALUES (1, 'P', false)"))
    await db.execute(text("""
        INSERT INTO entrees_produits (id, id_nom, lot, date_entree, qte_entree, stock, prix_achat, prix_vente, type_entree)
        VALUES (1, 1, 'L1', :e1, 20, 0, 10, 15, 'A'), (2, 1, 'L2', :e2, 12, 10, 10, 15, 'A'),
               (3, 1, 'L2', :av, 2, 0, 10, 15, 'AV')"""), {"e1": j(10), "e2": j(4), "av": j(1)})
    n = 0
    for k in range(10):
        n += 1
        await db.execute(text("""INSERT INTO sorties_produits (id, id_nom, lot, date, qte_sortie, prix_vente, type_sortie)
            VALUES (:i, 1, 'L1', :d, 2, 15, 'V')"""), {"i": n, "d": j(k)})
    await db.execute(text("""INSERT INTO sorties_produits (id, id_nom, lot, date, qte_sortie, prix_vente, type_sortie)
        VALUES (99, 1, 'L1', :d, -1, 15, 'V')"""), {"d": j(3)})
    await db.execute(text("""INSERT INTO inventaires_produits (id, id_nom, lot, date, stock_theorique, stock_reel, ecart)
        VALUES (1, 1, 'L1', :d, 11, 10, -1)"""), {"d": j(5)})
    await db.execute(text("REFRESH MATERIALIZED VIEW mv_stock_produits"))
    await db.commit()


async def test_reconstitution_par_lot_tous_mouvements(db):
    await db.execute(text("TRUNCATE inventaires_produits"))
    await _jeu(db)
    r = await reconstituer(db, j(11), T)
    serie = {l.date: float(l.stock_eod) for l in await db.execute(text(
        "SELECT date, stock_eod FROM historique_stock_jour WHERE id_nom = 1 ORDER BY date"))}
    # À rebours, les mouvements d'un jour donnent le stock de la veille au soir :
    #   fin(veille) = fin(jour) + sorties(jour) − ajustements(jour).
    # L1 (stock 0 aujourd'hui) : j0 0 ; j1 0+2 = 2 ; j2 4 ; j3 6 ;
    #   j4 = 6 + (2 vendus − 1 retour du jour j3) = 7 ; j5 9 ;
    #   j6 = 9 + 2 − (−1 casse du jour j5) = 12 ; j7 14 ; j8 16 ; j9 18 ; j10 20 (entrée) ; j11 : pas encore là.
    # L2 (10 aujourd'hui) : j0 10 ; j1 = 10 + 0 = 10 ; j2 = 10 + 2 (avoir du jour j1) = 12 ; j3 12 ; j4 12 (entrée).
    attendu_l1 = {0: 0, 1: 2, 2: 4, 3: 6, 4: 7, 5: 9, 6: 12, 7: 14, 8: 16, 9: 18, 10: 20, 11: 0}
    attendu_l2 = {0: 10, 1: 10, 2: 12, 3: 12, 4: 12}
    attendu = {j(k): attendu_l1[k] + attendu_l2.get(k, 0) for k in range(12)}
    assert serie == attendu
    assert r.jours_negatifs == 0 and r.produits == 1


async def test_une_photo_n_est_pas_remplacee(db):
    await db.execute(text("TRUNCATE inventaires_produits"))
    await _jeu(db)
    await db.execute(text("""INSERT INTO historique_stock_jour (id_nom, date, stock_eod, source)
        VALUES (1, :d, 99, 'photo')"""), {"d": j(2)})
    await db.commit()
    r = await reconstituer(db, j(11), T)
    assert r.photos_preservees == 1
    ligne = (await db.execute(text(
        "SELECT stock_eod, source FROM historique_stock_jour WHERE id_nom = 1 AND date = :d"), {"d": j(2)})).one()
    assert (float(ligne.stock_eod), ligne.source) == (99, "photo")


async def test_essai_n_ecrit_rien(db):
    await db.execute(text("TRUNCATE inventaires_produits"))
    await _jeu(db)
    r = await reconstituer(db, j(11), T, ecrire=False)
    assert r.jours_ecrits == 12
    assert (await db.execute(text("SELECT count(*) FROM historique_stock_jour"))).scalar() == 0


async def test_ajustement_rattache_par_code_barre(db):
    """Dans EASYPHARM, la ligne d'inventaire a id_nom vide : elle désigne son
    lot par le code-barres (unique par lot)."""
    await db.execute(text("TRUNCATE inventaires_produits"))
    await db.execute(text("INSERT INTO nomenclature (id, nom, archive) VALUES (1, 'P', false)"))
    await db.execute(text("""
        INSERT INTO entrees_produits (id, id_nom, lot, code_barre, date_entree, qte_entree, stock, prix_achat, prix_vente, type_entree)
        VALUES (1, 1, 'L1', '2000000123', :e, 10, 7, 10, 15, 'A')"""), {"e": j(5)})
    await db.execute(text("""
        INSERT INTO inventaires_produits (id, id_nom, lot, code_barre, date, ecart, motif)
        VALUES (1, NULL, 'L1', '2000000123', :d, -3, 'Casse')"""), {"d": j(2)})
    await db.execute(text("REFRESH MATERIALIZED VIEW mv_stock_produits"))
    await db.commit()
    await reconstituer(db, j(5), T)
    serie = {l.date: float(l.stock_eod) for l in await db.execute(text(
        "SELECT date, stock_eod FROM historique_stock_jour WHERE id_nom = 1 ORDER BY date"))}
    # 7 aujourd'hui ; la casse de 3 au jour j2 : 10 en fin de j3 et avant
    assert serie == {j(0): 7, j(1): 7, j(2): 7, j(3): 10, j(4): 10, j(5): 10}


async def test_lots_retrouves_par_id_produit(db):
    """Inventaire et vente sans numéro de lot désignent leur lot par
    id_produit = entrees_produits.id (convention d'EASYPHARM)."""
    await db.execute(text("TRUNCATE inventaires_produits"))
    await db.execute(text("INSERT INTO nomenclature (id, nom, archive) VALUES (1, 'P', false), (2, 'Q', false)"))
    await db.execute(text("""
        INSERT INTO entrees_produits (id, id_nom, lot, date_entree, qte_entree, stock, prix_achat, prix_vente, type_entree)
        VALUES (41, 1, 'L1', :e, 10, 4, 10, 15, 'A'), (42, 2, 'L1', :e, 10, 10, 10, 15, 'A')"""), {"e": j(5)})
    # Vente sans numéro de lot du lot 41 (j1, 5 u) ; inventaire du lot 41 (j3, −1),
    # son numéro « L1 » existe aussi chez le produit 2 : seul l'id_produit tranche.
    await db.execute(text("""INSERT INTO sorties_produits (id, id_nom, lot, id_produit, date, qte_sortie, prix_vente, type_sortie)
        VALUES (1, 1, '', 41, :d, 5, 15, 'V')"""), {"d": j(1)})
    await db.execute(text("""INSERT INTO inventaires_produits (id, id_nom, lot, id_produit, date, ecart, motif)
        VALUES (1, NULL, 'L1', 41, :d, -1, 'Casse')"""), {"d": j(3)})
    await db.execute(text("REFRESH MATERIALIZED VIEW mv_stock_produits"))
    await db.commit()
    await reconstituer(db, j(5), T)
    serie = {(l.id_nom, l.date): float(l.stock_eod) for l in await db.execute(text(
        "SELECT id_nom, date, stock_eod FROM historique_stock_jour"))}
    # Produit 1 : 4 ; fin j1 4 ; fin j2 = 4 + 5 = 9 ; fin j3 9 ; fin j4 = 9 + 1 (casse de j3) = 10 ; j5 10
    assert [serie[(1, j(k))] for k in range(6)] == [4, 4, 9, 9, 10, 10]
    assert {serie[(2, j(k))] for k in range(6)} == {10}       # l'autre « L1 » n'est pas touché
