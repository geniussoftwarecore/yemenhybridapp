"""Service and parts models."""
from sqlalchemy import Column, Integer, String, Numeric, Boolean, Text
from sqlalchemy.orm import relationship
from ..base import Base


class Service(Base):
    """Service model."""
    __tablename__ = "services"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    category = Column(String)
    base_price = Column(Numeric(12, 2))
    est_minutes = Column(Integer)
    description = Column(Text)
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    work_orders = relationship("WorkOrderService", back_populates="service")
    bookings = relationship("Booking", back_populates="service")


class Part(Base):
    """Part model."""
    __tablename__ = "parts"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    part_no = Column(String)
    supplier = Column(String)
    stock = Column(Integer)
    min_stock = Column(Integer)
    buy_price = Column(Numeric(12, 2))
    sell_price = Column(Numeric(12, 2))
    location = Column(String)