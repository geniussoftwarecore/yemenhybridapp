"""Vehicle model."""
from sqlalchemy import Column, Integer, String, ForeignKey, Index
from sqlalchemy.orm import relationship
from ..base import Base


class Vehicle(Base):
    """Vehicle model."""
    __tablename__ = "vehicles"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id", ondelete="CASCADE"), nullable=False)
    plate_no = Column(String, nullable=False)
    make = Column(String, nullable=False)
    model = Column(String, nullable=False)
    year = Column(Integer)
    vin = Column(String)
    odometer = Column(Integer)
    hybrid_type = Column(String)
    color = Column(String)

    # Relationships
    customer = relationship("Customer", back_populates="vehicles")
    work_orders = relationship("WorkOrder", back_populates="vehicle")
    bookings = relationship("Booking", back_populates="vehicle")

    __table_args__ = (
        Index('ix_vehicles_plate_no', 'plate_no'),
        Index('ix_vehicles_vin', 'vin'),
    )