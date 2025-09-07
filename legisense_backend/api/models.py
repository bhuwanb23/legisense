from django.db import models


class ParsedDocument(models.Model):
    """Stores the parsed output of an uploaded PDF document.

    We keep the raw JSON payload for flexibility and a few introspective fields
    for easy querying.
    """

    file_name = models.CharField(max_length=255)
    uploaded_file = models.FileField(upload_to='uploads/pdfs/', blank=True, null=True)
    num_pages = models.PositiveIntegerField(default=0)
    payload = models.JSONField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:  # pragma: no cover - simple model string
        return f"ParsedDocument({self.file_name}, pages={self.num_pages})"

