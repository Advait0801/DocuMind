import fitz  # PyMuPDF
from typing import List, Dict
import hashlib
import os


def extract_text_from_pdf(pdf_path: str) -> str:
    """
    Extract all text from a PDF file.
    
    Args:
        pdf_path: Path to the PDF file
        
    Returns:
        Extracted text as a string
        
    Raises:
        Exception: If PDF cannot be read or parsed
    """
    try:
        doc = fitz.open(pdf_path)
        text_parts = []
        
        for page_num in range(len(doc)):
            page = doc[page_num]
            text = page.get_text()
            if text.strip():
                text_parts.append(text)
        
        doc.close()
        return "\n\n".join(text_parts)
    
    except Exception as e:
        raise Exception(f"Error extracting text from PDF: {str(e)}")


def get_pdf_metadata(pdf_path: str) -> Dict:
    """
    Extract metadata from a PDF file.
    
    Args:
        pdf_path: Path to the PDF file
        
    Returns:
        Dictionary with PDF metadata
    """
    try:
        doc = fitz.open(pdf_path)
        metadata = doc.metadata
        page_count = len(doc)
        file_size = os.path.getsize(pdf_path)
        doc.close()
        
        return {
            "title": metadata.get("title", ""),
            "author": metadata.get("author", ""),
            "subject": metadata.get("subject", ""),
            "page_count": page_count,
            "file_size": file_size,
        }
    except Exception as e:
        return {
            "title": "",
            "author": "",
            "subject": "",
            "page_count": 0,
            "file_size": 0,
        }


def generate_doc_id(filename: str, user_id: int) -> str:
    """
    Generate a unique document ID based on filename and user_id.
    
    Args:
        filename: Original filename
        user_id: User ID
        
    Returns:
        Unique document ID
    """
    content = f"{filename}_{user_id}_{os.path.getmtime(filename) if os.path.exists(filename) else ''}"
    return hashlib.md5(content.encode()).hexdigest()

