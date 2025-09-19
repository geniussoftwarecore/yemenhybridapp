"""File storage service."""
import os
from typing import BinaryIO

class StorageService:
    def __init__(self, storage_dir: str = "./storage"):
        self.storage_dir = storage_dir
        os.makedirs(storage_dir, exist_ok=True)
    
    async def save_file(self, file: BinaryIO, filename: str) -> str:
        """Save uploaded file to storage."""
        # TODO: Implement file saving logic
        return f"{self.storage_dir}/{filename}"
    
    async def delete_file(self, filepath: str) -> bool:
        """Delete file from storage."""
        # TODO: Implement file deletion logic
        return True
    
    async def get_file_url(self, filepath: str) -> str:
        """Get URL for stored file."""
        # TODO: Implement file URL generation
        return f"/static/{filepath}"