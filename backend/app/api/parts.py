from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
import math

from ..core.deps import get_db, get_current_user, require_roles
from ..db.models import User, UserRole
from ..db.models.service import Part
from ..db.schemas import (
    PartCreate, 
    PartUpdate, 
    PartResponse, 
    PartListResponse,
    PartStockAdjustment
)

router = APIRouter(prefix="/parts", tags=["Parts"])

@router.get("/", response_model=PartListResponse)
async def get_parts(
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(10, ge=1, le=100, description="Page size"),
    q: Optional[str] = Query(None, description="Search query for name, part number, or supplier"),
    low_stock: Optional[bool] = Query(None, description="Filter parts with low stock (stock <= min_stock)"),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all parts with pagination, search, and filtering.
    
    - **page**: Page number (starts from 1)
    - **size**: Number of items per page (max 100)  
    - **q**: Search query for part name, part number, or supplier
    - **low_stock**: Filter parts with low stock (stock <= min_stock)
    """
    # Build query
    query = select(Part)
    count_query = select(func.count(Part.id))
    
    # Add low stock filter
    if low_stock:
        query = query.where(Part.stock <= Part.min_stock)
        count_query = count_query.where(Part.stock <= Part.min_stock)
    
    # Add search filter
    if q:
        search_filter = or_(
            Part.name.ilike(f"%{q}%"),
            Part.part_no.ilike(f"%{q}%"),
            Part.supplier.ilike(f"%{q}%")
        )
        query = query.where(search_filter)
        count_query = count_query.where(search_filter)
    
    # Get total count
    total_result = await db.execute(count_query)
    total = total_result.scalar()
    
    # Apply pagination
    offset = (page - 1) * size
    query = query.offset(offset).limit(size).order_by(Part.id)
    
    # Execute query
    result = await db.execute(query)
    parts = result.scalars().all()
    
    # Calculate pagination info
    pages = math.ceil(total / size)
    
    return PartListResponse(
        items=parts,
        total=total,
        page=page,
        size=size,
        pages=pages
    )

@router.post("/", response_model=PartResponse, status_code=status.HTTP_201_CREATED)
async def create_part(
    part_data: PartCreate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create new part.
    
    - **name**: Part name (required)
    - **part_no**: Part number
    - **supplier**: Part supplier
    - **stock**: Current stock quantity (default: 0)
    - **min_stock**: Minimum stock threshold (default: 0)
    - **buy_price**: Purchase price
    - **sell_price**: Selling price
    - **location**: Storage location
    """
    # Create part
    part = Part(**part_data.model_dump())
    db.add(part)
    await db.commit()
    await db.refresh(part)
    
    return part

@router.get("/{part_id}", response_model=PartResponse)
async def get_part(
    part_id: int,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get part by ID."""
    query = select(Part).where(Part.id == part_id)
    result = await db.execute(query)
    part = result.scalar_one_or_none()
    
    if not part:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Part not found"
        )
    
    return part

@router.put("/{part_id}", response_model=PartResponse)
async def update_part(
    part_id: int,
    part_data: PartUpdate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Update part.
    
    Only provided fields will be updated. All fields are optional.
    """
    # Get part
    query = select(Part).where(Part.id == part_id)
    result = await db.execute(query)
    part = result.scalar_one_or_none()
    
    if not part:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Part not found"
        )
    
    # Update fields
    update_data = part_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(part, field, value)
    
    await db.commit()
    await db.refresh(part)
    
    return part

@router.put("/{part_id}/adjust-stock", response_model=PartResponse)
async def adjust_part_stock(
    part_id: int,
    adjustment: PartStockAdjustment,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Adjust part stock quantity.
    
    - **delta**: Stock adjustment amount (positive to add, negative to subtract)
    """
    # Get part
    query = select(Part).where(Part.id == part_id)
    result = await db.execute(query)
    part = result.scalar_one_or_none()
    
    if not part:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Part not found"
        )
    
    # Adjust stock
    new_stock = (part.stock or 0) + adjustment.delta
    
    # Prevent negative stock
    if new_stock < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Stock adjustment would result in negative stock"
        )
    
    part.stock = new_stock
    
    await db.commit()
    await db.refresh(part)
    
    return part

@router.delete("/{part_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_part(
    part_id: int,
    current_user: User = Depends(require_roles(UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Delete part. Admin only."""
    # Get part
    query = select(Part).where(Part.id == part_id)
    result = await db.execute(query)
    part = result.scalar_one_or_none()
    
    if not part:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Part not found"
        )
    
    # Delete part
    await db.delete(part)
    await db.commit()