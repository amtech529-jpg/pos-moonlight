from rest_framework import serializers
from django.db.models import Q
from .models import Order
from customers.models import Customer
from order_items.models import OrderItem
from decimal import Decimal, InvalidOperation
from django.db import transaction


class OrderSerializer(serializers.ModelSerializer):
    """Complete serializer for Order model"""
    
    # Customer details
    customer_id = serializers.UUIDField(source='customer.id', read_only=True)
    created_by = serializers.StringRelatedField(read_only=True)
    created_by_id = serializers.IntegerField(read_only=True, source='created_by.id')
    
    # Computed fields
    days_since_ordered = serializers.IntegerField(read_only=True)
    days_until_delivery = serializers.IntegerField(read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    payment_percentage = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    order_summary = serializers.JSONField(read_only=True)
    delivery_status = serializers.CharField(source='get_delivery_status', read_only=True)
    
    # Status display
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = Order
        fields = (
            'id',
            'customer_id',
            'customer_name',
            'customer_phone',
            'customer_email',
            'advance_payment',
            'total_amount',
            'remaining_amount',
            'is_fully_paid',
            'date_ordered',
            'expected_delivery_date',
            'event_name',
            'event_location',
            'event_date',
            'return_date',
            'description',
            'status',
            'status_display',
            'days_since_ordered',
            'days_until_delivery',
            'is_overdue',
            'payment_percentage',
            'order_summary',
            'delivery_status',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'created_by_id'
        )
        read_only_fields = (
            'id', 'customer_id', 'customer_name', 'customer_phone', 'customer_email',
            'total_amount', 'remaining_amount', 'is_fully_paid', 'days_since_ordered',
            'days_until_delivery', 'is_overdue', 'payment_percentage', 'order_summary',
            'delivery_status', 'status_display', 'created_at', 'updated_at',
            'created_by', 'created_by_id'
        )

    def validate_advance_payment(self, value):
        """Validate advance payment"""
        if value < 0:
            raise serializers.ValidationError("Advance payment cannot be negative.")
        return value

    def validate_expected_delivery_date(self, value):
        """Validate expected delivery date"""
        if value and self.instance:
            if value < self.instance.date_ordered:
                raise serializers.ValidationError(
                    "Expected delivery date cannot be before order date."
                )
        return value

    def validate_description(self, value):
        """Clean description field"""
        if value:
            return value.strip()
        return value


class OrderCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating orders"""
    
    customer = serializers.UUIDField(write_only=True, help_text="Customer UUID")
    items = serializers.JSONField(write_only=True, help_text="List of items: [{product_id, quantity, rate, days, customization_notes}]")
    
    class Meta:
        model = Order
        fields = (
            'customer',
            'items',
            'advance_payment',
            'date_ordered',
            'expected_delivery_date',
            'event_name',
            'event_location',
            'event_date',
            'return_date',
            'description',
            'status'
        )

    def validate_customer(self, value):
        """Validate customer exists and is active"""
        try:
            customer = Customer.objects.get(id=value, is_active=True)
            return customer
        except Customer.DoesNotExist:
            raise serializers.ValidationError("Invalid customer or customer is not active.")

    def validate_advance_payment(self, value):
        """Validate advance payment"""
        if value < 0:
            raise serializers.ValidationError("Advance payment cannot be negative.")
        return value

    def validate_expected_delivery_date(self, value):
        """Validate expected delivery date"""
        # value is already a date object thanks to DRF's default parsing
        date_ordered_raw = self.initial_data.get('date_ordered')
        if value and date_ordered_raw:
            from datetime import datetime, date
            
            # Try to get date_ordered as a date object
            date_ordered = None
            if isinstance(date_ordered_raw, date):
                date_ordered = date_ordered_raw
            elif isinstance(date_ordered_raw, datetime):
                date_ordered = date_ordered_raw.date()
            elif isinstance(date_ordered_raw, str):
                try:
                    # Try common formats
                    if 'T' in date_ordered_raw:
                        date_ordered = datetime.fromisoformat(date_ordered_raw.replace('Z', '+00:00')).date()
                    else:
                        date_ordered = datetime.strptime(date_ordered_raw[:10], '%Y-%m-%d').date()
                except (ValueError, TypeError):
                    # Fallback to current date if parsing fails
                    date_ordered = date.today()
            
            if date_ordered and value < date_ordered:
                raise serializers.ValidationError(
                    "Expected delivery date cannot be before order date."
                )
        return value

    def validate_description(self, value):
        """Clean description field"""
        if value:
            return value.strip()
        return value

    def create(self, validated_data):
        """Create order with nested items in a transaction"""
        items_data = validated_data.pop('items', [])
        user = self.context['request'].user
        validated_data['created_by'] = user
        
        # Extract advance payment to create Payment record later
        initial_advance = validated_data.pop('advance_payment', Decimal('0.00'))
        # If advance_payment was not in validated_data, check initial_data just in case, but serializer handles this.
        if initial_advance is None:
             initial_advance = Decimal('0.00')
             
        # Create order with 0 advance payment initially (signals from Payment will update it)
        validated_data['advance_payment'] = Decimal('0.00')
        
        with transaction.atomic():
            # Create the order
            order = Order.objects.create(**validated_data)
            
            # Create order items
            for item in items_data:
                product_id = item.get('product_id')
                if not product_id:
                    continue
                
                from products.models import Product
                try:
                    product = Product.objects.get(id=product_id)
                except Product.DoesNotExist:
                    raise serializers.ValidationError(f"Product {product_id} not found")

                # Robustly extract and convert numeric values to prevent multiplication errors
                try:
                    qty = int(item.get('quantity', 1) or 1)
                    raw_rate = item.get('rate')
                    if raw_rate is None or raw_rate == '':
                        rate = product.price
                    else:
                        rate = Decimal(str(raw_rate))
                    
                    days = int(item.get('days', 1) or 1)
                    pricing_type = item.get('pricing_type', product.pricing_type)
                except (ValueError, TypeError, InvalidOperation):
                    qty = 1
                    rate = product.price
                    days = 1
                    pricing_type = 'PER_DAY'

                OrderItem.objects.create(
                    order=order,
                    product=product,
                    product_name=product.name, # Ensure product_name is cached
                    quantity=qty,
                    rate=rate,
                    days=days,
                    pricing_type=pricing_type,
                    customization_notes=item.get('customization_notes', ''),
                    rented_from_partner=item.get('rented_from_partner', False),
                    partner_id=item.get('partner'),
                    partner_rate=item.get('partner_rate')
                )
            
            # Recalculate totals
            order.calculate_totals()
            
            # Create Payment record if advance payment exists
            if initial_advance > 0:
                from payments.models import Payment
                from django.utils import timezone
                
                try:
                    # Use a sub-transaction (savepoint) so that if Payment creation fails, 
                    # it doesn't poison the whole Order creation transaction.
                    with transaction.atomic():
                        Payment.objects.create(
                            order=order,
                            amount_paid=initial_advance,
                            date=timezone.now().date(),
                            time=timezone.now().time(),
                            payment_month=timezone.now().date().replace(day=1), # Set to 1st of current month
                            payment_method='CASH',  # Default to CASH for initial advance
                            payer_type='CUSTOMER',
                            payer_id=order.customer.id if order.customer else None,
                            created_by=user,
                            description=f"Advance payment for Order #{order.id}"
                        )
                except Exception as e:
                    # Log error but don't fail order creation
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.error(f"Failed to create payment record for order {order.id}: {str(e)}")
            
            return order


class OrderUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating orders"""
    
    class Meta:
        model = Order
        fields = (
            'advance_payment',
            'expected_delivery_date',
            'description',
            'status'
        )

    def validate_advance_payment(self, value):
        """Validate advance payment doesn't exceed total amount"""
        if value < 0:
            raise serializers.ValidationError("Advance payment cannot be negative.")
        
        if self.instance and self.instance.total_amount > 0:
            if value > self.instance.total_amount:
                raise serializers.ValidationError(
                    f"Advance payment cannot exceed total amount of PKR {self.instance.total_amount}."
                )
        return value

    def validate_expected_delivery_date(self, value):
        """Validate expected delivery date"""
        if value and self.instance:
            if value < self.instance.date_ordered:
                raise serializers.ValidationError(
                    "Expected delivery date cannot be before order date."
                )
        return value

    def validate_status(self, value):
        """Validate status transitions"""
        if self.instance:
            current_status = self.instance.status
            
            # Prevent changing status of delivered or cancelled orders
            if current_status in ['DELIVERED', 'CANCELLED'] and value != current_status:
                raise serializers.ValidationError(
                    f"Cannot change status of {current_status.lower()} orders."
                )
            
            # Validate logical status progression
            valid_transitions = {
                'PENDING': ['CONFIRMED', 'CANCELLED'],
                'CONFIRMED': ['READY', 'CANCELLED'],
                'READY': ['DELIVERED', 'CANCELLED'],
                'DELIVERED': [],  # Terminal state
                'CANCELLED': []   # Terminal state
            }
            
            if value != current_status and value not in valid_transitions.get(current_status, []):
                raise serializers.ValidationError(
                    f"Invalid status transition from {current_status} to {value}."
                )
        
        return value

    def validate_description(self, value):
        """Clean description field"""
        if value:
            return value.strip()
        return value


class OrderListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing orders"""
    
    customer_id = serializers.UUIDField(source='customer.id', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    days_since_ordered = serializers.IntegerField(read_only=True)
    days_until_delivery = serializers.IntegerField(read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    payment_percentage = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    order_summary = serializers.JSONField(read_only=True)
    delivery_status = serializers.CharField(source='get_delivery_status', read_only=True)
    order_items = serializers.SerializerMethodField()
    conversion_status = serializers.ReadOnlyField()
    converted_sales_amount = serializers.ReadOnlyField()
    conversion_date = serializers.ReadOnlyField()
    can_convert_to_sale = serializers.BooleanField(source='can_be_converted_to_sale', read_only=True)
    has_sales = serializers.BooleanField(source='has_been_converted_to_sale', read_only=True)
    related_sales = serializers.SerializerMethodField()
    return_status = serializers.SerializerMethodField()
    created_by = serializers.StringRelatedField(read_only=True)
    
    def get_return_status(self, obj):
        """Get return status of the order"""
        if hasattr(obj, 'rental_return'):
            return obj.rental_return.status
        return 'NOT_STARTED'
    
    def get_related_sales(self, obj):
        """Get sales created from this order"""
        sales = obj.get_related_sales()
        return [
            {
                'id': str(sale.id),
                'invoice_number': sale.invoice_number,
                'grand_total': float(sale.grand_total),
                'date_of_sale': sale.date_of_sale,
                'status': sale.status
            }
            for sale in sales
        ]

    def get_customer(self, obj):
        """Get customer details"""
        return {
            'id': str(obj.customer.id),
            'name': obj.customer.name,
            'phone': obj.customer.phone,
            'email': obj.customer.email,
            'status': obj.customer.status,
            'customer_type': obj.customer.customer_type
        }

    def get_order_items(self, obj):
        """Get order items summary"""
        items = obj.get_order_items()
        return [
            {
                'id': str(item.id),
                'product_name': item.product_name,
                'quantity': item.quantity,
                'rate': item.rate,
                'days': item.days,
                'pricing_type': item.pricing_type,
                'line_total': item.line_total,
                'has_customization': bool(item.customization_notes)
            }
            for item in items
        ]
    
    class Meta:
        model = Order
        fields = (
            'id',
            'customer',
            'customer_id',
            'customer_name',
            'customer_phone',
            'customer_email',
            'advance_payment',
            'total_amount',
            'remaining_amount',
            'is_fully_paid',
            'payment_percentage',
            'date_ordered',
            'expected_delivery_date',
            'event_name',
            'event_location',
            'event_date',
            'return_date',
            'description',
            'status',
            'status_display',
            'days_since_ordered',
            'days_until_delivery',
            'is_overdue',
            'order_summary',
            'delivery_status',
            'order_items',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'conversion_status', 'converted_sales_amount', 'conversion_date', 'can_convert_to_sale', 'has_sales', 'related_sales',
            'return_status'
        )


class OrderDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for single order view"""
    
    customer = serializers.SerializerMethodField()
    created_by = serializers.StringRelatedField(read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    days_since_ordered = serializers.IntegerField(read_only=True)
    days_until_delivery = serializers.IntegerField(read_only=True)
    is_overdue = serializers.BooleanField(read_only=True)
    payment_percentage = serializers.DecimalField(max_digits=5, decimal_places=2, read_only=True)
    order_summary = serializers.JSONField(read_only=True)
    delivery_status = serializers.CharField(source='get_delivery_status', read_only=True)
    order_items = serializers.SerializerMethodField()
    customer_id = serializers.UUIDField(source='customer.id', read_only=True)
    conversion_status = serializers.ReadOnlyField()
    converted_sales_amount = serializers.ReadOnlyField()
    conversion_date = serializers.ReadOnlyField()
    can_convert_to_sale = serializers.BooleanField(source='can_be_converted_to_sale', read_only=True)
    has_sales = serializers.BooleanField(source='has_been_converted_to_sale', read_only=True)
    related_sales = serializers.SerializerMethodField()
    return_status = serializers.SerializerMethodField()

    def get_return_status(self, obj):
        """Get return status of the order"""
        if hasattr(obj, 'rental_return'):
            return obj.rental_return.status
        return 'NOT_STARTED'
    
    class Meta:
        model = Order
        fields = (
            'id',
            'customer',
            'customer_id',
            'customer_name',
            'customer_phone',
            'customer_email',
            'advance_payment',
            'total_amount',
            'remaining_amount',
            'is_fully_paid',
            'payment_percentage',
            'date_ordered',
            'expected_delivery_date',
            'event_name',
            'event_location',
            'event_date',
            'return_date',
            'description',
            'status',
            'status_display',
            'days_since_ordered',
            'days_until_delivery',
            'is_overdue',
            'order_summary',
            'delivery_status',
            'order_items',
            'is_active',
            'created_at',
            'updated_at',
            'created_by',
            'conversion_status', 'converted_sales_amount', 'conversion_date', 'can_convert_to_sale', 'has_sales', 'related_sales',
            'return_status'
        )

    def get_related_sales(self, obj):
        """Get sales created from this order"""
        sales = obj.get_related_sales()
        return [
            {
                'id': str(sale.id),
                'invoice_number': sale.invoice_number,
                'grand_total': float(sale.grand_total),
                'date_of_sale': sale.date_of_sale,
                'status': sale.status
            }
            for sale in sales
        ]

    def get_customer(self, obj):
        """Get customer details"""
        return {
            'id': str(obj.customer.id),
            'name': obj.customer.name,
            'phone': obj.customer.phone,
            'email': obj.customer.email,
            'status': obj.customer.status,
            'customer_type': obj.customer.customer_type
        }

    def get_order_items(self, obj):
        """Get order items summary"""
        items = obj.get_order_items()
        return [
            {
                'id': str(item.id),
                'product_name': item.product_name,
                'quantity': item.quantity,
                'rate': item.rate,
                'days': item.days,
                'pricing_type': item.pricing_type,
                'line_total': item.line_total,
                'has_customization': bool(item.customization_notes)
            }
            for item in items
        ]


class OrderStatsSerializer(serializers.Serializer):
    """Serializer for order statistics"""
    
    total_orders = serializers.IntegerField()
    status_breakdown = serializers.DictField()
    financial_summary = serializers.DictField()
    payment_summary = serializers.DictField()
    delivery_summary = serializers.DictField()
    recent_activity = serializers.DictField()


class OrderPaymentSerializer(serializers.Serializer):
    """Serializer for adding payments to orders"""
    
    amount = serializers.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        min_value=Decimal('0.01'),
        help_text="Payment amount to add"
    )
    notes = serializers.CharField(
        max_length=500,
        required=False,
        help_text="Optional payment notes"
    )
    payment_method = serializers.ChoiceField(
        choices=[
            ('CASH', 'Cash'),
            ('BANK_TRANSFER', 'Bank Transfer'),
            ('MOBILE_PAYMENT', 'Mobile Payment (JazzCash/EasyPaisa)'),
            ('CHECK', 'Check'),
            ('CARD', 'Credit/Debit Card'),
            ('OTHER', 'Other'),
        ],
        default='CASH',
        help_text="Method of payment"
    )

    def validate_amount(self, value):
        """Validate payment amount"""
        if value <= 0:
            raise serializers.ValidationError("Payment amount must be positive.")
        return value


class OrderStatusUpdateSerializer(serializers.Serializer):
    """Serializer for updating order status"""
    
    status = serializers.ChoiceField(
        choices=Order.STATUS_CHOICES,
        help_text="New order status"
    )
    notes = serializers.CharField(
        max_length=1000,
        required=False,
        help_text="Optional status update notes"
    )


class OrderBulkActionSerializer(serializers.Serializer):
    """Serializer for bulk order actions"""
    
    order_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1,
        help_text="List of order IDs to perform action on"
    )
    action = serializers.ChoiceField(
        choices=[
            ('confirm', 'Confirm Orders'),
            ('mark_ready', 'Mark as Ready'),
            ('cancel', 'Cancel Orders'),
            ('activate', 'Activate Orders'),
            ('deactivate', 'Deactivate Orders'),
        ],
        required=True,
        help_text="Action to perform on selected orders"
    )
    notes = serializers.CharField(
        max_length=1000,
        required=False,
        help_text="Optional notes for the bulk action"
    )

    def validate_order_ids(self, value):
        """Validate that all order IDs exist"""
        existing_ids = Order.objects.filter(id__in=value).values_list('id', flat=True)
        existing_ids = [str(id) for id in existing_ids]
        
        missing_ids = [str(id) for id in value if str(id) not in existing_ids]
        
        if missing_ids:
            raise serializers.ValidationError(
                f"Orders not found: {', '.join(missing_ids)}"
            )
        
        return value


