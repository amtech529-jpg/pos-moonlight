from django.urls import path
from . import views

app_name = 'returns'

urlpatterns = [
    # List & Create
    path('', views.list_returns, name='list'),
    path('create/', views.create_return, name='create'),
    
    # Detail & Tally
    path('<uuid:return_id>/', views.get_return, name='detail'),
    path('<uuid:return_id>/tally/', views.tally_return, name='tally'),
    
    # Stock restoration
    path('<uuid:return_id>/restore-stock/', views.restore_stock, name='restore_stock'),
    
    # Damage recovery
    path('<uuid:return_id>/damage-recovery/', views.add_damage_recovery, name='add_damage_recovery'),
    
    # Delete
    path('<uuid:return_id>/delete/', views.delete_return, name='delete'),
    
    # Statistics
    path('statistics/', views.return_statistics, name='statistics'),
]
