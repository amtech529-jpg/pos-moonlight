from django.urls import path
from . import views
from . import views_ledger
app_name = 'customers'

urlpatterns = [
    # Customer Ledger API
    path('<uuid:customer_id>/ledger/', views_ledger.customer_ledger, name='customer_ledger'),


    # Core CRUD operations
    path('', views.list_customers, name='list_customers'),
    path('create/', views.create_customer, name='create_customer'),
    path('<uuid:customer_id>/', views.get_customer, name='get_customer'),
    path('<uuid:customer_id>/update/', views.update_customer, name='update_customer'),
    
    # Hard delete (permanent deletion)
    path('<uuid:customer_id>/delete/', views.delete_customer, name='delete_customer'),
    
    # Soft delete operations
    path('<uuid:customer_id>/soft-delete/', views.soft_delete_customer, name='soft_delete_customer'),
    path('<uuid:customer_id>/restore/', views.restore_customer, name='restore_customer'),
    
    # Search and filtering
    path('search/', views.search_customers, name='search_customers'),
    path('status/<str:status_name>/', views.customers_by_status, name='customers_by_status'),
    path('type/<str:type_name>/', views.customers_by_type, name='customers_by_type'),
    path('city/<str:city_name>/', views.customers_by_city, name='customers_by_city'),
    path('country/<str:country_name>/', views.customers_by_country, name='customers_by_country'),
    
    # International customer segments
    path('pakistani/', views.pakistani_customers, name='pakistani_customers'),
    path('international/', views.international_customers, name='international_customers'),
    
    # Customer segments
    path('new/', views.new_customers, name='new_customers'),
    path('recent/', views.recent_customers, name='recent_customers'),
    
    # Statistics and analytics
    path('statistics/', views.customer_statistics, name='customer_statistics'),
    
    # Contact management
    path('<uuid:customer_id>/contact/', views.update_customer_contact, name='update_customer_contact'),
    path('<uuid:customer_id>/verify/', views.verify_customer_contact, name='verify_customer_contact'),
    
    # Activity tracking
    path('<uuid:customer_id>/activity/', views.update_customer_activity, name='update_customer_activity'),
    
    # Bulk operations
    path('bulk-actions/', views.bulk_customer_actions, name='bulk_customer_actions'),
    
    # Customer operations
    path('<uuid:customer_id>/duplicate/', views.duplicate_customer, name='duplicate_customer'),
    
    # Integration endpoints (placeholders for future)
    path('<uuid:customer_id>/orders/', views.customer_orders, name='customer_orders'),
    path('<uuid:customer_id>/sales/', views.customer_sales, name='customer_sales'),
]