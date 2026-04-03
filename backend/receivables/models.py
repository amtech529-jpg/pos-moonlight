import uuid
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import MinValueValidator
from django.utils import timezone
from decimal import Decimal
from datetime import date


def validate_amount_given(value):
    """Validate that amount given is positive"""
    if value <= 0:
        raise ValidationError("Amount given must be greater than zero.")


def validate_amount_returned(value):
    """Validate that amount returned is not negative"""
    if value < 0:
        raise ValidationError("Amount returned cannot be negative.")


def validate_expected_return_date(value):
    """Validate that expected return date is not in the past"""
    if value < date.today():
        raise ValidationError("Expected return date cannot be in the past.")


class ReceivableQuerySet(models.QuerySet):
    """Custom QuerySet for Receivable model"""
    
    def active(self):
        """Get active receivables"""
        return self.filter(is_active=True)
    
    def inactive(self):
        """Get inactive receivables"""
        return self.filter(is_active=False)
    
    def by_debtor(self, debtor_name):
        """Get receivables for a specific debtor"""
        return self.filter(debtor_name__icontains=debtor_name)
    
    def by_debtor_phone(self, phone):
        """Get receivables for a specific debtor phone"""
        return self.filter(debtor_phone__icontains=phone)
    
    def by_date_range(self, start_date, end_date):
        """Get receivables within date range"""
        return self.filter(date_lent__range=[start_date, end_date])
    
    def by_expected_return_date_range(self, start_date, end_date):
        """Get receivables by expected return date range"""
        return self.filter(expected_return_date__range=[start_date, end_date])
    
    def overdue(self):
        """Get overdue receivables"""
        today = date.today()
        return self.filter(
            expected_return_date__lt=today,
            balance_remaining__gt=0,
            is_active=True
        )
    
    def due_today(self):
        """Get receivables due today"""
        today = date.today()
        return self.filter(
            expected_return_date=today,
            balance_remaining__gt=0,
            is_active=True
        )
    
    def due_this_week(self):
        """Get receivables due this week"""
        today = date.today()
        week_end = today + timezone.timedelta(days=7)
        return self.filter(
            expected_return_date__range=[today, week_end],
            balance_remaining__gt=0,
            is_active=True
        )
    
    def fully_paid(self):
        """Get fully paid receivables"""
        return self.filter(balance_remaining=0)
    
    def partially_paid(self):
        """Get partially paid receivables"""
        return self.filter(
            balance_remaining__gt=0,
            amount_returned__gt=0
        )
    
    def unpaid(self):
        """Get completely unpaid receivables"""
        return self.filter(
            balance_remaining__gt=0,
            amount_returned=0
        )
    
    def recent(self, days=30):
        """Get receivables from last N days"""
        cutoff_date = date.today() - timezone.timedelta(days=days)
        return self.filter(date_lent__gte=cutoff_date)
    
    def today(self):
        """Get today's receivables"""
        today = date.today()
        return self.filter(date_lent=today)
    
    def this_month(self):
        """Get this month's receivables"""
        today = date.today()
        return self.filter(
            date_lent__year=today.year,
            date_lent__month=today.month
        )
    
    def this_year(self):
        """Get this year's receivables"""
        return self.filter(date_lent__year=date.today().year)
    
    def amount_range(self, min_amount=None, max_amount=None):
        """Filter by amount range"""
        queryset = self
        if min_amount is not None:
            queryset = queryset.filter(amount_given__gte=min_amount)
        if max_amount is not None:
            queryset = queryset.filter(amount_given__lte=max_amount)
        return queryset
    
    def search(self, query):
        """Search receivables by debtor name, phone, reason, or notes"""
        return self.filter(
            models.Q(debtor_name__icontains=query) |
            models.Q(debtor_phone__icontains=query) |
            models.Q(reason_or_item__icontains=query) |
            models.Q(notes__icontains=query)
        )


