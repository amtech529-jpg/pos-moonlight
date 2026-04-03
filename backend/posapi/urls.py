from django.urls import path, include
from . import views

# URL patterns for the posapi app
urlpatterns = [
    # Authentication endpoints
    path('auth/register/', views.register_user, name='register'),
    path('auth/login/', views.login_user, name='login'),
    path('auth/logout/', views.logout_user, name='logout'),
    
    # User profile endpoints
    path('auth/profile/', views.get_user_profile, name='user-profile'),
    path('auth/profile/update/', views.update_user_profile, name='update-profile'),
    path('auth/change-password/', views.change_password, name='change-password'),
    
    # User Management endpoints
    path('users/', views.manage_users, name='manage-users'),
    path('users/<int:pk>/', views.user_detail, name='user-detail'),
    
    # Role Management endpoints
    path('roles/', views.manage_roles, name='manage-roles'),
    path('roles/<int:role_id>/permissions/', views.update_role_permissions, name='update-role-permissions'),
]
