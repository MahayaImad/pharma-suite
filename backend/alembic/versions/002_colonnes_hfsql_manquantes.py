"""colonnes HFSQL absentes du miroir PostgreSQL

Relevées par `python -m pharmasuite_agent --verifier` sur la base EASYPHARM
réelle (2026-11-09) : colonnes présentes côté HFSQL, sans équivalent
PostgreSQL, donc ignorées par le sync et perdues à l'import.

Types choisis tolérants faute de connaître le type HFSQL exact : `TEXT` pour
les libellés et références, `SMALLINT` pour les drapeaux 0/1, `NUMERIC(15, 4)`
pour les montants et quantités (règle « Argent » des tables miroir). Une
valeur inconvertible devient NULL et est signalée par le sync, elle ne bloque
pas la ligne.

`groupware.droits` regroupe en JSONB les ~300 drapeaux de droits d'accès
EASYPHARM, plutôt que d'en faire autant de colonnes.

Revision ID: 002
Revises: 001
Create Date: 2026-11-09
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB

revision = "002"
down_revision = "001"
branch_labels = None
depends_on = None

_MONTANT = sa.Numeric(15, 4)

COLONNES: dict[str, list[tuple[str, sa.types.TypeEngine]]] = {
    "sorties": [("avec_tpe", sa.SmallInteger()), ("ref_tpe", sa.Text())],
    "sorties_produits": [("avec_tpe", sa.SmallInteger()), ("ref_tpe", sa.Text())],
    "operations": [("avec_tpe", sa.SmallInteger()), ("ref_tpe", sa.Text())],
    "entrees_produits": [("id_gst", sa.Text())],
    "suivi_caisses": [("det_clot_multisession", sa.Text()), ("observation", sa.Text())],
    "caisses": [("cloture_multisession", sa.SmallInteger())],
    "comptes_bancaires": [("tpe", sa.SmallInteger())],
    "formes": [("id_forme", sa.Text())],
    "groupware": [("droits", JSONB())],
    "inventaires": [
        ("date_ouverture", sa.Date()),
        ("date_cloture", sa.Date()),
        ("description", sa.Text()),
        ("valeur_achat_initiale", _MONTANT),
        ("valeur_achat_inventaire", _MONTANT),
        ("valeur_ppa_initiale", _MONTANT),
        ("valeur_ppa_inventaire", _MONTANT),
        ("ecart_achat", _MONTANT),
        ("ecart_ppa", _MONTANT),
    ],
    "inventaires_produits": [
        ("id_produit", sa.BigInteger()),
        ("produit", sa.Text()),
        ("heure", sa.Text()),
        ("quantite_theorique", _MONTANT),
        ("quantite_physique", _MONTANT),
        ("ppa", _MONTANT),
        ("edite", sa.SmallInteger()),
        ("observation", sa.Text()),
    ],
}


def upgrade() -> None:
    for table, colonnes in COLONNES.items():
        for nom, type_ in colonnes:
            op.add_column(table, sa.Column(nom, type_, nullable=True))


def downgrade() -> None:
    for table, colonnes in COLONNES.items():
        for nom, _ in reversed(colonnes):
            op.drop_column(table, nom)
