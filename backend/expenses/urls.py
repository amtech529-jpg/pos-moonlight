from django.urls import path
from . import views

# URL patterns for the expenses module
urlpatterns = [
    # Main CRUD endpoints
    path('', views.expenses_list_create, name='expenses-list-create'),
    path('<uuid:expense_id>/', views.expense_detail, name='expense-detail'),
    path('<uuid:expense_id>/update/', views.expense_update, name='expense-update'),
    path('<uuid:expense_id>/delete/', views.expense_delete, name='expense-delete'),
    
    # Filtering and search endpoints
    path('by-authority/<str:authority>/', views.expenses_by_authority, name='expenses-by-authority'),
    path('by-category/<str:category>/', views.expenses_by_category, name='expenses-by-category'),
    path('by-date-range/', views.expenses_by_date_range, name='expenses-by-date-range'),
    
    # Analytics and reporting endpoints
    path('statistics/', views.expense_statistics, name='expense-statistics'),
    path('monthly-summary/', views.expense_monthly_summary, name='expense-monthly-summary'),
    path('recent/', views.recent_expenses, name='recent-expenses'),
]