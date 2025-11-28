from fastapi import APIRouter, Depends, HTTPException

from utils.auth import get_current_user
from utils.schemas import SearchRequest, SearchResponse, CurrentUser
from rag.retrieve import search_documents

router = APIRouter(prefix="/search", tags=["search"])


@router.post("", response_model=SearchResponse)
async def search_documents_endpoint(
    request: SearchRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    """Perform semantic search across user's documents."""
    try:
        results = search_documents(
            query=request.query,
            user_id=current_user.id,
            top_k=request.top_k,
            doc_ids=request.doc_ids
        )
        
        return SearchResponse(
            results=results,
            query=request.query,
            total=len(results)
        )
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error performing search: {str(e)}"
        )

