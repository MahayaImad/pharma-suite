"""produits consommables (donnés, jamais vendus)

Certains produits sont achetés mais jamais vendus : donnés gratuitement
(aiguilles Insupen, sachets, lecteurs de glycémie…) puis remis à zéro par un
ajustement d'inventaire (docs/BUSINESS_LOGIC.md §3.4). Ce ne sont ni des
pertes ni des ventes : leur consommation se lit dans les ajustements.

`produits_consommables` (propre à PharmaSuite, hors miroir EASYPHARM) :

    consommable  true : le produit est un consommable
    confirme     false : proposé par la détection, à confirmer par le
                 titulaire ; true : décidé (oui ou non), jamais reproposé

Pré-remplie avec les produits jamais vendus mais ajustés à la baisse sur
12 mois (44 sur la base réelle le 2026-11-12), proposés.

Revision ID: 011
Revises: 010
Create Date: 2026-11-12
"""
import sqlalchemy as sa
from alembic import op

revision = "011"
down_revision = "010"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "produits_consommables",
        sa.Column("id_nom", sa.BigInteger, primary_key=True),
        sa.Column("consommable", sa.Boolean, nullable=False),
        sa.Column("confirme", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("source", sa.String(10), nullable=False, server_default="saisie"),
        sa.Column("modifie_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("modifie_par", sa.String(100)),
        sa.CheckConstraint("source IN ('saisie', 'detection')", name="ck_consommables_source"),
    )
    # Proposés : jamais vendus, ajustés à la baisse sur 12 mois. La ligne
    # d'inventaire désigne son lot par id_produit (= entrees_produits.id).
    op.execute("""
        INSERT INTO produits_consommables (id_nom, consommable, confirme, source)
        SELECT DISTINCT e.id_nom, true, false, 'detection'
        FROM inventaires_produits ip
        JOIN entrees_produits e ON e.id = ip.id_produit
        WHERE ip.date > CURRENT_DATE - INTERVAL '12 months' AND ip.ecart < 0
          AND NOT EXISTS (SELECT 1 FROM sorties_produits sp WHERE sp.id_nom = e.id_nom AND sp.qte_sortie > 0)
        ON CONFLICT (id_nom) DO NOTHING
    """)


def downgrade() -> None:
    op.drop_table("produits_consommables")
