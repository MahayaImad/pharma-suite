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
