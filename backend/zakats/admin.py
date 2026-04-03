from django.contrib import admin
from django.utils.html import format_html
from django.db.models import Sum, Count
from django.utils import timezone
from django.contrib.auth import get_user_model
from .models import Zakat

User = get_user_model()


class ZakatAmountRangeFilter(admin.SimpleListFilter):
    """Custom filter for Zakat amount ranges"""
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


@admin.register(Zakat)
class ZakatAdmin(admin.ModelAdmin):
    """Custom Admin for Zakat model"""
    
    list_display = [
        'zakat_summary_display', 'formatted_amount_display', 'authorized_by_display',
        'beneficiary_display', 'date', 'time', 'created_by_display', 'zakat_age_display', 'is_active'
    ]
    
    list_filter = [
        'is_active', 
        'authorized_by', 
        'date', 
        'created_at',
        ZakatAmountRangeFilter,
        ('beneficiary_contact', admin.filters.EmptyFieldListFilter),
        ('notes', admin.filters.EmptyFieldListFilter)
    ]
    
    search_fields = ['name', 'description', 'beneficiary_name', 'beneficiary_contact', 'notes', 'created_by__full_name']
    
    ordering = ['-date', '-time']
    
    date_hierarchy = 'date'
    
    readonly_fields = [
        'id', 'created_at', 'updated_at', 'formatted_amount', 'authorized_initials',
        'zakat_summary', 'zakat_age_days', 'beneficiary_summary'
    ]
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'description', 'amount', 'formatted_amount')
        }),
        ('Authorization & Timing', {
            'fields': ('authorized_by', 'authorized_initials', 'date', 'time')
        }),
        ('Beneficiary Information', {
            'fields': ('beneficiary_name', 'beneficiary_contact', 'beneficiary_summary')
        }),
        ('Additional Notes', {
            'fields': ('notes',),
            'classes': ('collapse',)
        }),
        ('System Information', {
            'fields': ('id', 'created_by', 'is_active', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
        ('Computed Properties', {
            'fields': ('zakat_summary', 'zakat_age_days'),
            'classes': ('collapse',)
        })
    )
    
    list_per_page = 25
    list_max_show_all = 100
    
    actions = ['mark_as_inactive', 'mark_as_active', 'export_selected_zakat']
    
    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('created_by')
    
    def zakat_summary_display(self, obj):
        """Display Zakat summary with truncation"""
        summary = obj.name
        if len(summary) > 40:
            summary = summary[:37] + "..."
        return format_html(
            '<strong>{}</strong><br><small style="color: #666;">{}</small>',
            summary,
            obj.description[:50] + "..." if len(obj.description) > 50 else obj.description
        )
    zakat_summary_display.short_description = 'Zakat Details'
    
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
    
    def authorized_by_display(self, obj):
        """Display authorization authority with initials"""
        return format_html(
            '{}<br><small style="color: #666;">Initials: {}</small>',
            obj.authorized_by,
            obj.authorized_initials
        )
    authorized_by_display.short_description = 'Authorized By'
    authorized_by_display.admin_order_field = 'authorized_by'
    
    def beneficiary_display(self, obj):
        """Display beneficiary with contact if available"""
        return format_html(
            '<strong>{}</strong><br><small style="color: #666;">{}</small>',
            obj.beneficiary_name,
            obj.beneficiary_contact or 'No contact info'
        )
    beneficiary_display.short_description = 'Beneficiary'
    beneficiary_display.admin_order_field = 'beneficiary_name'
    
    def created_by_display(self, obj):
        """Display created by user"""
        return format_html(
            '<span title="{}">{}</span>',
            obj.created_by.email,
            obj.created_by.full_name
        )
    created_by_display.short_description = 'Recorded By'
    created_by_display.admin_order_field = 'created_by__full_name'
    
    def zakat_age_display(self, obj):
        """Display Zakat age with color coding"""
        age = obj.zakat_age_days
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
    zakat_age_display.short_description = 'Age'
    zakat_age_display.admin_order_field = 'date'
    
    def mark_as_inactive(self, request, queryset):
        """Mark selected Zakat entries as inactive"""
        updated = queryset.update(is_active=False)
        self.message_user(
            request,
            f'{updated} Zakat entrie(s) were successfully marked as inactive.'
        )
    mark_as_inactive.short_description = 'Mark selected Zakat entries as inactive'
    
    def mark_as_active(self, request, queryset):
        """Mark selected Zakat entries as active"""
        updated = queryset.update(is_active=True)
        self.message_user(
            request,
            f'{updated} Zakat entrie(s) were successfully marked as active.'
        )
    mark_as_active.short_description = 'Mark selected Zakat entries as active'
    
    def export_selected_zakat(self, request, queryset):
        """Export selected Zakat entries to CSV"""
        import csv
        from django.http import HttpResponse
        
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="zakat_export.csv"'
        
        writer = csv.writer(response)
        writer.writerow([
            'ID', 'Name', 'Description', 'Amount', 'Authorized By',
            'Date', 'Time', 'Beneficiary Name', 'Beneficiary Contact',
            'Notes', 'Created By', 'Created At'
        ])
        
        for zakat in queryset:
            writer.writerow([
                str(zakat.id),
                zakat.name,
                zakat.description,
                str(zakat.amount),
                zakat.authorized_by,
                zakat.date.strftime('%Y-%m-%d'),
                zakat.time.strftime('%H:%M:%S'),
                zakat.beneficiary_name,
                zakat.beneficiary_contact or '',
                zakat.notes or '',
                zakat.created_by.full_name,
                zakat.created_at.strftime('%Y-%m-%d %H:%M:%S')
            ])
        
        self.message_user(
            request,
            f'{queryset.count()} Zakat entrie(s) exported successfully.'
        )
        
        return response
    export_selected_zakat.short_description = 'Export selected Zakat entries to CSV'
    
    def changelist_view(self, request, extra_context=None):
        """Add statistics to changelist view"""
        extra_context = extra_context or {}
        
        # Get statistics for active Zakat entries
        active_zakat = Zakat.objects.filter(is_active=True)
        total_amount = active_zakat.aggregate(total=Sum('amount'))['total'] or 0
        total_count = active_zakat.count()
        
        # Statistics by authorization authority
        authority_stats = {}
        for choice in Zakat.AUTHORIZATION_CHOICES:
            authority = choice[0]
            auth_zakat = active_zakat.filter(authorized_by=authority)
            auth_total = auth_zakat.aggregate(total=Sum('amount'))['total'] or 0
            auth_count = auth_zakat.count()
            authority_stats[authority] = {
                'total': auth_total,
                'count': auth_count,
                'formatted_total': f"PKR {auth_total:,.2f}"
            }
        
        # Recent Zakat entries (last 30 days)
        thirty_days_ago = timezone.now().date() - timezone.timedelta(days=30)
        recent_zakat = active_zakat.filter(date__gte=thirty_days_ago)
        recent_total = recent_zakat.aggregate(total=Sum('amount'))['total'] or 0
        recent_count = recent_zakat.count()
        
        # Top beneficiaries
        top_beneficiaries = active_zakat.values('beneficiary_name').annotate(
            total_amount=Sum('amount'),
            count=Count('id')
        ).order_by('-total_amount')[:5]
        
        extra_context.update({
            'total_amount': total_amount,
            'formatted_total': f"PKR {total_amount:,.2f}",
            'total_count': total_count,
            'authority_stats': authority_stats,
            'recent_total': recent_total,
            'formatted_recent_total': f"PKR {recent_total:,.2f}",
            'recent_count': recent_count,
            'top_beneficiaries': top_beneficiaries
        })
        
        return super().changelist_view(request, extra_context=extra_context)
    
    def save_model(self, request, obj, form, change):
        """Set created_by to current user when creating new Zakat entry"""
        if not change:  # Creating new object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)
    
    def has_delete_permission(self, request, obj=None):
        """Only allow superusers to hard delete Zakat entries"""
        return request.user.is_superuser
    
    def get_form(self, request, obj=None, **kwargs):
        """Customize form based on user permissions"""
        form = super().get_form(request, obj, **kwargs)
        
        # If not superuser, hide created_by field in add form
        if not request.user.is_superuser and not obj:
            if 'created_by' in form.base_fields:
                del form.base_fields['created_by']
        
        return form
    