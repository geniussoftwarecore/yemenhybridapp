import os
import time
import uuid
from datetime import datetime
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
from ..db.schemas import (
    WorkOrderCreate,
    WorkOrderUpdate, 
    WorkOrderResponse,
    WorkOrderListResponse,
    WorkOrderEstimate,
    WorkOrderSchedule,
    WorkOrderItemCreate,
    WorkOrderItemResponse,
    MediaUploadResponse
)
from ..services.audit import log_action

router = APIRouter(prefix="/workorders", tags=["Work Orders"])

@router.get("/", response_model=WorkOrderListResponse)
async def get_workorders(
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(10, ge=1, le=100, description="Page size"),
    status: Optional[WorkOrderStatus] = Query(None, description="Filter by status"),
    customer_id: Optional[int] = Query(None, description="Filter by customer ID"),
    vehicle_id: Optional[int] = Query(None, description="Filter by vehicle ID"),
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
        db, current_user, f"ADD_{item_data.item_type.upper()}_ITEM", "work_order", workorder_id
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
        db, current_user, f"DELETE_{item.item_type.upper()}_ITEM", "work_order", item.work_order_id
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