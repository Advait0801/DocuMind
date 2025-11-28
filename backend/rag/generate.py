from typing import AsyncGenerator
import os
import logging
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, SystemMessage

from utils.schemas import QueryChunk

logger = logging.getLogger(__name__)

# LLM Configuration - Google Gemini only
# Get API key from https://makersuite.google.com/app/apikey
GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")


def get_llm():
    """
    Get Gemini LLM instance.
    
    Returns:
        ChatGoogleGenerativeAI instance configured for streaming
    """
    if not GOOGLE_API_KEY:
        raise ValueError(
            "GOOGLE_API_KEY not set. "
            "Get your API key from https://makersuite.google.com/app/apikey"
        )
    
    return ChatGoogleGenerativeAI(
        model=GEMINI_MODEL,
        temperature=0.7,
        streaming=True,
        google_api_key=GOOGLE_API_KEY
    )


def build_context(chunks: list[QueryChunk]) -> str:
    """
    Build context string from retrieved chunks.
    
    Args:
        chunks: List of QueryChunk objects
        
    Returns:
        Formatted context string
    """
    context_parts = []
    for i, chunk in enumerate(chunks, 1):
        context_parts.append(
            f"[Document {i} - {chunk.metadata.get('filename', 'Unknown')}]\n"
            f"{chunk.content}\n"
        )
    return "\n".join(context_parts)


async def generate_answer_stream(
    query: str,
    chunks: list[QueryChunk]
) -> AsyncGenerator[str, None]:
    """
    Generate an answer using RAG with streaming via Gemini.
    
    Args:
        query: User's question
        chunks: Retrieved relevant chunks
        
    Yields:
        Token strings as they are generated
    """
    try:
        # Build context from chunks
        context = build_context(chunks)
        
        # Build prompt
        system_prompt = """You are a helpful AI assistant that answers questions based on the provided context from documents.
        Use only the information from the context to answer the question. If the context doesn't contain enough information,
        say so clearly. Be concise and accurate."""
        
        user_prompt = f"""Context from documents:
{context}

Question: {query}

Answer:"""
        
        # Get Gemini LLM
        llm = get_llm()
        
        # Generate with streaming
        messages = [
            SystemMessage(content=system_prompt),
            HumanMessage(content=user_prompt)
        ]
        
        async for chunk in llm.astream(messages):
            # Handle chunk content
            if hasattr(chunk, 'content'):
                content = chunk.content
                if content:
                    yield content
            elif isinstance(chunk, str):
                yield chunk
            elif hasattr(chunk, 'text'):
                yield chunk.text
    
    except Exception as e:
        logger.error(f"Error generating answer: {str(e)}")
        yield f"Error: {str(e)}"


async def generate_answer(
    query: str,
    chunks: list[QueryChunk]
) -> str:
    """
    Generate an answer using RAG (non-streaming) via Gemini.
    
    Args:
        query: User's question
        chunks: Retrieved relevant chunks
        
    Returns:
        Complete answer string
    """
    answer = ""
    async for token in generate_answer_stream(query, chunks):
        answer += token
    return answer
