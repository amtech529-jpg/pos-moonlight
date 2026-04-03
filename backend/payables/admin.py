from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.db.models import Count, Sum
from django.utils import timezone
from decimal import Decimal
from .models import Payable, PayablePayment


class PayablePaymentInline(admin.TabularInline):
    """Inline for payable payments"""
    model = PayablePayment
    extra = 0
    readonly_fields = ('id', 'created_at', 'created_by')
    fields = ('amount', 'payment_date', 'notes', 'created_at', 'created_by')
    
    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(Payable)
class PayableAdmin(admin.ModelAdmin):
    list_display = (
        'creditor_name_formatted',
        'amount_display',
        'balance_display',
        'due_date_display',
        'status_badge',
        'priority_badge',
        'is_fully_paid',
        'created_at'
    )
    
    list_filter = (
        'status',
        'priority',
        'is_fully_paid',
        'is_active',
        'expected_repayment_date',
        'date_borrowed',
        'created_at',
    )
    
    search_fields = (
        'creditor_name',
        'creditor_phone',
        'creditor_email',
        'reason_or_item',
        'notes',
        'vendor__name',
        'vendor__business_name',
    )
    
    readonly_fields = (
        'id',
        'balance_remaining',
        'is_fully_paid',
        'payment_percentage',
        'created_at',
        'updated_at',
        'created_by',
    )
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('id', 'creditor_name', 'creditor_phone', 'creditor_email', 'vendor')
        }),
        ('Amount Details', {
            'fields': (
                'amount_borrowed', 'amount_paid', 'balance_remaining',
                'payment_percentage', 'is_fully_paid'
            )
        }),
        ('Description & Dates', {
            'fields': (
                'reason_or_item', 'date_borrowed', 'expected_repayment_date'
            )
        }),
        ('Status & Priority', {
            'fields': ('status', 'priority')
        }),
        ('Additional Information', {
            'fields': ('notes', 'is_active'),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at', 'created_by'),
            'classes': ('collapse',)
        }),
    )
    
    inlines = [PayablePaymentInline]
    
    list_per_page = 25
    date_hierarchy = 'expected_repayment_date'
    ordering = ('-expected_repayment_date', '-created_at')
    
    actions = [
        'mark_as_urgent',
        'mark_as_high_priority',
        'mark_as_medium_priority',
        'mark_as_low_priority',
        'mark_as_active',
        'mark_as_inactive',
    ]

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('created_by', 'vendor')

    def creditor_name_formatted(self, obj):
        """Display formatted creditor name with vendor info"""
        if obj.vendor:
            return format_html(
                '<strong>{}</strong><br>'
                '<small style="color: #666;">🏢 {}</small>',
                obj.creditor_name,
                obj.vendor.business_name
            )
        return format_html('<strong>{}</strong>', obj.creditor_name)
    creditor_name_formatted.short_description = 'Creditor'
    creditor_name_formatted.admin_order_field = 'creditor_name'

    def status_badge(self, obj):
        """Display status badge with color"""
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; '
            'border-radius: 3px; font-size: 11px; font-weight: bold;">{}</span>',
            obj.status_color, obj.get_status_display()
        )
    status_badge.short_description = 'Status'
    status_badge.admin_order_field = 'status'

    def priority_badge(self, obj):
        """Display priority badge with color"""
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; '
            'border-radius: 3px; font-size: 11px; font-weight: bold;">{}</span>',
            obj.priority_color, obj.get_priority_display()
        )
    priority_badge.short_description = 'Priority'
    priority_badge.admin_order_field = 'priority'

    def amount_display(self, obj):
        """Display amount borrowed with formatting"""
        amount_str = '₹{:,.2f}'.format(float(obj.amount_borrowed))
        return format_html(
            '<strong>{}</strong><br>'
            '<small style="color: #666;">Borrowed</small>',
            amount_str
        )
    amount_display.short_description = 'Amount Borrowed'
    amount_display.admin_order_field = 'amount_borrowed'

    def balance_display(self, obj):
        """Display remaining balance with color coding"""
        if obj.is_fully_paid:
            color = '#28a745'  # Green
            text = '✅ Paid'
        else:
            balance_str = '₹{:,.2f}'.format(float(obj.balance_remaining))
            if obj.balance_remaining > obj.amount_borrowed * Decimal('0.8'):
                color = '#dc3545'  # Red - most amount remaining
            elif obj.balance_remaining > obj.amount_borrowed * Decimal('0.5'):
                color = '#fd7e14'  # Orange - moderate amount remaining
            else:
                color = '#ffc107'  # Yellow - small amount remaining
            text = balance_str
        
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span><br>'
            '<small style="color: #666;">Remaining</small>',
            color, text
        )
    balance_display.short_description = 'Balance'
    balance_display.admin_order_field = 'balance_remaining'

    def due_date_display(self, obj):
        """Display due date with urgency indicators"""
        if not obj.expected_repayment_date:
            return '—'
        
        # Calculate days manually to avoid model property f-strings
        from datetime import date
        today = date.today()
        days_until_due = (obj.expected_repayment_date - today).days
        is_overdue = today > obj.expected_repayment_date
        
        if is_overdue:
            color = '#dc3545'  # Red
            icon = '🚨'
            days_text = '{} days overdue'.format(abs(days_until_due))
        elif days_until_due <= 3:
            color = '#fd7e14'  # Orange
            icon = '⚠️'
            days_text = '{} days left'.format(days_until_due)
        elif days_until_due <= 7:
            color = '#ffc107'  # Yellow
            icon = '📅'
            days_text = '{} days left'.format(days_until_due)
        else:
            color = '#28a745'  # Green
            icon = '📅'
            days_text = '{} days left'.format(days_until_due)
        
        date_str = obj.expected_repayment_date.strftime('%Y-%m-%d')
        
        return format_html(
            '{} <span style="color: {};">{}</span><br>'
            '<small>{}</small>',
            icon, color, date_str, days_text
        )
    due_date_display.short_description = 'Due Date'
    due_date_display.admin_order_field = 'expected_repayment_date'

    # Custom admin actions
    def mark_as_urgent(self, request, queryset):
        """Mark selected payables as urgent priority"""
        updated = queryset.update(priority='URGENT')
        self.message_user(
            request,
            '{} payables were successfully marked as urgent priority.'.format(updated)
        )
    mark_as_urgent.short_description = 'Mark as URGENT priority'

    def mark_as_high_priority(self, request, queryset):
        """Mark selected payables as high priority"""
        updated = queryset.update(priority='HIGH')
        self.message_user(
            request,
            '{} payables were successfully marked as high priority.'.format(updated)
        )
    mark_as_high_priority.short_description = 'Mark as HIGH priority'

    def mark_as_medium_priority(self, request, queryset):
        """Mark selected payables as medium priority"""
        updated = queryset.update(priority='MEDIUM')
        self.message_user(
            request,
            '{} payables were successfully marked as medium priority.'.format(updated)
        )
    mark_as_medium_priority.short_description = 'Mark as MEDIUM priority'

    def mark_as_low_priority(self, request, queryset):
        """Mark selected payables as low priority"""
        updated = queryset.update(priority='LOW')
        self.message_user(
            request,
            '{} payables were successfully marked as low priority.'.format(updated)
        )
    mark_as_low_priority.short_description = 'Mark as LOW priority'

    def mark_as_active(self, request, queryset):
        """Mark selected payables as active"""
        updated = queryset.update(is_active=True)
        self.message_user(
            request,
            '{} payables were successfully marked as active.'.format(updated)
        )
    mark_as_active.short_description = 'Mark selected payables as active'

    def mark_as_inactive(self, request, queryset):
        """Mark selected payables as inactive"""
        updated = queryset.update(is_active=False)
        self.message_user(
            request,
            '{} payables were successfully marked as inactive.'.format(updated)
        )
    mark_as_inactive.short_description = 'Mark selected payables as inactive'

    def save_model(self, request, obj, form, change):
        """Set created_by when creating new payable"""
        if not change:
            obj.created_by = request.user
        super().save_model(request, obj, form, change)


@admin.register(PayablePayment)
class PayablePaymentAdmin(admin.ModelAdmin):
    list_display = (
        'payable',
        'amount',
        'payment_date',
        'created_at',
        'created_by'
    )
    
    list_filter = (
        'payment_date',
        'created_at',
        'payable__status',
        'payable__priority',
    )
    
    search_fields = (
        'payable__creditor_name',
        'notes',
        'payable__reason_or_item',
    )
    
    readonly_fields = (
        'id',
        'created_at',
        'created_by',
    )
    
    list_per_page = 30
    date_hierarchy = 'payment_date'
    ordering = ('-payment_date', '-created_at')

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('payable', 'created_by')

    def save_model(self, request, obj, form, change):
        """Set created_by when creating new payment"""
        if not change:
            obj.created_by = request.user
        super().save_model(request, obj, form, change)


# Custom admin site configuration
admin.site.site_header = "Payables Management System"
admin.site.site_title = "Payables Admin"
admin.site.index_title = "Welcome to Payables Management System"
