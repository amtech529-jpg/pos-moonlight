import uuid
import re
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import RegexValidator
from django.utils import timezone
from datetime import timedelta


class VendorQuerySet(models.QuerySet):
    """Custom QuerySet for Vendor model"""
    
    def active(self):
        return self.filter(is_active=True)
    
    def inactive(self):
        return self.filter(is_active=False)
    
    def search(self, query):
        """Search vendors by name, business name, phone, or CNIC"""
        return self.filter(
            models.Q(name__icontains=query) |
            models.Q(business_name__icontains=query) |
            models.Q(phone__icontains=query) |
            models.Q(cnic__icontains=query) |
            models.Q(city__icontains=query) |
            models.Q(area__icontains=query)
        )
    
    def by_city(self, city):
        """Filter vendors by city"""
        return self.filter(city__iexact=city)
    
    def by_area(self, area):
        """Filter vendors by area"""
        return self.filter(area__iexact=area)
    
    def recent(self, days=30):
        """Get vendors created in the last N days"""
        date_threshold = timezone.now() - timedelta(days=days)
        return self.filter(created_at__gte=date_threshold)
    
    def created_between(self, start_date, end_date):
        """Filter vendors created between dates"""
        return self.filter(created_at__date__range=[start_date, end_date])


def validate_pakistani_cnic(value):
    """Validate Pakistani CNIC format: 42101-1234567-8"""
    if value is None or value == '':
        return  # Allow empty/null values
    pattern = r'^\d{5}-\d{7}-\d{1}$'
    if not re.match(pattern, value):
        raise ValidationError(
            'CNIC must be in format: 12345-1234567-1'
        )


