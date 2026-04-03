import uuid
import logging
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from django.utils import timezone
from decimal import Decimal

logger = logging.getLogger(__name__)


class RentalReturn(models.Model):
    """Model for tracking equipment return after an event"""
    
    TALLY_STATUS = [
        ('PENDING', 'Pending Return'),
        ('PARTIAL', 'Partially Returned'),
        ('COMPLETE', 'Fully Returned'),
    ]
    
    RESPONSIBILITY_CHOICES = [
        ('CUSTOMER', 'Customer Side'),
        ('INTERNAL', 'Internal / Staff'),
        ('NONE', 'None'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.OneToOneField('orders.Order', on_delete=models.CASCADE, related_name='rental_return')
    
    return_date = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=TALLY_STATUS, default='PENDING')
    
    responsibility = models.CharField(max_length=20, choices=RESPONSIBILITY_CHOICES, default='NONE')
    damage_charges = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    damage_recovered = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'),
        help_text="Total amount recovered for damages")
    
    notes = models.TextField(blank=True, null=True)
    
    # Counts for quick reference
    total_items_sent = models.PositiveIntegerField(default=0, help_text="Total item quantity sent to event")
    total_items_returned = models.PositiveIntegerField(default=0, help_text="Total items returned in good condition")
    total_items_damaged = models.PositiveIntegerField(default=0)
    total_items_missing = models.PositiveIntegerField(default=0)
    
    is_stock_restored = models.BooleanField(default=False, help_text="Whether owned stock has been restored")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    processed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )

    class Meta:
        db_table = 'rental_return'
        ordering = ['-return_date']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['order']),
            models.Index(fields=['return_date']),
        ]

    def __str__(self):
        return f"Return for Order {self.order.id} ({self.get_status_display()})"

    def update_totals(self):
        """Recalculate totals from items"""
        items = self.items.all()
        self.total_items_sent = sum(item.qty_sent for item in items)
        self.total_items_returned = sum(item.qty_returned for item in items)
        self.total_items_damaged = sum(item.qty_damaged for item in items)
        self.total_items_missing = sum(item.qty_missing for item in items)
        self.damage_charges = sum(item.damage_charge for item in items)
    
    def update_status(self):
        """Auto-calculate status based on tallied items"""
        items = self.items.all()
        if not items.exists():
            self.status = 'PENDING'
            return
        
        all_tallied = all(
            (item.qty_returned + item.qty_damaged + item.qty_missing) == item.qty_sent
            for item in items
        )
        any_tallied = any(
            (item.qty_returned + item.qty_damaged + item.qty_missing) > 0
            for item in items
        )
        
        if all_tallied:
            self.status = 'COMPLETE'
        elif any_tallied:
            self.status = 'PARTIAL'
        else:
            self.status = 'PENDING'
    
    def restore_stock(self, user=None):
        """
        Restore owned inventory items back to stock.
        Only items that are:
        - Owned by us (not rented from partner)
        - Returned in good condition
        are added back to stock.
        Damaged items update quantity_damaged.
        Missing items permanently reduce stock.
        """
        if self.is_stock_restored:
            raise ValidationError("Stock has already been restored for this return.")
        
        from products.models import Product, StockChangeLog, StockReservation
        
        for item in self.items.all():
            product = item.product
            
            # Check if this was our own item or rented from partner
            is_partner_item = item.is_partner_item
            
            if is_partner_item:
                # Partner items — don't add back to our stock
                logger.info(f"Skipping stock restore for partner item: {product.name}")
                continue
            
            if product.is_rental and not product.is_consumable:
                # Deactivate the reservation for this order
                StockReservation.objects.filter(
                    sale_id=f"ORDER_{self.order.id}",
                    product=product,
                    is_active=True
                ).update(is_active=False, updated_at=timezone.now())

                old_quantity = product.quantity
                old_damaged = product.quantity_damaged
                
                # We DO NOT add to product.quantity for regular returns 
                # because it was never subtracted (only reserved).
                
                # Track damaged items
                if item.qty_damaged > 0:
                    product.quantity_damaged += item.qty_damaged
                
                # Missing items = permanent loss. Subtract from total quantity.
                if item.qty_missing > 0:
                    product.quantity = max(0, product.quantity - item.qty_missing)
                
                product.save(update_fields=['quantity', 'quantity_damaged', 'updated_at'])
                product.update_available_quantity() # This will recalculate based on remaining reservations
                
                # Log the stock change
                StockChangeLog.objects.create(
                    product=product,
                    old_quantity=old_quantity,
                    new_quantity=product.quantity,
                    change_type='RETURN',
                    reason=f'Return tally for Order {self.order.id}: '
                           f'{item.qty_returned} good, {item.qty_damaged} damaged, '
                           f'{item.qty_missing} missing',
                    changed_by=user or self.processed_by
                )
                
                logger.info(
                    f"Stock processed for {product.name}: "
                    f"Reservation cleared, "
                    f"+{item.qty_damaged} damaged, "
                    f"-{item.qty_missing} missing"
                )
        
        self.is_stock_restored = True
        RentalReturn.objects.filter(id=self.id).update(
            is_stock_restored=True, updated_at=timezone.now()
        )
    
    def _get_order_item(self, product):
        """Get the order item for a given product in this return's order"""
        from order_items.models import OrderItem
        try:
            return OrderItem.objects.get(
                order=self.order,
                product=product,
                is_active=True
            )
        except OrderItem.DoesNotExist:
            return None

    @property
    def damage_balance(self):
        """Unrecovered damage charges"""
        return max(Decimal('0.00'), self.damage_charges - self.damage_recovered)
    
    @property
    def is_fully_recovered(self):
        """Whether all damage charges have been recovered"""
        return self.damage_balance <= Decimal('0.00')
    
    @classmethod
    def get_statistics(cls):
        """Get return statistics"""
        from django.db.models import Sum, Count
        returns = cls.objects.all()
        
        return {
            'total_returns': returns.count(),
            'pending': returns.filter(status='PENDING').count(),
            'partial': returns.filter(status='PARTIAL').count(),
            'complete': returns.filter(status='COMPLETE').count(),
            'total_damage_charges': float(
                returns.aggregate(total=Sum('damage_charges'))['total'] or 0
            ),
            'total_recovered': float(
                returns.aggregate(total=Sum('damage_recovered'))['total'] or 0
            ),
            'total_items_damaged': returns.aggregate(
                total=Sum('total_items_damaged')
            )['total'] or 0,
            'total_items_missing': returns.aggregate(
                total=Sum('total_items_missing')
            )['total'] or 0,
        }


