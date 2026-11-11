"""
Tests du module stock sur une vraie base PostgreSQL.

Les calculs du stock sont du SQL : une session simulée ne prouverait rien.
Ces tests ne tournent donc que si une base **de test** est disponible, et
sont ignorés sinon (les autres suites restent sans postgres).

    createdb pharmasuite_test
    DB_HOST=localhost DB_NAME=pharmasuite_test alembic upgrade head
    DB_HOST=localhost DB_NAME=pharmasuite_test pytest tests/stock

Garde-fou : ils vident des tables. Ils refusent de démarrer si le nom de la
base ne se termine pas par « _test ».
"""
from __future__ import annotations

import pytest
import pytest_asyncio
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.pool import NullPool

from app.core.config import settings

TABLES_VIDEES = ("sorties_produits", "entrees_produits", "nomenclature", "familles", "sync_status")


@pytest_asyncio.fixture
async def db():
    if not settings.db_name.endswith("_test"):
        pytest.skip("base de test absente (DB_NAME doit se terminer par _test)")
    engine = create_async_engine(settings.database_url, poolclass=NullPool)
    try:
        async with engine.connect() as cnx:
            await cnx.execute(text("SELECT 1"))
    except Exception as erreur:
        await engine.dispose()
        pytest.skip(f"base de test injoignable : {str(erreur).splitlines()[0][:80]}")

    from app.services.indicateurs_stock_lot import vider_cache
    vider_cache()
    async with AsyncSession(engine, expire_on_commit=False) as session:
        await session.execute(text(f"TRUNCATE {', '.join(TABLES_VIDEES)}"))
        await session.commit()
        yield session
    await engine.dispose()
