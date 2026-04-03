from django.urls import path
from . import views

# URL patterns for the Zakat module
urlpatterns = [
    # Main CRUD endpoints
    path('', views.zakat_list_create, name='zakat-list-create'),
    path('<uuid:zakat_id>/', views.zakat_detail, name='zakat-detail'),
    path('<uuid:zakat_id>/update/', views.zakat_update, name='zakat-update'),
    path('<uuid:zakat_id>/delete/', views.zakat_delete, name='zakat-delete'),
   
    # Filtering and search endpoints
    path('by-beneficiary/<str:beneficiary_name>/', views.zakat_by_beneficiary, name='zakat-by-beneficiary'),
    path('by-authority/<str:authority>/', views.zakat_by_authority, name='zakat-by-authority'),
    path('by-date-range/', views.zakat_by_date_range, name='zakat-by-date-range'),
   
    # Analytics and reporting endpoints
    path('statistics/', views.zakat_statistics, name='zakat-statistics'),
    path('monthly-summary/', views.monthly_summary, name='zakat-monthly-summary'),
    path('beneficiary-report/', views.beneficiary_report, name='beneficiary-report'),
    path('recent/', views.recent_zakat, name='recent-zakat'),
   
    # Bulk operations
    path('bulk-actions/', views.bulk_actions, name='zakat-bulk-actions'),
]
