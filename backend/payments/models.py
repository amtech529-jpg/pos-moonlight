import uuid
import os
from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator
from django.core.exceptions import ValidationError
from django.utils import timezone
from datetime import datetime, date
from decimal import Decimal


def payment_receipt_upload_path(instance, filename):
    """Generate upload path for payment receipt images"""
    # Extract file extension
    ext = filename.split('.')[-1].lower()
    
    # Validate file extension
    allowed_extensions = ['jpg', 'jpeg', 'png', 'pdf']
    if ext not in allowed_extensions:
        raise ValidationError(f'File type .{ext} is not supported. Please use: {", ".join(allowed_extensions)}')
    
    # Generate new filename with UUID
    new_filename = f"{uuid.uuid4()}.{ext}"
    # Return path: payments/YYYY/MM/DD/filename
    return f"payments/{instance.date.year}/{instance.date.month:02d}/{instance.date.day:02d}/{new_filename}"


def validate_receipt_file_size(value):
    """Validate receipt file size (max 5MB)"""
    if value.size > 5 * 1024 * 1024:  # 5MB
        raise ValidationError('Receipt file size cannot exceed 5MB.')


def validate_payment_amount(value):
    """Validate that payment amount is reasonable"""
    if value <= 0:
        raise ValidationError("Payment amount must be greater than zero.")
    if value > 1000000:  # 10 lakh PKR maximum
        raise ValidationError("Payment amount cannot exceed 10,00,000 PKR.")


def validate_payment_date(value):
    """Validate that payment date is not in the future"""
    if value > date.today():
        raise ValidationError("Payment date cannot be in the future.")


class PaymentQuerySet(models.QuerySet):
    """Custom QuerySet for Payment model"""
    
    def active(self):
        """Get active payments"""
        return self.filter(is_active=True)
    
    def by_labor(self, labor_id):
        """Get payments for a specific labor"""
        return self.filter(labor_id=labor_id)
    
    def by_vendor(self, vendor_id):
        """Get payments for a specific vendor"""
        return self.filter(vendor_id=vendor_id)
    
    def by_order(self, order_id):
        """Get payments for a specific order"""
        return self.filter(order_id=order_id)
    
    def by_sale(self, sale_id):
        """Get payments for a specific sale"""
        return self.filter(sale_id=sale_id)
    
    def by_payer_type(self, payer_type):
        """Get payments by payer type"""
        return self.filter(payer_type=payer_type)
    
    def by_date_range(self, start_date, end_date):
        """Get payments within date range"""
        return self.filter(date__range=[start_date, end_date])
    
    def by_payment_month(self, month, year=None):
        """Get payments for specific month"""
        if year is None:
            year = date.today().year
        return self.filter(payment_month__year=year, payment_month__month=month)
    
    def recent(self, days=30):
        """Get payments from last N days"""
        from datetime import timedelta
        cutoff_date = date.today() - timedelta(days=days)
        return self.filter(date__gte=cutoff_date)
    
    def today(self):
        """Get today's payments"""
        return self.filter(date=date.today())
    
    def this_month(self):
        """Get this month's payments"""
        today = date.today()
        return self.filter(date__year=today.year, date__month=today.month)
    
    def this_year(self):
        """Get this year's payments"""
        return self.filter(date__year=date.today().year)
    
    def amount_range(self, min_amount=None, max_amount=None):
        """Filter by amount range"""
        queryset = self
        if min_amount is not None:
            queryset = queryset.filter(amount_paid__gte=min_amount)
        if max_amount is not None:
            queryset = queryset.filter(amount_paid__lte=max_amount)
        return queryset
    
    def final_payments(self):
        """Get final payments"""
        return self.filter(is_final_payment=True)
    
    def partial_payments(self):
        """Get partial payments"""
        return self.filter(is_final_payment=False)
    
    def by_payment_method(self, payment_method):
        """Filter by payment method"""
        return self.filter(payment_method=payment_method)
    
    def search(self, query):
        """Search payments by labor name, phone, role, vendor name, or description"""
        return self.filter(
            models.Q(labor_name__icontains=query) |
            models.Q(labor_phone__icontains=query) |
            models.Q(labor_role__icontains=query) |
            models.Q(vendor__business_name__icontains=query) |
            models.Q(description__icontains=query)
        )
    
    def with_receipts(self):
        """Get payments that have receipt images"""
        return self.exclude(receipt_image_path='')
    
    def without_receipts(self):
        """Get payments without receipt images"""
        return self.filter(receipt_image_path='')


