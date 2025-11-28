import chromadb
from chromadb.config import Settings
import os
from typing import List, Dict, Optional
from sentence_transformers import SentenceTransformer
import logging

logger = logging.getLogger(__name__)

# Global embedding model (loaded once at startup)
_embedding_model = None


def get_embedding_model():
    """Get or initialize the embedding model (singleton pattern)."""
    global _embedding_model
    if _embedding_model is None:
        logger.info("Loading embedding model...")
        # Using a lightweight, fast model for embeddings
        _embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
        logger.info("Embedding model loaded successfully")
    return _embedding_model


class VectorStore:
    """Wrapper for ChromaDB vector store with user-specific namespaces."""
    
    def __init__(self, persist_directory: str = "./data/chroma_db"):
        """Initialize ChromaDB client with persistence."""
        os.makedirs(persist_directory, exist_ok=True)
        
        self.client = chromadb.PersistentClient(
            path=persist_directory,
            settings=Settings(anonymized_telemetry=False)
        )
        self.embedding_model = get_embedding_model()
        logger.info(f"VectorStore initialized with persist directory: {persist_directory}")
    
    def get_collection(self, user_id: int):
        """Get or create a collection for a specific user (namespace)."""
        collection_name = f"user_{user_id}"
        try:
            collection = self.client.get_collection(name=collection_name)
        except:
            collection = self.client.create_collection(
                name=collection_name,
                metadata={"user_id": user_id}
            )
        return collection
    
    def add_documents(
        self,
        user_id: int,
        doc_id: str,
        texts: List[str],
        metadatas: List[Dict],
        ids: List[str]
    ):
        """
        Add documents to the vector store for a specific user.
        
        Args:
            user_id: User ID (determines namespace)
            doc_id: Document ID
            texts: List of text chunks
            metadatas: List of metadata dicts for each chunk
            ids: List of unique IDs for each chunk
        """
        collection = self.get_collection(user_id)
        
        # Generate embeddings
        embeddings = self.embedding_model.encode(texts, show_progress_bar=False).tolist()
        
        # Add to collection
        collection.add(
            embeddings=embeddings,
            documents=texts,
            metadatas=metadatas,
            ids=ids
        )
        
        logger.info(f"Added {len(texts)} chunks to vector store for user {user_id}, doc {doc_id}")
    
    def search(
        self,
        user_id: int,
        query: str,
        n_results: int = 5,
        doc_ids: Optional[List[str]] = None,
        where: Optional[Dict] = None
    ) -> List[Dict]:
        """
        Search for similar documents in the vector store.
        
        Args:
            user_id: User ID (determines namespace)
            query: Search query text
            n_results: Number of results to return
            doc_ids: Optional list of document IDs to filter by
            where: Optional additional filter conditions
            
        Returns:
            List of search results with content, metadata, and distance
        """
        collection = self.get_collection(user_id)
        
        # Generate query embedding
        query_embedding = self.embedding_model.encode([query], show_progress_bar=False).tolist()[0]
        
        # Build where clause
        where_clause = where or {}
        if doc_ids:
            where_clause["doc_id"] = {"$in": doc_ids}
        
        # Search
        results = collection.query(
            query_embeddings=[query_embedding],
            n_results=n_results,
            where=where_clause if where_clause else None
        )
        
        # Format results
        formatted_results = []
        if results["ids"] and len(results["ids"][0]) > 0:
            for i in range(len(results["ids"][0])):
                formatted_results.append({
                    "content": results["documents"][0][i],
                    "metadata": results["metadatas"][0][i],
                    "id": results["ids"][0][i],
                    "distance": results["distances"][0][i] if "distances" in results else None
                })
        
        return formatted_results
    
    def delete_document(self, user_id: int, doc_id: str):
        """Delete all chunks for a specific document."""
        collection = self.get_collection(user_id)
        collection.delete(where={"doc_id": doc_id})
        logger.info(f"Deleted document {doc_id} from vector store for user {user_id}")


# Global vector store instance
_vector_store = None


def get_vector_store() -> VectorStore:
    """Get or create the global vector store instance."""
    global _vector_store
    if _vector_store is None:
        _vector_store = VectorStore()
    return _vector_store

