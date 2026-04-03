from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.core.validators import MinValueValidator, MaxValueValidator
from decimal import Decimal
import uuid

User = get_user_model()

class ZakatManager(models.Manager):
    """Custom manager for Zakat model"""
    
    def active(self):
        """Get only active zakat records"""
        return self.filter(is_active=True)
    
    def by_authority(self, authority):
        """Get zakat entries by authorization authority"""
        return self.active().filter(authorized_by=authority)
    
    def by_beneficiary(self, beneficiary_name):
        """Get zakat entries by beneficiary"""
        return self.active().filter(beneficiary_name__icontains=beneficiary_name)
    
    def by_date_range(self, start_date, end_date):
        """Get zakat entries within date range"""
        return self.active().filter(date__range=[start_date, end_date])
    
    def recent(self, limit=10):
        """Get recent zakat entries"""
        return self.active().order_by('-created_at')[:limit]


class Zakat(models.Model):
    """Zakat model for tracking Islamic charitable giving"""
    
    AUTHORIZATION_CHOICES = [
        ('Mr. Shahzain Baloch', 'Mr. Shahzain Baloch'),
        ('Mr Huzaifa', 'Mr Huzaifa'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200, help_text="Zakat payment/distribution title")
    description = models.TextField(help_text="Detailed description of the Zakat transaction")
    date = models.DateField(help_text="Date of Zakat transaction")
    time = models.TimeField(help_text="Time of Zakat transaction")
    amount = models.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Zakat amount"
    )
    beneficiary_name = models.CharField(
        max_length=200, 
        help_text="Name of recipient/beneficiary"
    )
    beneficiary_contact = models.CharField(
        max_length=20, 
        blank=True, 
        null=True,
        help_text="Optional contact number"
    )
    notes = models.TextField(
        blank=True, 
        null=True,
        help_text="Additional notes or religious considerations"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        help_text="Who recorded this Zakat entry"
    )
    authorized_by = models.CharField(
        max_length=50,
        choices=AUTHORIZATION_CHOICES,
        help_text="Who authorized the Zakat payment"
    )
    is_active = models.BooleanField(default=True, help_text="For soft deletion")
    
    objects = ZakatManager()
    
    class Meta:
        db_table = 'zakat'
        verbose_name = 'Zakat'
        verbose_name_plural = 'Zakat Entries'
        ordering = ['-date', '-time']
        indexes = [
            models.Index(fields=['date']),
            models.Index(fields=['authorized_by']),
            models.Index(fields=['beneficiary_name']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        if not self.name:
            return "New Zakat Entry"
        return f"{self.name} - {self.formatted_amount}"
    
    @property
    def zakat_age_days(self):
        """Days since Zakat transaction was recorded"""
        if not self.date:
            return 0
        return (timezone.now().date() - self.date).days
    
    @property
    def formatted_amount(self):
        """Currency formatted amount display (PKR)"""
        if self.amount is None:
            return "PKR 0.00"
        return f"PKR {self.amount:,.2f}"
    
    @property
    def beneficiary_summary(self):
        """Combined beneficiary name and contact"""
        if self.beneficiary_contact:
            return f"{self.beneficiary_name} ({self.beneficiary_contact})"
        return self.beneficiary_name
    
    @property
    def zakat_summary(self):
        """Short summary for display purposes"""
        if not self.name:
            return "New Zakat Entry"
        summary = self.name
        if len(summary) > 50:
            summary = summary[:47] + "..."
        amount_display = self.formatted_amount if self.amount is not None else "PKR 0.00"
        return f"{summary} - {amount_display}"
    
    @property
    def authorized_initials(self):
        """Initials of person who authorized the Zakat payment"""
        name_parts = self.authorized_by.split()
        initials = ""
        for part in name_parts:
            if part.startswith(('Mr.', 'Mr', 'Mrs.', 'Mrs', 'Ms.', 'Ms', 'Sheikh')):
                continue
            if part:
                initials += part[0].upper()
        return initials or self.authorized_by[:2].upper()
    
    def clean(self):
        """Custom validation"""
        from django.core.exceptions import ValidationError
        
        # Date cannot be in the future
        if self.date > timezone.now().date():
            raise ValidationError({'date': 'Date cannot be in the future.'})
        
        # Amount must be positive
        if self.amount <= 0:
            raise ValidationError({'amount': 'Amount must be positive and greater than zero.'})
        
        # Beneficiary name is required
        if not self.beneficiary_name or not self.beneficiary_name.strip():
            raise ValidationError({'beneficiary_name': 'Beneficiary name is required.'})
    
    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)
    
    def delete(self):
        """Soft delete"""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])
    
    def hard_delete(self):
        """Permanent delete"""
        super().delete()
        