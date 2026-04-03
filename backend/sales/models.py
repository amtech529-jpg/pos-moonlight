import uuid
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from django.utils import timezone
from decimal import Decimal
from datetime import date


class TaxRate(models.Model):
    """Tax rate configuration for different tax types"""

    TAX_TYPE_CHOICES = [
        ('GST', 'General Sales Tax'),
        ('FED', 'Federal Excise Duty'),
        ('WHT', 'Withholding Tax'),
        ('ADDITIONAL', 'Additional Tax'),
        ('CUSTOM', 'Custom Tax Rate'),
    ]

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )

    name = models.CharField(
        max_length=100,
        help_text="Tax rate name (e.g., Standard GST, Reduced GST, FED on Textiles)"
    )

    tax_type = models.CharField(
        max_length=20,
        choices=TAX_TYPE_CHOICES,
        default='GST',
        help_text="Type of tax"
    )

    percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        help_text="Tax rate percentage (e.g., 17.00 for 17%)"
    )

    is_active = models.BooleanField(
        default=True,
        help_text="Whether this tax rate is currently active"
    )

    description = models.TextField(
        blank=True,
        help_text="Description of when this tax rate applies"
    )

    effective_from = models.DateField(
        default=date.today,
        help_text="Date from which this tax rate is effective"
    )

    effective_to = models.DateField(
        null=True,
        blank=True,
        help_text="Date until which this tax rate is effective (null for indefinite)"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'tax_rates'
        verbose_name = 'Tax Rate'
        verbose_name_plural = 'Tax Rates'
        ordering = ['tax_type', 'effective_from']

    def __str__(self):
        return f"{self.name} ({self.percentage}%)"

    @property
    def is_currently_effective(self):
        """Check if tax rate is currently effective"""
        today = date.today()
        if not self.is_active:
            return False
        if self.effective_from > today:
            return False
        if self.effective_to and self.effective_to < today:
            return False
        return True

    def clean(self):
        """Validate model data"""
        if self.percentage < 0 or self.percentage > 100:
            raise ValidationError({'percentage': 'Tax percentage must be between 0 and 100.'})

        if self.effective_to and self.effective_to < self.effective_from:
            raise ValidationError({'effective_to': 'Effective to date cannot be before effective from date.'})


def generate_invoice_number():
    """Generate sequential invoice number in format: INV-YYYY-XXXX"""
    today = date.today()
    year = today.year

    # Get the last invoice number for this year
    last_invoice = Sales.objects.filter(
        invoice_number__startswith=f'INV-{year}-'
    ).order_by('-invoice_number').first()

    if last_invoice:
        try:
            # Extract the sequence number and increment
            last_sequence = int(last_invoice.invoice_number.split('-')[-1])
            new_sequence = last_sequence + 1
        except (ValueError, IndexError):
            new_sequence = 1
    else:
        new_sequence = 1

    return f'INV-{year}-{new_sequence:04d}'


class Return(models.Model):
    """Return request model for processing customer returns"""

    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
        ('PROCESSED', 'Processed'),
        ('CANCELLED', 'Cancelled'),
    ]

    REASON_CHOICES = [
        ('DEFECTIVE', 'Defective Product'),
        ('SIZE_ISSUE', 'Wrong Size'),
        ('WRONG_COLOR', 'Wrong Color'),
        ('QUALITY_ISSUE', 'Quality Issue'),
        ('CUSTOMER_REQUEST', 'Customer Changed Mind'),
        ('DAMAGED', 'Damaged'),
        ('OTHER', 'Other'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    return_number = models.CharField(
        max_length=50,
        unique=True,
        help_text="Unique return number"
    )
    sale = models.ForeignKey(
        'Sales',
        on_delete=models.CASCADE,
        related_name='returns',
        help_text="Original sale for this return"
    )
    # ✅ FIX APPLIED: Added null=True and blank=True to allow Walk-in Customers
    customer = models.ForeignKey(
        'customers.Customer',
        on_delete=models.CASCADE,
        related_name='returns',
        null=True,
        blank=True,
        help_text="Customer requesting the return"
    )
    reason = models.CharField(
        max_length=20,
        choices=REASON_CHOICES,
        help_text="Primary reason for return"
    )
    reason_details = models.TextField(
        blank=True,
        help_text="Detailed explanation of return reason"
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='PENDING',
        help_text="Current status of return request"
    )
    return_date = models.DateTimeField(
        auto_now_add=True,
        help_text="When return was requested"
    )
    approved_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When return was approved"
    )
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='approved_returns',
        help_text="User who approved the return"
    )
    processed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When return was processed"
    )
    processed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='processed_returns',
        help_text="User who processed the return"
    )
    notes = models.TextField(
        blank=True,
        help_text="Additional notes about the return"
    )
    refund_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Amount to be refunded"
    )
    refund_method = models.CharField(
        max_length=20,
        choices=[
            ('CASH', 'Cash'),
            ('BANK_TRANSFER', 'Bank Transfer'),
            ('CHECK', 'Check'),
            ('CREDIT_NOTE', 'Credit Note'),
            ('EXCHANGE', 'Exchange'),
            ('OTHER', 'Other'),
        ],
        null=True,
        blank=True,
        help_text="Method of refund"
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
        related_name='created_returns',
        help_text="User who created this return request"
    )

    class Meta:

        db_table = 'sales_return'
        verbose_name = 'Return'
        verbose_name_plural = 'Returns'
        ordering = ['-return_date', '-created_at']
        indexes = [
            models.Index(fields=['return_number']),
            models.Index(fields=['sale']),
            models.Index(fields=['customer']),
            models.Index(fields=['status']),
            models.Index(fields=['return_date']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self):
        return f"Return {self.return_number} - {self.sale.invoice_number}"

    def save(self, *args, **kwargs):
        """Auto-generate return number if not set"""
        if not self.return_number:
            self.return_number = self._generate_return_number()
        super().save(*args, **kwargs)

    def _generate_return_number(self):
        """Generate unique return number"""
        today = date.today()
        year = today.year

        last_return = Return.objects.filter(
            return_number__startswith=f'RET-{year}-'
        ).order_by('-return_number').first()

        if last_return:
            try:
                last_sequence = int(last_return.return_number.split('-')[-1])
                new_sequence = last_sequence + 1
            except (ValueError, IndexError):
                new_sequence = 1
        else:
            new_sequence = 1

        return f'RET-{year}-{new_sequence:04d}'

    def approve(self, approved_by_user, reason=None):
        """Approve the return request and create a pending refund"""
        self.status = 'APPROVED'
        self.approved_at = timezone.now()
        self.approved_by = approved_by_user
        if reason:
            self.notes = f"Approved: {reason}"
        self.save(update_fields=['status', 'approved_at', 'approved_by', 'notes', 'updated_at'])
        
        # Auto-create a pending refund with the actual refund amount
        refund_amount = self.refund_amount or self.total_return_amount
        print(f"🔍 [Return] Approving return {self.return_number}, refund_amount={refund_amount}, total_return_amount={self.total_return_amount}")
        
        if refund_amount > 0:
            try:
                refund = Refund.objects.create(
                    return_request=self,
                    amount=refund_amount,
                    method='CASH',  # Default to cash, can be changed later
                    status='PENDING',
                    created_by=approved_by_user,
                    notes=f"Auto-created refund for approved return {self.return_number}"
                )
                print(f"✅ [Return] Created refund {refund.refund_number} for amount {refund_amount}")
            except Exception as e:
                print(f"❌ [Return] Error creating refund: {e}")
        else:
            print(f"⚠️ [Return] No refund created - amount is 0 or less")

    def reject(self, rejected_by_user, reason):
        """Reject the return request"""
        self.status = 'REJECTED'
        self.notes = f"Rejected: {reason}"
        self.save(update_fields=['status', 'notes', 'updated_at'])

    def process(self, processed_by_user, refund_amount=None, refund_method=None):
        """Process the approved return"""
        self.status = 'PROCESSED'
        self.processed_at = timezone.now()
        self.processed_by = processed_by_user
        if refund_amount is not None:
            self.refund_amount = refund_amount
        if refund_method is not None:
            self.refund_method = refund_method
        self.save(update_fields=['status', 'processed_at', 'processed_by', 'refund_amount', 'refund_method', 'updated_at'])

    def cancel(self, cancelled_by_user, reason):
        """Cancel the return request"""
        self.status = 'CANCELLED'
        self.notes = f"Cancelled: {reason}"
        self.save(update_fields=['status', 'notes', 'updated_at'])

    @property
    def total_return_amount(self):
        """Calculate total amount to be returned"""
        return sum(item.return_amount for item in self.return_items.all())

    @property
    def items_count(self):
        """Get count of return items"""
        return self.return_items.count()


class ReturnItem(models.Model):
    """Individual items being returned"""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    return_request = models.ForeignKey(
        Return,
        on_delete=models.CASCADE,
        related_name='return_items',
        help_text="Return request this item belongs to"
    )
    sale_item = models.ForeignKey(
        'SaleItem',
        on_delete=models.CASCADE,
        related_name='return_items',
        help_text="Original sale item being returned"
    )
    quantity_returned = models.PositiveIntegerField(
        help_text="Quantity being returned"
    )
    return_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text="Amount to be returned for this item"
    )
    return_reason = models.CharField(
        max_length=100,
        blank=True,
        help_text="Specific reason for returning this item"
    )
    condition = models.CharField(
        max_length=20,
        choices=[
            ('NEW', 'New/Unused'),
            ('GOOD', 'Good Condition'),
            ('FAIR', 'Fair Condition'),
            ('POOR', 'Poor Condition'),
            ('DAMAGED', 'Damaged'),
        ],
        default='GOOD',
        help_text="Condition of returned item"
    )
    notes = models.TextField(
        blank=True,
        help_text="Additional notes about this item"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Used for soft deletion"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'sales_return_item'
        verbose_name = 'Return Item'
        verbose_name_plural = 'Return Items'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['return_request']),
            models.Index(fields=['sale_item']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self):
        return f"{self.sale_item.product.name} x{self.quantity_returned} - Return {self.return_request.return_number}"

    def save(self, *args, **kwargs):
        """Auto-calculate return amount if not set"""
        if not self.return_amount:
            self.return_amount = self.sale_item.unit_price * self.quantity_returned
        super().save(*args, **kwargs)


