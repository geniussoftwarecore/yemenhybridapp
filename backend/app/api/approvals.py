from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from ..core.deps import get_db, get_current_user, require_roles
from ..db.models import User, UserRole

router = APIRouter(prefix="/approvals", tags=["Approvals"])

@router.get("/")
async def get_pending_approvals(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get pending approvals for current user. All authenticated users can view their approvals."""
    # TODO: Implement pending approvals retrieval
    return {"message": "Get pending approvals - to be implemented"}

@router.post("/")
async def create_approval_request(
    current_user: User = Depends(require_roles(UserRole.sales, UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Create approval request. Sales and admin only (engineers restricted)."""
    # TODO: Implement approval request creation
    return {"message": "Approval request created successfully"}

@router.put("/{approval_id}")
async def process_approval(
    approval_id: int,
    current_user: User = Depends(require_roles(UserRole.sales, UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Process approval decision. Sales and admin only (engineers restricted)."""
    # TODO: Implement approval processing
    return {"message": f"Approval {approval_id} processed successfully"}

@router.post("/send-to-customer")
async def send_approval_to_customer(
    current_user: User = Depends(require_roles(UserRole.sales, UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Send approval/offer to customer. Sales and admin only (engineers restricted)."""
    # TODO: Implement sending approval to customer
    return {"message": "Approval sent to customer successfully"}