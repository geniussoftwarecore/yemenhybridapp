from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, desc
from datetime import datetime, date
from typing import Optional, List
from ..core.deps import get_db, get_current_user, require_roles
from ..db.models import (
    User, UserRole, WorkOrder, WorkOrderStatus, WorkOrderService, 
    Service, Part, Customer, Invoice
)

router = APIRouter(prefix="/reports", tags=["Reports"])

@router.get("/kpis")
async def get_kpis(
    from_date: Optional[date] = Query(None, alias="from"),
    to_date: Optional[date] = Query(None, alias="to"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get KPI data for dashboards."""
    
    # Base date filter
    date_filter = []
    if from_date:
        date_filter.append(WorkOrder.created_at >= from_date)
    if to_date:
        date_filter.append(WorkOrder.created_at <= to_date)
    
    # Work orders by status
    wo_status_query = select(
        WorkOrder.status,
        func.count(WorkOrder.id).label('count')
    ).group_by(WorkOrder.status)
    
    if date_filter:
        wo_status_query = wo_status_query.where(and_(*date_filter))
    
    wo_status_result = await db.execute(wo_status_query)
    work_orders_by_status = [
        {"status": row.status.value, "count": row.count}
        for row in wo_status_result.fetchall()
    ]
    
    # Revenue by day (from invoices)
    revenue_query = select(
        func.date(Invoice.created_at).label('date'),
        func.sum(Invoice.total).label('total')
    ).group_by(func.date(Invoice.created_at)).order_by(func.date(Invoice.created_at))
    
    if from_date:
        revenue_query = revenue_query.where(Invoice.created_at >= from_date)
    if to_date:
        revenue_query = revenue_query.where(Invoice.created_at <= to_date)
    
    revenue_result = await db.execute(revenue_query)
    revenue_by_day = [
        {"date": str(row.date), "total": float(row.total or 0)}
        for row in revenue_result.fetchall()
    ]
    
    # Low stock parts
    low_stock_query = select(Part).where(
        Part.stock <= Part.min_stock
    ).order_by(Part.stock)
    
    low_stock_result = await db.execute(low_stock_query)
    low_stock_parts = [
        {
            "part_id": part.id,
            "name": part.name,
            "stock": int(part.stock) if part.stock is not None else 0,
            "min_stock": int(part.min_stock) if part.min_stock is not None else 0
        }
        for part in low_stock_result.scalars().all()
    ]
    
    # Top services (by work order count)
    top_services_query = select(
        Service.id,
        Service.name,
        func.count(WorkOrderService.work_order_id).label('count')
    ).join(WorkOrderService).join(WorkOrder).group_by(Service.id, Service.name).order_by(desc('count')).limit(10)
    
    if date_filter:
        top_services_query = top_services_query.where(and_(*date_filter))
    
    top_services_result = await db.execute(top_services_query)
    top_services = [
        {"service_id": row.id, "name": row.name, "count": row.count}
        for row in top_services_result.fetchall()
    ]
    
    return {
        "work_orders_by_status": work_orders_by_status,
        "revenue_by_day": revenue_by_day,
        "low_stock_parts": low_stock_parts,
        "top_services": top_services
    }

@router.get("/workorders")
async def get_workorder_report(
    status: Optional[WorkOrderStatus] = Query(None),
    tech: Optional[int] = Query(None),
    from_date: Optional[date] = Query(None, alias="from"),
    to_date: Optional[date] = Query(None, alias="to"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get work order report with filters."""
    
    filters = []
    if status:
        filters.append(WorkOrder.status == status)
    if tech:
        filters.append(WorkOrder.created_by == tech)
    if from_date:
        filters.append(WorkOrder.created_at >= from_date)
    if to_date:
        filters.append(WorkOrder.created_at <= to_date)
    
    query = select(WorkOrder).order_by(desc(WorkOrder.created_at))
    if filters:
        query = query.where(and_(*filters))
    
    result = await db.execute(query)
    work_orders = result.scalars().all()
    
    # Format for charts
    status_counts = {}
    daily_counts = {}
    
    for wo in work_orders:
        # Status distribution
        status_key = wo.status.value
        status_counts[status_key] = status_counts.get(status_key, 0) + 1
        
        # Daily distribution
        day_key = wo.created_at.date().isoformat()
        daily_counts[day_key] = daily_counts.get(day_key, 0) + 1
    
    return {
        "total_count": len(work_orders),
        "by_status": [{"label": k, "value": v} for k, v in status_counts.items()],
        "by_day": [{"label": k, "value": v} for k, v in sorted(daily_counts.items())],
        "work_orders": [
            {
                "id": wo.id,
                "status": wo.status.value,
                "created_at": wo.created_at.isoformat(),
                "customer_id": wo.customer_id,
                "vehicle_id": wo.vehicle_id,
                "final_cost": float(wo.final_cost) if wo.final_cost is not None else 0.0
            }
            for wo in work_orders
        ]
    }

@router.get("/inventory")
async def get_inventory_report(
    only_low: bool = Query(False),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get inventory report."""
    
    query = select(Part).order_by(Part.name)
    if only_low:
        query = query.where(Part.stock <= Part.min_stock)
    
    result = await db.execute(query)
    parts = result.scalars().all()
    
    # Format for charts
    stock_levels = []
    low_stock_count = 0
    total_value = 0
    
    for part in parts:
        stock = int(part.stock) if part.stock is not None else 0
        min_stock = int(part.min_stock) if part.min_stock is not None else 0
        buy_price = float(part.buy_price) if part.buy_price is not None else 0.0
        
        if stock <= min_stock:
            low_stock_count += 1
        
        total_value += stock * buy_price
        
        stock_levels.append({
            "name": part.name,
            "stock": stock,
            "min_stock": min_stock,
            "status": "low" if stock <= min_stock else "ok"
        })
    
    return {
        "total_parts": len(parts),
        "low_stock_count": low_stock_count,
        "total_value": total_value,
        "stock_levels": stock_levels,
        "parts": [
            {
                "id": part.id,
                "name": part.name,
                "part_no": part.part_no,
                "stock": int(part.stock) if part.stock is not None else 0,
                "min_stock": int(part.min_stock) if part.min_stock is not None else 0,
                "buy_price": float(part.buy_price) if part.buy_price is not None else 0.0,
                "sell_price": float(part.sell_price) if part.sell_price is not None else 0.0,
                "supplier": part.supplier,
                "location": part.location
            }
            for part in parts
        ]
    }

@router.get("/customers")
async def get_customer_report(
    top: Optional[int] = Query(None),
    from_date: Optional[date] = Query(None, alias="from"),
    to_date: Optional[date] = Query(None, alias="to"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get customer report."""
    
    # Customer work order counts and revenue
    date_filter = []
    if from_date:
        date_filter.append(WorkOrder.created_at >= from_date)
    if to_date:
        date_filter.append(WorkOrder.created_at <= to_date)
    
    query = select(
        Customer.id,
        Customer.name,
        Customer.created_at,
        func.count(WorkOrder.id).label('work_order_count'),
        func.coalesce(func.sum(Invoice.total), 0).label('total_revenue')
    ).outerjoin(WorkOrder).outerjoin(Invoice).group_by(Customer.id, Customer.name, Customer.created_at)
    
    if date_filter:
        query = query.where(and_(*date_filter))
    
    query = query.order_by(desc('total_revenue'))
    
    if top:
        query = query.limit(top)
    
    result = await db.execute(query)
    customers = result.fetchall()
    
    # Format for charts
    customer_revenue = []
    customer_orders = []
    
    for customer in customers:
        customer_revenue.append({
            "label": customer.name,
            "value": float(customer.total_revenue)
        })
        customer_orders.append({
            "label": customer.name,
            "value": customer.work_order_count
        })
    
    return {
        "total_customers": len(customers),
        "by_revenue": customer_revenue,
        "by_orders": customer_orders,
        "customers": [
            {
                "id": customer.id,
                "name": customer.name,
                "work_order_count": customer.work_order_count,
                "total_revenue": float(customer.total_revenue),
                "created_at": customer.created_at.isoformat()
            }
            for customer in customers
        ]
    }

@router.get("/sales")
async def get_sales_report(
    current_user: User = Depends(require_roles(UserRole.sales, UserRole.admin)),
    db: AsyncSession = Depends(get_db)
):
    """Get sales report. Sales and admin only."""
    # TODO: Implement sales report
    return {"message": "Sales report endpoint - to be implemented"}

@router.get("/vehicles")
async def get_vehicle_report(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get vehicle report. All authenticated users."""
    # TODO: Implement vehicle report
    return {"message": "Vehicle report endpoint - to be implemented"}