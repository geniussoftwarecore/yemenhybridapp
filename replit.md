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
- **SQLite** as default database with PostgreSQL support through configurable connection strings
- **Async database sessions** using asyncpg for PostgreSQL and aiosqlite for SQLite

### Authentication & Security
- **JWT-based authentication** with configurable expiration times
- **Bcrypt password hashing** for secure credential storage
- **Bearer token security** with optional authentication support
- **CORS middleware** with configurable allowed origins

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