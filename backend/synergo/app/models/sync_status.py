from sqlalchemy import BigInteger, Column, DateTime, Integer, String
from sqlalchemy.sql import func
from app.models.base import Base


class SyncStatus(Base):
    """Suivi de la progression de synchronisation par table."""

    __tablename__ = "sync_status"

    id = Column(BigInteger, primary_key=True, autoincrement=True)
    table_name = Column(String(100), unique=True, nullable=False, index=True)
    last_id = Column(BigInteger, default=0, nullable=False)
    total_synced = Column(Integer, default=0, nullable=False)
    last_sync_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
