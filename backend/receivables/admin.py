from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import Receivable
from django.db import models


@admin.register(Receivable)
class ReceivableAdmin(admin.ModelAdmin):
    """Admin configuration for Receivable model"""
    
    list_display = (
        'debtor_name', 
        'debtor_phone', 
        'amount_given', 
        'amount_returned', 
        'balance_remaining', 
        'date_lent', 
        'expected_return_date', 
        'status_display', 
        'is_active', 
        'created_by'
    )
    
    list_filter = (
        'is_active',
        'date_lent',
        'expected_return_date',
        'created_at',
        'created_by',
    )
    
    search_fields = (
        'debtor_name',
        'debtor_phone',
        'reason_or_item',
        'notes',
    )
    
    readonly_fields = (
        'id',
        'balance_remaining',
        'created_at',
        'updated_at',
        'created_by',
        'is_overdue',
        'days_overdue',
        'is_fully_paid',
        'is_partially_paid',
    )
    
    fieldsets = (
        ('Basic Information', {
            'fields': (
                'debtor_name',
                'debtor_phone',
                'reason_or_item',
                'notes',
            )
        }),
        ('Financial Details', {
            'fields': (
                'amount_given',
                'amount_returned',
                'balance_remaining',
            )
        }),
        ('Dates', {
            'fields': (
                'date_lent',
                'expected_return_date',
            )
        }),
        ('Status & Relations', {
            'fields': (
                'is_active',
                'related_sale',
            )
        }),
        ('System Information', {
            'fields': (
                'id',
                'created_by',
                'created_at',
                'updated_at',
            ),
            'classes': ('collapse',)
        }),
        ('Computed Fields', {
            'fields': (
                'is_overdue',
                'days_overdue',
                'is_fully_paid',
                'is_partially_paid',
            ),
            'classes': ('collapse',)
        }),
    )
    
    list_per_page = 25
    
    ordering = ('-date_lent', '-created_at')
    
    def status_display(self, obj):
        """Display status with color coding"""
        if obj.is_fully_paid():
            return format_html(
                '<span style="color: green; font-weight: bold;">✓ Fully Paid</span>'
            )
        elif obj.is_overdue():
            return format_html(
                '<span style="color: red; font-weight: bold;">⚠ Overdue ({days} days)</span>',
                days=obj.days_overdue()
            )
        elif obj.is_partially_paid():
            return format_html(
                '<span style="color: orange; font-weight: bold;">↻ Partially Paid</span>'
            )
        else:
            return format_html(
                '<span style="color: blue; font-weight: bold;">⏳ Unpaid</span>'
            )
    
    status_display.short_description = 'Status'
    
    def get_queryset(self, request):
        """Custom queryset with computed fields"""
        return super().get_queryset(request).select_related('created_by', 'related_sale')
    
    def save_model(self, request, obj, form, change):
        """Set created_by when creating new receivable"""
        if not change:  # New object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)
    
    def has_delete_permission(self, request, obj=None):
        """Only superusers can delete"""
        return request.user.is_superuser
    
    def get_readonly_fields(self, request, obj=None):
        """Make certain fields readonly based on user permissions"""
        readonly_fields = list(super().get_readonly_fields(request, obj))
        
        # Regular users can't modify financial amounts after creation
        if obj and not request.user.is_superuser:
            readonly_fields.extend(['amount_given', 'amount_returned'])
        
        return readonly_fields
    
    def get_list_display(self, request):
        """Customize list display based on user permissions"""
        list_display = list(super().get_list_display(request))
        
        # Hide sensitive fields for non-superusers
        if not request.user.is_superuser:
            if 'created_by' in list_display:
                list_display.remove('created_by')
        
        return list_display
    
    def get_actions(self, request):
        """Customize available actions"""
        actions = super().get_actions(request)
        
        # Add custom actions
        if 'delete_selected' in actions and not request.user.is_superuser:
            del actions['delete_selected']
        
        return actions
    
    # Custom admin actions
    actions = ['mark_as_paid', 'mark_as_overdue', 'export_receivables']
    
    def mark_as_paid(self, request, queryset):
        """Mark selected receivables as fully paid"""
        updated = queryset.update(
            amount_returned=models.F('amount_given'),
            balance_remaining=0
        )
        self.message_user(
            request,
            f'Successfully marked {updated} receivable(s) as fully paid.'
        )
    
    mark_as_paid.short_description = "Mark selected receivables as fully paid"
    
    def mark_as_overdue(self, request, queryset):
        """Mark selected receivables as overdue (set expected return date to yesterday)"""
        from datetime import date, timedelta
        yesterday = date.today() - timedelta(days=1)
        updated = queryset.update(expected_return_date=yesterday)
        self.message_user(
            request,
            f'Successfully marked {updated} receivable(s) as overdue.'
        )
    
    mark_as_overdue.short_description = "Mark selected receivables as overdue"
    
    def export_receivables(self, request, queryset):
        """Export selected receivables to CSV"""
        import csv
        from django.http import HttpResponse
        
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="receivables_export.csv"'
        
        writer = csv.writer(response)
        writer.writerow([
            'Debtor Name', 'Phone', 'Amount Given', 'Amount Returned', 
            'Balance Remaining', 'Date Lent', 'Expected Return Date',
            'Reason/Item', 'Status', 'Created Date'
        ])
        
        for receivable in queryset:
            writer.writerow([
                receivable.debtor_name,
                receivable.debtor_phone,
                receivable.amount_given,
                receivable.amount_returned,
                receivable.balance_remaining,
                receivable.date_lent,
                receivable.expected_return_date or 'Not Set',
                receivable.reason_or_item,
                'Fully Paid' if receivable.is_fully_paid() else 'Outstanding',
                receivable.created_at.strftime('%Y-%m-%d')
            ])
        
        return response
    
    export_receivables.short_description = "Export selected receivables to CSV"
