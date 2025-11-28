from typing import List, Dict, Optional
import logging

from rag.vectorstore import get_vector_store
from utils.schemas import QueryChunk, SearchResult

logger = logging.getLogger(__name__)


def retrieve_chunks(
    query: str,
    user_id: int,
    top_k: int = 5,
    doc_ids: Optional[List[str]] = None
) -> List[QueryChunk]:
    """
    Retrieve relevant chunks from the vector store for a query.
    
    Args:
        query: Search query
        user_id: User ID (for namespace)
        top_k: Number of chunks to retrieve
        doc_ids: Optional list of document IDs to filter by
        
    Returns:
        List of QueryChunk objects with content, metadata, and scores
    """
    try:
        vector_store = get_vector_store()
        
        # Search vector store
        results = vector_store.search(
            user_id=user_id,
            query=query,
            n_results=top_k,
            doc_ids=doc_ids
        )
        
        # Convert to QueryChunk objects
        chunks = []
        for result in results:
            # Convert distance to score (lower distance = higher score)
            distance = result.get("distance", 1.0)
            score = max(0.0, 1.0 - distance)  # Simple conversion
            
            chunk = QueryChunk(
                content=result["content"],
                doc_id=result["metadata"].get("doc_id", ""),
                chunk_id=result["metadata"].get("chunk_id", result["id"]),
                score=score,
                metadata=result["metadata"]
            )
            chunks.append(chunk)
        
        logger.info(f"Retrieved {len(chunks)} chunks for query: {query[:50]}...")
        return chunks
    
    except Exception as e:
        logger.error(f"Error retrieving chunks: {str(e)}")
        raise


def search_documents(
    query: str,
    user_id: int,
    top_k: int = 10,
    doc_ids: Optional[List[str]] = None
) -> List[SearchResult]:
    """
    Perform semantic search and return results.
    
    Args:
        query: Search query
        user_id: User ID (for namespace)
        top_k: Number of results to return
        doc_ids: Optional list of document IDs to filter by
        
    Returns:
        List of SearchResult objects
    """
    try:
        vector_store = get_vector_store()
        
        # Search vector store
        results = vector_store.search(
            user_id=user_id,
            query=query,
            n_results=top_k,
            doc_ids=doc_ids
        )
        
        # Convert to SearchResult objects
        search_results = []
        for result in results:
            distance = result.get("distance", 1.0)
            score = max(0.0, 1.0 - distance)
            
            search_result = SearchResult(
                content=result["content"],
                doc_id=result["metadata"].get("doc_id", ""),
                chunk_id=result["metadata"].get("chunk_id", result["id"]),
                score=score,
                metadata=result["metadata"]
            )
            search_results.append(search_result)
        
        logger.info(f"Found {len(search_results)} search results for query: {query[:50]}...")
        return search_results
    
    except Exception as e:
        logger.error(f"Error searching documents: {str(e)}")
        raise

