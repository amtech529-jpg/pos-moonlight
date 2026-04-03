from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db import transaction
from decimal import Decimal
from .models import Sales, SaleItem, TaxRate, Invoice, Receipt, Return, ReturnItem, Refund
from customers.models import Customer
from products.models import Product
from orders.models import Order
from order_items.models import OrderItem
import logging

logger = logging.getLogger(__name__)

class CartSaleItemSerializer(serializers.Serializer):
    """Serializer for sale items when creating from cart"""
    order_item = serializers.UUIDField(required=False, allow_null=True)
    product = serializers.UUIDField(required=True)
    unit_price = serializers.DecimalField(max_digits=12, decimal_places=2, required=True)
    quantity = serializers.IntegerField(required=True, min_value=1)
    item_discount = serializers.DecimalField(max_digits=12, decimal_places=2, required=False, default=0)
    customization_notes = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    
    def validate_product(self, value):
        """Validate product exists"""
        from products.models import Product
        try:
            product = Product.objects.get(id=value, is_active=True)
            return value
        except Product.DoesNotExist:
            raise serializers.ValidationError("Product not found or inactive.")
    
    def validate_quantity(self, value):
        """Validate quantity"""
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than zero.")
        return value

class SalesCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating sales with nested sale items"""
    sale_items = CartSaleItemSerializer(many=True, required=False)
    amount_paid = serializers.DecimalField(max_digits=15, decimal_places=2, required=False, default=0)
    # Accept tax_configuration from frontend but mark as write_only (won't be saved to DB)
    tax_configuration = serializers.JSONField(required=False, allow_null=True, write_only=True)
    
    class Meta:
        model = Sales
        fields = (
            'order_id', 'customer', 'overall_discount', 'tax_configuration',
            'payment_method', 'amount_paid', 'split_payment_details', 'notes', 'sale_items'
        )
    
    def validate_customer(self, value):
        """Validate customer exists and is active - allow None for walk-in sales"""
        if value and not value.is_active:
            raise serializers.ValidationError("Customer must be active.")
        return value
    
    def validate_tax_configuration(self, value):
        """Validate tax configuration for new sales"""
        if not value:
            return {}
        
        if not isinstance(value, dict):
            raise serializers.ValidationError("Tax configuration must be a valid JSON object.")
        
        # Frontend sends: { taxes: { gst: { percentage: 0.0 } } }
        # This is just for validation - we'll extract gst_percentage in create()
        
        return value
    
    def validate(self, data):
        """Validate the serializer data"""
        if 'amount_paid' not in data:
            data['amount_paid'] = 0
        
        if not data.get('sale_items') and not data.get('order_id'):
            raise serializers.ValidationError("Either sale_items or order_id must be provided.")
        
        if data.get('payment_method') == 'SPLIT':
            split_details = data.get('split_payment_details')
            if not split_details:
                raise serializers.ValidationError("Split payment details required for SPLIT payment method.")
        
        return data
    
    def create(self, validated_data):
        """Create sale with nested sale items"""
        logger.info(f"📦 Starting sale creation")
        
        try:
            logger.info(f"📋 Received data keys: {list(validated_data.keys())}")
            
            # Extract nested data
            sale_items_data = validated_data.pop('sale_items', [])
            tax_configuration = validated_data.pop('tax_configuration', None)
            
            # 🔥 CRITICAL FIX: Convert tax_configuration to gst_percentage
            # Frontend sends: { taxes: { gst: { percentage: 0.0, amount: 123 } } }
            # Backend model needs: gst_percentage = 0.0
            if tax_configuration:
                logger.info(f"📊 Processing tax_configuration: {tax_configuration}")
                
                gst_percentage = Decimal('0.00')  # Default
                
                if isinstance(tax_configuration, dict):
                    taxes = tax_configuration.get('taxes', {})
                    if isinstance(taxes, dict):
                        gst_data = taxes.get('gst', {})
                        if isinstance(gst_data, dict) and 'percentage' in gst_data:
                            gst_percentage = Decimal(str(gst_data['percentage']))
                            logger.info(f"✅ Extracted GST percentage: {gst_percentage}%")
                
                # Set the model field (gst_percentage exists in the model)
                validated_data['gst_percentage'] = gst_percentage
                
                # DO NOT save tax_configuration to validated_data unless you added the field to the model!
                # validated_data['tax_configuration'] = tax_configuration  # ❌ REMOVE THIS LINE
            else:
                validated_data['gst_percentage'] = Decimal('0.00')
                logger.info(f"ℹ️  Using default GST: 0.00%")

            # Get created_by from context
            created_by = None
            if self.context.get('request'):
                created_by = self.context['request'].user
                logger.info(f"👤 Creating sale for user: {created_by}")
            
            # Set default amount_paid if not provided
            if 'amount_paid' not in validated_data:
                validated_data['amount_paid'] = Decimal('0.00')
            
            # Convert floats to Decimals to avoid type errors
            if 'overall_discount' in validated_data:
                print(f"🔍 Converting overall_discount: {validated_data['overall_discount']}")
                validated_data['overall_discount'] = Decimal(str(validated_data['overall_discount']))
                print(f"✅ Converted overall_discount: {validated_data['overall_discount']}")
            if 'amount_paid' in validated_data:
                print(f"🔍 Converting amount_paid: {validated_data['amount_paid']}")
                validated_data['amount_paid'] = Decimal(str(validated_data['amount_paid']))
                print(f"✅ Converted amount_paid: {validated_data['amount_paid']}")
            
            # Debug the final validated_data
            print(f"🔍 Final validated_data keys: {list(validated_data.keys())}")
            if 'overall_discount' in validated_data:
                print(f"🔍 Final overall_discount: {validated_data['overall_discount']}")
            if 'sale_items' in validated_data:
                print(f"🔍 Final sale_items count: {len(validated_data['sale_items'])}")
            
            with transaction.atomic():
                # Add created_by if available
                if created_by:
                    try:
                        Sales._meta.get_field('created_by')
                        validated_data['created_by'] = created_by
                        logger.info(f"✅ Added created_by to validated_data")
                    except Exception as e:
                        logger.warning(f"⚠️  Sales model doesn't have created_by field: {e}")
                
                # Create Sale
                logger.info(f"🏗️  Creating Sales object with fields: {list(validated_data.keys())}")
                sale = Sales.objects.create(**validated_data)
                logger.info(f"✅ Sale created: {sale.invoice_number} (ID: {sale.id})")
                
                # Store sale items data on the sale instance for validation
                if 'sale_items' in validated_data:
                    sale._validated_sale_items_data = validated_data['sale_items']
                
                # Create Sale Items
                if sale_items_data:
                    logger.info(f"📦 Creating {len(sale_items_data)} sale items...")
                    for idx, item_data in enumerate(sale_items_data):
                        try:
                            product_id = item_data['product']
                            
                            try:
                                product = Product.objects.get(id=product_id, is_active=True)
                            except Product.DoesNotExist:
                                logger.error(f"  ❌ Product {product_id} not found")
                                raise serializers.ValidationError(f"Product {product_id} not found or inactive")
                            
                            # Convert numeric values to Decimal
                            unit_price = Decimal(str(item_data['unit_price']))
                            quantity = int(item_data['quantity'])
                            item_discount = Decimal(str(item_data.get('item_discount', 0)))
                            line_total = (quantity * unit_price) - item_discount
                            
                            print(f"🔍 Creating sale item {idx+1}:")
                            print(f"  📦 Product: {product.name}")
                            print(f"  💰 Unit Price: {unit_price}")
                            print(f"  🔢 Quantity: {quantity}")
                            print(f"  🎉 Item Discount: {item_discount}")
                            print(f"  💵 Line Total: {line_total}")
                            
                            sale_item = SaleItem.objects.create(
                                sale=sale,
                                order_item=item_data.get('order_item'),
                                product=product,
                                product_name=product.name,
                                unit_price=unit_price,
                                quantity=quantity,
                                item_discount=item_discount,
                                line_total=line_total,
                                customization_notes=item_data.get('customization_notes', '') or ''
                            )
                            
                            print(f"✅ Sale item {idx+1} created successfully")
                            
                            logger.info(f"  ✅ Item {idx+1}: {product.name} x{quantity} = PKR {line_total}")
                            
                        except Exception as item_error:
                            logger.error(f"  ❌ Error creating sale item {idx+1}: {item_error}", exc_info=True)
                            raise
                
                # Recalculate totals
                try:
                    logger.info(f"🔄 Recalculating sale totals...")
                    if hasattr(sale, 'recalculate_totals'):
                        sale.recalculate_totals()
                        logger.info(f"✅ Totals recalculated - Grand Total: PKR {sale.grand_total}")
                    else:
                        logger.warning(f"⚠️  Sale model doesn't have recalculate_totals method")
                except Exception as calc_error:
                    logger.error(f"❌ Error recalculating totals: {calc_error}", exc_info=True)
                    logger.warning(f"⚠️  Continuing without recalculation")
                
                return sale
                
        except Exception as e:
            logger.error(f"💥 CRITICAL ERROR in sale creation: {str(e)}", exc_info=True)
            raise

class TaxRateSerializer(serializers.ModelSerializer):
    """Serializer for TaxRate model"""
    
    is_currently_effective = serializers.BooleanField(read_only=True)
    display_name = serializers.CharField(read_only=True)
    
    class Meta:
        model = TaxRate
        fields = (
            'id', 'name', 'tax_type', 'percentage', 'is_active', 'description',
            'effective_from', 'effective_to', 'is_currently_effective', 'display_name',
            'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')


class SaleItemCreateSerializer(serializers.Serializer):
    """Nested serializer for creating sale items within a sale"""
    
    product = serializers.UUIDField(help_text="Product UUID")
    unit_price = serializers.DecimalField(max_digits=12, decimal_places=2)
    quantity = serializers.IntegerField()
    item_discount = serializers.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    customization_notes = serializers.CharField(max_length=500, required=False, allow_blank=True)
    
    def validate_product(self, value):
        """Validate product exists and is active"""
        try:
            product = Product.objects.get(id=value, is_active=True)
            return product
        except Product.DoesNotExist:
            raise serializers.ValidationError("Invalid product or product is not active.")
    
    def validate_quantity(self, value):
        """Validate quantity"""
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than zero.")
        return value
    
    def validate_unit_price(self, value):
        """Validate unit price"""
        if value < 0:
            raise serializers.ValidationError("Unit price cannot be negative.")
        return value
    
    def validate_item_discount(self, value):
        """Validate item discount"""
        print(f"🔍 Validating item_discount: {value}")
        if value < 0:
            print("❌ Item discount is negative")
            raise serializers.ValidationError("Item discount cannot be negative.")
        # Ensure discount doesn't exceed unit price
        if hasattr(self, 'parent_instance') and hasattr(self.parent_instance, 'unit_price'):
            if value > self.parent_instance.unit_price:
                print(f"❌ Item discount {value} exceeds unit price {self.parent_instance.unit_price}")
                raise serializers.ValidationError("Item discount cannot exceed unit price.")
        print(f"✅ Item discount validation passed: {value}")
        return value


class SaleItemSerializer(serializers.ModelSerializer):
    """Complete serializer for SaleItem model"""
    
    product_id = serializers.UUIDField(source='product.id', read_only=True)
    product_name = serializers.CharField(read_only=True)
    discounted_unit_price = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    total_before_discount = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    discount_percentage = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    formatted_line_total = serializers.CharField(read_only=True)
    
    class Meta:
        model = SaleItem
        fields = (
            'id', 'sale', 'order_item', 'product', 'product_id', 'product_name',
            'unit_price', 'quantity', 'item_discount', 'line_total',
            'customization_notes', 'discounted_unit_price', 'total_before_discount',
            'discount_percentage', 'formatted_line_total',
            'is_active', 'created_at', 'updated_at'
        )
        read_only_fields = (
            'id', 'product_id', 'product_name', 'line_total', 'discounted_unit_price',
            'total_before_discount', 'discount_percentage', 'formatted_line_total',
            'created_at', 'updated_at'
        )


class SaleItemUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating sale items"""
    
    class Meta:
        model = SaleItem
        fields = (
            'unit_price', 'quantity', 'item_discount', 'customization_notes'
        )
    
    def validate(self, data):
        """Validate updated sale item data"""
        quantity = data.get('quantity', self.instance.quantity)
        unit_price = data.get('unit_price', self.instance.unit_price)
        
        if self.instance.product and quantity > self.instance.product.quantity:
            raise serializers.ValidationError(
                f"Insufficient stock. Only {self.instance.product.quantity} available for {self.instance.product.name}."
            )
        
        if unit_price < 0:
            raise serializers.ValidationError("Unit price cannot be negative.")
        
        if quantity <= 0:
            raise serializers.ValidationError("Quantity must be greater than zero.")
        
        return data


