"""produit lent et cher : commandé à la demande

Constat du 2026-11-16 : le panier proposait de garder en rayon une ordonnance
de produits rares et chers (Menopur 53 000 DA, Decapeptyl, Cetrotide…), que
l'officine commande seulement quand le patient vient. Réglage
`lent_valeur_max_da` (5 000) : un produit lent dont une ordonnance vaut plus
n'est plus gardé en stock (sauf s'il est en tension confirmée).

Revision ID: 015
Revises: 014
Create Date: 2026-11-16
"""
import sqlalchemy as sa
from alembic import op

revision = "015"
down_revision = "014"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.get_bind().execute(sa.text(
        "INSERT INTO reglages_stock (cle, valeur, description) VALUES ('lent_valeur_max_da', 5000, "
        "'Produit lent : au-delà de cette valeur par ordonnance (DA), commandé à la demande') "
        "ON CONFLICT (cle) DO NOTHING"))


def downgrade() -> None:
    op.execute("DELETE FROM reglages_stock WHERE cle = 'lent_valeur_max_da'")