class OrderSearchSerializer(serializers.Serializer):
    """Serializer for order search parameters"""
    
    q = serializers.CharField(
        required=True,
        min_length=1,
        help_text="Search query for customer name, phone, email, or order description"
    )
    status = serializers.ChoiceField(
        choices=Order.STATUS_CHOICES,
        required=False,
        help_text="Filter by order status"
    )
    payment_status = serializers.ChoiceField(
        choices=[('paid', 'Fully Paid'), ('unpaid', 'Unpaid'), ('partial', 'Partially Paid')],
        required=False,
        help_text="Filter by payment status"
    )
    delivery_status = serializers.ChoiceField(
        choices=[('overdue', 'Overdue'), ('due_today', 'Due Today'), ('upcoming', 'Upcoming')],
        required=False,
        help_text="Filter by delivery status"
    )
    date_from = serializers.DateField(
        required=False,
        help_text="Filter orders from this date"
    )
    date_to = serializers.DateField(
        required=False,
        help_text="Filter orders until this date"
    )


class OrderCustomerUpdateSerializer(serializers.Serializer):
    """Serializer for updating cached customer information in orders"""
    
    customer_name = serializers.CharField(max_length=200, required=False)
    customer_phone = serializers.CharField(max_length=20, required=False)
    customer_email = serializers.EmailField(required=False, allow_blank=True)

    def validate_customer_name(self, value):
        """Clean customer name"""
        if value:
            return value.strip()
        return value

    def validate_customer_phone(self, value):
        """Clean customer phone"""
        if value:
            return value.strip()
        return value

    def validate_customer_email(self, value):
        """Clean customer email"""
        if value:
            return value.strip().lower()
        return value
    