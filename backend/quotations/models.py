import uuid
from django.db import models
from django.conf import settings
from django.utils import timezone
from decimal import Decimal
from datetime import timedelta

class Quotation(models.Model):
    """Quotation model for event rental quotes"""
    
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('ACCEPTED', 'Accepted'),
        ('CONVERTED', 'Converted to Order'),
        ('REJECTED', 'Rejected'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Customer Details
    customer = models.ForeignKey(
        'customers.Customer', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='quotations'
    )
    company_name = models.CharField(max_length=200, blank=True, null=True)
    customer_name = models.CharField(max_length=200, help_text="Contact person name")
    customer_phone = models.CharField(max_length=20, blank=True, null=True)
    
    # Event Details
    event_name = models.CharField(max_length=200, help_text="e.g. Wedding, Corporate Launch")
    event_location = models.CharField(max_length=500, blank=True, null=True)
    event_date = models.DateField(null=True, blank=True)
    return_date = models.DateField(null=True, blank=True)
    
    # Quotation Info
    quotation_number = models.CharField(max_length=50, unique=True, blank=True)
    valid_until = models.DateField(default=timezone.now().date() + timedelta(days=15))
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    
    # Financials
    total_amount = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    discount_amount = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    final_amount = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    
    # Terms and Notes
    special_notes = models.TextField(blank=True, null=True, help_text="Terms, damage charges, advance payment rules")
    
    # System fields
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_quotations'
    )

    class Meta:
        db_table = 'quotation'
        ordering = ['-created_at']

    def __str__(self):
        return f"Quote {self.quotation_number or self.id} - {self.customer_name}"

    def save(self, *args, **kwargs):
        if not self.quotation_number:
            # Generate a simple quotation number: QTE-YYYYMMDD-XXXX
            today = timezone.localdate()
            today_str = today.strftime('%Y%m%d')
            
            # Since generating numbers by count can have race conditions or timezone issues,
            # let's find the max quotation number for today instead.
            last_quote = Quotation.objects.filter(quotation_number__startswith=f"QTE-{today_str}-").order_by('quotation_number').last()
            
            if last_quote:
                try:
                    count = int(last_quote.quotation_number.split('-')[-1]) + 1
                except ValueError:
                    count = 1
            else:
                count = 1
                
            self.quotation_number = f"QTE-{today_str}-{count:04d}"
        
        self.final_amount = self.total_amount - self.discount_amount
        super().save(*args, **kwargs)

    def calculate_totals(self):
        """Recalculate total amount from items"""
        total = self.items.aggregate(total=models.Sum('total'))['total'] or Decimal('0.00')
        self.total_amount = total
        self.save()

class QuotationItem(models.Model):
    """Items included in a quotation"""
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    quotation = models.ForeignKey(Quotation, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey('products.Product', on_delete=models.SET_NULL, null=True, blank=True)
    product_name = models.CharField(max_length=255, blank=True, null=True, help_text="Manual name if product is not selected")
    
    quantity = models.PositiveIntegerField(default=1)
    rate = models.DecimalField(max_digits=12, decimal_places=2, help_text="Rate per day or per event")
    days = models.PositiveIntegerField(default=1, help_text="Number of days for rental")
    
    PRICING_TYPE_CHOICES = [
        ('PER_DAY', 'Per Day'),
        ('PER_EVENT', 'Per Event'),
        ('FIXED', 'Fixed Price'),
    ]
    pricing_type = models.CharField(max_length=20, choices=PRICING_TYPE_CHOICES, default='PER_DAY')
    
    # Partner/Sub-rental fields
    rented_from_partner = models.BooleanField(
        default=False,
        help_text="Whether this item is rented from a partner"
    )
    partner = models.ForeignKey(
        'vendors.Vendor',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='partner_quotations',
        help_text="Partner from whom this item is intended to be rented"
    )
    partner_rate = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Rate expected from the partner"
    )
    
    total = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    
    def save(self, *args, **kwargs):
        if self.pricing_type in ['PER_EVENT', 'FIXED']:
            self.total = Decimal(str(self.quantity)) * self.rate
        else:
            self.total = Decimal(str(self.quantity)) * self.rate * Decimal(str(self.days))
        super().save(*args, **kwargs)
        # Update parent quotation total
        self.quotation.calculate_totals()

    def __str__(self):
        name = self.product.name if self.product else self.product_name
        return f"{name} x {self.quantity} for {self.quotation.id}"
