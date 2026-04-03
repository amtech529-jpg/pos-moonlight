import uuid
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from decimal import Decimal
import json

class ProductQuerySet(models.QuerySet):
    """Custom QuerySet for Product model"""
    
    def active(self):
        return self.filter(is_active=True)
    
    def by_category(self, category_id):
        return self.filter(category_id=category_id)
    
    def search(self, query):
        """Search products by name, color, fabric, or category name"""
        return self.filter(
            models.Q(name__icontains=query) |
            models.Q(color__icontains=query) |
            models.Q(fabric__icontains=query) |
            models.Q(category__name__icontains=query)
        )
    
    def price_range(self, min_price=None, max_price=None):
        """Filter products by price range"""
        queryset = self
        if min_price is not None:
            queryset = queryset.filter(price__gte=min_price)
        if max_price is not None:
            queryset = queryset.filter(price__lte=max_price)
        return queryset
    
    def stock_level(self, level):
        """Filter by stock level"""
        if level == 'OUT_OF_STOCK':
            return self.filter(quantity=0)
        elif level == 'LOW_STOCK':
            return self.filter(quantity__gt=0, quantity__lte=5)
        elif level == 'MEDIUM_STOCK':
            return self.filter(quantity__gt=5, quantity__lte=20)
        elif level == 'HIGH_STOCK':
            return self.filter(quantity__gt=20)
        return self

class ProductManager(models.Manager):
    def get_queryset(self):
        return ProductQuerySet(self.model, using=self._db)

    def active(self):
        return self.get_queryset().active()

    def search(self, query):
        return self.get_queryset().search(query)

    def price_range(self, min_price=None, max_price=None):
        return self.get_queryset().price_range(min_price, max_price)

    def stock_level(self, level):
        return self.get_queryset().stock_level(level)


