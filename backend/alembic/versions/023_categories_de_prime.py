"""catégories de prime : choix à la main, seuil générique++, historique des classements

L'enveloppe de prime dépend de `nomenclature.categorie` (princeps, générique,
générique++), propre à PharmaSuite. L'écran « Catégories de prime » la remplit :

- `nomenclature.categorie_manuelle` : catégorie choisie à la main, jamais
  écrasée par un classement automatique ;
- réglage `categories_seuil_generique_plus` (50) : marge moyenne des lots,
  en %, au-delà de laquelle un produit est générique++ ;
- `categories_classements` : chaque classement lancé (qui, quand, seuil,
  nombre de produits par catégorie) — l'enveloppe en dépend, on la trace.

Revision ID: 023
Revises: 022
Create Date: 2026-11-18
"""
import sqlalchemy as sa
from alembic import op

revision = "023"
down_revision = "022"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("nomenclature", sa.Column("categorie_manuelle", sa.Boolean, nullable=False,
                                            server_default=sa.false()))
    op.create_table(
        "categories_classements",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("par", sa.String(100)),
        sa.Column("seuil_marge", sa.Numeric(5, 2), nullable=False),
        sa.Column("tout_reclasser", sa.Boolean, nullable=False),
        sa.Column("nb_princeps", sa.Integer, nullable=False),
        sa.Column("nb_generique", sa.Integer, nullable=False),
        sa.Column("nb_generique_plus", sa.Integer, nullable=False),
    )
    op.get_bind().execute(sa.text(
        "INSERT INTO reglages_stock (cle, valeur, description) VALUES (:c, :v, :d) ON CONFLICT (cle) DO NOTHING"),
        {"c": "categories_seuil_generique_plus", "v": 50,
         "d": "Prime : marge moyenne des lots (%) au-delà de laquelle un produit est générique++"})


def downgrade() -> None:
    op.execute("DELETE FROM reglages_stock WHERE cle = 'categories_seuil_generique_plus'")
    op.drop_table("categories_classements")
    op.drop_column("nomenclature", "categorie_manuelle")