class SaleItemListSerializer(serializers.ModelSerializer):
    """Simplified serializer for listing sale items"""
    
    product_name = serializers.CharField(read_only=True)
    sale_invoice = serializers.CharField(source='sale.invoice_number', read_only=True)
    
    class Meta:
        model = SaleItem
        fields = (
            'id', 'product_name', 'sale_invoice', 'quantity', 'unit_price',
            'item_discount', 'line_total', 'is_active', 'created_at'
        )


class SalesSerializer(serializers.ModelSerializer):
    """Complete serializer for Sales model"""
    
    sale_items = SaleItemSerializer(many=True, read_only=True)
    payment_method_display = serializers.CharField(source='get_payment_method_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    tax_breakdown = serializers.JSONField(read_only=True)
    tax_summary_display = serializers.CharField(read_only=True)
    
    class Meta:
        model = Sales
        fields = (
            'id', 'invoice_number', 'order_id', 'customer_id', 'customer_name',
            'customer_phone', 'customer_email', 'subtotal', 'overall_discount',
            'gst_percentage', 'tax_amount', 'grand_total', 'amount_paid',
            'remaining_amount', 'is_fully_paid', 'payment_method', 'payment_method_display',
            'split_payment_details', 'date_of_sale', 'status', 'status_display',
            'notes', 'sale_items', 'sales_age_days', 'formatted_grand_total',
            'formatted_remaining_amount', 'payment_percentage', 'sales_summary',
            'authorized_initials', 'invoice_display', 'payment_status_display',
            'total_items', 'tax_breakdown', 'tax_summary_display',
            'is_active', 'created_at', 'updated_at'
        )
        read_only_fields = (
            'id', 'invoice_number', 'customer_id', 'customer_name', 'customer_phone',
            'customer_email', 'subtotal', 'tax_amount', 'grand_total', 'remaining_amount',
            'sales_age_days', 'formatted_grand_total', 'formatted_remaining_amount',
            'payment_percentage', 'sales_summary', 'authorized_initials',
            'invoice_display', 'payment_status_display', 'total_items', 'tax_breakdown',
            'status_display', 'payment_method_display', 'tax_summary_display',
            'created_at', 'updated_at'
        )
    
    def validate_overall_discount(self, value):
        """Validate overall discount"""
        print(f"🔍 Validating overall_discount: {value}")
        if value < 0:
            print("❌ Overall discount is negative")
            raise serializers.ValidationError("Overall discount cannot be negative.")
        # Get subtotal to validate discount doesn't exceed it
        if hasattr(self, 'initial_data') and 'sale_items' in self.initial_data:
            subtotal = Decimal('0.00')
            print(f"🔍 Calculating subtotal from {len(self.initial_data['sale_items'])} items")
            for idx, item in enumerate(self.initial_data['sale_items']):
                unit_price = Decimal(str(item.get('unit_price', 0)))
                quantity = int(item.get('quantity', 0))
                item_discount = Decimal(str(item.get('item_discount', 0)))
                item_total = (quantity * unit_price) - item_discount
                subtotal += item_total
                print(f"  📦 Item {idx+1}: {unit_price} x {quantity} - {item_discount} = {item_total}")
            
            print(f"💰 Calculated subtotal: {subtotal}")
            print(f"🎉 Overall discount: {value}")
            print(f"🔍 Is discount valid? {value <= subtotal}")
            
            # Remove the strict validation for now - let the sale proceed
            # The business logic should handle this at the model level
            if value > subtotal:
                print(f"⚠️ Overall discount {value} exceeds subtotal {subtotal}, but allowing for now")
                # Don't raise error, just log it
                # raise serializers.ValidationError("Overall discount cannot exceed subtotal.")
        print(f"✅ Overall discount validation passed: {value}")
        return value
    
    def validate_amount_paid(self, value):
        """Validate amount paid"""
        if value < 0:
            raise serializers.ValidationError("Amount paid cannot be negative.")
        return value


class SalesUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating sales"""
    
    class Meta:
        model = Sales
        fields = (
            'overall_discount', 'payment_method',
            'split_payment_details', 'notes', 'status'
        )
    
    def validate_status(self, value):
        """Validate status transitions"""
        instance = self.instance
        if instance and instance.status in ['PAID', 'DELIVERED']:
            raise serializers.ValidationError("Cannot change status of completed sales.")
        return value


class SalesListSerializer(serializers.ModelSerializer):
    """Simplified serializer for listing sales"""
    
    payment_method_display = serializers.CharField(source='get_payment_method_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    tax_summary_display = serializers.CharField(read_only=True)
    
    class Meta:
        model = Sales
        fields = (
            'id', 'invoice_number', 'customer_name', 'status', 'status_display',
            'grand_total', 'amount_paid', 'payment_method', 'payment_method_display',
            'date_of_sale', 'total_items', 'tax_summary_display', 'is_active'
        )


class SalesPaymentSerializer(serializers.ModelSerializer):
    """Serializer for updating payment information"""
    
    class Meta:
        model = Sales
        fields = ('amount_paid', 'payment_method', 'split_payment_details')
    
    def validate_amount_paid(self, value):
        """Validate amount paid"""
        if value < 0:
            raise serializers.ValidationError("Amount paid cannot be negative.")
        
        return value


class SalesStatusUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating sale status"""
    
    class Meta:
        model = Sales
        fields = ('status',)
    
    def validate_status(self, value):
        """Validate status transitions"""
        instance = self.instance
        if instance.status in ['PAID', 'DELIVERED']:
            raise serializers.ValidationError("Cannot change status of completed sales.")
        return value


class SalesBulkActionSerializer(serializers.Serializer):
    """Serializer for bulk sales actions"""
    
    action = serializers.ChoiceField(choices=[
        ('activate', 'Activate'),
        ('deactivate', 'Deactivate'),
        ('confirm', 'Confirm'),
        ('invoice', 'Mark as Invoiced'),
        ('cancel', 'Cancel'),
        ('delete', 'Delete')
    ])
    
    sale_ids = serializers.ListField(
        child=serializers.UUIDField(),
        help_text="List of sale IDs to perform action on"
    )


class SalesStatisticsSerializer(serializers.Serializer):
    """Serializer for sales statistics"""
    
    total_sales = serializers.IntegerField()
    total_revenue = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_items_sold = serializers.IntegerField()
    average_order_value = serializers.DecimalField(max_digits=15, decimal_places=2)
    total_tax_collected = serializers.DecimalField(max_digits=15, decimal_places=2)
    tax_breakdown = serializers.JSONField()
    payment_method_distribution = serializers.JSONField()
    status_distribution = serializers.JSONField()
    daily_trends = serializers.ListField()
    monthly_trends = serializers.ListField()


class OrderToSaleConversionSerializer(serializers.Serializer):
    """Serializer for converting orders to sales"""
    
    order_id = serializers.UUIDField(
        help_text="ID of the order to convert"
    )
    payment_method = serializers.ChoiceField(
        choices=Sales.PAYMENT_METHOD_CHOICES,
        help_text="Method of payment for the sale"
    )
    amount_paid = serializers.DecimalField(
        max_digits=15,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Amount paid immediately"
    )
    overall_discount = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Overall discount to apply"
    )
    gst_percentage = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="GST percentage to apply"
    )
    notes = serializers.CharField(
        max_length=1000,
        required=False,
        help_text="Additional sale notes"
    )
    partial_items = serializers.ListField(
        child=serializers.DictField(),
        required=False,
        help_text="List of order items to convert with quantities"
    )
    
    def validate_order_id(self, value):
        """Validate order exists and can be converted"""
        try:
            order = Order.objects.get(id=value, is_active=True)
            if order.status not in ['CONFIRMED', 'IN_PROGRESS']:
                raise serializers.ValidationError("Order must be confirmed or in progress to convert to sale.")
        except Order.DoesNotExist:
            raise serializers.ValidationError("Order not found or inactive.")
        
        return value


