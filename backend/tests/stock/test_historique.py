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