class Refund(models.Model):
    """Refund processing for returns"""

    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('PROCESSED', 'Processed'),
        ('FAILED', 'Failed'),
        ('CANCELLED', 'Cancelled'),
    ]

    METHOD_CHOICES = [
        ('CASH', 'Cash'),
        ('BANK_TRANSFER', 'Bank Transfer'),
        ('CHECK', 'Check'),
        ('CREDIT_NOTE', 'Credit Note'),
        ('OTHER', 'Other'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    refund_number = models.CharField(
        max_length=50,
        unique=True,
        help_text="Unique refund number"
    )
    return_request = models.ForeignKey(
        Return,
        on_delete=models.CASCADE,
        related_name='refunds',
        help_text="Return request this refund is for"
    )
    amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        help_text="Amount to be refunded"
    )
    method = models.CharField(
        max_length=20,
        choices=METHOD_CHOICES,
        help_text="Refund method"
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='PENDING',
        help_text="Current status of refund"
    )
    reference_number = models.CharField(
        max_length=100,
        blank=True,
        help_text="External reference number (check number, transfer ID, etc.)"
    )
    processed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When refund was processed"
    )
    processed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='processed_refunds',
        help_text="User who processed the refund"
    )
    notes = models.TextField(
        blank=True,
        help_text="Additional notes about the refund"
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
        related_name='created_refunds',
        help_text="User who created this refund"
    )

    class Meta:
        db_table = 'sales_refund'
        verbose_name = 'Refund'
        verbose_name_plural = 'Refunds'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['refund_number']),
            models.Index(fields=['return_request']),
            models.Index(fields=['status']),
            models.Index(fields=['method']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self):
        return f"Refund {self.refund_number} - {self.return_request.return_number}"

    def save(self, *args, **kwargs):
        """Auto-generate refund number if not set"""
        if not self.refund_number:
            self.refund_number = self._generate_refund_number()
        super().save(*args, **kwargs)

    def _generate_refund_number(self):
        """Generate unique refund number"""
        today = date.today()
        year = today.year

        last_refund = Refund.objects.filter(
            refund_number__startswith=f'REF-{year}-'
        ).order_by('-refund_number').first()

        if last_refund:
            try:
                last_sequence = int(last_refund.refund_number.split('-')[-1])
                new_sequence = last_sequence + 1
            except (ValueError, IndexError):
                new_sequence = 1
        else:
            new_sequence = 1

        return f'REF-{year}-{new_sequence:04d}'

    def process(self, processed_by_user, reference_number=None):
        """Process the refund"""
        self.status = 'PROCESSED'
        self.processed_at = timezone.now()
        self.processed_by = processed_by_user
        if reference_number:
            self.reference_number = reference_number
        self.save(update_fields=['status', 'processed_at', 'processed_by', 'reference_number', 'updated_at'])

    def fail(self, failed_by_user, reason):
        """Mark refund as failed"""
        self.status = 'FAILED'
        self.notes = f"Failed: {reason}"
        self.save(update_fields=['status', 'notes', 'updated_at'])

    def cancel(self, cancelled_by_user, reason):
        """Cancel the refund"""
        self.status = 'CANCELLED'
        self.notes = f"Cancelled: {reason}"
        self.save(update_fields=['status', 'notes', 'updated_at'])


class Invoice(models.Model):
    """Invoice model for managing sale invoices and receipts"""

    INVOICE_STATUS_CHOICES = [
        ('DRAFT', 'Draft'),
        ('ISSUED', 'Issued'),
        ('SENT', 'Sent to Customer'),
        ('VIEWED', 'Viewed by Customer'),
        ('PARTIALLY_PAID', 'Partially Paid'),
        ('PAID', 'Paid'),
        ('OVERDUE', 'Overdue'),
        ('WRITTEN_OFF', 'Written Off'),
        ('CLOSED', 'Closed'),
    ]

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    sale = models.OneToOneField(
        'Sales',
        on_delete=models.CASCADE,
        related_name='invoice',
        null=True,
        blank=True,
        help_text="Associated sale (optional if order-based)"
    )
    order = models.ForeignKey(
        'orders.Order',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='invoices',
        help_text="Associated order (optional if sale-based)"
    )
    customer = models.ForeignKey(
        'customers.Customer',
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name='invoices',
        help_text="Customer for this invoice"
    )
    invoice_number = models.CharField(
        max_length=20,
        unique=True,
        help_text="Unique invoice number"
    )
    issue_date = models.DateTimeField(
        default=timezone.now,
        help_text="Date and time invoice was issued"
    )
    due_date = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Payment due date (optional)"
    )
    status = models.CharField(
        max_length=20,
        choices=INVOICE_STATUS_CHOICES,
        default='DRAFT',
        help_text="Current invoice status"
    )
    notes = models.TextField(
        blank=True,
        help_text="Additional invoice notes"
    )
    terms_conditions = models.TextField(
        blank=True,
        help_text="Terms and conditions for this invoice"
    )
    pdf_file = models.FileField(
        upload_to='invoices/',
        null=True,
        blank=True,
        help_text="Generated PDF invoice file"
    )
    email_sent = models.BooleanField(
        default=False,
        help_text="Whether invoice was emailed to customer"
    )
    email_sent_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When invoice was last emailed"
    )
    viewed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When customer last viewed the invoice"
    )
    # Payment tracking fields
    total_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total invoice amount"
    )
    amount_paid = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total amount paid against this invoice"
    )
    amount_due = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Remaining amount due"
    )
    write_off_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Amount written off for invoice closure"
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
        related_name='created_invoices',
        help_text="User who created this invoice"
    )

    class Meta:
        db_table = 'sales_invoice'
        verbose_name = 'Invoice'
        verbose_name_plural = 'Invoices'
        ordering = ['-issue_date', '-created_at']
        indexes = [
            models.Index(fields=['invoice_number']),
            models.Index(fields=['sale']),
            models.Index(fields=['status']),
            models.Index(fields=['issue_date']),
            models.Index(fields=['due_date']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self):
        return f"Invoice {self.invoice_number} - {self.sale.invoice_number}"

    def clean(self):
        """Validate model data"""
        if self.due_date:
            # Convert both to date for comparison
            due_date = self.due_date.date() if hasattr(self.due_date, 'date') else self.due_date
            issue_date = self.issue_date.date() if hasattr(self.issue_date, 'date') else self.issue_date
            if due_date < issue_date:
                raise ValidationError({'due_date': 'Due date cannot be before issue date.'})

    def save(self, *args, **kwargs):
        """Auto-generate invoice number if not set"""
        if not self.invoice_number:
            self.invoice_number = self._generate_invoice_number()

        # Auto-set due date if not specified (30 days from issue)
        if not self.due_date:
            from datetime import timedelta
            self.due_date = self.issue_date + timedelta(days=30)
            
        # Sync financial fields from associated sale/order if they exist
        if self.sale:
            # Always sync with the sale record if it exists
            self.total_amount = self.sale.grand_total
            self.amount_paid = self.sale.amount_paid
            # Don't overwrite amount_due if already handled by mark_as_written_off
            if self.status not in ['WRITTEN_OFF', 'CLOSED', 'PAID']:
                self.amount_due = self.sale.remaining_amount - (self.write_off_amount or Decimal('0.00'))
        elif self.order and self.total_amount == Decimal('0.00'):
            # Only auto-set from order if not already set (initial creation)
            self.total_amount = self.order.total_amount or Decimal('0.00')
            self.amount_paid = self.order.advance_payment or Decimal('0.00')
            self.amount_due = self.total_amount - self.amount_paid
        
        # Enforce terminal status logic: Dues must be zero
        if self.status in ['WRITTEN_OFF', 'CLOSED', 'PAID']:
            self.amount_due = Decimal('0.00')
            # For WRITTEN_OFF and CLOSED, the write_off_amount must cover the gap
            if self.status in ['WRITTEN_OFF', 'CLOSED']:
                self.write_off_amount = self.total_amount - self.amount_paid
        else:
            # Recalculate due for other statuses
            self.amount_due = max(self.total_amount - self.amount_paid - (self.write_off_amount or Decimal('0.00')), Decimal('0.00'))
        
        # Ensure name is consistent with status PAID
        if self.status == 'PAID' and self.amount_paid < self.total_amount and self.write_off_amount == 0:
            self.status = 'PARTIALLY_PAID' if self.amount_paid > 0 else 'ISSUED'
            
        super().save(*args, **kwargs)

    def _generate_invoice_number(self):
        """Generate unique invoice number"""
        today = date.today()
        year = today.year

        # Get the last invoice number for this year
        last_invoice = Invoice.objects.filter(
            invoice_number__startswith=f'INV-{year}-'
        ).order_by('-invoice_number').first()

        if last_invoice:
            try:
                # Extract the sequence number and increment
                last_sequence = int(last_invoice.invoice_number.split('-')[-1])
                new_sequence = last_sequence + 1
            except (ValueError, IndexError):
                new_sequence = 1
        else:
            new_sequence = 1

        return f'INV-{year}-{new_sequence:04d}'

    @property
    def is_overdue(self):
        """Check if invoice is overdue"""
        if self.due_date and self.status not in ['PAID', 'CANCELLED']:
            # Convert both to date for comparison
            due_date = self.due_date.date() if hasattr(self.due_date, 'date') else self.due_date
            return timezone.now().date() > due_date
        return False

    @property
    def days_until_due(self):
        """Days until payment is due"""
        if self.due_date and self.status not in ['PAID', 'CANCELLED']:
            # Convert due_date to date for calculation
            due_date = self.due_date.date() if hasattr(self.due_date, 'date') else self.due_date
            delta = due_date - timezone.now().date()
            return delta.days
        return 0

    @property
    def formatted_due_date(self):
        """Formatted due date for display"""
        if self.due_date:
            return self.due_date.strftime('%d/%m/%Y')
        return 'Not specified'

    def mark_as_sent(self):
        """Mark invoice as sent to customer"""
        self.email_sent = True
        self.email_sent_at = timezone.now()
        self.status = 'SENT'
        self.save(update_fields=['email_sent', 'email_sent_at', 'status', 'updated_at'])

    def mark_as_viewed(self):
        """Mark invoice as viewed by customer"""
        self.viewed_at = timezone.now()
        self.status = 'VIEWED'
        self.save(update_fields=['viewed_at', 'status', 'updated_at'])

    def mark_as_paid(self):
        """Mark invoice as paid"""
        self.status = 'PAID'
        self.amount_due = Decimal('0.00')
        self.amount_paid = self.total_amount - self.write_off_amount
        self.save(update_fields=['status', 'amount_due', 'amount_paid', 'updated_at'])
        
        # Sync with associated sale if exists
        if self.sale:
            self.sale.status = 'PAID'
            self.sale.amount_paid = self.sale.grand_total
            self.sale.remaining_amount = Decimal('0.00')
            self.sale.is_fully_paid = True
            self.sale.save(update_fields=['status', 'amount_paid', 'remaining_amount', 'is_fully_paid', 'updated_at'])

    def mark_as_written_off(self):
        """Mark invoice as written off and clear remaining balance"""
        self.status = 'WRITTEN_OFF'
        # Total Amount = Amount Paid + Write-Off Amount
        # Due should be 0.
        self.write_off_amount = self.total_amount - (self.amount_paid or Decimal('0.00'))
        self.amount_due = Decimal('0.00')
        self.save(update_fields=['status', 'amount_due', 'write_off_amount', 'updated_at'])
        
        # Sync with associated sale if exists
        if self.sale:
            # For sales reports, a written-off sale is effectively closed/paid 
            # as it shouldn't show up in receivables.
            self.sale.remaining_amount = Decimal('0.00')
            self.sale.is_fully_paid = True
            self.sale.save(update_fields=['remaining_amount', 'is_fully_paid', 'updated_at'])

    def cancel_invoice(self):
        """Cancel the invoice"""
        self.status = 'CANCELLED'
        self.save(update_fields=['status', 'updated_at'])

    def apply_payment(self, amount):
        """Apply a payment against this invoice and update status"""
        if amount <= Decimal('0.00'):
            raise ValueError("Payment amount must be positive")
        
        self.amount_paid = (self.amount_paid or Decimal('0.00')) + amount
        self.amount_due = self.total_amount - self.amount_paid - self.write_off_amount
        
        if self.amount_due <= Decimal('0.00'):
            self.amount_due = Decimal('0.00')
            self.status = 'PAID'
        else:
            self.status = 'PARTIALLY_PAID'
        
        self.save(update_fields=['amount_paid', 'amount_due', 'status', 'updated_at'])

    def apply_write_off(self, amount, notes=''):
        """Write off a balance for invoice closure"""
        if amount <= Decimal('0.00'):
            raise ValueError("Write-off amount must be positive")
        if amount > self.amount_due:
            raise ValueError("Write-off amount cannot exceed amount due")
        
        self.write_off_amount = (self.write_off_amount or Decimal('0.00')) + amount
        self.amount_due = self.total_amount - self.amount_paid - self.write_off_amount
        
        if notes:
            self.notes = (self.notes or '') + f"\nWrite-off: PKR {amount} - {notes}"
        
        if self.amount_due <= Decimal('0.00'):
            self.amount_due = Decimal('0.00')
            self.status = 'WRITTEN_OFF' if self.write_off_amount > Decimal('0.00') else 'PAID'
        
        self.save(update_fields=['write_off_amount', 'amount_due', 'notes', 'status', 'updated_at'])

    def update_payment_status(self):
        """Recalculate and update payment status based on amounts"""
        # If status is terminal (CLOSED, WRITTEN_OFF), ensure dues are 0.
        # This covers cases where status was updated but write-off amounts weren't adjusted.
        if self.status == 'WRITTEN_OFF':
            self.mark_as_written_off()
            return
            
        if self.status == 'CLOSED':
            # Closure implies no more payments expected.
            self.write_off_amount = self.total_amount - (self.amount_paid or Decimal('0.00'))
            self.amount_due = Decimal('0.00')
            self.save(update_fields=['amount_due', 'write_off_amount', 'updated_at'])
            return

        self.amount_due = self.total_amount - (self.amount_paid or 0) - (self.write_off_amount or 0)
        
        # Don't change status if it's already in a terminal state (PAID, CANCELLED)
        if self.status in ['PAID', 'CANCELLED']:
            self.save(update_fields=['amount_due', 'updated_at'])
            return

        if self.amount_due <= Decimal('0.00'):
            self.amount_due = Decimal('0.00')
            if self.write_off_amount > Decimal('0.00'):
                self.status = 'WRITTEN_OFF'
            else:
                self.status = 'PAID'
        elif self.amount_paid > Decimal('0.00'):
            self.status = 'PARTIALLY_PAID'
        elif self.is_overdue:
            self.status = 'OVERDUE'
        else:
            self.status = 'ISSUED'
        self.save(update_fields=['amount_due', 'status', 'updated_at'])

    @property
    def payment_percentage(self):
        """Percentage of invoice that has been paid"""
        if self.total_amount <= Decimal('0.00'):
            return Decimal('0.00')
        return (self.amount_paid / self.total_amount) * 100


class Receipt(models.Model):
    """Receipt model for managing payment receipts"""

    RECEIPT_STATUS_CHOICES = [
        ('GENERATED', 'Generated'),
        ('SENT', 'Sent to Customer'),
        ('VIEWED', 'Viewed by Customer'),
        ('ARCHIVED', 'Archived'),
    ]

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    sale = models.ForeignKey(
        'Sales',
        on_delete=models.CASCADE,
        related_name='receipts',
        help_text="Associated sale"
    )
    payment = models.ForeignKey(
        'payments.Payment',
        on_delete=models.CASCADE,
        related_name='receipts',
        null=True,
        blank=True,
        help_text="Associated payment (optional for simple receipts)"
    )
    receipt_number = models.CharField(
        max_length=20,
        unique=True,
        help_text="Unique receipt number"
    )
    generated_at = models.DateTimeField(
        default=timezone.now,
        help_text="When receipt was generated"
    )
    status = models.CharField(
        max_length=20,
        choices=RECEIPT_STATUS_CHOICES,
        default='GENERATED',
        help_text="Current receipt status"
    )
    pdf_file = models.FileField(
        upload_to='receipts/',
        null=True,
        blank=True,
        help_text="Generated PDF receipt file"
    )
    email_sent = models.BooleanField(
        default=False,
        help_text="Whether receipt was emailed to customer"
    )
    email_sent_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When receipt was last emailed"
    )
    viewed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When customer last viewed the receipt"
    )
    notes = models.TextField(
        blank=True,
        help_text="Additional receipt notes"
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
        related_name='created_receipts',
        help_text="User who generated this receipt"
    )

    class Meta:
        db_table = 'sales_receipt'
        verbose_name = 'Receipt'
        verbose_name_plural = 'Receipts'
        ordering = ['-generated_at', '-created_at']
        indexes = [
            models.Index(fields=['receipt_number']),
            models.Index(fields=['sale']),
            models.Index(fields=['payment']),
            models.Index(fields=['status']),
            models.Index(fields=['generated_at']),
            models.Index(fields=['is_active']),
        ]

    def __str__(self):
        return f"Receipt {self.receipt_number} - {self.sale.invoice_number}"

    def save(self, *args, **kwargs):
        """Auto-generate receipt number if not set"""
        if not self.receipt_number:
            self.receipt_number = self._generate_receipt_number()
        super().save(*args, **kwargs)

    def _generate_receipt_number(self):
        """Generate unique receipt number"""
        today = date.today()
        year = today.year

        last_receipt = Receipt.objects.filter(
            receipt_number__startswith=f'RCP-{year}-'
        ).order_by('-receipt_number').first()

        if last_receipt:
            try:
                last_sequence = int(last_receipt.receipt_number.split('-')[-1])
                new_sequence = last_sequence + 1
            except (ValueError, IndexError):
                new_sequence = 1
        else:
            new_sequence = 1

        return f'RCP-{year}-{new_sequence:04d}'

    def mark_as_sent(self):
        """Mark receipt as sent to customer"""
        self.email_sent = True
        self.email_sent_at = timezone.now()
        self.status = 'SENT'
        self.save(update_fields=['email_sent', 'email_sent_at', 'status', 'updated_at'])

    def mark_as_viewed(self):
        """Mark receipt as viewed by customer"""
        self.viewed_at = timezone.now()
        self.status = 'VIEWED'
        self.save(update_fields=['viewed_at', 'status', 'updated_at'])

    def archive_receipt(self):
        """Archive the receipt"""
        self.status = 'ARCHIVED'
        self.save(update_fields=['status', 'updated_at'])


