# Pydantic schemas
from .auth import LoginRequest, LoginResponse, UserResponse
from .customers import CustomerCreate, CustomerUpdate, CustomerResponse, CustomerListResponse
from .vehicles import VehicleCreate, VehicleUpdate, VehicleResponse, VehicleListResponse
from .services import ServiceCreate, ServiceUpdate, ServiceResponse, ServiceListResponse
from .parts import PartCreate, PartUpdate, PartResponse, PartListResponse, PartStockAdjustment

__all__ = [
    "LoginRequest", "LoginResponse", "UserResponse",
    "CustomerCreate", "CustomerUpdate", "CustomerResponse", "CustomerListResponse",
    "VehicleCreate", "VehicleUpdate", "VehicleResponse", "VehicleListResponse", 
    "ServiceCreate", "ServiceUpdate", "ServiceResponse", "ServiceListResponse",
    "PartCreate", "PartUpdate", "PartResponse", "PartListResponse", "PartStockAdjustment"
]