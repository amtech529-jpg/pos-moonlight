from django.contrib import admin
from django.utils.html import format_html
from django.db.models import Sum, Count
from django.utils import timezone
from django.contrib.auth import get_user_model
from .models import Expense

User = get_user_model()


class ExpenseAmountRangeFilter(admin.SimpleListFilter):
    """Custom filter for expense amount ranges"""
    title = 'Amount Range'
    parameter_name = 'amount_range'

    def lookups(self, request, model_admin):
        return (
            ('0-1000', '0 - 1,000 PKR'),
            ('1000-5000', '1,000 - 5,000 PKR'),
            ('5000-10000', '5,000 - 10,000 PKR'),
            ('10000-25000', '10,000 - 25,000 PKR'),
            ('25000-50000', '25,000 - 50,000 PKR'),
            ('50000-100000', '50,000 - 100,000 PKR'),
            ('100000+', '100,000+ PKR'),
        )

    def queryset(self, request, queryset):
        if self.value() == '0-1000':
            return queryset.filter(amount__lt=1000)
        elif self.value() == '1000-5000':
            return queryset.filter(amount__gte=1000, amount__lt=5000)
        elif self.value() == '5000-10000':
            return queryset.filter(amount__gte=5000, amount__lt=10000)
        elif self.value() == '10000-25000':
            return queryset.filter(amount__gte=10000, amount__lt=25000)
        elif self.value() == '25000-50000':
            return queryset.filter(amount__gte=25000, amount__lt=50000)
        elif self.value() == '50000-100000':
            return queryset.filter(amount__gte=50000, amount__lt=100000)
        elif self.value() == '100000+':
            return queryset.filter(amount__gte=100000)


