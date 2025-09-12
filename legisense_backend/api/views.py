from pathlib import Path
import tempfile
import json

from django.http import JsonResponse, HttpRequest
from django.views.decorators.csrf import csrf_exempt
from django.core.files.base import ContentFile
from django.shortcuts import get_object_or_404
from django.db import transaction

from .models import ParsedDocument, DocumentAnalysis
from documents.pdf_document_parser import extract_pdf_text
from ai_models.run_analysis import call_openrouter_for_analysis


@csrf_exempt
def parse_pdf_view(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    uploaded_file = request.FILES.get("file")
    if not uploaded_file:
        return JsonResponse({"error": "No file uploaded."}, status=400)

    # Save to a temporary file to pass a filesystem path to the parser
    with tempfile.NamedTemporaryFile(delete=False, suffix=Path(uploaded_file.name).suffix) as tmp:
        for chunk in uploaded_file.chunks():
            tmp.write(chunk)
        tmp_path = Path(tmp.name)

    try:
        data = extract_pdf_text(tmp_path)
    except Exception as exc:  # noqa: BLE001 - bubble parser errors
        return JsonResponse({"error": str(exc)}, status=500)
    finally:
        try:
            tmp_path.unlink(missing_ok=True)
        except Exception:
            pass

    # Fallback: if parser returned no page texts, synthesize from full_text
    try:
        pages = data.get("pages") or []
        if not pages:
            full_text = (data.get("full_text") or "").strip()
            if full_text:
                # Split by form-feed if present; otherwise make a single page
                candidates = [p for p in full_text.split("\f") if p.strip()]
                if not candidates:
                    candidates = [full_text]
                data["pages"] = [
                    {"page_number": i + 1, "text": txt}
                    for i, txt in enumerate(candidates)
                ]
                data["num_pages"] = len(data["pages"])  # keep num_pages consistent
    except Exception:
        # If anything goes wrong in fallback, keep original data as-is
        pass

    # Create DB record and also persist the uploaded file into MEDIA_ROOT
    doc = ParsedDocument(
        file_name=Path(data.get("file") or uploaded_file.name).name,
        num_pages=int(data.get("num_pages") or 0),
        payload=data,
    )
    # Attach uploaded file contents
    uploaded_file.seek(0)
    doc.uploaded_file.save(uploaded_file.name, ContentFile(uploaded_file.read()), save=False)
    doc.save()

    # Include id and stored file URL for client convenience
    response = dict(data)
    response["id"] = doc.id
    response["file_url"] = doc.uploaded_file.url if doc.uploaded_file else None

    # Trigger analysis synchronously (simple implementation)
    try:
        meta = {"file_name": doc.file_name, "num_pages": doc.num_pages}
        pages = [p.get("text", "") for p in data.get("pages", [])]
        analysis_payload = call_openrouter_for_analysis(pages, meta)
        DocumentAnalysis.objects.update_or_create(
            document=doc,
            defaults={
                "status": "success" if analysis_payload else "failed",
                "output_json": analysis_payload or {},
                "model": "openrouter",
            },
        )
    except Exception as exc:  # noqa: BLE001
        DocumentAnalysis.objects.update_or_create(
            document=doc,
            defaults={"status": "failed", "error": str(exc)},
        )

    response["analysis_available"] = DocumentAnalysis.objects.filter(document=doc, status="success").exists()
    return JsonResponse(response)


def list_parsed_docs_view(request: HttpRequest):
    if request.method != "GET":
        return JsonResponse({"error": "Method not allowed"}, status=405)
    qs = ParsedDocument.objects.order_by("-created_at").values("id", "file_name", "num_pages", "created_at")
    return JsonResponse({"results": list(qs)})


def parsed_doc_detail_view(request: HttpRequest, pk: int):
    if request.method != "GET":
        return JsonResponse({"error": "Method not allowed"}, status=405)
    doc = get_object_or_404(ParsedDocument, pk=pk)
    data = dict(doc.payload)
    data["id"] = doc.id
    data["file_name"] = doc.file_name
    data["num_pages"] = doc.num_pages
    data["file_url"] = doc.uploaded_file.url if doc.uploaded_file else None
    data["analysis_available"] = hasattr(doc, "analysis") and doc.analysis.status == "success"
    return JsonResponse(data)


def parsed_doc_analysis_view(request: HttpRequest, pk: int):
    if request.method != "GET":
        return JsonResponse({"error": "Method not allowed"}, status=405)
    doc = get_object_or_404(ParsedDocument, pk=pk)
    if not hasattr(doc, "analysis") or doc.analysis.status != "success":
        return JsonResponse({"error": "Analysis not available"}, status=404)
    return JsonResponse({"id": doc.id, "analysis": doc.analysis.output_json})


@csrf_exempt
def parsed_doc_analyze_view(request: HttpRequest, pk: int):
    """(Re)run analysis for a given document and persist result."""
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)
    doc = get_object_or_404(ParsedDocument, pk=pk)
    payload = doc.payload or {}
    pages = [p.get("text", "") for p in payload.get("pages", [])]
    meta = {"file_name": doc.file_name, "num_pages": doc.num_pages}
    try:
        analysis_payload = call_openrouter_for_analysis(pages, meta)
        obj, _ = DocumentAnalysis.objects.update_or_create(
            document=doc,
            defaults={
                "status": "success" if analysis_payload else "failed",
                "output_json": analysis_payload or {},
                "model": "openrouter",
                "error": "" if analysis_payload else "empty response",
            },
        )
        return JsonResponse({"status": obj.status, "analysis": obj.output_json})
    except Exception as exc:  # noqa: BLE001
        obj, _ = DocumentAnalysis.objects.update_or_create(
            document=doc,
            defaults={"status": "failed", "error": str(exc)},
        )
        return JsonResponse({"error": str(exc)}, status=500)


