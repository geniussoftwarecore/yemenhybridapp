"""Test configuration and fixtures."""
import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.main import app
from app.db.session import AsyncSessionLocal


@pytest_asyncio.fixture
async def async_client():
    """Create async test client."""
    from fastapi.testclient import TestClient
    with TestClient(app) as client:
        # Convert TestClient to async interface for our tests
        from httpx import AsyncClient
        async with AsyncClient(base_url="http://testserver") as ac:
            # Override methods to use the TestClient
            original_request = ac.request
            def sync_request(method, url, **kwargs):
                return client.request(method, str(url), **kwargs)
            ac.request = sync_request
            ac.get = lambda url, **kwargs: client.get(str(url), **kwargs)
            ac.post = lambda url, **kwargs: client.post(str(url), **kwargs)
            ac.put = lambda url, **kwargs: client.put(str(url), **kwargs)
            ac.delete = lambda url, **kwargs: client.delete(str(url), **kwargs)
            yield ac


@pytest_asyncio.fixture
async def db_session():
    """Create test database session."""
    async with AsyncSessionLocal() as session:
        yield session


@pytest_asyncio.fixture
async def auth_headers(async_client: AsyncClient):
    """Get authentication headers for a regular user."""
    login_response = await async_client.post(
        "/api/v1/auth/login",
        json={
            "email": "engineer@yemenhybrid.com",
            "password": "Passw0rd!"
        }
    )
    assert login_response.status_code == 200
    token = login_response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def admin_auth_headers(async_client: AsyncClient):
    """Get authentication headers for an admin user."""
    login_response = await async_client.post(
        "/api/v1/auth/login",
        json={
            "email": "admin@yemenhybrid.com",
            "password": "Passw0rd!"
        }
    )
    assert login_response.status_code == 200
    token = login_response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def sales_auth_headers(async_client: AsyncClient):
    """Get authentication headers for a sales user."""
    login_response = await async_client.post(
        "/api/v1/auth/login",
        json={
            "email": "sales@yemenhybrid.com",
            "password": "Passw0rd!"
        }
    )
    assert login_response.status_code == 200
    token = login_response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


# Configure pytest to run async tests by default
pytestmark = pytest.mark.asyncio