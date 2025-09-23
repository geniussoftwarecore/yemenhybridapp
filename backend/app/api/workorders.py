import os
import time
import uuid
import secrets
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status, File, UploadFile, Form
from fastapi.responses import FileResponse
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
import math

from ..core.deps import get_db, get_current_user, require_roles
from ..core.config import settings
from ..db.models import User, UserRole, Customer, Vehicle
from ..db.models.work_order import WorkOrder, WorkOrderStatus, WorkOrderItem, ItemType
from ..db.models.media import Media, MediaPhase
from ..db.models.approval_request import ApprovalRequest, ApprovalChannel
from ..db.schemas import (
    WorkOrderCreate,
    WorkOrderUpdate, 
    WorkOrderResponse,
    WorkOrderListResponse,
    WorkOrderEstimate,
    WorkOrderSchedule,
    WorkOrderItemCreate,
    WorkOrderItemResponse,
    MediaUploadResponse,
    ApprovalRequestCreate,
    ApprovalRequestResponse
)
from ..services.audit import log_action
from ..services.notify import notify

import logging
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/workorders", tags=["Work Orders"])

@router.get("/", response_model=WorkOrderListResponse)
async def get_workorders(
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(10, ge=1, le=100, description="Page size"),
    status: Optional[WorkOrderStatus] = Query(None, description="Filter by status"),
    customer_id: Optional[int] = Query(None, description="Filter by customer ID"),
    vehicle_id: Optional[int] = Query(None, description="Filter by vehicle ID"),
    technician_id: Optional[int] = Query(None, description="Filter by technician ID (created_by)"),
    date_from: Optional[datetime] = Query(None, description="Filter by creation date from"),
    date_to: Optional[datetime] = Query(None, description="Filter by creation date to"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all work orders with pagination and filtering.
    
    - **page**: Page number (starts from 1)
    - **size**: Number of items per page (max 100)
    - **status**: Filter by work order status
    - **customer_id**: Filter by customer ID
    - **vehicle_id**: Filter by vehicle ID
    - **technician_id**: Filter by technician (created_by user)
    - **date_from**: Filter by creation date from
    - **date_to**: Filter by creation date to
    """
    # Build query
    query = select(WorkOrder).options(selectinload(WorkOrder.items))
    count_query = select(func.count(WorkOrder.id))
    
    # Add filters
    if status:
        query = query.where(WorkOrder.status == status)
        count_query = count_query.where(WorkOrder.status == status)
    
    if customer_id:
        query = query.where(WorkOrder.customer_id == customer_id)
        count_query = count_query.where(WorkOrder.customer_id == customer_id)
    
    if vehicle_id:
        query = query.where(WorkOrder.vehicle_id == vehicle_id)
        count_query = count_query.where(WorkOrder.vehicle_id == vehicle_id)
    
    if technician_id:
        query = query.where(WorkOrder.created_by == technician_id)
        count_query = count_query.where(WorkOrder.created_by == technician_id)
    
    if date_from:
        query = query.where(WorkOrder.created_at >= date_from)
        count_query = count_query.where(WorkOrder.created_at >= date_from)
    
    if date_to:
        query = query.where(WorkOrder.created_at <= date_to)
        count_query = count_query.where(WorkOrder.created_at <= date_to)
    
    # Get total count
    total_result = await db.execute(count_query)
    total = total_result.scalar()
    
    # Apply pagination
    offset = (page - 1) * size
    query = query.offset(offset).limit(size).order_by(WorkOrder.id.desc())
    
    # Execute query
    result = await db.execute(query)
    workorders = result.scalars().all()
    
    # Calculate pagination info
    pages = math.ceil(total / size) if total > 0 else 1
    
    return WorkOrderListResponse(
        items=workorders,
        total=total,
        page=page,
        size=size,
        pages=pages
    )

@router.post("/", response_model=WorkOrderResponse, status_code=status.HTTP_201_CREATED)
async def create_workorder(
    workorder_data: WorkOrderCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create new work order with status=new.
    
    - **customer_id**: Customer ID (required, must exist)
    - **vehicle_id**: Vehicle ID (required, must exist)
    - **complaint**: Customer complaint description
    - **notes**: Additional notes
    """
    # Verify customer exists
    customer_query = select(Customer).where(Customer.id == workorder_data.customer_id)
    customer_result = await db.execute(customer_query)
    customer = customer_result.scalar_one_or_none()
    
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Customer not found"
        )
    
    # Verify vehicle exists
    vehicle_query = select(Vehicle).where(Vehicle.id == workorder_data.vehicle_id)
    vehicle_result = await db.execute(vehicle_query)
    vehicle = vehicle_result.scalar_one_or_none()
    
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Vehicle not found"
        )
    
    # Create work order
    workorder = WorkOrder(
        **workorder_data.model_dump(),
        status=WorkOrderStatus.NEW,
        created_by=current_user.id
    )
    db.add(workorder)
    await db.flush()
    
    # Log audit entry
    await log_action(
        db, current_user, "CREATE", "work_order", workorder.id
    )
    
    await db.commit()
    await db.refresh(workorder)
    
    return workorder

