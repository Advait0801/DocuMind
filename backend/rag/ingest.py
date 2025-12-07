from langchain.text_splitter import RecursiveCharacterTextSplitter
from typing import List, Dict
import uuid
import logging

from rag.vectorstore import get_vector_store
from utils.pdf_parser import extract_text_from_pdf

logger = logging.getLogger(__name__)


def chunk_text(text: str, chunk_size: int = 800, chunk_overlap: int = 200) -> List[str]:
    """
    Split text into chunks with overlap.
    
    Args:
        text: Text to chunk
        chunk_size: Target size of each chunk (in characters, ~500-800 tokens)
        chunk_overlap: Overlap between chunks (in characters)
        
    Returns:
        List of text chunks
    """
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        length_function=len,
        separators=["\n\n", "\n", ". ", " ", ""]
    )
    
    chunks = text_splitter.split_text(text)
    return chunks


def ingest_pdf(
    pdf_path: str,
    doc_id: str,
    user_id: str,
    filename: str,
    metadata: Dict = None
) -> int:
    """
    Ingest a PDF file: extract text, chunk it, embed it, and store in vector DB.
    
    Args:
        pdf_path: Path to the PDF file
        doc_id: Unique document ID
        user_id: User ID (for namespace)
        filename: Original filename
        metadata: Additional metadata to store
        
    Returns:
        Number of chunks created
    """
    try:
        # Extract text from PDF
        logger.info(f"Extracting text from PDF: {pdf_path}")
        text = extract_text_from_pdf(pdf_path)
        
        if not text.strip():
            raise ValueError("PDF contains no extractable text")
        
        # Chunk the text
        logger.info(f"Chunking text for document {doc_id}")
        chunks = chunk_text(text, chunk_size=800, chunk_overlap=200)
        
        if not chunks:
            raise ValueError("No chunks created from PDF")
        
        # Prepare metadata and IDs for each chunk
        metadatas = []
        ids = []
        
        for i, chunk in enumerate(chunks):
            chunk_id = f"{doc_id}_chunk_{i}"
            chunk_metadata = {
                "doc_id": doc_id,
                "chunk_id": chunk_id,
                "chunk_index": i,
                "user_id": user_id,
                "filename": filename,
                "source": "pdf"
            }
            
            # Add any additional metadata
            if metadata:
                chunk_metadata.update(metadata)
            
            metadatas.append(chunk_metadata)
            ids.append(chunk_id)
        
        # Store in vector database
        logger.info(f"Storing {len(chunks)} chunks in vector store")
        vector_store = get_vector_store()
        vector_store.add_documents(
            user_id=user_id,
            doc_id=doc_id,
            texts=chunks,
            metadatas=metadatas,
            ids=ids
        )
        
        logger.info(f"Successfully ingested PDF {filename} with {len(chunks)} chunks")
        return len(chunks)
    
    except Exception as e:
        logger.error(f"Error ingesting PDF {pdf_path}: {str(e)}")
        raise

