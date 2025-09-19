"""Vehicle schemas for API operations."""
from typing import Optional
from pydantic import BaseModel


class VehicleBase(BaseModel):
    """Base vehicle schema."""
    customer_id: int
    plate_no: str
    make: str
    model: str
    year: Optional[int] = None
    vin: Optional[str] = None
    odometer: Optional[int] = None
    hybrid_type: Optional[str] = None
    color: Optional[str] = None


class VehicleCreate(VehicleBase):
    """Vehicle creation schema."""
    pass


class VehicleUpdate(BaseModel):
    """Vehicle update schema."""
    customer_id: Optional[int] = None
    plate_no: Optional[str] = None
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    vin: Optional[str] = None
    odometer: Optional[int] = None
    hybrid_type: Optional[str] = None
    color: Optional[str] = None


class VehicleResponse(VehicleBase):
    """Vehicle response schema."""
    id: int

    class Config:
        from_attributes = True


class VehicleListResponse(BaseModel):
    """Vehicle list response with pagination."""
    items: list[VehicleResponse]
    total: int
    page: int
    size: int
    pages: int