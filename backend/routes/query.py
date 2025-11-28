from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
import json

from utils.auth import get_current_user
from utils.schemas import QueryRequest, QueryResponse, CurrentUser
from rag.retrieve import retrieve_chunks
from rag.generate import generate_answer_stream, generate_answer

router = APIRouter(prefix="/query", tags=["query"])


@router.post("")
async def query_documents(
    request: QueryRequest,
    current_user: CurrentUser = Depends(get_current_user),
):
    """
    Query documents using RAG. Supports streaming and non-streaming responses.
    """
    try:
        # Retrieve relevant chunks
        chunks = retrieve_chunks(
            query=request.query,
            user_id=current_user.id,
            top_k=request.top_k,
            doc_ids=request.doc_ids
        )
        
        if not chunks:
            raise HTTPException(
                status_code=404,
                detail="No relevant documents found for the query"
            )
        
        # Stream response if requested
        if request.stream:
            async def generate():
                # Send initial metadata
                yield f"data: {json.dumps({'type': 'chunks', 'chunks': [{'doc_id': c.doc_id, 'chunk_id': c.chunk_id, 'score': c.score} for c in chunks]})}\n\n"
                
                # Stream answer tokens
                async for token in generate_answer_stream(request.query, chunks):
                    yield f"data: {json.dumps({'type': 'token', 'content': token})}\n\n"
                
                # Send completion signal
                yield f"data: {json.dumps({'type': 'done'})}\n\n"
            
            return StreamingResponse(
                generate(),
                media_type="text/event-stream",
                headers={
                    "Cache-Control": "no-cache",
                    "Connection": "keep-alive",
                }
            )
        
        else:
            # Non-streaming response
            answer = await generate_answer(request.query, chunks)
            
            return QueryResponse(
                answer=answer,
                chunks=chunks,
                query=request.query
            )
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error processing query: {str(e)}"
        )

