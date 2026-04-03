from decimal import Decimal
import uuid
import re
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import EmailValidator
from django.utils import timezone
from datetime import timedelta


class Customer(models.Model):
    """Customer model for managing customer information and relationships"""
    
    # Customer Status Choices
    STATUS_CHOICES = [
        ('NEW', 'New Customer'),
        ('REGULAR', 'Regular Customer'),
        ('VIP', 'VIP Customer'),
        ('INACTIVE', 'Inactive Customer'),
    ]
    
    # Customer Type Choices
    TYPE_CHOICES = [
        ('INDIVIDUAL', 'Individual'),
        ('BUSINESS', 'Business'),
    ]
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    name = models.CharField(
        max_length=200,
        help_text="Customer full name"
    )
    phone = models.CharField(
        max_length=20,
        unique=True,
        help_text="Customer phone number (any format)"
    )
    email = models.EmailField(
        unique=True,
        null=True,
        blank=True,
        validators=[EmailValidator()],
        help_text="Customer email address"
    )
    address = models.TextField(
        blank=True,
        help_text="Customer address"
    )
    city = models.CharField(
        max_length=100,
        blank=True,
        help_text="Customer city/location"
    )
    country = models.CharField(
        max_length=100,
        default='Pakistan',
        help_text="Customer country"
    )
    customer_type = models.CharField(
        max_length=20,
        choices=TYPE_CHOICES,
        default='INDIVIDUAL',
        help_text="Type of customer"
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='NEW',
        help_text="Customer status"
    )
    notes = models.TextField(
        blank=True,
        help_text="Additional notes about the customer"
    )
    
    # Contact verification
    phone_verified = models.BooleanField(
        default=False,
        help_text="Whether phone number is verified"
    )
    email_verified = models.BooleanField(
        default=False,
        help_text="Whether email is verified"
    )
    
    # Business fields
    business_name = models.CharField(
        max_length=200,
        blank=True,
        help_text="Business name (for business customers)"
    )
    tax_number = models.CharField(
        max_length=50,
        blank=True,
        help_text="Tax/NTN number (for business customers)"
    )
    
    # Timestamps and metadata
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
        related_name='created_customers'
    )
    
    # Activity tracking
    last_order_date = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Date of last order"
    )
    last_contact_date = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Date of last contact"
    )

    class Meta:
        db_table = 'customer'
        verbose_name = 'Customer'
        verbose_name_plural = 'Customers'
        ordering = ['-created_at', 'name']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['phone']),
            models.Index(fields=['email']),
            models.Index(fields=['status']),
            models.Index(fields=['customer_type']),
            models.Index(fields=['is_active']),
            models.Index(fields=['country']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        country_flag = f" ({self.country})" if self.country != 'Pakistan' else ""
        return f"{self.name} ({self.phone}){country_flag}"

    def clean(self):
        """Validate model data"""
        # Clean and validate name
        if self.name:
            self.name = self.name.strip()
            if not self.name:
                raise ValidationError({'name': 'Customer name cannot be empty.'})
        
        # Clean phone number (optional formatting)
        if self.phone:
            self.phone = self.phone.strip()
            # Optional: Auto-format Pakistani numbers
            if not self.phone.startswith('+') and re.match(r'^03\d{9}$', self.phone):
                self.phone = f"+92-{self.phone[1:4]}-{self.phone[4:]}"
        
        # Clean other fields
        if self.email:
            self.email = self.email.strip().lower()
            if not self.email:
                self.email = None
        if self.address:
            self.address = self.address.strip()
        if self.city:
            self.city = self.city.strip().title()
        if self.country:
            self.country = self.country.strip().title()
        if self.business_name:
            self.business_name = self.business_name.strip()
        if self.tax_number:
            self.tax_number = self.tax_number.strip().upper()
        
        # Business customer validation
        if self.customer_type == 'BUSINESS' and not self.business_name:
            raise ValidationError({'business_name': 'Business name is required for business customers.'})

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)

    # Properties
    @property
    def display_name(self):
        """Get display name for customer"""
        if self.customer_type == 'BUSINESS' and self.business_name:
            return f"{self.business_name} ({self.name})"
        return self.name

    @property
    def is_new_customer(self):
        """Check if customer is new (created within last 30 days)"""
        thirty_days_ago = timezone.now() - timedelta(days=30)
        return self.created_at >= thirty_days_ago

    @property
    def is_recent_customer(self):
        """Check if customer was active recently (last order within 90 days)"""
        if not self.last_order_date:
            return False
        ninety_days_ago = timezone.now() - timedelta(days=90)
        return self.last_order_date >= ninety_days_ago

    @property
    def customer_age_days(self):
        """Get customer age in days"""
        return (timezone.now() - self.created_at).days

    @property
    def is_pakistani_customer(self):
        """Check if customer is Pakistani"""
        return (
            (self.country and self.country.lower() in ['pakistan', 'pk']) or
            (self.phone and self.phone.startswith('+92'))
        )

    @property
    def phone_country_code(self):
        """Extract country code from phone number"""
        if not self.phone or not self.phone.startswith('+'):
            return None
        match = re.match(r'^\+(\d{1,4})', self.phone)
        return f"+{match.group(1)}" if match else None

    @property
    def formatted_country_phone(self):
        """Get country name based on phone country code"""
        country_codes = {
            '+92': 'Pakistan', '+1': 'US/Canada', '+44': 'UK',
            '+91': 'India', '+971': 'UAE', '+966': 'Saudi Arabia'
        }
        code = self.phone_country_code
        return country_codes.get(code, f'International ({code})' if code else 'Unknown')

    # Helper methods
    def get_initials(self):
        """Get customer initials for avatar"""
        words = self.name.split()
        if len(words) >= 2:
            return f"{words[0][0]}{words[1][0]}".upper()
        elif len(words) == 1:
            return words[0][:2].upper()
        return "CU"

    def soft_delete(self):
        """Soft delete the customer"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])

    def restore(self):
        """Restore a soft-deleted customer"""
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])

    def verify_phone(self):
        """Mark phone as verified"""
        self.phone_verified = True
        self.save(update_fields=['phone_verified', 'updated_at'])

    def verify_email(self):
        """Mark email as verified"""
        self.email_verified = True
        self.save(update_fields=['email_verified', 'updated_at'])

    def update_last_order_date(self, order_date=None):
        """Update last order date"""
        if order_date is None:
            order_date = timezone.now()
        self.last_order_date = order_date
        self.save(update_fields=['last_order_date', 'updated_at'])

    def update_last_contact_date(self, contact_date=None):
        """Update last contact date"""
        if contact_date is None:
            contact_date = timezone.now()
        self.last_contact_date = contact_date
        self.save(update_fields=['last_contact_date', 'updated_at'])

    def update_status_based_on_activity(self):
        """Auto-update customer status based on activity"""
        if not self.last_order_date:
            if self.is_new_customer:
                self.status = 'NEW'
            else:
                self.status = 'INACTIVE'
        else:
            if self.is_recent_customer:
                if self.status not in ['VIP', 'REGULAR']:
                    self.status = 'REGULAR'
            else:
                self.status = 'INACTIVE'
        self.save(update_fields=['status', 'updated_at'])

    @property
    def total_sales_amount(self):
        """Get total sales amount for this customer"""
        from django.db.models import Sum
        return self.sales.aggregate(
            total=Sum('grand_total')
        )['total'] or Decimal('0.00')

    @property  
    def total_sales_count(self):
        """Get total number of sales for this customer"""
        return self.sales.filter(is_active=True).count()

    def update_last_sale_date(self, sale_date=None):
        """Update last order date when sale is created"""
        if sale_date is None:
            sale_date = timezone.now()
        self.last_order_date = sale_date  # Reuse existing field
        self.save(update_fields=['last_order_date', 'updated_at'])

    def update_sales_metrics(self):
        """Update sales metrics for this customer"""
        try:
            # This method is called by sales signals to update customer metrics
            # The metrics are already calculated via properties, so we just need to ensure
            # the customer is saved to trigger any necessary updates
            self.save(update_fields=['updated_at'])
        except Exception as e:
            # Log error but don't fail the operation
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to update sales metrics for customer {self.name}: {str(e)}")

    def update_credit_usage(self, credit_amount):
        """Update customer credit usage when credit sale is created"""
        try:
            # This method is called by sales signals to update credit usage
            # For now, we'll just log the credit usage
            import logging
            logger = logging.getLogger(__name__)
            logger.info(f"Credit usage updated for customer {self.name}: PKR {credit_amount:,.2f}")
            
            # You can extend this to track credit limits, payment history, etc.
            # For example:
            # if hasattr(self, 'credit_limit'):
            #     self.credit_limit -= credit_amount
            #     self.save(update_fields=['credit_limit', 'updated_at'])
            
        except Exception as e:
            # Log error but don't fail the operation
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to update credit usage for customer {self.name}: {str(e)}")

    # Enhanced Sales Integration Properties and Methods
    @property
    def average_sale_amount(self):
        """Get average sale amount for this customer"""
        if self.total_sales_count == 0:
            return Decimal('0.00')
        return self.total_sales_amount / self.total_sales_count

    @property
    def last_sale_date(self):
        """Get date of last sale"""
        last_sale = self.sales.filter(is_active=True).order_by('-created_at').first()
        return last_sale.created_at.date() if last_sale else None

    @property
    def sales_frequency_days(self):
        """Get average days between sales"""
        if self.total_sales_count < 2:
            return None
        
        sales_dates = list(self.sales.filter(is_active=True).order_by('created_at').values_list('created_at', flat=True))
        if len(sales_dates) < 2:
            return None
        
        total_days = 0
        for i in range(1, len(sales_dates)):
            days_between = (sales_dates[i] - sales_dates[i-1]).days
            total_days += days_between
        
        return round(total_days / (len(sales_dates) - 1), 1)

    @property
    def customer_lifetime_value(self):
        """Calculate customer lifetime value (CLV)"""
        return self.total_sales_amount

    @property
    def sales_trend(self):
        """Get sales trend (increasing, decreasing, stable)"""
        if self.total_sales_count < 3:
            return 'insufficient_data'
        
        recent_sales = self.sales.filter(is_active=True).order_by('-created_at')[:3]
        if len(recent_sales) < 3:
            return 'insufficient_data'
        
        amounts = [sale.grand_total for sale in recent_sales]
        if amounts[0] > amounts[1] > amounts[2]:
            return 'increasing'
        elif amounts[0] < amounts[1] < amounts[2]:
            return 'decreasing'
        else:
            return 'stable'

    def get_sales_by_period(self, days=30):
        """Get sales within specified period"""
        from django.utils import timezone
        cutoff_date = timezone.now() - timedelta(days=days)
        return self.sales.filter(
            is_active=True,
            created_at__gte=cutoff_date
        )

    def get_sales_statistics(self):
        """Get comprehensive sales statistics for this customer"""
        from django.db.models import Sum
        active_sales = self.sales.filter(is_active=True)
        
        # Payment status breakdown
        payment_status = {
            'fully_paid': active_sales.filter(is_fully_paid=True).count(),
            'partially_paid': active_sales.filter(is_fully_paid=False).count(),
        }
        
        # Sales by status
        status_breakdown = {}
        for sale in active_sales:
            status = sale.status
            status_breakdown[status] = status_breakdown.get(status, 0) + 1
        
        # Recent activity
        recent_sales = self.get_sales_by_period(30)
        recent_sales_count = recent_sales.count()
        recent_sales_amount = recent_sales.aggregate(
            total=Sum('grand_total')
        )['total'] or Decimal('0.00')
        
        return {
            'total_sales': self.total_sales_count,
            'total_amount': float(self.total_sales_amount),
            'average_amount': float(self.average_sale_amount),
            'payment_status': payment_status,
            'status_breakdown': status_breakdown,
            'recent_activity': {
                'sales_last_30_days': recent_sales_count,
                'amount_last_30_days': float(recent_sales_amount),
            },
            'lifetime_value': float(self.customer_lifetime_value),
            'sales_trend': self.sales_trend,
            'last_sale_date': self.last_sale_date,
        }

    def update_customer_status_based_on_sales(self):
        """Update customer status based on sales activity"""
        if self.total_sales_count == 0:
            if self.is_new_customer:
                self.status = 'NEW'
            else:
                self.status = 'INACTIVE'
        elif self.total_sales_count >= 10 and self.average_sale_amount >= 50000:
            self.status = 'VIP'
        elif self.total_sales_count >= 3 or self.is_recent_customer:
            self.status = 'REGULAR'
        else:
            self.status = 'INACTIVE'
        
        self.save(update_fields=['status', 'updated_at'])

    # Class methods
    @classmethod
    def active_customers(cls):
        """Return only active customers"""
        return cls.objects.filter(is_active=True)

    @classmethod
    def new_customers(cls, days=30):
        """Get customers created within specified days"""
        cutoff_date = timezone.now() - timedelta(days=days)
        return cls.active_customers().filter(created_at__gte=cutoff_date)

    @classmethod
    def recent_customers(cls, days=7):
        """Get recently added customers"""
        cutoff_date = timezone.now() - timedelta(days=days)
        return cls.active_customers().filter(created_at__gte=cutoff_date)

    @classmethod
    def inactive_customers(cls, days=90):
        """Get customers inactive for specified days"""
        cutoff_date = timezone.now() - timedelta(days=days)
        return cls.active_customers().filter(
            models.Q(last_order_date__lt=cutoff_date) | models.Q(last_order_date__isnull=True)
        ).exclude(created_at__gte=cutoff_date)

    @classmethod
    def customers_by_status(cls, status):
        """Get customers by status"""
        return cls.active_customers().filter(status=status)

    @classmethod
    def customers_by_type(cls, customer_type):
        """Get customers by type"""
        return cls.active_customers().filter(customer_type=customer_type)

    @classmethod
    def get_statistics(cls):
        """Get comprehensive customer statistics"""
        active_customers = cls.active_customers()
        total_customers = active_customers.count()
        new_customers_count = cls.new_customers().count()
        recent_customers_count = cls.recent_customers().count()
        inactive_customers_count = cls.inactive_customers().count()
        
        # Status breakdown
        status_breakdown = {}
        for status, _ in cls.STATUS_CHOICES:
            status_breakdown[status.lower()] = active_customers.filter(status=status).count()
        
        # Type breakdown
        type_breakdown = {}
        for customer_type, _ in cls.TYPE_CHOICES:
            type_breakdown[customer_type.lower()] = active_customers.filter(
                customer_type=customer_type
            ).count()
        
        # Verification stats
        phone_verified_count = active_customers.filter(phone_verified=True).count()
        email_verified_count = active_customers.filter(email_verified=True).count()
        both_verified_count = active_customers.filter(
            phone_verified=True, email_verified=True
        ).count()
        
        # Country breakdown (top 10)
        country_breakdown = list(
            active_customers.exclude(country='')
            .values('country')
            .annotate(count=models.Count('id'))
            .order_by('-count')[:10]
        )
        
        return {
            'total_customers': total_customers,
            'new_customers_this_month': new_customers_count,
            'recent_customers_this_week': recent_customers_count,
            'inactive_customers': inactive_customers_count,
            'status_breakdown': status_breakdown,
            'type_breakdown': type_breakdown,
            'verification_stats': {
                'phone_verified': phone_verified_count,
                'email_verified': email_verified_count,
                'both_verified': both_verified_count,
                'phone_verification_rate': round(
                    (phone_verified_count / total_customers * 100) if total_customers > 0 else 0, 2
                ),
                'email_verification_rate': round(
                    (email_verified_count / total_customers * 100) if total_customers > 0 else 0, 2
                ),
            },
            'top_countries': country_breakdown,
        }

    def get_has_recent_sales(self):
        """Check if customer has sales in last 90 days"""
        try:
            cutoff_date = timezone.now() - timedelta(days=90)
            return self.sales.filter(date_of_sale__gte=cutoff_date, is_active=True).exists()
        except Exception:
            return False


class CustomerQuerySet(models.QuerySet):
    """Custom QuerySet for Customer model"""
    
    def active(self):
        return self.filter(is_active=True)
    
    def by_status(self, status):
        return self.filter(status=status.upper())
    
    def by_type(self, customer_type):
        return self.filter(customer_type=customer_type.upper())
    
    def search(self, query):
        """Search customers by name, phone, email, or business name"""
        return self.filter(
            models.Q(name__icontains=query) |
            models.Q(phone__icontains=query) |
            models.Q(email__icontains=query) |
            models.Q(business_name__icontains=query) |
            models.Q(city__icontains=query)
        )
    
    def by_city(self, city):
        """Filter customers by city"""
        return self.filter(city__iexact=city)
    
    def by_country(self, country):
        """Filter customers by country"""
        return self.filter(country__iexact=country)
    
    def pakistani_customers(self):
        """Get Pakistani customers"""
        return self.filter(
            models.Q(country__iexact='Pakistan') | 
            models.Q(country__iexact='PK') |
            models.Q(phone__startswith='+92')
        )
    
    def international_customers(self):
        """Get non-Pakistani customers"""
        return self.exclude(
            models.Q(country__iexact='Pakistan') | 
            models.Q(country__iexact='PK')
        ).exclude(phone__startswith='+92')
    
    def verified(self, verification_type='any'):
        """Filter by verification status"""
        if verification_type == 'phone':
            return self.filter(phone_verified=True)
        elif verification_type == 'email':
            return self.filter(email_verified=True)
        elif verification_type == 'both':
            return self.filter(phone_verified=True, email_verified=True)
        else:  # any
            return self.filter(
                models.Q(phone_verified=True) | models.Q(email_verified=True)
            )
    
    def created_between(self, start_date, end_date):
        """Filter customers created between dates"""
        return self.filter(created_at__date__range=[start_date, end_date])
    
    def with_recent_activity(self, days=90):
        """Filter customers with recent order activity"""
        cutoff_date = timezone.now() - timedelta(days=days)
        return self.filter(last_order_date__gte=cutoff_date)


# Add the custom manager to the Customer model
Customer.add_to_class('objects', models.Manager.from_queryset(CustomerQuerySet)())
