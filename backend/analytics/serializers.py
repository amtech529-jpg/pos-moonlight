from rest_framework import serializers
from .models import BusinessMetrics, CustomerInsights, ProductPerformance


class BusinessMetricSerializer(serializers.ModelSerializer):
    """Serializer for BusinessMetrics model"""
    
    class Meta:
        model = BusinessMetrics
        fields = [
            'id', 'period_type', 'start_date', 'end_date',
            'total_sales', 'sales_count', 'average_sale_value',
            'new_customers', 'returning_customers', 'total_customers',
            'products_sold', 'top_selling_products', 'low_stock_products',
            'total_revenue', 'total_expenses', 'net_profit', 'profit_margin',
            'orders_fulfilled', 'orders_pending', 'average_fulfillment_time',
            'cash_payments', 'bank_transfers', 'pending_payments',
            'created_at', 'updated_at', 'calculated_by'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'calculated_by']


class CustomerInsightSerializer(serializers.ModelSerializer):
    """Serializer for CustomerInsights model"""
    
    class Meta:
        model = CustomerInsights
        fields = [
            'id', 'customer_id', 'customer_name',
            'total_purchases', 'total_spent', 'average_order_value',
            'first_purchase_date', 'last_purchase_date', 'days_since_last_purchase',
            'customer_segment', 'loyalty_score',
            'calculated_at', 'updated_at'
        ]
        read_only_fields = ['id', 'calculated_at', 'updated_at']


class ProductPerformanceSerializer(serializers.ModelSerializer):
    """Serializer for ProductPerformance model"""
    
    class Meta:
        model = ProductPerformance
        fields = [
            'id', 'product_id', 'product_name', 'category',
            'units_sold', 'revenue_generated', 'profit_margin',
            'current_stock', 'reorder_point', 'stock_turnover_rate',
            'is_top_seller', 'is_low_stock', 'performance_score',
            'calculated_at', 'updated_at'
        ]
        read_only_fields = ['id', 'calculated_at', 'updated_at']
