from django.contrib import admin
from .models import Category


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    """Django admin configuration for Category model"""
    
    list_display = [
        'name', 
        'description', 
        'is_active', 
        'created_by', 
        'created_at', 
        'updated_at'
    ]
    
    list_filter = [
        'is_active', 
        'created_at', 
        'updated_at',
        'created_by'
    ]
    
    search_fields = [
        'name', 
        'description',
        'created_by__email',
        'created_by__full_name'
    ]
    
    readonly_fields = [
        'id', 
        'created_at', 
        'updated_at'
    ]
    
    fieldsets = (
        ('Category Information', {
            'fields': ('name', 'description', 'is_active')
        }),
        ('Metadata', {
            'fields': ('id', 'created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    ordering = ['name']
    
    def get_queryset(self, request):
        """Include related created_by user data"""
        return super().get_queryset(request).select_related('created_by')
    
    def save_model(self, request, obj, form, change):
        """Set created_by to current user if creating new category"""
        if not change:  # Creating new object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)
    
    actions = ['make_active', 'make_inactive']
    
    def make_active(self, request, queryset):
        """Admin action to activate categories"""
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} categories were successfully activated.')
    make_active.short_description = "Mark selected categories as active"
    
    def make_inactive(self, request, queryset):
        """Admin action to deactivate categories"""
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} categories were successfully deactivated.')
    make_inactive.short_description = "Mark selected categories as inactive"    
