"""Service schemas for API operations."""
from typing import Optional
from decimal import Decimal
from pydantic import BaseModel


class ServiceBase(BaseModel):
    """Base service schema."""
    name: str
    category: Optional[str] = None
    base_price: Optional[Decimal] = None
    est_minutes: Optional[int] = None
    description: Optional[str] = None
    is_active: bool = True


class ServiceCreate(ServiceBase):
    """Service creation schema."""
    pass


class ServiceUpdate(BaseModel):
    """Service update schema."""
    name: Optional[str] = None
    category: Optional[str] = None
    base_price: Optional[Decimal] = None
    est_minutes: Optional[int] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None


class ServiceResponse(ServiceBase):
    """Service response schema."""
    id: int

    class Config:
        from_attributes = True


class ServiceListResponse(BaseModel):
    """Service list response with pagination."""
    items: list[ServiceResponse]
    total: int
    page: int
    size: int
    pages: int