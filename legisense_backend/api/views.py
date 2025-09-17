from pathlib import Path
import tempfile
import json

from django.http import JsonResponse, HttpRequest
from django.views.decorators.csrf import csrf_exempt
from django.core.files.base import ContentFile
from django.shortcuts import get_object_or_404
from django.db import transaction

from .models import ParsedDocument, DocumentAnalysis, DocumentTranslation, DocumentAnalysisTranslation
from documents.pdf_document_parser import extract_pdf_text
from ai_models.run_analysis import call_openrouter_for_analysis
from translation.translator import DocumentTranslator


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
    return JsonResponse({"id": doc.analysis.id, "analysis": doc.analysis.output_json})


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

    # Check if document already has simulations
    from .models import SimulationSession
    existing_simulations = SimulationSession.objects.filter(document=doc).order_by('-created_at')
    
    if existing_simulations.exists():
        # Return the most recent simulation session ID
        latest_simulation = existing_simulations.first()
        print(f"🔍 Found existing simulation for document {pk}: session_id={latest_simulation.id}")
        return JsonResponse({
            "status": "ok", 
            "session_id": latest_simulation.id,
            "cached": True,
            "message": "Using existing simulation data"
        })

    # No existing simulation found, generate new one via LLM
    print(f"🔍 No existing simulation found for document {pk}, generating new one...")
    
    # Run extraction (LLM) to produce a structured JSON based on document content
    try:
        from ai_models.run_simulation_models_extraction import run_extraction
        # Pass document content to the extraction
        document_content = doc.payload.get('full_text', '') if doc.payload else ''
        print(f"🔍 Document content length: {len(document_content)}")
        print(f"🔍 Document content preview: {document_content[:200]}...")
        extracted = run_extraction(document_content=document_content)
        print(f"🤖 LLM extracted data: {extracted}")
    except Exception as exc:  # noqa: BLE001
        # Return error instead of mock data
        print(f"❌ Simulation extraction failed: {exc}")
        return JsonResponse({
            "error": "Simulation generation failed",
            "message": "Unable to generate simulation data. Please try again later.",
            "details": str(exc)
        }, status=500)

    # Map extracted JSON to our import payload shape using LLM data
    session_data = extracted.get("session", {})
    session_payload = {
        "document_id": doc.id,
        "session": {
            "title": session_data.get("title", f"Simulation for {doc.file_name}"),
            "scenario": session_data.get("scenario", "normal"),
            "parameters": session_data.get("parameters", {"source": "llm_extraction"}),
            "jurisdiction": session_data.get("jurisdiction", ""),
            "jurisdiction_note": session_data.get("jurisdiction_note", ""),
        },
        "timeline": extracted.get("timeline", []),
        "penalty_forecast": extracted.get("penalty_forecast", []),
        "exit_comparisons": extracted.get("exit_comparisons", []),
        "narratives": extracted.get("narratives", []),
        "long_term": extracted.get("long_term", []),
        "risk_alerts": extracted.get("risk_alerts", []),
    }

    # Try to infer some defaults from enums/relationships if provided (best-effort)
    # For now, we leave those arrays empty unless you want me to create mock data from the model definitions.

    # Persist via the same code path as manual import
    request._body = json.dumps(session_payload).encode("utf-8")  # type: ignore[attr-defined]
    result = import_simulation_view(request)
    
    # If successful, add metadata to indicate this is a new simulation
    if isinstance(result, JsonResponse) and result.status_code == 200:
        response_data = json.loads(result.content.decode('utf-8'))
        response_data['cached'] = False
        response_data['message'] = 'New simulation generated'
        return JsonResponse(response_data)
    
    return result


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
            label=str(row.get("label", f"Month {row.get('month', 1)}"))[:64],
            base_amount=float(row.get("base_amount", 0)),
            fees_amount=float(row.get("fees_amount", 0)),
            penalties_amount=float(row.get("penalties_amount", 0)),
            total_amount=float(row.get("total_amount", 0)),
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
            financial_impact=[item.get("financial_impact", "")] if isinstance(item.get("financial_impact"), str) else (item.get("financial_impact") or []),
        )

    for item in payload.get("long_term", []) or []:
        SimulationLongTermPoint.objects.create(
            session=session,
            index=int(item.get("index") or 0),
            label=str(item.get("label", ""))[:64],
            value=item.get("value") or 0,
            description=str(item.get("description", ""))[:255],
        )

    for item in payload.get("risk_alerts", []) or []:
        SimulationRiskAlert.objects.create(
            session=session,
            level=str(item.get("level", "info"))[:16],
            message=str(item.get("message", ""))[:512],
        )

    return JsonResponse({"status": "ok", "session_id": session.id})


