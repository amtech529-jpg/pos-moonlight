from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from django.db.models import Count
from .models import Vendor


@admin.register(Vendor)
class VendorAdmin(admin.ModelAdmin):
    list_display = (
        'display_name_formatted',
        'business_name_formatted',
        'cnic',
        'phone_formatted',
        'location_formatted',
        'is_new_vendor_badge',
        'is_active',
        'created_at'
    )
    
    list_filter = (
        'is_active',
        'city',
        'area',
        'created_at',
    )
    
    search_fields = (
        'name',
        'business_name',
        'cnic',
        'phone',
        'city',
        'area',
    )
    
    readonly_fields = (
        'id',
        'created_at',
        'updated_at',
        'created_by',
        'vendor_age_display',
        'initials_display',
        'formatted_phone_display',
        'full_address_display',
    )
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('id', 'name', 'business_name', 'cnic')
        }),
        ('Contact Details', {
            'fields': ('phone', 'city', 'area', 'formatted_phone_display', 'full_address_display')
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at', 'created_by', 'vendor_age_display', 'initials_display'),
            'classes': ('collapse',)
        }),
    )
    
    list_per_page = 25
    date_hierarchy = 'created_at'
    ordering = ('-created_at', 'name')
    
    actions = [
        'mark_as_active',
        'mark_as_inactive',
        'export_vendor_list',
    ]

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('created_by')

    def display_name_formatted(self, obj):
        """Display formatted vendor name"""
        return format_html('<strong>{}</strong>', obj.name)
    display_name_formatted.short_description = 'Vendor Name'
    display_name_formatted.admin_order_field = 'name'

    def business_name_formatted(self, obj):
        """Display formatted business name"""
        return format_html('<em>{}</em>', obj.business_name)
    business_name_formatted.short_description = 'Business Name'
    business_name_formatted.admin_order_field = 'business_name'

    def phone_formatted(self, obj):
        """Display formatted phone number"""
        country_info = ""
        if obj.phone_country_code:
            country_info = f" <small style='color: #666;'>({obj.phone_country_code})</small>"
        
        return format_html(
            '{}{} ',
            obj.phone,
            country_info
        )
    phone_formatted.short_description = 'Phone'
    phone_formatted.admin_order_field = 'phone'

    def location_formatted(self, obj):
        """Display formatted location"""
        return format_html(
            '<strong>{}</strong><br><small style="color: #666;">{}</small>',
            obj.city,
            obj.area
        )
    location_formatted.short_description = 'Location'
    location_formatted.admin_order_field = 'city'

    def is_new_vendor_badge(self, obj):
        """Display new vendor badge"""
        if not obj.created_at:
            return format_html(
                '<span style="background-color: #17a2b8; color: white; padding: 2px 6px; '
                'border-radius: 3px; font-size: 10px; font-weight: bold;">UNSAVED</span>'
            )
        elif obj.is_new_vendor:
            return format_html(
                '<span style="background-color: #007bff; color: white; padding: 2px 6px; '
                'border-radius: 3px; font-size: 10px; font-weight: bold;">NEW</span>'
            )
        elif obj.is_recent_vendor:
            return format_html(
                '<span style="background-color: #28a745; color: white; padding: 2px 6px; '
                'border-radius: 3px; font-size: 10px; font-weight: bold;">RECENT</span>'
            )
        return format_html('<span style="color: #6c757d;">—</span>')
    is_new_vendor_badge.short_description = 'Status'

    def vendor_age_display(self, obj):
        """Display vendor age in days"""
        if not obj.created_at:
            return "New vendor"
        return f"{obj.vendor_age_days} days"
    vendor_age_display.short_description = 'Vendor Age'

    def initials_display(self, obj):
        """Display vendor initials"""
        return obj.get_initials()
    initials_display.short_description = 'Initials'

    def formatted_phone_display(self, obj):
        """Display formatted phone with country code"""
        return obj.formatted_phone
    formatted_phone_display.short_description = 'Formatted Phone'

    def full_address_display(self, obj):
        """Display complete address"""
        return obj.full_address
    full_address_display.short_description = 'Complete Address'

    def save_model(self, request, obj, form, change):
        """Set created_by when creating new vendor"""
        if not change:  # Creating new vendor
            obj.created_by = request.user
        super().save_model(request, obj, form, change)

    # Custom admin actions
    def mark_as_active(self, request, queryset):
        """Mark selected vendors as active"""
        updated = queryset.update(is_active=True)
        self.message_user(
            request,
            f'{updated} vendors were successfully marked as active.'
        )
    mark_as_active.short_description = 'Mark selected vendors as active'

    def mark_as_inactive(self, request, queryset):
        """Mark selected vendors as inactive"""
        updated = queryset.update(is_active=False)
        self.message_user(
            request,
            f'{updated} vendors were successfully marked as inactive.'
        )
    mark_as_inactive.short_description = 'Mark selected vendors as inactive'

    def export_vendor_list(self, request, queryset):
        """Show vendor count for export"""
        count = queryset.count()
        cities = queryset.values('city').annotate(
            count=Count('id')
        ).order_by('city')
        
        city_breakdown = ', '.join([
            f"{item['city']}: {item['count']}" 
            for item in cities
        ])
        
        self.message_user(
            request,
            f'Selected {count} vendors for export. Cities: {city_breakdown}'
        )
    export_vendor_list.short_description = 'Show export summary'

    def changelist_view(self, request, extra_context=None):
        """Add extra context to changelist view"""
        extra_context = extra_context or {}
        
        # Get vendor statistics
        stats = Vendor.get_statistics()
        
        extra_context.update({
            'total_vendors': stats['total_vendors'],
            'active_vendors': stats['active_vendors'],
            'inactive_vendors': stats['inactive_vendors'],
            'new_vendors_count': stats['new_vendors_this_month'],
            'recent_vendors_count': stats['recent_vendors_this_week'],
            'top_cities': stats['top_cities'][:5],
        })
        
        return super().changelist_view(request, extra_context)


# Optional: Custom admin site title and header for vendors
admin.site.site_header = "Vendor Management System"
admin.site.site_title = "Vendor Admin"
admin.site.index_title = "Welcome to Vendor Management System"
