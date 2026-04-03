import uuid
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from django.utils import timezone
from decimal import Decimal
from datetime import timedelta, date


class Order(models.Model):
    """Order model for managing customer orders"""
    
    # Order Status Choices
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('CONFIRMED', 'Confirmed'),
        ('READY', 'Ready for Delivery'),
        ('DELIVERED', 'Delivered'),
        ('RETURNED', 'Returned'),
        ('CANCELLED', 'Cancelled'),
    ]
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    customer = models.ForeignKey(
        'customers.Customer',
        on_delete=models.PROTECT,
        related_name='orders',
        help_text="Customer who placed the order"
    )
    # Cached customer information for performance and data integrity
    customer_name = models.CharField(
        max_length=200,
        help_text="Cached customer name at time of order"
    )
    customer_phone = models.CharField(
        max_length=20,
        help_text="Cached customer phone at time of order"
    )
    customer_email = models.EmailField(
        blank=True,
        help_text="Cached customer email at time of order"
    )
    advance_payment = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Amount paid in advance"
    )
    total_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total order amount (calculated from order items)"
    )
    remaining_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Remaining amount to be paid"
    )
    is_fully_paid = models.BooleanField(
        default=False,
        help_text="Whether the order is fully paid"
    )
    date_ordered = models.DateField(
        default=timezone.now,
        help_text="Date when order was placed"
    )
    expected_delivery_date = models.DateField(
        null=True,
        blank=True,
        help_text="Expected delivery date"
    )
    description = models.TextField(
        blank=True,
        help_text="Order description and notes"
    )
    # Event Details for Rental Business
    event_name = models.CharField(
        max_length=200,
        blank=True,
        null=True,
        help_text="Event Name (e.g. Wedding of X)"
    )
    event_location = models.CharField(
        max_length=500,
        blank=True,
        null=True,
        help_text="Event Venue/Location"
    )
    event_date = models.DateField(
        null=True,
        blank=True,
        help_text="Date of the event"
    )
    return_date = models.DateField(
        null=True,
        blank=True,
        help_text="Expected return date of items"
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='PENDING',
        help_text="Current order status"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Used for soft deletion"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_orders',
        help_text="User who created this order"
    )

    # Enhanced Sales Integration Fields
    conversion_status = models.CharField(
        max_length=20,
        choices=[
            ('NOT_CONVERTED', 'Not Converted'),
            ('PARTIALLY_CONVERTED', 'Partially Converted'),
            ('FULLY_CONVERTED', 'Fully Converted'),
        ],
        default='NOT_CONVERTED',
        help_text="Status of order conversion to sales"
    )
    
    converted_sales_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total amount converted to sales"
    )
    
    conversion_date = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Date when order was first converted to sale"
    )

    class Meta:
        db_table = 'order'
        verbose_name = 'Order'
        verbose_name_plural = 'Orders'
        ordering = ['-date_ordered', '-created_at']
        indexes = [
            models.Index(fields=['customer']),
            models.Index(fields=['status']),
            models.Index(fields=['date_ordered']),
            models.Index(fields=['expected_delivery_date']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
            models.Index(fields=['is_fully_paid']),
            models.Index(fields=['conversion_status']),
            models.Index(fields=['conversion_date']),
        ]

    def __str__(self):
        return f"Order #{self.id} - {self.customer_name} ({self.get_status_display()})"

    def clean(self):
        """Validate model data"""
        if self.advance_payment and self.advance_payment < 0:
            raise ValidationError({'advance_payment': 'Advance payment cannot be negative.'})
        
        if self.total_amount and self.total_amount < 0:
            raise ValidationError({'total_amount': 'Total amount cannot be negative.'})
        
        if self.advance_payment and self.total_amount and self.advance_payment > self.total_amount:
            raise ValidationError({
                'advance_payment': 'Advance payment cannot be greater than total amount.'
            })
        
        # Validate delivery date
        if self.expected_delivery_date and self.expected_delivery_date < self.date_ordered:
            raise ValidationError({
                'expected_delivery_date': 'Expected delivery date cannot be before order date.'
            })
        
    def can_be_converted_to_sale(self):
        """Check if order can be converted to sale"""
        return self.status in ['CONFIRMED', 'READY', 'DELIVERED'] and self.is_active

    def get_related_sales(self):
        """Get sales created from this order"""
        return self.sales.filter(is_active=True)

    def has_been_converted_to_sale(self):
        """Check if order has been converted to any sales"""
        return self.sales.exists()

    # Enhanced Sales Integration Methods
    @property
    def conversion_percentage(self):
        """Get percentage of order converted to sales"""
        total = self.total_amount or Decimal('0.00')
        converted = self.converted_sales_amount or Decimal('0.00')
        if total == 0:
            return 100.0
        return float((converted / total) * 100)

    def update_conversion_status(self):
        """Update conversion status based on related sales"""
        from django.db.models import Sum
        
        # Prevent recursion by checking if we're already updating conversion status
        if hasattr(self, '_updating_conversion_status'):
            return
        
        # Mark that we're updating conversion status
        self._updating_conversion_status = True
        
        try:
            if not self.has_been_converted_to_sale():
                self.conversion_status = 'NOT_CONVERTED'
                self.converted_sales_amount = Decimal('0.00')
                self.conversion_date = None
            else:
                # Calculate total converted amount
                total_converted = self.sales.filter(is_active=True).aggregate(
                    total=Sum('grand_total')
                )['total'] or Decimal('0.00')
                
                self.converted_sales_amount = total_converted
                
                if total_converted >= self.total_amount:
                    self.conversion_status = 'FULLY_CONVERTED'
                else:
                    self.conversion_status = 'PARTIALLY_CONVERTED'
                
                # Set conversion date if not set
                if not self.conversion_date:
                    first_sale = self.sales.filter(is_active=True).order_by('created_at').first()
                    if first_sale:
                        self.conversion_date = first_sale.created_at
            
            # Use update() instead of save() to avoid triggering signals
            Order.objects.filter(id=self.id).update(
                conversion_status=self.conversion_status,
                converted_sales_amount=self.converted_sales_amount,
                conversion_date=self.conversion_date,
                updated_at=timezone.now()
            )
        finally:
            # Always remove the updating flag
            if hasattr(self, '_updating_conversion_status'):
                delattr(self, '_updating_conversion_status')

    def get_conversion_summary(self):
        """Get summary of order conversion to sales"""
        related_sales = self.get_related_sales()
        
        # Get the actual conversion status from the field
        actual_status = self.conversion_status
        
        return {
            'conversion_status': actual_status,
            'conversion_percentage': self.conversion_percentage,
            'converted_amount': float(self.converted_sales_amount or Decimal('0.00')),
            'remaining_amount': float((self.total_amount or Decimal('0.00')) - (self.converted_sales_amount or Decimal('0.00'))),
            'related_sales_count': related_sales.count(),
            'conversion_date': self.conversion_date,
            'can_convert_more': self.can_be_converted_to_sale() and actual_status != 'FULLY_CONVERTED',
        }

    def save(self, *args, **kwargs):
        # Prevent recursion by checking if we're already saving
        if hasattr(self, '_saving_order'):
            super().save(*args, **kwargs)
            return
        
        # Mark that we're saving
        self._saving_order = True
        
        try:
            # Auto-populate customer information if not set
            if self.customer and not self.customer_name:
                self.customer_name = self.customer.name
                self.customer_phone = self.customer.phone
                self.customer_email = self.customer.email or ''
            
            # Ensure date_ordered is set and is a date object
            if not self.date_ordered:
                self.date_ordered = timezone.now().date()
            elif hasattr(self.date_ordered, 'date'):
                self.date_ordered = self.date_ordered.date()
            
            # Calculate remaining amount and payment status
            self.calculate_payment_status()
            
            self.full_clean()
            super().save(*args, **kwargs)
            
            # Update conversion status after save (but only if not already updating)
            if not hasattr(self, '_updating_conversion_status'):
                self.update_conversion_status()
        finally:
            # Always remove the saving flag
            if hasattr(self, '_saving_order'):
                delattr(self, '_saving_order')

    # Properties
    @property
    def days_since_ordered(self):
        """Get number of days since order was placed"""
        if not self.date_ordered:
            return 0
        today = timezone.now().date()
        
        # Ensure date_ordered is a date object
        if hasattr(self.date_ordered, 'date'):
            order_date = self.date_ordered.date()
        else:
            order_date = self.date_ordered
            
        return (today - order_date).days

    @property
    def days_until_delivery(self):
        """Get number of days until expected delivery"""
        if not self.expected_delivery_date:
            return None
        today = timezone.now().date()
        
        # Ensure expected_delivery_date is a date object
        if hasattr(self.expected_delivery_date, 'date'):
            delivery_date = self.expected_delivery_date.date()
        else:
            delivery_date = self.expected_delivery_date
            
        return (delivery_date - today).days

    @property
    def is_overdue(self):
        """Check if order is overdue for delivery"""
        if not self.expected_delivery_date:
            return False
        today = timezone.now().date()
        
        # Ensure expected_delivery_date is a date object
        if hasattr(self.expected_delivery_date, 'date'):
            delivery_date = self.expected_delivery_date.date()
        else:
            delivery_date = self.expected_delivery_date
            
        return today > delivery_date and self.status not in ['DELIVERED', 'RETURNED', 'CANCELLED']

    @property
    def payment_percentage(self):
        """Get payment completion percentage"""
        total = self.total_amount or Decimal('0.00')
        advance = self.advance_payment or Decimal('0.00')
        if total == 0:
            return 100.0
        return float((advance / total) * 100)

    @property
    def order_summary(self):
        """Get order summary information"""
        active_items = self.order_items.filter(is_active=True).select_related('product', 'product__category')
        items_list = []
        for item in active_items:
            items_list.append({
                'product_name': item.product_name,
                'category': item.product.category.name if item.product and item.product.category else '',
                'quantity': item.quantity,
                'rate': float(item.rate),
                'line_total': float(item.line_total),
            })
        return {
            'total_items': len(items_list),
            'total_quantity': sum(item['quantity'] for item in items_list),
            'items_list': items_list,
            'payment_status': 'Fully Paid' if self.is_fully_paid else f'{self.payment_percentage:.1f}% Paid',
            'days_since_ordered': self.days_since_ordered,
            'delivery_status': self.get_delivery_status()
        }

    def get_delivery_status(self):
        """Get human-readable delivery status"""
        if self.status == 'DELIVERED':
            return 'Delivered'
        elif self.status == 'RETURNED':
            return 'Returned'
        elif self.status == 'CANCELLED':
            return 'Cancelled'
        elif not self.expected_delivery_date:
            return 'No delivery date set'
        elif self.is_overdue:
            return f'Overdue by {abs(self.days_until_delivery)} days'
        elif self.days_until_delivery == 0:
            return 'Due today'
        elif self.days_until_delivery > 0:
            return f'Due in {self.days_until_delivery} days'
        else:
            return 'Past due'

    # Helper methods
    def calculate_totals(self):
        """Calculate and update order totals from order items"""
        from order_items.models import OrderItem
        
        # Prevent recursion by checking if we're already calculating
        if hasattr(self, '_calculating_totals'):
            return self.total_amount
        
        # Mark that we're calculating totals
        self._calculating_totals = True
        
        try:
            # Use select_related to optimize the query and avoid N+1 queries
            total = OrderItem.objects.filter(
                order=self,
                is_active=True
            ).aggregate(
                total=models.Sum('line_total')
            )['total'] or Decimal('0.00')
            
            self.total_amount = total
            self.calculate_payment_status()
            
            # Use save(update_fields) instead of update() so signals fire
            self.save(update_fields=['total_amount', 'remaining_amount', 'is_fully_paid', 'updated_at'])
            
            return total
        except Exception as e:
            # Log the error but don't fail the operation
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error calculating totals for order {self.id}: {str(e)}")
            return self.total_amount or Decimal('0.00')
        finally:
            # Always remove the calculating flag
            if hasattr(self, '_calculating_totals'):
                delattr(self, '_calculating_totals')

    def calculate_payment_status(self):
        """Calculate remaining amount and payment status"""
        total = self.total_amount or Decimal('0.00')
        advance = self.advance_payment or Decimal('0.00')
        self.remaining_amount = max(Decimal('0.00'), total - advance)
        self.is_fully_paid = self.remaining_amount == 0 and total > 0

    def add_payment(self, amount):
        """Add payment to the order"""
        if amount <= 0:
            raise ValidationError("Payment amount must be positive.")
        
        # Prevent recursion by checking if we're already processing payment
        if hasattr(self, '_processing_payment'):
            return {
                'new_advance_payment': self.advance_payment,
                'remaining_amount': self.remaining_amount,
                'is_fully_paid': self.is_fully_paid
            }
        
        # Mark that we're processing payment
        self._processing_payment = True
        
        try:
            new_advance = self.advance_payment + amount
            if new_advance > self.total_amount:
                raise ValidationError("Payment exceeds remaining amount.")
            
            self.advance_payment = new_advance
            self.calculate_payment_status()
            
            # Use update() instead of save() to avoid triggering signals
            Order.objects.filter(id=self.id).update(
                advance_payment=self.advance_payment,
                remaining_amount=self.remaining_amount,
                is_fully_paid=self.is_fully_paid,
                updated_at=timezone.now()
            )
            
            return {
                'new_advance_payment': self.advance_payment,
                'remaining_amount': self.remaining_amount,
                'is_fully_paid': self.is_fully_paid
            }
        finally:
            # Always remove the processing flag
            if hasattr(self, '_processing_payment'):
                delattr(self, '_processing_payment')

    def update_status(self, new_status, notes=None):
        """Update order status with optional notes"""
        if new_status not in dict(self.STATUS_CHOICES):
            raise ValidationError("Invalid status.")
        
        # Prevent recursion by checking if we're already updating status
        if hasattr(self, '_updating_status'):
            return {
                'old_status': self.status,
                'new_status': new_status
            }
        
        # Mark that we're updating status
        self._updating_status = True
        
        try:
            old_status = self.status
            self.status = new_status
            
            # Auto-update delivery date if status changes to delivered
            if new_status == 'DELIVERED' and old_status != 'DELIVERED':
                if not self.expected_delivery_date:
                    self.expected_delivery_date = timezone.now().date()
            
            if notes:
                desc = self.description or ""
                self.description = desc + f"\nStatus updated to {self.get_status_display()}: {notes}"
            
            # Use save(update_fields) instead of update() so signals fire
            self.save(update_fields=['status', 'description', 'expected_delivery_date', 'updated_at'])
            
            return {
                'old_status': old_status,
                'new_status': new_status
            }
        finally:
            # Always remove the updating flag
            if hasattr(self, '_updating_status'):
                delattr(self, '_updating_status')

    def soft_delete(self):
        """Soft delete the order"""
        # Prevent recursion by checking if we're already processing
        if hasattr(self, '_processing_soft_delete'):
            return
        
        # Mark that we're processing soft delete
        self._processing_soft_delete = True
        
        try:
            self.is_active = False
            
            # Use save(update_fields) instead of update() so signals fire
            self.save(update_fields=['is_active', 'updated_at'])
        finally:
            # Always remove the processing flag
            if hasattr(self, '_processing_soft_delete'):
                delattr(self, '_processing_soft_delete')

    def restore(self):
        """Restore a soft-deleted order"""
        # Prevent recursion by checking if we're already processing
        if hasattr(self, '_processing_restore'):
            return
        
        # Mark that we're processing restore
        self._processing_restore = True
        
        try:
            self.is_active = True
            
            # Use save(update_fields) instead of update() so signals fire
            self.save(update_fields=['is_active', 'updated_at'])
        finally:
            # Always remove the processing flag
            if hasattr(self, '_processing_restore'):
                delattr(self, '_processing_restore')

    def get_order_items(self):
        """Get active order items"""
        return self.order_items.filter(is_active=True)

    def can_be_cancelled(self):
        """Check if order can be cancelled"""
        return self.status not in ['DELIVERED', 'RETURNED', 'CANCELLED']

    def can_be_modified(self):
        """Check if order can be modified"""
        return self.status in ['PENDING', 'CONFIRMED', 'READY']

    # Class methods
    @classmethod
    def active_orders(cls):
        """Return only active orders"""
        return cls.objects.filter(is_active=True)

    @classmethod
    def orders_by_status(cls, status):
        """Get orders by status"""
        return cls.active_orders().filter(status=status.upper())

    @classmethod
    def orders_by_customer(cls, customer_id):
        """Get orders by customer"""
        return cls.active_orders().filter(customer_id=customer_id)

    @classmethod
    def pending_orders(cls):
        """Get pending orders"""
        return cls.orders_by_status('PENDING')

    @classmethod
    def overdue_orders(cls):
        """Get overdue orders"""
        today = timezone.now().date()
        return cls.active_orders().filter(
            expected_delivery_date__lt=today,
            status__in=['PENDING', 'CONFIRMED', 'READY']
        )

    @classmethod
    def orders_due_today(cls):
        """Get orders due today"""
        today = timezone.now().date()
        return cls.active_orders().filter(
            expected_delivery_date=today,
            status__in=['PENDING', 'CONFIRMED', 'READY']
        )

    @classmethod
    def recent_orders(cls, days=7):
        """Get recently created orders"""
        cutoff_date = timezone.now().date() - timedelta(days=days)
        return cls.active_orders().filter(date_ordered__gte=cutoff_date)

    @classmethod
    def unpaid_orders(cls):
        """Get orders that are not fully paid"""
        return cls.active_orders().filter(is_fully_paid=False, total_amount__gt=0)

    @classmethod
    def get_statistics(cls):
        """Get comprehensive order statistics"""
        from django.db.models import Sum, Count, Avg
        
        active_orders = cls.active_orders()
        total_orders = active_orders.count()
        
        # Status breakdown
        status_breakdown = {}
        for status, _ in cls.STATUS_CHOICES:
            status_breakdown[status.lower()] = active_orders.filter(status=status).count()
        
        # Financial stats
        total_value = active_orders.aggregate(Sum('total_amount'))['total_amount__sum'] or Decimal('0.00')
        total_advance = active_orders.aggregate(Sum('advance_payment'))['advance_payment__sum'] or Decimal('0.00')
        total_remaining = active_orders.aggregate(Sum('remaining_amount'))['remaining_amount__sum'] or Decimal('0.00')
        
        average_order_value = active_orders.aggregate(Avg('total_amount'))['total_amount__avg'] or Decimal('0.00')
        
        # Payment stats
        fully_paid_count = active_orders.filter(is_fully_paid=True).count()
        unpaid_count = active_orders.filter(is_fully_paid=False, total_amount__gt=0).count()
        
        # Delivery stats
        overdue_count = cls.overdue_orders().count()
        due_today_count = cls.orders_due_today().count()
        
        # Recent activity
        recent_orders_count = cls.recent_orders().count()
        recent_orders_this_month = cls.recent_orders(30).count()
        
        return {
            'total_orders': total_orders,
            'status_breakdown': status_breakdown,
            'financial_summary': {
                'total_value': float(total_value),
                'total_advance_received': float(total_advance),
                'total_remaining': float(total_remaining),
                'average_order_value': float(average_order_value),
            },
            'payment_summary': {
                'fully_paid_orders': fully_paid_count,
                'unpaid_orders': unpaid_count,
                'payment_rate': round((fully_paid_count / total_orders * 100) if total_orders > 0 else 0, 2)
            },
            'delivery_summary': {
                'overdue_orders': overdue_count,
                'due_today': due_today_count,
                'on_time_rate': round(((total_orders - overdue_count) / total_orders * 100) if total_orders > 0 else 0, 2)
            },
            'recent_activity': {
                'orders_this_week': recent_orders_count,
                'orders_this_month': recent_orders_this_month,
            }
        }


class OrderQuerySet(models.QuerySet):
    """Custom QuerySet for Order model"""
    
    def active(self):
        return self.filter(is_active=True)
    
    def by_status(self, status):
        return self.filter(status=status.upper())
    
    def by_customer(self, customer_id):
        return self.filter(customer_id=customer_id)
    
    def search(self, query):
        """Search orders by customer name, phone, email, or description"""
        return self.filter(
            models.Q(customer_name__icontains=query) |
            models.Q(customer_phone__icontains=query) |
            models.Q(customer_email__icontains=query) |
            models.Q(description__icontains=query) |
            models.Q(id__icontains=query)
        )
    
    def pending(self):
        """Get pending orders"""
        return self.filter(status='PENDING')
    
    def confirmed(self):
        """Get confirmed orders"""
        return self.filter(status='CONFIRMED')
    
    def ready_for_delivery(self):
        """Get orders ready for delivery"""
        return self.filter(status='READY')
    
    def delivered(self):
        """Get delivered orders"""
        return self.filter(status='DELIVERED')
    
    def cancelled(self):
        """Get cancelled orders"""
        return self.filter(status='CANCELLED')
    
    def overdue(self):
        """Get overdue orders"""
        today = timezone.now().date()
        return self.filter(
            expected_delivery_date__lt=today,
            status__in=['PENDING', 'CONFIRMED', 'READY']
        )
    
    def due_today(self):
        """Get orders due today"""
        today = timezone.now().date()
        return self.filter(
            expected_delivery_date=today,
            status__in=['PENDING', 'CONFIRMED', 'READY']
        )
    
    def due_this_week(self):
        """Get orders due this week"""
        today = timezone.now().date()
        week_end = today + timedelta(days=7)
        return self.filter(
            expected_delivery_date__range=[today, week_end],
            status__in=['PENDING', 'CONFIRMED', 'READY']
        )
    
    def fully_paid(self):
        """Get fully paid orders"""
        return self.filter(is_fully_paid=True)
    
    def unpaid(self):
        """Get unpaid orders"""
        return self.filter(is_fully_paid=False, total_amount__gt=0)
    
    def partially_paid(self):
        """Get partially paid orders"""
        return self.filter(
            advance_payment__gt=0,
            is_fully_paid=False,
            total_amount__gt=0
        )
    
    def date_range(self, start_date, end_date):
        """Filter orders by date range"""
        return self.filter(date_ordered__range=[start_date, end_date])
    
    def this_month(self):
        """Get orders from this month"""
        today = timezone.now().date()
        start_of_month = today.replace(day=1)
        return self.filter(date_ordered__gte=start_of_month)
    
    def this_week(self):
        """Get orders from this week"""
        today = timezone.now().date()
        start_of_week = today - timedelta(days=today.weekday())
        return self.filter(date_ordered__gte=start_of_week)
    
    def value_range(self, min_value=None, max_value=None):
        """Filter orders by total amount range"""
        queryset = self
        if min_value is not None:
            queryset = queryset.filter(total_amount__gte=min_value)
        if max_value is not None:
            queryset = queryset.filter(total_amount__lte=max_value)
        return queryset


# Add the custom manager to the Order model
Order.add_to_class('objects', models.Manager.from_queryset(OrderQuerySet)())
