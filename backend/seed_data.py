"""
Comprehensive seed data script for Yemen Hybrid Backend API.

Creates test users (admin/sales/engineer) and extensive sample data for development and testing.
Run with: python seed_data.py
"""

import asyncio
from datetime import datetime, timedelta
from decimal import Decimal
from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import AsyncSessionLocal
from app.db.models import (
    User, UserRole, Customer, Vehicle, WorkOrder, WorkOrderStatus, 
    WorkOrderItem, ItemType, Service, Part, Invoice, ApprovalRequest
)

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


async def create_test_users(db: AsyncSession) -> dict:
    """Create test users with different roles."""
    print("🔐 Creating test users...")
    
    hashed_password = pwd_context.hash("Passw0rd!")
    
    users_data = [
        {
            "full_name": "Admin User",
            "email": "admin@example.com",
            "phone": "+967-1-234-567",
            "role": UserRole.admin,
            "password_hash": hashed_password,
            "is_active": True
        },
        {
            "full_name": "Sales Representative", 
            "email": "sales@example.com",
            "phone": "+967-1-234-568",
            "role": UserRole.sales,
            "password_hash": hashed_password,
            "is_active": True
        },
        {
            "full_name": "Service Engineer",
            "email": "eng@example.com", 
            "phone": "+967-1-234-569",
            "role": UserRole.engineer,
            "password_hash": hashed_password,
            "is_active": True
        }
    ]
    
    created_users = {}
    
    for user_data in users_data:
        # Check if user already exists
        result = await db.execute(
            select(User).where(User.email == user_data["email"])
        )
        existing_user = result.scalar_one_or_none()
        
        if existing_user:
            print(f"   User {user_data['email']} already exists, skipping...")
            created_users[user_data["role"].value] = existing_user
            continue
            
        # Create new user
        user = User(**user_data)
        db.add(user)
        await db.flush()
        created_users[user_data["role"].value] = user
        print(f"   ✅ Created user: {user_data['email']} ({user_data['role'].value})")
    
    await db.commit()
    return created_users


async def create_sample_services(db: AsyncSession) -> list:
    """Create sample automotive services."""
    print("🔧 Creating sample services...")
    
    services_data = [
        {
            "name": "Oil Change",
            "category": "Maintenance", 
            "base_price": Decimal("45.00"),
            "est_minutes": 30,
            "description": "Complete oil and filter change service",
            "is_active": True
        },
        {
            "name": "Hybrid Battery Diagnostic",
            "category": "Hybrid Systems",
            "base_price": Decimal("125.00"),
            "est_minutes": 60,
            "description": "Comprehensive hybrid battery health check",
            "is_active": True
        },
        {
            "name": "Brake Inspection",
            "category": "Brakes",
            "base_price": Decimal("75.00"),
            "est_minutes": 45,
            "description": "Complete brake system inspection",
            "is_active": True
        },
        {
            "name": "Engine Diagnostic",
            "category": "Engine",
            "base_price": Decimal("95.00"),
            "est_minutes": 90,
            "description": "Computer diagnostic scan and analysis",
            "is_active": True
        },
        {
            "name": "AC Service",
            "category": "HVAC",
            "base_price": Decimal("85.00"),
            "est_minutes": 60,
            "description": "Air conditioning system service and recharge",
            "is_active": True
        }
    ]
    
    created_services = []
    for service_data in services_data:
        service = Service(**service_data)
        db.add(service)
        created_services.append(service)
        print(f"   ✅ Created service: {service_data['name']}")
    
    await db.flush()
    return created_services


async def create_sample_parts(db: AsyncSession) -> list:
    """Create sample automotive parts."""
    print("📦 Creating sample parts...")
    
    parts_data = [
        {
            "name": "Engine Oil Filter",
            "part_no": "OF-TOY-001",
            "supplier": "Toyota",
            "stock": 50,
            "min_stock": 10,
            "buy_price": Decimal("12.99"),
            "sell_price": Decimal("19.99"),
            "location": "Shelf A-1"
        },
        {
            "name": "Hybrid Battery Cell",
            "part_no": "HBC-TOY-002", 
            "supplier": "Toyota",
            "stock": 5,
            "min_stock": 2,
            "buy_price": Decimal("450.00"),
            "sell_price": Decimal("599.99"),
            "location": "Secure Storage"
        },
        {
            "name": "Air Filter",
            "part_no": "AF-GEN-003",
            "supplier": "ACDelco",
            "stock": 25,
            "min_stock": 5,
            "buy_price": Decimal("15.99"),
            "sell_price": Decimal("24.99"),
            "location": "Shelf B-2"
        },
        {
            "name": "Brake Pad Set",
            "part_no": "BP-BEN-004",
            "supplier": "Bendix",
            "stock": 15,
            "min_stock": 3,
            "buy_price": Decimal("65.00"),
            "sell_price": Decimal("89.99"),
            "location": "Shelf C-1"
        },
        {
            "name": "Inverter Coolant",
            "part_no": "IC-TOY-005",
            "supplier": "Toyota",
            "stock": 8,
            "min_stock": 3,
            "buy_price": Decimal("25.00"),
            "sell_price": Decimal("39.99"),
            "location": "Fluids Storage"
        }
    ]
    
    created_parts = []
    for part_data in parts_data:
        part = Part(**part_data)
        db.add(part)
        created_parts.append(part)
        print(f"   ✅ Created part: {part_data['name']}")
    
    await db.flush()
    return created_parts


