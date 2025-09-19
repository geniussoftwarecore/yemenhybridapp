"""Tests for customers API endpoints."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.customer import Customer


class TestCustomersAPI:
    """Test customers CRUD API."""

    @pytest.mark.asyncio
    async def test_create_customer(self, async_client: AsyncClient, auth_headers: dict):
        """Test creating a customer."""
        customer_data = {
            "name": "John Doe",
            "phone": "+1234567890",
            "email": "john.doe@example.com",
            "address": "123 Main St, Anytown, USA"
        }
        
        response = await async_client.post(
            "/api/v1/customers/",
            json=customer_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == customer_data["name"]
        assert data["phone"] == customer_data["phone"]
        assert data["email"] == customer_data["email"]
        assert data["address"] == customer_data["address"]
        assert "id" in data
        assert "created_at" in data

    @pytest.mark.asyncio
    async def test_get_customers_list(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test getting customers list with pagination."""
        # Create test customers
        customers = [
            Customer(name="Customer 1", phone="111", email="c1@test.com"),
            Customer(name="Customer 2", phone="222", email="c2@test.com"),
            Customer(name="Customer 3", phone="333", email="c3@test.com"),
        ]
        for customer in customers:
            db_session.add(customer)
        await db_session.commit()
        
        # Test default pagination
        response = await async_client.get("/api/v1/customers/", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "page" in data
        assert "size" in data
        assert "pages" in data
        assert data["page"] == 1
        assert data["size"] == 10

    @pytest.mark.asyncio
    async def test_search_customers(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test searching customers."""
        # Create test customers
        customers = [
            Customer(name="John Smith", phone="111", email="john@test.com"),
            Customer(name="Jane Doe", phone="222", email="jane@test.com"),
            Customer(name="Bob Johnson", phone="333", email="bob@test.com"),
        ]
        for customer in customers:
            db_session.add(customer)
        await db_session.commit()
        
        # Search by name
        response = await async_client.get(
            "/api/v1/customers/?q=John",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len([item for item in data["items"] if "John" in item["name"]]) > 0

    @pytest.mark.asyncio
    async def test_get_customer_by_id(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test getting a specific customer by ID."""
        # Create test customer
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.commit()
        await db_session.refresh(customer)
        
        response = await async_client.get(
            f"/api/v1/customers/{customer.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == customer.id
        assert data["name"] == customer.name

    @pytest.mark.asyncio
    async def test_update_customer(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test updating a customer."""
        # Create test customer
        customer = Customer(name="Original Name", phone="123456")
        db_session.add(customer)
        await db_session.commit()
        await db_session.refresh(customer)
        
        update_data = {"name": "Updated Name", "email": "updated@test.com"}
        
        response = await async_client.put(
            f"/api/v1/customers/{customer.id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == update_data["name"]
        assert data["email"] == update_data["email"]

    @pytest.mark.asyncio
    async def test_delete_customer(self, async_client: AsyncClient, admin_auth_headers: dict, db_session: AsyncSession):
        """Test deleting a customer."""
        # Create test customer
        customer = Customer(name="To Delete", phone="123456")
        db_session.add(customer)
        await db_session.commit()
        await db_session.refresh(customer)
        
        response = await async_client.delete(
            f"/api/v1/customers/{customer.id}",
            headers=admin_auth_headers
        )
        
        assert response.status_code == 204

    @pytest.mark.asyncio
    async def test_customer_not_found(self, async_client: AsyncClient, auth_headers: dict):
        """Test accessing non-existent customer."""
        response = await async_client.get(
            "/api/v1/customers/999999",
            headers=auth_headers
        )
        
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_pagination_parameters(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test pagination parameters."""
        # Create multiple customers
        customers = [Customer(name=f"Customer {i}", phone=f"123{i}") for i in range(15)]
        for customer in customers:
            db_session.add(customer)
        await db_session.commit()
        
        # Test custom page size
        response = await async_client.get(
            "/api/v1/customers/?page=1&size=5",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data["items"]) <= 5
        assert data["size"] == 5
        assert data["pages"] >= 3  # Should have at least 3 pages for 15 items with size 5