"""
Google Cloud Service Factory for Legisense
Factory pattern for creating and managing Google Cloud service clients
"""

import logging
from typing import Dict, Any, Optional, Type
from .config import GoogleCloudConfig, get_config
from .document_ai_client import MockDocumentAIClient, DocumentAIClient
from .vertex_ai_client import MockVertexAIClient, VertexAIClient
from .storage_client import MockStorageClient, StorageClient
from .firestore_client import MockFirestoreClient, FirestoreClient
from .pubsub_client import MockPubSubClient, PubSubClient
from .bigquery_client import MockBigQueryClient, BigQueryClient
from .auth_client import MockAuthClient, AuthClient

logger = logging.getLogger(__name__)

class GoogleCloudServiceFactory:
    """
    Factory for creating Google Cloud service clients
    Supports both mock and production implementations
    """
    
    def __init__(self, config: Optional[GoogleCloudConfig] = None, use_mock: bool = True):
        self.config = config or get_config()
        self.use_mock = use_mock
        self._clients = {}
        logger.info(f"Initialized Google Cloud Service Factory (mock={use_mock})")
    
    def get_document_ai_client(self) -> Any:
        """Get Document AI client"""
        if 'document_ai' not in self._clients:
            if self.use_mock:
                self._clients['document_ai'] = MockDocumentAIClient(
                    project_id=self.config.project_id,
                    location=self.config.document_ai_location
                )
            else:
                self._clients['document_ai'] = DocumentAIClient(
                    project_id=self.config.project_id,
                    location=self.config.document_ai_location
                )
        return self._clients['document_ai']
    
    def get_vertex_ai_client(self) -> Any:
        """Get Vertex AI client"""
        if 'vertex_ai' not in self._clients:
            if self.use_mock:
                self._clients['vertex_ai'] = MockVertexAIClient(
                    project_id=self.config.project_id,
                    location=self.config.vertex_ai_location
                )
            else:
                self._clients['vertex_ai'] = VertexAIClient(
                    project_id=self.config.project_id,
                    location=self.config.vertex_ai_location
                )
        return self._clients['vertex_ai']
    
    def get_storage_client(self) -> Any:
        """Get Cloud Storage client"""
        if 'storage' not in self._clients:
            if self.use_mock:
                self._clients['storage'] = MockStorageClient(
                    project_id=self.config.project_id
                )
            else:
                self._clients['storage'] = StorageClient(
                    project_id=self.config.project_id
                )
        return self._clients['storage']
    
    def get_firestore_client(self) -> Any:
        """Get Firestore client"""
        if 'firestore' not in self._clients:
            if self.use_mock:
                self._clients['firestore'] = MockFirestoreClient(
                    project_id=self.config.project_id
                )
            else:
                self._clients['firestore'] = FirestoreClient(
                    project_id=self.config.project_id
                )
        return self._clients['firestore']
    
    def get_pubsub_client(self) -> Any:
        """Get Pub/Sub client"""
        if 'pubsub' not in self._clients:
            if self.use_mock:
                self._clients['pubsub'] = MockPubSubClient(
                    project_id=self.config.project_id
                )
            else:
                self._clients['pubsub'] = PubSubClient(
                    project_id=self.config.project_id
                )
        return self._clients['pubsub']
    
    def get_bigquery_client(self) -> Any:
        """Get BigQuery client"""
        if 'bigquery' not in self._clients:
            if self.use_mock:
                self._clients['bigquery'] = MockBigQueryClient(
                    project_id=self.config.project_id,
                    dataset_id=self.config.dataset_id
                )
            else:
                self._clients['bigquery'] = BigQueryClient(
                    project_id=self.config.project_id,
                    dataset_id=self.config.dataset_id
                )
        return self._clients['bigquery']
    
    def get_auth_client(self) -> Any:
        """Get Auth client"""
        if 'auth' not in self._clients:
            if self.use_mock:
                self._clients['auth'] = MockAuthClient(
                    project_id=self.config.project_id
                )
            else:
                self._clients['auth'] = AuthClient(
                    project_id=self.config.project_id
                )
        return self._clients['auth']
    
    def get_all_clients(self) -> Dict[str, Any]:
        """Get all service clients"""
        return {
            'document_ai': self.get_document_ai_client(),
            'vertex_ai': self.get_vertex_ai_client(),
            'storage': self.get_storage_client(),
            'firestore': self.get_firestore_client(),
            'pubsub': self.get_pubsub_client(),
            'bigquery': self.get_bigquery_client(),
            'auth': self.get_auth_client()
        }
    
    def reset_clients(self) -> None:
        """Reset all clients (useful for testing)"""
        self._clients.clear()
        logger.info("All Google Cloud clients reset")
    
    def switch_to_production(self) -> None:
        """Switch to production clients"""
        self.use_mock = False
        self.reset_clients()
        logger.info("Switched to production Google Cloud clients")
    
    def switch_to_mock(self) -> None:
        """Switch to mock clients"""
        self.use_mock = True
        self.reset_clients()
        logger.info("Switched to mock Google Cloud clients")

# Global service factory instance
_service_factory = None

def get_service_factory(use_mock: bool = True) -> GoogleCloudServiceFactory:
    """Get the global service factory instance"""
    global _service_factory
    if _service_factory is None:
        _service_factory = GoogleCloudServiceFactory(use_mock=use_mock)
    return _service_factory

def get_document_ai_client() -> Any:
    """Convenience function to get Document AI client"""
    return get_service_factory().get_document_ai_client()

def get_vertex_ai_client() -> Any:
    """Convenience function to get Vertex AI client"""
    return get_service_factory().get_vertex_ai_client()

def get_storage_client() -> Any:
    """Convenience function to get Storage client"""
    return get_service_factory().get_storage_client()

def get_firestore_client() -> Any:
    """Convenience function to get Firestore client"""
    return get_service_factory().get_firestore_client()

def get_pubsub_client() -> Any:
    """Convenience function to get Pub/Sub client"""
    return get_service_factory().get_pubsub_client()

def get_bigquery_client() -> Any:
    """Convenience function to get BigQuery client"""
    return get_service_factory().get_bigquery_client()

def get_auth_client() -> Any:
    """Convenience function to get Auth client"""
    return get_service_factory().get_auth_client()

def reset_service_factory() -> None:
    """Reset the global service factory"""
    global _service_factory
    _service_factory = None
    logger.info("Google Cloud service factory reset")

