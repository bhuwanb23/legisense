# Google Cloud (Fake Clients)

This directory contains mock clients that simulate Google Cloud services for local development and tests. No external network calls are made, and all data is kept in-memory.

## Clients
- `document_ai_client.py`: `MockDocumentAIClient` returns fake OCR, entities, and clause extraction.
- `storage_client.py`: `MockGCSClient` simulates GCS uploads and signed URLs.
- `pubsub_client.py`: `MockPubSubClient` simulates publish/subscribe and pulling messages.
- `dlp_client.py`: `MockDLPClient` detects and redacts Aadhaar, PAN, phone, and emails.
- `vertex_ai_client.py`: `MockGeminiClient`, `MockEmbeddingsClient`, and `MockMatchingEngine` for summaries, risk scoring, embeddings, and vector search.
- `firestore_client.py`: `MockFirestoreClient` for basic document set/get/query.
- `bigquery_client.py`: `MockBigQueryClient` for simple insert and query operations.

## Usage (Examples)
```python
from legisense_backend.google_cloud.document_ai_client import MockDocumentAIClient, DocumentType

client = MockDocumentAIClient(project_id="demo")
result = await client.process_document("/path/to/file.pdf", document_type=DocumentType.CONTRACT)
print(result.clauses[:2])
```

```python
from legisense_backend.google_cloud.vertex_ai_client import MockGeminiClient

ai = MockGeminiClient()
print(ai.summarize("This is a long text. It has multiple sentences.", level="basic"))
```

## Configuration
Set environment variables in `.env` (see `env.example`):

- `GCP_CLIENT_MODE=mock`
- `GCP_PROJECT_ID=your-gcp-project-id`
- `GCP_LOCATION=us`
- `GCS_DEFAULT_BUCKET=legisense-dev`
- `VERTEX_GEMINI_MODEL=gemini-1.5-pro`
- `VERTEX_EMBEDDINGS_DIM=64`

These clients are designed to be replaced by production implementations later.

