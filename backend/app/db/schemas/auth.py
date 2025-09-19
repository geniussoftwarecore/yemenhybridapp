"""Authentication schemas."""
from typing import Optional
from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    """Login request schema."""
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    """Login response schema."""
    access_token: str
    token_type: str = "bearer"
    user: "UserResponse"

    model_config = {"from_attributes": True}


class UserResponse(BaseModel):
    """User response schema."""
    id: int
    full_name: str
    email: str
    role: str
    is_active: bool

    model_config = {"from_attributes": True}


# Resolve forward references
LoginResponse.model_rebuild()