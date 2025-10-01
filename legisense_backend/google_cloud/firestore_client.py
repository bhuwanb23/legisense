"""
Mock Firestore client for Legisense.
Imitates a small subset of Firestore's document operations.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional


class MockFirestoreClient:
    def __init__(self) -> None:
        self._collections: Dict[str, Dict[str, Dict[str, Any]]] = {}

    def set_document(self, collection: str, doc_id: str, data: Dict[str, Any]) -> None:
        self._collections.setdefault(collection, {})[doc_id] = dict(data)

    def get_document(self, collection: str, doc_id: str) -> Optional[Dict[str, Any]]:
        return self._collections.get(collection, {}).get(doc_id)

    def query_documents(self, collection: str, where: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        docs = list(self._collections.get(collection, {}).values())
        if not where:
            return docs
        return [d for d in docs if all(d.get(k) == v for k, v in where.items())]

