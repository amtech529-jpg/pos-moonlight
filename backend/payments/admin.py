from django.contrib import admin
from .models import Payment


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    """Django admin configuration for Payment model"""
    
    list_display = [
        'id', 
        'labor_name', 
        'vendor', 
        'payer_type',
        'amount_paid', 
        'bonus', 
        'deduction',
        'payment_month', 
        'is_final_payment',
        'payment_method', 
        'date', 
        'time',
        'is_active', 
        'created_by', 
        'created_at'
    ]
    
    list_filter = [
        'payer_type',
        'payment_method',
        'is_final_payment',
        'is_active', 
        'date',
        'payment_month',
        'created_at',
        'created_by'
    ]
    
    search_fields = [
        'labor_name', 
        'labor_phone',
        'labor_role',
        'vendor__business_name',
        'description',
        'created_by__email',
        'created_by__full_name'
    ]
    
    readonly_fields = [
        'id', 
        'created_at', 
        'updated_at',
        'payer_id',
        'labor_name',
        'labor_phone',
        'labor_role'
    ]
    
    fieldsets = (
        ('Payment Information', {
            'fields': (
                'labor', 'vendor', 'order', 'sale',
                'amount_paid', 'bonus', 'deduction',
                'payment_month', 'is_final_payment',
                'payment_method', 'description'
            )
        }),
        ('Date & Time', {
            'fields': ('date', 'time')
        }),
        ('Receipt', {
            'fields': ('receipt_image_path',),
            'classes': ('collapse',)
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('id', 'payer_type', 'payer_id', 'created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    ordering = ['-date', '-time', '-created_at']
    
    list_per_page = 25
    
    def get_queryset(self, request):
        """Include related data for better performance"""
        return super().get_queryset(request).select_related(
            'labor', 'vendor', 'order', 'sale', 'created_by'
        )
    
    def save_model(self, request, obj, form, change):
        """Set created_by to current user if creating new payment"""
        if not change:  # Creating new object
            obj.created_by = request.user
        super().save_model(request, obj, form, change)
    
    actions = ['make_active', 'make_inactive', 'mark_as_final', 'mark_as_partial', 'export_payments_csv']
    
    def make_active(self, request, queryset):
        """Admin action to activate payments"""
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} payments were successfully activated.')
    make_active.short_description = "Mark selected payments as active"
    
    def make_inactive(self, request, queryset):
        """Admin action to deactivate payments"""
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} payments were successfully deactivated.')
    make_inactive.short_description = "Mark selected payments as inactive"
    
    def mark_as_final(self, request, queryset):
        """Admin action to mark payments as final"""
        updated = queryset.update(is_final_payment=True)
        self.message_user(request, f'{updated} payments were marked as final payments.')
    mark_as_final.short_description = "Mark selected payments as final"
    
    def mark_as_partial(self, request, queryset):
        """Admin action to mark payments as partial"""
        updated = queryset.update(is_final_payment=False)
        self.message_user(request, f'{updated} payments were marked as partial payments.')
    mark_as_partial.short_description = "Mark selected payments as partial"
    
    def export_payments_csv(self, request, queryset):
        """Admin action to export selected payments to CSV"""
        import csv
        from django.http import HttpResponse
        from django.utils import timezone
        
        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = f'attachment; filename="payments_export_{timezone.now().strftime("%Y%m%d_%H%M%S")}.csv"'
        
        writer = csv.writer(response)
        writer.writerow([
            'ID', 'Labor Name', 'Vendor', 'Payer Type', 'Amount Paid', 'Bonus', 'Deduction',
            'Payment Month', 'Is Final Payment', 'Payment Method', 'Date', 'Time',
            'Description', 'Status', 'Created By', 'Created At'
        ])
        
        for payment in queryset:
            writer.writerow([
                payment.id,
                payment.labor_name or '',
                payment.vendor.business_name if payment.vendor else '',
                payment.get_payer_type_display(),
                float(payment.amount_paid),
                float(payment.bonus),
                float(payment.deduction),
                payment.payment_month.strftime('%Y-%m-%d') if payment.payment_month else '',
                'Yes' if payment.is_final_payment else 'No',
                payment.get_payment_method_display(),
                payment.date.strftime('%Y-%m-%d') if payment.date else '',
                payment.time.strftime('%H:%M:%S') if payment.time else '',
                payment.description or '',
                'Active' if payment.is_active else 'Inactive',
                payment.created_by.email if payment.created_by else '',
                payment.created_at.strftime('%Y-%m-%d %H:%M:%S') if payment.created_at else ''
            ])
        
        self.message_user(request, f'{queryset.count()} payments exported successfully.')
        return response
    export_payments_csv.short_description = "Export selected payments to CSV"
    
    def get_list_display(self, request):
        """Customize list display based on user permissions"""
        list_display = list(super().get_list_display(request))
        
        # Add computed fields for superusers
        if request.user.is_superuser:
            computed_fields = ['computed_net_amount', 'computed_payment_age', 'computed_has_receipt', 'computed_payment_period']
            for field in computed_fields:
                if field not in list_display:
                    list_display.insert(5, field)
        
        return list_display
    
    def get_fieldsets(self, request, obj=None):
        """Customize fieldsets based on user permissions"""
        fieldsets = list(super().get_fieldsets(request, obj))
        
        # For superusers, we can add computed fields as readonly
        if request.user.is_superuser:
            # Add computed fields (readonly)
            payment_fields = list(fieldsets[0][1]['fields'])
            computed_fields = ['computed_net_amount', 'computed_payment_age', 'computed_has_receipt', 'computed_payment_period']
            for field in computed_fields:
                if field not in payment_fields:
                    payment_fields.insert(5, field)
            fieldsets[0] = ('Payment Information', {'fields': payment_fields})
        
        return fieldsets
    
    def changelist_view(self, request, extra_context=None):
        """Add payment statistics to the changelist view for superusers"""
        if request.user.is_superuser:
            try:
                from .models import Payment
                stats = Payment.get_statistics()
                extra_context = extra_context or {}
                extra_context['payment_stats'] = stats
            except Exception:
                pass
        return super().changelist_view(request, extra_context)
    
    def get_readonly_fields(self, request, obj=None):
        """Add computed fields as readonly for superusers"""
        readonly_fields = list(super().get_readonly_fields(request, obj))
        
        if request.user.is_superuser:
            computed_fields = ['computed_net_amount', 'computed_payment_age', 'computed_has_receipt', 'computed_payment_period']
            for field in computed_fields:
                if field not in readonly_fields:
                    readonly_fields.append(field)
        
        return readonly_fields
    
    def computed_net_amount(self, obj):
        """Display computed net amount for superusers"""
        if obj.pk:  # Only for existing objects
            return f"PKR {obj.net_amount:,.2f}"
        return "N/A (New Payment)"
    computed_net_amount.short_description = "Net Amount (Computed)"
    
    def computed_payment_age(self, obj):
        """Display payment age in days for superusers"""
        if obj.pk and obj.date:
            return f"{obj.payment_age_days} days"
        return "N/A"
    computed_payment_age.short_description = "Payment Age"
    
    def computed_has_receipt(self, obj):
        """Display receipt status for superusers"""
        if obj.pk:
            return "Yes" if obj.has_receipt else "No"
        return "N/A"
    computed_has_receipt.short_description = "Has Receipt"
    
    def computed_payment_period(self, obj):
        """Display payment period in readable format for superusers"""
        if obj.pk and obj.payment_month:
            return obj.payment_period_display
        return "N/A"
    computed_payment_period.short_description = "Payment Period"