class Payment(models.Model):
    """Payment model for tracking various types of payments"""
    
    # Payer Type Choices
    PAYER_TYPE_CHOICES = [
        ('LABOR', 'Labor'),
        ('VENDOR', 'Vendor'),
        ('CUSTOMER', 'Customer'),
        ('OTHER', 'Other'),
    ]
    
    # Payment Method Choices
    PAYMENT_METHOD_CHOICES = [
        ('CASH', 'Cash'),
        ('BANK_TRANSFER', 'Bank Transfer'),
        ('MOBILE_PAYMENT', 'Mobile Payment (JazzCash/EasyPaisa)'),
        ('CHECK', 'Check'),
        ('CARD', 'Credit/Debit Card'),
        ('OTHER', 'Other'),
    ]
    
    # Primary fields
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    
    # Foreign Key relationships
    labor = models.ForeignKey(
        'labors.Labor',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payments',
        help_text="Labor receiving payment (if applicable)"
    )
    vendor = models.ForeignKey(
        'vendors.Vendor',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payments',
        help_text="Vendor receiving payment (if applicable)"
    )
    order = models.ForeignKey(
        'orders.Order',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payments',
        help_text="Order this payment is related to (if applicable)"
    )
    sale = models.ForeignKey(
        'sales.Sales',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='payments',
        help_text="Sale this payment is related to (if applicable)"
    )
    
    # Payer identification
    payer_type = models.CharField(
        max_length=20,
        choices=PAYER_TYPE_CHOICES,
        help_text="Type of entity making the payment"
    )
    payer_id = models.UUIDField(
        null=True,
        blank=True,
        help_text="ID of the payer entity"
    )
    payable = models.ForeignKey(
    'payables.Payable',
    on_delete=models.SET_NULL,
    null=True,
    blank=True,
    related_name='linked_payments',
    help_text="Payable this payment is reducing (if applicable)"
    )
    # Cached labor information for historical accuracy
    labor_name = models.CharField(
        max_length=200,
        blank=True,
        help_text="Cached labor name at time of payment"
    )
    labor_phone = models.CharField(
        max_length=20,
        blank=True,
        help_text="Cached labor phone at time of payment"
    )
    labor_role = models.CharField(
        max_length=100,
        blank=True,
        help_text="Cached labor role at time of payment"
    )
    
    # Financial fields
    amount_paid = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Amount paid"
    )
    bonus = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Bonus amount (if any)"
    )
    deduction = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Deduction amount (if any)"
    )
    
    # Payment details
    payment_month = models.DateField(
        help_text="Month for which payment is made"
    )
    is_final_payment = models.BooleanField(
        default=False,
        help_text="Whether this is the final payment for the period"
    )
    payment_method = models.CharField(
        max_length=20,
        choices=PAYMENT_METHOD_CHOICES,
        default='CASH',
        help_text="Method of payment"
    )
    description = models.TextField(
        blank=True,
        help_text="Payment description and notes"
    )
    
    # Date and time
    date = models.DateField(
        validators=[validate_payment_date],
        help_text="Date of payment"
    )
    time = models.TimeField(
        help_text="Time of payment"
    )
    
    # Receipt management
    receipt_image_path = models.FileField(
        upload_to=payment_receipt_upload_path,
        blank=True,
        null=True,
        validators=[validate_receipt_file_size],
        help_text="Receipt file for payment verification (JPG, PNG, PDF, max 5MB)"
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
        related_name='created_payments',
        help_text="User who recorded this payment"
    )
    
    objects = PaymentQuerySet.as_manager()
    
    class Meta:
        db_table = 'payment'
        verbose_name = 'Payment'
        verbose_name_plural = 'Payments'
        ordering = ['-date', '-time', '-created_at']
        indexes = [
            models.Index(fields=['labor']),
            models.Index(fields=['vendor']),
            models.Index(fields=['order']),
            models.Index(fields=['sale']),
            models.Index(fields=['payer_type']),
            models.Index(fields=['payment_month']),
            models.Index(fields=['date']),
            models.Index(fields=['payment_method']),
            models.Index(fields=['is_final_payment']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        payer_info = f"{self.get_payer_type_display()}"
        if self.labor_name:
            payer_info = f"{self.labor_name} ({self.labor_role})"
        elif self.vendor:
            payer_info = f"{self.vendor.business_name}"
        
        return f"{payer_info} - {self.formatted_amount} ({self.date})"
    
    def clean(self):
        """Validate model data"""
        # Validate amount
        if self.amount_paid <= 0:
            raise ValidationError({'amount_paid': 'Amount paid must be greater than zero.'})
        
        # Validate bonus and deduction
        if self.bonus < 0:
            raise ValidationError({'bonus': 'Bonus cannot be negative.'})
        
        if self.deduction < 0:
            raise ValidationError({'deduction': 'Deduction cannot be negative.'})
        
        # Validate that at least one entity is specified
        if not any([self.labor, self.vendor, self.order, self.sale]):
            raise ValidationError('At least one entity (labor, vendor, order, or sale) must be specified.')
        
        # Validate payment month is not in future
        if self.payment_month and self.payment_month > date.today():
            raise ValidationError({'payment_month': 'Payment month cannot be in the future.'})
        
        # Validate business rules
        if self.labor:
            # Check if payment amount exceeds monthly salary
            if hasattr(self.labor, 'salary') and self.labor.salary:
                max_allowed = self.labor.salary + (self.bonus or 0) - (self.deduction or 0)
                if self.amount_paid > max_allowed and not self.is_final_payment:
                    raise ValidationError({
                        'amount_paid': f'Payment amount cannot exceed monthly salary (PKR {max_allowed:,.2f}) unless marked as final payment.'
                    })
            
            # Check for duplicate payments in same month (excluding this instance)
            existing_payments = Payment.objects.filter(
                labor=self.labor,
                payment_month=self.payment_month,
                is_active=True
            ).exclude(id=self.id)
            
            if existing_payments.exists() and self.is_final_payment:
                raise ValidationError({
                    'is_final_payment': 'A final payment already exists for this labor in the specified month.'
                })
    
    def save(self, *args, **kwargs):
        """Custom save method with validation and data caching"""
        # Cache labor information if labor is specified
        if self.labor:
            self.labor_name = self.labor.name if hasattr(self.labor, 'name') else ''
            self.labor_phone = self.labor.phone_number if hasattr(self.labor, 'phone_number') else ''
            self.labor_role = self.labor.designation if hasattr(self.labor, 'designation') else ''
            self.payer_type = 'LABOR'
            self.payer_id = self.labor.id
        
        # Set payer type for vendor
        elif self.vendor:
            self.payer_type = 'VENDOR'
            self.payer_id = self.vendor.id
        
        # Set payer type for order
        elif self.order and hasattr(self.order, 'customer'):
            self.payer_type = 'CUSTOMER'
            self.payer_id = self.order.customer.id
        
        # Set payer type for sale
        elif self.sale and hasattr(self.sale, 'customer'):
            self.payer_type = 'CUSTOMER'
            self.payer_id = self.sale.customer.id
        
        self.full_clean()
        super().save(*args, **kwargs)
    
    # Properties
    @property
    def formatted_amount(self):
        """Get formatted amount string"""
        if self.amount_paid is None:
            return "PKR 0.00"
        return f"PKR {self.amount_paid:,.2f}"
    
    @property
    def net_amount(self):
        """Get net amount after bonus and deduction"""
        # Handle None values safely
        amount_paid = self.amount_paid or Decimal('0.00')
        bonus = self.bonus or Decimal('0.00')
        deduction = self.deduction or Decimal('0.00')
        return amount_paid + bonus - deduction
    
    @property
    def payment_age_days(self):
        """Days since payment was made"""
        return (date.today() - self.date).days
    
    @property
    def has_receipt(self):
        """Check if payment has receipt image"""
        return bool(self.receipt_image_path)
    
    @property
    def payment_period_display(self):
        """Get human-readable payment period"""
        if self.payment_month:
            return self.payment_month.strftime('%B %Y')
        return 'Not specified'
    
    # Helper methods
    def soft_delete(self):
        """Soft delete the payment"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])
    
    def restore(self):
        """Restore a soft-deleted payment"""
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])
    
    def mark_as_final(self):
        """Mark payment as final payment"""
        self.is_final_payment = True
        self.save(update_fields=['is_final_payment', 'updated_at'])
    
    def add_bonus(self, bonus_amount, description=""):
        """Add bonus to payment"""
        if bonus_amount <= 0:
            raise ValidationError("Bonus amount must be positive.")
        
        self.bonus += bonus_amount
        if description:
            self.description += f"\nBonus added: {description}"
        self.save(update_fields=['bonus', 'description', 'updated_at'])
    
    def add_deduction(self, deduction_amount, description=""):
        """Add deduction to payment"""
        if deduction_amount <= 0:
            raise ValidationError("Deduction amount must be positive.")
        
        self.deduction += deduction_amount
        if description:
            self.description += f"\nDeduction added: {description}"
        self.save(update_fields=['deduction', 'description', 'updated_at'])
    
    # Class methods
    @classmethod
    def active_payments(cls):
        """Return only active payments"""
        return cls.objects.filter(is_active=True)
    
    @classmethod
    def payments_by_month(cls, month, year):
        """Get payments for specific month and year"""
        return cls.active_payments().filter(
            payment_month__year=year,
            payment_month__month=month
        )
    
    @classmethod
    def get_statistics(cls):
        """Get comprehensive payment statistics"""
        active_payments = cls.active_payments()
        total_payments = active_payments.count()
        
        # Amount statistics
        total_amount = active_payments.aggregate(
            total=models.Sum('amount_paid')
        )['total'] or Decimal('0.00')
        
        total_bonus = active_payments.aggregate(
            total=models.Sum('bonus')
        )['total'] or Decimal('0.00')
        
        total_deduction = active_payments.aggregate(
            total=models.Sum('deduction')
        )['total'] or Decimal('0.00')
        
        # Payer type breakdown
        payer_type_breakdown = {}
        for payer_type, _ in cls.PAYER_TYPE_CHOICES:
            count = active_payments.filter(payer_type=payer_type).count()
            if count > 0:
                payer_type_breakdown[payer_type.lower()] = count
        
        # Payment method breakdown
        payment_method_breakdown = {}
        for method, _ in cls.PAYMENT_METHOD_CHOICES:
            count = active_payments.filter(payment_method=method).count()
            if count > 0:
                payment_method_breakdown[method.lower()] = count
        
        # Recent activity
        recent_payments = cls.recent(30)
        recent_count = recent_payments.count()
        recent_amount = recent_payments.aggregate(
            total=models.Sum('amount_paid')
        )['total'] or Decimal('0.00')
        
        return {
            'total_payments': total_payments,
            'total_amount': float(total_amount),
            'total_bonus': float(total_bonus),
            'total_deduction': float(total_deduction),
            'net_amount': float(total_amount + total_bonus - total_deduction),
            'payer_type_breakdown': payer_type_breakdown,
            'payment_method_breakdown': payment_method_breakdown,
            'recent_activity': {
                'payments_last_30_days': recent_count,
                'amount_last_30_days': float(recent_amount),
            },
            'final_payments_count': active_payments.filter(is_final_payment=True).count(),
            'partial_payments_count': active_payments.filter(is_final_payment=False).count(),
        }
    
    @property
    def formatted_amount(self):
        """Currency formatted amount display"""
        if self.amount_paid is None:
            return "PKR 0.00"
        return f"PKR {self.amount_paid:,.2f}"


# Custom manager is already set via PaymentQuerySet.as_manager()