@router.get("/{workorder_id}", response_model=WorkOrderResponse)
async def get_workorder(
    workorder_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get work order by ID."""
    query = select(WorkOrder).options(selectinload(WorkOrder.items)).where(WorkOrder.id == workorder_id)
    result = await db.execute(query)
    workorder = result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order not found"
        )
    
    return workorder

@router.patch("/{workorder_id}/estimate", response_model=WorkOrderResponse)
async def set_workorder_estimate(
    workorder_id: int,
    estimate_data: WorkOrderEstimate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Set work order estimate (est_parts, est_labor -> est_total).
    
    Automatically calculates est_total as sum of est_parts and est_labor.
    """
    # Get work order
    query = select(WorkOrder).where(WorkOrder.id == workorder_id)
    result = await db.execute(query)
    workorder = result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order not found"
        )
    
    # Update estimates
    if estimate_data.est_parts is not None:
        workorder.est_parts = estimate_data.est_parts
    if estimate_data.est_labor is not None:
        workorder.est_labor = estimate_data.est_labor
    
    # Calculate total
    est_parts = workorder.est_parts or Decimal('0')
    est_labor = workorder.est_labor or Decimal('0')
    workorder.est_total = est_parts + est_labor
    
    # Log audit entry
    await log_action(
        db, current_user, "UPDATE_ESTIMATE", "work_order", workorder.id
    )
    
    await db.commit()
    await db.refresh(workorder)
    
    return workorder

@router.patch("/{workorder_id}/schedule", response_model=WorkOrderResponse)
async def schedule_workorder(
    workorder_id: int,
    schedule_data: WorkOrderSchedule,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Set work order scheduled date/time."""
    # Get work order
    query = select(WorkOrder).where(WorkOrder.id == workorder_id)
    result = await db.execute(query)
    workorder = result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order not found"
        )
    
    # Update scheduled time
    workorder.scheduled_at = schedule_data.scheduled_at
    
    # Log audit entry
    await log_action(
        db, current_user, "SCHEDULE", "work_order", workorder.id
    )
    
    await db.commit()
    await db.refresh(workorder)
    
    return workorder

@router.patch("/{workorder_id}/start", response_model=WorkOrderResponse)
async def start_workorder(
    workorder_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Start work order (allowed only if status=ready_to_start)."""
    # Get work order
    query = select(WorkOrder).where(WorkOrder.id == workorder_id)
    result = await db.execute(query)
    workorder = result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order not found"
        )
    
    # Check status
    if workorder.status != WorkOrderStatus.READY_TO_START:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Work order must be in 'ready_to_start' status to start. Current status: {workorder.status}"
        )
    
    # Update status and started time
    workorder.status = WorkOrderStatus.IN_PROGRESS
    workorder.started_at = datetime.utcnow()
    
    # Log audit entry
    await log_action(
        db, current_user, "START", "work_order", workorder.id
    )
    
    await db.commit()
    await db.refresh(workorder)
    
    return workorder

