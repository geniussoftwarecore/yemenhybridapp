# Run Commands

## Backend (DEV)

```bash
cd backend
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Database Migration
```bash
cd backend
uv run alembic upgrade head
```

### Environment
- ENV fallback to sqlite if DATABASE_URL not present
- Current setup uses PostgreSQL via DATABASE_URL environment variable
- Fallback: `sqlite+pysqlite:///./app.db`

### API Documentation
- Swagger: http://localhost:8000/docs
- Health: http://localhost:8000/health

## Frontend (WEB)

```bash
cd flutter_app
flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5000
```

### Alternative Chrome Development
```bash
cd flutter_app
flutter run -d chrome  # localhost:5173 if using webdev server
```

### Environment
- Base API URL from .env (flutter_dotenv)
- Current .env: `API_BASE_URL=https://76cd5cee-4cfd-41c5-98d7-ba005f97e2a4-00-1xk1vkpwt6mqt.janeway.replit.dev`

## Development URLs
- **Backend**: http://localhost:8000
- **Frontend**: http://localhost:5000
- **API Docs**: http://localhost:8000/docs