class Receivable(models.Model):
    """Receivable model for tracking money lent to debtors"""
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    debtor_name = models.CharField(
        max_length=200,
        help_text="Name of the person who owes money"
    )
    debtor_phone = models.CharField(
        max_length=20,
        help_text="Phone number of the debtor"
    )
    amount_given = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Amount of money lent to the debtor"
    )
    reason_or_item = models.TextField(
        blank=True,
        default='',
        help_text="Reason for lending money or item description"
    )
    date_lent = models.DateField(
        default=timezone.now,
        help_text="Date when money was lent"
    )
    expected_return_date = models.DateField(
        null=True,
        blank=True,
        help_text="Expected date for money return"
    )
    amount_returned = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))],
        help_text="Amount of money returned by the debtor"
    )
    balance_remaining = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Remaining amount to be returned"
    )
    notes = models.TextField(
        blank=True,
        help_text="Additional notes about the receivable"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Used for soft deletion. Inactive receivables won't appear in lists"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_receivables',
        help_text="User who created this receivable"
    )
    
    # Optional relationship to sales if customer has remaining amount
    related_sale = models.ForeignKey(
        'sales.Sales',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='receivables',
        help_text="Related sale if this receivable is from a sale transaction"
    )
    
    objects = ReceivableQuerySet.as_manager()
    
    class Meta:
        db_table = 'receivable'
        verbose_name = 'Receivable'
        verbose_name_plural = 'Receivables'
        ordering = ['-date_lent', '-created_at']
        indexes = [
            models.Index(fields=['debtor_name']),
            models.Index(fields=['debtor_phone']),
            models.Index(fields=['date_lent']),
            models.Index(fields=['expected_return_date']),
            models.Index(fields=['balance_remaining']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.debtor_name} - {self.amount_given} PKR ({self.date_lent})"
    
    def clean(self):
        """Validate model data"""
        if self.amount_returned > self.amount_given:
            raise ValidationError({
                'amount_returned': 'Amount returned cannot exceed amount given.'
            })
        
        if self.expected_return_date and self.date_lent > self.expected_return_date:
            raise ValidationError({
                'expected_return_date': 'Expected return date cannot be before date lent.'
            })
    
    def save(self, *args, **kwargs):
        """Override save to automatically calculate balance_remaining"""
        if self.pk is None:  # New instance
            self.balance_remaining = self.amount_given
        
        # Calculate remaining balance
        self.balance_remaining = self.amount_given - self.amount_returned
        
        # Validate before saving
        self.clean()
        super().save(*args, **kwargs)
    
    def soft_delete(self):
        """Soft delete the receivable by setting is_active to False"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])
    
    def restore(self):
        """Restore a soft-deleted receivable"""
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])
    
    def record_payment(self, amount):
        """Record a payment/return from the debtor"""
        if amount <= 0:
            raise ValidationError("Payment amount must be positive.")
        
        if amount > self.balance_remaining:
            raise ValidationError("Payment amount cannot exceed remaining balance.")
        
        self.amount_returned += amount
        self.balance_remaining = self.amount_given - self.amount_returned
        self.save(update_fields=['amount_returned', 'balance_remaining', 'updated_at'])
        
        return self.balance_remaining
    
    def is_overdue(self):
        """Check if the receivable is overdue"""
        if not self.expected_return_date:
            return False
        return date.today() > self.expected_return_date and self.balance_remaining > 0
    
    def days_overdue(self):
        """Calculate days overdue"""
        if not self.is_overdue():
            return 0
        return (date.today() - self.expected_return_date).days
    
    def is_fully_paid(self):
        """Check if the receivable is fully paid"""
        return self.balance_remaining == 0
    
    def is_partially_paid(self):
        """Check if the receivable is partially paid"""
        return 0 < self.balance_remaining < self.amount_given
    
    @classmethod
    def active_receivables(cls):
        """Return only active receivables"""
        return cls.objects.filter(is_active=True)
    
    @classmethod
    def total_outstanding(cls):
        """Calculate total outstanding amount"""
        return cls.active_receivables().aggregate(
            total=models.Sum('balance_remaining')
        )['total'] or Decimal('0.00')
    
    @classmethod
    def overdue_receivables(cls):
        """Get all overdue receivables"""
        return cls.active_receivables().overdue()
