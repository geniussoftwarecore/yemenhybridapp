"""Public API endpoints (no authentication required)."""
import os
from datetime import datetime, timezone
from decimal import Decimal
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query, Request, Form
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..core.deps import get_db
from ..core.config import settings
from ..db.models import Customer, Vehicle
from ..db.models.work_order import WorkOrder, WorkOrderStatus
from ..db.models.media import Media, MediaPhase
from ..db.models.approval_request import ApprovalRequest
from ..db.schemas import PublicApprovalResponse, ApprovalDecision
from ..services.audit import log_action

router = APIRouter(prefix="/public", tags=["Public"])

# Set up Jinja2 templates
templates = Jinja2Templates(directory="templates")

@router.get("/approve/{token}", response_class=HTMLResponse)
async def get_approval_page(
    request: Request,
    token: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Render minimal HTML page for customer approval.
    Shows work order summary, estimate, and BEFORE/diagnostic photos.
    """
    # Get approval request by token
    approval_query = select(ApprovalRequest).where(ApprovalRequest.token == token)
    approval_result = await db.execute(approval_query)
    approval_request = approval_result.scalar_one_or_none()
    
    if not approval_request:
        raise HTTPException(status_code=404, detail="Approval request not found")
    
    # Check if token has expired or already used
    is_expired = datetime.now(timezone.utc) > approval_request.expires_at or approval_request.is_used
    
    # Get work order with related data
    workorder_query = (
        select(WorkOrder)
        .options(
            selectinload(WorkOrder.customer),
            selectinload(WorkOrder.vehicle),
            selectinload(WorkOrder.media)
        )
        .where(WorkOrder.id == approval_request.work_order_id)
    )
    workorder_result = await db.execute(workorder_query)
    workorder = workorder_result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(status_code=404, detail="Work order not found")
    
    # Get BEFORE photos - use public media access with token
    before_photos = []
    for media in workorder.media:
        if media.phase == MediaPhase.BEFORE:
            before_photos.append(f"/public/media/{token}/{media.path}")
    
    # Format currency values
    est_parts = f"${workorder.est_parts:.2f}" if workorder.est_parts else "N/A"
    est_labor = f"${workorder.est_labor:.2f}" if workorder.est_labor else "N/A"
    est_total = f"${workorder.est_total:.2f}" if workorder.est_total else "N/A"
    
    # Create vehicle info string
    vehicle_info = f"{workorder.vehicle.year} {workorder.vehicle.make} {workorder.vehicle.model} ({workorder.vehicle.plate_no})"
    
    approval_data = PublicApprovalResponse(
        work_order_id=workorder.id,
        customer_name=workorder.customer.name,
        vehicle_info=vehicle_info,
        complaint=workorder.complaint,
        est_parts=est_parts,
        est_labor=est_labor,
        est_total=est_total,
        before_photos=before_photos,
        is_expired=is_expired
    )
    
    return templates.TemplateResponse(
        "approval.html",
        {
            "request": request,
            "token": token,
            "approval": approval_data,
            "is_expired": is_expired
        }
    )

@router.post("/approve/{token}")
async def submit_approval_decision(
    token: str,
    decision: str = Form(...),
    reason: str = Form(default=""),
    db: AsyncSession = Depends(get_db)
):
    """
    Handle customer approval decision (approve/reject).
    """
    if decision not in ["approve", "reject"]:
        raise HTTPException(status_code=400, detail="Invalid decision. Must be 'approve' or 'reject'")
    
    # Get approval request by token
    approval_query = select(ApprovalRequest).where(ApprovalRequest.token == token)
    approval_result = await db.execute(approval_query)
    approval_request = approval_result.scalar_one_or_none()
    
    if not approval_request:
        raise HTTPException(status_code=404, detail="Approval request not found")
    
    # Check if token has expired or already used
    if datetime.now(timezone.utc) > approval_request.expires_at:
        raise HTTPException(status_code=400, detail="Approval request has expired")
    
    if approval_request.is_used:
        raise HTTPException(status_code=400, detail="Approval request has already been used")
    
    # Get work order
    workorder_query = select(WorkOrder).where(WorkOrder.id == approval_request.work_order_id)
    workorder_result = await db.execute(workorder_query)
    workorder = workorder_result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(status_code=404, detail="Work order not found")
    
    # Mark approval request as used and record decision
    approval_request.is_used = True
    approval_request.decision = decision
    approval_request.decided_at = datetime.now(timezone.utc)
    if reason:
        approval_request.reason = reason
    
    # Update work order status based on decision
    if decision == "approve":
        workorder.status = WorkOrderStatus.READY_TO_START
        action = "CUSTOMER_APPROVE"
    else:
        workorder.status = WorkOrderStatus.NEW
        action = "CUSTOMER_REJECT"
    
    # Log audit entry (no user, so we'll use None for actor_id)
    from ..db.models.audit_log import AuditLog
    audit_entry = AuditLog(
        actor_id=None,  # Customer action, no user
        action=action,
        entity="work_order",
        entity_id=workorder.id,
        attachment_url=None
    )
    db.add(audit_entry)
    
    await db.commit()
    
    # Return success response
    return {
        "message": f"Work order {decision}d successfully",
        "work_order_id": workorder.id,
        "status": workorder.status.value
    }

@router.get("/media/{token}/{path:path}")
async def get_public_media(
    token: str,
    path: str,
    db: AsyncSession = Depends(get_db)
):
    """Get media file for public approval (token-protected access to BEFORE photos)."""
    # Verify token exists and is valid
    approval_query = select(ApprovalRequest).where(ApprovalRequest.token == token)
    approval_result = await db.execute(approval_query)
    approval_request = approval_result.scalar_one_or_none()
    
    if not approval_request:
        raise HTTPException(status_code=404, detail="Invalid approval token")
    
    # Check if token has expired (allow access to used tokens for reference)
    if datetime.now(timezone.utc) > approval_request.expires_at:
        raise HTTPException(status_code=404, detail="Approval link has expired")
    
    # Verify media exists and belongs to the work order
    media_query = (
        select(Media)
        .where(Media.path == path)
        .where(Media.work_order_id == approval_request.work_order_id)
        .where(Media.phase == MediaPhase.BEFORE)  # Only allow BEFORE photos
    )
    media_result = await db.execute(media_query)
    media = media_result.scalar_one_or_none()
    
    if not media:
        raise HTTPException(status_code=404, detail="Media not found or access denied")
    
    # Build full file path
    from ..core.config import settings
    file_path = os.path.join(settings.storage_dir, path)
    
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    
    from fastapi.responses import FileResponse
    return FileResponse(file_path, filename=os.path.basename(path))