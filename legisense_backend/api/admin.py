from django.contrib import admin
from .models import ParsedDocument, DocumentAnalysis
from .models import (
    SimulationSession,
    SimulationTimelineNode,
    SimulationPenaltyForecast,
    SimulationExitComparison,
    SimulationNarrativeOutcome,
    SimulationLongTermPoint,
    SimulationRiskAlert,
)


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


@admin.register(SimulationSession)
class SimulationSessionAdmin(admin.ModelAdmin):
    list_display = ("id", "document", "scenario", "title", "created_at")
    list_filter = ("scenario",)
    search_fields = ("title", "document__file_name")


@admin.register(SimulationTimelineNode)
class SimulationTimelineNodeAdmin(admin.ModelAdmin):
    list_display = ("id", "session", "order", "title")
    list_filter = ("session",)
    search_fields = ("title",)


@admin.register(SimulationPenaltyForecast)
class SimulationPenaltyForecastAdmin(admin.ModelAdmin):
    list_display = ("id", "session", "label", "total_amount")
    list_filter = ("session",)


@admin.register(SimulationExitComparison)
class SimulationExitComparisonAdmin(admin.ModelAdmin):
    list_display = ("id", "session", "label", "risk_level")
    list_filter = ("risk_level", "session")


@admin.register(SimulationNarrativeOutcome)
class SimulationNarrativeOutcomeAdmin(admin.ModelAdmin):
    list_display = ("id", "session", "title", "severity")
    list_filter = ("severity", "session")


@admin.register(SimulationLongTermPoint)
class SimulationLongTermPointAdmin(admin.ModelAdmin):
    list_display = ("id", "session", "index", "value")
    list_filter = ("session",)


@admin.register(SimulationRiskAlert)
class SimulationRiskAlertAdmin(admin.ModelAdmin):
    list_display = ("id", "session", "level", "message", "created_at")
    list_filter = ("level", "session")
