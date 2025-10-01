"""
Mock BigQuery client for Legisense.
Provides minimal dataset/table and insert/query capabilities for tests.
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional


class MockBigQueryClient:
    def __init__(self) -> None:
        self._datasets: Dict[str, Dict[str, List[Dict[str, Any]]]] = {}

    def create_dataset(self, name: str) -> None:
        self._datasets.setdefault(name, {})

    def create_table(self, dataset: str, table: str) -> None:
        self._datasets.setdefault(dataset, {}).setdefault(table, [])

    def insert_rows(self, dataset: str, table: str, rows: List[Dict[str, Any]]) -> int:
        tbl = self._datasets.setdefault(dataset, {}).setdefault(table, [])
        tbl.extend(rows)
        return len(rows)

    def query(self, dataset: str, table: str, where: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        rows = list(self._datasets.get(dataset, {}).get(table, []))
        if not where:
            return rows
        return [r for r in rows if all(r.get(k) == v for k, v in where.items())]

