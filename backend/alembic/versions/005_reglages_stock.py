"""réglages du calcul de stock (période de commande, délais)

Les indicateurs de la fiche produit (stock de sécurité, stock maximum, délai
de livraison) dépendent de quelques constantes propres à l'officine. Elles
vivent en base, modifiables par un administrateur (`PATCH /stock/reglages`),
jamais en dur dans le code :

    periode_commande_jours     7   jours entre deux commandes d'un même produit
                                   (stock max = SS + CMM × période ÷ 30)
    delai_securite_jours       2   stock de sécurité simple = CMJ × ce délai
    delai_livraison_jours      1   délai en jours ouvrés d'un fournisseur sans
                                   délai saisi (fournisseurs.delai_livraison)

Chaque modification garde qui et quand.

Revision ID: 005
Revises: 004
Create Date: 2026-11-11
"""
import sqlalchemy as sa
from alembic import op

revision = "005"
down_revision = "004"
branch_labels = None
depends_on = None

_VALEURS = [
    ("periode_commande_jours", 7, "Jours entre deux commandes d'un même produit"),
    ("delai_securite_jours", 2, "Délai de sécurité du stock de sécurité simple (jours)"),
    ("delai_livraison_jours", 1, "Délai de livraison par défaut, en jours ouvrés"),
]


def upgrade() -> None:
    op.create_table(
        "reglages_stock",
        sa.Column("cle", sa.String(50), primary_key=True),
        sa.Column("valeur", sa.Numeric(10, 2), nullable=False),
        sa.Column("description", sa.String(200)),
        sa.Column("modifie_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("modifie_par", sa.String(100)),
        sa.CheckConstraint("valeur >= 0", name="ck_reglages_stock_valeur_positive"),
    )
    conn = op.get_bind()
    for cle, valeur, description in _VALEURS:
        conn.execute(
            sa.text("INSERT INTO reglages_stock (cle, valeur, description) VALUES (:c, :v, :d)"),
            {"c": cle, "v": valeur, "d": description},
        )


def downgrade() -> None:
    op.drop_table("reglages_stock")
