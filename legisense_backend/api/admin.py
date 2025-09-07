from django.contrib import admin
from .models import ParsedDocument


@admin.register(ParsedDocument)
class ParsedDocumentAdmin(admin.ModelAdmin):
    list_display = ("id", "file_name", "num_pages", "created_at")
    search_fields = ("file_name",)
    readonly_fields = ("created_at",)
