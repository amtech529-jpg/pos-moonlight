from django.urls import path, include
from . import views

app_name = 'sales'

urlpatterns = [
    # Sales endpoints
    path('', views.list_sales, name='list_sales'),
    path('create/', views.create_sale, name='create_sale'),
    path('<uuid:sale_id>/', views.get_sale, name='get_sale'),
    path('<uuid:sale_id>/update/', views.update_sale, name='update_sale'),
    path('<uuid:sale_id>/delete/', views.delete_sale, name='delete_sale'),
    path('<uuid:sale_id>/add-payment/', views.add_payment, name='add_payment'),
    path('<uuid:sale_id>/update-status/', views.update_status, name='update_status'),
    path('<uuid:sale_id>/print-receipt/', views.generate_sale_receipt_pdf, name='generate_sale_receipt_pdf'), # ✅ Added this line
    path('<uuid:sale_id>/thermal-print/', views.generate_sale_thermal_print, name='generate_sale_thermal_print'), # ✅ Added thermal print

    # Bulk operations
    path('bulk-action/', views.bulk_action_sales, name='bulk_action_sales'),

    # Customer sales history
    path('by-customer/<uuid:customer_id>/', views.customer_sales_history, name='customer_sales_history'),

    # Sales analytics
    path('statistics/', views.sales_statistics, name='sales_statistics'),

    # Order conversion
    path('create-from-order/', views.create_from_order, name='create_from_order'),

    # Sale items endpoints
    path('items/', views.list_sale_items, name='list_sale_items'),
    path('items/create/', views.create_sale_item, name='create_sale_item'),
    path('items/<uuid:item_id>/update/', views.update_sale_item, name='update_sale_item'),
    path('items/<uuid:item_id>/delete/', views.delete_sale_item, name='delete_sale_item'),

    # Invoice management endpoints
    path('invoices/', views.list_invoices, name='list_invoices'),
    path('invoices/create/', views.create_invoice, name='create_invoice'),
    path('invoices/<uuid:invoice_id>/', views.get_invoice, name='get_invoice'),
    path('invoices/<uuid:invoice_id>/update/', views.update_invoice, name='update_invoice'),
    path('invoices/<uuid:invoice_id>/delete/', views.delete_invoice, name='delete_invoice'),
    path('invoices/<uuid:invoice_id>/generate-pdf/', views.generate_invoice_pdf, name='generate_invoice_pdf'),
    path('invoices/<uuid:invoice_id>/thermal-print/', views.generate_invoice_thermal_print, name='generate_invoice_thermal_print'),

    # Invoice generation & payment endpoints
    path('invoices/generate-from-order/', views.generate_invoice_from_order, name='generate_invoice_from_order'),
    path('invoices/<uuid:invoice_id>/apply-payment/', views.apply_invoice_payment, name='apply_invoice_payment'),
    path('invoices/<uuid:invoice_id>/write-off/', views.write_off_invoice, name='write_off_invoice'),
    path('invoices/ledger/', views.invoice_ledger, name='invoice_ledger'),

    # Receipt management endpoints
    path('receipts/', views.list_receipts, name='list_receipts'),
    path('receipts/create/', views.create_receipt, name='create_receipt'),
    path('receipts/create-simple/', views.create_simple_receipt, name='create_simple_receipt'),
    path('receipts/<uuid:receipt_id>/', views.get_receipt, name='get_receipt'),
    path('receipts/<uuid:receipt_id>/update/', views.update_receipt, name='update_receipt'),
    path('receipts/<uuid:receipt_id>/generate-pdf/', views.generate_receipt_pdf, name='generate_receipt_pdf'),

    # Return system endpoints
    path('returns/', include('sales.return_urls')),
]