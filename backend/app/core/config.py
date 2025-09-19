from typing import List
from pydantic_settings import BaseSettings
from pydantic import field_validator
import os
from dotenv import load_dotenv

load_dotenv()

class Settings(BaseSettings):
    # Database (sync URL for Alembic, converted to async for app)
    database_url: str = os.getenv("DATABASE_URL", "sqlite+pysqlite:///./app.db")
    
    @property
    def async_database_url(self) -> str:
        """Convert database URL to use async driver."""
        if self.database_url.startswith("postgresql://"):
            # Convert to asyncpg and remove unsupported params
            url = self.database_url.replace("postgresql://", "postgresql+asyncpg://", 1)
            # Remove sslmode parameter as asyncpg doesn't support it in URL
            if "?sslmode=" in url:
                url = url.split("?sslmode=")[0]
            return url
        elif self.database_url.startswith("sqlite+pysqlite://"):
            # Convert SQLite to async driver
            return self.database_url.replace("sqlite+pysqlite://", "sqlite+aiosqlite://", 1)
        return self.database_url
    
    # JWT
    jwt_secret: str = "devsecret"
    jwt_algorithm: str = "HS256"
    jwt_expire_hours: int = 24
    
    # CORS - Allow all origins for Replit environment
    allowed_origins: str = "*"
    
    # Storage
    storage_dir: str = "./storage"
    
    # Email
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_pass: str = ""
    
    # WhatsApp
    whatsapp_sid: str = ""
    whatsapp_token: str = ""
    whatsapp_from: str = ""
    
    @property
    def cors_origins(self) -> List[str]:
        """Parse CORS origins from string."""
        if isinstance(self.allowed_origins, str) and self.allowed_origins:
            if self.allowed_origins == "*":
                return ["*"]
            return [origin.strip() for origin in self.allowed_origins.split(",")]
        return ["*"]

    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()