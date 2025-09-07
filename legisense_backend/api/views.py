from pathlib import Path
import tempfile

from django.http import JsonResponse, HttpRequest
from django.views.decorators.csrf import csrf_exempt

from .models import ParsedDocument
from documents.pdf_document_parser import extract_pdf_text


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

    doc = ParsedDocument.objects.create(
        file_name=Path(data.get("file") or uploaded_file.name).name,
        num_pages=int(data.get("num_pages") or 0),
        payload=data,
    )

    return JsonResponse(data)