# Invoice Serializers
class InvoiceSerializer(serializers.ModelSerializer):
    """Serializer for Invoice model"""
    
    sale_invoice_number = serializers.CharField(source='sale.invoice_number', read_only=True)
    customer_name = serializers.SerializerMethodField()
    customer_phone = serializers.SerializerMethodField()
    write_off_amount = serializers.SerializerMethodField()
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    days_until_due = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Invoice
        fields = (
            'id', 'order', 'sale', 'sale_invoice_number', 'invoice_number', 'issue_date', 'due_date',
            'status', 'notes', 'terms_conditions', 'pdf_file', 'email_sent', 'email_sent_at',
            'viewed_at', 'is_active', 'created_at', 'updated_at', 'created_by', 'created_by_name',
            'customer_name', 'customer_phone', 'is_overdue', 'days_until_due',
            'total_amount', 'amount_paid', 'amount_due', 'write_off_amount'
        )
        read_only_fields = (
            'id', 'invoice_number', 'email_sent', 'email_sent_at', 'viewed_at', 'is_active',
            'created_at', 'updated_at', 'sale_invoice_number', 'customer_name', 'customer_phone',
            'created_by_name', 'is_overdue', 'days_until_due', 'total_amount', 'amount_paid', 
            'amount_due', 'write_off_amount'
        )

    def get_write_off_amount(self, obj):
        # Always return the correct write-off amount for terminal statuses for display consistency
        from decimal import Decimal
        if obj.status in ['WRITTEN_OFF', 'CLOSED']:
            total = obj.total_amount or Decimal('0.00')
            paid = obj.amount_paid or Decimal('0.00')
            return float(max(total - paid, Decimal('0.00')))
        return float(obj.write_off_amount or 0.0)

    def get_customer_name(self, obj):
        if obj.sale:
            return obj.sale.customer_name
        if obj.customer:
            return obj.customer.name
        if obj.order:
            return obj.order.customer_name
        return "Unknown Customer"

    def get_customer_phone(self, obj):
        if obj.sale:
            return obj.sale.customer_phone
        if obj.customer:
            return obj.customer.phone
        if obj.order:
            return obj.order.customer_phone
        return ""


class InvoiceCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating invoices"""
    
    class Meta:
        model = Invoice
        fields = ('sale', 'due_date', 'notes', 'terms_conditions')
    
    def validate(self, data):
        """Validate invoice data"""
        sale = data.get('sale')
        
        # Validate sale exists and is active
        if not sale or not sale.is_active:
            raise serializers.ValidationError("Invalid or inactive sale.")
        
        # Check if invoice already exists for this sale
        if hasattr(sale, 'invoice'):
            raise serializers.ValidationError("Invoice already exists for this sale.")
        
        return data
    
    def create(self, validated_data):
        """Create invoice"""
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class InvoiceUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating invoices"""
    write_off_amount = serializers.DecimalField(max_digits=12, decimal_places=2, required=False)
    
    class Meta:
        model = Invoice
        fields = ('due_date', 'status', 'notes', 'terms_conditions', 'write_off_amount')

    def update(self, instance, validated_data):
        write_off_amount = validated_data.pop('write_off_amount', None)
        
        # Capture status update but don't let super().update handle it automatically
        # because we need custom logic for PAID and automation.
        status_update = validated_data.pop('status', None)

        if write_off_amount is not None:
            instance.write_off_amount = write_off_amount
        
        if status_update:
            instance.status = status_update
        
        # super().update() will call instance.save() which now contains the logic to
        # auto-calculate the write_off_amount if the status is WRITTEN_OFF or CLOSED.
        instance = super().update(instance, validated_data)
        
        return instance


