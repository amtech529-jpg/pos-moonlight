from django.urls import path
from . import views

urlpatterns = [
    path('', views.list_tax_rates, name='list_tax_rates'),
    path('active/', views.get_active_tax_rates, name='get_active_tax_rates'),
    path('create/', views.create_tax_rate, name='create_tax_rate'),
    path('<uuid:pk>/', views.tax_rate_detail, name='tax_rate_detail'),
]
