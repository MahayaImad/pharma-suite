# Tests

```bash
cd backend
python -m pip install -r requirements-dev.txt
python -m pytest
```

`pytest.ini` met `backend/pharmasuite` sur le `pythonpath`, donc les tests
importent `app.…` directement.

## `tests/paie/` — non négociable

Toute modification d'un calcul de paie ou de prime doit être accompagnée
d'un test ici, dans le même commit. Voir la règle « Paie » du CLAUDE.md.

Ces tests **ne touchent pas la base** : `FakeSession` (dans `conftest.py`)
simule les réponses de PostgreSQL. Ils vérifient l'arithmétique, pas le SQL —
c'est délibéré, un test de calcul monétaire ne doit pas dépendre d'un
conteneur qui tourne.

## Tests du stock (`tests/stock/`)

Les calculs du stock sont du SQL : ils se testent sur une vraie base
PostgreSQL, avec des jeux de données dont le résultat est calculé à la main.
Ils sont **ignorés** si aucune base de test n'est disponible, et refusent de
tourner sur une base dont le nom ne se termine pas par `_test` (ils vident
des tables).

```bash
createdb pharmasuite_test
DB_HOST=localhost DB_NAME=pharmasuite_test alembic upgrade head
DB_HOST=localhost DB_NAME=pharmasuite_test pytest tests/stock
```
