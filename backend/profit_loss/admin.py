from django.contrib import admin
from django.utils.html import format_html
from django.db.models import Sum
from .models import ProfitLossRecord, ProfitLossCalculation


@admin.register(ProfitLossCalculation)
class ProfitLossCalculationAdmin(admin.ModelAdmin):
    """Admin interface for ProfitLossCalculation model"""
    
    list_display = [
        'id', 'profit_loss_record', 'calculation_type', 'source_model',
        'source_count', 'formatted_source_total', 'calculated_at'
    ]
    
    list_filter = [
        'calculation_type', 'source_model', 'calculated_at'
    ]
    
    search_fields = [
        'calculation_type', 'source_model', 'calculation_notes'
    ]
    
    readonly_fields = [
        'id', 'calculated_at', 'created_at', 'updated_at'
    ]
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('id', 'profit_loss_record', 'calculation_type')
        }),
        ('Calculation Details', {
            'fields': ('source_model', 'source_count', 'source_total')
        }),
        ('Additional Information', {
            'fields': ('calculation_details', 'calculation_notes')
        }),
        ('Timestamps', {
            'fields': ('calculated_at', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def formatted_source_total(self, obj):
        """Display formatted source total"""
        return obj.formatted_source_total
    formatted_source_total.short_description = 'Source Total'
    
    def has_add_permission(self, request):
        """Calculations are created automatically, not manually"""
        return False


@admin.register(ProfitLossRecord)
class ProfitLossRecordAdmin(admin.ModelAdmin):
    """Admin interface for ProfitLossRecord model"""
    
    list_display = [
        'period_display', 'period_type', 'total_sales_income_display',
        'total_cost_of_goods_sold_display', 'gross_profit_display', 'total_expenses_display', 
        'net_profit_display', 'gross_profit_margin_display', 'profit_margin_display',
        'is_profitable_display', 'total_products_sold', 'created_at'
    ]
    
    list_filter = [
        'period_type', 'is_active', 'created_at'
    ]
    
    search_fields = [
        'period_type', 'calculation_notes'
    ]
    
    readonly_fields = [
        'id', 'total_expenses_calculated', 'net_profit', 'profit_margin_percentage',
        'created_at', 'updated_at', 'expense_breakdown_display', 'summary_stats_display'
    ]
    
    fieldsets = (
        ('Period Information', {
            'fields': ('id', 'period_type', 'start_date', 'end_date')
        }),
        ('Income & COGS', {
            'fields': ('total_sales_income', 'total_cost_of_goods_sold', 'total_products_sold', 'average_order_value')
        }),
        ('Expenses', {
            'fields': (
                'total_labor_payments', 'total_vendor_payments', 
                'total_expenses', 'total_zakat'
            )
        }),
        ('Calculated Fields', {
            'fields': (
                'gross_profit', 'gross_profit_margin_percentage',
                'total_expenses_calculated', 'net_profit', 'profit_margin_percentage'
            ),
            'classes': ('collapse',)
        }),
        ('Additional Information', {
            'fields': ('calculation_notes', 'is_active')
        }),
        ('System Information', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def total_sales_income_display(self, obj):
        """Display formatted total sales income"""
        return obj.formatted_total_sales_income
    total_sales_income_display.short_description = 'Sales Income'
    
    def total_cost_of_goods_sold_display(self, obj):
        """Display formatted total cost of goods sold"""
        return obj.formatted_total_cost_of_goods_sold
    total_cost_of_goods_sold_display.short_description = 'COGS'
    
    def gross_profit_display(self, obj):
        """Display formatted gross profit with color coding"""
        if obj.gross_profit > 0:
            return format_html(
                '<span style="color: green; font-weight: bold;">{}</span>',
                obj.formatted_gross_profit
            )
        else:
            return format_html(
                '<span style="color: red; font-weight: bold;">{}</span>',
                obj.formatted_gross_profit
            )
    gross_profit_display.short_description = 'Gross Profit'
    
    def total_expenses_display(self, obj):
        """Display formatted total expenses"""
        return obj.formatted_total_expenses
    total_expenses_display.short_description = 'Total Expenses'
    
    def net_profit_display(self, obj):
        """Display formatted net profit with color coding"""
        if obj.is_profitable:
            return format_html(
                '<span style="color: green; font-weight: bold;">{}</span>',
                obj.formatted_net_profit
            )
        else:
            return format_html(
                '<span style="color: red; font-weight: bold;">{}</span>',
                obj.formatted_net_profit
            )
    net_profit_display.short_description = 'Net Profit'
    
    def profit_margin_display(self, obj):
        """Display formatted profit margin with color coding"""
        if obj.profit_margin_percentage > 20:
            color = 'green'
        elif obj.profit_margin_percentage > 10:
            color = 'orange'
        else:
            color = 'red'
        
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            color, obj.formatted_profit_margin
        )
    profit_margin_display.short_description = 'Profit Margin'
    
    def gross_profit_margin_display(self, obj):
        """Display formatted gross profit margin with color coding"""
        if obj.gross_profit_margin_percentage > 40:
            color = 'green'
        elif obj.gross_profit_margin_percentage > 25:
            color = 'orange'
        else:
            color = 'red'
        
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            color, obj.formatted_gross_profit_margin
        )
    gross_profit_margin_display.short_description = 'Gross Profit Margin'
    
    def is_profitable_display(self, obj):
        """Display profitability status with icon"""
        if obj.is_profitable:
            return format_html(
                '<span style="color: green;">✓ Profitable</span>'
            )
        else:
            return format_html(
                '<span style="color: red;">✗ Loss</span>'
            )
    is_profitable_display.short_description = 'Status'
    
    def expense_breakdown_display(self, obj):
        """Display expense breakdown as formatted text"""
        breakdown = obj.expense_breakdown
        return format_html(
            '<div style="font-family: monospace;">'
            '<strong>Cost of Goods Sold:</strong> PKR {:,}<br>'
            '<strong>Labor Payments:</strong> PKR {:,}<br>'
            '<strong>Vendor Payments:</strong> PKR {:,}<br>'
            '<strong>Other Expenses:</strong> PKR {:,}<br>'
            '<strong>Zakat:</strong> PKR {:,}<br>'
            '<strong>Total:</strong> PKR {:,}'
            '</div>',
            breakdown['cost_of_goods_sold'],
            breakdown['labor_payments'],
            breakdown['vendor_payments'],
            breakdown['other_expenses'],
            breakdown['zakat'],
            breakdown['total']
        )
    expense_breakdown_display.short_description = 'Expense Breakdown'
    
    def summary_stats_display(self, obj):
        """Display summary statistics as formatted text"""
        stats = obj.summary_stats
        return format_html(
            '<div style="font-family: monospace;">'
            '<strong>Period:</strong> {}<br>'
            '<strong>Total Sales:</strong> PKR {:,}<br>'
            '<strong>Cost of Goods Sold:</strong> PKR {:,}<br>'
            '<strong>Gross Profit:</strong> PKR {:,}<br>'
            '<strong>Gross Profit Margin:</strong> {}<br>'
            '<strong>Total Expenses:</strong> PKR {:,}<br>'
            '<strong>Net Profit:</strong> PKR {:,}<br>'
            '<strong>Net Profit Margin:</strong> {}<br>'
            '<strong>Products Sold:</strong> {}<br>'
            '<strong>Average Order:</strong> PKR {:,}<br>'
            '<strong>Profitable:</strong> {}'
            '</div>',
            stats['period'],
            stats['total_sales'],
            stats['cost_of_goods_sold'],
            stats['gross_profit'],
            f"{stats['gross_profit_margin']:.2f}%",
            stats['total_expenses'],
            stats['net_profit'],
            f"{stats['profit_margin']:.2f}%",
            stats['products_sold'],
            stats['average_order_value'],
            'Yes' if stats['is_profitable'] else 'No'
        )
    summary_stats_display.short_description = 'Summary Statistics'
    
    def get_queryset(self, request):
        """Optimize queryset with related calculations"""
        return super().get_queryset(request).prefetch_related('calculations')
    
    def has_add_permission(self, request):
        """Records are created through calculations, not manually"""
        return False
    
    def has_delete_permission(self, request, obj=None):
        """Allow deletion for admin users"""
        return request.user.is_superuser


# Custom admin site configuration
admin.site.site_header = "Al Noor Fabrics - Profit & Loss Management"
admin.site.site_title = "Profit & Loss Admin"
admin.site.index_title = "Profit & Loss Administration"
