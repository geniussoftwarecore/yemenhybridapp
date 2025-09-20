"""Work order related models."""
from sqlalchemy import Column, Integer, String, ForeignKey, Enum, Numeric, Text, DateTime, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from ..base import Base


class WorkOrderStatus(str, enum.Enum):
    """Work order status enum."""
    NEW = "new"
    AWAITING_APPROVAL = "awaiting_approval"
    READY_TO_START = "ready_to_start"
    IN_PROGRESS = "in_progress"
    DONE = "done"
    CLOSED = "closed"


class ItemType(str, enum.Enum):
    """Work order item type enum."""
    PART = "part"
    LABOR = "labor"


class WorkOrder(Base):
    """Work order model."""
    __tablename__ = "work_orders"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id", ondelete="CASCADE"), nullable=False)
    vehicle_id = Column(Integer, ForeignKey("vehicles.id", ondelete="CASCADE"), nullable=False)
    status = Column(Enum(WorkOrderStatus), nullable=False, default=WorkOrderStatus.NEW, index=True)
    complaint = Column(Text)
    est_parts = Column(Numeric(12, 2))
    est_labor = Column(Numeric(12, 2))
    est_total = Column(Numeric(12, 2))
    final_cost = Column(Numeric(12, 2))
    warranty_text = Column(Text)
    notes = Column(Text)
    scheduled_at = Column(DateTime(timezone=True))
    started_at = Column(DateTime(timezone=True))
    completed_at = Column(DateTime(timezone=True))
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    customer = relationship("Customer", back_populates="work_orders")
    vehicle = relationship("Vehicle", back_populates="work_orders")
    created_by_user = relationship("User", back_populates="work_orders_created", foreign_keys=[created_by])
    items = relationship("WorkOrderItem", back_populates="work_order", cascade="all, delete-orphan")
    media = relationship("Media", back_populates="work_order", cascade="all, delete-orphan")
    services = relationship("WorkOrderService", back_populates="work_order", cascade="all, delete-orphan")
    invoice = relationship("Invoice", back_populates="work_order", uselist=False)
    approval_requests = relationship("ApprovalRequest", back_populates="work_order", cascade="all, delete-orphan")

    __table_args__ = (
        Index('ix_work_orders_status', 'status'),
    )


class WorkOrderItem(Base):
    """Work order item model."""
    __tablename__ = "work_order_items"

    id = Column(Integer, primary_key=True, index=True)
    work_order_id = Column(Integer, ForeignKey("work_orders.id", ondelete="CASCADE"), nullable=False)
    item_type = Column(Enum(ItemType), nullable=False)
    name = Column(String, nullable=False)
    qty = Column(Numeric(10, 2), nullable=False)
    unit_price = Column(Numeric(12, 2), nullable=False)

    # Relationships
    work_order = relationship("WorkOrder", back_populates="items")


class WorkOrderService(Base):
    """Work order service junction table."""
    __tablename__ = "work_order_services"

    id = Column(Integer, primary_key=True, index=True)
    work_order_id = Column(Integer, ForeignKey("work_orders.id", ondelete="CASCADE"), nullable=False)
    service_id = Column(Integer, ForeignKey("services.id", ondelete="CASCADE"), nullable=False)

    # Relationships
    work_order = relationship("WorkOrder", back_populates="services")
    service = relationship("Service", back_populates="work_orders")