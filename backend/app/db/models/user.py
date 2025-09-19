"""User model."""
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Enum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum
from ..base import Base


class UserRole(str, enum.Enum):
    """User role enum."""
    engineer = "engineer"
    sales = "sales"
    admin = "admin"


class User(Base):
    """User model."""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False, index=True)
    phone = Column(String)
    role = Column(Enum(UserRole, name="userrole", native_enum=True, validate_strings=True), nullable=False)
    password_hash = Column(String, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    work_orders_created = relationship("WorkOrder", back_populates="created_by_user", foreign_keys="WorkOrder.created_by")
    audit_logs = relationship("AuditLog", back_populates="actor")