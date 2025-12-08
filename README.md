DocuMind 📚🧠
============

[![Swift](https://img.shields.io/badge/Swift-FA7343?logo=swift&logoColor=white)](https://developer.apple.com/swift/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-0A84FF?logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![iOS](https://img.shields.io/badge/iOS-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![FastAPI](https://img.shields.io/badge/FastAPI-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![MongoDB](https://img.shields.io/badge/MongoDB-4EA94B?logo=mongodb&logoColor=white)](https://www.mongodb.com/)
[![LangChain](https://img.shields.io/badge/LangChain-1E4B82?logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjI2IiBoZWlnaHQ9IjIyNiIgdmlld0JveD0iMCAwIDIyNiAyMjYiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHJlY3Qgd2lkdGg9IjIyNiIgaGVpZ2h0PSIyMjYiIHJ4PSI1MCIgZmlsbD0iIzBlMmE1ZCIvPjx0ZXh0IHg9IjEyMyIgeT0iMTQwIiBmb250LXNpemU9IjExMCIgZm9udC13ZWlnaHQ9IjcwMCIgZmlsbD0iI2ZmZiIgZGV4LWxlbmVtaXRlci1hZGRpdGlvbj0iMzAiIHRleHQtYW5jaG9yPSJtaWRkbGUiPkxDPC90ZXh0Pjwvc3ZnPg==&logoColor=white)](https://langchain.com/)
[![ChromaDB](https://img.shields.io/badge/Chroma-4B0082?logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjI2IiBoZWlnaHQ9IjIyNiIgdmlld0JveD0iMCAwIDIyNiAyMjYiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+PHJlY3Qgd2lkdGg9IjIyNiIgaGVpZ2h0PSIyMjYiIHJ4PSI1MCIgZmlsbD0iIzRiMDA4MiIvPjxjaXJjbGUgY3g9Ijk2IiBjeT0iMTA0IiByPSI0MCIgZmlsbD0iI2ZmZiIvPjxjaXJjbGUgY3g9IjEzMCIgY3k9IjEyMCIgcj0iMzAiIGZpbGw9IiNmZmYiIG9wYWNpdHk9IjAuOCIvPjwvc3ZnPg==)](https://www.trychroma.com/)
[![JWT](https://img.shields.io/badge/JWT-000000?logo=jsonwebtokens&logoColor=white)](https://jwt.io/)

**RAG-powered knowledge assistant** with a FastAPI backend and a SwiftUI iOS client. Upload PDFs, chunk + embed them, run semantic search, and chat with streaming answers — all with JWT auth and token revocation.

Key Highlights
--------------
- 🤝 **Secure Auth**: Register/login, access + refresh tokens, refresh endpoint, logout with revocation store.
- 📤 **PDF Uploads**: FileImporter → FastAPI ingest → chunk + embed → vector DB (Chroma/FAISS).
- 🔎 **Semantic Search**: Filter by selected documents, tune top-K, view scored chunks.
- 💬 **Streaming Chat**: RAG answers streamed to the app for low-latency UX.
- 🗂️ **Docs UX**: List, view detail, delete; responsive layouts for iPhone/iPad.
- 🎨 **Design System**: Brand colors/typography enforced via theme (no raw hex in views).

System Architecture
-------------------
```
┌──────────────────┐      ┌─────────────────────┐      ┌──────────────────┐
│   SwiftUI App    │ ───► │ FastAPI (Auth/RAG)  │ ───► │ MongoDB + Vectors│
│  (MVVM, async)   │ ◄─── │ LangChain + Chroma  │ ◄─── │  (Chroma/FAISS)  │
└──────────────────┘      └─────────────────────┘      └──────────────────┘
        ▲                          │
        │ SSE (streamed chat)      │
        └──────────────────────────┘
```

Stack
-----
- **Frontend**: SwiftUI, MVVM, async/await networking, streaming handling, FileImporter uploads.
- **Backend**: FastAPI, LangChain, Chroma/FAISS, MongoDB (Motor), JWT (python-jose), bcrypt.
- **RAG**: SentenceTransformer embeddings, document chunking, semantic search + retrieval, optional rerank-ready.

Notes
-----
- Embedding model is preloaded on startup to reduce first-query latency.
- Revoked tokens stored with TTL (`revoked_tokens` collection).
- SwiftUI views must use theme colors/typography (no raw hex in views).

Roadmap Ideas
-------------
- Profile screen (update password/email).
- Chat citations with chunk metadata + copy.
- Offline cache for document metadata and last chat thread.