@router.patch("/{workorder_id}/finish", response_model=WorkOrderResponse)
async def finish_workorder(
    workorder_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Finish work order (set status=done, set completed_at)."""
    # Get work order
    query = select(WorkOrder).where(WorkOrder.id == workorder_id)
    result = await db.execute(query)
    workorder = result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order not found"
        )
    
    # Update status and completion time
    workorder.status = WorkOrderStatus.DONE
    workorder.completed_at = datetime.utcnow()
    
    # Log audit entry
    await log_action(
        db, current_user, "FINISH", "work_order", workorder.id
    )
    
    await db.commit()
    await db.refresh(workorder)
    
    # Send pickup notification
    await _send_pickup_notification(workorder, db)
    
    return workorder

@router.patch("/{workorder_id}/close", response_model=WorkOrderResponse)
async def close_workorder(
    workorder_id: int,
    current_user: User = Depends(require_roles(UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Close work order (admin only, status=closed)."""
    # Get work order
    query = select(WorkOrder).where(WorkOrder.id == workorder_id)
    result = await db.execute(query)
    workorder = result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order not found"
        )
    
    # Update status
    workorder.status = WorkOrderStatus.CLOSED
    
    # Log audit entry
    await log_action(
        db, current_user, "CLOSE", "work_order", workorder.id
    )
    
    await db.commit()
    await db.refresh(workorder)
    
    return workorder

@router.post("/{workorder_id}/items", response_model=WorkOrderItemResponse, status_code=status.HTTP_201_CREATED)
async def add_workorder_item(
    workorder_id: int,
    item_data: WorkOrderItemCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Add part/labor item to work order."""
    # Verify work order exists
    workorder_query = select(WorkOrder).where(WorkOrder.id == workorder_id)
    workorder_result = await db.execute(workorder_query)
    workorder = workorder_result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order not found"
        )
    
    # Create item
    item = WorkOrderItem(
        work_order_id=workorder_id,
        **item_data.model_dump()
    )
    db.add(item)
    
    # Log audit entry
    await log_action(
        db, current_user, f"ADD_{item_data.item_type.value.upper()}_ITEM", "work_order", workorder_id
    )
    
    await db.commit()
    await db.refresh(item)
    
    return item

@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_workorder_item(
    item_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete work order item."""
    # Get item
    query = select(WorkOrderItem).where(WorkOrderItem.id == item_id)
    result = await db.execute(query)
    item = result.scalar_one_or_none()
    
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order item not found"
        )
    
    # Log audit entry
    await log_action(
        db, current_user, f"DELETE_{item.item_type.value.upper()}_ITEM", "work_order", item.work_order_id
    )
    
    # Delete item
    await db.delete(item)
    await db.commit()

@router.post("/{workorder_id}/media", response_model=MediaUploadResponse, status_code=status.HTTP_201_CREATED)
async def upload_workorder_media(
    workorder_id: int,
    file: UploadFile = File(...),
    phase: str = Form(..., regex="^(before|during|after)$"),
    note: Optional[str] = Form(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Upload media file for work order.
    
    - **file**: Media file to upload
    - **phase**: Media phase (before|during|after)
    - **note**: Optional note about the media
    """
    # Verify work order exists
    workorder_query = select(WorkOrder).where(WorkOrder.id == workorder_id)
    workorder_result = await db.execute(workorder_query)
    workorder = workorder_result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order not found"
        )
    
    # Generate unique filename
    timestamp = int(time.time())
    file_ext = os.path.splitext(file.filename)[1] if file.filename else ""
    unique_filename = f"{timestamp}_{uuid.uuid4().hex[:8]}{file_ext}"
    
    # Create directory structure
    media_dir = os.path.join(settings.storage_dir, "workorders", str(workorder_id), phase)
    os.makedirs(media_dir, exist_ok=True)
    
    # Save file
    file_path = os.path.join(media_dir, unique_filename)
    with open(file_path, "wb") as buffer:
        content = await file.read()
        buffer.write(content)
    
    # Create media record
    relative_path = f"workorders/{workorder_id}/{phase}/{unique_filename}"
    media = Media(
        work_order_id=workorder_id,
        path=relative_path,
        phase=MediaPhase(phase),
        note=note
    )
    db.add(media)
    
    # Log audit entry
    await log_action(
        db, current_user, f"UPLOAD_{phase.upper()}_MEDIA", "work_order", workorder_id
    )
    
    await db.commit()
    await db.refresh(media)
    
    # Generate URL
    media_url = f"/api/v1/media/{relative_path}"
    
    return MediaUploadResponse(
        id=media.id,
        filename=file.filename or unique_filename,
        path=media.path,
        phase=media.phase.value,
        note=media.note,
        url=media_url
    )

@router.get("/media/{path:path}")
async def get_media(
    path: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get protected media file for internal use."""
    # Verify media exists in database
    query = select(Media).where(Media.path == path)
    result = await db.execute(query)
    media = result.scalar_one_or_none()
    
    if not media:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Media not found"
        )
    
    # Build full file path
    file_path = os.path.join(settings.storage_dir, path)
    
    if not os.path.exists(file_path):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="File not found on disk"
        )
    
    return FileResponse(file_path, filename=os.path.basename(media.path))

