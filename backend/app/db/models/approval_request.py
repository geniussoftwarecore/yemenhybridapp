"""Approval request model."""
from sqlalchemy import Column, Integer, String, ForeignKey, Enum, DateTime, Text, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from ..base import Base


class ApprovalChannel(str, enum.Enum):
    """Approval channel enum."""
    EMAIL = "email"
    WHATSAPP = "whatsapp"


class ApprovalRequest(Base):
    """Approval request model."""
    __tablename__ = "approval_requests"

    id = Column(Integer, primary_key=True, index=True)
    work_order_id = Column(Integer, ForeignKey("work_orders.id", ondelete="CASCADE"), nullable=False)
    token = Column(String, nullable=False, unique=True, index=True)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    sent_via = Column(Enum(ApprovalChannel), nullable=False)
    reason = Column(Text)  # For rejection reason
    decision = Column(String)  # "approve" or "reject"
    decided_at = Column(DateTime(timezone=True))
    is_used = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    work_order = relationship("WorkOrder", back_populates="approval_requests")