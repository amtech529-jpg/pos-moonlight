from django.urls import path
from . import views

app_name = 'purchases'

urlpatterns = [
    path('', views.purchase_list, name='list_create'),
    path('<uuid:pk>/', views.purchase_detail, name='detail'),
]