def simulation_detail_view(request: HttpRequest, pk: int):
    """Fetch simulation session and all related data."""
    if request.method != "GET":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    from .models import (
        SimulationSession,
        SimulationTimelineNode,
        SimulationPenaltyForecast,
        SimulationExitComparison,
        SimulationNarrativeOutcome,
        SimulationLongTermPoint,
        SimulationRiskAlert,
    )

    session = get_object_or_404(SimulationSession, pk=pk)

    # Fetch all related data
    timeline_nodes = SimulationTimelineNode.objects.filter(session=session).order_by('order')
    penalty_forecasts = SimulationPenaltyForecast.objects.filter(session=session).order_by('id')
    exit_comparisons = SimulationExitComparison.objects.filter(session=session).order_by('id')
    narratives = SimulationNarrativeOutcome.objects.filter(session=session).order_by('id')
    long_term_points = SimulationLongTermPoint.objects.filter(session=session).order_by('index')
    risk_alerts = SimulationRiskAlert.objects.filter(session=session).order_by('id')

    # Build response
    response_data = {
        "session": {
            "id": session.id,
            "title": session.title,
            "scenario": session.scenario,
            "parameters": session.parameters,
            "jurisdiction": session.jurisdiction,
            "jurisdiction_note": session.jurisdiction_note,
            "created_at": session.created_at.isoformat(),
        },
        "timeline": [
            {
                "id": node.id,
                "order": node.order,
                "title": node.title,
                "description": node.description,
                "detailed_description": node.detailed_description,
                "risks": node.risks,
            }
            for node in timeline_nodes
        ],
        "penalty_forecast": [
            {
                "id": forecast.id,
                "label": forecast.label,
                "base_amount": float(forecast.base_amount),
                "fees_amount": float(forecast.fees_amount),
                "penalties_amount": float(forecast.penalties_amount),
                "total_amount": float(forecast.total_amount),
            }
            for forecast in penalty_forecasts
        ],
        "exit_comparisons": [
            {
                "id": comp.id,
                "label": comp.label,
                "penalty_text": comp.penalty_text,
                "risk_level": comp.risk_level,
                "benefits_lost": comp.benefits_lost,
            }
            for comp in exit_comparisons
        ],
        "narratives": [
            {
                "id": narrative.id,
                "title": narrative.title,
                "subtitle": narrative.subtitle,
                "narrative": narrative.narrative,
                "severity": narrative.severity,
                "key_points": narrative.key_points,
                "financial_impact": narrative.financial_impact,
            }
            for narrative in narratives
        ],
        "long_term": [
            {
                "id": point.id,
                "index": point.index,
                "label": point.label,
                "value": float(point.value),
                "description": point.description,
            }
            for point in long_term_points
        ],
        "risk_alerts": [
            {
                "id": alert.id,
                "level": alert.level,
                "message": alert.message,
            }
            for alert in risk_alerts
        ],
    }

    return JsonResponse(response_data)


def document_simulations_view(request: HttpRequest, pk: int):
    """Check if a document has existing simulations."""
    if request.method != "GET":
        return JsonResponse({"error": "Method not allowed"}, status=405)

    doc = get_object_or_404(ParsedDocument, pk=pk)
    
    from .models import SimulationSession
    simulations = SimulationSession.objects.filter(document=doc).order_by('-created_at')
    
    response_data = {
        "document_id": doc.id,
        "has_simulations": simulations.exists(),
        "simulation_count": simulations.count(),
        "latest_simulation": None,
    }
    
    if simulations.exists():
        latest = simulations.first()
        response_data["latest_simulation"] = {
            "id": latest.id,
            "title": latest.title,
            "scenario": latest.scenario,
            "created_at": latest.created_at.isoformat(),
        }
    
    return JsonResponse(response_data)