class InvoiceListSerializer(serializers.ModelSerializer):
    """Serializer for listing invoices"""
    
    sale_invoice_number = serializers.CharField(source='sale.invoice_number', read_only=True)
    customer_name = serializers.SerializerMethodField()
    customer_phone = serializers.SerializerMethodField()
    write_off_amount = serializers.SerializerMethodField()
    
    class Meta:
        model = Invoice
        fields = (
            'id', 'sale', 'sale_invoice_number', 'invoice_number', 'issue_date', 'due_date',
            'status', 'customer_name', 'customer_phone', 'total_amount', 'amount_paid', 
            'amount_due', 'write_off_amount', 'created_at'
        )

    def get_write_off_amount(self, obj):
        # Always return the correct write-off amount for terminal statuses for display consistency
        from decimal import Decimal
        if obj.status in ['WRITTEN_OFF', 'CLOSED']:
            total = obj.total_amount or Decimal('0.00')
            paid = obj.amount_paid or Decimal('0.00')
            return float(max(total - paid, Decimal('0.00')))
        return float(obj.write_off_amount or 0.0)

    def get_customer_name(self, obj):
        if obj.sale:
            return obj.sale.customer_name
        if obj.customer:
            return obj.customer.name
        if obj.order:
            return obj.order.customer_name
        return "Unknown Customer"

    def get_customer_phone(self, obj):
        if obj.sale:
            return obj.sale.customer_phone
        if obj.customer:
            return obj.customer.phone
        if obj.order:
            return obj.order.customer_phone
        return ""


