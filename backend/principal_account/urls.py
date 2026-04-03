from django.urls import path
from . import views

app_name = 'principal_account'

urlpatterns = [
    # Principal Account transactions
    path('', views.principal_account_list_create, name='list_create'),
    path('<uuid:transaction_id>/', views.principal_account_detail, name='detail'),
    
    # Balance and statistics
    path('balance/', views.principal_account_balance, name='balance'),
    path('statistics/', views.principal_account_statistics, name='statistics'),
    
    # Module integration endpoint
    path('create-from-module/', views.create_transaction_from_module, name='create_from_module'),
]