@csrf_exempt
def translate_document_view(request: HttpRequest, pk: int):
    """Translate a document to a specific language."""
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)
    
    try:
        payload = json.loads(request.body.decode("utf-8"))
    except Exception as exc:  # noqa: BLE001
        return JsonResponse({"error": f"Invalid JSON: {exc}"}, status=400)
    
    target_language = payload.get("language", "en")
    if target_language not in ['en', 'hi', 'ta', 'te']:
        return JsonResponse({"error": "Invalid language code"}, status=400)
    
    doc = get_object_or_404(ParsedDocument, pk=pk)
    
    # Check if translation already exists
    existing_translation = DocumentTranslation.objects.filter(
        document=doc, 
        language=target_language
    ).first()
    
    if existing_translation:
        return JsonResponse({
            "status": "ok",
            "translation_id": existing_translation.id,
            "language": existing_translation.language,
            "cached": True,
            "message": "Translation already exists"
        })
    
    # Create new translation
    try:
        translator = DocumentTranslator()
        target_lang_code = translator.get_language_code(target_language)
        
        # Get original document data
        original_pages = doc.payload.get('pages', [])
        original_full_text = doc.payload.get('full_text', '')
        
        # Translate pages
        translated_pages = translator.translate_pages(original_pages, target_lang_code)
        
        # Translate full text
        translated_full_text = translator.translate_full_text(original_full_text, target_lang_code)
        
        # Create translation record
        translation = DocumentTranslation.objects.create(
            document=doc,
            language=target_language,
            translated_pages=translated_pages,
            translated_full_text=translated_full_text
        )
        
        return JsonResponse({
            "status": "ok",
            "translation_id": translation.id,
            "language": translation.language,
            "cached": False,
            "message": "Translation created successfully"
        })
        
    except Exception as exc:  # noqa: BLE001
        return JsonResponse({
            "error": "Translation failed",
            "message": "Unable to translate document. Please try again later.",
            "details": str(exc)
        }, status=500)


def get_document_translation_view(request: HttpRequest, pk: int, language: str):
    """Get translated document content."""
    if request.method != "GET":
        return JsonResponse({"error": "Method not allowed"}, status=405)
    
    if language not in ['en', 'hi', 'ta', 'te']:
        return JsonResponse({"error": "Invalid language code"}, status=400)
    
    doc = get_object_or_404(ParsedDocument, pk=pk)
    
    # If requesting English, return original document
    if language == 'en':
        data = dict(doc.payload)
        data["id"] = doc.id
        data["file_name"] = doc.file_name
        data["num_pages"] = doc.num_pages
        data["file_url"] = doc.uploaded_file.url if doc.uploaded_file else None
        data["analysis_available"] = hasattr(doc, "analysis") and doc.analysis.status == "success"
        data["language"] = "en"
        return JsonResponse(data)
    
    # Get translation
    translation = DocumentTranslation.objects.filter(
        document=doc, 
        language=language
    ).first()
    
    if not translation:
        return JsonResponse({
            "error": "Translation not found",
            "message": f"Document not translated to {language}. Please request translation first."
        }, status=404)
    
    # Return translated data
    data = {
        "id": doc.id,
        "file_name": doc.file_name,
        "num_pages": doc.num_pages,
        "file_url": doc.uploaded_file.url if doc.uploaded_file else None,
        "analysis_available": hasattr(doc, "analysis") and doc.analysis.status == "success",
        "language": language,
        "pages": translation.translated_pages,
        "full_text": translation.translated_full_text,
        "num_pages": len(translation.translated_pages)
    }
    
    return JsonResponse(data)