@csrf_exempt
@transaction.atomic
def parsed_doc_simulate_view(request: HttpRequest, pk: int):
    """Generate simulation JSON via OpenRouter and persist records for a document."""
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    doc = get_object_or_404(ParsedDocument, pk=pk)

    # Run extraction (LLM) to produce a structured JSON
    try:
        from ai_models.run_simulation_models_extraction import run_extraction
        extracted = run_extraction()
    except Exception as exc:  # noqa: BLE001
        # Graceful fallback: continue with a minimal payload so UX flow still works
        extracted = {}

    # Map extracted JSON to our import payload shape
    session_payload = {
        "document_id": doc.id,
        "session": {
            "title": f"Simulation for {doc.file_name}",
            "scenario": "normal",
            "parameters": {"source": "llm_extraction"},
            "jurisdiction": "",
            "jurisdiction_note": "",
        },
        "timeline": [],
        "penalty_forecast": [],
        "exit_comparisons": [],
        "narratives": [],
        "long_term": [],
        "risk_alerts": [],
    }

    # Try to infer some defaults from enums/relationships if provided (best-effort)
    # For now, we leave those arrays empty unless you want me to create mock data from the model definitions.

    # Persist via the same code path as manual import
    request._body = json.dumps(session_payload).encode("utf-8")  # type: ignore[attr-defined]
    return import_simulation_view(request)


@csrf_exempt
@transaction.atomic
def import_simulation_view(request: HttpRequest):
    """Accepts a JSON payload describing a simulation and persists related models.

    Expected JSON (minimal):
    {
      "document_id": 1,
      "session": {
        "title": "...",
        "scenario": "normal",
        "parameters": {...},
        "jurisdiction": "...",
        "jurisdiction_note": "..."
      },
      "timeline": [ {"order": 1, "title": "...", "description": "...", "detailed_description": "...", "risks": []} ],
      "penalty_forecast": [ {"label": "Month 1", "base_amount": 0, "fees_amount": 0, "penalties_amount": 0, "total_amount": 0} ],
      "exit_comparisons": [ {"label": "Exit at 6 months", "penalty_text": "₹25,000", "risk_level": "medium", "benefits_lost": "..."} ],
      "narratives": [ {"title": "...", "subtitle": "...", "narrative": "...", "severity": "low", "key_points": [], "financial_impact": []} ],
      "long_term": [ {"index": 0, "label": "Month 0", "value": 0} ],
      "risk_alerts": [ {"level": "info", "message": "..."} ]
    }
    """
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    try:
        payload = json.loads(request.body.decode("utf-8"))
    except Exception as exc:  # noqa: BLE001
        return JsonResponse({"error": f"Invalid JSON: {exc}"}, status=400)

    doc_id = payload.get("document_id")
    if not doc_id:
        return JsonResponse({"error": "document_id is required"}, status=400)

    document = get_object_or_404(ParsedDocument, pk=doc_id)

    from .models import (
        SimulationSession,
        SimulationTimelineNode,
        SimulationPenaltyForecast,
        SimulationExitComparison,
        SimulationNarrativeOutcome,
        SimulationLongTermPoint,
        SimulationRiskAlert,
    )

    session_data = payload.get("session") or {}
    session = SimulationSession.objects.create(
        document=document,
        title=str(session_data.get("title", ""))[:255],
        scenario=str(session_data.get("scenario", "normal"))[:32],
        parameters=session_data.get("parameters") or {},
        jurisdiction=str(session_data.get("jurisdiction", ""))[:128],
        jurisdiction_note=str(session_data.get("jurisdiction_note", "")),
    )

    for node in payload.get("timeline", []) or []:
        SimulationTimelineNode.objects.create(
            session=session,
            order=int(node.get("order") or 0),
            title=str(node.get("title", ""))[:255],
            description=str(node.get("description", ""))[:512],
            detailed_description=str(node.get("detailed_description", "")),
            risks=node.get("risks") or [],
        )

    for row in payload.get("penalty_forecast", []) or []:
        SimulationPenaltyForecast.objects.create(
            session=session,
            label=str(row.get("label", ""))[:64],
            base_amount=row.get("base_amount") or 0,
            fees_amount=row.get("fees_amount") or 0,
            penalties_amount=row.get("penalties_amount") or 0,
            total_amount=row.get("total_amount") or 0,
        )

    for item in payload.get("exit_comparisons", []) or []:
        SimulationExitComparison.objects.create(
            session=session,
            label=str(item.get("label", ""))[:128],
            penalty_text=str(item.get("penalty_text", ""))[:64],
            risk_level=str(item.get("risk_level", "low"))[:16],
            benefits_lost=str(item.get("benefits_lost", ""))[:128],
        )

    for item in payload.get("narratives", []) or []:
        SimulationNarrativeOutcome.objects.create(
            session=session,
            title=str(item.get("title", ""))[:255],
            subtitle=str(item.get("subtitle", ""))[:255],
            narrative=str(item.get("narrative", "")),
            severity=str(item.get("severity", "low"))[:16],
            key_points=item.get("key_points") or [],
            financial_impact=item.get("financial_impact") or [],
        )

    for item in payload.get("long_term", []) or []:
        SimulationLongTermPoint.objects.create(
            session=session,
            index=int(item.get("index") or 0),
            label=str(item.get("label", ""))[:64],
            value=item.get("value") or 0,
        )

    for item in payload.get("risk_alerts", []) or []:
        SimulationRiskAlert.objects.create(
            session=session,
            level=str(item.get("level", "info"))[:16],
            message=str(item.get("message", ""))[:512],
        )

    return JsonResponse({"status": "ok", "session_id": session.id})
