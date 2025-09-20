"""Tests for work orders API endpoints."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timedelta
from decimal import Decimal

from app.db.models.customer import Customer
from app.db.models.vehicle import Vehicle
from app.db.models.work_order import WorkOrder, WorkOrderStatus, WorkOrderItem, ItemType


class TestWorkOrdersAPI:
    """Test work orders CRUD API."""

    @pytest.mark.asyncio
    async def test_create_workorder(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test creating a work order."""
        # Create customer and vehicle first
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.commit()
        await db_session.refresh(customer)
        await db_session.refresh(vehicle)
        
        workorder_data = {
            "customer_id": customer.id,
            "vehicle_id": vehicle.id,
            "complaint": "Engine noise",
            "notes": "Customer reports strange noise when starting"
        }
        
        response = await async_client.post(
            "/api/v1/workorders/",
            json=workorder_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["customer_id"] == workorder_data["customer_id"]
        assert data["vehicle_id"] == workorder_data["vehicle_id"]
        assert data["complaint"] == workorder_data["complaint"]
        assert data["status"] == "new"
        assert "id" in data
        assert "created_at" in data

    @pytest.mark.asyncio
    async def test_get_workorders_list(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test getting work orders list with pagination."""
        # Create customer, vehicle and work orders
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorders = [
            WorkOrder(customer_id=customer.id, vehicle_id=vehicle.id, complaint="Issue 1", created_by=1),
            WorkOrder(customer_id=customer.id, vehicle_id=vehicle.id, complaint="Issue 2", created_by=1),
        ]
        for workorder in workorders:
            db_session.add(workorder)
        await db_session.commit()
        
        response = await async_client.get("/api/v1/workorders/", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "page" in data

    @pytest.mark.asyncio
    async def test_filter_workorders_by_status(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test filtering work orders by status."""
        # Create customer, vehicle and work orders with different statuses
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorders = [
            WorkOrder(customer_id=customer.id, vehicle_id=vehicle.id, status=WorkOrderStatus.NEW, created_by=1),
            WorkOrder(customer_id=customer.id, vehicle_id=vehicle.id, status=WorkOrderStatus.IN_PROGRESS, created_by=1),
        ]
        for workorder in workorders:
            db_session.add(workorder)
        await db_session.commit()
        
        # Filter by NEW status
        response = await async_client.get(
            "/api/v1/workorders/?status=new",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        for item in data["items"]:
            assert item["status"] == "new"

    @pytest.mark.asyncio
    async def test_set_workorder_estimate(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test setting work order estimate."""
        # Create work order
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(customer_id=customer.id, vehicle_id=vehicle.id, created_by=1)
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        estimate_data = {
            "est_parts": "150.00",
            "est_labor": "200.00"
        }
        
        response = await async_client.patch(
            f"/api/v1/workorders/{workorder.id}/estimate",
            json=estimate_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert float(data["est_parts"]) == 150.00
        assert float(data["est_labor"]) == 200.00
        assert float(data["est_total"]) == 350.00  # Auto-calculated

    @pytest.mark.asyncio
    async def test_schedule_workorder(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test scheduling a work order."""
        # Create work order
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(customer_id=customer.id, vehicle_id=vehicle.id, created_by=1)
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        scheduled_time = (datetime.utcnow() + timedelta(days=1)).isoformat()
        schedule_data = {"scheduled_at": scheduled_time}
        
        response = await async_client.patch(
            f"/api/v1/workorders/{workorder.id}/schedule",
            json=schedule_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["scheduled_at"] is not None

    @pytest.mark.asyncio
    async def test_start_workorder_requires_ready_status(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test that starting work order requires ready_to_start status."""
        # Create work order in NEW status
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(
            customer_id=customer.id, 
            vehicle_id=vehicle.id, 
            status=WorkOrderStatus.NEW,
            created_by=1
        )
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        # Try to start when not in ready_to_start status
        response = await async_client.patch(
            f"/api/v1/workorders/{workorder.id}/start",
            headers=auth_headers
        )
        
        assert response.status_code == 400
        assert "ready_to_start" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_start_workorder_success(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test successfully starting a work order."""
        # Create work order in READY_TO_START status
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(
            customer_id=customer.id, 
            vehicle_id=vehicle.id, 
            status=WorkOrderStatus.READY_TO_START,
            created_by=1
        )
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        response = await async_client.patch(
            f"/api/v1/workorders/{workorder.id}/start",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "in_progress"
        assert data["started_at"] is not None

    @pytest.mark.asyncio
    async def test_finish_workorder(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test finishing a work order."""
        # Create work order
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(customer_id=customer.id, vehicle_id=vehicle.id, created_by=1)
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        response = await async_client.patch(
            f"/api/v1/workorders/{workorder.id}/finish",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "done"
        assert data["completed_at"] is not None

    @pytest.mark.asyncio
    async def test_close_workorder_admin_only(self, async_client: AsyncClient, admin_auth_headers: dict, db_session: AsyncSession):
        """Test closing a work order (admin only)."""
        # Create work order
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(customer_id=customer.id, vehicle_id=vehicle.id, created_by=1)
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        response = await async_client.patch(
            f"/api/v1/workorders/{workorder.id}/close",
            headers=admin_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "closed"

    @pytest.mark.asyncio
    async def test_add_workorder_item(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test adding an item to a work order."""
        # Create work order
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(customer_id=customer.id, vehicle_id=vehicle.id, created_by=1)
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        item_data = {
            "item_type": "part",
            "name": "Oil Filter",
            "qty": "1",
            "unit_price": "15.99"
        }
        
        response = await async_client.post(
            f"/api/v1/workorders/{workorder.id}/items",
            json=item_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["item_type"] == item_data["item_type"]
        assert data["name"] == item_data["name"]
        assert float(data["qty"]) == 1.0
        assert float(data["unit_price"]) == 15.99
        assert data["work_order_id"] == workorder.id

    @pytest.mark.asyncio
    async def test_delete_workorder_item(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test deleting a work order item."""
        # Create work order and item
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(customer_id=customer.id, vehicle_id=vehicle.id, created_by=1)
        db_session.add(workorder)
        await db_session.flush()
        
        item = WorkOrderItem(
            work_order_id=workorder.id,
            item_type=ItemType.PART,
            name="Oil Filter",
            qty=Decimal("1"),
            unit_price=Decimal("15.99")
        )
        db_session.add(item)
        await db_session.commit()
        await db_session.refresh(item)
        
        response = await async_client.delete(
            f"/api/v1/workorders/items/{item.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 204

    @pytest.mark.asyncio
    async def test_workorder_not_found(self, async_client: AsyncClient, auth_headers: dict):
        """Test accessing non-existent work order."""
        response = await async_client.get(
            "/api/v1/workorders/999999",
            headers=auth_headers
        )
        
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()

    @pytest.mark.asyncio
    async def test_create_workorder_invalid_customer(self, async_client: AsyncClient, auth_headers: dict):
        """Test creating work order with non-existent customer."""
        workorder_data = {
            "customer_id": 999999,  # Non-existent customer
            "vehicle_id": 1,
            "complaint": "Engine noise"
        }
        
        response = await async_client.post(
            "/api/v1/workorders/",
            json=workorder_data,
            headers=auth_headers
        )
        
        assert response.status_code == 400
        assert "Customer not found" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_create_workorder_invalid_vehicle(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test creating work order with non-existent vehicle."""
        # Create customer
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.commit()
        await db_session.refresh(customer)
        
        workorder_data = {
            "customer_id": customer.id,
            "vehicle_id": 999999,  # Non-existent vehicle
            "complaint": "Engine noise"
        }
        
        response = await async_client.post(
            "/api/v1/workorders/",
            json=workorder_data,
            headers=auth_headers
        )
        
        assert response.status_code == 400
        assert "Vehicle not found" in response.json()["detail"]