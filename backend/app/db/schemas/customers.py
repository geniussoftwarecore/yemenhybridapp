"""Customer schemas for API operations."""
from typing import Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr


class CustomerBase(BaseModel):
    """Base customer schema."""
    name: str
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    address: Optional[str] = None


class CustomerCreate(CustomerBase):
    """Customer creation schema."""
    pass


class CustomerUpdate(BaseModel):
    """Customer update schema."""
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    address: Optional[str] = None


class CustomerResponse(CustomerBase):
    """Customer response schema."""
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class CustomerListResponse(BaseModel):
    """Customer list response with pagination."""
    items: list[CustomerResponse]
    total: int
    page: int
    size: int
    pages: int