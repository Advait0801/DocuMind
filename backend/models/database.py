import os
from typing import Optional, Tuple
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pymongo import ASCENDING

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
MONGODB_DB_NAME = os.getenv("MONGODB_DB_NAME", "documind")

_client: Optional[AsyncIOMotorClient] = None
_database: Optional[AsyncIOMotorDatabase] = None


def _get_client_and_db() -> Tuple[AsyncIOMotorClient, AsyncIOMotorDatabase]:
    """Create (or reuse) the MongoDB client and database."""
    global _client, _database
    if _client is None or _database is None:
        _client = AsyncIOMotorClient(MONGODB_URI)
        _database = _client[MONGODB_DB_NAME]
    return _client, _database


def get_db() -> AsyncIOMotorDatabase:
    """FastAPI dependency to retrieve the Mongo database."""
    _, database = _get_client_and_db()
    return database


async def init_db():
    """
    Initialize MongoDB by ensuring indexes exist.
    This runs once on application startup.
    """
    _, database = _get_client_and_db()

    # Ensure indexes for faster lookups + uniqueness
    await database.users.create_index("username", unique=True)
    await database.users.create_index("email", unique=True)
    await database.documents.create_index("doc_id", unique=True)
    await database.documents.create_index([("user_id", ASCENDING), ("uploaded_at", ASCENDING)])
    await database.revoked_tokens.create_index("token", unique=True)
    await database.revoked_tokens.create_index("expires_at", expireAfterSeconds=0)


async def close_db():
    """Close the MongoDB connection."""
    global _client
    if _client is not None:
        _client.close()
        _client = None

