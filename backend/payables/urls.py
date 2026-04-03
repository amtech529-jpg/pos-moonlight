from django.urls import path
from . import views
from . import views_advanced

app_name = 'payables'

urlpatterns = [
    # Basic CRUD operations (views.py)
    path('', views.list_payables, name='list'),
    path('create/', views.create_payable, name='create'),
    path('<uuid:payable_id>/', views.get_payable, name='detail'),
    path('<uuid:payable_id>/update/', views.update_payable, name='update'),
    path('<uuid:payable_id>/delete/', views.delete_payable, name='delete'),
    
    # Soft delete operations (views.py)
    path('<uuid:payable_id>/soft-delete/', views.soft_delete_payable, name='soft_delete'),
    path('<uuid:payable_id>/restore/', views.restore_payable, name='restore'),
    
    # Payment operations (views.py)
    path('<uuid:payable_id>/payment/', views.add_payment, name='add_payment'),
    
    # Contact management (views.py)
    path('<uuid:payable_id>/contact/update/', views.update_payable_contact, name='update_contact'),
    
    # Advanced features and analytics (views_advanced.py)
    path('search/', views_advanced.search_payables, name='search'),
    path('overdue/', views_advanced.overdue_payables, name='overdue'),
    path('urgent/', views_advanced.urgent_payables, name='urgent'),
    path('due-soon/', views_advanced.due_soon_payables, name='due_soon'),
    path('recent/', views_advanced.recent_payables, name='recent'),
    path('creditor/<str:creditor_name>/', views_advanced.payables_by_creditor, name='by_creditor'),
    path('vendor/<uuid:vendor_id>/', views_advanced.payables_by_vendor, name='by_vendor'),
    
    # Statistics and analytics (views_advanced.py)
    path('statistics/', views_advanced.payable_statistics, name='statistics'),
    path('payment-schedule/', views_advanced.payment_schedule, name='payment_schedule'),
    path('creditor-summary/', views_advanced.creditor_summary, name='creditor_summary'),
    
    # Bulk operations (views_advanced.py)
    path('bulk-actions/', views_advanced.bulk_payable_actions, name='bulk_actions'),
    
    # Partner rental payable generation (views.py)
    path('generate-partner-payables/', views.generate_partner_payables_view, name='generate_partner_payables'),
]