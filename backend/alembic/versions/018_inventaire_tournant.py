"""inventaire tournant : liste du jour et comptages

PharmaSuite n'écrit jamais dans EASYPHARM : un comptage vit ici, avec le
stock d'EASYPHARM au moment du comptage, et l'écart reste « à corriger dans
EASYPHARM » jusqu'à ce que quelqu'un le marque corrigé.

- `inventaire_liste` : les produits à compter un jour donné, figés à la
  première lecture du jour (la liste ne bouge plus quand on compte).
- `inventaire_comptages` : un comptage par produit et par jour.
- réglages : nombre de produits par jour et fréquence de comptage par classe.

Revision ID: 018
Revises: 017
Create Date: 2026-11-17
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "018"
down_revision = "017"
branch_labels = None
depends_on = None

_REGLAGES = (
    ("inventaire_par_jour", 20, "Inventaire : produits proposés au comptage chaque jour"),
    ("inventaire_jours_a", 30, "Inventaire : un produit de classe A est recompté tous les N jours"),
    ("inventaire_jours_b", 90, "Inventaire : un produit de classe B est recompté tous les N jours"),
    ("inventaire_jours_c", 180, "Inventaire : un produit de classe C ou non classé est recompté tous les N jours"),
)


def upgrade() -> None:
    op.create_table(
        "inventaire_liste",
        sa.Column("jour", sa.Date, primary_key=True),
        sa.Column("id_nom", sa.BigInteger, primary_key=True),
        sa.Column("rang", sa.Integer, nullable=False),
        sa.Column("raison", sa.String(120), nullable=False),
    )
    op.create_table(
        "inventaire_comptages",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("client_uuid", postgresql.UUID(as_uuid=True), nullable=False, unique=True),
        sa.Column("jour", sa.Date, nullable=False),
        sa.Column("id_nom", sa.BigInteger, nullable=False),
        sa.Column("stock_theorique", sa.Integer, nullable=False),
        sa.Column("stock_compte", sa.Integer, nullable=False),
        sa.Column("ecart", sa.Integer, nullable=False),
        sa.Column("valeur_ecart", sa.Numeric(14, 2), nullable=False, server_default="0"),
        sa.Column("cause", sa.String(20)),
        sa.Column("compte_par", sa.String(100)),
        sa.Column("compte_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("corrige", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("corrige_le", sa.DateTime(timezone=True)),
        sa.Column("corrige_par", sa.String(100)),
        sa.CheckConstraint("stock_compte >= 0", name="ck_inventaire_comptages_compte"),
        sa.CheckConstraint("cause IS NULL OR cause IN ('casse', 'perime', 'saisie', 'vol', 'inconnu')",
                           name="ck_inventaire_comptages_cause"),
        sa.UniqueConstraint("id_nom", "jour", name="uq_inventaire_comptages_produit_jour"),
    )
    op.create_index("ix_inventaire_comptages_jour", "inventaire_comptages", ["jour"])
    conn = op.get_bind()
    for cle, valeur, description in _REGLAGES:
        conn.execute(sa.text(
            "INSERT INTO reglages_stock (cle, valeur, description) VALUES (:c, :v, :d) ON CONFLICT (cle) DO NOTHING"),
            {"c": cle, "v": valeur, "d": description})


def downgrade() -> None:
    op.drop_table("inventaire_comptages")
    op.drop_table("inventaire_liste")
    op.execute("DELETE FROM reglages_stock WHERE cle LIKE 'inventaire\\_%'")
