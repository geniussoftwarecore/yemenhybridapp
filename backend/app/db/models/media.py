"""Media model."""
from sqlalchemy import Column, Integer, String, ForeignKey, Enum, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from ..base import Base


class MediaPhase(str, enum.Enum):
    """Media phase enum."""
    BEFORE = "before"
    DURING = "during"
    AFTER = "after"


class Media(Base):
    """Media model."""
    __tablename__ = "media"

    id = Column(Integer, primary_key=True, index=True)
    work_order_id = Column(Integer, ForeignKey("work_orders.id", ondelete="CASCADE"), nullable=False)
    phase = Column(Enum(MediaPhase), nullable=False)
    path = Column(String, nullable=False)
    mime = Column(String)
    note = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    work_order = relationship("WorkOrder", back_populates="media")