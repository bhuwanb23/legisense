# Google Cloud Tools Integration for Legisense

This module provides comprehensive Google Cloud services integration for the Legisense legal document analysis platform. It includes both mock implementations for development/testing and production-ready clients for actual Google Cloud deployment.

## 🏗️ Architecture Overview

The Google Cloud integration follows a modular architecture with the following components:

```
┌─────────────────────────────────────────────────────────────┐
│                    Legisense Application                    │
├─────────────────────────────────────────────────────────────┤
│  Google Cloud Service Factory                              │
│  ├── Document AI Client     ├── Vertex AI Client          │
│  ├── Storage Client         ├── Firestore Client          │
│  ├── Pub/Sub Client         ├── BigQuery Client           │
│  └── Auth Client            └── Configuration Manager     │
└─────────────────────────────────────────────────────────────┘
```

## 🔧 Services Included

### 1. Document Ingestion & Processing
- **Google Cloud Storage (GCS)** → Store uploaded PDFs, DOCX, images
- **Cloud Run** → API layer for upload, preprocessing, analysis orchestration
- **Cloud Pub/Sub** → Event-driven pipeline (trigger processing after upload)

### 2. Document Parsing & Cleaning
- **Document AI (DocAI)** → OCR, Contract Parser, Form Extractor
- **Cloud DLP** → Detect & optionally redact sensitive data (PII)

### 3. Knowledge & Retrieval
- **Vertex AI Embeddings** → Convert document clauses into semantic vectors
- **Vertex AI Matching Engine** → ANN-based search for clause retrieval
- **BigQuery** → Store structured legal data for analytics
- **Firestore** → Store user metadata, doc metadata, analysis results

### 4. Reasoning & Generative AI
- **Vertex AI Gemini 1.5 Pro** → Deep analysis, risk scoring, simulation
- **Vertex AI Gemini 1.5 Flash** → Quick summaries, real-time Q&A
- **Vertex AI Function Calling** → Tools for extract_clauses(), score_risk()

### 5. Application & UX
- **Firebase Auth / Identity Platform** → Secure login (email, phone, OAuth)
- **Cloud Endpoints / API Gateway** → Manage API requests securely
- **Looker Studio + BigQuery** → Dashboards for evaluation, monitoring

### 6. Security & Compliance
- **VPC-SC (Service Controls)** → Network-level isolation
- **CMEK (Customer-Managed Encryption Keys)** → User-controlled encryption
- **IAM (Identity & Access Management)** → Least privilege access

## 📁 File Structure

```
google_cloud/
├── __init__.py                 # Module initialization
├── config.py                   # Configuration management
├── service_factory.py          # Service factory pattern
├── document_ai_client.py       # Document AI integration
├── vertex_ai_client.py         # Vertex AI integration
├── storage_client.py           # Cloud Storage integration
├── firestore_client.py         # Firestore integration
├── pubsub_client.py            # Pub/Sub integration
├── bigquery_client.py          # BigQuery integration
├── auth_client.py              # Authentication integration
└── README.md                   # This file
```

## 🚀 Quick Start

### 1. Basic Usage

```python
from google_cloud import get_service_factory

# Get service factory (uses mock by default)
factory = get_service_factory(use_mock=True)

# Get individual clients
document_ai = factory.get_document_ai_client()
vertex_ai = factory.get_vertex_ai_client()
storage = factory.get_storage_client()
firestore = factory.get_firestore_client()
```

### 2. Document Processing Pipeline

```python
from google_cloud import get_document_ai_client, get_vertex_ai_client, get_storage_client

# Upload document
storage = get_storage_client()
upload_result = await storage.upload_document("path/to/document.pdf")

# Process with Document AI
document_ai = get_document_ai_client()
analysis_result = await document_ai.process_document("path/to/document.pdf")

# Analyze with Vertex AI
vertex_ai = get_vertex_ai_client()
ai_analysis = await vertex_ai.analyze_document(analysis_result.text)
```

### 3. Event-Driven Processing

