from django.urls import path

from .views import (
    parse_pdf_view,
    list_parsed_docs_view,
    parsed_doc_detail_view,
    parsed_doc_analysis_view,
    parsed_doc_analyze_view,
    parsed_doc_simulate_view,
    import_simulation_view,
    simulation_detail_view,
)

urlpatterns = [
    path('parse-pdf/', parse_pdf_view, name='parse_pdf'),
    path('documents/', list_parsed_docs_view, name='parsed_docs_list'),
    path('documents/<int:pk>/', parsed_doc_detail_view, name='parsed_doc_detail'),
    path('documents/<int:pk>/analysis/', parsed_doc_analysis_view, name='parsed_doc_analysis'),
    path('documents/<int:pk>/analyze/', parsed_doc_analyze_view, name='parsed_doc_analyze'),
    path('documents/<int:pk>/simulate/', parsed_doc_simulate_view, name='parsed_doc_simulate'),
    path('simulations/import/', import_simulation_view, name='import_simulation'),
    path('simulations/<int:pk>/', simulation_detail_view, name='simulation_detail'),
]


