from django.contrib import admin
from django.utils.html import format_html
from django.db.models import Sum, F
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import Product


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = (
        'name',
        'color',
        'fabric',
        'formatted_price',
        'quantity',
        'stock_status_badge',
        'category_link',
        'formatted_total_value',
        'is_active',
        'created_at'
    )
    
    list_filter = (
        'is_active',
        'category',
        'color',
        'fabric',
        'created_at',
        'updated_at',
    )
    
    search_fields = (
        'name',
        'detail',
        'color',
        'fabric',
        'category__name',
        'pieces',
    )
    
    readonly_fields = (
        'id',
        'stock_status',
        'stock_status_display',
        'total_value',
        'created_at',
        'updated_at',
        'created_by',
    )
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('id', 'name', 'detail', 'category')
        }),
        ('Product Details', {
            'fields': ('color', 'fabric', 'pieces', 'price')
        }),
        ('Inventory', {
            'fields': ('quantity', 'stock_status', 'stock_status_display', 'total_value')
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
    date_hierarchy = 'created_at'
    ordering = ('-created_at', 'name')
    
    actions = [
        'mark_as_active',
        'mark_as_inactive',
        'update_low_stock_alert',
        'calculate_total_inventory_value',
    ]

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related(
            'category',
            'created_by'
        )

    def formatted_price(self, obj):
        """Display formatted price"""
        if obj.price is None:
            return "Not set"
        return f"PKR {obj.price:,.2f}"
    formatted_price.short_description = 'Price'
    formatted_price.admin_order_field = 'price'

    def formatted_total_value(self, obj):
        """Display formatted total inventory value"""
        if obj.price is None:
            return "Not calculated"
        return f"PKR {obj.total_value:,.2f}"
    formatted_total_value.short_description = 'Total Value'
    formatted_total_value.admin_order_field = 'total_value'

    def stock_status_badge(self, obj):
        """Display stock status with color coding"""
        colors = {
            'OUT_OF_STOCK': '#dc3545',  # Red
            'LOW_STOCK': '#fd7e14',     # Orange
            'MEDIUM_STOCK': '#ffc107',  # Yellow
            'HIGH_STOCK': '#198754',    # Green
        }
        
        color = colors.get(obj.stock_status, '#6c757d')
        
        return format_html(
            '<span style="background-color: {}; color: white; padding: 2px 8px; '
            'border-radius: 4px; font-size: 11px; font-weight: bold;">{}</span>',
            color,
            obj.stock_status_display
        )
    stock_status_badge.short_description = 'Stock Status'
    stock_status_badge.admin_order_field = 'quantity'

    def category_link(self, obj):
        """Display category as a clickable link"""
        if obj.category:
            url = reverse('admin:categories_category_change', args=[obj.category.id])
            return format_html('<a href="{}">{}</a>', url, obj.category.name)
        return '-'
    category_link.short_description = 'Category'
    category_link.admin_order_field = 'category__name'

    def save_model(self, request, obj, form, change):
        """Set created_by when creating new product"""
        if not change:  # Creating new product
            obj.created_by = request.user
        super().save_model(request, obj, form, change)

    # Custom admin actions
    def mark_as_active(self, request, queryset):
        """Mark selected products as active"""
        updated = queryset.update(is_active=True)
        self.message_user(
            request,
            f'{updated} products were successfully marked as active.'
        )
    mark_as_active.short_description = 'Mark selected products as active'

    def mark_as_inactive(self, request, queryset):
        """Mark selected products as inactive"""
        updated = queryset.update(is_active=False)
        self.message_user(
            request,
            f'{updated} products were successfully marked as inactive.'
        )
    mark_as_inactive.short_description = 'Mark selected products as inactive'

    def update_low_stock_alert(self, request, queryset):
        """Show low stock alert for selected products"""
        low_stock_products = queryset.filter(quantity__lte=5, quantity__gt=0)
        count = low_stock_products.count()
        
        if count > 0:
            products_list = ', '.join([p.name for p in low_stock_products[:5]])
            if count > 5:
                products_list += f' and {count - 5} more'
            
            self.message_user(
                request,
                f'Low stock alert: {count} products need restocking: {products_list}',
                level='WARNING'
            )
        else:
            self.message_user(
                request,
                'No low stock products found in selection.'
            )
    update_low_stock_alert.short_description = 'Check low stock status'

    def calculate_total_inventory_value(self, request, queryset):
        """Calculate total inventory value for selected products"""
        from django.db.models import Sum, Case, When, DecimalField, F
        
        total = queryset.aggregate(
            total_value=Sum(
                Case(
                    When(price__isnull=False, quantity__isnull=False, 
                         then=F('price') * F('quantity')),
                    default=0,
                    output_field=DecimalField(max_digits=15, decimal_places=2)
                )
            )
        )['total_value'] or 0
        
        self.message_user(
            request,
            f'Total inventory value for {queryset.count()} selected products: PKR {total:,.2f}'
        )
    calculate_total_inventory_value.short_description = 'Calculate total inventory value'

    def changelist_view(self, request, extra_context=None):
        """Add extra context to changelist view"""
        extra_context = extra_context or {}
        
        # Get some quick stats for the admin
        from django.db.models import Sum, Case, When, DecimalField, F
        
        active_products = Product.objects.filter(is_active=True)
        total_products = active_products.count()
        low_stock_count = Product.low_stock_products().count()
        out_of_stock_count = Product.out_of_stock_products().count()
        
        total_value = active_products.aggregate(
            total=Sum(
                Case(
                    When(price__isnull=False, quantity__isnull=False, 
                         then=F('price') * F('quantity')),
                    default=0,
                    output_field=DecimalField(max_digits=15, decimal_places=2)
                )
            )
        )['total'] or 0
        
        extra_context.update({
            'total_products': total_products,
            'low_stock_count': low_stock_count,
            'out_of_stock_count': out_of_stock_count,
            'total_inventory_value': total_value,
        })
        
        return super().changelist_view(request, extra_context)


# Optional: Custom admin site title and header
admin.site.site_header = "Product Inventory Management"
admin.site.site_title = "Product Admin"
admin.site.index_title = "Welcome to Product Inventory Management"
