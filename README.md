# 📚 DocuMind

<div align="center">

**A RAG-powered knowledge assistant with semantic search and streaming chat over your PDFs**

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Python](https://img.shields.io/badge/Python-3.10+-blue.svg)](https://www.python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104-green.svg)](https://fastapi.tiangolo.com)
[![MongoDB](https://img.shields.io/badge/MongoDB-Motor-green.svg)](https://www.mongodb.com)
[![iOS](https://img.shields.io/badge/iOS-17.0+-lightgrey.svg)](https://developer.apple.com/ios)
[![ChromaDB](https://img.shields.io/badge/ChromaDB-Vector%20Store-purple.svg)](https://www.trychroma.com)
[![LangChain](https://img.shields.io/badge/LangChain-RAG-blue.svg)](https://langchain.com)
[![Gemini](https://img.shields.io/badge/Google-Gemini%20LLM-4285F4.svg)](https://ai.google.dev)

</div>

---

## 📱 Overview

**DocuMind** is a full-stack RAG (Retrieval-Augmented Generation) application that lets users upload PDFs, search them semantically, and chat with an AI that answers from document context. Built with SwiftUI for iOS and FastAPI for the backend, it uses ChromaDB for vector storage, SentenceTransformer for embeddings, and Google Gemini for streaming answers.

### Key Highlights

- 🤖 **RAG Pipeline**: Chunk → embed → store in ChromaDB; retrieve by similarity → generate answer with Gemini
- 🔐 **Secure Auth**: JWT access + refresh tokens, bcrypt hashing, logout with token revocation (MongoDB)
- 📤 **PDF Ingestion**: PyMuPDF text extraction, LangChain RecursiveCharacterTextSplitter, user-scoped namespaces
- 🔎 **Semantic Search**: Filter by document(s), tune top-K; results show filename and score
- 💬 **Streaming Chat**: SSE streaming of LLM tokens for low-latency UX
- 🗂️ **Document Management**: List, view detail, delete documents with responsive SwiftUI layouts
- 🎨 **Design System**: Brand colors and typography (no raw hex in views); light/dark aware

---

## ✨ Features

### Core Functionality

- **PDF Upload**: FileImporter on iOS → multipart upload → server saves file, extracts text with PyMuPDF
- **Chunking & Embedding**: RecursiveCharacterTextSplitter (~800 chars, 200 overlap); SentenceTransformer `all-MiniLM-L6-v2` for embeddings
- **Vector Store**: ChromaDB with persistent storage; per-user collections (`user_{user_id}`)
- **Document Metadata**: MongoDB stores doc_id, filename, uploaded_at, chunk_count, file_size per user
- **User Authentication**: Register, login, refresh token, logout (revoked tokens stored with TTL)
- **Document CRUD**: List documents, view detail, delete (removes from MongoDB and vector store)

### Search & Chat

- **Semantic Search**: Query embedded with same model; similarity search in user’s Chroma collection; optional `doc_ids` filter and `top_k`
- **Search Filters (iOS)**: Filter sheet to select documents and set “top K” results; active filters shown in bar
- **RAG Query**: Retrieve top-K chunks → build context → Gemini generates answer from context only
- **Streaming Responses**: Server-Sent Events (SSE); iOS consumes stream and updates UI per token
- **Chat UI**: Streaming message bubbles, document-scoped queries

### User Experience

- **Responsive Layouts**: GeometryReader and size classes; works on iPhone and iPad
- **Theme**: Colors and typography from theme (e.g. `dmBackground`, `dmPrimary`); no raw hex in views
- **Loading & Errors**: LoadingView, ErrorAlert component, consistent error handling
- **Simulator-Friendly**: FileImporter for PDFs; no camera or device-specific APIs required

---

## 🏗️ Architecture

### System Architecture

```
┌─────────────────┐         ┌──────────────────┐        ┌─────────────────┐
│   iOS Client    │◄───────►│  FastAPI Backend │◄──────►│    MongoDB      │
│   (SwiftUI)     │  REST   │  (Python)        │ Async  │   (Users, Docs) │
└─────────────────┘         └──────────────────┘        └─────────────────┘
      │                              │
      │ SSE (streamed chat)          │
      │                              ▼
      │                     ┌──────────────────┐
      │                     │ ChromaDB         │
      │                     │ (vector store)   │
      │                     │ per-user coll.   │
      │                     └────────┬─────────┘
      │                              │
      │                     ┌────────┴────────┐
      │                     ▼                 ▼
      │              ┌──────────────┐  ┌──────────────┐
      │              │ Sentence     │  │ Google       │
      │              │ Transformer  │  │ Gemini LLM   │
      │              │ (embeddings) │  │ (streaming)  │
      │              └──────────────┘  └──────────────┘
      │
      ▼
┌─────────────┐
│ JWT Tokens  │
│ UserDefaults│
└─────────────┘
```

### Workflow

1. **User uploads a PDF**  
   From the iOS app they pick a file via FileImporter. The app sends it to `POST /upload` with the auth token.

2. **Backend stores the file and ingests it**  
   The PDF is saved under `./data/uploads`. The server extracts text with **PyMuPDF** (fitz). If the PDF is empty or unreadable, the request fails with a clear error.

3. **Text is chunked and embedded**  
   **LangChain**’s `RecursiveCharacterTextSplitter` splits the text into chunks (~800 characters, 200 overlap). Each chunk is embedded with **SentenceTransformer** (`all-MiniLM-L6-v2`). Embeddings are computed in batch and written to **ChromaDB** in the user’s collection, with metadata: `doc_id`, `chunk_id`, `filename`, etc.

4. **Document record is saved**  
   MongoDB gets a document entry: `doc_id`, `user_id`, `filename`, `uploaded_at`, `chunk_count`, `file_size`. The list/detail/delete APIs use this.

5. **User runs a search**  
   They type a query in the Search tab and optionally apply filters (specific documents, top-K). The app sends `POST /search` with `query`, optional `doc_ids`, and `top_k`. The backend embeds the query with the same model, runs similarity search in ChromaDB (scoped to the user and optional doc_ids), and returns matching chunks with scores. The app shows results with filename and score.

6. **User asks a question in Chat**  
   They submit a question (optionally limited to certain docs). The app sends `POST /query` with `stream: true`. The backend **retrieves** top-K relevant chunks (same retrieval path as search), **builds** a context string from those chunks, and sends it to **Google Gemini** with a system prompt: “Answer only from the context.” The LLM response is **streamed** back as Server-Sent Events.

7. **iOS displays the stream**  
   The app parses SSE lines, decodes `data: {...}` JSON (e.g. `type: "token"`, `content`), and appends tokens to the current message so the answer appears incrementally.

8. **Logout**  
   User taps Sign Out. The app calls `POST /auth/logout` with the refresh token (and auth header). The server revokes both access and refresh tokens in MongoDB (`revoked_tokens`). The app clears local tokens and user state and shows the login screen.

---

## 🛠️ Tech Stack

### Frontend (iOS)

- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Architecture**: MVVM
- **Networking**: URLSession with async/await; SSE parsing for streaming
- **Storage**: UserDefaults for JWT and current user
- **Uploads**: FileImporter for PDF selection
- **Minimum iOS**: 17.0+
- **Layout**: ResponsiveContainer, GeometryReader, size classes

### Backend (Python)

- **Framework**: FastAPI 0.104.1
- **ASGI Server**: Uvicorn
- **Database**: MongoDB (Motor async driver, PyMongo)
- **Authentication**: JWT (python-jose), bcrypt (passlib)
- **PDF**: PyMuPDF (fitz)
- **Python**: 3.10+

### RAG & AI

- **Embeddings**: SentenceTransformer (`all-MiniLM-L6-v2`)
- **Vector DB**: ChromaDB (persistent, per-user collections)
- **Chunking**: LangChain RecursiveCharacterTextSplitter
- **LLM**: Google Gemini (langchain-google-genai, streaming)
- **Orchestration**: LangChain (prompts, message handling)

---

## 🚧 Future Enhancements

- [ ] Profile screen (change password / email)
- [ ] Chat citations: show source chunks and copy button
- [ ] Offline cache for document list and last chat thread
- [ ] Reranker step for retrieval
- [ ] Support for more file types (e.g. plain text, Markdown)

---

<div align="center">

**Built with ❤️ using Swift, Python, and RAG**

⭐ Star this repo if you find it helpful!

</div>
