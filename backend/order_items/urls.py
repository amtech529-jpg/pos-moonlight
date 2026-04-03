from django.urls import path
from . import views

app_name = 'order_items'

urlpatterns = [
    # Core CRUD operations
    path('', views.list_order_items, name='list_order_items'),
    path('create/', views.create_order_item, name='create_order_item'),
    path('<uuid:order_item_id>/', views.get_order_item, name='get_order_item'),
    path('<uuid:order_item_id>/update/', views.update_order_item, name='update_order_item'),
    
    # Hard delete (permanent deletion)
    path('<uuid:order_item_id>/delete/', views.delete_order_item, name='delete_order_item'),
    
    # Soft delete operations
    path('<uuid:order_item_id>/soft-delete/', views.soft_delete_order_item, name='soft_delete_order_item'),
    path('<uuid:order_item_id>/restore/', views.restore_order_item, name='restore_order_item'),
    
    # Search and filtering
    path('search/', views.search_order_items, name='search_order_items'),
    path('order/<uuid:order_id>/', views.order_items_by_order, name='order_items_by_order'),
    path('product/<uuid:product_id>/', views.order_items_by_product, name='order_items_by_product'),
    
    # Specialized views
    path('customized/', views.items_with_customization, name='items_with_customization'),
    
    # Statistics and analytics
    path('statistics/', views.order_item_statistics, name='order_item_statistics'),
    
    # Quantity management
    path('<uuid:order_item_id>/quantity/', views.update_order_item_quantity, name='update_order_item_quantity'),
    path('bulk-update/', views.bulk_update_order_items, name='bulk_update_order_items'),
    
    # Order item operations
    path('<uuid:order_item_id>/duplicate/', views.duplicate_order_item, name='duplicate_order_item'),
]