async def create_sample_customers(db: AsyncSession) -> list:
    """Create sample customers."""
    print("👥 Creating sample customers...")
    
    customers_data = [
        {
            "name": "Ahmed Al-Rashid",
            "phone": "+967-1-234-5678",
            "email": "ahmed.rashid@email.com",
            "address": "Al-Zubairi Street, Sanaa",
        },
        {
            "name": "Fatima Al-Mansouri", 
            "phone": "+967-2-345-6789",
            "email": "fatima.mansouri@email.com",
            "address": "Al-Moalla District, Aden",
        },
        {
            "name": "Mohammed Al-Hakim",
            "phone": "+967-3-456-7890", 
            "email": "mohammed.hakim@email.com",
            "address": "Hadda Road, Sanaa",
        },
        {
            "name": "Sarah Al-Zahra",
            "phone": "+967-4-567-8901",
            "email": "sarah.zahra@email.com", 
            "address": "Crater District, Aden",
        },
        {
            "name": "Ali Al-Sabri",
            "phone": "+967-5-678-9012",
            "email": "ali.sabri@email.com",
            "address": "Ma'ain District, Sanaa", 
        }
    ]
    
    created_customers = []
    for customer_data in customers_data:
        customer = Customer(**customer_data)
        db.add(customer)
        created_customers.append(customer)
        print(f"   ✅ Created customer: {customer_data['name']}")
    
    await db.flush()
    return created_customers


async def create_sample_vehicles(db: AsyncSession, customers: list) -> list:
    """Create sample vehicles for customers."""
    print("🚗 Creating sample vehicles...")
    
    vehicles_data = [
        {
            "customer": customers[0],
            "plate_no": "SAA-1234",
            "make": "Toyota",
            "model": "Prius",
            "year": 2020,
            "vin": "JTDKB20U123456789",
            "color": "Silver",
            "odometer": 45000,
            "hybrid_type": "Full Hybrid"
        },
        {
            "customer": customers[1],
            "plate_no": "ADE-5678",
            "make": "Toyota",
            "model": "Camry Hybrid",
            "year": 2019,
            "vin": "JTDKB30U987654321",
            "color": "Blue",
            "odometer": 62000,
            "hybrid_type": "Full Hybrid"
        },
        {
            "customer": customers[2],
            "plate_no": "SAA-9999",
            "make": "Honda",
            "model": "Insight",
            "year": 2021,
            "vin": "JHMZE2H30MS123456",
            "color": "White",
            "odometer": 28000,
            "hybrid_type": "Full Hybrid"
        },
        {
            "customer": customers[3],
            "plate_no": "ADE-3333",
            "make": "Toyota",
            "model": "Prius Prime",
            "year": 2023,
            "vin": "JTDKB50U789123456",
            "color": "Green",
            "odometer": 8000,
            "hybrid_type": "Plug-in Hybrid"
        },
        {
            "customer": customers[4],
            "plate_no": "SAA-7777",
            "make": "Honda",
            "model": "Accord Hybrid",
            "year": 2018,
            "vin": "JHMCR6F75KC123456",
            "color": "Red",
            "odometer": 95000,
            "hybrid_type": "Full Hybrid"
        }
    ]
    
    created_vehicles = []
    for vehicle_data in vehicles_data:
        customer = vehicle_data.pop("customer")
        vehicle = Vehicle(customer_id=customer.id, **vehicle_data)
        db.add(vehicle)
        created_vehicles.append(vehicle)
        print(f"   ✅ Created vehicle: {vehicle_data['make']} {vehicle_data['model']} - {vehicle_data['plate_no']}")
    
    await db.flush()
    return created_vehicles


