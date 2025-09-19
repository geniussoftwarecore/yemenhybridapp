"""Seed data script for development."""
import asyncio
from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import AsyncSessionLocal
from app.db.models import User, UserRole, Customer, Vehicle

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

async def seed_data():
    """Seed the database with minimal development data."""
    async with AsyncSessionLocal() as db:
        # Hash the password "Passw0rd!"
        hashed_password = pwd_context.hash("Passw0rd!")
        
        # Create users
        admin_user = User(
            full_name="Admin User",
            email="admin@yemenhybrid.com",
            phone="+967-1-234-567",
            role=UserRole.ADMIN,
            password_hash=hashed_password,
            is_active=True
        )
        
        sales_user = User(
            full_name="Sales User", 
            email="sales@yemenhybrid.com",
            phone="+967-1-234-568",
            role=UserRole.SALES,
            password_hash=hashed_password,
            is_active=True
        )
        
        engineer_user = User(
            full_name="Engineer User",
            email="engineer@yemenhybrid.com", 
            phone="+967-1-234-569",
            role=UserRole.ENGINEER,
            password_hash=hashed_password,
            is_active=True
        )
        
        # Add users to session
        db.add(admin_user)
        db.add(sales_user)
        db.add(engineer_user)
        
        # Create a customer
        customer = Customer(
            name="Ahmed Al-Yamani",
            phone="+967-777-123-456",
            email="ahmed.yamani@example.com",
            address="Sanaa, Yemen - Hadda Street, Building 123"
        )
        
        db.add(customer)
        
        # Flush to get customer ID
        await db.flush()
        
        # Create a vehicle linked to the customer
        vehicle = Vehicle(
            customer_id=customer.id,
            plate_no="SAA-12345",
            make="Toyota",
            model="Prius",
            year=2020,
            vin="JTDKN3DU8L0123456",
            odometer=45000,
            hybrid_type="Series Hybrid",
            color="Silver"
        )
        
        db.add(vehicle)
        
        # Commit all changes
        await db.commit()
        
        print("✅ Seed data created successfully!")
        print(f"👤 Users created: admin, sales, engineer (password: Passw0rd!)")
        print(f"👥 Customer created: {customer.name}")
        print(f"🚗 Vehicle created: {vehicle.year} {vehicle.make} {vehicle.model} ({vehicle.plate_no})")

if __name__ == "__main__":
    asyncio.run(seed_data())