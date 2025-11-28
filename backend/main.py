from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

from models.database import init_db, close_db
from routes import auth, ingestion, query, search, documents

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Suppress harmless warnings
logging.getLogger("passlib.handlers.bcrypt").setLevel(logging.ERROR)
logging.getLogger("chromadb.telemetry.product.posthog").setLevel(logging.ERROR)

# Initialize FastAPI app
app = FastAPI(
    title="DocuMind API",
    description="RAG-powered knowledge assistant backend",
    version="1.0.0"
)

# CORS middleware (configure for iOS app)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your iOS app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize database on startup
@app.on_event("startup")
async def startup_event():
    logger.info("Initializing database...")
    await init_db()
    logger.info("Database initialized")
    
    # Pre-load embedding model
    logger.info("Pre-loading embedding model...")
    from rag.vectorstore import get_embedding_model
    get_embedding_model()
    logger.info("Embedding model loaded")


@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Closing database connection...")
    await close_db()


# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy", "message": "DocuMind API is running"}


# Include routers
app.include_router(auth.router)
app.include_router(ingestion.router)
app.include_router(query.router)
app.include_router(search.router)
app.include_router(documents.router)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )

