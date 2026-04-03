import uuid
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from django.utils import timezone
from decimal import Decimal
from datetime import date


class PrincipalAccount(models.Model):
    """Principal Account model to track all financial transactions across modules"""
    
    TRANSACTION_TYPE_CHOICES = [
        ('CREDIT', 'Credit'),
        ('DEBIT', 'Debit'),
    ]
    
    SOURCE_MODULE_CHOICES = [
        ('SALES', 'Sales'),
        ('ORDERS', 'Orders'),
        ('PAYMENTS', 'Payments'),
        ('RECEIVABLES', 'Receivables'),
        ('PAYABLES', 'Payables'),
        ('ADVANCE_PAYMENT', 'Advance Payment'),
        ('EXPENSES', 'Expenses'),
        ('ZAKAT', 'Zakat'),
        ('LABOR', 'Labor'),
        ('VENDOR', 'Vendor'),
        ('ADJUSTMENT', 'Adjustment'),
        ('TRANSFER', 'Transfer'),
    ]
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    
    # Transaction details
    date = models.DateField(
        default=date.today,
        help_text="Transaction date"
    )
    time = models.TimeField(
        default=timezone.now,
        help_text="Transaction time"
    )
    
    # Source information
    source_module = models.CharField(
        max_length=20,
        choices=SOURCE_MODULE_CHOICES,
        help_text="Module that generated this transaction"
    )
    source_id = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text="ID of the source record (e.g., sale ID, order ID)"
    )
    
    # Transaction details
    description = models.TextField(
        help_text="Description of the transaction"
    )
    type = models.CharField(
        max_length=10,
        choices=TRANSACTION_TYPE_CHOICES,
        help_text="Transaction type (credit/debit)"
    )
    amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        help_text="Transaction amount"
    )
    
    # Balance tracking
    balance_before = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        help_text="Account balance before this transaction"
    )
    balance_after = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        help_text="Account balance after this transaction"
    )
    
    # Additional information
    handled_by = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text="Person who handled this transaction"
    )
    notes = models.TextField(
        blank=True,
        null=True,
        help_text="Additional notes"
    )
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_principal_accounts'
    )
    is_active = models.BooleanField(default=True)
    
    class Meta:
        db_table = 'principal_account'
        verbose_name = 'Principal Account'
        verbose_name_plural = 'Principal Accounts'
        ordering = ['-date', '-time']
        indexes = [
            models.Index(fields=['date']),
            models.Index(fields=['source_module']),
            models.Index(fields=['type']),
            models.Index(fields=['source_id']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return f"{self.source_module} - {self.description} ({self.amount})"
    
    def clean(self):
        """Validate model data"""
        if self.amount <= 0:
            raise ValidationError({'amount': 'Amount must be greater than zero.'})
        
        if self.balance_after < 0:
            raise ValidationError({'balance_after': 'Balance cannot be negative.'})
    
    @property
    def formatted_amount(self):
        """Format amount with currency symbol"""
        return f"PKR {self.amount:,.2f}"
    
    @property
    def formatted_balance_after(self):
        """Format balance after with currency symbol"""
        return f"PKR {self.balance_after:,.2f}"
    
    @property
    def is_credit(self):
        """Check if transaction is credit"""
        return self.type == 'CREDIT'
    
    @property
    def is_debit(self):
        """Check if transaction is debit"""
        return self.type == 'DEBIT'


class PrincipalAccountBalance(models.Model):
    """Model to track current account balance"""
    
    id = models.AutoField(primary_key=True)
    current_balance = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Current account balance"
    )
    last_updated = models.DateTimeField(auto_now=True)
    last_transaction_id = models.UUIDField(
        blank=True,
        null=True,
        help_text="ID of the last transaction that updated this balance"
    )
    
    class Meta:
        db_table = 'principal_account_balance'
        verbose_name = 'Principal Account Balance'
        verbose_name_plural = 'Principal Account Balances'
    
    def __str__(self):
        return f"Current Balance: {self.formatted_balance}"
    
    @property
    def formatted_balance(self):
        """Format balance with currency symbol"""
        return f"PKR {self.current_balance:,.2f}"