class RentalReturnItem(models.Model):
    """Individual item tally within a rental return"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    rental_return = models.ForeignKey(RentalReturn, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey('products.Product', on_delete=models.PROTECT)
    
    qty_sent = models.PositiveIntegerField(help_text="Quantity sent to event")
    qty_returned = models.PositiveIntegerField(default=0, help_text="Quantity returned in good condition")
    qty_damaged = models.PositiveIntegerField(default=0)
    qty_missing = models.PositiveIntegerField(default=0)
    
    # Damage charge per item
    damage_charge = models.DecimalField(
        max_digits=12, decimal_places=2, default=Decimal('0.00'),
        help_text="Charge for damaged/missing items"
    )
    
    condition_notes = models.TextField(blank=True, null=True)
    is_partner_item = models.BooleanField(default=False)
    
    class Meta:
        db_table = 'rental_return_item'
        unique_together = [('rental_return', 'product', 'is_partner_item')]

    def clean(self):
        """Validate that tallied quantities don't exceed sent quantity"""
        total_accounted = self.qty_returned + self.qty_damaged + self.qty_missing
        if total_accounted > self.qty_sent:
            raise ValidationError(
                f"Total accounted ({total_accounted}) cannot exceed quantity sent ({self.qty_sent})"
            )
    
    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.product.name}: {self.qty_returned}/{self.qty_sent} returned"


class DamageRecovery(models.Model):
    """Track recovery actions for damage charges"""
    
    RECOVERY_TYPE_CHOICES = [
        ('CUSTOMER_DEDUCTION', 'Deducted from Customer Payment'),
        ('CUSTOMER_PAYMENT', 'Separate Customer Payment'),
        ('INSURANCE', 'Insurance Claim'),
        ('STAFF_DEDUCTION', 'Deducted from Staff Salary'),
        ('WRITE_OFF', 'Written Off'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    rental_return = models.ForeignKey(RentalReturn, on_delete=models.CASCADE, related_name='recoveries')
    
    recovery_type = models.CharField(max_length=30, choices=RECOVERY_TYPE_CHOICES)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    
    notes = models.TextField(blank=True, null=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True, blank=True
    )
    
    class Meta:
        db_table = 'damage_recovery'
        ordering = ['-created_at']
    
    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        # Update total recovered on parent
        from django.db.models import Sum
        total = self.rental_return.recoveries.aggregate(
            total=Sum('amount')
        )['total'] or Decimal('0.00')
        RentalReturn.objects.filter(id=self.rental_return_id).update(
            damage_recovered=total, updated_at=timezone.now()
        )
    
    def __str__(self):
        return f"{self.get_recovery_type_display()}: PKR {self.amount}"
