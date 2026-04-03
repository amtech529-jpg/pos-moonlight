from django.urls import path
from . import views

app_name = 'analytics'

urlpatterns = [
    # Dashboard analytics
    path('dashboard/', views.dashboard_analytics, name='dashboard'),
    
    # Business metrics
    path('business-metrics/', views.business_metrics, name='business_metrics'),
    # path('business-metrics/<uuid:metric_id>/', views.business_metric_detail, name='business_metric_detail'),
    
    # # Customer insights
    # path('customer-insights/', views.customer_insights, name='customer_insights'),
    # path('customer-insights/<uuid:insight_id>/', views.customer_insight_detail, name='customer_insight_detail'),
    
    # # Product performance
    # path('product-performance/', views.product_performance, name='product_performance'),
    # path('product-performance/<uuid:performance_id>/', views.product_performance_detail, name='product_performance_detail'),
    
    # Real-time analytics
    path('realtime/', views.realtime_analytics, name='realtime'),
    path('reminders/', views.reminders, name='reminders'),
    
    # Reports
    path('reports/top-customers/', views.top_customers, name='top_customers'),
    path('reports/top-products/', views.top_products, name='top_products'),
    path('reports/revenue/', views.revenue_report, name='revenue_report'),
    path('reports/monthly-revenue/', views.monthly_revenue_report, name='monthly_revenue_report'),
    path('reports/business-performance/', views.business_performance, name='business_performance'),
    path('reports/tool-usage/', views.tool_usage_report, name='tool_usage_report'),
    
    # # Export analytics
    # path('export/', views.export_analytics, name='export'),
]