async def create_sample_workorders(db: AsyncSession, customers: list, vehicles: list, users: dict) -> list:
    """Create sample work orders with different statuses."""
    print("📋 Creating sample work orders...")
    
    engineer = users['engineer']
    
    workorders_data = [
        {
            "customer": customers[0],
            "vehicle": vehicles[0],
            "complaint": "Engine making unusual noise during startup",
            "status": WorkOrderStatus.NEW,
            "created_by": engineer.id,
            "notes": "Customer reports noise started 2 weeks ago. Hybrid battery cooling system needs inspection."
        },
        {
            "customer": customers[1], 
            "vehicle": vehicles[1],
            "complaint": "Reduced fuel efficiency",
            "status": WorkOrderStatus.IN_PROGRESS,
            "created_by": engineer.id,
            "started_at": datetime.utcnow() - timedelta(hours=2),
            "est_parts": Decimal("25.00"),
            "est_labor": Decimal("45.00"),
            "notes": "Diagnostic completed, air filter replacement needed. Parts installed."
        },
        {
            "customer": customers[2],
            "vehicle": vehicles[2], 
            "complaint": "Regular maintenance service",
            "status": WorkOrderStatus.DONE,
            "created_by": engineer.id,
            "started_at": datetime.utcnow() - timedelta(days=1),
            "completed_at": datetime.utcnow() - timedelta(hours=6),
            "est_parts": Decimal("20.00"),
            "est_labor": Decimal("45.00"),
            "notes": "Oil change and general inspection completed. Routine maintenance completed successfully."
        }
    ]
    
    created_workorders = []
    for wo_data in workorders_data:
        customer = wo_data.pop("customer")
        vehicle = wo_data.pop("vehicle")
        
        workorder = WorkOrder(
            customer_id=customer.id,
            vehicle_id=vehicle.id,
            **wo_data
        )
        db.add(workorder)
        created_workorders.append(workorder)
        print(f"   ✅ Created work order: {wo_data['complaint'][:40]}... ({wo_data['status'].value})")
    
    await db.flush()
    return created_workorders


async def add_workorder_items(db: AsyncSession, workorders: list):
    """Add items to work orders."""
    print("📝 Adding items to work orders...")
    
    # Add items to DONE work order (for invoice generation)
    done_wo = next(wo for wo in workorders if wo.status == WorkOrderStatus.DONE)
    items = [
        WorkOrderItem(
            work_order_id=done_wo.id,
            item_type=ItemType.PART,
            name="Engine Oil Filter",
            qty=Decimal("1"),
            unit_price=Decimal("19.99")
        ),
        WorkOrderItem(
            work_order_id=done_wo.id,
            item_type=ItemType.LABOR,
            name="Oil Change",
            qty=Decimal("1"),
            unit_price=Decimal("45.00")
        )
    ]
    
    for item in items:
        db.add(item)
        print(f"   ✅ Added item: {item.name} to work order {item.work_order_id}")
    
    await db.flush()


async def create_sample_invoice(db: AsyncSession, workorders: list):
    """Create sample invoice for completed work order."""
    print("🧾 Creating sample invoice...")
    
    # Create invoice for DONE work order
    done_wo = next(wo for wo in workorders if wo.status == WorkOrderStatus.DONE)
    
    invoice = Invoice(
        work_order_id=done_wo.id,
        subtotal=Decimal("64.99"),  # Oil change + filter
        tax=Decimal("9.75"),  # 15% tax
        total=Decimal("74.74")
    )
    
    db.add(invoice)
    print(f"   ✅ Created invoice for work order {done_wo.id} - Total: ${invoice.total}")
    
    await db.flush()


async def seed_data():
    """Main seed function with comprehensive sample data."""
    print("=" * 70)
    print("🇾🇪 YEMEN HYBRID BACKEND API - COMPREHENSIVE DATA SEEDING")
    print("=" * 70)
    
    try:
        async with AsyncSessionLocal() as db:
            # Create test users first
            users = await create_test_users(db)
            
            # Create services and parts
            services = await create_sample_services(db)
            parts = await create_sample_parts(db)
            
            # Create customers and their vehicles
            customers = await create_sample_customers(db)
            vehicles = await create_sample_vehicles(db, customers)
            
            # Create work orders with different statuses
            workorders = await create_sample_workorders(db, customers, vehicles, users)
            
            # Add items to work orders
            await add_workorder_items(db, workorders)
            
            # Create invoice for completed work
            await create_sample_invoice(db, workorders)
            
            # Final commit
            await db.commit()
            
        print("\n" + "=" * 70)
        print("✅ COMPREHENSIVE DATA SEEDING COMPLETED SUCCESSFULLY!")
        print("=" * 70)
        print("\n🔐 Test Users Created:")
        print("   • admin@example.com (Admin)")
        print("   • sales@example.com (Sales)")  
        print("   • eng@example.com (Engineer)")
        print("   📧 Password for all users: Passw0rd!")
        
        print("\n📊 Sample Data Created:")
        print("   • 5 customers with diverse profiles")
        print("   • 5 vehicles (Toyota/Honda hybrids)")
        print("   • 5 automotive services with pricing")
        print("   • 5 parts with stock management") 
        print("   • 3 work orders (NEW/IN_PROGRESS/DONE)")
        print("   • Work order items and sample invoice")
        
        print("\n🎯 Ready for Testing:")
        print("   • Full CRUD operations")
        print("   • Approval workflow testing")
        print("   • Invoice generation testing")
        print("   • Role-based access control")
        print("   • Media upload workflows")
        
        print("\n🚀 Application is ready for development and testing!")
        
    except Exception as e:
        print(f"\n❌ ERROR: Failed to seed data: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(asyncio.run(seed_data()))