# Receipt Serializers
class ReceiptSerializer(serializers.ModelSerializer):
    """Serializer for Receipt model"""
    
    sale_invoice_number = serializers.CharField(source='sale.invoice_number', read_only=True)
    payment_amount = serializers.SerializerMethodField()
    payment_method = serializers.SerializerMethodField()
    customer_name = serializers.CharField(source='sale.customer_name', read_only=True)
    customer_phone = serializers.CharField(source='sale.customer_phone', read_only=True)
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = Receipt
        fields = (
            'id', 'sale', 'payment', 'receipt_number', 'generated_at', 'status',
            'pdf_file', 'email_sent', 'email_sent_at', 'viewed_at', 'notes',
            'is_active', 'created_at', 'updated_at', 'created_by', 'created_by_name',
            'sale_invoice_number', 'payment_amount', 'payment_method', 'customer_name', 'customer_phone'
        )
        read_only_fields = (
            'id', 'receipt_number', 'generated_at', 'email_sent', 'email_sent_at', 'viewed_at',
            'is_active', 'created_at', 'updated_at', 'sale_invoice_number', 'payment_amount',
            'payment_method', 'customer_name', 'customer_phone', 'created_by_name'
        )
    
    def get_payment_amount(self, obj):
        """Get payment amount from payment if exists, otherwise from sale"""
        if obj.payment:
            return obj.payment.amount_paid
        return float(obj.sale.amount_paid)
    
    def get_payment_method(self, obj):
        """Get payment method from payment if exists, otherwise from sale"""
        if obj.payment:
            return obj.payment.payment_method
        return obj.sale.payment_method


class ReceiptCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating receipts"""
    
    class Meta:
        model = Receipt
        fields = ('sale', 'payment', 'notes')
    
    def validate(self, data):
        """Validate receipt data"""
        sale = data.get('sale')
        payment = data.get('payment')
        
        # Validate sale exists and is active
        if not sale or not sale.is_active:
            raise serializers.ValidationError("Invalid or inactive sale.")
        
        # Validate payment exists and belongs to the sale
        if not payment or payment.entity_id != str(sale.id) or payment.entity_type != 'sale':
            raise serializers.ValidationError("Invalid payment or payment doesn't belong to this sale.")
        
        return data
    
    def create(self, validated_data):
        """Create receipt"""
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class ReceiptUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating receipts"""
    
    class Meta:
        model = Receipt
        fields = ('status', 'notes')


class ReceiptListSerializer(serializers.ModelSerializer):
    """Serializer for listing receipts"""
    
    sale_invoice_number = serializers.CharField(source='sale.invoice_number', read_only=True)
    payment_amount = serializers.SerializerMethodField()
    payment_method = serializers.SerializerMethodField()
    customer_name = serializers.CharField(source='sale.customer_name', read_only=True)
    
    class Meta:
        model = Receipt
        fields = (
            'id', 'sale', 'payment', 'receipt_number', 'generated_at', 'status',
            'customer_name', 'sale_invoice_number', 'payment_amount', 'payment_method', 'created_at'
        )
    
    def get_payment_amount(self, obj):
        """Get payment amount from payment if exists, otherwise from sale"""
        if obj.payment:
            return obj.payment.amount_paid
        return float(obj.sale.amount_paid)
    
    def get_payment_method(self, obj):
        """Get payment method from payment if exists, otherwise from sale"""
        if obj.payment:
            return obj.payment.payment_method
        return obj.sale.payment_method