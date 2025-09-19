"""Part schemas for API operations."""
from typing import Optional
from decimal import Decimal
from pydantic import BaseModel


class PartBase(BaseModel):
    """Base part schema."""
    name: str
    part_no: Optional[str] = None
    supplier: Optional[str] = None
    stock: Optional[int] = 0
    min_stock: Optional[int] = 0
    buy_price: Optional[Decimal] = None
    sell_price: Optional[Decimal] = None
    location: Optional[str] = None


class PartCreate(PartBase):
    """Part creation schema."""
    pass


class PartUpdate(BaseModel):
    """Part update schema."""
    name: Optional[str] = None
    part_no: Optional[str] = None
    supplier: Optional[str] = None
    stock: Optional[int] = None
    min_stock: Optional[int] = None
    buy_price: Optional[Decimal] = None
    sell_price: Optional[Decimal] = None
    location: Optional[str] = None


class PartStockAdjustment(BaseModel):
    """Part stock adjustment schema."""
    delta: int  # positive for adding stock, negative for removing


class PartResponse(PartBase):
    """Part response schema."""
    id: int

    class Config:
        from_attributes = True


class PartListResponse(BaseModel):
    """Part list response with pagination."""
    items: list[PartResponse]
    total: int
    page: int
    size: int
    pages: int