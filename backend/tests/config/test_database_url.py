"""L'URL de connexion doit survivre à un mot de passe avec caractères spéciaux."""
from configparser import ConfigParser

import pytest
from sqlalchemy.engine import make_url

from app.core.config import Settings


@pytest.mark.parametrize("mdp", ["simple", "a@b", "x/y#z:w", "100%sûr!", "p@ss/w0rd#2026"])
def test_mot_de_passe_preserve(mdp):
    s = Settings(db_host="postgres", db_user="pharmasuite_admin", db_password=mdp, db_name="pharmasuite")
    for url in (s.database_url, s.sync_database_url):
        parsee = make_url(url)
        assert parsee.password == mdp
        assert parsee.host == "postgres"
        assert parsee.database == "pharmasuite"
        assert parsee.username == "pharmasuite_admin"


def test_url_echappee_passe_par_configparser_comme_dans_alembic():
    s = Settings(db_password="a@b%c")
    cp = ConfigParser()
    cp.add_section("alembic")
    cp.set("alembic", "sqlalchemy.url", s.sync_database_url.replace("%", "%%"))
    assert make_url(cp.get("alembic", "sqlalchemy.url")).password == "a@b%c"
