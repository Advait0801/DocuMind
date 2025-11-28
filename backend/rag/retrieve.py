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


def _calculate_content_similarity(content1: str, content2: str) -> float:
    """Calculate simple similarity between two content strings."""
    # Use simple word overlap ratio
    words1 = set(content1.lower().split())
    words2 = set(content2.lower().split())
    
    if not words1 or not words2:
        return 0.0
    
    intersection = len(words1 & words2)
    union = len(words1 | words2)
    return intersection / union if union > 0 else 0.0


def _deduplicate_search_results(search_results: List[SearchResult], similarity_threshold: float = 0.7) -> List[SearchResult]:
    """
    Remove duplicate or highly similar search results.
    
    Args:
        search_results: List of search results to deduplicate
        similarity_threshold: Threshold for considering results as duplicates (0-1)
        
    Returns:
        Deduplicated list of search results
    """
    if not search_results:
        return search_results
    
    # Sort by score (highest first)
    sorted_results = sorted(search_results, key=lambda x: x.score, reverse=True)
    
    deduplicated = []
    seen_content_hashes = set()
    
    for result in sorted_results:
        # Create a simple hash from first 100 chars for quick duplicate detection
        content_preview = result.content[:100].strip().lower()
        content_hash = hash(content_preview)
        
        # Check if we've seen this content before
        if content_hash in seen_content_hashes:
            continue
        
        # Check similarity with already added results
        is_duplicate = False
        for existing_result in deduplicated:
            similarity = _calculate_content_similarity(result.content, existing_result.content)
            
            # If chunks are from same document and very similar, skip
            if result.doc_id == existing_result.doc_id and similarity > similarity_threshold:
                is_duplicate = True
                break
            
            # If chunks are from different documents but still very similar, skip
            if similarity > 0.9:
                is_duplicate = True
                break
        
        if not is_duplicate:
            deduplicated.append(result)
            seen_content_hashes.add(content_hash)
    
    return deduplicated


def search_documents(
    query: str,
    user_id: int,
    top_k: int = 10,
    doc_ids: Optional[List[str]] = None
) -> List[SearchResult]:
    """
    Perform semantic search and return results with deduplication.
    
    Args:
        query: Search query
        user_id: User ID (for namespace)
        top_k: Number of results to return
        doc_ids: Optional list of document IDs to filter by
        
    Returns:
        List of SearchResult objects (deduplicated)
    """
    try:
        vector_store = get_vector_store()
        
        # Search vector store (get more results to account for deduplication)
        results = vector_store.search(
            user_id=user_id,
            query=query,
            n_results=min(top_k * 2, 50),  # Get more results to filter from
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
        
        # Deduplicate results
        deduplicated_results = _deduplicate_search_results(search_results)
        
        # Limit to requested top_k
        final_results = deduplicated_results[:top_k]
        
        logger.info(f"Found {len(final_results)} search results (after deduplication) for query: {query[:50]}...")
        return final_results
    
    except Exception as e:
        logger.error(f"Error searching documents: {str(e)}")
        raise

