from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
import math

from ..core.deps import get_db, get_current_user, require_roles
from ..db.models import User, UserRole, Customer
from ..db.schemas import (
    CustomerCreate, 
    CustomerUpdate, 
    CustomerResponse, 
    CustomerListResponse
)

router = APIRouter(prefix="/customers", tags=["Customers"])

@router.get("/", response_model=CustomerListResponse)
async def get_customers(
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(10, ge=1, le=100, description="Page size"),
    q: Optional[str] = Query(None, description="Search query for name, phone, or email"),
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all customers with pagination and search.
    
    - **page**: Page number (starts from 1)
    - **size**: Number of items per page (max 100)  
    - **q**: Search query for name, phone, or email
    """
    # Build query
    query = select(Customer)
    count_query = select(func.count(Customer.id))
    
    # Add search filter
    if q:
        search_filter = or_(
            Customer.name.ilike(f"%{q}%"),
            Customer.phone.ilike(f"%{q}%"),
            Customer.email.ilike(f"%{q}%")
        )
        query = query.where(search_filter)
        count_query = count_query.where(search_filter)
    
    # Get total count
    total_result = await db.execute(count_query)
    total = total_result.scalar()
    
    # Apply pagination
    offset = (page - 1) * size
    query = query.offset(offset).limit(size).order_by(Customer.id)
    
    # Execute query
    result = await db.execute(query)
    customers = result.scalars().all()
    
    # Calculate pagination info
    pages = math.ceil(total / size)
    
    return CustomerListResponse(
        items=customers,
        total=total,
        page=page,
        size=size,
        pages=pages
    )

@router.post("/", response_model=CustomerResponse, status_code=status.HTTP_201_CREATED)
async def create_customer(
    customer_data: CustomerCreate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create new customer.
    
    - **name**: Customer name (required)
    - **phone**: Customer phone number  
    - **email**: Customer email address
    - **address**: Customer address
    """
    # Create customer
    customer = Customer(**customer_data.model_dump())
    db.add(customer)
    await db.commit()
    await db.refresh(customer)
    
    return customer

@router.get("/{customer_id}", response_model=CustomerResponse)
async def get_customer(
    customer_id: int,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get customer by ID."""
    query = select(Customer).where(Customer.id == customer_id)
    result = await db.execute(query)
    customer = result.scalar_one_or_none()
    
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer not found"
        )
    
    return customer

@router.put("/{customer_id}", response_model=CustomerResponse)
async def update_customer(
    customer_id: int,
    customer_data: CustomerUpdate,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Update customer.
    
    Only provided fields will be updated. All fields are optional.
    """
    # Get customer
    query = select(Customer).where(Customer.id == customer_id)
    result = await db.execute(query)
    customer = result.scalar_one_or_none()
    
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer not found"
        )
    
    # Update fields
    update_data = customer_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(customer, field, value)
    
    await db.commit()
    await db.refresh(customer)
    
    return customer

@router.delete("/{customer_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_customer(
    customer_id: int,
    current_user: User = Depends(require_roles(UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Delete customer. Admin only."""
    # Get customer
    query = select(Customer).where(Customer.id == customer_id)
    result = await db.execute(query)
    customer = result.scalar_one_or_none()
    
    if not customer:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Customer not found"
        )
    
    # Delete customer (cascades to vehicles, work orders, bookings)
    await db.delete(customer)
    await db.commit()