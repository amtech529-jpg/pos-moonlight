from rest_framework import serializers
from .models import ProfitLossRecord, ProfitLossCalculation
from decimal import Decimal


class ProfitLossCalculationSerializer(serializers.ModelSerializer):
    """Serializer for ProfitLossCalculation model"""
    
    calculation_type_display = serializers.CharField(
        source='get_calculation_type_display',
        read_only=True
    )
    formatted_source_total = serializers.CharField(read_only=True)
    calculation_summary = serializers.DictField(read_only=True)
    
    class Meta:
        model = ProfitLossCalculation
        fields = [
            'id', 'calculation_type', 'calculation_type_display',
            'source_model', 'source_count', 'source_total',
            'calculation_details', 'calculation_notes',
            'calculated_at', 'formatted_source_total', 'calculation_summary'
        ]
        read_only_fields = ['id', 'calculated_at']


class ProfitLossRecordSerializer(serializers.ModelSerializer):
    """Serializer for ProfitLossRecord model"""
    
    period_type_display = serializers.CharField(
        source='get_period_type_display',
        read_only=True
    )
    formatted_total_sales_income = serializers.CharField(read_only=True)
    formatted_total_cost_of_goods_sold = serializers.CharField(read_only=True)
    formatted_gross_profit = serializers.CharField(read_only=True)
    formatted_total_expenses = serializers.CharField(read_only=True)
    formatted_net_profit = serializers.CharField(read_only=True)
    formatted_gross_profit_margin = serializers.CharField(read_only=True)
    formatted_profit_margin = serializers.CharField(read_only=True)
    period_display = serializers.CharField(read_only=True)
    is_profitable = serializers.BooleanField(read_only=True)
    expense_breakdown = serializers.DictField(read_only=True)
    summary_stats = serializers.DictField(read_only=True)
    
    # Include calculations
    calculations = ProfitLossCalculationSerializer(
        many=True, 
        read_only=True,
        source='calculations.all'
    )
    
    class Meta:
        model = ProfitLossRecord
        fields = [
            'id', 'period_type', 'period_type_display',
            'start_date', 'end_date',
            'total_sales_income', 'total_cost_of_goods_sold', 'total_labor_payments', 'total_vendor_payments',
            'total_expenses', 'total_zakat', 'total_expenses_calculated',
            'gross_profit', 'gross_profit_margin_percentage', 'net_profit', 'profit_margin_percentage',
            'total_products_sold', 'average_order_value',
            'calculation_notes', 'is_active',
            'formatted_total_sales_income', 'formatted_total_cost_of_goods_sold', 'formatted_gross_profit',
            'formatted_total_expenses', 'formatted_net_profit', 'formatted_gross_profit_margin',
            'formatted_profit_margin', 'period_display', 'is_profitable', 'expense_breakdown',
            'summary_stats', 'calculations',
            'created_at', 'updated_at', 'created_by'
        ]
        read_only_fields = [
            'id', 'total_expenses_calculated', 'gross_profit', 'gross_profit_margin_percentage',
            'net_profit', 'profit_margin_percentage', 'created_at', 'updated_at'
        ]


class ProfitLossCalculationRequestSerializer(serializers.Serializer):
    """Serializer for profit and loss calculation requests"""
    
    start_date = serializers.DateField(
        help_text="Start date for the calculation period"
    )
    end_date = serializers.DateField(
        help_text="End date for the calculation period"
    )
    period_type = serializers.ChoiceField(
        choices=ProfitLossRecord.PERIOD_CHOICES,
        default='CUSTOM',
        help_text="Type of period for the calculation"
    )
    include_calculations = serializers.BooleanField(
        default=True,
        help_text="Whether to include detailed calculation breakdowns"
    )
    calculation_notes = serializers.CharField(
        max_length=1000,
        required=False,
        allow_blank=True,
        help_text="Optional notes about the calculation"
    )