```python
from google_cloud import get_pubsub_client

# Publish document upload event
pubsub = get_pubsub_client()
await pubsub.publish_document_upload_event(
    document_id="doc_123",
    user_id="user_456",
    file_path="path/to/document.pdf",
    file_size=1024000,
    content_type="application/pdf"
)

# Subscribe to processing events
async def handle_document_processed(message):
    print(f"Document {message.data['document_id']} processed!")

await pubsub.subscribe_to_topic(
    "document-processor",
    "document-upload",
    handle_document_processed
)
```

## ⚙️ Configuration

### Environment Variables

```bash
# Required
GOOGLE_CLOUD_PROJECT_ID=your-project-id

# Optional
GOOGLE_CLOUD_LOCATION=us-central1
DOCUMENT_AI_PROCESSOR_ID=your-processor-id
VERTEX_AI_LOCATION=us-central1
STORAGE_BUCKET_DOCUMENTS=legisense-documents
FIRESTORE_DATABASE_ID=(default)
```

### Configuration Object

```python
from google_cloud.config import GoogleCloudConfig

# Create custom configuration
config = GoogleCloudConfig(
    project_id="my-project",
    location="us-central1",
    gemini_model="gemini-1.5-pro",
    storage_bucket_documents="my-documents-bucket"
)

# Validate configuration
if config.validate():
    print("Configuration is valid!")
```

## 🧪 Mock vs Production

### Mock Implementation (Default)
- **Use Case**: Development, testing, local development
- **Features**: Simulated responses, no actual API calls
- **Performance**: Fast, no network latency
- **Cost**: Free

```python
# Use mock clients (default)
factory = get_service_factory(use_mock=True)
```

### Production Implementation
- **Use Case**: Production deployment
- **Features**: Real Google Cloud API calls
- **Performance**: Network latency, actual processing time
- **Cost**: Based on Google Cloud pricing

```python
# Use production clients
factory = get_service_factory(use_mock=False)
```

## 📊 Analytics & Monitoring

### BigQuery Integration

```python
from google_cloud import get_bigquery_client
from google_cloud.bigquery_client import DocumentMetrics, AnalyticsEvent

# Track document processing metrics
bigquery = get_bigquery_client()
metrics = DocumentMetrics(
    document_id="doc_123",
    user_id="user_456",
    processing_time=5.2,
    file_size=1024000,
    analysis_confidence=0.95,
    risk_score=0.3,
    created_at=datetime.now()
)
await bigquery.insert_document_metrics(metrics)

# Query analytics
analytics = await bigquery.query_document_analytics(
    start_date=date(2024, 1, 1),
    end_date=date(2024, 1, 31)
)
```

### User Activity Tracking

```python
from google_cloud.bigquery_client import UserActivity

# Track user activity
activity = UserActivity(
    user_id="user_456",
    activity_type="document_upload",
    timestamp=datetime.now(),
    document_id="doc_123",
    properties={"file_type": "pdf", "file_size": 1024000}
)
await bigquery.insert_user_activity(activity)
```

## 🔐 Authentication & Security

### User Management

```python
from google_cloud import get_auth_client

auth = get_auth_client()

# Create user
result = await auth.create_user(
    email="user@example.com",
    password="secure_password",
    display_name="John Doe"
)

# Sign in
result = await auth.sign_in_with_email_and_password(
    email="user@example.com",
    password="secure_password"
)

# Verify token
user = await auth.verify_id_token(result.token.access_token)
```

### Custom Claims & Authorization

```python
# Set custom claims for role-based access
await auth.set_custom_claims("user_123", {
    "role": "premium_user",
    "permissions": ["upload_documents", "run_simulations"],
    "subscription_tier": "pro"
})
```

## 🔄 Event-Driven Architecture

### Pub/Sub Integration

```python
from google_cloud import get_pubsub_client

pubsub = get_pubsub_client()

# Publish events
await pubsub.publish_document_upload_event(...)
await pubsub.publish_document_processed_event(...)
await pubsub.publish_analysis_completed_event(...)
await pubsub.publish_simulation_requested_event(...)

# Subscribe to events
async def process_document(message):
    # Process document based on event
    pass

await pubsub.subscribe_to_topic(
    "document-processor",
    "document-upload",
    process_document
)
```