class Vendor(models.Model):
    """Vendor model for managing business vendors"""
    
    # Phone validator
    phone_regex = RegexValidator(
        regex=r'^[\+]?[0-9\-\s]{10,20}$',
        message="Phone number must be entered in valid format"
    )
    
    # Primary fields as per specification
    id = models.UUIDField(
        primary_key=True, 
        default=uuid.uuid4, 
        editable=False
    )
    name = models.CharField(
        max_length=200,
        help_text="Full name of the vendor"
    )
    business_name = models.CharField(
        max_length=200,
        help_text="Name of the business/company",
        null=True,
        blank=True
    )
    cnic = models.CharField(
        max_length=15,
        unique=True,
        null=True,
        blank=True,
        validators=[validate_pakistani_cnic],
        help_text="Pakistani CNIC in format: 12345-1234567-1 (optional)"
    )
    phone = models.CharField(
        max_length=20,
        unique=True,
        validators=[phone_regex],
        help_text="Contact phone number"
    )
    city = models.CharField(
        max_length=100,
        help_text="City where vendor is located",
        null=True,
        blank=True
    )
    area = models.CharField(
        max_length=100,
        help_text="Area/locality within the city",
        null=True,
        blank=True
    )
    
    # System fields (following customer module pattern)
    is_active = models.BooleanField(
        default=True,
        help_text="Used for soft deletion"
    )
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_vendors'
    )
    
    # Custom manager
    objects = models.Manager.from_queryset(VendorQuerySet)()
    
    class Meta:
        db_table = 'vendor'
        verbose_name = 'Vendor'
        verbose_name_plural = 'Vendors'
        ordering = ['-created_at', 'name']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['business_name']),
            models.Index(fields=['cnic']),
            models.Index(fields=['phone']),
            models.Index(fields=['city']),
            models.Index(fields=['area']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.business_name})"
    
    def clean(self):
        """Validate model data"""
        # Clean and validate name
        if self.name:
            self.name = self.name.strip()
            if not self.name:
                raise ValidationError({'name': 'Vendor name cannot be empty.'})
        
        # Clean phone number
        if self.phone:
            self.phone = self.phone.strip()
            self.phone = self.format_phone_number(self.phone)
        
        # Clean other fields
        if self.business_name:
            self.business_name = self.business_name.strip()
        if self.cnic:
            self.cnic = self.cnic.strip()
        if self.city:
            self.city = self.city.strip().title()
        if self.area:
            self.area = self.area.strip().title()
    
    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)
    
    # Properties
    @property
    def display_name(self):
        """Get display name for vendor"""
        if self.business_name:
            return f"{self.business_name} ({self.name})"
        return self.name
    
    @property
    def full_address(self):
        """Return complete address"""
        parts = []
        if self.area:
            parts.append(self.area)
        if self.city:
            parts.append(self.city)
        return ", ".join(parts) if parts else ""
    
    @property
    def is_new_vendor(self):
        """Check if vendor is new (created within last 30 days)"""
        thirty_days_ago = timezone.now() - timedelta(days=30)
        return self.created_at >= thirty_days_ago
    
    @property
    def is_recent_vendor(self):
        """Check if vendor was added recently (last 7 days)"""
        seven_days_ago = timezone.now() - timedelta(days=7)
        return self.created_at >= seven_days_ago
    
    @property
    def vendor_age_days(self):
        """Get vendor age in days"""
        if not self.created_at:
            return 0
        return (timezone.now() - self.created_at).days
    
    @property
    def phone_country_code(self):
        """Extract country code from phone number"""
        if not self.phone or not self.phone.startswith('+'):
            return '+92'  # Default to Pakistan
        match = re.match(r'^\+(\d{1,4})', self.phone)
        return f"+{match.group(1)}" if match else '+92'
    
    @property
    def formatted_phone(self):
        """Get formatted phone with country code"""
        if self.phone and not self.phone.startswith('+'):
            if self.phone.startswith('0'):
                return f'+92{self.phone[1:]}'
            else:
                return f'+92{self.phone}'
        return self.phone
    
    # Helper methods
    def get_initials(self):
        """Get vendor initials for avatar"""
        words = self.name.split()
        if len(words) >= 2:
            return f"{words[0][0]}{words[1][0]}".upper()
        elif len(words) == 1:
            return words[0][:2].upper()
        return "VE"
    
    @staticmethod
    def format_phone_number(phone):
        """Format phone number to a consistent format"""
        # Remove all non-digit characters except +
        cleaned = re.sub(r'[^\d+]', '', phone)
        
        # Handle Pakistani mobile numbers
        if cleaned.startswith('03') and len(cleaned) == 11:
            return f"+92-{cleaned[1:]}"
        elif cleaned.startswith('923') and len(cleaned) == 12:
            return f"+{cleaned[:2]}-{cleaned[2:]}"
        elif cleaned.startswith('+923') and len(cleaned) == 13:
            return f"{cleaned[:3]}-{cleaned[3:]}"
        
        return phone  # Return original if no pattern matches
    
    def soft_delete(self):
        """Soft delete the vendor"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])
    
    def restore(self):
        """Restore a soft-deleted vendor"""
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])
    
    # Class methods
    @classmethod
    def active_vendors(cls):
        """Return only active vendors"""
        return cls.objects.filter(is_active=True)
    
    @classmethod
    def new_vendors(cls, days=30):
        """Get vendors created within specified days"""
        cutoff_date = timezone.now() - timedelta(days=days)
        return cls.active_vendors().filter(created_at__gte=cutoff_date)
    
    @classmethod
    def recent_vendors(cls, days=7):
        """Get recently added vendors"""
        cutoff_date = timezone.now() - timedelta(days=days)
        return cls.active_vendors().filter(created_at__gte=cutoff_date)
    
    @classmethod
    def vendors_by_city(cls, city):
        """Get vendors by city"""
        return cls.active_vendors().filter(city__iexact=city)
    
    @classmethod
    def vendors_by_area(cls, area):
        """Get vendors by area"""
        return cls.active_vendors().filter(area__iexact=area)
    
    @classmethod
    def get_statistics(cls):
        """Get comprehensive vendor statistics"""
        active_vendors = cls.active_vendors()
        total_vendors = active_vendors.count()
        new_vendors_count = cls.new_vendors().count()
        recent_vendors_count = cls.recent_vendors().count()
        inactive_vendors_count = cls.objects.filter(is_active=False).count()
        
        # City breakdown (top 10)
        city_breakdown = list(
            active_vendors.exclude(city='')
            .values('city')
            .annotate(count=models.Count('id'))
            .order_by('-count')[:10]
        )
        
        # Area breakdown (top 10)
        area_breakdown = list(
            active_vendors.exclude(area='')
            .values('area', 'city')
            .annotate(count=models.Count('id'))
            .order_by('-count')[:10]
        )
        
        return {
            'total_vendors': total_vendors,
            'active_vendors': total_vendors,
            'inactive_vendors': inactive_vendors_count,
            'new_vendors_this_month': new_vendors_count,
            'recent_vendors_this_week': recent_vendors_count,
            'top_cities': city_breakdown,
            'top_areas': area_breakdown,
        }
    
    # Payment-related methods (using Purchase module)
    def get_payments_count(self):
        """Get total number of purchases made from this vendor"""
        return self.purchases.count()
    
    def get_total_payments_amount(self):
        """Get total amount of purchases from this vendor"""
        from django.db.models import Sum
        return self.purchases.aggregate(total=Sum('total'))['total'] or 0.00
    
    def get_last_payment_date(self):
        """Get date of last purchase from this vendor"""
        last_purchase = self.purchases.order_by('-purchase_date').first()
        return last_purchase.purchase_date if last_purchase else None
    
    def get_average_payment_amount(self):
        """Get average payment amount for this vendor"""
        # This will be implemented when Payment model is available
        # return self.payments.aggregate(avg=models.Avg('amount'))['avg'] or 0.00
        return 0.00
    