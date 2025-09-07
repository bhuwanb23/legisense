from django.urls import path

from .views import parse_pdf_view, list_parsed_docs_view, parsed_doc_detail_view

urlpatterns = [
    path('parse-pdf/', parse_pdf_view, name='parse_pdf'),
    path('documents/', list_parsed_docs_view, name='parsed_docs_list'),
    path('documents/<int:pk>/', parsed_doc_detail_view, name='parsed_doc_detail'),
]


