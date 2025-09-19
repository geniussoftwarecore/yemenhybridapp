"""Tests for vehicles API endpoints."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.customer import Customer
from app.db.models.vehicle import Vehicle


class TestVehiclesAPI:
    """Test vehicles CRUD API."""

    @pytest.mark.asyncio
    async def test_create_vehicle(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test creating a vehicle."""
        # Create a customer first
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.commit()
        await db_session.refresh(customer)
        
        vehicle_data = {
            "customer_id": customer.id,
            "plate_no": "ABC-123",
            "make": "Toyota",
            "model": "Prius",
            "year": 2020,
            "vin": "1HGBH41JXMN109186",
            "odometer": 50000,
            "hybrid_type": "Full Hybrid",
            "color": "Silver"
        }
        
        response = await async_client.post(
            "/api/v1/vehicles/",
            json=vehicle_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["customer_id"] == vehicle_data["customer_id"]
        assert data["plate_no"] == vehicle_data["plate_no"]
        assert data["make"] == vehicle_data["make"]
        assert data["model"] == vehicle_data["model"]
        assert "id" in data

    @pytest.mark.asyncio
    async def test_create_vehicle_invalid_customer(self, async_client: AsyncClient, auth_headers: dict):
        """Test creating a vehicle with non-existent customer."""
        vehicle_data = {
            "customer_id": 999999,  # Non-existent customer
            "plate_no": "ABC-123",
            "make": "Toyota",
            "model": "Prius"
        }
        
        response = await async_client.post(
            "/api/v1/vehicles/",
            json=vehicle_data,
            headers=auth_headers
        )
        
        assert response.status_code == 400
        assert "Customer not found" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_get_vehicles_list(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test getting vehicles list with pagination."""
        # Create customer and vehicles
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicles = [
            Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius"),
            Vehicle(customer_id=customer.id, plate_no="XYZ-789", make="Honda", model="Insight"),
            Vehicle(customer_id=customer.id, plate_no="DEF-456", make="Ford", model="Escape"),
        ]
        for vehicle in vehicles:
            db_session.add(vehicle)
        await db_session.commit()
        
        response = await async_client.get("/api/v1/vehicles/", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "page" in data

    @pytest.mark.asyncio
    async def test_filter_by_customer(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test filtering vehicles by customer ID."""
        # Create customers and vehicles
        customer1 = Customer(name="Customer 1", phone="111")
        customer2 = Customer(name="Customer 2", phone="222")
        db_session.add_all([customer1, customer2])
        await db_session.flush()
        
        vehicles = [
            Vehicle(customer_id=customer1.id, plate_no="ABC-123", make="Toyota", model="Prius"),
            Vehicle(customer_id=customer2.id, plate_no="XYZ-789", make="Honda", model="Insight"),
        ]
        for vehicle in vehicles:
            db_session.add(vehicle)
        await db_session.commit()
        
        response = await async_client.get(
            f"/api/v1/vehicles/?customer_id={customer1.id}",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) == 1
        assert data["items"][0]["customer_id"] == customer1.id

    @pytest.mark.asyncio
    async def test_search_vehicles(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test searching vehicles by plate number and VIN."""
        # Create customer and vehicles
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicles = [
            Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius", vin="1HGBH41JXMN109186"),
            Vehicle(customer_id=customer.id, plate_no="XYZ-789", make="Honda", model="Insight", vin="2HGBH41JXMN109187"),
        ]
        for vehicle in vehicles:
            db_session.add(vehicle)
        await db_session.commit()
        
        # Search by plate number
        response = await async_client.get(
            "/api/v1/vehicles/?q=ABC",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len([item for item in data["items"] if "ABC" in item["plate_no"]]) > 0
        
        # Search by VIN
        response = await async_client.get(
            "/api/v1/vehicles/?q=1HGBH41JXMN109186",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) >= 1

    @pytest.mark.asyncio
    async def test_get_vehicle_by_id(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test getting a specific vehicle by ID."""
        # Create customer and vehicle
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.commit()
        await db_session.refresh(vehicle)
        
        response = await async_client.get(
            f"/api/v1/vehicles/{vehicle.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == vehicle.id
        assert data["plate_no"] == vehicle.plate_no

    @pytest.mark.asyncio
    async def test_update_vehicle(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test updating a vehicle."""
        # Create customer and vehicle
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.commit()
        await db_session.refresh(vehicle)
        
        update_data = {"odometer": 60000, "color": "Blue"}
        
        response = await async_client.put(
            f"/api/v1/vehicles/{vehicle.id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["odometer"] == update_data["odometer"]
        assert data["color"] == update_data["color"]

    @pytest.mark.asyncio
    async def test_delete_vehicle(self, async_client: AsyncClient, admin_auth_headers: dict, db_session: AsyncSession):
        """Test deleting a vehicle."""
        # Create customer and vehicle
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.commit()
        await db_session.refresh(vehicle)
        
        response = await async_client.delete(
            f"/api/v1/vehicles/{vehicle.id}",
            headers=admin_auth_headers
        )
        
        assert response.status_code == 204

    @pytest.mark.asyncio
    async def test_vehicle_not_found(self, async_client: AsyncClient, auth_headers: dict):
        """Test accessing non-existent vehicle."""
        response = await async_client.get(
            "/api/v1/vehicles/999999",
            headers=auth_headers
        )
        
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()