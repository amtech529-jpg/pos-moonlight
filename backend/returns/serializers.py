from rest_framework import serializers
from decimal import Decimal
from django.db import transaction

from .models import RentalReturn, RentalReturnItem, DamageRecovery


class RentalReturnItemSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    
    class Meta:
        model = RentalReturnItem
        fields = [
            'id', 'product', 'product_name', 'qty_sent', 'qty_returned',
            'qty_damaged', 'qty_missing', 'damage_charge', 'condition_notes',
            'is_partner_item',
        ]
        read_only_fields = ['id']


class DamageRecoverySerializer(serializers.ModelSerializer):
    class Meta:
        model = DamageRecovery
        fields = ['id', 'recovery_type', 'amount', 'notes', 'created_at']
        read_only_fields = ['id', 'created_at']


class RentalReturnSerializer(serializers.ModelSerializer):
    items = RentalReturnItemSerializer(many=True, read_only=True)
    recoveries = DamageRecoverySerializer(many=True, read_only=True)
    order_number = serializers.CharField(source='order.id', read_only=True)
    customer_name = serializers.CharField(source='order.customer_name', read_only=True)
    damage_balance = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    is_fully_recovered = serializers.BooleanField(read_only=True)
    
    class Meta:
        model = RentalReturn
        fields = [
            'id', 'order', 'order_number', 'customer_name',
            'return_date', 'status', 'responsibility',
            'damage_charges', 'damage_recovered', 'damage_balance',
            'is_fully_recovered',
            'notes', 'total_items_sent', 'total_items_returned',
            'total_items_damaged', 'total_items_missing',
            'is_stock_restored',
            'items', 'recoveries',
            'created_at', 'updated_at',
        ]
        read_only_fields = [
            'id', 'return_date', 'damage_charges', 'damage_recovered',
            'total_items_sent', 'total_items_returned',
            'total_items_damaged', 'total_items_missing',
            'is_stock_restored', 'created_at', 'updated_at',
        ]


class CreateRentalReturnItemSerializer(serializers.Serializer):
    product = serializers.CharField(required=False, allow_null=True, allow_blank=True,
        help_text="Product UUID (or leave blank if providing order_item_id)")
    order_item_id = serializers.UUIDField(required=False, allow_null=True,
        help_text="Alternative to product: the order item UUID from which we resolve the product")
    qty_sent = serializers.IntegerField(min_value=0)
    qty_returned = serializers.IntegerField(min_value=0, default=0)
    qty_damaged = serializers.IntegerField(min_value=0, default=0)
    qty_missing = serializers.IntegerField(min_value=0, default=0)
    damage_charge = serializers.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    condition_notes = serializers.CharField(required=False, allow_blank=True, default='')
    is_partner_item = serializers.BooleanField(default=False)
    
    product_name = serializers.CharField(required=False, allow_null=True, allow_blank=True,
        help_text="Product name, used to look up product if order_item_id has null product FK")

    def validate(self, data):
        # Normalize empty product string to None
        if data.get('product') == '' or data.get('product') == 'null':
            data['product'] = None

        # Must have either product or order_item_id
        if not data.get('product') and not data.get('order_item_id') and not data.get('product_name'):
            raise serializers.ValidationError(
                "Either 'product' (UUID), 'order_item_id', or 'product_name' must be provided"
            )
        
        # Resolve product from order_item_id if product not given
        if not data.get('product') and data.get('order_item_id'):
            from order_items.models import OrderItem
            from products.models import Product
            try:
                order_item = OrderItem.objects.select_related('product').get(id=data['order_item_id'])
                if order_item.product:
                    # Best case: product FK is available
                    data['product'] = order_item.product.id
                elif order_item.product_name:
                    # Fallback: look up by product_name
                    product = Product.objects.filter(
                        name__iexact=order_item.product_name, is_active=True
                    ).first()
                    if product:
                        data['product'] = product.id
                    else:
                        raise serializers.ValidationError(
                            f"Cannot find product '{order_item.product_name}' in the system"
                        )
                else:
                    raise serializers.ValidationError(
                        f"Order item {data['order_item_id']} has no associated product"
                    )
            except OrderItem.DoesNotExist:
                raise serializers.ValidationError(
                    f"Order item {data['order_item_id']} not found"
                )

        # If still no product, try product_name field
        if not data.get('product') and data.get('product_name'):
            from products.models import Product
            product = Product.objects.filter(
                name__iexact=data['product_name'], is_active=True
            ).first()
            if product:
                data['product'] = product.id
            else:
                raise serializers.ValidationError(
                    f"Cannot find product '{data['product_name']}' in the system"
                )

        if not data.get('product'):
            raise serializers.ValidationError(
                "Could not resolve product. Please ensure the product exists in the system."
            )

        total = data.get('qty_returned', 0) + data.get('qty_damaged', 0) + data.get('qty_missing', 0)
        if total > data['qty_sent']:
            raise serializers.ValidationError(
                f"Total accounted ({total}) cannot exceed quantity sent ({data['qty_sent']})"
            )
        return data