@router.put("/{workorder_id}", response_model=WorkOrderResponse)
async def update_workorder(
    workorder_id: int,
    workorder_data: WorkOrderUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update work order basic information."""
    # Get work order
    query = select(WorkOrder).where(WorkOrder.id == workorder_id)
    result = await db.execute(query)
    workorder = result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order not found"
        )
    
    # Update fields
    update_data = workorder_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(workorder, field, value)
    
    # Log audit entry
    await log_action(
        db, current_user, "UPDATE", "work_order", workorder.id
    )
    
    await db.commit()
    await db.refresh(workorder)
    
    return workorder

@router.post("/{workorder_id}/request-approval", response_model=WorkOrderResponse)
async def request_workorder_approval(
    workorder_id: int,
    current_user: User = Depends(require_roles(UserRole.engineer)),
    db: AsyncSession = Depends(get_db)
):
    """Engineer request approval for work order (change status to awaiting_approval)."""
    # Get work order
    query = select(WorkOrder).where(WorkOrder.id == workorder_id)
    result = await db.execute(query)
    workorder = result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order not found"
        )
    
    # Update status to awaiting approval
    workorder.status = WorkOrderStatus.AWAITING_APPROVAL
    
    # Log audit entry
    await log_action(
        db, current_user, "REQUEST_APPROVAL", "work_order", workorder.id
    )
    
    await db.commit()
    await db.refresh(workorder)
    
    return workorder

@router.post("/{workorder_id}/send-to-customer", response_model=ApprovalRequestResponse, status_code=status.HTTP_201_CREATED)
async def send_approval_to_customer(
    workorder_id: int,
    approval_data: ApprovalRequestCreate,
    current_user: User = Depends(require_roles(UserRole.sales, UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Send approval request to customer (sales/admin only). Creates approval token and record."""
    # Verify work order exists
    workorder_query = select(WorkOrder).where(WorkOrder.id == workorder_id)
    workorder_result = await db.execute(workorder_query)
    workorder = workorder_result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order not found"
        )
    
    # Generate secure token (24 hour expiry)
    token = secrets.token_urlsafe(32)
    expires_at = datetime.now(timezone.utc) + timedelta(hours=24)
    
    # Create approval request
    approval_request = ApprovalRequest(
        work_order_id=workorder_id,
        token=token,
        expires_at=expires_at,
        sent_via=approval_data.sent_via
    )
    db.add(approval_request)
    
    # Log audit entry
    await log_action(
        db, current_user, f"SEND_APPROVAL_{approval_data.sent_via.value.upper()}", "work_order", workorder_id
    )
    
    await db.commit()
    await db.refresh(approval_request)
    
    # Send approval notification
    await _send_approval_notification(workorder, approval_request, db)
    
    return approval_request

