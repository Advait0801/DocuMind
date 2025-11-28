from pydantic import BaseModel, EmailStr, ConfigDict
from typing import Optional, List
from datetime import datetime


# Auth Schemas
class UserRegister(BaseModel):
    username: str
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    username_or_email: str  # Can be either username or email
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    user_id: Optional[str] = None
    email: Optional[str] = None
    username: Optional[str] = None


class CurrentUser(BaseModel):
    id: str
    username: str
    email: EmailStr


# Document Schemas
class DocumentInfo(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    
    doc_id: str
    filename: str
    uploaded_at: datetime
    chunk_count: int
    file_size: int


class DocumentListResponse(BaseModel):
    documents: List[DocumentInfo]
    total: int


# Upload Schemas
class UploadResponse(BaseModel):
    doc_id: str
    filename: str
    chunks_created: int
    message: str


# Query Schemas
class QueryRequest(BaseModel):
    query: str
    doc_ids: Optional[List[str]] = None  # Filter by specific documents
    top_k: int = 5
    stream: bool = True


class QueryChunk(BaseModel):
    content: str
    doc_id: str
    chunk_id: str
    score: float
    metadata: dict


class QueryResponse(BaseModel):
    answer: str
    chunks: List[QueryChunk]
    query: str


# Search Schemas
class SearchRequest(BaseModel):
    query: str
    doc_ids: Optional[List[str]] = None
    top_k: int = 10


class SearchResult(BaseModel):
    content: str
    doc_id: str
    chunk_id: str
    score: float
    metadata: dict


class SearchResponse(BaseModel):
    results: List[SearchResult]
    query: str
    total: int


# Health Check
class HealthResponse(BaseModel):
    status: str
    message: str

