import uuid
import re
from decimal import Decimal
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import MinValueValidator
from django.utils import timezone
from datetime import timedelta


class PayableQuerySet(models.QuerySet):
    """Custom QuerySet for Payable model"""
    
    def active(self):
        return self.filter(is_active=True)
    
    def inactive(self):
        return self.filter(is_active=False)
    
    def fully_paid(self):
        return self.filter(is_fully_paid=True)
    
    def pending(self):
        return self.filter(is_fully_paid=False, is_active=True)
    
    def overdue(self):
        today = timezone.now().date()
        return self.filter(
            expected_repayment_date__lt=today,
            is_fully_paid=False,
            is_active=True
        )
    
    def urgent(self):
        return self.filter(priority='URGENT', is_active=True)
    
    def high_priority(self):
        return self.filter(priority__in=['HIGH', 'URGENT'], is_active=True)
    
    def by_status(self, status):
        return self.filter(status=status)
    
    def by_creditor(self, creditor_name):
        return self.filter(creditor_name__icontains=creditor_name)
    
    def by_vendor(self, vendor_id):
        return self.filter(vendor_id=vendor_id)
    
    def due_in_days(self, days):
        """Get payables due within specified days"""
        end_date = timezone.now().date() + timedelta(days=days)
        return self.filter(
            expected_repayment_date__lte=end_date,
            is_fully_paid=False,
            is_active=True
        )
    
    def recent(self, days=30):
        """Get payables created in the last N days"""
        date_threshold = timezone.now() - timedelta(days=days)
        return self.filter(date_borrowed__gte=date_threshold)
    
    def search(self, query):
        """Search payables by creditor name, reason, or notes"""
        return self.filter(
            models.Q(creditor_name__icontains=query) |
            models.Q(reason_or_item__icontains=query) |
            models.Q(notes__icontains=query) |
            models.Q(creditor_phone__icontains=query) |
            models.Q(creditor_email__icontains=query)
        )


