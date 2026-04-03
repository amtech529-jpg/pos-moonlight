from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.views.generic import RedirectView

urlpatterns = [
    # 2. Add this line to redirect the empty Homepage to Admin
    path('', RedirectView.as_view(url='/admin/', permanent=False)),

    path('admin/', admin.site.urls),
    path('api/v1/', include('posapi.urls')),
    path('api/v1/categories/', include('categories.urls')),
    path('api/v1/products/', include('products.urls')),
    path('api/v1/purchases/', include('purchases.urls')),
    path('api/v1/customers/', include('customers.urls')),
    path('api/v1/vendors/', include('vendors.urls')),
    path('api/v1/labors/', include('labors.urls')),
    path('api/v1/advance-payments/', include('advance_payments.urls')),
    path('api/v1/orders/', include('orders.urls')),
    path('api/v1/order-items/', include('order_items.urls')),
    path('api/v1/sales/', include('sales.urls')),
    path('api/v1/sale-items/', include('sale_items.urls')),
    path('api/v1/payables/', include('payables.urls')),
    path('api/v1/zakats/', include('zakats.urls')),
    path('api/v1/payments/', include('payments.urls')),
    path('api/v1/receivables/', include('receivables.urls')),
    path('api/v1/profit-loss/', include('profit_loss.urls')),
    path('api/v1/expenses/', include('expenses.urls')),
    path('api/v1/principal-account/', include('principal_account.urls')),
    path('api/v1/analytics/', include('analytics.urls')),
    path('api/v1/quotations/', include('quotations.urls')),
    path('api/v1/rental-returns/', include('returns.urls')),
    path('api/v1/tax-rates/', include('sales.tax_rates_urls')), # Tax rates are handled in sales app
    path('api/v1/data-management/', include('data_management.urls')),
    path('api/v1/backup/', include('backup.urls')),
]

# Serve media files during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)