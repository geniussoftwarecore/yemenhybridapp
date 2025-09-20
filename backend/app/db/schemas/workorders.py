"""Work order schemas for API operations."""
from typing import Optional, List
from datetime import datetime
from decimal import Decimal
from pydantic import BaseModel

from ..models.work_order import WorkOrderStatus, ItemType


class WorkOrderBase(BaseModel):
    """Base work order schema."""
    customer_id: int
    vehicle_id: int
    complaint: Optional[str] = None
    notes: Optional[str] = None


class WorkOrderCreate(WorkOrderBase):
    """Work order creation schema."""
    pass


class WorkOrderUpdate(BaseModel):
    """Work order update schema."""
    customer_id: Optional[int] = None
    vehicle_id: Optional[int] = None
    complaint: Optional[str] = None
    notes: Optional[str] = None


class WorkOrderEstimate(BaseModel):
    """Work order estimate schema."""
    est_parts: Optional[Decimal] = None
    est_labor: Optional[Decimal] = None


class WorkOrderSchedule(BaseModel):
    """Work order schedule schema."""
    scheduled_at: datetime


class WorkOrderItemBase(BaseModel):
    """Base work order item schema."""
    item_type: ItemType
    name: str
    qty: Decimal
    unit_price: Decimal


class WorkOrderItemCreate(WorkOrderItemBase):
    """Work order item creation schema."""
    pass


class WorkOrderItemResponse(WorkOrderItemBase):
    """Work order item response schema."""
    id: int
    work_order_id: int

    class Config:
        from_attributes = True


class WorkOrderResponse(WorkOrderBase):
    """Work order response schema."""
    id: int
    status: WorkOrderStatus
    est_parts: Optional[Decimal] = None
    est_labor: Optional[Decimal] = None
    est_total: Optional[Decimal] = None
    final_cost: Optional[Decimal] = None
    warranty_text: Optional[str] = None
    scheduled_at: Optional[datetime] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    created_by: int
    created_at: datetime
    items: List[WorkOrderItemResponse] = []

    class Config:
        from_attributes = True


class WorkOrderListResponse(BaseModel):
    """Work order list response with pagination."""
    items: List[WorkOrderResponse]
    total: int
    page: int
    size: int
    pages: int


class MediaUploadResponse(BaseModel):
    """Media upload response schema."""
    id: int
    filename: str
    path: str
    phase: str
    note: Optional[str] = None
    url: str

    class Config:
        from_attributes = True


class AuditLogResponse(BaseModel):
    """Audit log response schema."""
    id: int
    actor_id: int
    action: str
    entity: str
    entity_id: Optional[int] = None
    at: datetime
    attachment_url: Optional[str] = None

    class Config:
        from_attributes = True