class Product(models.Model):
    """Product model for inventory management"""
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    name = models.CharField(
        max_length=200,
        help_text="Product name"
    )
    detail = models.TextField(
        help_text="Product description/details"
    )
    price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text="Product selling price in PKR"
    )
    cost_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Production/purchase cost price in PKR"
    )
    color = models.CharField(
        max_length=50,
        null=True,
        blank=True,
        help_text="Product color (optional)"
    )
    fabric = models.CharField(
        max_length=100,
        null=True,
        blank=True,
        help_text="Material/Fabric type (optional)"
    )
    pieces = models.JSONField(
        default=list,
        blank=True,
        help_text="Product components/pieces"
    )
    serial_number = models.CharField(
        max_length=100,
        unique=True,
        null=True,
        blank=True,
        help_text="Unique Tag or Serial Number for the equipment"
    )
    warehouse_location = models.CharField(
        max_length=200,
        null=True,
        blank=True,
        help_text="Physical location (e.g., Rack A, Room 2, Warehouse 1)"
    )
    pricing_type = models.CharField(
        max_length=20,
        choices=[('PER_DAY', 'Per Day'), ('PER_EVENT', 'Per Event')],
        default='PER_DAY',
        help_text="Rental pricing model"
    )
    is_rental = models.BooleanField(
        default=True,
        help_text="Whether this is a rental item (Lights, DJ) or a consumable tool"
    )
    is_consumable = models.BooleanField(
        default=False,
        help_text="Whether this is a consumable tool (Tapes, Cable Ties)"
    )
    quantity = models.PositiveIntegerField(
        default=0,
        help_text="Available quantity in stock"
    )
    # New field for available quantity (excluding reserved stock)
    quantity_available = models.PositiveIntegerField(
        default=0,
        help_text="Available quantity excluding reserved stock"
    )
    # New field for reserved quantity
    quantity_reserved = models.PositiveIntegerField(
        default=0,
        help_text="Quantity currently reserved for pending sales"
    )
    # New field for damaged quantity
    quantity_damaged = models.PositiveIntegerField(
        default=0,
        help_text="Quantity currently marked as damaged"
    )
    # New field for minimum stock threshold
    min_stock_threshold = models.PositiveIntegerField(
        default=5,
        help_text="Minimum stock level before low stock warning"
    )
    # New field for reorder point
    reorder_point = models.PositiveIntegerField(
        default=10,
        help_text="Stock level at which to reorder"
    )
    # New field for maximum stock level
    max_stock_level = models.PositiveIntegerField(
        default=100,
        help_text="Maximum stock level to maintain"
    )
    category = models.ForeignKey(
        'categories.Category',
        on_delete=models.PROTECT,
        related_name='products',
        help_text="Product category"
    )
    barcode = models.CharField(
        max_length=50,
        unique=True,
        null=True,
        blank=True,
        help_text="Product barcode (EAN-13 format)"
    )
    sku = models.CharField(
        max_length=100,
        unique=True,
        null=True,
        blank=True,
        help_text="Stock Keeping Unit identifier"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Used for soft deletion. Inactive products won't appear in lists"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_products'
    )
    objects = ProductManager()
    
    class Meta:
        db_table = 'product'
        verbose_name = 'Product'
        verbose_name_plural = 'Products'
        ordering = ['-created_at', 'name']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['category']),
            models.Index(fields=['quantity']),
            models.Index(fields=['price']),
            models.Index(fields=['barcode']),
            models.Index(fields=['sku']),
            models.Index(fields=['serial_number']),
            models.Index(fields=['warehouse_location']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        info = f" - {self.serial_number}" if self.serial_number else ""
        return f"{self.name}{info} ({self.quantity} in stock)"

    def clean(self):
        """Validate model data"""
        if self.price and self.price < 0:
            raise ValidationError({'price': 'Price/Rate cannot be negative.'})
        
        if self.cost_price and self.cost_price < 0:
            raise ValidationError({'cost_price': 'Purchase cost price cannot be negative.'})
        
        if self.quantity < 0:
            raise ValidationError({'quantity': 'Quantity cannot be negative.'})
        
        if self.is_consumable and self.is_rental:
            raise ValidationError({'is_consumable': 'Item cannot be both rental and consumable.'})

    def save(self, *args, **kwargs):
        # Auto-generate barcode if not provided
        if not self.barcode:
            import random
            # Generate EAN-13 barcode: prefix "2" + random 12 digits
            while True:
                barcode = '2' + ''.join([str(random.randint(0, 9)) for _ in range(12)])
                # Check uniqueness
                if not Product.objects.filter(barcode=barcode).exclude(pk=self.pk).exists():
                    self.barcode = barcode
                    break
        
        # Auto-generate SKU if not provided
        if not self.sku:
            # Generate SKU: PROD-{uuid_hex_first_8_chars}
            while True:
                sku = f"PROD-{uuid.uuid4().hex[:8].upper()}"
                # Check uniqueness
                if not Product.objects.filter(sku=sku).exclude(pk=self.pk).exists():
                    self.sku = sku
                    break
        
        self.full_clean()
        # Update available quantity unless explicitly provided via update_fields
        # User Confirmation: Available = Total - Damaged
        update_fields = kwargs.get('update_fields')
        if update_fields is None or 'quantity_available' not in update_fields:
            self.quantity_available = max(0, self.quantity - self.quantity_damaged)
                
        super().save(*args, **kwargs)

    def get_available_quantity_for_dates(self, start_date, end_date, exclude_order_id=None):
        """
        Calculate available quantity for a specific date range.
        Consider all active orders that overlap with this range.
        """
        from order_items.models import OrderItem
        from django.db.models import Sum

        if not self.is_rental:
            return self.quantity - self.quantity_damaged

        # Find overlapping orders
        # Overlap filter: (event_date <= end_date) AND (return_date >= start_date)
        overlapping_items = OrderItem.objects.filter(
            product=self,
            is_active=True,
            order__is_active=True,
            order__event_date__lte=end_date,
            order__return_date__gte=start_date
        ).exclude(
            order__status__in=['CANCELLED', 'RETURNED']
        )

        if exclude_order_id:
            overlapping_items = overlapping_items.exclude(order_id=exclude_order_id)

        # Total quantity booked during this period from regular orders
        total_booked = overlapping_items.aggregate(total=Sum('quantity'))['total'] or 0
        
        # Deduct items that are rented from partners (since they don't consume our stock)
        partner_booked = overlapping_items.filter(rented_from_partner=True).aggregate(total=Sum('quantity'))['total'] or 0
        booked_from_our_stock = total_booked - partner_booked

        # Available = Total Stock - Damaged - Booked from our stock (dates)
        available = self.quantity - self.quantity_damaged - booked_from_our_stock
        return max(0, available)

    @property
    def stock_status(self):
        """Get stock status based on quantity"""
        if self.quantity is None:
            return 'UNKNOWN'
        elif self.quantity == 0:
            return 'OUT_OF_STOCK'
        elif self.quantity <= 5:
            return 'LOW_STOCK'
        elif self.quantity <= 20:
            return 'MEDIUM_STOCK'
        else:
            return 'HIGH_STOCK'
        
    def update_sales_metrics(self):
        """Update sales metrics for this product"""
        try:
            # This method is called by sales signals to update product metrics
            # The metrics are already calculated via properties, so we just need to ensure
            # the product is saved to trigger any necessary updates
            self.save(update_fields=['updated_at'])
        except Exception as e:
            # Log error but don't fail the operation
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to update sales metrics for product {self.name}: {str(e)}")

    def get_total_sales_quantity(self):
        """Get total quantity sold through sales"""
        from django.db.models import Sum
        return self.sale_items.aggregate(
            total=Sum('quantity')
        )['total'] or 0

    def get_sales_revenue(self):
        """Get total revenue from sales of this product"""
        from django.db.models import Sum
        return self.sale_items.aggregate(
            total=Sum('line_total')
        )['total'] or Decimal('0.00')

    # Enhanced Sales Integration Properties and Methods
    @property
    def total_sales_quantity(self):
        """Get total quantity sold through sales"""
        from django.db.models import Sum
        return self.sale_items.aggregate(
            total=Sum('quantity')
        )['total'] or 0

    @property
    def total_sales_revenue(self):
        """Get total revenue from sales of this product"""
        from django.db.models import Sum
        return self.sale_items.aggregate(
            total=Sum('line_total')
        )['total'] or Decimal('0.00')

    @property
    def average_sale_price(self):
        """Get average sale price for this product"""
        if self.total_sales_quantity == 0:
            return Decimal('0.00')
        return self.total_sales_revenue / self.total_sales_quantity

    @property
    def sales_velocity(self):
        """Get sales velocity (units sold per day)"""
        if self.total_sales_quantity == 0:
            return 0.0
        
        # Calculate days since first sale
        first_sale = self.sale_items.filter(is_active=True).order_by('created_at').first()
        if not first_sale:
            return 0.0
        
        from django.utils import timezone
        days_since_first_sale = (timezone.now() - first_sale.created_at).days
        if days_since_first_sale == 0:
            return float(self.total_sales_quantity)
        
        return round(self.total_sales_quantity / days_since_first_sale, 2)

    @property
    def stock_turnover_ratio(self):
        """Get stock turnover ratio (sales / average inventory)"""
        if self.quantity == 0:
            return 0.0
        
        # Simple calculation: total sales / current stock
        return round(self.total_sales_quantity / self.quantity, 2)

    @property
    def profit_margin(self):
        """Calculate profit margin if cost price is available"""
        if not self.cost_price or not self.price:
            return None
        
        if self.cost_price == 0:
            return None
            
        profit = self.price - self.cost_price
        margin_percentage = (profit / self.price) * 100
        return {
            'profit_amount': profit,
            'margin_percentage': margin_percentage,
            'cost_price': self.cost_price,
            'selling_price': self.price
        }
    
    @property
    def profit_margin_percentage(self):
        """Get profit margin percentage from sales"""
        if self.total_sales_revenue == 0:
            return 0.0
        
        if self.cost_price:
            # Calculate actual profit margin based on cost price
            total_cost = self.cost_price * self.total_sales_quantity
            profit = self.total_sales_revenue - total_cost
            return round((profit / self.total_sales_revenue) * 100, 2)
        else:
            # Fallback to estimated calculation
            estimated_cost = self.total_sales_revenue * Decimal('0.8')
            profit = self.total_sales_revenue - estimated_cost
            return round((profit / self.total_sales_revenue) * 100, 2)

    def get_sales_by_period(self, days=30):
        """Get sales within specified period"""
        from django.utils import timezone
        from datetime import timedelta
        cutoff_date = timezone.now() - timedelta(days=days)
        return self.sale_items.filter(
            is_active=True,
            created_at__gte=cutoff_date
        )

    def get_sales_statistics(self):
        """Get comprehensive sales statistics for this product"""
        from django.db.models import Sum
        active_sale_items = self.sale_items.filter(is_active=True)
        
        # Sales by period
        recent_sales = self.get_sales_by_period(30)
        recent_sales_quantity = recent_sales.aggregate(
            total=Sum('quantity')
        )['total'] or 0
        recent_sales_revenue = recent_sales.aggregate(
            total=Sum('line_total')
        )['total'] or Decimal('0.00')
        
        # Top customers
        top_customers = active_sale_items.values(
            'sale__customer__name'
        ).annotate(
            total_quantity=Sum('quantity'),
            total_amount=Sum('line_total')
        ).order_by('-total_amount')[:5]
        
        return {
            'total_sales_quantity': self.total_sales_quantity,
            'total_sales_revenue': float(self.total_sales_revenue),
            'average_sale_price': float(self.average_sale_price),
            'sales_velocity': self.sales_velocity,
            'stock_turnover_ratio': self.stock_turnover_ratio,
            'profit_margin_percentage': self.profit_margin_percentage,
            'recent_activity': {
                'quantity_last_30_days': recent_sales_quantity,
                'revenue_last_30_days': float(recent_sales_revenue),
            },
            'top_customers': list(top_customers),
            'current_stock': self.quantity,
            'stock_status': self.stock_status,
        }

    def reduce_stock_for_sale(self, quantity_sold, user=None):
        """Reduce stock when product is sold"""
        if not self.can_fulfill_quantity(quantity_sold):
            raise ValidationError("Insufficient stock for sale")
        
        return self.update_quantity(
            self.quantity - quantity_sold,
            user=user
        )

    @property
    def stock_status_display(self):
        """Human readable stock status"""
        status_map = {
            'OUT_OF_STOCK': 'Out of Stock',
            'LOW_STOCK': 'Low Stock',
            'MEDIUM_STOCK': 'Medium Stock',
            'HIGH_STOCK': 'In Stock',
            'UNKNOWN': 'Unknown'
        }
        return status_map.get(self.stock_status, 'Unknown')

    @property
    def total_value(self):
        """Calculate total inventory value for this product"""
        if self.price is None:
            return Decimal('0.00')
        return self.price * self.quantity

    def soft_delete(self):
        """Soft delete the product by setting is_active to False"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])

    def restore(self):
        """Restore a soft-deleted product"""
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])

    def update_quantity(self, new_quantity, user=None):
        """Update product quantity with optional user tracking"""
        old_quantity = self.quantity
        self.quantity = new_quantity
        self.save(update_fields=['quantity', 'updated_at'])
        
        # You can extend this to log quantity changes if needed
        return {
            'old_quantity': old_quantity,
            'new_quantity': new_quantity,
            'difference': new_quantity - old_quantity
        }

    def is_low_stock(self, threshold=5):
        """Check if product is low in stock"""
        if self.quantity is None:
            return False
        return 0 < self.quantity <= threshold

    def can_fulfill_quantity(self, requested_quantity):
        """Check if we have enough stock for requested quantity"""
        if self.quantity is None:
            return False
        return self.quantity >= requested_quantity

    def update_quantity(self, new_quantity):
        """Update total quantity and sync available quantity immediately."""
        self.quantity = max(0, new_quantity)
        # Force availability to match total (minus damaged)
        self.quantity_available = max(0, self.quantity - self.quantity_damaged)
        self.quantity_reserved = 0 # RESET ANY GHOST RESERVATIONS
        self.save(update_fields=['quantity', 'quantity_available', 'quantity_reserved', 'updated_at'])

    def update_available_quantity(self):
        """Available = total - damaged. Logic confirmed by user."""
        self.quantity_available = max(0, self.quantity - self.quantity_damaged)
        self.save(update_fields=['quantity_available', 'updated_at'])

    def reserve_stock(self, quantity, sale_id, user, duration_minutes=30):
        """Reserve stock for a pending sale"""
        if not self.can_fulfill_quantity(quantity):
            raise ValidationError(f"Insufficient available stock. Available: {self.quantity_available}, Requested: {quantity}")
        
        from .models import StockReservation
        from django.utils import timezone
        from datetime import timedelta
        reservation = StockReservation.objects.create(
            product=self,
            sale_id=sale_id,
            quantity_reserved=quantity,
            reserved_until=timezone.now() + timedelta(minutes=duration_minutes),
            reserved_by=user
        )
        
        # Update available quantity
        self.update_available_quantity()
        
        return reservation

    def confirm_stock_deduction(self, sale_id):
        """
        Confirm stock reservation after sale confirmation.
        
        IMPORTANT: This does NOT reduce quantity (total stock).
        Total stock (quantity) only changes when items are physically lost/damaged.
        This only marks the reservation as confirmed and updates quantity_available.
        
        Before: quantity=15, available=10, reserved=5
        After confirming 10 more: quantity=15, available=0, reserved=15
        """
        from .models import StockReservation
        from django.utils import timezone

        reservations = StockReservation.objects.filter(
            product=self,
            sale_id=sale_id,
            is_active=True,
            is_confirmed=False
        )

        total_confirmed = 0
        for reservation in reservations:
            total_confirmed += reservation.quantity_reserved
            reservation.is_confirmed = True
            reservation.confirmed_at = timezone.now()
            reservation.save(update_fields=['is_confirmed', 'confirmed_at'])

        if total_confirmed > 0:
            # Do NOT reduce self.quantity (total). Only update available.
            # quantity_available = quantity - quantity_reserved - quantity_damaged
            self.update_available_quantity()

        return total_confirmed

    def get_stock_alerts(self):
        """Get stock alerts for this product"""
        alerts = []
        
        if self.quantity == 0:
            alerts.append({
                'level': 'CRITICAL',
                'message': 'Product is out of stock',
                'action': 'Restock immediately'
            })
        elif self.quantity <= self.min_stock_threshold:
            alerts.append({
                'level': 'WARNING',
                'message': f'Low stock: {self.quantity} remaining',
                'action': 'Consider restocking'
            })
        
        if self.quantity <= self.reorder_point:
            alerts.append({
                'level': 'INFO',
                'message': f'Stock at reorder point: {self.quantity}',
                'action': 'Place reorder'
            })
        
        return alerts

    @classmethod
    def active_products(cls):
        """Return only active products"""
        return cls.objects.filter(is_active=True)

    @classmethod
    def low_stock_products(cls, threshold=5):
        """Get products with low stock"""
        return cls.active_products().filter(
            quantity__gt=0,
            quantity__lte=threshold
        )

    @classmethod
    def out_of_stock_products(cls):
        """Get products that are out of stock"""
        return cls.active_products().filter(quantity=0)

    @classmethod
    def products_by_category(cls, category_id):
        """Get active products by category"""
        return cls.active_products().filter(category_id=category_id)

    @classmethod
    def get_statistics(cls):
        """Get inventory statistics"""
        active_products = cls.active_products()
        
        total_products = active_products.count()
        
        # Calculate total value safely
        total_value = Decimal('0.00')
        for product in active_products:
            if product.price is not None and product.quantity is not None:
                total_value += product.price * product.quantity
        
        low_stock_count = cls.low_stock_products().count()
        out_of_stock_count = cls.out_of_stock_products().count()
        
        # Category breakdown
        from django.db.models import Count, Sum, Case, When, DecimalField
        category_stats = active_products.values(
            'category__name'
        ).annotate(
            count=Count('id'),
            total_quantity=Sum('quantity'),
            total_value=Sum(
                Case(
                    When(price__isnull=False, quantity__isnull=False, 
                         then=models.F('price') * models.F('quantity')),
                    default=0,
                    output_field=DecimalField(max_digits=15, decimal_places=2)
                )
            )
        ).order_by('-count')

        return {
            'total_products': total_products,
            'total_inventory_value': float(total_value),
            'low_stock_count': low_stock_count,
            'out_of_stock_count': out_of_stock_count,
            'category_breakdown': list(category_stats),
            'stock_status_summary': {
                'in_stock': active_products.filter(quantity__gt=20).count(),
                'medium_stock': active_products.filter(quantity__gt=5, quantity__lte=20).count(),
                'low_stock': low_stock_count,
                'out_of_stock': out_of_stock_count,
            }
        }


    
class StockReservation(models.Model):
    """Model for tracking stock reservations during sales process"""
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    product = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name='stock_reservations'
    )
    sale_id = models.CharField(
        max_length=100,
        help_text="ID of the sale this reservation is for"
    )
    quantity_reserved = models.PositiveIntegerField(
        help_text="Quantity reserved for this sale"
    )
    reserved_until = models.DateTimeField(
        help_text="When this reservation expires (Legacy field, use dates for rentals)"
    )
    start_date = models.DateField(
        null=True,
        blank=True,
        help_text="Date when stock starts being busy (e.g. event_date)"
    )
    end_date = models.DateField(
        null=True,
        blank=True,
        help_text="Date when stock becomes free again (e.g. return_date)"
    )
    is_confirmed = models.BooleanField(
        default=False,
        help_text="Whether this reservation has been confirmed"
    )
    confirmed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When this reservation was confirmed"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Whether this reservation is active"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    reserved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='stock_reservations'
    )

    class Meta:
        db_table = 'stock_reservation'
        verbose_name = 'Stock Reservation'
        verbose_name_plural = 'Stock Reservations'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['product', 'is_active']),
            models.Index(fields=['sale_id', 'is_active']),
            models.Index(fields=['reserved_until']),
            models.Index(fields=['is_confirmed']),
        ]

    def __str__(self):
        return f"{self.product.name} - {self.quantity_reserved} reserved for sale {self.sale_id}"

    def is_expired(self):
        """Check if reservation has expired"""
        from django.utils import timezone
        return timezone.now() > self.reserved_until

    def extend_reservation(self, additional_minutes):
        """Extend reservation duration"""
        from datetime import timedelta
        self.reserved_until += timedelta(minutes=additional_minutes)
        self.save(update_fields=['reserved_until', 'updated_at'])

    def cancel_reservation(self):
        """Cancel this reservation"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])
        
        # Update product available quantity
        self.product.update_available_quantity()

class StockChangeLog(models.Model):
    """Model for logging all stock quantity changes"""
    
    CHANGE_TYPE_CHOICES = [
        ('SALE_CONFIRMATION', 'Sale Confirmation'),
        ('MANUAL_ADJUSTMENT', 'Manual Adjustment'),
        ('RESTOCK', 'Restock'),
        ('RETURN', 'Return'),
        ('DAMAGE', 'Damage'),
        ('BULK_UPDATE', 'Bulk Update'),
        ('SYSTEM_CORRECTION', 'System Correction'),
    ]

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    product = models.ForeignKey(
        Product,
        on_delete=models.CASCADE,
        related_name='stock_changes'
    )
    old_quantity = models.PositiveIntegerField(
        help_text="Quantity before change"
    )
    new_quantity = models.PositiveIntegerField(
        help_text="Quantity after change"
    )
    change_type = models.CharField(
        max_length=20,
        choices=CHANGE_TYPE_CHOICES,
        help_text="Type of stock change"
    )
    reason = models.TextField(
        blank=True,
        help_text="Reason for the stock change"
    )
    reference_id = models.CharField(
        max_length=100,
        blank=True,
        help_text="Reference ID (sale, order, etc.)"
    )
    changed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='stock_changes'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'stock_change_log'
        verbose_name = 'Stock Change Log'
        verbose_name_plural = 'Stock Change Logs'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['product', 'created_at']),
            models.Index(fields=['change_type', 'created_at']),
            models.Index(fields=['changed_by', 'created_at']),
        ]

    def __str__(self):
        return f"{self.product.name}: {self.old_quantity} → {self.new_quantity} ({self.change_type})"

    @property
    def quantity_difference(self):
        """Calculate the difference in quantity"""
        return self.new_quantity - self.old_quantity

    @property
    def is_increase(self):
        """Check if this was a stock increase"""
        return self.quantity_difference > 0

    @property
    def is_decrease(self):
        """Check if this was a stock decrease"""
        return self.quantity_difference < 0 
    