## 📈 Performance Optimization

### Configuration Tuning

```python
from google_cloud.config import update_config

# Optimize for performance
update_config(
    max_concurrent_requests=200,
    request_timeout=600,
    retry_attempts=5
)
```

### Caching Strategy

```python
# Use Firestore for caching
firestore = get_firestore_client()

# Cache analysis results
await firestore.store_analysis_result(analysis_result)

# Retrieve cached results
cached_analysis = await firestore.get_analysis_result(analysis_id)
```

## 🧪 Testing

### Unit Testing with Mocks

```python
import pytest
from google_cloud import get_service_factory

@pytest.fixture
def mock_factory():
    return get_service_factory(use_mock=True)

async def test_document_processing(mock_factory):
    document_ai = mock_factory.get_document_ai_client()
    result = await document_ai.process_document("test.pdf")
    
    assert result.text is not None
    assert result.confidence > 0.0
    assert len(result.entities) > 0
```

### Integration Testing

```python
# Switch to production for integration tests
factory = get_service_factory(use_mock=False)

# Test with real Google Cloud services
# (Ensure proper credentials and project setup)
```

## 🚀 Deployment

### Production Setup

1. **Enable Google Cloud APIs**:
   ```bash
   gcloud services enable documentai.googleapis.com
   gcloud services enable aiplatform.googleapis.com
   gcloud services enable storage.googleapis.com
   gcloud services enable firestore.googleapis.com
   gcloud services enable pubsub.googleapis.com
   gcloud services enable bigquery.googleapis.com
   ```

2. **Set up authentication**:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"
   ```

3. **Configure environment**:
   ```bash
   export GOOGLE_CLOUD_PROJECT_ID="your-project-id"
   export GOOGLE_CLOUD_LOCATION="us-central1"
   ```

4. **Switch to production**:
   ```python
   from google_cloud import get_service_factory
   factory = get_service_factory(use_mock=False)
   ```

## 📚 API Reference

### Document AI Client
- `process_document(file_path, document_type)` → DocumentAnalysisResult
- `extract_entities(text)` → List[DocumentEntity]
- `extract_clauses(text)` → List[DocumentClause]

### Vertex AI Client
- `analyze_document(text, document_type)` → AnalysisResult
- `generate_simulation(text, scenario, parameters)` → SimulationResult
- `generate_embeddings(texts)` → List[List[float]]
- `chat_completion(messages, model)` → str

### Storage Client
- `upload_document(file_path, bucket_name, object_name)` → UploadResult
- `download_document(bucket_name, object_name, destination_path)` → bool
- `delete_document(bucket_name, object_name)` → bool
- `list_documents(bucket_name, prefix, max_results)` → List[StorageObject]

### Firestore Client
- `store_document_metadata(metadata)` → str
- `get_document_metadata(document_id)` → DocumentMetadata
- `list_user_documents(user_id, limit)` → List[DocumentMetadata]
- `store_analysis_result(analysis)` → str
- `get_analysis_result(analysis_id)` → AnalysisResult

### Pub/Sub Client
- `publish_document_upload_event(...)` → str
- `publish_document_processed_event(...)` → str
- `publish_analysis_completed_event(...)` → str
- `subscribe_to_topic(subscription_name, topic_name, handler)` → bool

### BigQuery Client
- `insert_analytics_event(event)` → bool
- `insert_document_metrics(metrics)` → bool
- `query_document_analytics(start_date, end_date, user_id)` → List[Dict]
- `query_user_activity(user_id, days)` → List[Dict]

### Auth Client
- `create_user(email, password, display_name)` → AuthResult
- `sign_in_with_email_and_password(email, password)` → AuthResult
- `verify_id_token(id_token)` → User
- `refresh_token(refresh_token)` → AuthToken

## 🤝 Contributing

1. Follow the existing code structure and patterns
2. Add comprehensive docstrings for all public methods
3. Include type hints for all parameters and return values
4. Write unit tests for new functionality
5. Update this README for any new features

## 📄 License

This module is part of the Legisense project and follows the same MIT license.

