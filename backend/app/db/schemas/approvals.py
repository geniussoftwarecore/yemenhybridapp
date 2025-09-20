"""Approval schemas for API operations."""
from typing import Optional
from datetime import datetime
from pydantic import BaseModel

from ..models.approval_request import ApprovalChannel


class ApprovalRequestCreate(BaseModel):
    """Schema for creating approval request."""
    sent_via: ApprovalChannel


class ApprovalRequestResponse(BaseModel):
    """Schema for approval request response."""
    id: int
    work_order_id: int
    token: str
    expires_at: datetime
    sent_via: ApprovalChannel
    reason: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class PublicApprovalResponse(BaseModel):
    """Schema for public approval page data."""
    work_order_id: int
    customer_name: str
    vehicle_info: str
    complaint: Optional[str] = None
    est_parts: Optional[str] = None
    est_labor: Optional[str] = None
    est_total: Optional[str] = None
    before_photos: list[str] = []
    is_expired: bool = False


class ApprovalDecision(BaseModel):
    """Schema for approval decision."""
    decision: str  # "approve" or "reject"
    reason: Optional[str] = None