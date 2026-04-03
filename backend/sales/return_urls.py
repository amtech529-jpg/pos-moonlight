from django.urls import path
from . import return_views
app_name = 'returns'

urlpatterns = [
    # Return management
    path('', return_views.ReturnListView.as_view(), name='return_list'),
    path('<uuid:pk>/', return_views.ReturnDetailView.as_view(), name='return_detail'),
    path('<uuid:pk>/items/', return_views.ReturnItemListView.as_view(), name='return_items'),
    path('<uuid:pk>/approve/', return_views.ReturnApprovalView.as_view(), name='return_approval'),
    path('<uuid:pk>/process/', return_views.ReturnProcessingView.as_view(), name='return_processing'),
    
    # Refund management
    path('refunds/', return_views.RefundListView.as_view(), name='refund_list'),
    path('refunds/<uuid:pk>/', return_views.RefundDetailView.as_view(), name='refund_detail'),
    path('refunds/<uuid:pk>/process/', return_views.RefundProcessingView.as_view(), name='refund_processing'),
    path('refunds/<uuid:pk>/fail/', return_views.RefundFailureView.as_view(), name='refund_failure'),
    path('refunds/<uuid:pk>/cancel/', return_views.RefundCancellationView.as_view(), name='refund_cancellation'),
    
    # Statistics and reports
    path('statistics/', return_views.return_statistics, name='return_statistics'),
    path('customer/<uuid:customer_id>/history/', return_views.customer_return_history, name='customer_return_history'),
    path('sale/<uuid:sale_id>/returns/', return_views.sale_return_details, name='sale_return_details'),
]
