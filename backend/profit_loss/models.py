import uuid
from django.db import models
from django.conf import settings
from django.core.exceptions import ValidationError
from django.utils import timezone
from decimal import Decimal
from datetime import date


class ProfitLossRecord(models.Model):
    """Model to store calculated profit and loss records for different periods"""
    
    PERIOD_CHOICES = [
        ('DAILY', 'Daily'),
        ('WEEKLY', 'Weekly'),
        ('MONTHLY', 'Monthly'),
        ('QUARTERLY', 'Quarterly'),
        ('YEARLY', 'Yearly'),
        ('CUSTOM', 'Custom Period'),
    ]
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    
    # Period information
    period_type = models.CharField(
        max_length=20,
        choices=PERIOD_CHOICES,
        help_text="Type of period for this calculation"
    )
    start_date = models.DateField(
        help_text="Start date of the period"
    )
    end_date = models.DateField(
        help_text="End date of the period"
    )
    
    # Income calculations
    total_sales_income = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total income from sales.grand_total"
    )
    
    # Cost of Goods Sold
    total_cost_of_goods_sold = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total cost of goods sold in this period"
    )
    
    # Expense calculations
    total_labor_payments = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total payments to labor"
    )
    total_vendor_payments = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total payments to vendors"
    )
    total_expenses = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total expenses amount"
    )
    total_zakat = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total zakat amount"
    )
    
    # Calculated fields
    total_expenses_calculated = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total expenses (labor + vendor + other + zakat)"
    )
    gross_profit = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Gross profit (income - cost of goods sold)"
    )
    net_profit = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Net profit (gross profit - total expenses)"
    )
    gross_profit_margin_percentage = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Gross profit margin as percentage of sales"
    )
    profit_margin_percentage = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Net profit margin as percentage of sales"
    )
    
    # Additional metrics
    total_products_sold = models.PositiveIntegerField(
        default=0,
        help_text="Total number of products sold in this period"
    )
    average_order_value = models.DecimalField(
        max_digits=20,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Average order value in this period"
    )
    
    # Metadata
    calculation_notes = models.TextField(
        blank=True,
        help_text="Notes about the calculation or any adjustments"
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
        related_name='created_profit_loss_records',
        help_text="User who created this record"
    )
    
    class Meta:
        db_table = 'profit_loss_record'
        verbose_name = 'Profit & Loss Record'
        verbose_name_plural = 'Profit & Loss Records'
        ordering = ['-start_date', '-end_date']
        indexes = [
            models.Index(fields=['period_type']),
            models.Index(fields=['start_date', 'end_date']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
        ]
        unique_together = ['period_type', 'start_date', 'end_date']
    
    def __str__(self):
        return f"P&L {self.period_type} ({self.start_date} to {self.end_date}) - {self.formatted_net_profit}"
    
    def clean(self):
        """Validate model data"""
        if self.start_date and self.end_date and self.start_date > self.end_date:
            raise ValidationError({'end_date': 'End date must be after start date.'})
        
        if self.total_sales_income < 0:
            raise ValidationError({'total_sales_income': 'Sales income cannot be negative.'})
        
        if self.total_labor_payments < 0:
            raise ValidationError({'total_labor_payments': 'Labor payments cannot be negative.'})
        
        if self.total_vendor_payments < 0:
            raise ValidationError({'total_vendor_payments': 'Vendor payments cannot be negative.'})
        
        if self.total_expenses < 0:
            raise ValidationError({'total_expenses': 'Expenses cannot be negative.'})
        
        if self.total_zakat < 0:
            raise ValidationError({'total_zakat': 'Zakat amount cannot be negative.'})
    
    def save(self, *args, **kwargs):
        """Calculate derived fields before saving"""
        # Calculate total expenses
        self.total_expenses_calculated = (
            self.total_labor_payments + 
            self.total_vendor_payments + 
            self.total_expenses + 
            self.total_zakat
        )
        
        # Calculate gross profit
        self.gross_profit = self.total_sales_income - self.total_cost_of_goods_sold
        
        # Calculate net profit
        self.net_profit = self.gross_profit - self.total_expenses_calculated
        
        # Calculate gross profit margin percentage
        if self.total_sales_income > 0:
            gross_margin = (self.gross_profit / self.total_sales_income) * 100
            # Round to 2 decimal places and cap at 99999999.99%
            self.gross_profit_margin_percentage = gross_margin.quantize(Decimal('0.01'))
            self.gross_profit_margin_percentage = min(self.gross_profit_margin_percentage, Decimal('99999999.99'))
        else:
            self.gross_profit_margin_percentage = Decimal('0.00')
        
        # Calculate profit margin percentage
        if self.total_sales_income > 0:
            profit_margin = (self.net_profit / self.total_sales_income) * 100
            # Round to 2 decimal places and cap at 99999999.99%
            self.profit_margin_percentage = profit_margin.quantize(Decimal('0.01'))
            self.profit_margin_percentage = min(self.profit_margin_percentage, Decimal('99999999.99'))
        else:
            self.profit_margin_percentage = Decimal('0.00')
        
        self.full_clean()
        super().save(*args, **kwargs)
    
    @property
    def formatted_total_sales_income(self):
        """Currency formatted total sales income"""
        return f"PKR {self.total_sales_income:,.2f}"
    
    @property
    def formatted_total_cost_of_goods_sold(self):
        """Currency formatted total cost of goods sold"""
        return f"PKR {self.total_cost_of_goods_sold:,.2f}"
    
    @property
    def formatted_gross_profit(self):
        """Currency formatted gross profit"""
        return f"PKR {self.gross_profit:,.2f}"
    
    @property
    def formatted_total_expenses(self):
        """Currency formatted total expenses"""
        return f"PKR {self.total_expenses_calculated:,.2f}"
    
    @property
    def formatted_net_profit(self):
        """Currency formatted net profit"""
        return f"PKR {self.net_profit:,.2f}"
    
    @property
    def formatted_profit_margin(self):
        """Formatted profit margin percentage"""
        return f"{self.profit_margin_percentage:.2f}%"
    
    @property
    def formatted_gross_profit_margin(self):
        """Formatted gross profit margin percentage"""
        return f"{self.gross_profit_margin_percentage:.2f}%"
    
    @property
    def period_display(self):
        """Human readable period display"""
        if self.period_type == 'CUSTOM':
            return f"{self.start_date.strftime('%b %d, %Y')} to {self.end_date.strftime('%b %d, %Y')}"
        elif self.period_type == 'DAILY':
            return self.start_date.strftime('%b %d, %Y')
        elif self.period_type == 'WEEKLY':
            return f"Week of {self.start_date.strftime('%b %d, %Y')}"
        elif self.period_type == 'MONTHLY':
            return self.start_date.strftime('%B %Y')
        elif self.period_type == 'QUARTERLY':
            return f"Q{((self.start_date.month - 1) // 3) + 1} {self.start_date.year}"
        elif self.period_type == 'YEARLY':
            return str(self.start_date.year)
        return f"{self.start_date} to {self.end_date}"
    
    @property
    def is_profitable(self):
        """Check if this period was profitable"""
        return self.net_profit > 0
    
    @property
    def expense_breakdown(self):
        """Get breakdown of expenses"""
        return {
            'cost_of_goods_sold': float(self.total_cost_of_goods_sold),
            'labor_payments': float(self.total_labor_payments),
            'vendor_payments': float(self.total_vendor_payments),
            'other_expenses': float(self.total_expenses),
            'zakat': float(self.total_zakat),
            'total': float(self.total_expenses_calculated)
        }
    
    @property
    def summary_stats(self):
        """Get summary statistics for this period"""
        return {
            'period': self.period_display,
            'total_sales': float(self.total_sales_income),
            'cost_of_goods_sold': float(self.total_cost_of_goods_sold),
            'gross_profit': float(self.gross_profit),
            'gross_profit_margin': float(self.gross_profit_margin_percentage),
            'total_expenses': float(self.total_expenses_calculated),
            'net_profit': float(self.net_profit),
            'profit_margin': float(self.profit_margin_percentage),
            'products_sold': self.total_products_sold,
            'average_order_value': float(self.average_order_value),
            'is_profitable': self.is_profitable
        }


class ProfitLossCalculation(models.Model):
    """Model to store detailed calculation breakdowns for profit and loss"""
    
    CALCULATION_TYPE_CHOICES = [
        ('SALES_INCOME', 'Sales Income'),
        ('LABOR_PAYMENTS', 'Labor Payments'),
        ('VENDOR_PAYMENTS', 'Vendor Payments'),
        ('EXPENSES', 'Other Expenses'),
        ('ZAKAT', 'Zakat'),
        ('PROFIT_CALCULATION', 'Profit Calculation'),
    ]
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    
    profit_loss_record = models.ForeignKey(
        ProfitLossRecord,
        on_delete=models.CASCADE,
        related_name='calculations',
        help_text="Associated profit and loss record"
    )
    
    calculation_type = models.CharField(
        max_length=20,
        choices=CALCULATION_TYPE_CHOICES,
        help_text="Type of calculation performed"
    )
    
    # Calculation details
    source_model = models.CharField(
        max_length=50,
        help_text="Source model for the calculation (e.g., 'Sales', 'Payment')"
    )
    source_count = models.PositiveIntegerField(
        default=0,
        help_text="Number of source records used in calculation"
    )
    source_total = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total amount from source records"
    )
    
    # Calculation metadata
    calculation_details = models.JSONField(
        default=dict,
        blank=True,
        help_text="Detailed breakdown of the calculation"
    )
    calculation_notes = models.TextField(
        blank=True,
        help_text="Notes about this specific calculation"
    )
    
    # Timestamps
    calculated_at = models.DateTimeField(
        default=timezone.now,
        help_text="When this calculation was performed"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'profit_loss_calculation'
        verbose_name = 'Profit & Loss Calculation'
        verbose_name_plural = 'Profit & Loss Calculations'
        ordering = ['profit_loss_record', 'calculation_type', 'calculated_at']
        indexes = [
            models.Index(fields=['profit_loss_record']),
            models.Index(fields=['calculation_type']),
            models.Index(fields=['source_model']),
            models.Index(fields=['calculated_at']),
        ]
    
    def __str__(self):
        return f"{self.get_calculation_type_display()} for {self.profit_loss_record}"
    
    @property
    def formatted_source_total(self):
        """Currency formatted source total"""
        return f"PKR {self.source_total:,.2f}"
    
    @property
    def calculation_summary(self):
        """Get summary of this calculation"""
        return {
            'type': self.get_calculation_type_display(),
            'source_model': self.source_model,
            'source_count': self.source_count,
            'source_total': float(self.source_total),
            'calculated_at': self.calculated_at.isoformat(),
            'notes': self.calculation_notes
        }
