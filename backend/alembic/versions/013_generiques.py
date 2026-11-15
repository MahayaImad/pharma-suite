"""génériques d'une même DCI : lesquels commander

Règle arrêtée le 2026-11-15 (app/services/prevision/generiques.py) : les
produits de même code DCI (`nomenclature.de_equiv`) forment un groupe ; une
classe thérapeutique chronique (3 premiers caractères du code présents dans
`classe_maladie`) garde toutes ses marques ; sinon seules les marques les
plus vendues parmi les disponibles sont commandées.

- `generiques_groupes` : mode forcé d'un groupe par le titulaire
  (« toutes » / « quelques »), sinon déduit de la classe.
- `generiques_choix` : choix forcé d'un produit (« garder » / « exclure »).
- réglage `generiques_gardes` : nombre de marques gardées (2).

Revision ID: 013
Revises: 012
Create Date: 2026-11-15
"""
import sqlalchemy as sa
from alembic import op

revision = "013"
down_revision = "012"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "generiques_groupes",
        sa.Column("code", sa.String(20), primary_key=True),
        sa.Column("mode", sa.String(10), nullable=False),
        sa.Column("modifie_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("modifie_par", sa.String(100)),
        sa.CheckConstraint("mode IN ('toutes', 'quelques')", name="ck_generiques_groupes_mode"),
    )
    op.create_table(
        "generiques_choix",
        sa.Column("id_nom", sa.BigInteger, primary_key=True),
        sa.Column("choix", sa.String(10), nullable=False),
        sa.Column("modifie_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("modifie_par", sa.String(100)),
        sa.CheckConstraint("choix IN ('garder', 'exclure')", name="ck_generiques_choix_choix"),
    )
    op.get_bind().execute(sa.text(
        "INSERT INTO reglages_stock (cle, valeur, description) VALUES "
        "('generiques_gardes', 2, 'Marques gardées par DCI non chronique') ON CONFLICT (cle) DO NOTHING"))


def downgrade() -> None:
    op.drop_table("generiques_choix")
    op.drop_table("generiques_groupes")
    op.execute("DELETE FROM reglages_stock WHERE cle = 'generiques_gardes'")
