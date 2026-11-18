"""
Non-régression — enveloppe de la prime de rendement.

Règle métier : enveloppe = Σ (CA de la catégorie × taux_pct), sur les seules
catégories actives de `prime_taux_config`. Taux en vigueur (migration 038,
arbitrage du 2026-08-19) : Princeps 0,5 % · Générique 1 % · Générique++ 3 %.

Ces tests verrouillent deux choses :
  1. les montants produits pour des entrées connues ;
  2. le fait qu'aucun float n'intervient dans la chaîne de calcul.
"""
from __future__ import annotations

from decimal import Decimal

import pytest

from app.api.v1.performance import (
    _BASE_CA_SQL,
    _ca_sql_pour_filtre,
    _calc_enveloppe_prime,
    _d,
)

from .conftest import FakeSession, config


# ── Montants ──────────────────────────────────────────────────────────────────

async def test_somme_ponderee_des_trois_categories(configs_officine):
    """1 000 000 à 0,5 % + 500 000 à 1 % + 200 000 à 3 % = 16 000,00 DA."""
    db = FakeSession(configs_officine, [
        Decimal("1000000.00"),
        Decimal("500000.00"),
        Decimal("200000.00"),
    ])

    assert await _calc_enveloppe_prime(db, 2026, 7) == Decimal("16000.00")


async def test_aucune_categorie_active_donne_zero():
    """Pas de config → enveloppe nulle, et un Decimal, pas un 0.0 flottant."""
    db = FakeSession([], [])
    enveloppe = await _calc_enveloppe_prime(db, 2026, 7)

    assert enveloppe == Decimal("0.00")
    assert isinstance(enveloppe, Decimal)


async def test_ca_nul_sur_une_categorie(configs_officine):
    """Un CA nul (ou NULL en base) ne contribue pas et ne casse rien."""
    db = FakeSession(configs_officine, [Decimal("400000.00"), None, Decimal("100000.00")])

    # 400 000 × 0,5 % = 2 000 ; rien ; 100 000 × 3 % = 3 000
    assert await _calc_enveloppe_prime(db, 2026, 7) == Decimal("5000.00")


async def test_precision_conservee_a_grande_echelle(configs_officine):
    """
    CA réaliste d'officine avec des prix en Numeric(15, 4).

    Le résultat doit être exact au centime, sans dérive de représentation.
    """
    db = FakeSession(configs_officine, [
        Decimal("14837291.5537"),
        Decimal("9204118.8261"),
        Decimal("3115664.1902"),
    ])

    attendu = (
        Decimal("14837291.5537") * Decimal("0.500") / 100
        + Decimal("9204118.8261") * Decimal("1.000") / 100
        + Decimal("3115664.1902") * Decimal("3.000") / 100
    ).quantize(Decimal("0.01"))

    assert await _calc_enveloppe_prime(db, 2026, 7) == attendu
    assert await _calc_enveloppe_prime(
        FakeSession(configs_officine, [
            Decimal("14837291.5537"),
            Decimal("9204118.8261"),
            Decimal("3115664.1902"),
        ]), 2026, 7
    ) == Decimal("259697.57")


async def test_demi_centime_arrondi_vers_le_haut():
    """
    Régression : 33 333,50 DA à 3 % = 1 000,0050 DA exactement.

    L'ancienne implémentation renvoyait un float, et `round(1000.005, 2)`
    donne 1000.0 — le demi-centime binaire tombe juste en dessous. On exige
    ROUND_HALF_UP, cohérent avec le stockage Numeric(14, 2).
    """
    db = FakeSession([config("Générique++", "3.000", "gentype:generique_remb")],
                     [Decimal("33333.50")])

    assert await _calc_enveloppe_prime(db, 2026, 7) == Decimal("1000.01")
    assert round(1000.005, 2) == 1000.0  # ce que faisait l'ancien chemin


# ── Contrat de type : pas de float dans la chaîne ─────────────────────────────

async def test_retourne_un_decimal_quantifie(configs_officine):
    db = FakeSession(configs_officine, [Decimal("123456.78")] * 3)
    enveloppe = await _calc_enveloppe_prime(db, 2026, 7)

    assert isinstance(enveloppe, Decimal)
    assert not isinstance(enveloppe, float)
    assert enveloppe.as_tuple().exponent == -2, "doit être quantifié au centime"


@pytest.mark.parametrize("brut, attendu", [
    (None, Decimal(0)),
    (0, Decimal(0)),
    (Decimal("12.3456"), Decimal("12.3456")),
    (7, Decimal(7)),
])
def test_conversion_sans_passer_par_float(brut, attendu):
    resultat = _d(brut)
    assert resultat == attendu
    assert isinstance(resultat, Decimal)


