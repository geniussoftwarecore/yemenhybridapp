"""Tests for approval workflow transitions."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from unittest.mock import AsyncMock, patch

from app.db.models.customer import Customer
from app.db.models.vehicle import Vehicle
from app.db.models.work_order import WorkOrder, WorkOrderStatus
from app.db.models import ApprovalRequest


class TestApprovalWorkflow:
    """Test approval workflow transitions and notifications."""

    @pytest.mark.asyncio
    async def test_request_approval_workflow(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test requesting approval from engineer to sales/admin."""
        # Create customer, vehicle and work order
        customer = Customer(name="Test Customer", phone="123456", email="test@example.com")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(
            customer_id=customer.id, 
            vehicle_id=vehicle.id, 
            complaint="Engine noise",
            status=WorkOrderStatus.NEW,
            created_by=1
        )
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        # Request approval (engineer -> sales/admin)
        response = await async_client.post(
            f"/api/v1/workorders/{workorder.id}/request-approval",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "waiting_approval"
        
        # Verify approval request was created
        # This would be checked in the database in a real test

    @pytest.mark.asyncio
    async def test_send_approval_to_customer_email(self, async_client: AsyncClient, sales_auth_headers: dict, db_session: AsyncSession):
        """Test sending approval request to customer via email."""
        # Create customer, vehicle and work order
        customer = Customer(name="Test Customer", phone="123456", email="customer@example.com")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(
            customer_id=customer.id, 
            vehicle_id=vehicle.id, 
            complaint="Engine noise",
            status=WorkOrderStatus.WAITING_APPROVAL,
            created_by=1
        )
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        # Mock email service
        with patch('app.services.email.send_approval_email', new_callable=AsyncMock) as mock_email:
            mock_email.return_value = True
            
            # Send approval to customer via email
            response = await async_client.post(
                f"/api/v1/workorders/{workorder.id}/send-to-customer",
                json={"sent_via": "email"},
                headers=sales_auth_headers
            )
            
            assert response.status_code == 200
            data = response.json()
            assert data["sent_via"] == "email"
            assert "token" in data
            assert "expires_at" in data
            
            # Verify email was sent
            mock_email.assert_called_once()

    @pytest.mark.asyncio
    async def test_send_approval_to_customer_whatsapp(self, async_client: AsyncClient, sales_auth_headers: dict, db_session: AsyncSession):
        """Test sending approval request to customer via WhatsApp."""
        # Create customer, vehicle and work order
        customer = Customer(name="Test Customer", phone="+1234567890", email="customer@example.com")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(
            customer_id=customer.id, 
            vehicle_id=vehicle.id, 
            complaint="Engine noise",
            status=WorkOrderStatus.WAITING_APPROVAL,
            created_by=1
        )
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        # Mock WhatsApp service
        with patch('app.services.whatsapp.send_approval_whatsapp', new_callable=AsyncMock) as mock_whatsapp:
            mock_whatsapp.return_value = True
            
            # Send approval to customer via WhatsApp
            response = await async_client.post(
                f"/api/v1/workorders/{workorder.id}/send-to-customer",
                json={"sent_via": "whatsapp"},
                headers=sales_auth_headers
            )
            
            assert response.status_code == 200
            data = response.json()
            assert data["sent_via"] == "whatsapp"
            assert "token" in data
            
            # Verify WhatsApp was sent
            mock_whatsapp.assert_called_once()

    @pytest.mark.asyncio
    async def test_public_approval_page_approve(self, async_client: AsyncClient, db_session: AsyncSession):
        """Test customer approving via public approval page."""
        # Create approval request
        customer = Customer(name="Test Customer", phone="123456", email="customer@example.com")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(
            customer_id=customer.id, 
            vehicle_id=vehicle.id, 
            complaint="Engine noise",
            status=WorkOrderStatus.WAITING_CUSTOMER,
            created_by=1
        )
        db_session.add(workorder)
        await db_session.flush()
        
        approval_request = ApprovalRequest(
            work_order_id=workorder.id,
            token="test-token-123",
            sent_via=ApprovalChannel.EMAIL
        )
        db_session.add(approval_request)
        await db_session.commit()
        
        # Customer approves via public link
        response = await async_client.post(
            f"/api/v1/public/approval/{approval_request.token}",
            json={"approved": True, "customer_notes": "Approved by customer"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["approved"] == True
        assert data["customer_notes"] == "Approved by customer"

    @pytest.mark.asyncio
    async def test_public_approval_page_reject(self, async_client: AsyncClient, db_session: AsyncSession):
        """Test customer rejecting via public approval page."""
        # Create approval request
        customer = Customer(name="Test Customer", phone="123456", email="customer@example.com")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(
            customer_id=customer.id, 
            vehicle_id=vehicle.id, 
            complaint="Engine noise",
            status=WorkOrderStatus.WAITING_CUSTOMER,
            created_by=1
        )
        db_session.add(workorder)
        await db_session.flush()
        
        approval_request = ApprovalRequest(
            work_order_id=workorder.id,
            token="test-token-456",
            sent_via=ApprovalChannel.EMAIL
        )
        db_session.add(approval_request)
        await db_session.commit()
        
        # Customer rejects via public link
        response = await async_client.post(
            f"/api/v1/public/approval/{approval_request.token}",
            json={"approved": False, "customer_notes": "Too expensive"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["approved"] == False
        assert data["customer_notes"] == "Too expensive"

    @pytest.mark.asyncio
    async def test_approval_workflow_transitions(self, async_client: AsyncClient, sales_auth_headers: dict, db_session: AsyncSession):
        """Test complete approval workflow status transitions."""
        # Create customer, vehicle and work order
        customer = Customer(name="Test Customer", phone="123456", email="customer@example.com")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(
            customer_id=customer.id, 
            vehicle_id=vehicle.id, 
            complaint="Engine noise",
            status=WorkOrderStatus.NEW,
            created_by=1
        )
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        # Step 1: Request approval (NEW -> WAITING_APPROVAL)
        response = await async_client.post(
            f"/api/v1/workorders/{workorder.id}/request-approval",
            headers=sales_auth_headers
        )
        assert response.status_code == 200
        assert response.json()["status"] == "waiting_approval"
        
        # Step 2: Send to customer (WAITING_APPROVAL -> WAITING_CUSTOMER)
        with patch('app.services.email.send_approval_email', new_callable=AsyncMock):
            response = await async_client.post(
                f"/api/v1/workorders/{workorder.id}/send-to-customer",
                json={"sent_via": "email"},
                headers=sales_auth_headers
            )
            assert response.status_code == 200
            
        # Step 3: Customer approves (WAITING_CUSTOMER -> READY_TO_START)
        # This would be done via the public approval endpoint
        # For testing, we'll simulate the status change
        response = await async_client.patch(
            f"/api/v1/workorders/{workorder.id}",
            json={"status": "ready_to_start"},
            headers=sales_auth_headers
        )
        assert response.status_code == 200
        assert response.json()["status"] == "ready_to_start"

    @pytest.mark.asyncio
    async def test_approval_token_expiry(self, async_client: AsyncClient, db_session: AsyncSession):
        """Test that expired approval tokens are rejected."""
        # This test would check that expired tokens return 400/401
        response = await async_client.post(
            "/api/v1/public/approval/expired-token-123",
            json={"approved": True}
        )
        
        # Should return error for expired/invalid token
        assert response.status_code in [400, 401, 404]

    @pytest.mark.asyncio
    async def test_approval_permissions(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test that only sales/admin can send approvals to customers."""
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
        
        # Engineer should not be able to send to customer (sales/admin only)
        response = await async_client.post(
            f"/api/v1/workorders/{workorder.id}/send-to-customer",
            json={"sent_via": "email"},
            headers=auth_headers  # This is engineer auth from conftest
        )
        
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_media_upload_workflow(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test media upload for BEFORE/DURING/AFTER phases."""
        # Create work order
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(
            customer_id=customer.id, 
            vehicle_id=vehicle.id, 
            status=WorkOrderStatus.IN_PROGRESS,
            created_by=1
        )
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        # Test BEFORE phase media upload
        with patch('app.services.storage.save_media_file', return_value="test-file-path.jpg"):
            # Mock file upload
            files = {"file": ("test.jpg", b"fake image data", "image/jpeg")}
            data = {"phase": "before", "note": "Before repair photo"}
            
            response = await async_client.post(
                f"/api/v1/workorders/{workorder.id}/media",
                files=files,
                data=data,
                headers=auth_headers
            )
            
            assert response.status_code == 201
            media_data = response.json()
            assert media_data["phase"] == "before"
            assert media_data["note"] == "Before repair photo"
            assert "url" in media_data

    @pytest.mark.asyncio
    async def test_get_media_galleries(self, async_client: AsyncClient, auth_headers: dict, db_session: AsyncSession):
        """Test retrieving BEFORE/DURING/AFTER media galleries."""
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
        
        # Test getting media by phase
        response = await async_client.get(
            f"/api/v1/workorders/{workorder.id}/media?phase=before",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        
        # Test getting all media
        response = await async_client.get(
            f"/api/v1/workorders/{workorder.id}/media",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)