@admin.register(Expense)
class ExpenseAdmin(admin.ModelAdmin):
    """Custom Admin for Expense model"""
    
    list_display = [
        'expense_summary_display', 'formatted_amount_display', 'withdrawal_by_display',
        'category', 'date', 'time', 'created_by_display', 'expense_age_display', 'is_active'
    ]
    
    list_filter = [
        'is_active', 
        'withdrawal_by', 
        'category', 
        'date', 
        'created_at',
        ExpenseAmountRangeFilter,
        ('category', admin.filters.EmptyFieldListFilter),
        ('notes', admin.filters.EmptyFieldListFilter)
    ]
    
    search_fields = ['expense', 'description', 'category', 'notes', 'created_by__full_name']
    
    ordering = ['-date', '-time']
    
    date_hierarchy = 'date'
    
    readonly_fields = [
        'id', 'created_at', 'updated_at', 'formatted_amount', 'withdrawal_initials',
        'expense_summary', 'expense_age_days'
    ]
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('expense', 'description', 'amount', 'formatted_amount')
        }),
        ('Authorization & Timing', {
            'fields': ('withdrawal_by', 'withdrawal_initials', 'date', 'time')
        }),
        ('Categorization', {
            'fields': ('category', 'notes'),
            'classes': ('collapse',)
        }),
        ('System Information', {
            'fields': ('id', 'created_by', 'is_active', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
        ('Computed Properties', {
            'fields': ('expense_summary', 'expense_age_days'),
            'classes': ('collapse',)
        })
    )
    
    list_per_page = 25
    list_max_show_all = 100
    
    actions = ['mark_as_inactive', 'mark_as_active', 'export_selected_expenses']
    
    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('created_by')
    
    def expense_summary_display(self, obj):
        """Display expense summary with truncation"""
        summary = obj.expense
        if len(summary) > 40:
            summary = summary[:37] + "..."
        return format_html(
            '<strong>{}</strong><br><small style="color: #666;">{}</small>',
            summary,
            obj.description[:50] + "..." if len(obj.description) > 50 else obj.description
        )
    expense_summary_display.short_description = 'Expense Details'
    
    def formatted_amount_display(self, obj):
        """Display formatted amount with color coding"""
        amount = obj.amount
        color = '#e74c3c' if amount > 10000 else '#27ae60' if amount < 1000 else '#f39c12'
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            color,
            obj.formatted_amount
        )
    formatted_amount_display.short_description = 'Amount'
    formatted_amount_display.admin_order_field = 'amount'
    
    def withdrawal_by_display(self, obj):
        """Display withdrawal authority with initials"""
        return format_html(
            '{}<br><small style="color: #666;">Initials: {}</small>',
            obj.withdrawal_by,
            obj.withdrawal_initials
        )
    withdrawal_by_display.short_description = 'Authorized By'
    withdrawal_by_display.admin_order_field = 'withdrawal_by'
    
    def created_by_display(self, obj):
        """Display created by user"""
        return format_html(
            '<span title="{}">{}</span>',
            obj.created_by.email,
            obj.created_by.full_name
        )
    created_by_display.short_description = 'Recorded By'
    created_by_display.admin_order_field = 'created_by__full_name'
    
    def expense_age_display(self, obj):
        """Display expense age with color coding"""
        age = obj.expense_age_days
        if age == 0:
            color = '#27ae60'
            text = 'Today'
        elif age == 1:
            color = '#f39c12'
            text = 'Yesterday'
        elif age <= 7:
            color = '#f39c12'
            text = f'{age} days ago'
        elif age <= 30:
            color = '#e67e22'
            text = f'{age} days ago'
        else:
            color = '#e74c3c'
            text = f'{age} days ago'
        
        return format_html(
            '<span style="color: {};">{}</span>',
            color,
            text
        )
    expense_age_display.short_description = 'Age'
    expense_age_display.admin_order_field = 'date'
    
    def mark_as_inactive(self, request, queryset):
        """Mark selected expenses as inactive"""
        updated = queryset.update(is_active=False)
        self.message_user(
            request,
            f'{updated} expense(s) were successfully marked as inactive.'
        )
    mark_as_inactive.short_description = 'Mark selected expenses as inactive'
    
    def mark_as_active(self, request, queryset):
        """Mark selected expenses as active"""
        updated = queryset.update(is_active=True)
        self.message_user(
            request,
            f'{updated} expense(s) were successfully marked as active.'
        )
    mark_as_active.short_description = 'Mark selected expenses as active'
    
    def export_selected_expenses(self, request, queryset):
        """Export selected expenses to CSV"""
        import csv
        from django.http import HttpResponse
        
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="expenses_export.csv"'
        
        writer = csv.writer(response)
        writer.writerow([
            'ID', 'Expense', 'Description', 'Amount', 'Withdrawal By',
            'Date', 'Time', 'Category', 'Notes', 'Created By', 'Created At'
        ])
        
        for expense in queryset:
            writer.writerow([
                str(expense.id),
                expense.expense,
                expense.description,
                str(expense.amount),
                expense.withdrawal_by,
                expense.date.strftime('%Y-%m-%d'),
                expense.time.strftime('%H:%M:%S'),
                expense.category or '',
                expense.notes or '',
                expense.created_by.full_name,
                expense.created_at.strftime('%Y-%m-%d %H:%M:%S')
            ])
        
        self.message_user(
            request,
            f'{queryset.count()} expense(s) exported successfully.'
        )
        
        return response
    export_selected_expenses.short_description = 'Export selected expenses to CSV'
    
    def changelist_view(self, request, extra_context=None):
        """Add statistics to changelist view"""
        extra_context = extra_context or {}
        
        # Get statistics for active expenses
        active_expenses = Expense.objects.filter(is_active=True)
        total_amount = active_expenses.aggregate(total=Sum('amount'))['total'] or 0
        total_count = active_expenses.count()
        
        # Statistics by withdrawal authority
        authority_stats = {}
        for choice in Expense.WITHDRAWAL_CHOICES:
            authority = choice[0]
            auth_expenses = active_expenses.filter(withdrawal_by=authority)
            auth_total = auth_expenses.aggregate(total=Sum('amount'))['total'] or 0
            auth_count = auth_expenses.count()
            authority_stats[authority] = {
                'total': auth_total,
                'count': auth_count,
                'formatted_total': f"PKR {auth_total:,.2f}"
            }
        
        # Recent expenses (last 30 days)
        thirty_days_ago = timezone.now().date() - timezone.timedelta(days=30)
        recent_expenses = active_expenses.filter(date__gte=thirty_days_ago)
        recent_total = recent_expenses.aggregate(total=Sum('amount'))['total'] or 0
        recent_count = recent_expenses.count()
        
        extra_context.update({
            'total_amount': total_amount,
            'formatted_total': f"PKR {total_amount:,.2f}",
            'total_count': total_count,
            'authority_stats': authority_stats,
            'recent_total': recent_total,
            'formatted_recent_total': f"PKR {recent_total:,.2f}",
            'recent_count': recent_count
        })
        
        return super().changelist_view(request, extra_context=extra_context)
    
    def save_model(self, request, obj, form, change):
        """Set created_by to current user when creating new expense"""
        if not change:  # Creating new object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)
    
    def has_delete_permission(self, request, obj=None):
        """Only allow superusers to hard delete expenses"""
        return request.user.is_superuser
    
    def get_form(self, request, obj=None, **kwargs):
        """Customize form based on user permissions"""
        form = super().get_form(request, obj, **kwargs)
        
        # If not superuser, hide created_by field in add form
        if not request.user.is_superuser and not obj:
            if 'created_by' in form.base_fields:
                del form.base_fields['created_by']
        
        return form
    