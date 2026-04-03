import uuid
import os
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from django.utils import timezone
from datetime import datetime, date, timedelta
from decimal import Decimal
from django.core.exceptions import ObjectDoesNotExist


def advance_payment_upload_path(instance, filename):
    """Generate upload path for advance payment receipt images"""
    # Extract file extension
    ext = filename.split('.')[-1]
    # Generate new filename with UUID
    new_filename = f"{uuid.uuid4()}.{ext}"
    # Return path: advance_payments/YYYY/MM/DD/filename
    return f"advance_payments/{instance.date.year}/{instance.date.month:02d}/{instance.date.day:02d}/{new_filename}"


def validate_advance_amount(value):
    """Validate that advance amount is reasonable"""
    if value <= 0:
        raise ValidationError("Advance amount must be greater than zero.")
    if value > 1000000:  # 10 lakh PKR maximum
        raise ValidationError("Advance amount cannot exceed 10,00,000 PKR.")


def validate_payment_date(value):
    """Validate that payment date is not more than 1 year in the future"""
    from datetime import timedelta
    max_future_date = date.today() + timedelta(days=365)
    if value > max_future_date:
        raise ValidationError("Payment date cannot be more than 1 year in the future.")


class AdvancePaymentQuerySet(models.QuerySet):
    """Custom QuerySet for AdvancePayment model"""
    
    def active(self):
        """Get active advance payments"""
        return self.filter(is_active=True)
    
    def by_labor(self, labor_id):
        """Get advance payments for a specific labor"""
        return self.filter(labor_id=labor_id)
    
    def by_date_range(self, start_date, end_date):
        """Get advance payments within date range"""
        return self.filter(date__range=[start_date, end_date])
    
    def recent(self, days=30):
        """Get advance payments from last N days"""
        from datetime import timedelta
        cutoff_date = date.today() - timedelta(days=days)
        return self.filter(date__gte=cutoff_date)
    
    def today(self):
        """Get today's advance payments"""
        return self.filter(date=date.today())
    
    def this_month(self):
        """Get this month's advance payments"""
        today = date.today()
        return self.filter(date__year=today.year, date__month=today.month)
    
    def this_year(self):
        """Get this year's advance payments"""
        return self.filter(date__year=date.today().year)
    
    def amount_range(self, min_amount=None, max_amount=None):
        """Filter by amount range"""
        queryset = self
        if min_amount is not None:
            queryset = queryset.filter(amount__gte=min_amount)
        if max_amount is not None:
            queryset = queryset.filter(amount__lte=max_amount)
        return queryset
    
    def search(self, query):
        """Search advance payments by labor name, phone, role, or description"""
        return self.filter(
            models.Q(labor_name__icontains=query) |
            models.Q(labor_phone__icontains=query) |
            models.Q(labor_role__icontains=query) |
            models.Q(description__icontains=query)
        )
    
    def with_receipts(self):
        """Get advance payments that have receipt images"""
        return self.exclude(receipt_image_path='')
    
    def without_receipts(self):
        """Get advance payments without receipt images"""
        return self.filter(receipt_image_path='')


