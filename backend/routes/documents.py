from fastapi import APIRouter, Depends, HTTPException, status
from bson import ObjectId
import os
import logging

from models.database import get_db
from utils.auth import get_current_user
from utils.schemas import DocumentListResponse, DocumentInfo, CurrentUser
from rag.vectorstore import get_vector_store

logger = logging.getLogger(__name__)

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
        DocumentInfo.model_validate({
            "doc_id": doc["doc_id"],
            "filename": doc["filename"],
            "uploaded_at": doc.get("uploaded_at"),
            "chunk_count": doc.get("chunk_count", 0),
            "file_size": doc.get("file_size", 0)
        })
        for doc in documents
    ]
    
    return DocumentListResponse(
        documents=document_infos,
        total=len(document_infos)
    )


@router.get("/{doc_id}", response_model=DocumentInfo)
async def get_document(
    doc_id: str,
    current_user: CurrentUser = Depends(get_current_user),
    db=Depends(get_db)
):
    """Get a single document by ID for the current user."""
    document = await db.documents.find_one({
        "doc_id": doc_id,
        "user_id": ObjectId(current_user.id)
    })
    
    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found"
        )
    
    return DocumentInfo.model_validate({
        "doc_id": document["doc_id"],
        "filename": document["filename"],
        "uploaded_at": document.get("uploaded_at"),
        "chunk_count": document.get("chunk_count", 0),
        "file_size": document.get("file_size", 0)
    })


@router.delete("/{doc_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(
    doc_id: str,
    current_user: CurrentUser = Depends(get_current_user),
    db=Depends(get_db)
):
    """Delete a document and all its chunks from the vector store."""
    # Find the document and verify ownership
    document = await db.documents.find_one({
        "doc_id": doc_id,
        "user_id": ObjectId(current_user.id)
    })
    
    if not document:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found"
        )
    
    try:
        # Delete from vector store
        vector_store = get_vector_store()
        vector_store.delete_document(
            user_id=current_user.id,
            doc_id=doc_id
        )
        
        # Delete the file from disk if it exists
        file_path = document.get("file_path")
        if file_path and os.path.exists(file_path):
            try:
                os.remove(file_path)
            except Exception as e:
                # Log error but don't fail the request
                logger.warning(f"Failed to delete file {file_path}: {str(e)}")
        
        # Delete document record from database
        await db.documents.delete_one({
            "doc_id": doc_id,
            "user_id": ObjectId(current_user.id)
        })
        
        return None
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting document: {str(e)}"
    )