def list_document_translations_view(request: HttpRequest, pk: int):
    """List all available translations for a document."""
    if request.method != "GET":
        return JsonResponse({"error": "Method not allowed"}, status=405)
    
    doc = get_object_or_404(ParsedDocument, pk=pk)
    
    translations = DocumentTranslation.objects.filter(document=doc).values(
        'id', 'language', 'created_at', 'updated_at'
    )
    
    return JsonResponse({
        "document_id": doc.id,
        "available_translations": list(translations),
        "total_translations": translations.count()
    })


@csrf_exempt
def translate_analysis_view(request: HttpRequest, pk: int):
    """Translate document analysis to a specific language."""
    if request.method != "POST":
        return JsonResponse({"error": "Method not allowed"}, status=405)
    
    try:
        payload = json.loads(request.body)
    except Exception as exc:  # noqa: BLE001
        return JsonResponse({"error": f"Invalid JSON: {exc}"}, status=400)
    
    target_language = payload.get("language", "en")
    if target_language not in ['en', 'hi', 'ta', 'te']:
        return JsonResponse({"error": "Invalid language code"}, status=400)
    
    analysis = get_object_or_404(DocumentAnalysis, pk=pk)
    
    # Check if translation already exists
    existing_translation = DocumentAnalysisTranslation.objects.filter(
        analysis=analysis, language=target_language
    ).first()
    
    if existing_translation:
        return JsonResponse({
            "message": "Translation already exists",
            "translation_id": existing_translation.id,
            "language": target_language
        })
    
    # If requesting English, return original analysis
    if target_language == 'en':
        return JsonResponse({
            "message": "Original analysis returned",
            "analysis": analysis.output_json,
            "language": "en"
        })
    
    # Translate the analysis
    translator = DocumentTranslator()
    original_analysis = analysis.output_json or {}
    
    try:
        translated_analysis = translator.translate_analysis_json(
            original_analysis, target_language, 'en'
        )
        
        # Save the translation
        translation = DocumentAnalysisTranslation.objects.create(
            analysis=analysis,
            language=target_language,
            translated_analysis_json=translated_analysis
        )
        
        return JsonResponse({
            "message": "Analysis translated successfully",
            "translation_id": translation.id,
            "language": target_language,
            "analysis": translated_analysis
        })
        
    except Exception as e:
        return JsonResponse({"error": f"Translation failed: {str(e)}"}, status=500)


def get_analysis_translation_view(request: HttpRequest, pk: int, language: str):
    """Get translated analysis for a specific language."""
    if request.method != "GET":
        return JsonResponse({"error": "Method not allowed"}, status=405)
    
    if language not in ['en', 'hi', 'ta', 'te']:
        return JsonResponse({"error": "Invalid language code"}, status=400)
    
    analysis = get_object_or_404(DocumentAnalysis, pk=pk)
    
    # If requesting English, return original analysis
    if language == 'en':
        return JsonResponse({
            "analysis": analysis.output_json,
            "language": "en",
            "is_original": True
        })
    
    # Try to get existing translation
    translation = DocumentAnalysisTranslation.objects.filter(
        analysis=analysis, language=language
    ).first()
    
    if translation:
        return JsonResponse({
            "analysis": translation.translated_analysis_json,
            "language": language,
            "is_original": False,
            "translation_id": translation.id
        })
    
    return JsonResponse({"error": "Translation not found"}, status=404)


def list_analysis_translations_view(request: HttpRequest, pk: int):
    """List all available translations for a document analysis."""
    if request.method != "GET":
        return JsonResponse({"error": "Method not allowed"}, status=405)
    
    analysis = get_object_or_404(DocumentAnalysis, pk=pk)
    translations = DocumentAnalysisTranslation.objects.filter(analysis=analysis)
    
    translation_list = [
        {
            "id": t.id,
            "language": t.language,
            "created_at": t.created_at.isoformat(),
            "updated_at": t.updated_at.isoformat()
        }
        for t in translations
    ]
    
    return JsonResponse({
        "analysis_id": analysis.id,
        "available_translations": translation_list,
        "total_translations": translations.count()
    })