class AdvancePayment(models.Model):
    """Advanced Payment model for tracking salary advances given to labors"""
    
    # Primary fields
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    
    # Labor relationship and cached data
    labor = models.ForeignKey(
        'labors.Labor',
        on_delete=models.PROTECT,
        related_name='advance_payments',
        help_text="Labor receiving the advance payment"
    )
    labor_name = models.CharField(
        max_length=200,
        help_text="Cached labor name at time of payment"
    )
    labor_phone = models.CharField(
        max_length=20,
        help_text="Cached labor phone at time of payment"
    )
    labor_role = models.CharField(
        max_length=150,
        help_text="Cached labor designation/role at time of payment"
    )
    
    # Payment details
    amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[validate_advance_amount],
        help_text="Advance amount given to labor"
    )
    description = models.TextField(
        blank=True,
        help_text="Purpose or description of the advance payment"
    )
    date = models.DateField(
        validators=[validate_payment_date],
        help_text="Date when advance payment was made"
    )
    time = models.TimeField(
        help_text="Time when advance payment was made"
    )
    
    # Receipt and documentation
    receipt_image_path = models.ImageField(
        upload_to=advance_payment_upload_path,
        blank=True,
        null=True,
        help_text="Receipt image for the advance payment"
    )
    
    # Salary context (cached from labor at time of payment)
    remaining_salary = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0.00,
        help_text="Remaining salary after this advance"
    )
    total_salary = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text="Labor's total monthly salary at time of payment"
    )
    
    # System fields
    is_active = models.BooleanField(
        default=True,
        help_text="Used for soft deletion"
    )
    source_module = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        help_text="Module that created this advance (e.g., EXPENSES)"
    )
    source_id = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text="ID of the source record in the source module"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_advance_payments'
    )
    
    # Custom manager
    objects = models.Manager.from_queryset(AdvancePaymentQuerySet)()
    
    class Meta:
        db_table = 'advance_payment'
        verbose_name = 'Advance Payment'
        verbose_name_plural = 'Advance Payments'
        ordering = ['-date', '-time', '-created_at']
        indexes = [
            models.Index(fields=['labor']),
            models.Index(fields=['labor_name']),
            models.Index(fields=['labor_phone']),
            models.Index(fields=['labor_role']),
            models.Index(fields=['date']),
            models.Index(fields=['amount']),
            models.Index(fields=['is_active']),
            models.Index(fields=['source_module', 'source_id']),
            models.Index(fields=['created_at']),
            models.Index(fields=['-date', '-time']),
        ]
    
    def __str__(self):
        return f"{self.labor_name} - {self.amount} PKR ({self.date})"
    
    def clean(self):
        """Validate model data"""
        # Validate amount against labor's salary if labor exists
        if self.labor_id and self.amount:
            try:
                if self.amount > self.labor.salary:
                    raise ValidationError({
                        'amount': f'Advance amount cannot exceed monthly salary of {self.labor.salary} PKR.'
                    })
                
                # Check if advance amount exceeds remaining advance amount
                if not self.pk:  # Only for new records
                    remaining_advance = self.labor.get_remaining_advance_amount()
                    if self.amount > remaining_advance:
                        total_advances = self.labor.get_total_advances_amount()
                        raise ValidationError({
                            'amount': f'Advance amount {self.amount} exceeds remaining advance amount {remaining_advance}. Total advances this month: {total_advances}.'
                        })
            except AttributeError:
                pass  # Labor might not be loaded
        
        # Clean description
        if self.description:
            self.description = self.description.strip()
    
    def save(self, *args, **kwargs):
        # Set default time if not provided
        if not self.time:
            self.time = timezone.now().time()
        
        # Set default date if not provided
        if not self.date:
            self.date = date.today()
        
        # Cache labor data if labor is provided
        if self.labor_id and not self.labor_name:
            self.labor_name = self.labor.name
            self.labor_phone = self.labor.phone_number
            self.labor_role = self.labor.designation
            self.total_salary = self.labor.salary
        
        # Handle advance payment deduction from labor's remaining salary
        if self.labor_id:
            # ✅ First, save the record (or get old one if labor changed)
            if not self._state.adding:
                try:
                    old_instance = AdvancePayment.objects.get(pk=self.pk)
                    old_labor = old_instance.labor
                except (ObjectDoesNotExist, AdvancePayment.DoesNotExist):
                    old_labor = None
            else:
                old_labor = None

            # ✅ Save the current AdvancePayment first so it's reflected in calculations
            self.full_clean()
            super().save(*args, **kwargs)

            # ✅ Recalculate current labor's balance
            self.labor.refresh_from_db()
            self.remaining_salary = self.labor.recalculate_remaining_salary()
            
            # ✅ Save again to store the updated remaining_salary snapshot
            super().save(update_fields=['remaining_salary'])

            # ✅ If labor changed, recalculate old labor's balance too
            if old_labor and old_labor != self.labor:
                old_labor.recalculate_remaining_salary()
            
            return # Skip the final super().save() as we've already saved
        
        self.full_clean()
        super().save(*args, **kwargs)
    
    # Properties
    @property
    def display_name(self):
        """Get display name for advance payment"""
        return f"{self.labor_name} - {self.amount} PKR"
    
    @property
    def formatted_amount(self):
        """Get formatted amount with currency"""
        return f"PKR {self.amount:,.2f}"
    
    @property
    def payment_datetime(self):
        """Combine date and time"""
        if self.date and self.time:
            return datetime.combine(self.date, self.time)
        elif self.date:
            return datetime.combine(self.date, timezone.now().time())
        return None
    
    @property
    def is_recent(self):
        """Check if payment was made recently (last 7 days)"""
        from datetime import timedelta
        return self.date >= (date.today() - timedelta(days=7))
    
    @property
    def is_today(self):
        """Check if payment was made today"""
        return self.date == date.today()
    
    @property
    def has_receipt(self):
        """Check if payment has receipt image"""
        return bool(self.receipt_image_path)
    
    @property
    def receipt_url(self):
        """Get receipt image URL"""
        if self.receipt_image_path:
            return self.receipt_image_path.url
        return None
    
    @property
    def advance_percentage(self):
        """Get advance as percentage of total salary"""
        if self.total_salary and self.total_salary > 0:
            percentage = (self.amount / self.total_salary) * Decimal('100')
            return float(round(percentage, 2))
        return 0
    
    # Helper methods
    def get_total_advances_for_labor(self):
        """Get total advance amount for the same labor in current month"""
        from django.db import models
        total = AdvancePayment.objects.filter(
            labor=self.labor,
            date__year=self.date.year,
            date__month=self.date.month,
            is_active=True
        ).aggregate(total=models.Sum('amount'))['total']
        return total or Decimal('0.00')
    
    def soft_delete(self):
        """Soft delete the advance payment"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])
    
    def restore(self):
        """Restore a soft-deleted advance payment"""
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])
    
    # Class methods
    @classmethod
    def get_statistics(cls):
        """Get comprehensive advance payment statistics"""
        active_payments = cls.objects.filter(is_active=True)
        today = date.today()
        
        # Overall statistics
        total_count = active_payments.count()
        total_amount = active_payments.aggregate(
            total=models.Sum('amount')
        )['total'] or Decimal('0.00')
        
        # Today's statistics
        today_payments = active_payments.filter(date=today)
        today_count = today_payments.count()
        today_amount = today_payments.aggregate(
            total=models.Sum('amount')
        )['total'] or Decimal('0.00')
        
        # This month's statistics
        this_month_payments = active_payments.filter(
            date__year=today.year,
            date__month=today.month
        )
        this_month_count = this_month_payments.count()
        this_month_amount = this_month_payments.aggregate(
            total=models.Sum('amount')
        )['total'] or Decimal('0.00')
        
        # Amount statistics
        amount_stats = active_payments.aggregate(
            avg_amount=models.Avg('amount'),
            min_amount=models.Min('amount'),
            max_amount=models.Max('amount')
        )
        
        # Top labor recipients
        top_labors = list(
            active_payments.values('labor_name', 'labor_role')
            .annotate(
                total_advances=models.Sum('amount'),
                payment_count=models.Count('id')
            )
            .order_by('-total_advances')[:10]
        )
        
        # Monthly breakdown (last 12 months)
        from datetime import timedelta
        monthly_stats = []
        for i in range(12):
            month_date = today.replace(day=1) - timedelta(days=i*30)
            month_payments = active_payments.filter(
                date__year=month_date.year,
                date__month=month_date.month
            )
            monthly_stats.append({
                'month': month_date.strftime('%B %Y'),
                'count': month_payments.count(),
                'amount': month_payments.aggregate(
                    total=models.Sum('amount')
                )['total'] or Decimal('0.00')
            })
        
        return {
            'total_payments': total_count,
            'total_amount': total_amount,
            'today_payments': today_count,
            'today_amount': today_amount,
            'this_month_payments': this_month_count,
            'this_month_amount': this_month_amount,
            'amount_statistics': amount_stats,
            'top_labor_recipients': top_labors,
            'monthly_breakdown': monthly_stats[:6],  # Last 6 months
            'payments_with_receipts': active_payments.exclude(receipt_image_path='').count(),
            'payments_without_receipts': active_payments.filter(receipt_image_path='').count(),
        }
    
    @classmethod
    def get_labor_advance_summary(cls, labor_id):
        """Get advance payment summary for a specific labor"""
        payments = cls.objects.filter(labor_id=labor_id, is_active=True)
        
        return {
            'total_advances': payments.aggregate(
                total=models.Sum('amount')
            )['total'] or Decimal('0.00'),
            'payment_count': payments.count(),
            'last_payment_date': payments.first().date if payments.exists() else None,
            'this_month_advances': payments.filter(
                date__year=date.today().year,
                date__month=date.today().month
            ).aggregate(total=models.Sum('amount'))['total'] or Decimal('0.00')
        }
    