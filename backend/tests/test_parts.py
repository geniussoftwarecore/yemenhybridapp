"""Tests for parts API endpoints."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.service import Part


class TestPartsAPI:
    """Test parts CRUD API."""

    @pytest.mark.asyncio
    async def test_create_part(self, async_client: AsyncClient, auth_headers: dict):
        """Test creating a part."""
        part_data = {
            "name": "Oil Filter",
            "part_no": "OF-123",
            "supplier": "ACDelco",
            "stock": 50,
            "min_stock": 10,
            "buy_price": "12.99",
            "sell_price": "19.99",
            "location": "Shelf A-1"
        }
        
        response = await async_client.post(
            "/api/v1/parts/",
            json=part_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == part_data["name"]
        assert data["part_no"] == part_data["part_no"]
        assert data["supplier"] == part_data["supplier"]
        assert data["stock"] == part_data["stock"]
        assert "id" in data

    @pytest.mark.asyncio
    async def test_get_parts_list(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test getting parts list with pagination."""
        # Create test parts
        parts = [
            Part(name="Oil Filter", part_no="OF-123", stock=50, min_stock=10),
            Part(name="Air Filter", part_no="AF-456", stock=25, min_stock=5),
            Part(name="Brake Pad", part_no="BP-789", stock=15, min_stock=3),
        ]
        for part in parts:
            db_session.add(part)
        await db_session.commit()
        
        response = await async_client.get("/api/v1/parts/", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "page" in data

    @pytest.mark.asyncio
    async def test_filter_low_stock_parts(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test filtering parts with low stock."""
        # Create test parts with different stock levels
        parts = [
            Part(name="Low Stock Part", part_no="LSP-001", stock=2, min_stock=10),  # Low stock
            Part(name="Good Stock Part", part_no="GSP-001", stock=50, min_stock=10),  # Good stock
        ]
        for part in parts:
            db_session.add(part)
        await db_session.commit()
        
        response = await async_client.get(
            "/api/v1/parts/?low_stock=true",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        # Should only return parts where stock <= min_stock
        for item in data["items"]:
            assert item["stock"] <= item["min_stock"]

    @pytest.mark.asyncio
    async def test_search_parts(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test searching parts by name, part number, or supplier."""
        # Create test parts
        parts = [
            Part(name="Oil Filter", part_no="OF-123", supplier="ACDelco"),
            Part(name="Air Filter", part_no="AF-456", supplier="Bosch"),
            Part(name="Brake Pad", part_no="BP-789", supplier="Bendix"),
        ]
        for part in parts:
            db_session.add(part)
        await db_session.commit()
        
        # Search by name
        response = await async_client.get(
            "/api/v1/parts/?q=Oil",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len([item for item in data["items"] if "Oil" in item["name"]]) > 0
        
        # Search by part number
        response = await async_client.get(
            "/api/v1/parts/?q=OF-123",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len([item for item in data["items"] if "OF-123" in item["part_no"]]) > 0
        
        # Search by supplier
        response = await async_client.get(
            "/api/v1/parts/?q=ACDelco",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert len([item for item in data["items"] if "ACDelco" in item["supplier"]]) > 0

    @pytest.mark.asyncio
    async def test_get_part_by_id(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test getting a specific part by ID."""
        part = Part(name="Test Part", part_no="TP-001", stock=25, min_stock=5)
        db_session.add(part)
        await db_session.commit()
        await db_session.refresh(part)
        
        response = await async_client.get(
            f"/api/v1/parts/{part.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == part.id
        assert data["name"] == part.name

    @pytest.mark.asyncio
    async def test_update_part(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test updating a part."""
        part = Part(name="Original Part", part_no="OP-001", stock=25, min_stock=5)
        db_session.add(part)
        await db_session.commit()
        await db_session.refresh(part)
        
        update_data = {"name": "Updated Part", "buy_price": "15.99"}
        
        response = await async_client.put(
            f"/api/v1/parts/{part.id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["name"] == update_data["name"]
        assert float(data["buy_price"]) == float(update_data["buy_price"])

    @pytest.mark.asyncio
    async def test_adjust_part_stock(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test adjusting part stock quantity."""
        part = Part(name="Test Part", part_no="TP-001", stock=25, min_stock=5)
        db_session.add(part)
        await db_session.commit()
        await db_session.refresh(part)
        
        # Add stock
        response = await async_client.put(
            f"/api/v1/parts/{part.id}/adjust-stock",
            json={"delta": 10},
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["stock"] == 35  # Original 25 + 10
        
        # Subtract stock
        response = await async_client.put(
            f"/api/v1/parts/{part.id}/adjust-stock",
            json={"delta": -5},
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["stock"] == 30  # 35 - 5

    @pytest.mark.asyncio
    async def test_adjust_stock_negative_prevention(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test that stock adjustment prevents negative stock."""
        part = Part(name="Test Part", part_no="TP-001", stock=5, min_stock=5)
        db_session.add(part)
        await db_session.commit()
        await db_session.refresh(part)
        
        # Try to subtract more than available
        response = await async_client.put(
            f"/api/v1/parts/{part.id}/adjust-stock",
            json={"delta": -10},
            headers=auth_headers
        )
        
        assert response.status_code == 400
        assert "negative stock" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_delete_part(self, async_client: AsyncClient, admin_auth_headers: dict, db_session: AsyncSession):
        """Test deleting a part."""
        part = Part(name="To Delete", part_no="TD-001", stock=10, min_stock=5)
        db_session.add(part)
        await db_session.commit()
        await db_session.refresh(part)
        
        response = await async_client.delete(
            f"/api/v1/parts/{part.id}",
            headers=admin_auth_headers
        )
        
        assert response.status_code == 204

    @pytest.mark.asyncio
    async def test_part_not_found(self, async_client: AsyncClient, auth_headers: dict):
        """Test accessing non-existent part."""
        response = await async_client.get(
            "/api/v1/parts/999999",
            headers=auth_headers
        )
        
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()