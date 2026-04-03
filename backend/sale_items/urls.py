from django.urls import path
from . import views

app_name = 'sale_items'

urlpatterns = [
    path('', views.list_sale_items, name='list_sale_items'),
    path('create/', views.create_sale_item, name='create_sale_item'),
    path('<uuid:item_id>/', views.get_sale_item, name='get_sale_item'),
    path('<uuid:item_id>/update/', views.update_sale_item, name='update_sale_item'),
    path('<uuid:item_id>/delete/', views.delete_sale_item, name='delete_sale_item'),
]
