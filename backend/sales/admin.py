from django.contrib import admin
from django.utils.html import format_html
from django.db.models import Sum, Count
from django.utils import timezone
from decimal import Decimal
from .models import Sales, SaleItem, TaxRate, Return, ReturnItem, Invoice, Receipt, Refund


@admin.register(TaxRate)
class TaxRateAdmin(admin.ModelAdmin):
    """Admin interface for TaxRate model"""
    
    list_display = [
        'name', 'tax_type', 'percentage', 'is_active', 'is_currently_effective',
        'effective_from', 'effective_to', 'created_at'
    ]
    
    list_filter = [
        'tax_type', 'is_active', 'effective_from', 'effective_to', 'created_at'
    ]
    
    search_fields = [
        'name', 'description', 'tax_type'
    ]
    
    readonly_fields = [
        'id', 'created_at', 'updated_at', 'is_currently_effective'
    ]
    
    fieldsets = (
        ('Tax Rate Information', {
            'fields': ('id', 'name', 'tax_type', 'percentage', 'description')
        }),
        ('Status & Effectiveness', {
            'fields': ('is_active', 'effective_from', 'effective_to', 'is_currently_effective')
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    list_per_page = 25
    ordering = ('tax_type', 'effective_from')
    
    def is_currently_effective(self, obj):
        """Display if tax rate is currently effective"""
        if obj.is_currently_effective:
            return format_html(
                '<span style="color: green;">✓ Effective</span>'
            )
        else:
            return format_html(
                '<span style="color: red;">✗ Not Effective</span>'
            )
    is_currently_effective.short_description = 'Currently Effective'
    
    def get_queryset(self, request):
        """Optimize queryset with annotations"""
        return super().get_queryset(request).select_related()


@admin.register(SaleItem)
class SaleItemAdmin(admin.ModelAdmin):
    """Admin interface for SaleItem model"""
    
    list_display = [
        'id', 'product_name', 'sale_invoice', 'quantity', 'unit_price', 
        'item_discount', 'line_total', 'is_active'
    ]
    
    list_filter = [
        'is_active', 'created_at', 'product'
    ]
    
    search_fields = [
        'product_name', 'customization_notes', 'sale__invoice_number'
    ]
    
    readonly_fields = [
        'id', 'created_at', 'updated_at', 'line_total'
    ]
    
    fieldsets = (
        ('Sale Item Information', {
            'fields': ('id', 'sale', 'order_item', 'product')
        }),
        ('Product Details', {
            'fields': ('product_name', 'unit_price', 'quantity', 'item_discount')
        }),
        ('Financial', {
            'fields': ('line_total',)
        }),
        ('Customization', {
            'fields': ('customization_notes',)
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    list_per_page = 25
    ordering = ('-created_at',)
    
    def sale_invoice(self, obj):
        """Display sale invoice number"""
        if obj.sale:
            return format_html(
                '<strong>{}</strong>',
                obj.sale.invoice_number
            )
        return '-'
    sale_invoice.short_description = 'Sale Invoice'
    
    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related(
            'sale', 'product'
        )


@admin.register(Sales)
class SalesAdmin(admin.ModelAdmin):
    """Admin interface for Sales model"""
    
    list_display = [
        'invoice_number', 'customer_name', 'status', 'grand_total', 
        'amount_paid', 'payment_status', 'payment_method', 'date_of_sale', 
        'total_items', 'is_active', 'tax_summary'
    ]
    
    list_filter = [
        'status', 'payment_method', 'is_fully_paid', 'is_active', 
        'date_of_sale', 'created_at'
    ]
    
    search_fields = [
        'invoice_number', 'customer_name', 'customer_phone', 
        'customer_email', 'notes'
    ]
    
    readonly_fields = [
        'id', 'invoice_number', 'created_at', 'updated_at', 
        'subtotal', 'tax_amount', 'grand_total', 'remaining_amount',
        'is_fully_paid', 'total_items', 'sales_age_days',
        'payment_percentage', 'sales_summary', 'authorized_initials',
        'invoice_display', 'payment_status_display', 'tax_breakdown_display',
    ]
    
    fieldsets = (
        ('Sale Information', {
            'fields': ('id', 'invoice_number', 'order_id', 'customer', 'status', 'date_of_sale')
        }),
        ('Customer Details', {
            'fields': ('customer_name', 'customer_phone', 'customer_email'),
            'classes': ('collapse',)
        }),
        ('Financial Details', {
            'fields': ('subtotal', 'overall_discount', 'tax_configuration', 'tax_amount', 'grand_total')
        }),
        ('Payment Information', {
            'fields': ('amount_paid', 'remaining_amount', 'is_fully_paid', 'payment_method', 'split_payment_details')
        }),
        ('Tax Breakdown', {
            'fields': ('tax_breakdown_display',),
            'classes': ('collapse',)
        }),
        ('Additional Information', {
            'fields': ('notes', 'created_by')
        }),
        ('Status & Metadata', {
            'fields': ('is_active', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    list_per_page = 25
    ordering = ('-date_of_sale', '-created_at')
    
    def payment_status(self, obj):
        """Display payment status with color coding"""
        if obj.is_fully_paid:
            return format_html(
                '<span style="color: green; font-weight: bold;">✓ Fully Paid</span>'
            )
        elif obj.amount_paid > 0:
            return format_html(
                '<span style="color: orange; font-weight: bold;">⚠ Partial ({:.1f}%)</span>',
                obj.payment_percentage
            )
        else:
            return format_html(
                '<span style="color: red; font-weight: bold;">✗ Unpaid</span>'
            )
    payment_status.short_description = 'Payment Status'
    
    def tax_summary(self, obj):
        """Display tax summary in list view"""
        if not obj.tax_configuration:
            return "No taxes"
        
        tax_types = list(obj.tax_configuration.keys())
        if len(tax_types) == 1:
            tax_type = tax_types[0]
            tax_data = obj.tax_configuration[tax_type]
            return f"{tax_data.get('name', tax_type)}: {tax_data.get('percentage', 0)}%"
        else:
            return f"Multiple taxes ({len(tax_types)} types)"
    tax_summary.short_description = 'Tax Summary'
    
    def tax_breakdown_display(self, obj):
        """Display detailed tax breakdown"""
        if not obj.tax_configuration:
            return "No taxes applied"
        
        breakdown_html = []
        for tax_type, tax_data in obj.tax_configuration.items():
            name = tax_data.get('name', tax_type)
            percentage = tax_data.get('percentage', 0)
            amount = tax_data.get('amount', 0)
            description = tax_data.get('description', '')
            
            breakdown_html.append(
                f'<div style="margin-bottom: 10px; padding: 8px; border: 1px solid #ddd; border-radius: 4px;">'
                f'<strong>{name}</strong> ({tax_type})<br>'
                f'Rate: {percentage}%<br>'
                f'Amount: PKR {amount:,.2f}<br>'
                f'<em>{description}</em>'
                f'</div>'
            )
        
        return format_html(''.join(breakdown_html))
    tax_breakdown_display.short_description = 'Tax Breakdown'
    
    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related(
            'customer', 'order_id', 'created_by'
        ).prefetch_related('sale_items')
    
    def save_model(self, request, obj, form, change):
        """Custom save method to handle tax calculations"""
        if not change:  # New sale
            obj.created_by = request.user
        
        # Ensure tax configuration is set
        if not obj.tax_configuration:
            obj.tax_configuration = obj.get_default_tax_configuration()
        
        super().save_model(request, obj, form, change)
    
    def get_readonly_fields(self, request, obj=None):
        """Make certain fields readonly based on sale status"""
        readonly_fields = list(super().get_readonly_fields(request, obj))
        
        if obj and obj.status in ['PAID', 'DELIVERED']:
            # Make financial fields readonly for completed sales
            readonly_fields.extend(['subtotal', 'overall_discount', 'tax_configuration'])
        
        return readonly_fields
    
    def has_delete_permission(self, request, obj=None):
        """Prevent deletion of completed sales"""
        if obj and obj.status in ['PAID', 'DELIVERED']:
            return False
        return super().has_delete_permission(request, obj)
    
    def get_actions(self, request):
        """Custom actions for sales"""
        actions = super().get_actions(request)
        
        # Add custom actions
        if 'delete_selected' in actions:
            del actions['delete_selected']
        
        return actions


@admin.register(Return)
class ReturnAdmin(admin.ModelAdmin):
    """Admin interface for Return model"""
    
    list_display = [
        'return_number', 'sale', 'customer', 'reason', 'status', 'return_date', 
        'refund_amount', 'refund_method', 'is_active'
    ]
    
    list_filter = [
        'status', 'reason', 'is_active', 'return_date', 'created_at'
    ]
    
    search_fields = [
        'return_number', 'sale__invoice_number', 'customer__name', 'customer__phone',
        'reason_details', 'notes'
    ]
    
    readonly_fields = [
        'id', 'return_number', 'return_date', 'created_at', 'updated_at'
    ]
    
    fieldsets = (
        ('Return Information', {
            'fields': ('id', 'return_number', 'sale', 'customer', 'reason', 'reason_details')
        }),
        ('Status & Processing', {
            'fields': ('status', 'return_date', 'approved_at', 'processed_at', 'approved_by', 'processed_by')
        }),
        ('Refund Details', {
            'fields': ('refund_amount', 'refund_method'),
            'classes': ('collapse',)
        }),
        ('Notes', {
            'fields': ('notes',)
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    list_per_page = 25
    ordering = ('-return_date', '-created_at')
    
    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related(
            'sale', 'customer', 'approved_by', 'processed_by', 'created_by'
        ).prefetch_related('return_items')
    
    def save_model(self, request, obj, form, change):
        """Custom save method to handle return processing"""
        if not change:  # New return
            obj.created_by = request.user
        
        super().save_model(request, obj, form, change)


@admin.register(ReturnItem)
class ReturnItemAdmin(admin.ModelAdmin):
    """Admin interface for ReturnItem model"""
    
    list_display = [
        'id', 'return_request', 'sale_item', 'quantity_returned', 'return_amount', 
        'return_reason', 'condition', 'is_active'
    ]
    
    list_filter = [
        'condition', 'is_active', 'created_at'
    ]
    
    search_fields = [
        'return_request__return_number', 'sale_item__product_name', 'return_reason'
    ]
    
    readonly_fields = [
        'id', 'created_at', 'updated_at'
    ]
    
    fieldsets = (
        ('Return Item Information', {
            'fields': ('id', 'return_request', 'sale_item')
        }),
        ('Item Details', {
            'fields': ('quantity_returned', 'return_amount', 'return_reason', 'condition')
        }),
        ('Notes', {
            'fields': ('notes',)
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    list_per_page = 25
    ordering = ('-created_at',)
    
    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related(
            'return_request', 'return_request__sale', 'return_request__customer', 'sale_item'
        )


@admin.register(Invoice)
class InvoiceAdmin(admin.ModelAdmin):
    """Admin interface for Invoice model"""
    
    list_display = [
        'invoice_number', 'sale', 'status', 'issue_date', 'due_date', 'is_active'
    ]
    
    list_filter = [
        'status', 'is_active', 'issue_date', 'due_date', 'created_at'
    ]
    
    search_fields = [
        'invoice_number', 'sale__invoice_number', 'notes'
    ]
    
    readonly_fields = [
        'id', 'invoice_number', 'created_at', 'updated_at'
    ]
    
    fieldsets = (
        ('Invoice Information', {
            'fields': ('id', 'invoice_number', 'sale')
        }),
        ('Status & Dates', {
            'fields': ('status', 'issue_date', 'due_date')
        }),
        ('Content', {
            'fields': ('notes', 'terms_conditions')
        }),
        ('Files & Communication', {
            'fields': ('pdf_file', 'email_sent', 'email_sent_at', 'viewed_at'),
            'classes': ('collapse',)
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at', 'created_by'),
            'classes': ('collapse',)
        }),
    )
    
    list_per_page = 25
    ordering = ('-issue_date', '-created_at')
    
    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('sale', 'created_by')
    
    def save_model(self, request, obj, form, change):
        """Custom save method to handle invoice creation"""
        if not change:  # New invoice
            obj.created_by = request.user
        
        super().save_model(request, obj, form, change)


@admin.register(Receipt)
class ReceiptAdmin(admin.ModelAdmin):
    """Admin interface for Receipt model"""
    
    list_display = [
        'receipt_number', 'sale', 'payment', 'status', 'generated_at', 'is_active'
    ]
    
    list_filter = [
        'status', 'is_active', 'generated_at', 'created_at'
    ]
    
    search_fields = [
        'receipt_number', 'sale__invoice_number', 'notes'
    ]
    
    readonly_fields = [
        'id', 'receipt_number', 'created_at', 'updated_at'
    ]
    
    fieldsets = (
        ('Receipt Information', {
            'fields': ('id', 'receipt_number', 'sale', 'payment')
        }),
        ('Status & Communication', {
            'fields': ('status', 'generated_at', 'email_sent', 'email_sent_at', 'viewed_at')
        }),
        ('Files', {
            'fields': ('pdf_file',)
        }),
        ('Notes', {
            'fields': ('notes',)
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at', 'created_by'),
            'classes': ('collapse',)
        }),
    )
    
    list_per_page = 25
    ordering = ('-generated_at', '-created_at')
    
    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related('sale', 'payment', 'created_by')
    
    def save_model(self, request, obj, form, change):
        """Custom save method to handle receipt creation"""
        if not change:  # New receipt
            obj.created_by = request.user
        
        super().save_model(request, obj, form, change)


@admin.register(Refund)
class RefundAdmin(admin.ModelAdmin):
    """Admin interface for Refund model"""
    
    list_display = [
        'refund_number', 'return_request', 'amount', 'method', 'status', 
        'processed_by', 'processed_at', 'is_active'
    ]
    
    list_filter = [
        'status', 'method', 'is_active', 'created_at', 'processed_at'
    ]
    
    search_fields = [
        'refund_number', 'return_request__return_number', 'notes'
    ]
    
    readonly_fields = [
        'id', 'refund_number', 'created_at', 'updated_at'
    ]
    
    fieldsets = (
        ('Refund Information', {
            'fields': ('id', 'refund_number', 'return_request', 'amount', 'method')
        }),
        ('Status & Processing', {
            'fields': ('status', 'reference_number', 'processed_by', 'processed_at')
        }),
        ('Notes', {
            'fields': ('notes',)
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    list_per_page = 25
    ordering = ('-created_at',)
    
    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related(
            'return_request', 'return_request__sale', 'return_request__customer',
            'processed_by', 'created_by'
        )
    
    def save_model(self, request, obj, form, change):
        """Custom save method to handle refund processing"""
        if not change:  # New refund
            obj.created_by = request.user
        
        super().save_model(request, obj, form, change)
