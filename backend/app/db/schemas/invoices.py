"""Invoice and payment schemas."""
from decimal import Decimal
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel


class InvoiceBase(BaseModel):
    """Base invoice schema."""
    work_order_id: int
    subtotal: Optional[Decimal] = None
    tax: Optional[Decimal] = None
    discount: Optional[Decimal] = None
    total: Optional[Decimal] = None
    paid: Optional[Decimal] = None
    method: Optional[str] = None


class InvoiceCreate(InvoiceBase):
    """Schema for creating invoices."""
    work_order_id: int


class InvoiceUpdate(BaseModel):
    """Schema for updating invoices."""
    subtotal: Optional[Decimal] = None
    tax: Optional[Decimal] = None
    discount: Optional[Decimal] = None
    total: Optional[Decimal] = None
    paid: Optional[Decimal] = None
    method: Optional[str] = None


class InvoiceResponse(InvoiceBase):
    """Schema for invoice responses."""
    id: int
    pdf_path: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class InvoiceListResponse(BaseModel):
    """Schema for listing invoices."""
    invoices: List[InvoiceResponse]
    count: int


class PaymentBase(BaseModel):
    """Base payment schema."""
    invoice_id: int
    amount: Decimal
    method: Optional[str] = None
    ref: Optional[str] = None


class PaymentCreate(PaymentBase):
    """Schema for creating payments."""
    pass


class PaymentResponse(PaymentBase):
    """Schema for payment responses."""
    id: int
    paid_at: datetime

    class Config:
        from_attributes = True