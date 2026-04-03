import uuid
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from decimal import Decimal


class OrderItemQuerySet(models.QuerySet):
    """Custom QuerySet for OrderItem model"""
    
    def active(self):
        return self.filter(is_active=True)
    
    def by_order(self, order_id):
        return self.filter(order_id=order_id)
    
    def by_product(self, product_id):
        return self.filter(product_id=product_id)
    
    def search(self, query):
        """Search order items by product name or customization notes"""
        return self.filter(
            models.Q(product_name__icontains=query) |
            models.Q(customization_notes__icontains=query) |
            models.Q(product__name__icontains=query) |
            models.Q(product__color__icontains=query) |
            models.Q(product__fabric__icontains=query)
        )
    
    def quantity_range(self, min_quantity=None, max_quantity=None):
        """Filter by quantity range"""
        queryset = self
        if min_quantity is not None:
            queryset = queryset.filter(quantity__gte=min_quantity)
        if max_quantity is not None:
            queryset = queryset.filter(quantity__lte=max_quantity)
        return queryset
    
    def price_range(self, min_price=None, max_price=None):
        """Filter by rate range"""
        queryset = self
        if min_price is not None:
            queryset = queryset.filter(rate__gte=min_price)
        if max_price is not None:
            queryset = queryset.filter(rate__lte=max_price)
        return queryset
    
    def with_customization(self):
        """Filter items that have customization notes"""
        return self.exclude(customization_notes='')
    
    def without_customization(self):
        """Filter items that don't have customization notes"""
        return self.filter(customization_notes='')


class OrderItemManager(models.Manager):
    """Custom manager for OrderItem model"""
    
    def get_queryset(self):
        return OrderItemQuerySet(self.model, using=self._db)
    
    def active(self):
        return self.get_queryset().active()
    
    def by_order(self, order_id):
        return self.get_queryset().by_order(order_id)
    
    def by_product(self, product_id):
        return self.get_queryset().by_product(product_id)
    
    def search(self, query):
        """Search order items by product name or customization notes"""
        return self.get_queryset().search(query)
    
    def quantity_range(self, min_quantity=None, max_quantity=None):
        """Filter by quantity range"""
        return self.get_queryset().quantity_range(min_quantity, max_quantity)
    
    def price_range(self, min_price=None, max_price=None):
        """Filter by rate range"""
        return self.get_queryset().price_range(min_price, max_price)
    
    def with_customization(self):
        """Filter items that have customization notes"""
        return self.get_queryset().with_customization()
    
    def without_customization(self):
        """Filter items that don't have customization notes"""
        return self.get_queryset().without_customization()


