"""Authentication tests."""
import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.main import app
from app.db.session import AsyncSessionLocal
from app.db.models import User, UserRole
from app.core.security import get_password_hash

# Configure pytest-asyncio
pytestmark = pytest.mark.asyncio


@pytest_asyncio.fixture
async def async_client():
    """Create async test client."""
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac


@pytest_asyncio.fixture
async def db_session():
    """Create test database session."""
    async with AsyncSessionLocal() as session:
        yield session


@pytest_asyncio.fixture
async def test_users(db_session: AsyncSession):
    """Create test users with different roles."""
    # These should already exist from seed data, but let's ensure they exist
    users = {
        "admin": await db_session.get(User, 1),  # Should be admin from seed
        "sales": await db_session.get(User, 2),  # Should be sales from seed  
        "engineer": await db_session.get(User, 3)  # Should be engineer from seed
    }
    return users


class TestAuthentication:
    """Test authentication endpoints."""
    
    async def test_login_success(self, async_client: AsyncClient):
        """Test successful login."""
        response = await async_client.post(
            "/api/v1/auth/login",
            json={
                "email": "admin@yemenhybrid.com",
                "password": "Passw0rd!"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        assert "user" in data
        assert data["user"]["email"] == "admin@yemenhybrid.com"
        assert data["user"]["role"] == "admin"

    async def test_login_invalid_credentials(self, async_client: AsyncClient):
        """Test login with invalid credentials."""
        response = await async_client.post(
            "/api/v1/auth/login",
            json={
                "email": "admin@yemenhybrid.com",
                "password": "wrongpassword"
            }
        )
        
        assert response.status_code == 401
        data = response.json()
        assert data["detail"]["error"]["code"] == "INVALID_CREDENTIALS"

    async def test_login_nonexistent_user(self, async_client: AsyncClient):
        """Test login with non-existent user."""
        response = await async_client.post(
            "/api/v1/auth/login",
            json={
                "email": "nonexistent@example.com",
                "password": "password"
            }
        )
        
        assert response.status_code == 401
        data = response.json()
        assert data["detail"]["error"]["code"] == "INVALID_CREDENTIALS"

    async def test_me_endpoint_authenticated(self, async_client: AsyncClient):
        """Test /auth/me endpoint with valid token."""
        # First login to get token
        login_response = await async_client.post(
            "/api/v1/auth/login",
            json={
                "email": "admin@yemenhybrid.com",
                "password": "Passw0rd!"
            }
        )
        
        assert login_response.status_code == 200
        token = login_response.json()["access_token"]
        
        # Use token to access /me endpoint
        response = await async_client.get(
            "/api/v1/auth/me",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "admin@yemenhybrid.com"
        assert data["role"] == "admin"

    async def test_me_endpoint_unauthenticated(self, async_client: AsyncClient):
        """Test /auth/me endpoint without token."""
        response = await async_client.get("/api/v1/auth/me")
        
        assert response.status_code == 403  # HTTPBearer returns 403 for missing auth


class TestRoleBasedAccess:
    """Test role-based access control."""

    async def get_auth_headers(self, async_client: AsyncClient, email: str, password: str):
        """Helper to get auth headers for a user."""
        login_response = await async_client.post(
            "/api/v1/auth/login",
            json={"email": email, "password": password}
        )
        assert login_response.status_code == 200
        token = login_response.json()["access_token"]
        return {"Authorization": f"Bearer {token}"}

    async def test_admin_full_access(self, async_client: AsyncClient):
        """Test admin has full access."""
        headers = await self.get_auth_headers(async_client, "admin@yemenhybrid.com", "Passw0rd!")
        
        # Admin can access all endpoints
        endpoints = [
            ("GET", "/api/v1/invoices/"),
            ("POST", "/api/v1/invoices/"),
            ("DELETE", "/api/v1/invoices/1"),
            ("GET", "/api/v1/reports/sales"),
            ("DELETE", "/api/v1/workorders/1"),
        ]
        
        for method, endpoint in endpoints:
            if method == "GET":
                response = await async_client.get(endpoint, headers=headers)
            elif method == "POST":
                response = await async_client.post(endpoint, headers=headers, json={})
            elif method == "DELETE":
                response = await async_client.delete(endpoint, headers=headers)
            
            # Should not get 403 Forbidden (may get other errors for placeholder endpoints)
            assert response.status_code != 403

    async def test_sales_access(self, async_client: AsyncClient):
        """Test sales role access."""
        headers = await self.get_auth_headers(async_client, "sales@yemenhybrid.com", "Passw0rd!")
        
        # Sales can create/update invoices
        response = await async_client.post("/api/v1/invoices/", headers=headers, json={})
        assert response.status_code != 403
        
        # Sales can access sales reports
        response = await async_client.get("/api/v1/reports/sales", headers=headers)
        assert response.status_code != 403
        
        # Sales cannot delete invoices (admin only)
        response = await async_client.delete("/api/v1/invoices/1", headers=headers)
        assert response.status_code == 403

    async def test_engineer_restrictions(self, async_client: AsyncClient):
        """Test engineer role restrictions."""
        headers = await self.get_auth_headers(async_client, "engineer@yemenhybrid.com", "Passw0rd!")
        
        # Engineers can view invoices
        response = await async_client.get("/api/v1/invoices/", headers=headers)
        assert response.status_code != 403
        
        # Engineers cannot create invoices (sales/admin only)
        response = await async_client.post("/api/v1/invoices/", headers=headers, json={})
        assert response.status_code == 403
        
        # Engineers cannot access sales reports (sales/admin only)
        response = await async_client.get("/api/v1/reports/sales", headers=headers)
        assert response.status_code == 403
        
        # Engineers cannot delete work orders (admin only)
        response = await async_client.delete("/api/v1/workorders/1", headers=headers)
        assert response.status_code == 403

    async def test_unauthenticated_access(self, async_client: AsyncClient):
        """Test that unauthenticated requests are rejected."""
        endpoints = [
            "/api/v1/invoices/",
            "/api/v1/workorders/",
            "/api/v1/reports/sales",
        ]
        
        for endpoint in endpoints:
            response = await async_client.get(endpoint)
            assert response.status_code == 403  # HTTPBearer returns 403 for missing auth