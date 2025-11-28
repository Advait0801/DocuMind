# DocuMind Backend

FastAPI backend for DocuMind - a RAG-powered knowledge assistant.

## Features

- JWT-based authentication with access and refresh tokens
- PDF ingestion with chunking and embedding
- Vector storage using ChromaDB
- RAG pipeline using Google Gemini 2.5 Flash
- Streaming responses for real-time chat
- Semantic search across documents

## Setup

1. **Install dependencies:**
```bash
pip install -r requirements.txt
```

2. **Configure environment variables:**
```bash
# Create .env file with the following variables:
SECRET_KEY=your-secret-key-change-in-production-min-32-chars
GOOGLE_API_KEY=your-google-api-key-here  # Required - Get from https://makersuite.google.com/app/apikey
MONGODB_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net
MONGODB_DB_NAME=documind
GEMINI_MODEL=gemini-2.5-flash  # Optional: Default is gemini-2.5-flash
```

3. **Initialize the database:**
The database will be automatically initialized on first run.

4. **Run the server:**
```bash
python main.py
# Or with uvicorn directly:
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at `http://localhost:8000`

## API Endpoints

### Authentication
- `POST /auth/register` - Register a new user
- `POST /auth/login` - Login and get tokens

### Documents
- `POST /upload` - Upload and ingest a PDF file
- `GET /documents` - Get all user's documents

### Query & Search
- `POST /query` - Query documents using RAG (supports streaming)
- `POST /search` - Semantic search across documents

### Health
- `GET /health` - Health check endpoint

## API Documentation

Once the server is running, visit:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Environment Variables

**Required:**
- `SECRET_KEY`: JWT secret key
- `GOOGLE_API_KEY`: Google Gemini API key - Get from [Google AI Studio](https://makersuite.google.com/app/apikey)
- `MONGODB_URI`: Connection string for your MongoDB Atlas cluster
- `MONGODB_DB_NAME`: Database name (default: `documind`)

**Optional:**
- `GEMINI_MODEL`: Gemini model name (default: `gemini-2.5-flash`)

## LLM Provider: Google Gemini (Default)

**DocuMind uses Google Gemini 2.5 Flash by default** - the fastest and cheapest option for RAG applications.

### Why Gemini 2.5 Flash?
- **Lowest cost**: $0.075 per million input tokens, $0.30 per million output tokens
- **Faster than 1.5**: Improved speed and performance
- **High quality**: Excellent performance for RAG tasks
- **Large context**: Supports up to 1M input tokens
- **Free tier**: Generous free tier for development

### Getting Your API Key
1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the key and add it to your `.env` file as `GOOGLE_API_KEY`

### Model Configuration
You can change the Gemini model by setting `GEMINI_MODEL` in your `.env`:
- `gemini-2.5-flash` (default) - Latest and fastest
- `gemini-1.5-flash` - Stable version
- `gemini-2.0-flash-exp` - Experimental version

*Costs: $0.075 per million input tokens, $0.30 per million output tokens*

## Project Structure

```
backend/
├── main.py                 # FastAPI app entry point
├── routes/                 # API route handlers
│   ├── auth.py            # Authentication endpoints
│   ├── ingestion.py       # PDF upload endpoint
│   ├── query.py           # RAG query endpoint
│   ├── search.py          # Semantic search endpoint
│   └── documents.py       # Document listing endpoint
├── rag/                   # RAG pipeline components
│   ├── ingest.py          # PDF ingestion logic
│   ├── retrieve.py        # Vector retrieval
│   ├── generate.py        # LLM generation
│   └── vectorstore.py     # ChromaDB wrapper
├── utils/                 # Utilities
│   ├── auth.py            # JWT and password utilities
│   ├── pdf_parser.py      # PDF parsing
│   └── schemas.py         # Pydantic models
├── models/                # Database helpers
│   ├── models.py          # Legacy SQLAlchemy models (unused, kept for reference)
│   └── database.py        # MongoDB (Motor) connection + indexes
└── data/                  # Data storage (created automatically)
    ├── chroma_db/         # Vector database
    └── uploads/           # Uploaded PDFs
```

## Notes

- The embedding model (`all-MiniLM-L6-v2`) is loaded once at startup for efficiency
- Vector stores are namespaced by user ID for data isolation
- PDFs are chunked with ~800 character chunks and 200 character overlap
- Streaming is supported for real-time chat responses