class SalesQuerySet(models.QuerySet):
    """Custom QuerySet for Sales model"""

    def active(self):
        """Get active sales"""
        return self.filter(is_active=True)

    def by_status(self, status):
        """Get sales by status"""
        return self.filter(status=status.upper())

    def by_customer(self, customer_id):
        """Get sales for a specific customer"""
        return self.filter(customer_id=customer_id)

    def by_date_range(self, start_date, end_date):
        """Get sales within date range"""
        return self.filter(date_of_sale__date__range=[start_date, end_date])

    def by_payment_method(self, payment_method):
        """Get sales by payment method"""
        return self.filter(payment_method=payment_method.upper())

    def paid(self):
        """Get fully paid sales"""
        return self.filter(is_fully_paid=True)

    def unpaid(self):
        """Get unpaid or partially paid sales"""
        return self.filter(is_fully_paid=False)

    def recent(self, days=30):
        """Get sales from last N days"""
        cutoff_date = timezone.now() - timezone.timedelta(days=days)
        return self.filter(date_of_sale__gte=cutoff_date)

    def today(self):
        """Get today's sales"""
        today = date.today()
        return self.filter(date_of_sale__date=today)

    def this_month(self):
        """Get this month's sales"""
        today = date.today()
        return self.filter(
            date_of_sale__year=today.year,
            date_of_sale__month=today.month
        )

    def this_year(self):
        """Get this year's sales"""
        return self.filter(date_of_sale__year=date.today().year)

    def search(self, query):
        """Search sales by invoice number, customer name, phone, or notes"""
        return self.filter(
            models.Q(invoice_number__icontains=query) |
            models.Q(customer_name__icontains=query) |
            models.Q(customer_phone__icontains=query) |
            models.Q(customer_email__icontains=query) |
            models.Q(notes__icontains=query)
        )

    def by_order(self, order_id):
        """Get sales created from a specific order"""
        return self.filter(order_id=order_id)