def test_conversion_ne_degrade_pas_un_decimal_existant():
    """_d doit rendre l'objet tel quel, sans aller-retour str/float."""
    valeur = Decimal("9999999999.9999")
    assert _d(valeur) is valeur


# ── Construction du SQL ───────────────────────────────────────────────────────

@pytest.mark.parametrize("filtre, fragment", [
    ("gentype:princeps", "COALESCE(n.categorie, 'princeps') NOT IN ('generique', 'generique++')"),
    ("gentype:generique", "n.categorie = 'generique'"),
    ("gentype:generique_remb", "n.categorie = 'generique++'"),
])
def test_filtres_categorie(filtre, fragment):
    sql, params = _ca_sql_pour_filtre(filtre)
    assert sql.startswith(_BASE_CA_SQL)
    assert sql.endswith(" AND " + fragment)
    assert params == {}


@pytest.mark.parametrize("filtre", [None, ""])
def test_filtre_absent_prend_tous_les_produits(filtre):
    sql, params = _ca_sql_pour_filtre(filtre)
    assert sql == _BASE_CA_SQL
    assert params == {}


def test_filtre_commercial_passe_en_parametre_lie():
    """
    Le filtre libre vient de la base et est éditable via l'API : il ne doit
    jamais être interpolé dans le SQL.
    """
    sql, params = _ca_sql_pour_filtre("%PARAPHARMACIE%")

    assert sql.endswith(" AND sp.famille ILIKE :filtre")
    assert params == {"filtre": "%PARAPHARMACIE%"}
    assert "PARAPHARMACIE" not in sql


async def test_injection_dans_le_filtre_reste_une_valeur():
    """Un filtre hostile ressort en paramètre, pas en fragment de requête."""
    hostile = "%'; DROP TABLE sorties; --"
    db = FakeSession([config("Bricolé", "1.000", hostile)], [Decimal("1000.00")])

    await _calc_enveloppe_prime(db, 2026, 7)

    sql, params = db.sql_executes[0]
    assert "DROP TABLE" not in sql
    assert params["filtre"] == hostile


async def test_periode_toujours_transmise_en_parametres(configs_officine):
    db = FakeSession(configs_officine, [Decimal("1000.00")] * 3)

    await _calc_enveloppe_prime(db, 2026, 7)

    assert len(db.sql_executes) == 3
    for _, params in db.sql_executes:
        assert params["annee"] == 2026
        assert params["mois"] == 7


# ── Sur une vraie base : produit sans catégorie compté au taux princeps ──────

async def test_produit_sans_categorie_compte_au_taux_princeps():
    """Arbitrage du 2026-11-18 : une vente de produit non classé (ou absent de
    la nomenclature) entre dans l'enveloppe au taux princeps."""
    from sqlalchemy import text
    from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
    from sqlalchemy.pool import NullPool
    from app.core.config import settings

    if not settings.db_name.endswith("_test"):
        pytest.skip("base de test absente (DB_NAME doit se terminer par _test)")
    engine = create_async_engine(settings.database_url, poolclass=NullPool)
    try:
        async with AsyncSession(engine) as db:
            try:
                await db.execute(text("SELECT 1"))
            except Exception as erreur:
                pytest.skip(f"base de test injoignable : {str(erreur).splitlines()[0][:80]}")
            await db.execute(text("DELETE FROM sorties_produits WHERE id BETWEEN 990001 AND 990005"))
            await db.execute(text("DELETE FROM sorties WHERE id = 990000"))
            await db.execute(text("DELETE FROM nomenclature WHERE id BETWEEN 990001 AND 990004"))
            await db.execute(text("""
                INSERT INTO nomenclature (id, nom, categorie) VALUES
                (990001, 'P', 'princeps'), (990002, 'G', 'generique'), (990003, 'X', NULL), (990004, 'Y', 'promotion')
            """))
            await db.execute(text("INSERT INTO sorties (id, date, type) VALUES (990000, DATE '2031-03-05', 'V')"))
            await db.execute(text("""
                INSERT INTO sorties_produits (id, id_sortie, id_nom, qte_sortie, prix_vente) VALUES
                (990001, 990000, 990001, 1, 10000), (990002, 990000, 990002, 1, 20000),
                (990003, 990000, 990003, 1, 5000),  (990004, 990000, 999999, 1, 1000),
                (990005, 990000, 990004, 1, 2000)
            """))
            # princeps (10 000 + 5 000 non classé + 1 000 hors nomenclature + 2 000 ancienne valeur)
            # × 0,5 % + générique 20 000 × 1 %
            assert await _calc_enveloppe_prime(db, 2031, 3) == Decimal("290.00")
            await db.rollback()
    finally:
        await engine.dispose()
