from django.urls import path
from . import views

app_name = 'orders'

urlpatterns = [
    # Core CRUD operations
    path('', views.list_orders, name='list_orders'),
    path('create/', views.create_order, name='create_order'),
    path('<uuid:order_id>/', views.get_order, name='get_order'),
    path('<uuid:order_id>/update/', views.update_order, name='update_order'),
    
    # Hard delete (permanent deletion)
    path('<uuid:order_id>/delete/', views.delete_order, name='delete_order'),
    
    # Soft delete operations
    path('<uuid:order_id>/soft-delete/', views.soft_delete_order, name='soft_delete_order'),
    path('<uuid:order_id>/restore/', views.restore_order, name='restore_order'),
    
    # Search and filtering
    path('search/', views.search_orders, name='search_orders'),
    path('status/<str:status_name>/', views.orders_by_status, name='orders_by_status'),
    path('customer/<uuid:customer_id>/', views.orders_by_customer, name='orders_by_customer'),
    
    # Order status views
    path('pending/', views.pending_orders, name='pending_orders'),
    path('overdue/', views.overdue_orders, name='overdue_orders'),
    path('unpaid/', views.unpaid_orders, name='unpaid_orders'),
    path('recent/', views.recent_orders, name='recent_orders'),
    path('due-today/', views.due_today_orders, name='due_today_orders'),
    
    # Statistics and analytics
    path('statistics/', views.order_statistics, name='order_statistics'),
    
    # Payment management
    path('<uuid:order_id>/payment/', views.add_payment, name='add_payment'),
    
    # Status management
    path('<uuid:order_id>/status/', views.update_order_status, name='update_order_status'),
    path('bulk-actions/', views.bulk_order_actions, name='bulk_order_actions'),
    
    # Order operations
    path('<uuid:order_id>/recalculate/', views.recalculate_order_totals, name='recalculate_order_totals'),
    path('<uuid:order_id>/customer-info/', views.update_customer_info, name='update_customer_info'),
    path('<uuid:order_id>/duplicate/', views.duplicate_order, name='duplicate_order'),
    path('<uuid:order_id>/invoice/', views.generate_invoice, name='generate_invoice'),
]