class Sales(models.Model):
    """Sales model for managing complete sales transactions"""

    # Sale Status Choices
    STATUS_CHOICES = [
        ('DRAFT', 'Draft'),
        ('CONFIRMED', 'Confirmed'),
        ('INVOICED', 'Invoiced'),
        ('PAID', 'Paid'),
        ('DELIVERED', 'Delivered'),
        ('CANCELLED', 'Cancelled'),
        ('RETURNED', 'Returned'),
    ]

    # Payment Method Choices
    PAYMENT_METHOD_CHOICES = [
        ('CASH', 'Cash'),
        ('CARD', 'Credit/Debit Card'),
        ('BANK_TRANSFER', 'Bank Transfer'),
        ('MOBILE_PAYMENT', 'Mobile Payment (JazzCash/EasyPaisa)'),
        ('SPLIT', 'Split Payment'),
        ('CREDIT', 'Credit Sale'),
    ]

    # Primary fields
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    invoice_number = models.CharField(
        max_length=20,
        unique=True,
        default=generate_invoice_number,
        help_text="Auto-generated invoice number"
    )
    order_id = models.ForeignKey(
        'orders.Order',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='sales',
        help_text="Optional: Order this sale was created from"
    )
    customer = models.ForeignKey(
        'customers.Customer',
        on_delete=models.PROTECT,
        related_name='sales',
        null=True,
        blank=True,
        help_text="Customer making the purchase (optional for walk-in sales)"
    )

    # Cached customer information for historical accuracy
    customer_name = models.CharField(
        max_length=200,
        default='Walk-in Customer',
        help_text="Cached customer name at time of sale"
    )
    customer_phone = models.CharField(
        max_length=20,
        default='',
        blank=True,
        help_text="Cached customer contact at time of sale"
    )
    customer_email = models.EmailField(
        blank=True,
        help_text="Cached customer email at time of sale"
    )

    # Financial fields
    subtotal = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Sum of all line items before discounts"
    )
    overall_discount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total discount applied to entire sale"
    )
    gst_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="GST tax rate (default 17% for Pakistan)"
    )

    tax_configuration = models.JSONField(
        default=dict,
        blank=True,
        help_text="Flexible tax configuration as JSON"
    )
    tax_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Calculated GST amount"
    )
    grand_total = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Final amount after discounts and taxes"
    )
    amount_paid = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total amount received from customer"
    )
    remaining_amount = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Outstanding balance"
    )
    is_fully_paid = models.BooleanField(
        default=False,
        help_text="Payment completion status"
    )

    # Payment details
    payment_method = models.CharField(
        max_length=20,
        choices=PAYMENT_METHOD_CHOICES,
        default='CASH',
        help_text="Method of payment"
    )
    split_payment_details = models.JSONField(
        default=dict,
        blank=True,
        help_text="Details for multiple payment methods when payment_method='Split'"
    )

    # Sale details
    date_of_sale = models.DateTimeField(
        default=timezone.now,
        help_text="Transaction timestamp"
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='DRAFT',
        help_text="Current sale status"
    )
    notes = models.TextField(
        blank=True,
        help_text="Additional sale information or special instructions"
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
        related_name='created_sales',
        help_text="Sales person who processed the transaction"
    )

    objects = SalesQuerySet.as_manager()

    class Meta:
        db_table = 'sales'
        verbose_name = 'Sale'
        verbose_name_plural = 'Sales'
        ordering = ['-date_of_sale', '-created_at']
        indexes = [
            models.Index(fields=['date_of_sale', '-created_at']),
            models.Index(fields=['status', 'is_active']),
            models.Index(fields=['invoice_number']),
            models.Index(fields=['customer']),
            models.Index(fields=['order_id']),
            models.Index(fields=['status']),
            models.Index(fields=['payment_method']),
            models.Index(fields=['date_of_sale']),
            models.Index(fields=['is_fully_paid']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f"{self.invoice_number} - {self.customer_name} ({self.get_status_display()})"

    def clean(self):
        """Validate model data"""
        if self.subtotal < 0:
            raise ValidationError({'subtotal': 'Subtotal cannot be negative.'})

        if self.overall_discount < 0:
            raise ValidationError({'overall_discount': 'Discount cannot be negative.'})

        # Calculate actual subtotal from sale items for validation
        # This handles the case where subtotal hasn't been calculated yet
        actual_subtotal = self.subtotal
        
        # If subtotal is 0 but we have sale items, calculate from items
        if actual_subtotal == 0 and hasattr(self, '_sale_items'):
            actual_subtotal = sum(item.line_total for item in self._sale_items)
        
        # If still 0, try to get from the serializer context (during creation)
        if actual_subtotal == 0 and hasattr(self, '_validated_sale_items_data'):
            actual_subtotal = Decimal('0.00')
            for item_data in self._validated_sale_items_data:
                unit_price = Decimal(str(item_data.get('unit_price', 0)))
                quantity = int(item_data.get('quantity', 0))
                item_discount = Decimal(str(item_data.get('item_discount', 0)))
                line_total = (quantity * unit_price) - item_discount
                actual_subtotal += line_total

        # Validate overall discount against actual subtotal
        if actual_subtotal > 0 and self.overall_discount > actual_subtotal:
            raise ValidationError({
                'overall_discount': f'Discount cannot exceed subtotal. Discount: {self.overall_discount}, Subtotal: {actual_subtotal}'
            })

        if self.gst_percentage < 0 or self.gst_percentage > 100:
            raise ValidationError({'gst_percentage': 'GST percentage must be between 0 and 100.'})

        if self.amount_paid < 0:
            raise ValidationError({'amount_paid': 'Amount paid cannot be negative.'})

        # ✅ REMOVED: Allow partial payments for wholesale business model
        # The validation "amount_paid > grand_total" has been removed
        # to support partial payments and flexible payment scenarios

        # Validate split payment details
        if self.payment_method == 'SPLIT' and not self.split_payment_details:
            raise ValidationError({'split_payment_details': 'Split payment details are required when payment method is Split.'})

    def save(self, *args, **kwargs):
        """Auto-calculate financial fields and validate before saving"""
        # Cache customer information if not set
        if self.customer:
            if not self.customer_name or self.customer_name == 'Walk-in Customer':
                self.customer_name = self.customer.name

            if not self.customer_phone:
                self.customer_phone = self.customer.phone

            if not self.customer_email:
                self.customer_email = self.customer.email

        # Calculate tax amount
        if self.subtotal and self.overall_discount is not None and self.gst_percentage:
            taxable_amount = self.subtotal - self.overall_discount
            self.tax_amount = (taxable_amount * self.gst_percentage) / 100

        # Calculate grand total
        if self.subtotal is not None and self.overall_discount is not None and self.tax_amount is not None:
            self.grand_total = self.subtotal - self.overall_discount + self.tax_amount

        # Calculate remaining amount
        if self.grand_total is not None and self.amount_paid is not None:
            self.remaining_amount = self.grand_total - self.amount_paid

        # Update payment status
        if self.grand_total and self.amount_paid is not None:
            self.is_fully_paid = self.amount_paid >= self.grand_total

        self.full_clean()
        super().save(*args, **kwargs)

    @property
    def sales_age_days(self):
        """Days since sale was created"""
        return (timezone.now().date() - self.date_of_sale.date()).days

    @property
    def formatted_grand_total(self):
        """Currency formatted grand total (PKR format)"""
        return f"PKR {self.grand_total:,.2f}"

    @property
    def formatted_remaining_amount(self):
        """Currency formatted outstanding balance"""
        return f"PKR {self.remaining_amount:,.2f}"

    @property
    def payment_percentage(self):
        """Percentage of payment completed"""
        if self.grand_total > 0:
            return (self.amount_paid / self.grand_total) * 100
        return 0

    @property
    def sales_summary(self):
        """Short summary for display purposes"""
        return f"{self.invoice_number} - {self.customer_name} - {self.formatted_grand_total}"

    @property
    def authorized_initials(self):
        """Initials of sales person who created the sale"""
        if self.created_by:
            full_name = getattr(self.created_by, 'full_name', None) or self.created_by.username
            return ''.join([name[0].upper() for name in full_name.split()])
        return ''

    @property
    def invoice_display(self):
        """Formatted invoice number for display"""
        return f"#{self.invoice_number}"

    @property
    def payment_status_display(self):
        """Human readable payment status"""
        if self.is_fully_paid:
            return "Fully Paid"
        elif self.amount_paid > 0:
            return f"Partially Paid ({self.payment_percentage:.1f}%)"
        else:
            return "Unpaid"

    @property
    def total_items(self):
        """Count of items in this sale"""
        return self.sale_items.count()

    @property
    def profit_margin(self):
        """Calculated profit from this sale (if cost data available)"""
        # This would need to be implemented based on product cost data
        # For now, return None
        return None

    @property
    def tax_breakdown(self):
        """Detailed tax calculation breakdown"""
        taxable_amount = self.subtotal - self.overall_discount
        return {
            'taxable_amount': taxable_amount,
            'gst_percentage': self.gst_percentage,
            'gst_amount': self.tax_amount,
            'tax_rate_display': f"{self.gst_percentage}%"
        }

    @property
    def tax_summary_display(self):
        """Summary of tax for display"""
        if self.gst_percentage > 0:
            return f"GST {self.gst_percentage}%"
        return "No Tax"

    def can_be_cancelled(self):
        """Check if sale can be cancelled"""
        return self.status in ['DRAFT', 'CONFIRMED', 'INVOICED']

    def can_be_returned(self):
        """Check if sale can be returned"""
        return self.status == 'DELIVERED' and self.is_fully_paid

    def update_payment_status(self):
        """Update payment status based on amount paid"""
        if self.grand_total > 0:
            self.is_fully_paid = self.amount_paid >= self.grand_total
            self.remaining_amount = max(0, self.grand_total - self.amount_paid)
            self.save(update_fields=['is_fully_paid', 'remaining_amount'])

    def recalculate_totals(self):
        """Safely recalculate sale totals"""
        import logging
        logger = logging.getLogger(__name__)

        try:
            # Calculate subtotal
            total_subtotal = sum(item.line_total for item in self.sale_items.all())
            self.subtotal = total_subtotal

            # Calculate tax and grand total
            taxable_amount = self.subtotal - self.overall_discount

            # Calculate tax based on configuration if available, otherwise fall back to GST
            tax_amount = Decimal('0.00')

            if hasattr(self, 'tax_configuration') and self.tax_configuration:
                try:
                    for tax_key, tax_data in self.tax_configuration.items():
                        if isinstance(tax_data, dict) and 'percentage' in tax_data:
                            percentage = Decimal(str(tax_data['percentage']))
                            tax_amount += (taxable_amount * percentage) / Decimal('100')
                except Exception as tax_error:
                    logger.warning(f"Error calculating details from tax_configuration: {tax_error}")
                    # Fallback to standard GST if configured
                    if self.gst_percentage:
                        tax_amount = (taxable_amount * self.gst_percentage) / 100
            elif self.gst_percentage:
                tax_amount = (taxable_amount * self.gst_percentage) / 100

            self.tax_amount = tax_amount
            self.grand_total = self.subtotal - self.overall_discount + self.tax_amount

            # Update payment status
            self.update_payment_status()

            # Define fields to update
            update_fields = ['subtotal', 'tax_amount', 'grand_total', 'remaining_amount', 'is_fully_paid']

            self.save(update_fields=update_fields)
            logger.info(f"✅ Recalculated totals for {self.invoice_number}: {self.grand_total}")

        except Exception as e:
            logger.error(f"Failed to recalculate totals for sale {self.invoice_number}: {str(e)}")
            # Do not raise exception to avoid blocking the main transaction if this is called from signal


class SaleItemQuerySet(models.QuerySet):
    """Custom QuerySet for SaleItem model"""

    def active(self):
        """Get active sale items"""
        return self.filter(is_active=True)

    def by_sale(self, sale_id):
        """Get items for a specific sale"""
        return self.filter(sale_id=sale_id)

    def by_product(self, product_id):
        """Get sale items for a specific product"""
        return self.filter(product_id=product_id)

    def by_order_item(self, order_item_id):
        """Get sale items created from a specific order item"""
        return self.filter(order_item=order_item_id)

    def search(self, query):
        """Search sale items by product name or customization notes"""
        return self.filter(
            models.Q(product_name__icontains=query) |
            models.Q(customization_notes__icontains=query)
        )


class SaleItem(models.Model):
    """Sale Item model for managing individual products within sales"""

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    sale = models.ForeignKey(
        Sales,
        on_delete=models.CASCADE,
        related_name='sale_items',
        help_text="Parent sale transaction"
    )
    order_item = models.UUIDField(
        null=True,
        blank=True,
        help_text="Optional: Order item ID this sale item was created from"
    )
    product = models.ForeignKey(
        'products.Product',
        on_delete=models.PROTECT,
        related_name='sale_items',
        help_text="Sold product reference"
    )
    product_name = models.CharField(
        max_length=200,
        help_text="Cached product name at time of sale"
    )
    unit_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        help_text="Selling price per unit at time of sale"
    )
    quantity = models.PositiveIntegerField(
        help_text="Number of units sold"
    )
    item_discount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Discount applied to this specific item"
    )
    line_total = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        help_text="Total for this line after discount"
    )
    customization_notes = models.TextField(
        blank=True,
        help_text="Inherited from order item or new customizations"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Used for soft deletion"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = SaleItemQuerySet.as_manager()

    class Meta:
        db_table = 'sale_item'
        verbose_name = 'Sale Item'
        verbose_name_plural = 'Sale Items'
        ordering = ['sale', 'created_at']
        indexes = [
            models.Index(fields=['sale']),
            models.Index(fields=['order_item']),
            models.Index(fields=['product']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f"{self.product_name} x{self.quantity} in {self.sale.invoice_number}"

    def clean(self):
        """Validate model data"""
        if self.quantity <= 0:
            raise ValidationError({'quantity': 'Quantity must be greater than zero.'})

        if self.unit_price < 0:
            raise ValidationError({'unit_price': 'Unit price cannot be negative.'})

        if self.item_discount < 0:
            raise ValidationError({'item_discount': 'Item discount cannot be negative.'})

        # Validate line total calculation
        if self.quantity and self.unit_price:
            expected_total = self.quantity * self.unit_price - self.item_discount
            if self.line_total != expected_total:
                self.line_total = expected_total

    def save(self, *args, **kwargs):
        """Auto-populate fields and calculate totals before saving"""
        # Auto-populate product name and unit price from product if not set
        if self.product and not self.product_name:
            self.product_name = self.product.name

        if self.product and not self.unit_price:
            self.unit_price = self.product.price

        # Calculate line total
        if self.quantity and self.unit_price:
            self.line_total = (self.quantity * self.unit_price) - self.item_discount

        self.full_clean()
        super().save(*args, **kwargs)

    @property
    def discounted_unit_price(self):
        """Unit price after item-specific discount"""
        if self.quantity > 0:
            return self.line_total / self.quantity
        return self.unit_price

    @property
    def total_before_discount(self):
        """Line total before any discounts applied"""
        return self.quantity * self.unit_price

    @property
    def discount_percentage(self):
        """Percentage discount applied to this item"""
        if self.total_before_discount > 0:
            return (self.item_discount / self.total_before_discount) * 100
        return 0

    @property
    def item_profit(self):
        """Profit margin for this specific item"""
        # This would need to be implemented based on product cost data
        # For now, return None
        return None

    @property
    def formatted_line_total(self):
        """Currency formatted line total"""
        return f"PKR {self.line_total:,.2f}"

    @property
    def product_info_at_sale(self):
        """Product details captured at time of sale"""
        return {
            'name': self.product_name,
            'unit_price': self.unit_price,
            'quantity': self.quantity,
            'customization_notes': self.customization_notes
        }