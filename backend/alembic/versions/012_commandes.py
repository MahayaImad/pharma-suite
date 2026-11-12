"""commandes fournisseurs préparées dans PharmaSuite

PharmaSuite propose et prépare la commande ; EASYPHARM reste l'outil de
réception (e-facture). L'agent ne fait que lire EASYPHARM : une commande
vit donc ici, du brouillon à l'envoi par WhatsApp ou téléphone.

- `fournisseurs_commande` : type de grossiste (pharmaceutique ou
  parapharmaceutique), actif ou non, numéro WhatsApp. Pré-rempli avec les
  fournisseurs livrés depuis 6 mois ; type deviné (pharmaceutique si la
  majorité des produits reçus ont une DCI ou un code CNAS), à corriger.
- `commandes` : une par jour et par fournisseur (hors annulées).
  Statuts : brouillon → validee → envoyee ; annulee.
- `commandes_lignes` : une ligne par produit ; `qte_proposee` NULL pour un
  ajout manuel ; `raison` garde la décomposition du calcul.
- `commandes_valideurs` : employés désignés pour valider, en plus du
  titulaire (rôle admin).
- réglage `budget_mensuel_commandes` (DA, 0 = pas de budget).

`client_uuid` sur commandes et lignes : idempotence du futur hors-ligne.

Revision ID: 012
Revises: 011
Create Date: 2026-11-12
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "012"
down_revision = "011"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "fournisseurs_commande",
        sa.Column("id_fournisseur", sa.BigInteger, primary_key=True),
        sa.Column("type", sa.String(10), nullable=False, server_default="pharma"),
        sa.Column("actif", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("whatsapp", sa.String(30)),
        sa.Column("modifie_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("modifie_par", sa.String(100)),
        sa.CheckConstraint("type IN ('pharma', 'para')", name="ck_fournisseurs_commande_type"),
    )
    op.create_table(
        "commandes",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("client_uuid", postgresql.UUID(as_uuid=True), nullable=False, unique=True),
        sa.Column("jour", sa.Date, nullable=False),
        sa.Column("id_fournisseur", sa.BigInteger, nullable=False),
        sa.Column("statut", sa.String(10), nullable=False, server_default="brouillon"),
        sa.Column("livraison_prevue", sa.Date),
        sa.Column("observation", sa.String(200)),
        sa.Column("cree_par", sa.String(100)),
        sa.Column("cree_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("valide_par", sa.String(100)),
        sa.Column("valide_le", sa.DateTime(timezone=True)),
        sa.Column("envoye_le", sa.DateTime(timezone=True)),
        sa.CheckConstraint("statut IN ('brouillon', 'validee', 'envoyee', 'annulee')", name="ck_commandes_statut"),
    )
    op.create_index("ix_commandes_jour", "commandes", ["jour"])
    op.create_index("uq_commandes_jour_fournisseur", "commandes", ["jour", "id_fournisseur"], unique=True,
                    postgresql_where=sa.text("statut <> 'annulee'"))
    op.create_table(
        "commandes_lignes",
        sa.Column("id", sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("client_uuid", postgresql.UUID(as_uuid=True), nullable=False, unique=True),
        sa.Column("id_commande", sa.BigInteger, sa.ForeignKey("commandes.id", ondelete="CASCADE"), nullable=False),
        sa.Column("id_nom", sa.BigInteger, nullable=False),
        sa.Column("qte", sa.Integer, nullable=False),
        sa.Column("qte_proposee", sa.Integer),
        sa.Column("prix_achat", sa.Numeric(15, 4), nullable=False, server_default="0"),
        sa.Column("raison", postgresql.JSONB),
        sa.Column("modifie_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("modifie_par", sa.String(100)),
        sa.CheckConstraint("qte > 0", name="ck_commandes_lignes_qte"),
        sa.UniqueConstraint("id_commande", "id_nom", name="uq_commandes_lignes_produit"),
    )
    op.create_table(
        "commandes_valideurs",
        sa.Column("username", sa.String(100), primary_key=True),
        sa.Column("ajoute_le", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("ajoute_par", sa.String(100)),
    )
    conn = op.get_bind()
    conn.execute(sa.text(
        "INSERT INTO reglages_stock (cle, valeur, description) VALUES "
        "('budget_mensuel_commandes', 0, 'Budget mensuel des commandes, en DA (0 : pas de budget)') "
        "ON CONFLICT (cle) DO NOTHING"))
    conn.execute(sa.text("""
        INSERT INTO fournisseurs_commande (id_fournisseur, type)
        SELECT ep.id_fournisseur,
               CASE WHEN avg(CASE WHEN COALESCE(n.id_cnas, 0) > 0 OR NULLIF(trim(n.dci), '') IS NOT NULL
                                  THEN 1.0 ELSE 0.0 END) >= 0.5 THEN 'pharma' ELSE 'para' END
        FROM entrees_produits ep
        JOIN nomenclature n ON n.id = ep.id_nom
        WHERE ep.id_fournisseur IS NOT NULL AND ep.date_entree >= current_date - 182
          AND COALESCE(ep.type_entree, '') <> 'AV' AND COALESCE(ep.type_achat, '') <> 'E'
        GROUP BY ep.id_fournisseur
        ON CONFLICT DO NOTHING
    """))


def downgrade() -> None:
    op.drop_table("commandes_valideurs")
    op.drop_table("commandes_lignes")
    op.drop_table("commandes")
    op.drop_table("fournisseurs_commande")
    op.execute("DELETE FROM reglages_stock WHERE cle = 'budget_mensuel_commandes'")
