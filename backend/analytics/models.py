import uuid
from django.db import models
from django.conf import settings
from django.utils import timezone
from decimal import Decimal
from datetime import date


class BusinessMetrics(models.Model):
    """Model to store calculated business metrics for different periods"""
    
    PERIOD_CHOICES = [
        ('DAILY', 'Daily'),
        ('WEEKLY', 'Weekly'),
        ('MONTHLY', 'Monthly'),
        ('QUARTERLY', 'Quarterly'),
        ('YEARLY', 'Yearly'),
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
    
    # Sales metrics
    total_sales = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total sales revenue"
    )
    sales_count = models.PositiveIntegerField(
        default=0,
        help_text="Number of sales transactions"
    )
    average_sale_value = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Average sale value"
    )
    
    # Customer metrics
    new_customers = models.PositiveIntegerField(
        default=0,
        help_text="Number of new customers"
    )
    returning_customers = models.PositiveIntegerField(
        default=0,
        help_text="Number of returning customers"
    )
    total_customers = models.PositiveIntegerField(
        default=0,
        help_text="Total unique customers"
    )
    
    # Product metrics
    products_sold = models.PositiveIntegerField(
        default=0,
        help_text="Total products sold"
    )
    top_selling_products = models.JSONField(
        default=list,
        help_text="List of top selling products with quantities"
    )
    low_stock_products = models.PositiveIntegerField(
        default=0,
        help_text="Number of products with low stock"
    )
    
    # Financial metrics
    total_revenue = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total revenue from all sources"
    )
    total_expenses = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total expenses"
    )
    net_profit = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Net profit (revenue - expenses)"
    )
    profit_margin = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Profit margin percentage"
    )
    
    # Operational metrics
    orders_fulfilled = models.PositiveIntegerField(
        default=0,
        help_text="Number of orders fulfilled"
    )
    orders_pending = models.PositiveIntegerField(
        default=0,
        help_text="Number of pending orders"
    )
    average_fulfillment_time = models.PositiveIntegerField(
        default=0,
        help_text="Average order fulfillment time in days"
    )
    
    # Payment metrics
    cash_payments = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total cash payments received"
    )
    bank_transfers = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total bank transfers received"
    )
    pending_payments = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total pending payments"
    )
    
    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    calculated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='calculated_metrics'
    )
    
    class Meta:
        db_table = 'business_metrics'
        verbose_name = 'Business Metrics'
        verbose_name_plural = 'Business Metrics'
        ordering = ['-start_date']
        indexes = [
            models.Index(fields=['period_type', 'start_date']),
            models.Index(fields=['start_date', 'end_date']),
        ]
    
    def __str__(self):
        return f"{self.period_type} Metrics ({self.start_date} - {self.end_date})"
    
    @property
    def formatted_total_sales(self):
        """Format total sales with currency symbol"""
        return f"PKR {self.total_sales:,.2f}"
    
    @property
    def formatted_net_profit(self):
        """Format net profit with currency symbol"""
        return f"PKR {self.net_profit:,.2f}"
    
    @property
    def formatted_profit_margin(self):
        """Format profit margin as percentage"""
        return f"{self.profit_margin:.2f}%"


class CustomerInsights(models.Model):
    """Model to store customer behavior insights"""
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    
    # Customer information
    customer_id = models.CharField(
        max_length=100,
        help_text="Customer identifier"
    )
    customer_name = models.CharField(
        max_length=200,
        help_text="Customer name"
    )
    
    # Purchase behavior
    total_purchases = models.PositiveIntegerField(
        default=0,
        help_text="Total number of purchases"
    )
    total_spent = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total amount spent"
    )
    average_order_value = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Average order value"
    )
    
    # Frequency analysis
    first_purchase_date = models.DateField(
        null=True,
        blank=True,
        help_text="Date of first purchase"
    )
    last_purchase_date = models.DateField(
        null=True,
        blank=True,
        help_text="Date of last purchase"
    )
    days_since_last_purchase = models.PositiveIntegerField(
        default=0,
        help_text="Days since last purchase"
    )
    
    # Customer segmentation
    customer_segment = models.CharField(
        max_length=50,
        blank=True,
        help_text="Customer segment (VIP, Regular, Occasional)"
    )
    loyalty_score = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Customer loyalty score (0-100)"
    )
    
    # Metadata
    calculated_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'customer_insights'
        verbose_name = 'Customer Insights'
        verbose_name_plural = 'Customer Insights'
        ordering = ['-total_spent']
        indexes = [
            models.Index(fields=['customer_segment']),
            models.Index(fields=['loyalty_score']),
            models.Index(fields=['last_purchase_date']),
        ]
    
    def __str__(self):
        return f"{self.customer_name} - {self.customer_segment}"
    
    @property
    def formatted_total_spent(self):
        """Format total spent with currency symbol"""
        return f"PKR {self.total_spent:,.2f}"
    
    @property
    def formatted_average_order_value(self):
        """Format average order value with currency symbol"""
        return f"PKR {self.average_order_value:,.2f}"


class ProductPerformance(models.Model):
    """Model to store product performance metrics"""
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False
    )
    
    # Product information
    product_id = models.CharField(
        max_length=100,
        help_text="Product identifier"
    )
    product_name = models.CharField(
        max_length=200,
        help_text="Product name"
    )
    category = models.CharField(
        max_length=100,
        blank=True,
        help_text="Product category"
    )
    
    # Sales performance
    units_sold = models.PositiveIntegerField(
        default=0,
        help_text="Total units sold"
    )
    revenue_generated = models.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Total revenue generated"
    )
    profit_margin = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Product profit margin percentage"
    )
    
    # Inventory metrics
    current_stock = models.PositiveIntegerField(
        default=0,
        help_text="Current stock level"
    )
    reorder_point = models.PositiveIntegerField(
        default=0,
        help_text="Reorder point for this product"
    )
    stock_turnover_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Stock turnover rate"
    )
    
    # Performance indicators
    is_top_seller = models.BooleanField(
        default=False,
        help_text="Whether this is a top selling product"
    )
    is_low_stock = models.BooleanField(
        default=False,
        help_text="Whether this product has low stock"
    )
    performance_score = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Overall performance score (0-100)"
    )
    
    # Metadata
    calculated_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'product_performance'
        verbose_name = 'Product Performance'
        verbose_name_plural = 'Product Performance'
        ordering = ['-revenue_generated']
        indexes = [
            models.Index(fields=['category']),
            models.Index(fields=['is_top_seller']),
            models.Index(fields=['performance_score']),
        ]
    
    def __str__(self):
        return f"{self.product_name} - {self.category}"
    
    @property
    def formatted_revenue_generated(self):
        """Format revenue generated with currency symbol"""
        return f"PKR {self.revenue_generated:,.2f}"
    
    @property
    def formatted_profit_margin(self):
        """Format profit margin as percentage"""
        return f"{self.profit_margin:.2f}%"
    
    @property
    def stock_status(self):
        """Get stock status description"""
        if self.current_stock == 0:
            return "Out of Stock"
        elif self.current_stock <= self.reorder_point:
            return "Low Stock"
        else:
            return "In Stock"

