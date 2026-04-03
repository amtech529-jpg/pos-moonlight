from django.urls import path
from . import views
from . import views_ledger

app_name = 'vendors'

urlpatterns = [
    #ledger api
    path('<uuid:vendor_id>/ledger/', views_ledger.vendor_ledger, name='vendor_ledger'),
     
    # Basic CRUD operations
    path('', views.list_vendors, name='list'),
    path('create/', views.create_vendor, name='create'),
    path('<uuid:vendor_id>/', views.get_vendor, name='detail'),
    path('<uuid:vendor_id>/update/', views.update_vendor, name='update'),
    path('<uuid:vendor_id>/delete/', views.delete_vendor, name='delete'),
    
    # Soft delete operations
    path('<uuid:vendor_id>/soft-delete/', views.soft_delete_vendor, name='soft_delete'),
    path('<uuid:vendor_id>/restore/', views.restore_vendor, name='restore'),
    
    # Search and filtering
    path('search/', views.search_vendors, name='search'),
    path('city/<str:city_name>/', views.vendors_by_city, name='by_city'),
    path('area/<str:area_name>/', views.vendors_by_area, name='by_area'),
    
    # Time-based filtering
    path('new/', views.new_vendors, name='new'),
    path('recent/', views.recent_vendors, name='recent'),
    
    # Statistics and analytics
    path('statistics/', views.vendor_statistics, name='statistics'),
    
    # Contact management
    path('<uuid:vendor_id>/contact/update/', views.update_vendor_contact, name='update_contact'),
    
    # Bulk operations
    path('bulk-actions/', views.bulk_vendor_actions, name='bulk_actions'),
    
    # Utility operations
    path('<uuid:vendor_id>/duplicate/', views.duplicate_vendor, name='duplicate'),
    
    # Payment integration (placeholder)
    path('<uuid:vendor_id>/payments/', views.vendor_payments, name='payments'),
    # Vendor purchases
    path('<uuid:vendor_id>/purchases/', views.vendor_purchases, name='vendor_purchases'),
    # Vendor transactions
    path('<uuid:vendor_id>/transactions/', views.vendor_transactions, name='transactions'),

]
