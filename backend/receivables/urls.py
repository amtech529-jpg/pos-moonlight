from django.urls import path
from . import views

app_name = 'receivables'

urlpatterns = [
    # Basic CRUD operations
    path('', views.list_receivables, name='list_receivables'),
    path('create/', views.create_receivable, name='create_receivable'),
    path('<uuid:receivable_id>/', views.get_receivable, name='get_receivable'),
    path('<uuid:receivable_id>/update/', views.update_receivable, name='update_receivable'),
    path('<uuid:receivable_id>/delete/', views.delete_receivable, name='delete_receivable'),
    
    # Special operations
    path('<uuid:receivable_id>/record-payment/', views.record_payment, name='record_payment'),
    path('<uuid:receivable_id>/restore/', views.restore_receivable, name='restore_receivable'),
    
    # Summary and search
    path('summary/', views.receivable_summary, name='receivable_summary'),
    path('search/', views.search_receivables, name='search_receivables'),
]
