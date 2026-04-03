from django.urls import path
from . import views

app_name = 'advance_payments'

urlpatterns = [
    # Basic CRUD operations
    path('', views.list_advance_payments, name='list'),
    path('create/', views.create_advance_payment, name='create'),
    path('<uuid:payment_id>/', views.get_advance_payment, name='detail'),
    path('<uuid:payment_id>/update/', views.update_advance_payment, name='update'),
    path('<uuid:payment_id>/delete/', views.delete_advance_payment, name='delete'),
    
    # Soft delete operations
    path('<uuid:payment_id>/soft-delete/', views.soft_delete_advance_payment, name='soft_delete'),
    path('<uuid:payment_id>/restore/', views.restore_advance_payment, name='restore'),
    
    # Search and filtering
    path('search/', views.search_advance_payments, name='search'),
    path('labor/<uuid:labor_id>/', views.payments_by_labor, name='by_labor'),
    path('date-range/', views.payments_by_date_range, name='by_date_range'),
    
    # Time-based filtering
    path('today/', views.today_payments, name='today'),
    path('recent/', views.recent_payments, name='recent'),
    
    # Statistics and analytics
    path('statistics/', views.advance_payment_statistics, name='statistics'),
    path('monthly-report/', views.monthly_report, name='monthly_report'),
    path('labor-advance-report/', views.labor_advance_report, name='labor_advance_report'),
    
    # Bulk operations
    path('bulk-actions/', views.bulk_advance_payment_actions, name='bulk_actions'),
    
    # Utility operations
    path('with-receipts/', views.payments_with_receipts, name='with_receipts'),
    path('without-receipts/', views.payments_without_receipts, name='without_receipts'),
    path('labor/<uuid:labor_id>/summary/', views.labor_advance_summary, name='labor_summary'),
]
