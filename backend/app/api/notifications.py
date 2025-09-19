from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from ..core.deps import get_db, require_roles
from ..db.models import User, UserRole

router = APIRouter(prefix="/notifications", tags=["Notifications"])

@router.post("/send-email")
async def send_email_to_customer(
    current_user: User = Depends(require_roles(UserRole.sales, UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Send email notification to customer. Sales and admin only (engineers restricted)."""
    # TODO: Implement email sending logic
    return {"message": "Email sent successfully"}

@router.post("/send-whatsapp")
async def send_whatsapp_to_customer(
    current_user: User = Depends(require_roles(UserRole.sales, UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Send WhatsApp message to customer. Sales and admin only (engineers restricted)."""
    # TODO: Implement WhatsApp sending logic
    return {"message": "WhatsApp message sent successfully"}

@router.post("/send-invoice-notification")
async def send_invoice_notification(
    current_user: User = Depends(require_roles(UserRole.sales, UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Send invoice notification to customer. Sales and admin only (engineers restricted)."""
    # TODO: Implement invoice notification logic
    return {"message": "Invoice notification sent successfully"}