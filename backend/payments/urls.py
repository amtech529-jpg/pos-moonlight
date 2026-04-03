from django.urls import path
from . import views

app_name = 'payments'

urlpatterns = [
    # Function-based view endpoints
    path('', views.list_payments, name='list_payments'),
    path('create/', views.create_payment, name='create_payment'),
    path('<uuid:payment_id>/', views.get_payment, name='get_payment'),
    path('<uuid:payment_id>/update/', views.update_payment, name='update_payment'),
    
    # Hard delete (permanent deletion)
    path('<uuid:payment_id>/delete/', views.delete_payment, name='delete_payment'),
    
    # Soft delete (alternative - sets is_active=False)
    path('<uuid:payment_id>/soft-delete/', views.soft_delete_payment, name='soft_delete_payment'),
    path('<uuid:payment_id>/restore/', views.restore_payment, name='restore_payment'),
    
    # Additional payment-specific endpoints
    path('statistics/', views.get_payment_statistics, name='get_payment_statistics'),
    path('<uuid:payment_id>/mark-final/', views.mark_as_final_payment, name='mark_as_final_payment'),
    
    # Search and filtering endpoints
    path('search/', views.search_payments, name='search_payments'),
    path('by-labor/<uuid:labor_id>/', views.get_payments_by_labor, name='get_payments_by_labor'),
    path('by-vendor/<uuid:vendor_id>/', views.get_payments_by_vendor, name='get_payments_by_vendor'),
    path('by-order/<uuid:order_id>/', views.get_payments_by_order, name='get_payments_by_order'),
    path('by-sale/<uuid:sale_id>/', views.get_payments_by_sale, name='get_payments_by_sale'),
    path('by-date-range/', views.get_payments_by_date_range, name='get_payments_by_date_range'),
    path('by-payment-method/<str:method>/', views.get_payments_by_method, name='get_payments_by_method'),
    path('with-receipts/', views.get_payments_with_receipts, name='get_payments_with_receipts'),
    path('without-receipts/', views.get_payments_without_receipts, name='get_payments_without_receipts'),
    path('recent/', views.get_recent_payments, name='get_recent_payments'),
    path('today/', views.get_today_payments, name='get_today_payments'),
    path('this-month/', views.get_this_month_payments, name='get_this_month_payments'),
    path('this-year/', views.get_this_year_payments, name='get_this_year_payments'),
    
    # Payment processing endpoints
    path('process/', views.process_payment, name='process_payment'),
    path('split/', views.process_split_payment, name='process_split_payment'),
]