class OrderItem(models.Model):
    """Order Item model for managing individual products within orders"""
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    order = models.ForeignKey(
        'orders.Order',
        on_delete=models.CASCADE,
        related_name='order_items',
        help_text="Parent order"
    )
    product = models.ForeignKey(
        'products.Product',
        on_delete=models.PROTECT,
        related_name='order_items',
        null=True,
        blank=True,
        help_text="Product being ordered (optional for manual entries)"
    )
    product_name = models.CharField(
        max_length=200,
        help_text="Cached product name at time of order"
    )
    quantity = models.PositiveIntegerField(
        help_text="Quantity of this product ordered"
    )
    rate = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Rate per unit/day at time of order"
    )
    days = models.PositiveIntegerField(
        default=1,
        help_text="Number of days for rental"
    )
    customization_notes = models.TextField(
        blank=True,
        help_text="Special instructions or customization notes for this item"
    )
    # Partner/Sub-rental fields
    rented_from_partner = models.BooleanField(
        default=False,
        help_text="Whether this item is rented from a partner"
    )
    PRICING_TYPE_CHOICES = [
        ('PER_DAY', 'Per Day'),
        ('PER_EVENT', 'Per Event'),
        ('FIXED', 'Fixed Price'),
    ]
    pricing_type = models.CharField(
        max_length=20, 
        choices=PRICING_TYPE_CHOICES, 
        default='PER_DAY',
        help_text="Pricing model for this item"
    )
    partner = models.ForeignKey(
        'vendors.Vendor',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='partner_rentals',
        help_text="Partner from whom this item is rented"
    )
    partner_rate = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Rate charged by the partner"
    )
    line_total = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        help_text="Calculated total for this line item"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Used for soft deletion"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'order_item'
        verbose_name = 'Order Item'
        verbose_name_plural = 'Order Items'
        ordering = ['order', 'created_at']
        indexes = [
            models.Index(fields=['order']),
            models.Index(fields=['product']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
            models.Index(fields=['order', 'is_active']),  # Composite index for common query pattern
            models.Index(fields=['product', 'is_active']),  # Composite index for product queries
        ]
        # Removed unique_together = [('order', 'product')] to support multiple manual items with product=None

    # Custom manager
    objects = OrderItemManager()

    def __str__(self):
        return f"{self.product_name} x{self.quantity} in Order #{self.order.id}"

    def clean(self):
        """Validate model data"""
        if self.quantity and self.quantity <= 0:
            raise ValidationError({'quantity': 'Quantity must be greater than zero.'})
        
        if self.rate and self.rate < 0:
            raise ValidationError({'rate': 'Rate cannot be negative.'})
        
        if self.days and self.days <= 0:
            raise ValidationError({'days': 'Days must be greater than zero.'})
        
        # Validate line total calculation
        if self.quantity and self.rate and self.days:
            expected_total = Decimal(str(self.quantity)) * self.rate * Decimal(str(self.days))
            if self.line_total != expected_total:
                self.line_total = expected_total

    def save(self, *args, **kwargs):
        # Auto-populate product name and unit price from product if not set
        if self.product and not self.product_name:
            self.product_name = self.product.name
        
        if self.product and self.rate is None:
            self.rate = self.product.price
            
        # Inherit pricing type from product if not set
        if self.product and not self.pricing_type:
            # We need to handle the case where product might have a different name for this field
            # Check Product model again: it is 'pricing_type'
            self.pricing_type = self.product.pricing_type
        
        # Calculate line total
        if self.quantity and self.rate:
            if self.pricing_type in ['PER_EVENT', 'FIXED']:
                self.line_total = Decimal(str(self.quantity)) * self.rate
            else:
                days = self.days or 1
                self.line_total = Decimal(str(self.quantity)) * self.rate * Decimal(str(days))
        
        self.full_clean()
        super().save(*args, **kwargs)
        
        # Update parent order total
        if self.order:
            self.order.calculate_totals()

    def get_related_sale_items(self):
        """Get sale items created from this order item"""
        from sales.models import SaleItem
        return SaleItem.objects.filter(
            order_item=self.id,
            is_active=True
        )

    def has_been_sold(self):
        """Check if this order item has been converted to sales"""
        from sales.models import SaleItem
        return SaleItem.objects.filter(
            order_item=self.id,
            is_active=True
        ).exists()

    @property
    def remaining_quantity_to_sell(self):
        """Get quantity not yet converted to sales"""
        from django.db.models import Sum
        from sales.models import SaleItem
        
        sold_quantity = SaleItem.objects.filter(
            order_item=self.id,
            is_active=True
        ).aggregate(
            total=Sum('quantity')
        )['total'] or 0
        return max(0, self.quantity - sold_quantity)

    def can_create_sale_item(self, requested_quantity):
        """Check if we can create sale item with requested quantity"""
        return requested_quantity <= self.remaining_quantity_to_sell

    # Enhanced Sales Integration Properties and Methods
    @property
    def conversion_status(self):
        """Get conversion status for this order item"""
        if self.remaining_quantity_to_sell == 0:
            return 'Fully Converted'
        elif self.has_been_sold():
            return 'Partially Converted'
        else:
            return 'Not Converted'

    @property
    def conversion_percentage(self):
        """Get percentage of order item converted to sales"""
        if self.quantity == 0:
            return 100.0
        sold_quantity = self.quantity - self.remaining_quantity_to_sell
        return float((sold_quantity / self.quantity) * 100)

    def get_conversion_summary(self):
        """Get summary of order item conversion to sales"""
        related_sale_items = self.get_related_sale_items()
        
        return {
            'conversion_status': self.conversion_status,
            'conversion_percentage': self.conversion_percentage,
            'original_quantity': self.quantity,
            'sold_quantity': self.quantity - self.remaining_quantity_to_sell,
            'remaining_quantity': self.remaining_quantity_to_sell,
            'related_sale_items_count': related_sale_items.count(),
            'can_convert_more': self.remaining_quantity_to_sell > 0,
        }

    # Properties
    @property
    def total_value(self):
        """Get total value for this line item"""
        return self.line_total

    @property
    def product_display_info(self):
        """Get product display information"""
        if self.product:
            return {
                'name': self.product_name,
                'color': self.product.color,
                'fabric': self.product.fabric,
                'current_stock': self.product.quantity
            }
        return {'name': self.product_name}

    # Helper methods
    def update_quantity(self, new_quantity):
        """Update quantity and recalculate line total"""
        if new_quantity <= 0:
            raise ValidationError("Quantity must be greater than zero.")
        
        old_quantity = self.quantity
        self.quantity = new_quantity
        self.line_total = Decimal(str(self.quantity)) * self.rate * Decimal(str(self.days))
        self.save(update_fields=['quantity', 'line_total', 'updated_at'])
        
        return {
            'old_quantity': old_quantity,
            'new_quantity': new_quantity,
            'difference': new_quantity - old_quantity
        }

    def update_rate(self, new_rate):
        """Update rate and recalculate line total"""
        if new_rate < 0:
            raise ValidationError("Rate cannot be negative.")
        
        old_rate = self.rate
        self.rate = new_rate
        self.line_total = Decimal(str(self.quantity)) * self.rate * Decimal(str(self.days))
        self.save(update_fields=['rate', 'line_total', 'updated_at'])
        
        return {
            'old_price': old_rate,  # Keeping keys same for front-end compatibility if any
            'new_price': new_rate,
            'difference': new_rate - old_rate
        }

    def soft_delete(self):
        """Soft delete the order item"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])

    def restore(self):
        """Restore a soft-deleted order item"""
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])

    def can_fulfill_from_stock(self):
        """Check if current product stock can fulfill this order item"""
        if not self.product:
            return False
        return self.product.can_fulfill_quantity(self.quantity)

    # Class methods
    @classmethod
    def active_items(cls):
        """Return only active order items"""
        return cls.objects.filter(is_active=True)

    @classmethod
    def items_by_order(cls, order_id):
        """Get active order items by order"""
        return cls.active_items().filter(order_id=order_id)

    @classmethod
    def items_by_product(cls, product_id):
        """Get active order items by product"""
        return cls.active_items().filter(product_id=product_id)

    @classmethod
    def get_statistics(cls):
        """Get comprehensive order item statistics"""
        from django.db.models import Sum, Count, Avg
        
        active_items = cls.active_items()
        
        total_items = active_items.count()
        total_quantity = active_items.aggregate(Sum('quantity'))['quantity__sum'] or 0
        total_value = active_items.aggregate(Sum('line_total'))['line_total__sum'] or Decimal('0.00')
        average_quantity = active_items.aggregate(Avg('quantity'))['quantity__avg'] or 0
        average_unit_price = active_items.aggregate(Avg('rate'))['rate__avg'] or Decimal('0.00')
        
        # Top products by quantity ordered
        top_products = active_items.values(
            'product__name', 'product_name'
        ).annotate(
            total_quantity=Sum('quantity'),
            total_orders=Count('order', distinct=True),
            total_value=Sum('line_total')
        ).order_by('-total_quantity')[:10]
        
        return {
            'total_items': total_items,
            'total_quantity_ordered': total_quantity,
            'total_value': float(total_value),
            'average_quantity_per_item': round(average_quantity, 2),
            'average_rate': float(average_unit_price),
            'top_products': list(top_products),
        }



