from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from django.db.models import Sum, Count
from .models import Order


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = (
        'order_number',
        'customer_link',
        'formatted_total_amount',
        'payment_status_badge',
        'status_badge',
        'delivery_status_badge',
        'date_ordered',
        'expected_delivery_date',
        'is_active',
        'created_at'
    )
    
    list_filter = (
        'is_active',
        'status',
        'is_fully_paid',
        'date_ordered',
        'expected_delivery_date',
        'created_at',
        ('customer', admin.RelatedOnlyFieldListFilter),
        ('created_by', admin.RelatedOnlyFieldListFilter),
    )
    
    search_fields = (
        'customer_name',
        'customer_phone',
        'customer_email',
        'description',
        'id',
    )
    
    readonly_fields = (
        'id',
        'total_amount',
        'remaining_amount',
        'is_fully_paid',
        'days_since_ordered',
        'days_until_delivery',
        'is_overdue',
        'payment_percentage',
        'order_summary_display',
        'delivery_status_display',
        'order_items_summary',
        'created_at',
        'updated_at',
        'created_by',
    )
    
    fieldsets = (
        ('Order Information', {
            'fields': ('id', 'customer', 'customer_name', 'customer_phone', 'customer_email')
        }),
        ('Financial Details', {
            'fields': ('advance_payment', 'total_amount', 'remaining_amount', 'is_fully_paid', 'payment_percentage')
        }),
        ('Order Details', {
            'fields': ('date_ordered', 'expected_delivery_date', 'description', 'status')
        }),
        ('Order Analytics', {
            'fields': ('days_since_ordered', 'days_until_delivery', 'is_overdue', 'order_summary_display', 'delivery_status_display'),
            'classes': ('collapse',)
        }),
        ('Order Items', {
            'fields': ('order_items_summary',),
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
    date_hierarchy = 'date_ordered'
    ordering = ('-date_ordered', '-created_at')
    
    actions = [
        'mark_as_active',
        'mark_as_inactive',
        'confirm_orders',
        'mark_ready_for_delivery',
        'mark_delivered',
        'cancel_orders',
        'calculate_total_value',
        'check_overdue_orders',
        'check_payment_status',
        'recalculate_totals',
    ]

    def get_queryset(self, request):
        """Optimize queryset with select_related"""
        return super().get_queryset(request).select_related(
            'customer',
            'created_by'
        ).prefetch_related('order_items')

    def order_number(self, obj):
        """Display formatted order number"""
        return format_html(
            '<strong>#{}</strong>',
            str(obj.id)[:8]  # Show first 8 characters of UUID
        )
    order_number.short_description = 'Order #'
    order_number.admin_order_field = 'id'

    def customer_link(self, obj):
        """Display customer as a clickable link"""
        if obj.customer:
            url = reverse('admin:customers_customer_change', args=[obj.customer.id])
            return format_html(
                '<a href="{}">{}</a><br>'
                '<small style="color: #666;">{}</small><br>'
                '<small style="color: #666;">{}</small>',
                url,
                obj.customer_name,
                obj.customer_phone,
                obj.customer_email or 'No email'
            )
        return format_html(
            '<strong>{}</strong><br>'
            '<small style="color: #dc3545;">Customer not found</small><br>'
            '<small style="color: #666;">{}</small>',
            obj.customer_name,
            obj.customer_phone
        )
    customer_link.short_description = 'Customer'
    customer_link.admin_order_field = 'customer_name'

    def formatted_total_amount(self, obj):
        """Display formatted total amount"""
        if obj.total_amount is None or obj.total_amount == 0:
            return format_html('<span style="color: #6c757d;">Not calculated</span>')
        return f"PKR {obj.total_amount:,.2f}"
    formatted_total_amount.short_description = 'Total Amount'
    formatted_total_amount.admin_order_field = 'total_amount'

    def payment_status_badge(self, obj):
        """Display payment status with color coding"""
        if obj.total_amount == 0:
            return format_html(
                '<span style="background-color: #6c757d; color: white; padding: 2px 6px; '
                'border-radius: 3px; font-size: 10px; font-weight: bold;">NO ITEMS</span>'
            )
        
        if obj.is_fully_paid:
            color = '#28a745'  # Green
            text = 'FULLY PAID'
        elif obj.advance_payment > 0:
            color = '#fd7e14'  # Orange
            text = f'{obj.payment_percentage:.0f}% PAID'
        else:
            color = '#dc3545'  # Red
            text = 'UNPAID'
        
        return format_html(
            '<span style="background-color: {}; color: white; padding: 2px 6px; '
            'border-radius: 3px; font-size: 10px; font-weight: bold;" '
            'title="Advance: PKR {}, Remaining: PKR {}">{}</span>',
            color,
            obj.advance_payment,
            obj.remaining_amount,
            text
        )
    payment_status_badge.short_description = 'Payment'

    def status_badge(self, obj):
        """Display order status with color coding"""
        colors = {
            'PENDING': '#007bff',      # Primary blue
            'CONFIRMED': '#17a2b8',    # Info cyan
            'READY': '#28a745',        # Success green
            'DELIVERED': '#6f42c1',    # Purple
            'CANCELLED': '#dc3545',    # Danger red
        }
        
        color = colors.get(obj.status, '#6c757d')
        
        return format_html(
            '<span style="background-color: {}; color: {}; padding: 2px 8px; '
            'border-radius: 4px; font-size: 11px; font-weight: bold;">{}</span>',
            color,
            'white',
            obj.get_status_display()
        )
    status_badge.short_description = 'Status'
    status_badge.admin_order_field = 'status'

    def delivery_status_badge(self, obj):
        """Display delivery status with color coding"""
        if obj.status in ['DELIVERED', 'CANCELLED']:
            color = '#6c757d'
            status_text = obj.get_status_display()
        elif not obj.expected_delivery_date:
            color = '#6c757d'
            status_text = 'No Date Set'
        elif obj.is_overdue:
            color = '#dc3545'
            days_overdue = abs(obj.days_until_delivery)
            status_text = f'Overdue {days_overdue}d'
        elif obj.days_until_delivery == 0:
            color = '#ffc107'
            status_text = 'Due Today'
        elif obj.days_until_delivery > 0 and obj.days_until_delivery <= 3:
            color = '#fd7e14'
            status_text = f'Due in {obj.days_until_delivery}d'
        else:
            color = '#28a745'
            status_text = f'Due in {obj.days_until_delivery}d'
        
        return format_html(
            '<span style="background-color: {}; color: {}; padding: 2px 6px; '
            'border-radius: 3px; font-size: 10px; font-weight: bold;">{}</span>',
            color,
            'black' if color == '#ffc107' else 'white',
            status_text
        )
    delivery_status_badge.short_description = 'Delivery'

    def delivery_status_display(self, obj):
        """Display detailed delivery status"""
        return obj.get_delivery_status()
    delivery_status_display.short_description = 'Delivery Status'

    def order_summary_display(self, obj):
        """Display order summary information"""
        summary = obj.order_summary
        return format_html(
            '<strong>Order Summary:</strong><br>'
            'Total Items: {}<br>'
            'Total Quantity: {}<br>'
            'Payment Status: {}<br>'
            'Days Since Ordered: {}<br>'
            'Delivery Status: {}',
            summary['total_items'],
            summary['total_quantity'],
            summary['payment_status'],
            summary['days_since_ordered'],
            summary['delivery_status']
        )
    order_summary_display.short_description = 'Order Summary'

    def order_items_summary(self, obj):
        """Display order items summary"""
        items = obj.get_order_items()
        if not items:
            return format_html('<span style="color: #6c757d;">No items in this order</span>')
        
        items_html = []
        for item in items[:5]:  # Show first 5 items
            customization = ' (Custom)' if item.customization_notes else ''
            items_html.append(
                f"• {item.product_name} x{item.quantity} = PKR {item.line_total}{customization}"
            )
        
        if items.count() > 5:
            items_html.append(f"... and {items.count() - 5} more items")
        
        return format_html('<br>'.join(items_html))
    order_items_summary.short_description = 'Order Items'

    def save_model(self, request, obj, form, change):
        """Set created_by when creating new order"""
        if not change:  # Creating new order
            obj.created_by = request.user
        super().save_model(request, obj, form, change)

    # Custom admin actions
    def mark_as_active(self, request, queryset):
        """Mark selected orders as active"""
        updated = queryset.update(is_active=True)
        self.message_user(
            request,
            f'{updated} orders were successfully marked as active.'
        )
    mark_as_active.short_description = 'Mark selected orders as active'

    def mark_as_inactive(self, request, queryset):
        """Mark selected orders as inactive"""
        updated = queryset.update(is_active=False)
        self.message_user(
            request,
            f'{updated} orders were successfully marked as inactive.'
        )
    mark_as_inactive.short_description = 'Mark selected orders as inactive'

    def confirm_orders(self, request, queryset):
        """Confirm pending orders"""
        pending_orders = queryset.filter(status='PENDING')
        count = 0
        
        for order in pending_orders:
            order.update_status('CONFIRMED', 'Bulk confirmation via admin')
            count += 1
        
        self.message_user(
            request,
            f'{count} pending orders were confirmed.'
        )
    confirm_orders.short_description = 'Confirm pending orders'


    def mark_ready_for_delivery(self, request, queryset):
        """Mark orders as ready for delivery"""
        production_orders = queryset.filter(status='CONFIRMED')
        count = 0
        
        for order in production_orders:
            order.update_status('READY', 'Marked ready via admin')
            count += 1
        
        self.message_user(
            request,
            f'{count} orders marked as ready for delivery.'
        )
    mark_ready_for_delivery.short_description = 'Mark as ready for delivery'

    def mark_delivered(self, request, queryset):
        """Mark orders as delivered"""
        ready_orders = queryset.filter(status='READY')
        count = 0
        
        for order in ready_orders:
            order.update_status('DELIVERED', 'Marked delivered via admin')
            count += 1
        
        self.message_user(
            request,
            f'{count} orders marked as delivered.'
        )
    mark_delivered.short_description = 'Mark as delivered'

    def cancel_orders(self, request, queryset):
        """Cancel orders that can be cancelled"""
        cancelled_count = 0
        cannot_cancel = []
        
        for order in queryset:
            if order.can_be_cancelled():
                order.update_status('CANCELLED', 'Cancelled via admin')
                cancelled_count += 1
            else:
                cannot_cancel.append(str(order.id)[:8])
        
        message = f'{cancelled_count} orders were cancelled.'
        if cannot_cancel:
            message += f' Could not cancel {len(cannot_cancel)} orders: {", ".join(cannot_cancel)}'
        
        self.message_user(request, message)
    cancel_orders.short_description = 'Cancel selected orders'

    def calculate_total_value(self, request, queryset):
        """Calculate total value for selected orders"""
        totals = queryset.aggregate(
            total_amount=Sum('total_amount'),
            total_advance=Sum('advance_payment'),
            total_remaining=Sum('remaining_amount')
        )
        
        total_amount = totals['total_amount'] or 0
        total_advance = totals['total_advance'] or 0
        total_remaining = totals['total_remaining'] or 0
        
        self.message_user(
            request,
            f'Selected {queryset.count()} orders: '
            f'Total Value: PKR {total_amount:,.2f}, '
            f'Advance Received: PKR {total_advance:,.2f}, '
            f'Remaining: PKR {total_remaining:,.2f}'
        )
    calculate_total_value.short_description = 'Calculate total financial summary'

    def check_overdue_orders(self, request, queryset):
        """Check for overdue orders in selection"""
        overdue_orders = [order for order in queryset if order.is_overdue]
        
        if overdue_orders:
            overdue_list = [f"#{str(order.id)[:8]}" for order in overdue_orders[:5]]
            if len(overdue_orders) > 5:
                overdue_list.append(f"and {len(overdue_orders) - 5} more")
            
            self.message_user(
                request,
                f'Found {len(overdue_orders)} overdue orders: {", ".join(overdue_list)}',
                level='WARNING'
            )
        else:
            self.message_user(
                request,
                'No overdue orders found in selection.'
            )
    check_overdue_orders.short_description = 'Check for overdue deliveries'

    def check_payment_status(self, request, queryset):
        """Check payment status of selected orders"""
        fully_paid = queryset.filter(is_fully_paid=True).count()
        unpaid = queryset.filter(is_fully_paid=False, total_amount__gt=0).count()
        no_items = queryset.filter(total_amount=0).count()
        
        self.message_user(
            request,
            f'Payment status for {queryset.count()} orders: '
            f'{fully_paid} fully paid, {unpaid} unpaid, {no_items} without items'
        )
    check_payment_status.short_description = 'Check payment status'

    def recalculate_totals(self, request, queryset):
        """Recalculate order totals from order items"""
        recalculated = 0
        
        for order in queryset:
            try:
                order.calculate_totals()
                recalculated += 1
            except Exception:
                pass
        
        self.message_user(
            request,
            f'{recalculated} order totals recalculated successfully.'
        )
    recalculate_totals.short_description = 'Recalculate order totals'

    def changelist_view(self, request, extra_context=None):
        """Add extra context to changelist view"""
        extra_context = extra_context or {}
        
        # Get some quick stats for the admin
        active_orders = Order.objects.filter(is_active=True)
        total_orders = active_orders.count()
        pending_count = active_orders.filter(status='PENDING').count()
        overdue_count = Order.overdue_orders().count()
        unpaid_count = Order.unpaid_orders().count()
        
        total_value = active_orders.aggregate(Sum('total_amount'))['total_amount__sum'] or 0
        total_advance = active_orders.aggregate(Sum('advance_payment'))['advance_payment__sum'] or 0
        total_remaining = active_orders.aggregate(Sum('remaining_amount'))['remaining_amount__sum'] or 0
        
        extra_context.update({
            'total_orders': total_orders,
            'pending_orders_count': pending_count,
            'overdue_orders_count': overdue_count,
            'unpaid_orders_count': unpaid_count,
            'total_order_value': total_value,
            'total_advance_received': total_advance,
            'total_remaining_amount': total_remaining,
            'payment_rate': round((total_advance / total_value * 100) if total_value > 0 else 0, 1),
        })
        
        return super().changelist_view(request, extra_context)

    def get_inline_instances(self, request, obj=None):
        """Add order items inline if order exists"""
        if obj:
            from order_items.admin import OrderItemInline
            return [OrderItemInline(self.model, self.admin_site)]
        return []


# Optional: Custom admin site title and header
admin.site.site_header = "Order Management System"
admin.site.site_title = "Order Admin"
admin.site.index_title = "Welcome to Order Management System"


# Optional: Inline for Order Items (if you want to show order items in order admin)
class OrderItemInline(admin.TabularInline):
    """Inline for showing order items within order admin"""
    from order_items.models import OrderItem
    model = OrderItem
    extra = 0
    readonly_fields = ('line_total', 'product_display_info')
    fields = ('product', 'product_name', 'quantity', 'unit_price', 'line_total', 'customization_notes')
    
    def product_display_info(self, obj):
        """Display product information"""
        if obj.product:
            return f"{obj.product.color} - {obj.product.fabric}"
        return "Product not available"
    product_display_info.short_description = 'Product Info'


# Add the inline to OrderAdmin
OrderAdmin.inlines = [OrderItemInline]
