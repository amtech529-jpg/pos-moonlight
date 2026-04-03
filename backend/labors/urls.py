from django.urls import path
from . import views

app_name = 'labors'

urlpatterns = [
    # Basic CRUD operations
    path('', views.list_labors, name='list'),
    path('create/', views.create_labor, name='create'),
    path('<uuid:labor_id>/', views.get_labor, name='detail'),
    path('<uuid:labor_id>/update/', views.update_labor, name='update'),
    path('<uuid:labor_id>/delete/', views.delete_labor, name='delete'),
    
    # Soft delete operations
    path('<uuid:labor_id>/soft-delete/', views.soft_delete_labor, name='soft_delete'),
    path('<uuid:labor_id>/restore/', views.restore_labor, name='restore'),
    
    # Search and filtering
    path('search/', views.search_labors, name='search'),
    path('city/<str:city_name>/', views.labors_by_city, name='by_city'),
    path('area/<str:area_name>/', views.labors_by_area, name='by_area'),
    path('designation/<str:designation_name>/', views.labors_by_designation, name='by_designation'),
    path('caste/<str:caste_name>/', views.labors_by_caste, name='by_caste'),
    path('gender/<str:gender>/', views.labors_by_gender, name='by_gender'),
    path('salary-range/', views.labors_by_salary_range, name='by_salary_range'),
    path('age-range/', views.labors_by_age_range, name='by_age_range'),
    
    # Time-based filtering
    path('new/', views.new_labors, name='new'),
    path('recent/', views.recent_labors, name='recent'),
    
    # Statistics and analytics
    path('statistics/', views.labor_statistics, name='statistics'),
    path('salary-report/', views.salary_report, name='salary_report'),
    path('demographics-report/', views.demographics_report, name='demographics_report'),
    path('experience-report/', views.experience_report, name='experience_report'),
    
    # Contact and salary management
    path('<uuid:labor_id>/contact/update/', views.update_labor_contact, name='update_contact'),
    path('<uuid:labor_id>/salary/update/', views.update_labor_salary, name='update_salary'),
    
    # Bulk operations
    path('bulk-actions/', views.bulk_labor_actions, name='bulk_actions'),
    
    # Utility operations
    path('<uuid:labor_id>/duplicate/', views.duplicate_labor, name='duplicate'),
    
    # Payment integration (placeholder)
    # Payment integration (placeholder)
    path('<uuid:labor_id>/payments/', views.labor_payments, name='payments'),

    # Salary Slips
    path('salary-slips/', views.list_salary_slips, name='list_salary_slips'),
    path('salary-slips/generate/', views.generate_salary_slips, name='generate_salary_slips'),
    path('salary-slips/<uuid:slip_id>/status/', views.update_salary_status, name='update_salary_status'),
]