class ProfitLossSummarySerializer(serializers.Serializer):
    """Serializer for profit and loss summary data"""
    
    period_info = serializers.DictField(
        help_text="Period information (start_date, end_date, period_type)"
    )
    
    # Income
    total_sales_income = serializers.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Total income from sales"
    )
    total_cost_of_goods_sold = serializers.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Total cost of goods sold"
    )
    total_products_sold = serializers.IntegerField(
        help_text="Total number of products sold"
    )
    average_order_value = serializers.DecimalField(
        max_digits=20, 
        decimal_places=2,
        help_text="Average order value"
    )
    
    # Expenses breakdown
    total_labor_payments = serializers.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Total payments to labor"
    )
    total_vendor_payments = serializers.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Total payments to vendors"
    )
    total_expenses = serializers.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Total other expenses"
    )
    total_zakat = serializers.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Total zakat amount"
    )
    total_expenses_calculated = serializers.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Total calculated expenses"
    )
    
    # Profit calculations
    gross_profit = serializers.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Gross profit (income - COGS)"
    )
    gross_profit_margin_percentage = serializers.DecimalField(
        max_digits=12, 
        decimal_places=2,
        help_text="Gross profit margin as percentage"
    )
    net_profit = serializers.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Net profit (gross profit - expenses)"
    )
    profit_margin_percentage = serializers.DecimalField(
        max_digits=12, 
        decimal_places=2,
        help_text="Profit margin as percentage"
    )
    is_profitable = serializers.BooleanField(
        help_text="Whether the period was profitable"
    )
    
    # Formatted values for display
    formatted_total_sales_income = serializers.CharField(
        help_text="Formatted sales income (PKR)"
    )
    formatted_total_cost_of_goods_sold = serializers.CharField(
        help_text="Formatted cost of goods sold (PKR)"
    )
    formatted_gross_profit = serializers.CharField(
        help_text="Formatted gross profit (PKR)"
    )
    formatted_total_expenses = serializers.CharField(
        help_text="Formatted total expenses (PKR)"
    )
    formatted_net_profit = serializers.CharField(
        help_text="Formatted net profit (PKR)"
    )
    formatted_gross_profit_margin = serializers.CharField(
        help_text="Formatted gross profit margin percentage"
    )
    formatted_profit_margin = serializers.CharField(
        help_text="Formatted profit margin percentage"
    )
    
    # Additional metadata
    calculation_timestamp = serializers.DateTimeField(
        help_text="When this calculation was performed"
    )
    source_records_count = serializers.DictField(
        help_text="Count of source records used in calculation"
    )


class ProfitLossComparisonSerializer(serializers.Serializer):
    """Serializer for comparing profit and loss across different periods"""
    
    current_period = ProfitLossSummarySerializer(
        help_text="Current period profit and loss data"
    )
    previous_period = ProfitLossSummarySerializer(
        help_text="Previous period profit and loss data"
    )
    
    # Comparison metrics
    sales_growth = serializers.DecimalField(
        max_digits=8, 
        decimal_places=2,
        help_text="Percentage change in sales from previous period"
    )
    expense_growth = serializers.DecimalField(
        max_digits=8, 
        decimal_places=2,
        help_text="Percentage change in expenses from previous period"
    )
    profit_growth = serializers.DecimalField(
        max_digits=8, 
        decimal_places=2,
        help_text="Percentage change in profit from previous period"
    )
    margin_change = serializers.DecimalField(
        max_digits=8, 
        decimal_places=2,
        help_text="Change in profit margin percentage"
    )
    
    # Trend indicators
    sales_trend = serializers.CharField(
        help_text="Trend direction for sales (increasing, decreasing, stable)"
    )
    profit_trend = serializers.CharField(
        help_text="Trend direction for profit (increasing, decreasing, stable)"
    )
    margin_trend = serializers.CharField(
        help_text="Trend direction for profit margin (improving, declining, stable)"
    )


class ProductProfitabilitySerializer(serializers.Serializer):
    """Serializer for product-level profitability analysis"""
    
    product_id = serializers.UUIDField(
        help_text="Product identifier"
    )
    product_name = serializers.CharField(
        help_text="Product name"
    )
    product_category = serializers.CharField(
        help_text="Product category"
    )
    
    # Sales metrics
    units_sold = serializers.IntegerField(
        help_text="Number of units sold in the period"
    )
    total_revenue = serializers.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Total revenue from this product"
    )
    average_sale_price = serializers.DecimalField(
        max_digits=12, 
        decimal_places=2,
        help_text="Average sale price per unit"
    )
    
    # Cost and profit metrics
    cost_price = serializers.DecimalField(
        max_digits=12, 
        decimal_places=2,
        help_text="Product cost price (if available)"
    )
    total_cost = serializers.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Total cost for units sold"
    )
    gross_profit = serializers.DecimalField(
        max_digits=15, 
        decimal_places=2,
        help_text="Gross profit (revenue - cost)"
    )
    profit_margin = serializers.DecimalField(
        max_digits=5, 
        decimal_places=2,
        help_text="Profit margin percentage"
    )
    
    # Formatted values
    formatted_total_revenue = serializers.CharField(
        help_text="Formatted total revenue"
    )
    formatted_gross_profit = serializers.CharField(
        help_text="Formatted gross profit"
    )
    formatted_profit_margin = serializers.CharField(
        help_text="Formatted profit margin"
    )
    
    # Performance indicators
    is_profitable = serializers.BooleanField(
        help_text="Whether this product is profitable"
    )
    profitability_rank = serializers.IntegerField(
        help_text="Ranking by profitability (1 = most profitable)"
    )
