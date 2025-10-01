"""
Google Cloud Configuration for Legisense
Centralized configuration for all Google Cloud services
"""

import os
import logging
from typing import Dict, Any, Optional
from dataclasses import dataclass

logger = logging.getLogger(__name__)

@dataclass
class GoogleCloudConfig:
    """Configuration for Google Cloud services"""
    project_id: str
    location: str = "us-central1"
    dataset_id: str = "legisense_analytics"
    
    # Document AI Configuration
    document_ai_processor_id: Optional[str] = None
    document_ai_location: str = "us"
    
    # Vertex AI Configuration
    vertex_ai_location: str = "us-central1"
    gemini_model: str = "gemini-1.5-pro"
    gemini_flash_model: str = "gemini-1.5-flash"
    embedding_model: str = "text-embedding-004"
    
    # Storage Configuration
    storage_bucket_documents: str = "legisense-documents"
    storage_bucket_processed: str = "legisense-processed"
    storage_bucket_backups: str = "legisense-backups"
    
    # Firestore Configuration
    firestore_database_id: str = "(default)"
    
    # Pub/Sub Configuration
    pubsub_topic_upload: str = "document-upload"
    pubsub_topic_processed: str = "document-processed"
    pubsub_topic_analysis: str = "analysis-completed"
    pubsub_topic_simulation: str = "simulation-requested"
    
    # BigQuery Configuration
    bigquery_dataset: str = "legisense_analytics"
    bigquery_table_events: str = "analytics_events"
    bigquery_table_metrics: str = "document_metrics"
    bigquery_table_activity: str = "user_activity"
    
    # Auth Configuration
    auth_provider_id: str = "password"
    auth_phone_provider: str = "phone"
    
    # Security Configuration
    enable_dlp: bool = True
    enable_cmek: bool = False
    enable_vpc_sc: bool = False
    
    # Performance Configuration
    max_concurrent_requests: int = 100
    request_timeout: int = 300
    retry_attempts: int = 3
    
    @classmethod
    def from_environment(cls) -> 'GoogleCloudConfig':
        """Create configuration from environment variables"""
        return cls(
            project_id=os.getenv('GOOGLE_CLOUD_PROJECT_ID', 'legisense-dev'),
            location=os.getenv('GOOGLE_CLOUD_LOCATION', 'us-central1'),
            dataset_id=os.getenv('GOOGLE_CLOUD_DATASET_ID', 'legisense_analytics'),
            
            # Document AI
            document_ai_processor_id=os.getenv('DOCUMENT_AI_PROCESSOR_ID'),
            document_ai_location=os.getenv('DOCUMENT_AI_LOCATION', 'us'),
            
            # Vertex AI
            vertex_ai_location=os.getenv('VERTEX_AI_LOCATION', 'us-central1'),
            gemini_model=os.getenv('GEMINI_MODEL', 'gemini-1.5-pro'),
            gemini_flash_model=os.getenv('GEMINI_FLASH_MODEL', 'gemini-1.5-flash'),
            embedding_model=os.getenv('EMBEDDING_MODEL', 'text-embedding-004'),
            
            # Storage
            storage_bucket_documents=os.getenv('STORAGE_BUCKET_DOCUMENTS', 'legisense-documents'),
            storage_bucket_processed=os.getenv('STORAGE_BUCKET_PROCESSED', 'legisense-processed'),
            storage_bucket_backups=os.getenv('STORAGE_BUCKET_BACKUPS', 'legisense-backups'),
            
            # Firestore
            firestore_database_id=os.getenv('FIRESTORE_DATABASE_ID', '(default)'),
            
            # Pub/Sub
            pubsub_topic_upload=os.getenv('PUBSUB_TOPIC_UPLOAD', 'document-upload'),
            pubsub_topic_processed=os.getenv('PUBSUB_TOPIC_PROCESSED', 'document-processed'),
            pubsub_topic_analysis=os.getenv('PUBSUB_TOPIC_ANALYSIS', 'analysis-completed'),
            pubsub_topic_simulation=os.getenv('PUBSUB_TOPIC_SIMULATION', 'simulation-requested'),
            
            # BigQuery
            bigquery_dataset=os.getenv('BIGQUERY_DATASET', 'legisense_analytics'),
            bigquery_table_events=os.getenv('BIGQUERY_TABLE_EVENTS', 'analytics_events'),
            bigquery_table_metrics=os.getenv('BIGQUERY_TABLE_METRICS', 'document_metrics'),
            bigquery_table_activity=os.getenv('BIGQUERY_TABLE_ACTIVITY', 'user_activity'),
            
            # Auth
            auth_provider_id=os.getenv('AUTH_PROVIDER_ID', 'password'),
            auth_phone_provider=os.getenv('AUTH_PHONE_PROVIDER', 'phone'),
            
            # Security
            enable_dlp=os.getenv('ENABLE_DLP', 'true').lower() == 'true',
            enable_cmek=os.getenv('ENABLE_CMEK', 'false').lower() == 'true',
            enable_vpc_sc=os.getenv('ENABLE_VPC_SC', 'false').lower() == 'true',
            
            # Performance
            max_concurrent_requests=int(os.getenv('MAX_CONCURRENT_REQUESTS', '100')),
            request_timeout=int(os.getenv('REQUEST_TIMEOUT', '300')),
            retry_attempts=int(os.getenv('RETRY_ATTEMPTS', '3'))
        )
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert configuration to dictionary"""
        return {
            'project_id': self.project_id,
            'location': self.location,
            'dataset_id': self.dataset_id,
            'document_ai_processor_id': self.document_ai_processor_id,
            'document_ai_location': self.document_ai_location,
            'vertex_ai_location': self.vertex_ai_location,
            'gemini_model': self.gemini_model,
            'gemini_flash_model': self.gemini_flash_model,
            'embedding_model': self.embedding_model,
            'storage_bucket_documents': self.storage_bucket_documents,
            'storage_bucket_processed': self.storage_bucket_processed,
            'storage_bucket_backups': self.storage_bucket_backups,
            'firestore_database_id': self.firestore_database_id,
            'pubsub_topic_upload': self.pubsub_topic_upload,
            'pubsub_topic_processed': self.pubsub_topic_processed,
            'pubsub_topic_analysis': self.pubsub_topic_analysis,
            'pubsub_topic_simulation': self.pubsub_topic_simulation,
            'bigquery_dataset': self.bigquery_dataset,
            'bigquery_table_events': self.bigquery_table_events,
            'bigquery_table_metrics': self.bigquery_table_metrics,
            'bigquery_table_activity': self.bigquery_table_activity,
            'auth_provider_id': self.auth_provider_id,
            'auth_phone_provider': self.auth_phone_provider,
            'enable_dlp': self.enable_dlp,
            'enable_cmek': self.enable_cmek,
            'enable_vpc_sc': self.enable_vpc_sc,
            'max_concurrent_requests': self.max_concurrent_requests,
            'request_timeout': self.request_timeout,
            'retry_attempts': self.retry_attempts
        }
    
    def validate(self) -> bool:
        """Validate configuration"""
        required_fields = ['project_id']
        
        for field in required_fields:
            if not getattr(self, field):
                logger.error(f"Required configuration field '{field}' is missing")
                return False
        
        # Validate project ID format
        if not self.project_id.replace('-', '').replace('_', '').isalnum():
            logger.error("Project ID must contain only alphanumeric characters, hyphens, and underscores")
            return False
        
        # Validate location format
        if not self.location.replace('-', '').replace('_', '').isalnum():
            logger.error("Location must contain only alphanumeric characters, hyphens, and underscores")
            return False
        
        logger.info("Configuration validation passed")
        return True

# Global configuration instance
config = GoogleCloudConfig.from_environment()

def get_config() -> GoogleCloudConfig:
    """Get the global configuration instance"""
    return config

def update_config(**kwargs) -> None:
    """Update configuration with new values"""
    global config
    for key, value in kwargs.items():
        if hasattr(config, key):
            setattr(config, key, value)
        else:
            logger.warning(f"Unknown configuration key: {key}")

def reset_config() -> None:
    """Reset configuration to default values"""
    global config
    config = GoogleCloudConfig.from_environment()

