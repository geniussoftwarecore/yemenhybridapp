"""Tests for invoice generation and PDF handling."""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from unittest.mock import patch, AsyncMock
from decimal import Decimal

from app.db.models.customer import Customer
from app.db.models.vehicle import Vehicle
from app.db.models.work_order import WorkOrder, WorkOrderStatus, WorkOrderItem, ItemType
from app.db.models import Invoice


class TestInvoiceGeneration:
    """Test invoice creation, PDF generation, and payment processing."""

    @pytest.mark.asyncio
    async def test_create_invoice_from_workorder(self, async_client: AsyncClient, sales_auth_headers: dict, db_session: AsyncSession):
        """Test creating invoice from completed work order."""
        # Create customer, vehicle and work order with items
        customer = Customer(name="Test Customer", phone="123456", email="test@example.com")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(
            customer_id=customer.id, 
            vehicle_id=vehicle.id, 
            complaint="Oil change",
            status=WorkOrderStatus.DONE,
            created_by=1
        )
        db_session.add(workorder)
        await db_session.flush()
        
        # Add items to work order
        items = [
            WorkOrderItem(
                work_order_id=workorder.id,
                item_type=ItemType.PART,
                name="Oil Filter",
                qty=Decimal("1"),
                unit_price=Decimal("15.99")
            ),
            WorkOrderItem(
                work_order_id=workorder.id,
                item_type=ItemType.SERVICE,
                name="Oil Change Labor",
                qty=Decimal("1"),
                unit_price=Decimal("50.00")
            )
        ]
        for item in items:
            db_session.add(item)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        # Create invoice from work order
        invoice_data = {
            "work_order_id": workorder.id,
            "discount": "5.00"  # $5 discount
        }
        
        response = await async_client.post(
            "/api/v1/invoices/",
            json=invoice_data,
            headers=sales_auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["work_order_id"] == workorder.id
        assert data["customer_id"] == customer.id
        assert float(data["subtotal"]) == 65.99  # 15.99 + 50.00
        assert float(data["discount"]) == 5.00
        assert float(data["tax_amount"]) > 0  # Should calculate tax
        assert float(data["total"]) > 0
        assert data["status"] == "draft"
        assert "invoice_number" in data

    @pytest.mark.asyncio
    async def test_invoice_calculations(self, async_client: AsyncClient, sales_auth_headers: dict, db_session: AsyncSession):
        """Test invoice subtotal, tax, and total calculations."""
        # Create customer, vehicle and work order with items
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(
            customer_id=customer.id, 
            vehicle_id=vehicle.id, 
            status=WorkOrderStatus.DONE,
            created_by=1
        )
        db_session.add(workorder)
        await db_session.flush()
        
        # Add items totaling $100
        items = [
            WorkOrderItem(
                work_order_id=workorder.id,
                item_type=ItemType.PART,
                name="Part 1",
                qty=Decimal("2"),
                unit_price=Decimal("25.00")  # 2 * 25 = 50
            ),
            WorkOrderItem(
                work_order_id=workorder.id,
                item_type=ItemType.SERVICE,
                name="Service 1",
                qty=Decimal("1"),
                unit_price=Decimal("50.00")  # 1 * 50 = 50
            )
        ]
        for item in items:
            db_session.add(item)
        await db_session.commit()
        
        # Create invoice with 10% discount
        invoice_data = {
            "work_order_id": workorder.id,
            "discount": "10.00"  # $10 discount
        }
        
        response = await async_client.post(
            "/api/v1/invoices/",
            json=invoice_data,
            headers=sales_auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        
        # Verify calculations
        assert float(data["subtotal"]) == 100.00  # 50 + 50
        assert float(data["discount"]) == 10.00
        discounted_amount = 100.00 - 10.00  # 90.00
        expected_tax = discounted_amount * 0.15  # 15% tax = 13.50
        expected_total = discounted_amount + expected_tax  # 90 + 13.50 = 103.50
        
        assert abs(float(data["tax_amount"]) - expected_tax) < 0.01
        assert abs(float(data["total"]) - expected_total) < 0.01

    @pytest.mark.asyncio
    async def test_generate_invoice_pdf(self, async_client: AsyncClient, sales_auth_headers: dict, db_session: AsyncSession):
        """Test generating PDF for invoice."""
        # Create invoice
        customer = Customer(name="Test Customer", phone="123456", email="test@example.com")
        db_session.add(customer)
        await db_session.flush()
        
        invoice = Invoice(
            customer_id=customer.id,
            work_order_id=1,  # Mock work order ID
            subtotal=Decimal("100.00"),
            tax_amount=Decimal("15.00"),
            total=Decimal("115.00"),
            status=InvoiceStatus.SENT
        )
        db_session.add(invoice)
        await db_session.commit()
        await db_session.refresh(invoice)
        
        # Mock PDF generation service
        with patch('app.services.pdf.generate_invoice_pdf', return_value="https://example.com/invoice.pdf") as mock_pdf:
            # Generate PDF
            response = await async_client.get(
                f"/api/v1/invoices/{invoice.id}/pdf",
                headers=sales_auth_headers
            )
            
            assert response.status_code == 200
            data = response.json()
            assert "pdf_url" in data
            assert data["pdf_url"] == "https://example.com/invoice.pdf"
            
            # Verify PDF service was called
            mock_pdf.assert_called_once()

    @pytest.mark.asyncio
    async def test_process_invoice_payment(self, async_client: AsyncClient, sales_auth_headers: dict, db_session: AsyncSession):
        """Test processing payment for invoice."""
        # Create invoice
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        invoice = Invoice(
            customer_id=customer.id,
            work_order_id=1,
            subtotal=Decimal("100.00"),
            tax_amount=Decimal("15.00"),
            total=Decimal("115.00"),
            status=InvoiceStatus.SENT
        )
        db_session.add(invoice)
        await db_session.commit()
        await db_session.refresh(invoice)
        
        # Process payment
        payment_data = {
            "amount": "115.00",
            "payment_method": "cash",
            "notes": "Paid in full"
        }
        
        response = await async_client.post(
            "/api/v1/invoices/payments",
            json={
                "invoice_id": invoice.id,
                **payment_data
            },
            headers=sales_auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert float(data["amount"]) == 115.00
        assert data["payment_method"] == "cash"
        assert data["notes"] == "Paid in full"

    @pytest.mark.asyncio
    async def test_finalize_invoice(self, async_client: AsyncClient, sales_auth_headers: dict, db_session: AsyncSession):
        """Test finalizing invoice (changing from draft to sent)."""
        # Create draft invoice
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        invoice = Invoice(
            customer_id=customer.id,
            work_order_id=1,
            subtotal=Decimal("100.00"),
            tax_amount=Decimal("15.00"),
            total=Decimal("115.00"),
            status=InvoiceStatus.DRAFT
        )
        db_session.add(invoice)
        await db_session.commit()
        await db_session.refresh(invoice)
        
        # Finalize invoice
        response = await async_client.put(
            f"/api/v1/invoices/{invoice.id}/finalize",
            headers=sales_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "sent"
        assert data["issued_at"] is not None

    @pytest.mark.asyncio
    async def test_invoice_duplicate_prevention(self, async_client: AsyncClient, sales_auth_headers: dict, db_session: AsyncSession):
        """Test that duplicate invoices for same work order are prevented."""
        # Create customer, vehicle and work order
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(
            customer_id=customer.id, 
            vehicle_id=vehicle.id, 
            status=WorkOrderStatus.DONE,
            created_by=1
        )
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        # Create first invoice
        invoice_data = {"work_order_id": workorder.id}
        
        response1 = await async_client.post(
            "/api/v1/invoices/",
            json=invoice_data,
            headers=sales_auth_headers
        )
        assert response1.status_code == 201
        
        # Try to create duplicate invoice
        response2 = await async_client.post(
            "/api/v1/invoices/",
            json=invoice_data,
            headers=sales_auth_headers
        )
        assert response2.status_code == 400
        assert "already exists" in response2.json()["detail"]

    @pytest.mark.asyncio
    async def test_invoice_permissions(self, async_client: AsyncClient, auth_headers: dict, sales_auth_headers: dict, admin_auth_headers: dict, db_session: AsyncSession):
        """Test invoice permissions by role."""
        # Create invoice
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        invoice = Invoice(
            customer_id=customer.id,
            work_order_id=1,
            subtotal=Decimal("100.00"),
            tax_amount=Decimal("15.00"),
            total=Decimal("115.00"),
            status=InvoiceStatus.DRAFT
        )
        db_session.add(invoice)
        await db_session.commit()
        await db_session.refresh(invoice)
        
        # Engineers can view invoices
        response = await async_client.get(
            f"/api/v1/invoices/{invoice.id}",
            headers=auth_headers  # Engineer
        )
        assert response.status_code == 200
        
        # Engineers cannot create invoices
        response = await async_client.post(
            "/api/v1/invoices/",
            json={"work_order_id": 1},
            headers=auth_headers  # Engineer
        )
        assert response.status_code == 403
        
        # Sales can create and finalize invoices
        response = await async_client.put(
            f"/api/v1/invoices/{invoice.id}/finalize",
            headers=sales_auth_headers
        )
        assert response.status_code == 200
        
        # Only admin can delete invoices
        response = await async_client.delete(
            f"/api/v1/invoices/{invoice.id}",
            headers=sales_auth_headers  # Sales cannot delete
        )
        assert response.status_code == 403
        
        response = await async_client.delete(
            f"/api/v1/invoices/{invoice.id}",
            headers=admin_auth_headers  # Admin can delete
        )
        assert response.status_code == 204

    @pytest.mark.asyncio
    async def test_invoice_number_generation(self, async_client: AsyncClient, sales_auth_headers: dict, db_session: AsyncSession):
        """Test that invoice numbers are generated automatically and unique."""
        # Create multiple invoices and verify unique invoice numbers
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        # Create multiple work orders and invoices
        invoice_numbers = []
        for i in range(3):
            workorder = WorkOrder(
                customer_id=customer.id, 
                vehicle_id=vehicle.id, 
                complaint=f"Issue {i}",
                status=WorkOrderStatus.DONE,
                created_by=1
            )
            db_session.add(workorder)
            await db_session.flush()
            
            response = await async_client.post(
                "/api/v1/invoices/",
                json={"work_order_id": workorder.id},
                headers=sales_auth_headers
            )
            
            assert response.status_code == 201
            data = response.json()
            assert "invoice_number" in data
            assert data["invoice_number"] not in invoice_numbers  # Should be unique
            invoice_numbers.append(data["invoice_number"])

    @pytest.mark.asyncio
    async def test_invoice_with_no_items(self, async_client: AsyncClient, sales_auth_headers: dict, db_session: AsyncSession):
        """Test creating invoice from work order with no items."""
        # Create work order with no items
        customer = Customer(name="Test Customer", phone="123456")
        db_session.add(customer)
        await db_session.flush()
        
        vehicle = Vehicle(customer_id=customer.id, plate_no="ABC-123", make="Toyota", model="Prius")
        db_session.add(vehicle)
        await db_session.flush()
        
        workorder = WorkOrder(
            customer_id=customer.id, 
            vehicle_id=vehicle.id, 
            status=WorkOrderStatus.DONE,
            created_by=1
        )
        db_session.add(workorder)
        await db_session.commit()
        await db_session.refresh(workorder)
        
        # Create invoice from work order with no items
        response = await async_client.post(
            "/api/v1/invoices/",
            json={"work_order_id": workorder.id},
            headers=sales_auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert float(data["subtotal"]) == 0.00
        assert float(data["tax_amount"]) == 0.00
        assert float(data["total"]) == 0.00