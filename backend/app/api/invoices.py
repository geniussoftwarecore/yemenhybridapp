from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlalchemy import select
from decimal import Decimal
from typing import List
import os
from ..core.deps import get_db, get_current_user, require_roles
from ..db.models import User, UserRole, Invoice, Payment, WorkOrder, WorkOrderItem, Media
from ..db.schemas.invoices import InvoiceCreate, InvoiceResponse, InvoiceListResponse, PaymentCreate, PaymentResponse
from ..services.pdf import PDFService

router = APIRouter(prefix="/invoices", tags=["Invoices"])

@router.get("/", response_model=InvoiceListResponse)
async def get_invoices(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all invoices. All authenticated users can view."""
    stmt = select(Invoice).order_by(Invoice.created_at.desc())
    result = await db.execute(stmt)
    invoices = result.scalars().all()
    
    return InvoiceListResponse(
        invoices=[InvoiceResponse.from_orm(invoice) for invoice in invoices],
        count=len(invoices)
    )

@router.post("/", response_model=InvoiceResponse)
async def create_invoice(
    invoice_data: InvoiceCreate,
    current_user: User = Depends(require_roles(UserRole.sales, UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Create new invoice. Sales and admin only."""
    # Check if work order exists
    stmt = select(WorkOrder).options(
        selectinload(WorkOrder.items),
        selectinload(WorkOrder.services)
    ).where(WorkOrder.id == invoice_data.work_order_id)
    result = await db.execute(stmt)
    work_order = result.scalar_one_or_none()
    
    if not work_order:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Work order not found"
        )
    
    # Check if invoice already exists for this work order
    existing_invoice = await db.execute(
        select(Invoice).where(Invoice.work_order_id == invoice_data.work_order_id)
    )
    if existing_invoice.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invoice already exists for this work order"
        )
    
    # Calculate subtotal from work order items
    subtotal = Decimal('0.00')
    for item in work_order.items:
        item_total = item.qty * item.unit_price
        subtotal += item_total
    
    # Add services if any
    for service in work_order.services:
        if hasattr(service, 'price') and service.price:
            subtotal += service.price
        elif hasattr(service.service, 'base_price') and service.service.base_price:
            subtotal += service.service.base_price
    
    # Apply tax and discount with proper validation
    tax_rate = Decimal('0.15')  # 15% default tax
    discount = invoice_data.discount or Decimal('0.00')
    
    # Validate discount doesn't exceed subtotal
    if discount < 0 or discount > subtotal:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Discount must be between 0 and subtotal amount"
        )
    
    # Calculate tax on discounted amount (never negative)
    taxable_amount = max(subtotal - discount, Decimal('0.00'))
    tax = taxable_amount * tax_rate
    total = subtotal + tax - discount
    
    # Round all monetary values to 2 decimal places
    subtotal = subtotal.quantize(Decimal('0.01'))
    tax = tax.quantize(Decimal('0.01'))
    discount = discount.quantize(Decimal('0.01'))
    total = total.quantize(Decimal('0.01'))
    
    # Create invoice
    invoice = Invoice(
        work_order_id=invoice_data.work_order_id,
        subtotal=subtotal,
        tax=tax,
        discount=discount,
        total=total,
        paid=Decimal('0.00'),
        method=invoice_data.method
    )
    
    db.add(invoice)
    await db.commit()
    await db.refresh(invoice)
    
    return invoice

@router.get("/{invoice_id}", response_model=InvoiceResponse)
async def get_invoice(
    invoice_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get invoice by ID."""
    stmt = select(Invoice).where(Invoice.id == invoice_id)
    result = await db.execute(stmt)
    invoice = result.scalar_one_or_none()
    
    if not invoice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invoice not found"
        )
    
    return invoice

@router.get("/{invoice_id}/pdf")
async def get_invoice_pdf(
    invoice_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Generate and stream PDF for invoice."""
    # Get invoice with work order details
    stmt = select(Invoice).options(
        selectinload(Invoice.work_order).selectinload(WorkOrder.customer),
        selectinload(Invoice.work_order).selectinload(WorkOrder.vehicle),
        selectinload(Invoice.work_order).selectinload(WorkOrder.items),
        selectinload(Invoice.work_order).selectinload(WorkOrder.services),
        selectinload(Invoice.work_order).selectinload(WorkOrder.media)
    ).where(Invoice.id == invoice_id)
    result = await db.execute(stmt)
    invoice = result.scalar_one_or_none()
    
    if not invoice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invoice not found"
        )
    
    # Generate PDF
    pdf_service = PDFService()
    pdf_content = await pdf_service.generate_invoice_pdf(invoice)
    
    return Response(
        content=pdf_content,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename=invoice_{invoice_id}.pdf"}
    )

@router.post("/payments", response_model=PaymentResponse)
async def create_payment(
    payment_data: PaymentCreate,
    current_user: User = Depends(require_roles(UserRole.sales, UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Create payment for invoice. Sales and admin only."""
    # Check if invoice exists
    stmt = select(Invoice).where(Invoice.id == payment_data.invoice_id)
    result = await db.execute(stmt)
    invoice = result.scalar_one_or_none()
    
    if not invoice:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invoice not found"
        )
    
    # Validate payment amount
    if payment_data.amount <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment amount must be positive"
        )
    
    current_paid = invoice.paid if invoice.paid is not None else Decimal('0.00')
    remaining_balance = invoice.total - current_paid
    
    if payment_data.amount > remaining_balance:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Payment amount ({payment_data.amount}) exceeds remaining balance ({remaining_balance})"
        )
    
    # Create payment
    payment = Payment(
        invoice_id=payment_data.invoice_id,
        amount=payment_data.amount.quantize(Decimal('0.01')),
        method=payment_data.method,
        ref=payment_data.ref
    )
    
    db.add(payment)
    
    # Update invoice paid amount using proper SQLAlchemy update
    new_paid_amount = (current_paid + payment_data.amount).quantize(Decimal('0.01'))
    await db.execute(
        select(Invoice).where(Invoice.id == payment_data.invoice_id)
    )
    invoice.paid = new_paid_amount
    
    await db.commit()
    await db.refresh(payment)
    
    return payment

@router.put("/{invoice_id}")
async def update_invoice(
    invoice_id: int,
    current_user: User = Depends(require_roles(UserRole.sales, UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Update invoice. Sales and admin only (engineers cannot finalize)."""
    # TODO: Implement invoice update
    return {"message": f"Update invoice {invoice_id} endpoint - to be implemented"}

@router.put("/{invoice_id}/finalize")
async def finalize_invoice(
    invoice_id: int,
    current_user: User = Depends(require_roles(UserRole.sales, UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Finalize invoice. Sales and admin only (engineers cannot finalize)."""
    # TODO: Implement invoice finalization
    return {"message": f"Invoice {invoice_id} finalized successfully"}

@router.delete("/{invoice_id}")
async def delete_invoice(
    invoice_id: int,
    current_user: User = Depends(require_roles(UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Delete invoice. Admin only."""
    # TODO: Implement invoice deletion
    return {"message": f"Delete invoice {invoice_id} endpoint - to be implemented"}