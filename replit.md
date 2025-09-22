# Yemen Hybrid Backend API

## Overview

Yemen Hybrid Backend API is a FastAPI-based automotive service management system designed for a hybrid car service center. The application provides comprehensive customer, vehicle, work order, invoice, and reporting management capabilities. Built with clean architecture principles, it features a modular design with separated concerns across API routes, business use cases, services, and data layers.

The system is designed to handle automotive service workflows including customer management, vehicle tracking, work order processing, invoice generation, and business reporting. It includes notification capabilities through email and WhatsApp for customer communications and approval workflows.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Backend Framework
- **FastAPI** with async/await support for high-performance API endpoints
- **Clean Architecture** pattern with separated layers for API routes, use cases, services, and data access
- **Dependency Injection** using FastAPI's built-in system for loose coupling

### Database Layer
- **SQLAlchemy 2.0** with async support for ORM operations
- **Alembic** for database migrations and schema versioning
- **PostgreSQL** database configured via Replit's built-in database service
- **Async database sessions** using asyncpg for PostgreSQL connectivity
- **Database URL** automatically configured from environment variables

### Authentication & Security
- **JWT-based authentication** with configurable expiration times
- **Bcrypt password hashing** for secure credential storage
- **Bearer token security** with optional authentication support
- **CORS middleware** configured to allow all origins for Replit environment

### File Management
- **Local file storage** with configurable storage directory
- **File upload/download** capabilities through dedicated media endpoints
- **PDF generation service** for invoices and reports

### Business Logic Organization
- **Use Cases layer** for business workflows (approval processes, etc.)
- **Services layer** for external integrations (email, WhatsApp, PDF, storage)
- **Repository pattern** through SQLAlchemy models for data access

### API Design
- **RESTful endpoints** organized by domain (customers, vehicles, workorders, invoices)
- **Modular router system** with prefix-based organization
- **Standardized response patterns** with consistent error handling
- **Authentication-protected endpoints** with role-based access control

### Configuration Management
- **Pydantic Settings** for type-safe configuration
- **Environment variable support** with .env file loading
- **Database URL transformation** for async/sync compatibility

## External Dependencies

### Core Framework Dependencies
- **FastAPI** - Web framework and API development
- **SQLAlchemy** - Database ORM with async support
- **Alembic** - Database migration management
- **Pydantic** - Data validation and settings management

### Security & Authentication
- **PyJWT** - JWT token creation and verification
- **Passlib[bcrypt]** - Password hashing and verification
- **Python-multipart** - File upload handling

### Database Drivers
- **aiosqlite** - Async SQLite database driver
- **asyncpg** - Async PostgreSQL database driver (configurable)

### Notification Services
- **Twilio** (planned) - WhatsApp messaging integration
- **SMTP** (planned) - Email notification support

### File Processing
- **PDF generation library** (to be implemented) - Invoice and report generation
- **File storage** (local filesystem with cloud storage extensibility)

### Development Tools
- **python-dotenv** - Environment variable management
- **Logging** - Structured JSON logging for monitoring and debugging

## Recent Changes

### September 22, 2025 - Complete GitHub Import Setup and Fresh Environment Configuration
- **GitHub Import**: Successfully imported project from GitHub into fresh Replit environment
- **Asset Issues Resolved**: 
  - Recreated missing `assets/images/` and `assets/icons/` directories in Flutter app
  - Created new `.env` file with current Replit domain URL for API base URL
  - Fixed Flutter web initialization errors with updated loader configuration
- **Backend Configuration**: 
  - FastAPI server running on port 8000 with host 0.0.0.0 (localhost backend)
  - CORS settings properly configured for Replit environment (`allow_origins=["*"]`)
  - PostgreSQL database provisioned and connected via DATABASE_URL environment variable
  - All Alembic migrations successfully applied (7 migrations executed)
- **Frontend Configuration**:
  - Flutter Web running on port 5000 with host 0.0.0.0 (Replit frontend requirement)
  - API integration configured with current Replit domain URL
  - Compilation completed successfully (41.3 seconds build time)
  - Fixed Flutter web loader deprecation warnings in index.html
- **Database Setup**:
  - PostgreSQL database provisioned via Replit's built-in database service
  - All database tables created successfully through migration system
  - Database connectivity verified and operational
- **Workflow Setup**:
  - FastAPI Server workflow: Backend API running stably on port 8000
  - Flutter Web workflow: Frontend application running stably on port 5000
  - Both workflows configured for Replit environment and proxy compatibility
- **Production Deployment**:
  - Configured autoscale deployment target for optimal scaling
  - Build process configured for Flutter web production build
  - Production run configured to serve unified app on port 5000
- **Integration Testing**:
  - Backend API health endpoint verified (returns {"ok": true})
  - API documentation accessible at `/docs` endpoint
  - Authentication system operational (protected endpoints working)
  - Frontend application loading and displaying login interface correctly
  - Database migrations and connectivity fully verified
- **Import Status**: ✅ Fresh environment setup completed successfully with all services operational

## Project Status

**Current State**: ✅ Fully operational in Replit environment
- **API Server**: Running on port 8000 with FastAPI
- **Frontend**: Flutter Web running on port 5000
- **Database**: PostgreSQL with all migrations applied
- **Documentation**: Available at `/docs` endpoint
- **Health Check**: Available at `/health` endpoint
- **Deployment**: Configured for autoscale production deployment

**API Endpoints Available**:
- `GET /` - API information
- `GET /health` - Health check
- `GET /docs` - Swagger documentation
- `GET /api/v1/customers` - Customer management
- `GET /api/v1/vehicles` - Vehicle management  
- `GET /api/v1/workorders` - Work order management
- `GET /api/v1/invoices` - Invoice management
- `GET /api/v1/reports` - Reporting endpoints
- `GET /api/v1/media` - Media file management