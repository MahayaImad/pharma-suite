"""Photo du stock du soir dans historique_stock_jour."""
from datetime import date

from sqlalchemy import text

from app.services.photo_stock import prendre_photo
from app.services.purchase_engine.stock_history import reconstituer_et_sauvegarder

JOUR = date(2026, 11, 12)


async def _jeu(db):
    await db.execute(text("""
        INSERT INTO nomenclature (id, nom, archive) VALUES
        (1, 'EN STOCK', false), (2, 'RUPTURE', false), (3, 'ARCHIVE', true), (4, 'MORT', false)
    """))
    await db.execute(text("""
        INSERT INTO entrees_produits (id, id_nom, stock, qte_entree, prix_achat, prix_vente, date_entree) VALUES
        (1, 1, 12, 20, 10, 15, '2026-10-01'), (2, 3, 5, 5, 10, 15, '2026-10-01')
    """))
    # RUPTURE vendu il y a un mois → actif à 0 ; MORT jamais vendu, sans stock
    await db.execute(text("""
        INSERT INTO sorties_produits (id, id_nom, date, qte_sortie, prix_vente, type_sortie)
        VALUES (1, 2, CURRENT_DATE - 30, 1, 10, 'V')
    """))
    await db.execute(text("REFRESH MATERIALIZED VIEW mv_stock_produits"))
    await db.commit()


async def test_photo_releve_les_produits_actifs_ou_en_stock(db):
    await _jeu(db)
    r = await prendre_photo(db, JOUR)
    assert r["produits"] == 2 and r["donnees_anciennes"] is True    # aucune passe de l'agent notée
    lignes = (await db.execute(text(
        "SELECT id_nom, stock_eod, source FROM historique_stock_jour ORDER BY id_nom"))).all()
    assert [(l.id_nom, float(l.stock_eod), l.source) for l in lignes] == [(1, 12, "photo"), (2, 0, "photo")]
    # Une seconde photo le même jour remplace la première.
    await db.execute(text("UPDATE entrees_produits SET stock = 7 WHERE id = 1"))
    await db.execute(text("REFRESH MATERIALIZED VIEW mv_stock_produits"))
    await prendre_photo(db, JOUR)
    assert (await db.execute(text(
        "SELECT stock_eod FROM historique_stock_jour WHERE id_nom = 1"))).scalar() == 7


async def test_une_reconstitution_n_ecrase_pas_une_photo(db):
    await _jeu(db)
    await prendre_photo(db, date.today())
    # Une vente aujourd'hui : la reconstitution écrit une ligne pour ce jour.
    await db.execute(text("""
        INSERT INTO sorties_produits (id, id_nom, date, qte_sortie, prix_vente, type_sortie)
        VALUES (2, 2, CURRENT_DATE, 1, 10, 'V')"""))
    await db.commit()
    await reconstituer_et_sauvegarder(db, 2, 5, (date.today().replace(day=1)).isoformat())
    await db.commit()
    ligne = (await db.execute(text(
        "SELECT source, stock_eod FROM historique_stock_jour WHERE id_nom = 2 AND date = CURRENT_DATE"))).one()
    assert (ligne.source, float(ligne.stock_eod)) == ("photo", 0)   # pas le 5 reconstitué
