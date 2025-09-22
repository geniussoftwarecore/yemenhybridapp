from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
import math

from ..core.deps import get_db, get_current_user, require_roles
from ..db.models import User, UserRole, Vehicle, Customer
from ..db.schemas import (
    VehicleCreate, 
    VehicleUpdate, 
    VehicleResponse, 
    VehicleListResponse
)

router = APIRouter(prefix="/vehicles", tags=["Vehicles"])

@router.get("/", response_model=VehicleListResponse)
async def get_vehicles(
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(10, ge=1, le=100, description="Page size"),
    q: Optional[str] = Query(None, description="Search query for plate number or VIN"),
    customer_id: Optional[int] = Query(None, description="Filter by customer ID"),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all vehicles with pagination, search, and filtering.
    
    - **page**: Page number (starts from 1)
    - **size**: Number of items per page (max 100)  
    - **q**: Search query for plate number or VIN
    - **customer_id**: Filter vehicles by customer ID
    """
    # Build query
    query = select(Vehicle)
    count_query = select(func.count(Vehicle.id))
    
    # Add customer filter
    if customer_id:
        query = query.where(Vehicle.customer_id == customer_id)
        count_query = count_query.where(Vehicle.customer_id == customer_id)
    
    # Add search filter
    if q:
        search_filter = or_(
            Vehicle.plate_no.ilike(f"%{q}%"),
            Vehicle.vin.ilike(f"%{q}%")
        )
        query = query.where(search_filter)
        count_query = count_query.where(search_filter)
    
    # Get total count
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0
    
    # Apply pagination
    offset = (page - 1) * size
    query = query.offset(offset).limit(size).order_by(Vehicle.id)
    
    # Execute query
    result = await db.execute(query)
    vehicles = result.scalars().all()
    
    # Calculate pagination info
    pages = math.ceil(total / size) if total > 0 else 1
    
    return VehicleListResponse(
        items=[VehicleResponse.model_validate(vehicle) for vehicle in vehicles],
        total=total,
        page=page,
        size=size,
        pages=pages
    )

@router.post("/", response_model=VehicleResponse, status_code=status.HTTP_201_CREATED)
async def create_vehicle(
    vehicle_data: VehicleCreate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create new vehicle.
    
    - **customer_id**: Customer ID (required, must exist)
    - **plate_no**: Vehicle plate number (required)
    - **make**: Vehicle make (required)
    - **model**: Vehicle model (required)
    - **year**: Vehicle year
    - **vin**: Vehicle VIN
    - **odometer**: Current odometer reading
    - **hybrid_type**: Type of hybrid system
    - **color**: Vehicle color
    """
    # Verify customer exists
    customer_query = select(Customer).where(Customer.id == vehicle_data.customer_id)
    customer_result = await db.execute(customer_query)
    customer = customer_result.scalar_one_or_none()
    
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Customer not found"
        )
    
    # Create vehicle
    vehicle = Vehicle(**vehicle_data.model_dump())
    db.add(vehicle)
    await db.commit()
    await db.refresh(vehicle)
    
    return vehicle

@router.get("/{vehicle_id}", response_model=VehicleResponse)
async def get_vehicle(
    vehicle_id: int,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get vehicle by ID."""
    query = select(Vehicle).where(Vehicle.id == vehicle_id)
    result = await db.execute(query)
    vehicle = result.scalar_one_or_none()
    
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found"
        )
    
    return vehicle

@router.put("/{vehicle_id}", response_model=VehicleResponse)
async def update_vehicle(
    vehicle_id: int,
    vehicle_data: VehicleUpdate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Update vehicle.
    
    Only provided fields will be updated. All fields are optional.
    If customer_id is provided, the customer must exist.
    """
    # Get vehicle
    query = select(Vehicle).where(Vehicle.id == vehicle_id)
    result = await db.execute(query)
    vehicle = result.scalar_one_or_none()
    
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found"
        )
    
    # If updating customer_id, verify customer exists
    update_data = vehicle_data.model_dump(exclude_unset=True)
    if "customer_id" in update_data:
        customer_query = select(Customer).where(Customer.id == update_data["customer_id"])
        customer_result = await db.execute(customer_query)
        customer = customer_result.scalar_one_or_none()
        
        if not customer:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Customer not found"
            )
    
    # Update fields
    for field, value in update_data.items():
        setattr(vehicle, field, value)
    
    await db.commit()
    await db.refresh(vehicle)
    
    return vehicle

@router.delete("/{vehicle_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_vehicle(
    vehicle_id: int,
    current_user: User = Depends(require_roles(UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Delete vehicle. Admin only."""
    # Get vehicle
    query = select(Vehicle).where(Vehicle.id == vehicle_id)
    result = await db.execute(query)
    vehicle = result.scalar_one_or_none()
    
    if not vehicle:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found"
        )
    
    # Delete vehicle (cascades to work orders, bookings)
    await db.delete(vehicle)
    await db.commit()