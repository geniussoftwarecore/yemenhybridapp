"""Tests for services API endpoints."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.service import Service


class TestServicesAPI:
    """Test services CRUD API."""

    @pytest.mark.asyncio
    async def test_create_service(self, async_client: AsyncClient, auth_headers: dict):
        """Test creating a service."""
        service_data = {
            "name": "Oil Change",
            "category": "Maintenance",
            "base_price": "29.99",
            "est_minutes": 30,
            "description": "Regular oil change service",
            "is_active": True
        }
        
        response = await async_client.post(
            "/api/v1/services/",
            json=service_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == service_data["name"]
        assert data["category"] == service_data["category"]
        assert float(data["base_price"]) == float(service_data["base_price"])
        assert data["est_minutes"] == service_data["est_minutes"]
        assert "id" in data

    @pytest.mark.asyncio
    async def test_get_services_list(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test getting services list with pagination."""
        # Create test services
        services = [
            Service(name="Oil Change", category="Maintenance", base_price=29.99, is_active=True),
            Service(name="Battery Check", category="Electrical", base_price=19.99, is_active=True),
            Service(name="Brake Repair", category="Brakes", base_price=199.99, is_active=False),
        ]
        for service in services:
            db_session.add(service)
        await db_session.commit()
        
        response = await async_client.get("/api/v1/services/", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "page" in data

    @pytest.mark.asyncio
    async def test_filter_by_active_status(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test filtering services by active status."""
        # Create test services
        services = [
            Service(name="Active Service", category="Test", is_active=True),
            Service(name="Inactive Service", category="Test", is_active=False),
        ]
        for service in services:
            db_session.add(service)
        await db_session.commit()
        
        # Filter for active services only
        response = await async_client.get(
            "/api/v1/services/?is_active=true",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        for item in data["items"]:
            assert item["is_active"] == True

    @pytest.mark.asyncio
    async def test_search_services(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test searching services by name and category."""
        # Create test services
        services = [
            Service(name="Oil Change", category="Maintenance", is_active=True),
            Service(name="Battery Check", category="Electrical", is_active=True),
            Service(name="Brake Service", category="Brakes", is_active=True),
        ]
        for service in services:
            db_session.add(service)
        await db_session.commit()
        
        # Search by name
        response = await async_client.get(
            "/api/v1/services/?q=Oil",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len([item for item in data["items"] if "Oil" in item["name"]]) > 0
        
        # Search by category
        response = await async_client.get(
            "/api/v1/services/?q=Electrical",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len([item for item in data["items"] if "Electrical" in item["category"]]) > 0

    @pytest.mark.asyncio
    async def test_get_service_by_id(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test getting a specific service by ID."""
        service = Service(name="Test Service", category="Test", base_price=50.00, is_active=True)
        db_session.add(service)
        await db_session.commit()
        await db_session.refresh(service)
        
        response = await async_client.get(
            f"/api/v1/services/{service.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == service.id
        assert data["name"] == service.name

    @pytest.mark.asyncio
    async def test_update_service(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test updating a service."""
        service = Service(name="Original Service", category="Test", base_price=50.00, is_active=True)
        db_session.add(service)
        await db_session.commit()
        await db_session.refresh(service)
        
        update_data = {"name": "Updated Service", "base_price": "75.99"}
        
        response = await async_client.put(
            f"/api/v1/services/{service.id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == update_data["name"]
        assert float(data["base_price"]) == float(update_data["base_price"])

    @pytest.mark.asyncio
    async def test_toggle_service_active(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test toggling service active status."""
        service = Service(name="Test Service", category="Test", is_active=True)
        db_session.add(service)
        await db_session.commit()
        await db_session.refresh(service)
        
        # Toggle from active to inactive
        response = await async_client.put(
            f"/api/v1/services/{service.id}/toggle-active",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["is_active"] == False
        
        # Toggle back to active
        response = await async_client.put(
            f"/api/v1/services/{service.id}/toggle-active",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["is_active"] == True

    @pytest.mark.asyncio
    async def test_delete_service(self, async_client: AsyncClient, admin_auth_headers: dict, db_session: AsyncSession):
        """Test deleting a service."""
        service = Service(name="To Delete", category="Test", is_active=True)
        db_session.add(service)
        await db_session.commit()
        await db_session.refresh(service)
        
        response = await async_client.delete(
            f"/api/v1/services/{service.id}",
            headers=admin_auth_headers
        )
        
        assert response.status_code == 204

    @pytest.mark.asyncio
    async def test_service_not_found(self, async_client: AsyncClient, auth_headers: dict):
        """Test accessing non-existent service."""
        response = await async_client.get(
            "/api/v1/services/999999",
            headers=auth_headers
        )
        
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()