class CreateRentalReturnSerializer(serializers.Serializer):
    order = serializers.UUIDField()
    responsibility = serializers.ChoiceField(
        choices=RentalReturn.RESPONSIBILITY_CHOICES, default='NONE'
    )
    notes = serializers.CharField(required=False, allow_blank=True, default='')
    items = CreateRentalReturnItemSerializer(many=True, required=True)
    restore_stock = serializers.BooleanField(default=False,
        help_text="Whether to immediately restore stock for owned items")
    
    def validate_order(self, value):
        from orders.models import Order
        try:
            order = Order.objects.get(id=value, is_active=True)
        except Order.DoesNotExist:
            raise serializers.ValidationError("Order not found")
        
        if order.status != 'DELIVERED':
            raise serializers.ValidationError("Only orders with 'DELIVERED' status can be processed for return.")

        # Check if return already exists
        if RentalReturn.objects.filter(order=order).exists():
            raise serializers.ValidationError("A return already exists for this order")
        
        return value
    
    def validate_items(self, value):
        if not value:
            raise serializers.ValidationError("At least one item is required")
        return value

    @transaction.atomic
    def create(self, validated_data):
        from orders.models import Order
        from products.models import Product
        
        items_data = validated_data.pop('items')
        do_restore_stock = validated_data.pop('restore_stock', False)
        order_id = validated_data.pop('order')
        order = Order.objects.get(id=order_id)
        
        user = self.context.get('request', {})
        if hasattr(user, 'user'):
            user = user.user
        else:
            user = None
        
        rental_return = RentalReturn.objects.create(
            order=order,
            responsibility=validated_data.get('responsibility', 'NONE'),
            notes=validated_data.get('notes', ''),
            processed_by=user,
        )
        
        for item_data in items_data:
            product = Product.objects.get(id=item_data['product'])
            
            # Auto-detect partner status from order item if not provided
            is_partner = item_data.get('is_partner_item', False)
            if not is_partner:
                from order_items.models import OrderItem
                # Try to find corresponding order item to check partner status
                order_item = OrderItem.objects.filter(
                    order=order, product=product, is_active=True
                ).first()
                if order_item:
                    is_partner = order_item.rented_from_partner

            RentalReturnItem.objects.create(
                rental_return=rental_return,
                product=product,
                qty_sent=item_data['qty_sent'],
                qty_returned=item_data.get('qty_returned', 0),
                qty_damaged=item_data.get('qty_damaged', 0),
                qty_missing=item_data.get('qty_missing', 0),
                damage_charge=item_data.get('damage_charge', Decimal('0.00')),
                condition_notes=item_data.get('condition_notes', ''),
                is_partner_item=is_partner,
            )
        
        # Update totals and status
        rental_return.update_totals()
        rental_return.update_status()
        rental_return.save()
        
        # Update order status to RETURNED
        order.status = 'RETURNED'
        order.save(update_fields=['status', 'updated_at'])
        
        # Optionally restore stock immediately
        if do_restore_stock:
            rental_return.restore_stock(user=user)
        
        return rental_return


