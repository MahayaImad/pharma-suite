"""garde 24 h du 30/09/2026 (et non du 01/10)

La migration 006 avait enregistré la garde 24 h donnée par l'officine au
2026-10-01. L'officine a confirmé le 2026-11-12 qu'elle a couru du mercredi
30/09 au matin au jeudi 01/10 au matin : les ventes de la nuit sont datées du
01/10, la garde est celle du 30/09. Une garde se date du jour où elle
commence (docs/BUSINESS_LOGIC.md §3.7).

La garde du 30/09, si la détection l'a déjà enregistrée, devient saisie et
confirmée ; celle du 01/10 est retirée.

Revision ID: 008
Revises: 007
Create Date: 2026-11-12
"""
from alembic import op

revision = "008"
down_revision = "007"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        DELETE FROM gardes
        WHERE date = '2026-10-01' AND type = '24h' AND source = 'saisie'
    """)
    op.execute("""
        INSERT INTO gardes (date, type, source, confirme, note, modifie_par)
        VALUES ('2026-09-30', '24h', 'saisie', true,
                'du 30/09 au matin au 01/10 au matin, confirmé par l''officine', 'migration 008')
        ON CONFLICT (date) DO UPDATE SET
            type = '24h', source = 'saisie', confirme = true,
            note = EXCLUDED.note, modifie_le = now(), modifie_par = EXCLUDED.modifie_par
    """)


def downgrade() -> None:
    op.execute("DELETE FROM gardes WHERE date = '2026-09-30' AND modifie_par = 'migration 008'")
    op.execute("""
        INSERT INTO gardes (date, type, source, confirme, note)
        VALUES ('2026-10-01', '24h', 'saisie', true, 'donnée par l''officine')
        ON CONFLICT (date) DO NOTHING
    """)
