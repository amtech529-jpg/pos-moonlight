from rest_framework import serializers
from django.db.models import Q
from .models import OrderItem
from products.models import Product
from orders.models import Order


class OrderItemSerializer(serializers.ModelSerializer):
    """Complete serializer for OrderItem model"""
    
    # Order details
    order_id = serializers.UUIDField(source='order.id', read_only=True)
    
    # Product details
    product_id = serializers.UUIDField(source='product.id', read_only=True)
    product_color = serializers.CharField(source='product.color', read_only=True)
    product_fabric = serializers.CharField(source='product.fabric', read_only=True)
    product_category = serializers.CharField(source='product.category.name', read_only=True)
    current_stock = serializers.IntegerField(source='product.quantity', read_only=True)
    
    # Computed fields
    total_value = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True, source='line_total')
    product_display_info = serializers.JSONField(read_only=True)
    partner_name = serializers.ReadOnlyField(source='partner.name')
    
    class Meta:
        model = OrderItem
        fields = (
            'id',
            'order_id',
            'product_id',
            'product_name',
            'product_color',
            'product_fabric',
            'product_category',
            'current_stock',
            'quantity',
            'rate',
            'days',
            'customization_notes',
            'line_total',
            'total_value',
            'product_display_info',
            'is_active',
            'created_at',
            'updated_at',
            'rented_from_partner',
            'partner',
            'partner_name',
            'partner_rate'
        )
        read_only_fields = (
            'id', 'order_id', 'product_id', 'product_name', 'product_color',
            'product_fabric', 'product_category', 'current_stock', 'line_total', 'total_value',
            'product_display_info', 'created_at', 'updated_at'
        )

    def validate_quantity(self, value):
        """Validate quantity field"""
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than zero.")
        return value

    def validate_rate(self, value):
        """Validate rate field"""
        if value < 0:
            raise serializers.ValidationError("Rate cannot be negative.")
        if value > 9999999999.99:  # Max value for decimal(12,2)
            raise serializers.ValidationError("Rate is too large.")
        return value

    def validate_days(self, value):
        """Validate days field"""
        if value <= 0:
            raise serializers.ValidationError("Days must be greater than zero.")
        return value

    def validate_customization_notes(self, value):
        """Clean customization notes"""
        if value:
            return value.strip()
        return value


class OrderItemCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating order items"""
    
    order = serializers.UUIDField(write_only=True, help_text="Order UUID")
    product = serializers.UUIDField(write_only=True, help_text="Product UUID")
    
    class Meta:
        model = OrderItem
        fields = (
            'order',
            'product',
            'quantity',
            'rate',
            'days',
            'customization_notes',
            'rented_from_partner',
            'partner',
            'partner_rate'
        )

    def validate_order(self, value):
        """Validate order exists and is active"""
        try:
            # Use select_related to optimize the query
            order = Order.objects.select_related().get(id=value, is_active=True)
            return order
        except Order.DoesNotExist:
            raise serializers.ValidationError("Invalid order or order is not active.")

    def validate_product(self, value):
        """Validate product exists and is active"""
        try:
            # Use select_related to optimize the query
            product = Product.objects.select_related().get(id=value, is_active=True)
            return product
        except Product.DoesNotExist:
            raise serializers.ValidationError("Invalid product or product is not active.")

    def validate_quantity(self, value):
        """Validate quantity field"""
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than zero.")
        return value

    def validate_rate(self, value):
        """Validate rate field"""
        if value < 0:
            raise serializers.ValidationError("Rate cannot be negative.")
        if value > 9999999999.99:
            raise serializers.ValidationError("Rate is too large.")
        return value

    def validate_days(self, value):
        """Validate days field"""
        if value <= 0:
            raise serializers.ValidationError("Days must be greater than zero.")
        return value

    def validate_customization_notes(self, value):
        """Clean customization notes"""
        if value:
            return value.strip()
        return value

    def validate(self, data):
        """Cross-field validation"""
        order = data.get('order')
        product = data.get('product')
        quantity = data.get('quantity')
        
        # Check if product is already in this order - use exists() for better performance
        if OrderItem.objects.filter(order=order, product=product, is_active=True).exists():
            raise serializers.ValidationError({
                'product': 'This product is already in the order. Update the existing item instead.'
            })
        
        # Check if enough stock is available - skip for partner rentals
        if not data.get('rented_from_partner', False):
            # Use date-aware availability check
            available_for_dates = product.get_available_quantity_for_dates(
                start_date=order.event_date,
                end_date=order.return_date or order.event_date
            )
            if available_for_dates < quantity:
                raise serializers.ValidationError({
                    'quantity': f'Not enough stock for these dates ({order.event_date} to {order.return_date or order.event_date}). Available: {available_for_dates}, Requested: {quantity}'
                })
        
        # If rate not provided, use product price
        if 'rate' not in data or data['rate'] is None:
            data['rate'] = product.price
        
        return data

    def create(self, validated_data):
        """Create order item with optimized database operations"""
        try:
            # Use bulk_create for better performance if creating multiple items
            order_item = super().create(validated_data)
            return order_item
        except Exception as e:
            # Log the error for debugging
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error creating order item: {str(e)}")
            raise


class OrderItemUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating order items"""
    
    class Meta:
        model = OrderItem
        fields = (
            'quantity',
            'rate',
            'days',
            'customization_notes',
            'rented_from_partner',
            'partner',
            'partner_rate'
        )

    def validate_quantity(self, value):
        """Validate quantity field basics"""
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than zero.")
        return value

    def validate(self, data):
        """Cross-field validation for updates"""
        quantity = data.get('quantity', self.instance.quantity)
        rented_from_partner = data.get('rented_from_partner', self.instance.rented_from_partner)
        
        # Check stock availability for the quantity change (only for non-partner items)
        if quantity > self.instance.quantity and not rented_from_partner:
            quantity_difference = quantity - self.instance.quantity
            if self.instance.product and self.instance.order:
                order = self.instance.order
                available_for_dates = self.instance.product.get_available_quantity_for_dates(
                    start_date=order.event_date,
                    end_date=order.return_date or order.event_date,
                    exclude_order_id=order.id # Exclude current order's existing quantity of this item
                )
                if available_for_dates < quantity_difference:
                    raise serializers.ValidationError({
                        'quantity': f'Not enough stock for these dates. Available: {available_for_dates}, Additional needed: {quantity_difference}'
                    })
        
        return data

    def validate_rate(self, value):
        """Validate rate field"""
        if value < 0:
            raise serializers.ValidationError("Rate cannot be negative.")
        if value > 9999999999.99:
            raise serializers.ValidationError("Rate is too large.")
        return value

    def validate_days(self, value):
        """Validate days field"""
        if value <= 0:
            raise serializers.ValidationError("Days must be greater than zero.")
        return value

    def validate_customization_notes(self, value):
        """Clean customization notes"""
        if value:
            return value.strip()
        return value


class OrderItemListSerializer(serializers.ModelSerializer):
    """Minimal serializer for listing order items"""
    
    order_id = serializers.UUIDField(source='order.id', read_only=True)
    product_id = serializers.UUIDField(source='product.id', read_only=True)
    product_color = serializers.CharField(source='product.color', read_only=True)
    product_fabric = serializers.CharField(source='product.fabric', read_only=True)
    remaining_to_sell = serializers.IntegerField(source='remaining_quantity_to_sell', read_only=True)
    has_been_sold = serializers.BooleanField(read_only=True)
    
    # Alternative field names for customization_notes for backward compatibility
    notes = serializers.CharField(source='customization_notes', read_only=True)
    description = serializers.CharField(source='customization_notes', read_only=True)
    comment = serializers.CharField(source='customization_notes', read_only=True)
    remarks = serializers.CharField(source='customization_notes', read_only=True)
    
    class Meta:
        model = OrderItem
        fields = (
            'id',
            'order_id',
            'product_id',
            'product_name',
            'product_color',
            'product_fabric',
            'quantity',
            'rate',
            'days',
            'customization_notes',
            'notes',
            'description',
            'comment',
            'remarks',
            'line_total',
            'is_active',
            'created_at',
            'updated_at',
            'remaining_to_sell', 'has_been_sold',
            'rented_from_partner', 'partner', 'partner_rate'
        )


class OrderItemDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for single order item view"""
    
    order = serializers.SerializerMethodField()
    product = serializers.SerializerMethodField()
    product_display_info = serializers.JSONField(read_only=True)
    remaining_quantity_to_sell = serializers.ReadOnlyField()
    has_been_sold = serializers.BooleanField(read_only=True)
    related_sale_items = serializers.SerializerMethodField()
    
    class Meta:
        model = OrderItem
        fields = (
            'id',
            'order',
            'productId', # For compatibility
            'productName', # For compatibility
            'product_name',
            'quantity',
            'rate',
            'days',
            'customization_notes',
            'line_total',
            'product_display_info',
            'is_active',
            'created_at',
            'updated_at',
            'remaining_quantity_to_sell', 'has_been_sold', 'related_sale_items',
            'rented_from_partner', 'partner', 'partner_rate'
        )

    def get_related_sale_items(self, obj):
        """Get sale items created from this order item"""
        sale_items = obj.get_related_sale_items()
        return [
            {
                'id': str(item.id),
                'sale_id': str(item.sale.id),
                'quantity': item.quantity,
                'rate': float(item.rate),
                'days': item.days,
                'line_total': float(item.line_total)
            }
            for item in sale_items
        ]

    def get_order(self, obj):
        """Get order details"""
        return {
            'id': str(obj.order.id),
            'customer_name': obj.order.customer_name,
            'status': obj.order.status,
            'date_ordered': obj.order.date_ordered
        }

    def get_product(self, obj):
        """Get product details"""
        if obj.product:
            return {
                'id': str(obj.product.id),
                'name': obj.product.name,
                'color': obj.product.color,
                'fabric': obj.product.fabric,
                'current_price': obj.product.price,
                'current_stock': obj.product.quantity
            }
        return {
            'name': obj.product_name,
            'note': 'Product no longer available'
        }


class OrderItemStatsSerializer(serializers.Serializer):
    """Serializer for order item statistics"""
    
    total_items = serializers.IntegerField()
    total_quantity_ordered = serializers.IntegerField()
    total_value = serializers.DecimalField(max_digits=15, decimal_places=2)
    average_quantity_per_item = serializers.DecimalField(max_digits=10, decimal_places=2)
    average_rate = serializers.DecimalField(max_digits=12, decimal_places=2)
    top_products = serializers.ListField()


class OrderItemBulkUpdateSerializer(serializers.Serializer):
    """Serializer for bulk order item updates"""
    
    updates = serializers.ListField(
        child=serializers.DictField(
            child=serializers.CharField()
        ),
        help_text="List of {order_item_id: {field: value}} updates"
    )

    def validate_updates(self, value):
        """Validate bulk updates"""
        if not value:
            raise serializers.ValidationError("At least one update is required.")
        
        validated_updates = []
        item_ids = []
        
        for update in value:
            if 'order_item_id' not in update:
                raise serializers.ValidationError(
                    "Each update must contain 'order_item_id'."
                )
            
            order_item_id = update['order_item_id']
            item_ids.append(order_item_id)
            
            # Validate update fields
            allowed_fields = ['quantity', 'rate', 'customization_notes']
            update_fields = {k: v for k, v in update.items() if k != 'order_item_id'}
            
            if not update_fields:
                raise serializers.ValidationError(
                    f"No valid fields to update for item {order_item_id}."
                )
            
            for field in update_fields.keys():
                if field not in allowed_fields:
                    raise serializers.ValidationError(
                        f"Field '{field}' is not allowed for bulk update."
                    )
            
            # Validate field values
            if 'quantity' in update_fields:
                try:
                    quantity = int(update_fields['quantity'])
                    if quantity <= 0:
                        raise ValueError
                    update_fields['quantity'] = quantity
                except (ValueError, TypeError):
                    raise serializers.ValidationError(
                        f"Invalid quantity for item {order_item_id}."
                    )
            
            if 'rate' in update_fields:
                try:
                    rate = float(update_fields['rate'])
                    if rate < 0:
                        raise ValueError
                    update_fields['rate'] = rate
                except (ValueError, TypeError):
                    raise serializers.ValidationError(
                        f"Invalid rate for item {order_item_id}."
                    )
            
            validated_updates.append({
                'order_item_id': order_item_id,
                'fields': update_fields
            })
        
        # Check for duplicates
        if len(item_ids) != len(set(item_ids)):
            raise serializers.ValidationError("Duplicate order item IDs found in updates.")
        
        # Verify all order items exist and are active
        existing_items = OrderItem.objects.filter(
            id__in=item_ids,
            is_active=True
        ).values_list('id', flat=True)
        
        existing_ids = [str(item_id) for item_id in existing_items]
        missing_ids = [item_id for item_id in item_ids if item_id not in existing_ids]
        
        if missing_ids:
            raise serializers.ValidationError(
                f"Order items not found or inactive: {', '.join(missing_ids)}"
            )
        
        return validated_updates


class OrderItemQuantityUpdateSerializer(serializers.Serializer):
    """Serializer for updating order item quantity"""
    
    quantity = serializers.IntegerField(min_value=1, help_text="New quantity")

    def validate_quantity(self, value):
        """Validate quantity with stock check"""
        # This validation will be context-dependent and handled in the view
        return value
    