class TallyItemSerializer(serializers.Serializer):
    """Serializer for tallying individual items (updating return counts)"""
    id = serializers.UUIDField(required=False, help_text="ID of the rental return item")
    product = serializers.UUIDField()
    qty_returned = serializers.IntegerField(min_value=0)
    qty_damaged = serializers.IntegerField(min_value=0, default=0)
    qty_missing = serializers.IntegerField(min_value=0, default=0)
    damage_charge = serializers.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    condition_notes = serializers.CharField(required=False, allow_blank=True, default='')
    is_partner_item = serializers.BooleanField(required=False)


class TallyReturnSerializer(serializers.Serializer):
    """Serializer for the tally operation — updating return item counts on an existing return"""
    items = TallyItemSerializer(many=True, required=True)
    responsibility = serializers.ChoiceField(
        choices=RentalReturn.RESPONSIBILITY_CHOICES, required=False
    )
    notes = serializers.CharField(required=False, allow_blank=True)
    restore_stock = serializers.BooleanField(default=False,
        help_text="Whether to restore stock after tallying")
    
    @transaction.atomic
    def update(self, rental_return, validated_data):
        items_data = validated_data.pop('items')
        do_restore_stock = validated_data.pop('restore_stock', False)
        
        user = self.context.get('request', {})
        if hasattr(user, 'user'):
            user = user.user
        else:
            user = None
        
        from products.models import Product
        
        for item_data in items_data:
            item_id = item_data.get('id')
            product_id = item_data['product']
            
            try:
                if item_id:
                    return_item = RentalReturnItem.objects.get(
                        id=item_id, rental_return=rental_return
                    )
                else:
                    return_item = RentalReturnItem.objects.get(
                        rental_return=rental_return, product_id=product_id,
                        is_partner_item=item_data.get('is_partner_item', False)
                    )
                return_item.qty_returned = item_data['qty_returned']
                return_item.qty_damaged = item_data.get('qty_damaged', 0)
                return_item.qty_missing = item_data.get('qty_missing', 0)
                return_item.damage_charge = item_data.get('damage_charge', Decimal('0.00'))
                if item_data.get('condition_notes'):
                    return_item.condition_notes = item_data['condition_notes']
                if 'is_partner_item' in item_data:
                    return_item.is_partner_item = item_data['is_partner_item']
                return_item.save()
            except RentalReturnItem.DoesNotExist:
                raise serializers.ValidationError(
                    f"Item not found in this return"
                )
            except RentalReturnItem.MultipleObjectsReturned:
                raise serializers.ValidationError(
                    f"Multiple matching items found for product. Please provide an explicit item ID."
                )
        
        # Update responsibility and notes if provided
        if 'responsibility' in validated_data:
            rental_return.responsibility = validated_data['responsibility']
        if 'notes' in validated_data:
            rental_return.notes = validated_data['notes']

        # Update totals and status
        rental_return.update_totals()
        rental_return.update_status()
        rental_return.save()
        
        # Optionally restore stock
        if do_restore_stock and not rental_return.is_stock_restored:
            rental_return.restore_stock(user=user)
        
        return rental_return


class AddDamageRecoverySerializer(serializers.Serializer):
    """Serializer for recording damage recovery"""
    recovery_type = serializers.ChoiceField(choices=DamageRecovery.RECOVERY_TYPE_CHOICES)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, min_value=Decimal('0.01'))
    notes = serializers.CharField(required=False, allow_blank=True, default='')
    
    def create(self, validated_data):
        rental_return = self.context['rental_return']
        user = self.context.get('request', None)
        if hasattr(user, 'user'):
            user = user.user
        
        recovery = DamageRecovery.objects.create(
            rental_return=rental_return,
            recovery_type=validated_data['recovery_type'],
            amount=validated_data['amount'],
            notes=validated_data.get('notes', ''),
            created_by=user,
        )
        return recovery


class RestoreStockSerializer(serializers.Serializer):
    """Serializer to trigger stock restoration"""
    confirm = serializers.BooleanField(required=True)
    
    def validate_confirm(self, value):
        if not value:
            raise serializers.ValidationError("You must confirm stock restoration")
        return value
