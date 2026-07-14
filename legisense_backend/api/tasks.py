from __future__ import annotations

import logging

try:
    from celery import shared_task
except ImportError:  # celery not installed -> use a plain synchronous function
    shared_task = None

logger = logging.getLogger(__name__)


def perform_analysis(doc_id: int) -> None:
    """Run OpenRouter analysis for a document and persist the result.

    Shared by the Celery task and the threaded fallback (used when no broker
    is configured). Safe to call from a worker or a daemon thread.
    """
    from .models import ParsedDocument, DocumentAnalysis
    from ai_models.run_analysis import call_openrouter_for_analysis

    try:
        doc = ParsedDocument.objects.get(id=doc_id)
    except ParsedDocument.DoesNotExist:
        logger.warning("Analysis skipped: document %s not found", doc_id)
        return

    analysis_obj, _ = DocumentAnalysis.objects.update_or_create(
        document=doc,
        defaults={"status": "processing", "error": "", "model": "openrouter"},
    )

    payload = doc.payload or {}
    pages = [p.get("text", "") for p in payload.get("pages", [])]
    meta = {"file_name": doc.file_name, "num_pages": doc.num_pages}

    try:
        analysis_payload = call_openrouter_for_analysis(pages, meta)
    except Exception as exc:  # noqa: BLE001
        logger.exception("Analysis generation failed for document %s", doc_id)
        analysis_obj.status = "failed"
        analysis_obj.error = str(exc)
        analysis_obj.save()
        return

    analysis_obj.status = "success" if analysis_payload else "failed"
    analysis_obj.output_json = analysis_payload or {}
    analysis_obj.error = "" if analysis_payload else "empty response"
    analysis_obj.save()

    if analysis_payload:
        # Trigger translations (lazy import avoids a circular dependency with views)
        from .views import _translate_document_async, _translate_analysis_async

        try:
            _translate_document_async(doc.id, payload)
        except Exception as exc:  # noqa: BLE001
            logger.exception("Document translation failed for %s: %s", doc.id, exc)
        try:
            _translate_analysis_async(analysis_obj.id, analysis_obj.output_json)
        except Exception as exc:  # noqa: BLE001
            logger.exception("Analysis translation failed for %s: %s", analysis_obj.id, exc)


if shared_task is not None:
    @shared_task(name="api.tasks.process_document_analysis", bind=True, max_retries=2)
    def process_document_analysis(self, doc_id: int) -> None:
        try:
            perform_analysis(doc_id)
        except Exception as exc:  # noqa: BLE001
            logger.exception("process_document_analysis failed for %s", doc_id)
            raise self.retry(exc=exc, countdown=15)
else:
    def process_document_analysis(doc_id: int) -> None:
        """Synchronous fallback used only when Celery is unavailable."""
        perform_analysis(doc_id)
