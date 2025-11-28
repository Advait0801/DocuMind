from fastapi import APIRouter, Depends
from bson import ObjectId

from models.database import get_db
from utils.auth import get_current_user
from utils.schemas import DocumentListResponse, DocumentInfo, CurrentUser

router = APIRouter(prefix="/documents", tags=["documents"])


@router.get("", response_model=DocumentListResponse)
async def get_documents(
    current_user: CurrentUser = Depends(get_current_user),
    db=Depends(get_db)
):
    """Get all documents for the current user."""
    cursor = db.documents.find({"user_id": ObjectId(current_user.id)})
    documents = await cursor.to_list(length=None)
    
    document_infos = [
        DocumentInfo(
            doc_id=doc["doc_id"],
            filename=doc["filename"],
            uploaded_at=doc.get("uploaded_at"),
            chunk_count=doc.get("chunk_count", 0),
            file_size=doc.get("file_size", 0)
        )
        for doc in documents
    ]
    
    return DocumentListResponse(
        documents=document_infos,
        total=len(document_infos)
    )

