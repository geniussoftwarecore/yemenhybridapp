from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
import math

from ..core.deps import get_db, get_current_user, require_roles
from ..db.models import User, UserRole
from ..db.models.service import Service
from ..db.schemas import (
    ServiceCreate, 
    ServiceUpdate, 
    ServiceResponse, 
    ServiceListResponse
)

router = APIRouter(prefix="/services", tags=["Services"])

@router.get("/", response_model=ServiceListResponse)
async def get_services(
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(10, ge=1, le=100, description="Page size"),
    q: Optional[str] = Query(None, description="Search query for name or category"),
    category: Optional[str] = Query(None, description="Filter by category"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all services with pagination, search, and filtering.
    
    - **page**: Page number (starts from 1)
    - **size**: Number of items per page (max 100)  
    - **q**: Search query for service name or category
    - **category**: Filter by service category
    - **is_active**: Filter by active status (true/false)
    """
    # Build query
    query = select(Service)
    count_query = select(func.count(Service.id))
    
    # Add active status filter
    if is_active is not None:
        query = query.where(Service.is_active == is_active)
        count_query = count_query.where(Service.is_active == is_active)
    
    # Add category filter
    if category:
        query = query.where(Service.category.ilike(f"%{category}%"))
        count_query = count_query.where(Service.category.ilike(f"%{category}%"))
    
    # Add search filter
    if q:
        search_filter = or_(
            Service.name.ilike(f"%{q}%"),
            Service.category.ilike(f"%{q}%")
        )
        query = query.where(search_filter)
        count_query = count_query.where(search_filter)
    
    # Get total count
    total_result = await db.execute(count_query)
    total = total_result.scalar()
    
    # Apply pagination
    offset = (page - 1) * size
    query = query.offset(offset).limit(size).order_by(Service.id)
    
    # Execute query
    result = await db.execute(query)
    services = result.scalars().all()
    
    # Calculate pagination info
    pages = math.ceil(total / size)
    
    return ServiceListResponse(
        items=services,
        total=total,
        page=page,
        size=size,
        pages=pages
    )

@router.post("/", response_model=ServiceResponse, status_code=status.HTTP_201_CREATED)
async def create_service(
    service_data: ServiceCreate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create new service.
    
    - **name**: Service name (required)
    - **category**: Service category
    - **base_price**: Base price for the service
    - **est_minutes**: Estimated minutes to complete
    - **description**: Service description
    - **is_active**: Whether service is active (default: true)
    """
    # Create service
    service = Service(**service_data.model_dump())
    db.add(service)
    await db.commit()
    await db.refresh(service)
    
    return service

@router.get("/{service_id}", response_model=ServiceResponse)
async def get_service(
    service_id: int,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get service by ID."""
    query = select(Service).where(Service.id == service_id)
    result = await db.execute(query)
    service = result.scalar_one_or_none()
    
    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service not found"
        )
    
    return service

@router.put("/{service_id}", response_model=ServiceResponse)
async def update_service(
    service_id: int,
    service_data: ServiceUpdate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Update service.
    
    Only provided fields will be updated. All fields are optional.
    """
    # Get service
    query = select(Service).where(Service.id == service_id)
    result = await db.execute(query)
    service = result.scalar_one_or_none()
    
    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service not found"
        )
    
    # Update fields
    update_data = service_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(service, field, value)
    
    await db.commit()
    await db.refresh(service)
    
    return service

@router.put("/{service_id}/toggle-active", response_model=ServiceResponse)
async def toggle_service_active(
    service_id: int,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Toggle service active status."""
    # Get service
    query = select(Service).where(Service.id == service_id)
    result = await db.execute(query)
    service = result.scalar_one_or_none()
    
    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service not found"
        )
    
    # Toggle active status
    service.is_active = not service.is_active
    
    await db.commit()
    await db.refresh(service)
    
    return service

@router.delete("/{service_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_service(
    service_id: int,
    current_user: User = Depends(require_roles(UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Delete service. Admin only."""
    # Get service
    query = select(Service).where(Service.id == service_id)
    result = await db.execute(query)
    service = result.scalar_one_or_none()
    
    if not service:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service not found"
        )
    
    # Delete service
    await db.delete(service)
    await db.commit()