from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
import os
import uuid
import aiofiles
from datetime import datetime, timezone
from bson import ObjectId

from models.database import get_db
from utils.auth import get_current_user
from utils.schemas import UploadResponse, CurrentUser
from utils.pdf_parser import get_pdf_metadata
from rag.ingest import ingest_pdf

router = APIRouter(prefix="/upload", tags=["ingestion"])

# Upload directory
UPLOAD_DIR = "./data/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)


@router.post("", response_model=UploadResponse, status_code=status.HTTP_201_CREATED)
async def upload_pdf(
    file: UploadFile = File(...),
    current_user: CurrentUser = Depends(get_current_user),
    db=Depends(get_db)
):
    """Upload and ingest a PDF file."""
    # Validate file type
    if not file.filename.endswith('.pdf'):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only PDF files are supported"
        )
    
    # Generate unique document ID
    doc_id = str(uuid.uuid4())
    
    # Save file
    file_path = os.path.join(UPLOAD_DIR, f"{doc_id}_{file.filename}")
    
    try:
        async with aiofiles.open(file_path, 'wb') as f:
            content = await file.read()
            await f.write(content)
        
        # Get file metadata
        file_size = os.path.getsize(file_path)
        pdf_metadata = get_pdf_metadata(file_path)
        
        # Ingest PDF (chunk, embed, store)
        chunk_count = ingest_pdf(
            pdf_path=file_path,
            doc_id=doc_id,
            user_id=current_user.id,
            filename=file.filename,
            metadata=pdf_metadata
        )
        
        # Save document record in database
        document = {
            "doc_id": doc_id,
            "filename": file.filename,
            "file_path": file_path,
            "file_size": file_size,
            "chunk_count": chunk_count,
            "user_id": ObjectId(current_user.id),
            "uploaded_at": datetime.now(timezone.utc),
            "metadata": pdf_metadata
        }
        
        await db.documents.insert_one(document)
        
        return UploadResponse(
            doc_id=doc_id,
            filename=file.filename,
            chunks_created=chunk_count,
            message="PDF uploaded and processed successfully"
        )
    
    except Exception as e:
        # Clean up file if ingestion failed
        if os.path.exists(file_path):
            os.remove(file_path)
        
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error processing PDF: {str(e)}"
        )

