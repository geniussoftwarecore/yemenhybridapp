from sqlalchemy import MetaData
from sqlalchemy.ext.declarative import declarative_base

# SQLAlchemy base for all models
metadata = MetaData()
Base = declarative_base(metadata=metadata)