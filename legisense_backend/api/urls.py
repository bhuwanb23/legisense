from django.urls import path

from .views import parse_pdf_view

urlpatterns = [
    path('parse-pdf/', parse_pdf_view, name='parse_pdf'),
]


