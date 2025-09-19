"""FastAPI application main module."""
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
import time
import os

from .core.config import settings
from .db.session import engine
from .db.base import Base

# Import all routers
from .api import auth, customers, vehicles, workorders, media, invoices, reports

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='{"timestamp": "%(asctime)s", "level": "%(levelname)s", "message": "%(message)s", "module": "%(name)s"}',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events."""
    # Startup
    logger.info("Starting FastAPI application")
    
    # Create database tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    # Create storage directory
    os.makedirs(settings.storage_dir, exist_ok=True)
    
    yield
    
    # Shutdown
    logger.info("Shutting down FastAPI application")
    await engine.dispose()

# Create FastAPI app
app = FastAPI(
    title="Yemen Hybrid Backend API",
    description="FastAPI backend with clean architecture",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all incoming requests."""
    start_time = time.time()
    
    # Log request
    client_ip = request.client.host if request.client else "unknown"
    logger.info(f'{{"method": "{request.method}", "url": "{request.url}", "client_ip": "{client_ip}"}}')
    
    try:
        response = await call_next(request)
        process_time = time.time() - start_time
        
        # Log response
        logger.info(f'{{"method": "{request.method}", "url": "{request.url}", "status_code": {response.status_code}, "process_time": {process_time:.4f}}}')
        
        return response
    except Exception as e:
        process_time = time.time() - start_time
        logger.error(f'{{"method": "{request.method}", "url": "{request.url}", "error": "{str(e)}", "process_time": {process_time:.4f}}}')
        
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"error": {"code": "INTERNAL_ERROR", "message": "Internal server error"}}
        )

# Root endpoint
@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "message": "Yemen Hybrid Backend API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health"
    }

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"ok": True}

# Mount static files if storage directory exists
if os.path.exists(settings.storage_dir):
    app.mount("/static", StaticFiles(directory=settings.storage_dir), name="static")

# Include routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(customers.router, prefix="/api/v1")
app.include_router(vehicles.router, prefix="/api/v1")
app.include_router(workorders.router, prefix="/api/v1")
app.include_router(media.router, prefix="/api/v1")
app.include_router(invoices.router, prefix="/api/v1")
app.include_router(reports.router, prefix="/api/v1")

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler with consistent error format."""
    logger.error(f'{{"url": "{request.url}", "method": "{request.method}", "error": "{str(exc)}", "type": "{type(exc).__name__}"}}')
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"error": {"code": "INTERNAL_ERROR", "message": "Internal server error"}}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=5000, reload=True)