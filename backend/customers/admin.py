from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from django.db.models import Count
from .models import Customer


@admin.register(Customer)
class CustomerAdmin(admin.ModelAdmin):
    list_display = (
        'display_name_formatted',
        'phone_formatted',
        'email_formatted',
        'customer_type_badge',
        'status_badge',
        'city',
        'country',
        'country',
        'country',
        'verification_status',
        'is_active',
        'created_at'
    )
    
    list_filter = (
        'is_active',
        'status',
        'customer_type',
        'phone_verified',
        'email_verified',
        'city',
        'created_at',
        'last_order_date',
    )
    
    search_fields = (
        'name',
        'phone',
        'email',
        'business_name',
        'city',
        'address',
    )
    
    readonly_fields = (
        'id',
        'created_at',
        'updated_at',
        'created_by',
        'customer_age_display',
        'initials_display',
        'last_activity_display',
    )
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('id', 'name', 'phone', 'email')
        }),
        ('Contact Details', {
            'fields': ('address', 'city', 'country')
        }),
        ('Customer Classification', {
            'fields': ('customer_type', 'status', 'business_name', 'tax_number')
        }),
        ('Verification Status', {
            'fields': ('phone_verified', 'email_verified')
        }),
        ('Additional Information', {
            'fields': ('notes',)
        }),
        ('Activity Tracking', {
            'fields': ('last_order_date', 'last_contact_date', 'last_activity_display'),
            'classes': ('collapse',)
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at', 'created_by', 'customer_age_display', 'initials_display'),
            'classes': ('collapse',)
        }),
    )
    
    list_per_page = 25
    date_hierarchy = 'created_at'
    ordering = ('-created_at', 'name')
    
    actions = [
        'mark_as_active',
        'mark_as_inactive',
        'mark_phone_verified',
        'mark_email_verified',
        'update_to_regular_status',
        'update_to_vip_status',
        'export_customer_list',
    ]

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('created_by')

    def display_name_formatted(self, obj):
        """Display formatted customer name with type indicator"""
        if obj.customer_type == 'BUSINESS' and obj.business_name:
            return format_html(
                '<strong>{}</strong><br><small style="color: #666;">{}</small>',
                obj.business_name,
                obj.name
            )
        return format_html('<strong>{}</strong>', obj.name)
    display_name_formatted.short_description = 'Customer'
    display_name_formatted.admin_order_field = 'name'

    def phone_formatted(self, obj):
        """Display formatted phone with country and verification status"""
        verified_icon = '✓' if obj.phone_verified else '✗'
        color = '#28a745' if obj.phone_verified else '#dc3545'
        
        # Show country info for non-Pakistani numbers
        country_info = ""
        if not obj.is_pakistani_customer:
            country_info = f" <small style='color: #666;'>({obj.formatted_country_phone})</small>"
        
        return format_html(
            '{}{} <span style="color: {};">{}</span>',
            obj.phone,
            country_info,
            color,
            verified_icon
        )
    phone_formatted.short_description = 'Phone'
    phone_formatted.admin_order_field = 'phone'

    def email_formatted(self, obj):
        """Display formatted email with verification status"""
        if not obj.email:
            return format_html('<span style="color: #6c757d;">No email</span>')
        
        verified_icon = '✓' if obj.email_verified else '✗'
        color = '#28a745' if obj.email_verified else '#dc3545'
        
        return format_html(
            '{} <span style="color: {};">{}</span>',
            obj.email,
            color,
            verified_icon
        )
    email_formatted.short_description = 'Email'
    email_formatted.admin_order_field = 'email'

    def customer_type_badge(self, obj):
        """Display customer type with color coding"""
        colors = {
            'INDIVIDUAL': '#17a2b8',  # Info blue
            'BUSINESS': '#28a745',    # Success green
        }
        
        color = colors.get(obj.customer_type, '#6c757d')
        
        return format_html(
            '<span style="background-color: {}; color: white; padding: 2px 6px; '
            'border-radius: 3px; font-size: 10px; font-weight: bold;">{}</span>',
            color,
            obj.get_customer_type_display()
        )
    customer_type_badge.short_description = 'Type'
    customer_type_badge.admin_order_field = 'customer_type'

    def status_badge(self, obj):
        """Display customer status with color coding"""
        colors = {
            'NEW': '#007bff',      # Primary blue
            'REGULAR': '#28a745',  # Success green
            'VIP': '#ffc107',      # Warning yellow
            'INACTIVE': '#6c757d', # Secondary gray
        }
        
        color = colors.get(obj.status, '#6c757d')
        
        return format_html(
            '<span style="background-color: {}; color: {}; padding: 2px 8px; '
            'border-radius: 4px; font-size: 11px; font-weight: bold;">{}</span>',
            color,
            'black' if obj.status == 'VIP' else 'white',
            obj.get_status_display()
        )
    status_badge.short_description = 'Status'
    status_badge.admin_order_field = 'status'

    def verification_status(self, obj):
        """Display verification status"""
        phone_icon = '📱✓' if obj.phone_verified else '📱✗'
        email_icon = '📧✓' if obj.email_verified else '📧✗'
        
        phone_color = '#28a745' if obj.phone_verified else '#dc3545'
        email_color = '#28a745' if obj.email_verified else '#dc3545'
        
        return format_html(
            '<span style="color: {};">{}</span> '
            '<span style="color: {};">{}</span>',
            phone_color, phone_icon,
            email_color, email_icon if obj.email else '📧-'
        )
    verification_status.short_description = 'Verified'

    def customer_age_display(self, obj):
        """Display customer age in days"""
        return f"{obj.customer_age_days} days"
    customer_age_display.short_description = 'Customer Age'

    def initials_display(self, obj):
        """Display customer initials"""
        return obj.get_initials()
    initials_display.short_description = 'Initials'

    def last_activity_display(self, obj):
        """Display last activity information"""
        if obj.last_order_date:
            return format_html(
                'Last order: <strong>{}</strong>',
                obj.last_order_date.strftime('%Y-%m-%d')
            )
        elif obj.is_new_customer:
            return format_html('<span style="color: #007bff;">New customer</span>')
        else:
            return format_html('<span style="color: #6c757d;">No orders yet</span>')
    last_activity_display.short_description = 'Last Activity'

    def save_model(self, request, obj, form, change):
        """Set created_by when creating new customer"""
        if not change:  # Creating new customer
            obj.created_by = request.user
        super().save_model(request, obj, form, change)

    # Custom admin actions
    def mark_as_active(self, request, queryset):
        """Mark selected customers as active"""
        updated = queryset.update(is_active=True)
        self.message_user(
            request,
            f'{updated} customers were successfully marked as active.'
        )
    mark_as_active.short_description = 'Mark selected customers as active'

    def mark_as_inactive(self, request, queryset):
        """Mark selected customers as inactive"""
        updated = queryset.update(is_active=False)
        self.message_user(
            request,
            f'{updated} customers were successfully marked as inactive.'
        )
    mark_as_inactive.short_description = 'Mark selected customers as inactive'

    def mark_phone_verified(self, request, queryset):
        """Mark phone numbers as verified"""
        updated = queryset.update(phone_verified=True)
        self.message_user(
            request,
            f'{updated} customer phone numbers were marked as verified.'
        )
    mark_phone_verified.short_description = 'Mark phone numbers as verified'

    def mark_email_verified(self, request, queryset):
        """Mark emails as verified"""
        updated = queryset.filter(email__isnull=False).exclude(email='').update(email_verified=True)
        self.message_user(
            request,
            f'{updated} customer emails were marked as verified.'
        )
    mark_email_verified.short_description = 'Mark emails as verified'

    def update_to_regular_status(self, request, queryset):
        """Update customer status to regular"""
        updated = queryset.update(status='REGULAR')
        self.message_user(
            request,
            f'{updated} customers were updated to Regular status.'
        )
    update_to_regular_status.short_description = 'Update to Regular status'

    def update_to_vip_status(self, request, queryset):
        """Update customer status to VIP"""
        updated = queryset.update(status='VIP')
        self.message_user(
            request,
            f'{updated} customers were updated to VIP status.'
        )
    update_to_vip_status.short_description = 'Update to VIP status'

    def export_customer_list(self, request, queryset):
        """Show customer count for export"""
        count = queryset.count()
        customer_types = queryset.values('customer_type').annotate(
            count=Count('id')
        ).order_by('customer_type')
        
        type_breakdown = ', '.join([
            f"{item['customer_type']}: {item['count']}" 
            for item in customer_types
        ])
        
        self.message_user(
            request,
            f'Selected {count} customers for export. Breakdown: {type_breakdown}'
        )
    export_customer_list.short_description = 'Show export summary'

    def changelist_view(self, request, extra_context=None):
        """Add extra context to changelist view"""
        extra_context = extra_context or {}
        
        # Get customer statistics
        stats = Customer.get_statistics()
        
        extra_context.update({
            'total_customers': stats['total_customers'],
            'new_customers_count': stats['new_customers_this_month'],
            'recent_customers_count': stats['recent_customers_this_week'],
            'inactive_customers_count': stats['inactive_customers'],
            'phone_verification_rate': stats['verification_stats']['phone_verification_rate'],
            'email_verification_rate': stats['verification_stats']['email_verification_rate'],
        })
        
        return super().changelist_view(request, extra_context)


# Optional: Custom admin site title and header
admin.site.site_header = "Customer Management System"
admin.site.site_title = "Customer Admin"
admin.site.index_title = "Welcome to Customer Management System"