class Payable(models.Model):
    """Payable model for managing money owed to creditors"""
    
    PRIORITY_CHOICES = [
        ('LOW', 'Low'),
        ('MEDIUM', 'Medium'),
        ('HIGH', 'High'),
        ('URGENT', 'Urgent'),
    ]
    
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('PAID', 'Paid'),
        ('OVERDUE', 'Overdue'),
        ('PARTIALLY_PAID', 'Partially Paid'),
        ('CANCELLED', 'Cancelled'),
    ]
    
    # Primary fields
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    creditor_name = models.CharField(
        max_length=200,
        help_text="Name of creditor/lender"
    )
    creditor_phone = models.CharField(
        max_length=20,
        blank=True,
        help_text="Creditor contact number"
    )
    creditor_email = models.EmailField(
        null=True,
        blank=True,
        help_text="Optional creditor email"
    )
    vendor = models.ForeignKey(
        'vendors.Vendor',  # Assuming vendor app name is 'vendors'
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payables',
        help_text="Link to vendor if creditor is a registered vendor"
    )
    purchase = models.OneToOneField(
    'purchases.Purchase',
    on_delete=models.CASCADE,
    null=True,
    blank=True,
    related_name='payable',
    help_text="Linked purchase if payable originated from a purchase"
    )
    order = models.ForeignKey(
        'orders.Order',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='partner_payables',
        help_text="Linked order if payable originated from partner rental items"
    )
    
    SOURCE_TYPE_CHOICES = [
        ('MANUAL', 'Manual Entry'),
        ('PURCHASE', 'From Purchase'),
        ('PARTNER_RENTAL', 'From Partner Rental'),
    ]
    source_type = models.CharField(
        max_length=20,
        choices=SOURCE_TYPE_CHOICES,
        default='MANUAL',
        help_text="How this payable was generated"
    )

    # Amount fields
    amount_borrowed = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Original borrowed amount"
    )
    amount_paid = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        help_text="Total amount paid so far"
    )
    
    # Description and dates
    reason_or_item = models.TextField(
        blank=True,
        default='',
        help_text="Description of what was borrowed for"
    )
    date_borrowed = models.DateField(
        help_text="When the amount was borrowed"
    )
    expected_repayment_date = models.DateField(
        help_text="When repayment is due"
    )
    
    # Calculated fields
    balance_remaining = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Calculated remaining balance"
    )
    is_fully_paid = models.BooleanField(
        default=False,
        help_text="Auto-calculated payment status"
    )
    payment_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Calculated percentage paid"
    )
    
    # Status and priority
    priority = models.CharField(
        max_length=10,
        choices=PRIORITY_CHOICES,
        default='MEDIUM'
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='ACTIVE'
    )
    
    # Additional fields
    notes = models.TextField(
        null=True,
        blank=True,
        help_text="Additional notes and payment history"
    )
    
    # System fields
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
        related_name='created_payables'
    )
    
    # Custom manager
    objects = models.Manager.from_queryset(PayableQuerySet)()
    
    class Meta:
        db_table = 'payable'
        verbose_name = 'Payable'
        verbose_name_plural = 'Payables'
        ordering = ['-created_at', '-expected_repayment_date']
        indexes = [
            models.Index(fields=['creditor_name']),
            models.Index(fields=['status']),
            models.Index(fields=['priority']),
            models.Index(fields=['is_fully_paid']),
            models.Index(fields=['expected_repayment_date']),
            models.Index(fields=['date_borrowed']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
            models.Index(fields=['vendor']),
        ]
    
    def __str__(self):
        return f"{self.creditor_name} - {self.amount_borrowed} ({self.status})"
    
    def clean(self):
        """Validate model data"""
        if self.amount_paid > self.amount_borrowed:
            raise ValidationError({
                'amount_paid': 'Amount paid cannot exceed amount borrowed.'
            })
        
        if self.expected_repayment_date and self.date_borrowed:
            if self.expected_repayment_date < self.date_borrowed:
                raise ValidationError({
                    'expected_repayment_date': 'Repayment date cannot be before borrowed date.'
                })
        
        # Clean text fields
        if self.creditor_name:
            self.creditor_name = self.creditor_name.strip()
        if self.reason_or_item:
            self.reason_or_item = self.reason_or_item.strip()
        if self.notes:
            self.notes = self.notes.strip()
    
    def save(self, *args, **kwargs):
        self.full_clean()
        self.calculate_fields()
        self.update_status()
        super().save(*args, **kwargs)
    
    def calculate_fields(self):
        """Calculate derived fields"""
        # Calculate balance remaining
        self.balance_remaining = self.amount_borrowed - self.amount_paid
        
        # Calculate payment percentage
        if self.amount_borrowed > 0:
            self.payment_percentage = (self.amount_paid / self.amount_borrowed) * 100
        else:
            self.payment_percentage = Decimal('0.00')
        
        # Update fully paid status
        self.is_fully_paid = self.balance_remaining <= Decimal('0.00')
    
    def update_status(self):
        """Update status based on payment and dates"""
        # If cancelled, don't auto-update status
        if self.status == 'CANCELLED':
            return

        if self.is_fully_paid:
            self.status = 'PAID'
        elif self.amount_paid > Decimal('0.00'):
            # If any payment is made, mark as partially paid regardless of dates
            self.status = 'PARTIALLY_PAID'
        elif self.is_overdue:
            # Only mark as overdue if NO payment has been made
            self.status = 'OVERDUE'
        else:
            self.status = 'ACTIVE'
    
    # Properties
    @property
    def days_since_borrowed(self):
        """Days since the amount was borrowed"""
        if not self.date_borrowed:
            return 0
        return (timezone.now().date() - self.date_borrowed).days
    
    @property
    def days_until_due(self):
        """Days until expected repayment date"""
        if not self.expected_repayment_date:
            return 0
        return (self.expected_repayment_date - timezone.now().date()).days
    
    @property
    def is_overdue(self):
        """Whether the payable is past due date"""
        if not self.expected_repayment_date or self.is_fully_paid:
            return False
        return timezone.now().date() > self.expected_repayment_date
    
    @property
    def repayment_status(self):
        """Human-readable payment status"""
        if self.is_fully_paid:
            return "Fully Paid"
        elif self.amount_paid > Decimal('0.00'):
            return f"Partially Paid ({self.payment_percentage:.1f}%)"
        elif self.is_overdue:
            return f"Overdue by {abs(self.days_until_due)} days"
        else:
            return f"Due in {self.days_until_due} days"
    
    @property
    def priority_color(self):
        """Get color code for priority"""
        colors = {
            'LOW': '#28a745',      # Green
            'MEDIUM': '#ffc107',   # Yellow
            'HIGH': '#fd7e14',     # Orange
            'URGENT': '#dc3545',   # Red
        }
        return colors.get(self.priority, '#6c757d')
    
    @property
    def status_color(self):
        """Get color code for status"""
        colors = {
            'ACTIVE': '#007bff',      # Blue
            'PAID': '#28a745',        # Green
            'OVERDUE': '#dc3545',     # Red
            'PARTIALLY_PAID': '#ffc107',  # Yellow
            'CANCELLED': '#6c757d',   # Gray
        }
        return colors.get(self.status, '#6c757d')
    
    # Helper methods
    def add_payment(self, amount, notes=""):
        """Add a payment to this payable"""
        if amount <= 0:
            raise ValueError("Payment amount must be positive")
        
        if self.amount_paid + amount > self.amount_borrowed:
            raise ValueError("Payment would exceed borrowed amount")
        
        self.amount_paid += amount
        
        # Add to notes
        today = timezone.now().date().strftime('%Y-%m-%d')
        payment_note = f"[{today}] Payment: {amount}"
        if notes:
            payment_note += f" - {notes}"
        
        if self.notes:
            self.notes += f"\n{payment_note}"
        else:
            self.notes = payment_note
        
        self.save()
    
    def add_incremental_payment(self, additional_amount):
        """Add additional amount to existing paid amount"""
        if additional_amount <= 0:
            raise ValueError("Additional amount must be positive")
        
        if self.amount_paid + additional_amount > self.amount_borrowed:
            raise ValueError("Total payment would exceed borrowed amount")
        
        self.amount_paid += additional_amount
        self.save()
    
    def soft_delete(self):
        """Soft delete the payable"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])
    
    def restore(self):
        """Restore a soft-deleted payable"""
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])
    
    def cancel(self, reason=""):
        """Cancel the payable"""
        self.status = 'CANCELLED'
        if reason:
            today = timezone.now().date().strftime('%Y-%m-%d')
            cancel_note = f"[{today}] Cancelled: {reason}"
            if self.notes:
                self.notes += f"\n{cancel_note}"
            else:
                self.notes = cancel_note
        self.save()
    
    # Class methods
    @classmethod
    def active_payables(cls):
        """Return only active payables"""
        return cls.objects.filter(is_active=True)
    
    @classmethod
    def overdue_payables(cls):
        """Get all overdue payables"""
        return cls.active_payables().overdue()
    
    @classmethod
    def urgent_payables(cls):
        """Get all urgent payables"""
        return cls.active_payables().urgent()
    
    @classmethod
    def due_soon(cls, days=7):
        """Get payables due within specified days"""
        return cls.active_payables().due_in_days(days)
    
    @classmethod
    def by_creditor(cls, creditor_name):
        """Get payables by creditor"""
        return cls.active_payables().by_creditor(creditor_name)
    
    @classmethod
    def get_statistics(cls):
        """Get comprehensive payable statistics"""
        active_payables = cls.active_payables()
        
        # Basic counts
        total_count = active_payables.count()
        overdue_count = active_payables.overdue().count()
        urgent_count = active_payables.urgent().count()
        paid_count = active_payables.fully_paid().count()
        pending_count = active_payables.pending().count()
        
        # Amount calculations
        total_borrowed = active_payables.aggregate(
            total=models.Sum('amount_borrowed')
        )['total'] or Decimal('0.00')
        
        total_paid = active_payables.aggregate(
            total=models.Sum('amount_paid')
        )['total'] or Decimal('0.00')
        
        total_outstanding = active_payables.aggregate(
            total=models.Sum('balance_remaining')
        )['total'] or Decimal('0.00')
        
        overdue_amount = active_payables.overdue().aggregate(
            total=models.Sum('balance_remaining')
        )['total'] or Decimal('0.00')
        
        # Priority breakdown
        priority_breakdown = list(
            active_payables.pending()
            .values('priority')
            .annotate(count=models.Count('id'), 
                     amount=models.Sum('balance_remaining'))
            .order_by('-count')
        )
        
        # Status breakdown
        status_breakdown = list(
            active_payables.values('status')
            .annotate(count=models.Count('id'),
                     amount=models.Sum('balance_remaining'))
            .order_by('-count')
        )
        
        # Top creditors
        top_creditors = list(
            active_payables.pending()
            .values('creditor_name')
            .annotate(count=models.Count('id'),
                     total_amount=models.Sum('balance_remaining'))
            .order_by('-total_amount')[:10]
        )
        
        return {
            'total_payables': total_count,
            'overdue_payables': overdue_count,
            'urgent_payables': urgent_count,
            'paid_payables': paid_count,
            'pending_payables': pending_count,
            'total_borrowed_amount': total_borrowed,
            'total_paid_amount': total_paid,
            'total_outstanding_amount': total_outstanding,
            'overdue_amount': overdue_amount,
            'priority_breakdown': priority_breakdown,
            'status_breakdown': status_breakdown,
            'top_creditors': top_creditors,
        }


class PayablePayment(models.Model):
    """Model to track individual payments made to payables"""
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    payable = models.ForeignKey(
        Payable,
        on_delete=models.CASCADE,
        related_name='payments'
    )
    amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )
    payment_date = models.DateField(
        default=timezone.now
    )
    notes = models.TextField(
        null=True,
        blank=True,
        help_text="Payment notes"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    
    class Meta:
        db_table = 'payable_payment'
        verbose_name = 'Payable Payment'
        verbose_name_plural = 'Payable Payments'
        ordering = ['-payment_date', '-created_at']
        indexes = [
            models.Index(fields=['payable']),
            models.Index(fields=['payment_date']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"Payment of {self.amount} for {self.payable.creditor_name}"
    
    def clean(self):
        if self.payable and self.amount:
            # Check if payment would exceed remaining balance
            remaining = self.payable.balance_remaining
            if self.amount > remaining:
                raise ValidationError({
                    'amount': f'Payment amount cannot exceed remaining balance of {remaining}'
                })
    
    def save(self, *args, **kwargs):
        # Capture is_new BEFORE super().save() because super().save() sets _state.adding to False
        is_new = self._state.adding
        diff = Decimal('0.00')
        
        if not is_new:
            try:
                # If updating, we need the difference between old and new amount
                old_instance = PayablePayment.objects.get(pk=self.pk)
                diff = self.amount - old_instance.amount
            except Exception:
                # If lookup fails, treat as new to be safe
                is_new = True
                diff = self.amount
        else:
            diff = self.amount

        # Clean notes if they exist
        if self.notes:
            self.notes = self.notes.strip()

        self.full_clean()
        super().save(*args, **kwargs)
        
        # Update associated payable amounts
        if self.payable:
            if is_new:
                # For new payments, increment the paid amount
                self.payable.amount_paid += self.amount
            else:
                # For updates (like editing a payment amount), add only the difference
                self.payable.amount_paid += diff
            
            # Save the payable to trigger status and balance recalculations
            # The Payable.save() method handles the calculation of balance_remaining and status
            self.payable.save()
            
    def delete(self, *args, **kwargs):
        # Decrement payable amount_paid before deleting
        if self.payable:
            self.payable.amount_paid -= self.amount
            self.payable.save()
        super().delete(*args, **kwargs)
            