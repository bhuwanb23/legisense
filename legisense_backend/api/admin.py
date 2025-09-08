from django.contrib import admin
from .models import ParsedDocument, DocumentAnalysis


@admin.register(ParsedDocument)
class ParsedDocumentAdmin(admin.ModelAdmin):
    list_display = ("id", "file_name", "num_pages", "created_at")
    search_fields = ("file_name",)
    readonly_fields = ("created_at",)


@admin.register(DocumentAnalysis)
class DocumentAnalysisAdmin(admin.ModelAdmin):
    list_display = ("id", "document", "status", "model", "created_at", "updated_at")
    list_filter = ("status",)
    search_fields = ("document__file_name",)
    readonly_fields = ("created_at", "updated_at")