@router.delete("/{workorder_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_workorder(
    workorder_id: int,
    current_user: User = Depends(require_roles(UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Delete work order. Admin only."""
    # Get work order
    query = select(WorkOrder).where(WorkOrder.id == workorder_id)
    result = await db.execute(query)
    workorder = result.scalar_one_or_none()
    
    if not workorder:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order not found"
        )
    
    # Log audit entry
    await log_action(
        db, current_user, "DELETE", "work_order", workorder.id
    )
    
    # Delete work order (cascades to items, media, etc.)
    await db.delete(workorder)
    await db.commit()


# Helper functions for notifications
async def _send_approval_notification(workorder: WorkOrder, approval_request: ApprovalRequest, db: AsyncSession):
    """Send approval notification to customer."""
    try:
        # Get customer with related data
        customer_query = (
            select(Customer)
            .options(selectinload(Customer.vehicles))
            .where(Customer.id == workorder.customer_id)
        )
        customer_result = await db.execute(customer_query)
        customer = customer_result.scalar_one_or_none()
        
        if not customer:
            logger.error(f"Customer not found for work order {workorder.id}")
            return
        
        # Get vehicle info
        vehicle_query = select(Vehicle).where(Vehicle.id == workorder.vehicle_id)
        vehicle_result = await db.execute(vehicle_query)
        vehicle = vehicle_result.scalar_one_or_none()
        
        if not vehicle:
            logger.error(f"Vehicle not found for work order {workorder.id}")
            return
        
        # Get the domain for URL generation
        domain = os.getenv('REPLIT_DEV_DOMAIN', 'localhost:5000')
        protocol = 'https' if not domain.startswith('localhost') else 'http'
        approval_url = f"{protocol}://{domain}/public/approve/{approval_request.token}"
        
        # Format estimates
        est_total = f"${workorder.est_total:.2f}" if workorder.est_total else "TBD"
        vehicle_info = f"{vehicle.year} {vehicle.make} {vehicle.model} ({vehicle.plate_no})"
        
        # Send notification based on channel
        if approval_request.sent_via == ApprovalChannel.EMAIL:
            if customer.email:
                subject = f"Service Approval Required - Work Order #{workorder.id}"
                html = f"""
                <html>
                <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #007bff;">Yemen Hybrid Service Center</h2>
                    <h3>Service Approval Required</h3>
                    
                    <p>Dear {customer.name},</p>
                    
                    <p>Your vehicle service estimate is ready for approval:</p>
                    
                    <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <p><strong>Vehicle:</strong> {vehicle_info}</p>
                        <p><strong>Work Order #:</strong> {workorder.id}</p>
                        <p><strong>Issue:</strong> {workorder.complaint or 'Service required'}</p>
                        <p><strong>Total Estimate:</strong> <span style="font-size: 18px; color: #007bff;">{est_total}</span></p>
                    </div>
                    
                    <p>Please click the link below to review the details and approve or decline the service:</p>
                    
                    <p style="text-align: center; margin: 30px 0;">
                        <a href="{approval_url}" style="background: #007bff; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;">
                            Review & Approve Service
                        </a>
                    </p>
                    
                    <p><small>This link will expire in 24 hours. If you have any questions, please contact us.</small></p>
                    
                    <p>Best regards,<br>Yemen Hybrid Service Center</p>
                </body>
                </html>
                """
                await notify.send_email(customer.email, subject, html)
            else:
                logger.warning(f"Customer {customer.id} has no email address for approval notification")
        
        elif approval_request.sent_via == ApprovalChannel.WHATSAPP:
            if customer.phone:
                text = f"""
🔧 *Yemen Hybrid Service Center*

Dear {customer.name},

Your vehicle service estimate is ready for approval:

*Vehicle:* {vehicle_info}
*Work Order #:* {workorder.id}
*Issue:* {workorder.complaint or 'Service required'}
*Total Estimate:* {est_total}

Please review and approve: {approval_url}

This link expires in 24 hours.
                """.strip()
                await notify.send_whatsapp(customer.phone, text)
            else:
                logger.warning(f"Customer {customer.id} has no phone number for WhatsApp notification")
    
    except Exception as e:
        logger.error(f"Failed to send approval notification for work order {workorder.id}: {str(e)}")


async def _send_pickup_notification(workorder: WorkOrder, db: AsyncSession):
    """Send pickup notification to customer with AFTER photos."""
    try:
        # Get customer
        customer_query = select(Customer).where(Customer.id == workorder.customer_id)
        customer_result = await db.execute(customer_query)
        customer = customer_result.scalar_one_or_none()
        
        if not customer:
            logger.error(f"Customer not found for work order {workorder.id}")
            return
        
        # Get vehicle info
        vehicle_query = select(Vehicle).where(Vehicle.id == workorder.vehicle_id)
        vehicle_result = await db.execute(vehicle_query)
        vehicle = vehicle_result.scalar_one_or_none()
        
        if not vehicle:
            logger.error(f"Vehicle not found for work order {workorder.id}")
            return
        
        # Get AFTER photos
        after_media_query = (
            select(Media)
            .where(Media.work_order_id == workorder.id)
            .where(Media.phase == MediaPhase.AFTER)
        )
        after_media_result = await db.execute(after_media_query)
        after_media = after_media_result.scalars().all()
        
        # Get domain for photo URLs
        domain = os.getenv('REPLIT_DEV_DOMAIN', 'localhost:5000')
        protocol = 'https' if not domain.startswith('localhost') else 'http'
        after_photo_urls = [f"{protocol}://{domain}/api/v1/workorders/media/{media.path}" for media in after_media]
        
        vehicle_info = f"{vehicle.year} {vehicle.make} {vehicle.model} ({vehicle.plate_no})"
        final_cost = f"${workorder.final_cost:.2f}" if workorder.final_cost else "Final cost TBD"
        
        # Send email notification
        if customer.email:
            subject = f"Service Complete - Ready for Pickup #{workorder.id}"
            photo_html = ""
            if after_photo_urls:
                photo_html = "<h3>Service Completion Photos:</h3><div style='display: flex; flex-wrap: wrap; gap: 10px;'>"
                for url in after_photo_urls:
                    photo_html += f"<img src='{url}' style='width: 200px; height: 150px; object-fit: cover; border-radius: 5px;'>"
                photo_html += "</div>"
            
            html = f"""
            <html>
            <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2 style="color: #28a745;">Yemen Hybrid Service Center</h2>
                <h3>🎉 Service Complete - Ready for Pickup!</h3>
                
                <p>Dear {customer.name},</p>
                
                <p>Great news! Your vehicle service has been completed and is ready for pickup:</p>
                
                <div style="background: #e7f3ff; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #28a745;">
                    <p><strong>Vehicle:</strong> {vehicle_info}</p>
                    <p><strong>Work Order #:</strong> {workorder.id}</p>
                    <p><strong>Service:</strong> {workorder.complaint or 'Service completed'}</p>
                    <p><strong>Final Cost:</strong> <span style="font-size: 18px; color: #28a745;">{final_cost}</span></p>
                </div>
                
                {photo_html}
                
                <p>Please contact us to schedule your pickup or visit us during business hours.</p>
                
                <p>Thank you for choosing Yemen Hybrid Service Center!</p>
                
                <p>Best regards,<br>Yemen Hybrid Service Center</p>
            </body>
            </html>
            """
            await notify.send_email(customer.email, subject, html)
        
        # Send WhatsApp notification
        if customer.phone:
            text = f"""
🎉 *Yemen Hybrid Service Center*

Dear {customer.name},

Great news! Your vehicle service is complete and ready for pickup:

*Vehicle:* {vehicle_info}
*Work Order #:* {workorder.id}
*Service:* {workorder.complaint or 'Service completed'}
*Final Cost:* {final_cost}

Please contact us to schedule pickup or visit during business hours.

Thank you for choosing Yemen Hybrid! 🚗✨
            """.strip()
            
            await notify.send_whatsapp(customer.phone, text, after_photo_urls)
    
    except Exception as e:
        logger.error(f"Failed to send pickup notification for work order {workorder.id}: {str(e)}")


