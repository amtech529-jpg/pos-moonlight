from django.urls import path
from .views import DataExportView, DataImportView, DataTemplateView

urlpatterns = [
    path('export/<str:model_name>/', DataExportView.as_view(), name='data-export'),
    path('import/<str:model_name>/', DataImportView.as_view(), name='data-import'),
    path('template/<str:model_name>/', DataTemplateView.as_view(), name='data-template'),
]
