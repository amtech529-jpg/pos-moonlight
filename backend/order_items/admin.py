from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from django.db.models import Sum, Count
from .models import OrderItem


@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = (
        'product_name_formatted',
        'order_link',
        'quantity',
        'formatted_unit_price',
        'formatted_line_total',
        'customization_badge',
        'stock_status',
        'is_active',
        'created_at'
    )
    
    list_filter = (
        'is_active',
        'created_at',
        'updated_at',
        'order__status',
        'product__category',
    )
    
    search_fields = (
        'product_name',
        'customization_notes',
        'order__customer_name',
        'product__name',
        'product__color',
        'product__fabric',
    )
    
    readonly_fields = (
        'id',
        'line_total',
        'product_display_info',
        'stock_availability_info',
        'created_at',
        'updated_at',
    )
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('id', 'order', 'product', 'product_name')
        }),
        ('Quantity & Pricing', {
            'fields': ('quantity', 'unit_price', 'line_total')
        }),
        ('Customization', {
            'fields': ('customization_notes',)
        }),
        ('Product Information', {
            'fields': ('product_display_info', 'stock_availability_info'),
            'classes': ('collapse',)
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
    date_hierarchy = 'created_at'
    ordering = ('-created_at', 'product_name')
    
    actions = [
        'mark_as_active',
        'mark_as_inactive',
        'calculate_total_value',
        'check_stock_availability',
    ]

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related(
            'order',
            'product',
            'order__customer'
        )

    def product_name_formatted(self, obj):
        """Display formatted product name with link to product"""
        if obj.product:
            product_url = reverse('admin:products_product_change', args=[obj.product.id])
            return format_html(
                '<strong><a href="{}">{}</a></strong><br>'
                '<small style="color: #666;">{} - {}</small>',
                product_url,
                obj.product_name,
                obj.product.color if obj.product else 'N/A',
                obj.product.fabric if obj.product else 'N/A'
            )
        return format_html('<strong>{}</strong><br><small style="color: #dc3545;">Product not found</small>', obj.product_name)
    product_name_formatted.short_description = 'Product'
    product_name_formatted.admin_order_field = 'product_name'

    def order_link(self, obj):
        """Display order as a clickable link"""
        if obj.order:
            url = reverse('admin:orders_order_change', args=[obj.order.id])
            return format_html(
                '<a href="{}">{}</a><br>'
                '<small style="color: #666;">{}</small>',
                url,
                obj.order.customer_name,
                obj.order.get_status_display()
            )
        return '-'
    order_link.short_description = 'Order'
    order_link.admin_order_field = 'order__customer_name'

    def formatted_unit_price(self, obj):
        """Display formatted unit price"""
        if obj.unit_price is None:
            return "Not set"
        return f"PKR {obj.unit_price:,.2f}"
    formatted_unit_price.short_description = 'Unit Price'
    formatted_unit_price.admin_order_field = 'unit_price'

    def formatted_line_total(self, obj):
        """Display formatted line total"""
        if obj.line_total is None:
            return "Not calculated"
        return f"PKR {obj.line_total:,.2f}"
    formatted_line_total.short_description = 'Line Total'
    formatted_line_total.admin_order_field = 'line_total'

    def customization_badge(self, obj):
        """Display customization status with badge"""
        if obj.customization_notes:
            return format_html(
                '<span style="background-color: #17a2b8; color: white; padding: 2px 6px; '
                'border-radius: 3px; font-size: 10px; font-weight: bold;" '
                'title="{}">CUSTOM</span>',
                obj.customization_notes[:100] + '...' if len(obj.customization_notes) > 100 else obj.customization_notes
            )
        return format_html(
            '<span style="background-color: #6c757d; color: white; padding: 2px 6px; '
            'border-radius: 3px; font-size: 10px;">STANDARD</span>'
        )
    customization_badge.short_description = 'Customization'

    def stock_status(self, obj):
        """Display stock availability status"""
        if not obj.product:
            return format_html(
                '<span style="color: #dc3545;">Product N/A</span>'
            )
        
        available_stock = obj.product.quantity
        required_stock = obj.quantity
        
        if available_stock >= required_stock:
            color = '#28a745'  # Green
            status = f'✓ Available ({available_stock})'
        elif available_stock > 0:
            color = '#fd7e14'  # Orange
            status = f'⚠ Partial ({available_stock}/{required_stock})'
        else:
            color = '#dc3545'  # Red
            status = '✗ Out of Stock'
        
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            color,
            status
        )
    stock_status.short_description = 'Stock Status'

    def product_display_info(self, obj):
        """Display comprehensive product information"""
        if not obj.product:
            return format_html('<span style="color: #dc3545;">Product not available</span>')
        
        return format_html(
            '<strong>Current Product Info:</strong><br>'
            'Name: {}<br>'
            'Color: {}<br>'
            'Fabric: {}<br>'
            'Current Price: PKR {}<br>'
            'Current Stock: {} units<br>'
            'Category: {}',
            obj.product.name,
            obj.product.color,
            obj.product.fabric,
            obj.product.price,
            obj.product.quantity,
            obj.product.category.name if obj.product.category else 'N/A'
        )
    product_display_info.short_description = 'Product Information'

    def stock_availability_info(self, obj):
        """Display stock availability analysis"""
        if not obj.product:
            return format_html('<span style="color: #dc3545;">Product not available for stock check</span>')
        
        available = obj.product.quantity
        required = obj.quantity
        
        if available >= required:
            status_color = '#28a745'
            status_text = 'Stock Available'
        elif available > 0:
            status_color = '#fd7e14'
            status_text = 'Partial Stock Available'
        else:
            status_color = '#dc3545'
            status_text = 'Out of Stock'
        
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span><br>'
            'Required: {} units<br>'
            'Available: {} units<br>'
            'Shortage: {} units',
            status_color,
            status_text,
            required,
            available,
            max(0, required - available)
        )
    stock_availability_info.short_description = 'Stock Availability'

    # Custom admin actions
    def mark_as_active(self, request, queryset):
        """Mark selected order items as active"""
        updated = queryset.update(is_active=True)
        self.message_user(
            request,
            f'{updated} order items were successfully marked as active.'
        )
    mark_as_active.short_description = 'Mark selected order items as active'

    def mark_as_inactive(self, request, queryset):
        """Mark selected order items as inactive"""
        updated = queryset.update(is_active=False)
        self.message_user(
            request,
            f'{updated} order items were successfully marked as inactive.'
        )
    mark_as_inactive.short_description = 'Mark selected order items as inactive'

    def calculate_total_value(self, request, queryset):
        """Calculate total value for selected order items"""
        total_value = queryset.aggregate(Sum('line_total'))['line_total__sum'] or 0
        total_quantity = queryset.aggregate(Sum('quantity'))['quantity__sum'] or 0
        
        self.message_user(
            request,
            f'Total value for {queryset.count()} selected order items: '
            f'PKR {total_value:,.2f} (Total quantity: {total_quantity})'
        )
    calculate_total_value.short_description = 'Calculate total value'

    def check_stock_availability(self, request, queryset):
        """Check stock availability for selected order items"""
        stock_issues = []
        
        for item in queryset:
            if item.product:
                available = item.product.quantity
                required = item.quantity
                
                if available < required:
                    shortage = required - available
                    stock_issues.append(f"{item.product_name}: {shortage} short")
        
        if stock_issues:
            issues_text = ', '.join(stock_issues[:5])
            if len(stock_issues) > 5:
                issues_text += f' and {len(stock_issues) - 5} more'
            
            self.message_user(
                request,
                f'Stock issues found in {len(stock_issues)} items: {issues_text}',
                level='WARNING'
            )
        else:
            self.message_user(
                request,
                'All selected order items have sufficient stock available.'
            )
    check_stock_availability.short_description = 'Check stock availability'

    def changelist_view(self, request, extra_context=None):
        """Add extra context to changelist view"""
        extra_context = extra_context or {}
        
        # Get some quick stats for the admin
        active_items = OrderItem.objects.filter(is_active=True)
        total_items = active_items.count()
        total_value = active_items.aggregate(Sum('line_total'))['line_total__sum'] or 0
        total_quantity = active_items.aggregate(Sum('quantity'))['quantity__sum'] or 0
        items_with_customization = active_items.exclude(customization_notes='').count()
        
        extra_context.update({
            'total_order_items': total_items,
            'total_value': total_value,
            'total_quantity': total_quantity,
            'items_with_customization': items_with_customization,
            'customization_percentage': round(
                (items_with_customization / total_items * 100) if total_items > 0 else 0, 1
            ),
        })
        
        return super().changelist_view(request, extra_context)


# Optional: Custom admin site title and header
admin.site.site_header = "Order Item Management System"
admin.site.site_title = "Order Item Admin"
admin.site.index_title = "Welcome to Order Item Management System"
