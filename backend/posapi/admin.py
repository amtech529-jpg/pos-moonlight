from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    """Custom User Admin"""
    
    list_display = ('email', 'full_name', 'is_active', 'is_superuser', 'date_joined', 'agreed_to_terms')
    list_filter = ('is_active', 'is_superuser', 'agreed_to_terms', 'date_joined')
    search_fields = ('email', 'full_name')
    ordering = ('-date_joined',)
    
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Personal info', {'fields': ('full_name', 'agreed_to_terms')}),
        ('Permissions', {
            'fields': ('is_active', 'is_superuser', 'groups', 'user_permissions'),
        }),
        ('Important dates', {'fields': ('last_login', 'date_joined')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'full_name', 'password1', 'password2', 'agreed_to_terms'),
        }),
    )
    
    readonly_fields = ('date_joined', 'last_login')
    filter_horizontal = ('groups', 'user_permissions')
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.select_related()
        