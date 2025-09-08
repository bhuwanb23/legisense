from pathlib import Path
import tempfile

from django.http import JsonResponse, HttpRequest
from django.views.decorators.csrf import csrf_exempt
from django.core.files.base import ContentFile
from django.shortcuts import get_object_or_404

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
