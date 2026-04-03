from rest_framework import serializers
from decimal import Decimal
from .models import Return, ReturnItem, Refund, SaleItem


class ReturnSerializer(serializers.ModelSerializer):
    """Serializer for Return model"""
    
    sale_invoice_number = serializers.CharField(source='sale.invoice_number', read_only=True)
    customer_name = serializers.CharField(source='customer.name', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone', read_only=True)
    approved_by_name = serializers.CharField(source='approved_by.username', read_only=True)
    processed_by_name = serializers.CharField(source='processed_by.username', read_only=True)
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    return_items_count = serializers.SerializerMethodField()
    items_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Return
        fields = (
            'id', 'sale', 'sale_invoice_number', 'return_number', 'customer', 'customer_name', 
            'customer_phone', 'return_date', 'status', 'reason', 'reason_details', 
            'refund_amount', 'notes',
            'approved_by', 'approved_by_name', 'approved_at', 'processed_by', 'processed_by_name',
            'processed_at', 'is_active', 'created_at', 'updated_at', 'created_by', 'created_by_name',
            'return_items_count', 'items_count'
        )
        read_only_fields = (
            'id', 'return_number', 'return_date', 'refund_amount', 'approved_by', 
            'approved_at', 'processed_by', 'processed_at', 'created_at', 'updated_at',
            'sale_invoice_number', 'customer_name', 'customer_phone', 'approved_by_name',
            'processed_by_name', 'created_by_name', 'return_items_count', 'items_count'
        )
    
    def get_return_items_count(self, obj):
        """Get count of return items"""
        return obj.return_items.count()


class ReturnCreateSerializer(ReturnSerializer):
    """Serializer for creating returns"""
    
    return_items = serializers.ListField(
        child=serializers.DictField(),
        write_only=True,
        help_text="List of items to return"
    )
    
    class Meta:
        model = Return
        fields = (
            'sale', 'customer', 'reason', 'reason_details', 'notes', 'return_items'
        )
    
    def validate(self, data):
        """Validate return data"""
        sale = data.get('sale')
        customer = data.get('customer')
        return_items = data.get('return_items', [])
        
        # Validate sale exists and is active
        if not sale or not sale.is_active:
            raise serializers.ValidationError("Invalid or inactive sale.")
        
        # Validate customer matches sale customer (handle walk-in customers)
        if customer != sale.customer:
            # Allow if both are None (walk-in customer) or if both match
            if not (customer is None and sale.customer is None):
                raise serializers.ValidationError("Customer must match the sale customer.")
        
        # Validate return items
        if not return_items:
            raise serializers.ValidationError("At least one item must be returned.")
        
        # Validate each return item
        for item_data in return_items:
            sale_item_id = item_data.get('sale_item_id')
            quantity_returned = item_data.get('quantity_returned')
            condition = item_data.get('condition', 'GOOD')
            
            if not sale_item_id:
                raise serializers.ValidationError("Sale item ID is required for each return item.")
            
            try:
                sale_item = SaleItem.objects.get(id=sale_item_id, sale=sale, is_active=True)
            except SaleItem.DoesNotExist:
                raise serializers.ValidationError(f"Sale item {sale_item_id} not found or not associated with this sale.")
            
            if quantity_returned > sale_item.quantity:
                raise serializers.ValidationError(f"Return quantity cannot exceed sold quantity for item {sale_item.product_name}.")
            
            if quantity_returned <= 0:
                raise serializers.ValidationError(f"Return quantity must be positive for item {sale_item.product_name}.")
        
        return data
    
    def create(self, validated_data):
        """Create return with return items"""
        return_items_data = validated_data.pop('return_items')
        
        # Create return
        return_request = Return.objects.create(**validated_data)
        
        # Create return items
        total_return_amount = Decimal('0.00')
        for item_data in return_items_data:
            sale_item = SaleItem.objects.get(id=item_data['sale_item_id'])
            
            # Calculate return amount based on quantity and original unit price
            quantity_returned = item_data['quantity_returned']
            original_unit_price = sale_item.unit_price
            calculated_return_amount = original_unit_price * quantity_returned
            
            print(f"🔍 [ReturnSerializer] Item: {sale_item.product.name}, Qty: {quantity_returned}, Unit Price: {original_unit_price}, Calculated: {calculated_return_amount}")
            
            # Use provided return_amount if available, otherwise use calculated amount
            return_amount = Decimal(str(item_data.get('return_amount', calculated_return_amount)))
            
            return_item = ReturnItem.objects.create(
                return_request=return_request,
                sale_item=sale_item,
                quantity_returned=quantity_returned,
                return_amount=return_amount,
                condition=item_data.get('condition', 'GOOD'),
                return_reason=validated_data.get('reason', '')
            )
            
            total_return_amount += return_amount
            print(f"✅ [ReturnSerializer] Created return item with amount {return_amount}, running total: {total_return_amount}")
        
        # Update total return amount
        return_request.refund_amount = total_return_amount
        return_request.save()
        print(f"💰 [ReturnSerializer] Final refund_amount set to: {total_return_amount}")
        
        return return_request


class ReturnUpdateSerializer(ReturnSerializer):
    """Serializer for updating returns"""
    
    class Meta:
        model = Return
        fields = ('reason_details', 'notes')
    
    def validate(self, data):
        """Validate update data"""
        if self.instance.status not in ['PENDING']:
            raise serializers.ValidationError("Return can only be updated when status is PENDING.")
        return data


class ReturnItemSerializer(serializers.ModelSerializer):
    """Serializer for ReturnItem model"""
    
    product_name = serializers.CharField(source='product.name', read_only=True)
    sale_item_id = serializers.UUIDField(source='sale_item.id', read_only=True)
    
    class Meta:
        model = ReturnItem
        fields = (
            'id', 'return_request', 'sale_item', 'sale_item_id', 'product', 'product_name',
            'quantity_returned', 'original_quantity', 'original_price', 'return_amount',
            'condition', 'condition_notes', 'is_active', 'created_at', 'updated_at'
        )
        read_only_fields = (
            'id', 'return_request', 'sale_item', 'sale_item_id', 'product', 'product_name',
            'original_quantity', 'original_price', 'return_amount', 'created_at', 'updated_at'
        )


class RefundSerializer(serializers.ModelSerializer):
    """Serializer for Refund model"""
    
    return_number = serializers.CharField(source='return_request.return_number', read_only=True)
    sale_invoice_number = serializers.CharField(source='return_request.sale.invoice_number', read_only=True)
    customer_name = serializers.CharField(source='return_request.customer.name', read_only=True)
    processed_by_name = serializers.CharField(source='processed_by.username', read_only=True)
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = Refund
        fields = (
            'id', 'return_request', 'return_number', 'sale_invoice_number', 'customer_name',
            'refund_number', 'refund_date', 'amount', 'method', 'status', 'reference_number',
            'notes', 'processed_by', 'processed_by_name', 'processed_at', 'is_active',
            'created_at', 'updated_at', 'created_by', 'created_by_name'
        )
        read_only_fields = (
            'id', 'refund_number', 'refund_date', 'status', 'processed_by', 'processed_at',
            'created_at', 'updated_at', 'return_number', 'sale_invoice_number', 'customer_name',
            'processed_by_name', 'created_by_name'
        )


class RefundCreateSerializer(RefundSerializer):
    """Serializer for creating refunds"""
    
    class Meta:
        model = Refund
        fields = ('return_request', 'amount', 'method', 'notes')
    
    def validate(self, data):
        """Validate refund data"""
        return_request = data.get('return_request')
        amount = data.get('amount')
        method = data.get('method')
        
        # Validate return request exists and is processed
        if not return_request or return_request.status != 'PROCESSED':
            raise serializers.ValidationError("Return request must be processed before creating a refund.")
        
        # Validate amount
        if amount <= 0:
            raise serializers.ValidationError("Refund amount must be positive.")
        
        if amount > return_request.total_return_amount:
            raise serializers.ValidationError("Refund amount cannot exceed total return amount.")
        
        # Validate method
        valid_methods = ['CASH', 'CREDIT_NOTE', 'EXCHANGE', 'BANK_TRANSFER']
        if method not in valid_methods:
            raise serializers.ValidationError(f"Invalid refund method. Must be one of: {', '.join(valid_methods)}")
        
        return data


class RefundUpdateSerializer(RefundSerializer):
    """Serializer for updating refunds"""
    
    class Meta:
        model = Refund
        fields = ('notes',)
    
    def validate(self, data):
        """Validate update data"""
        if self.instance.status != 'PENDING':
            raise serializers.ValidationError("Refund can only be updated when status is PENDING.")
        return data


class ReturnListSerializer(serializers.ModelSerializer):
    """Serializer for listing returns"""
    
    sale_invoice_number = serializers.CharField(source='sale.invoice_number', read_only=True)
    customer_name = serializers.SerializerMethodField()
    customer_phone = serializers.SerializerMethodField()
    approved_by = serializers.SerializerMethodField()
    approved_by_name = serializers.SerializerMethodField()
    processed_by = serializers.SerializerMethodField()
    processed_by_name = serializers.SerializerMethodField()
    created_by = serializers.SerializerMethodField()
    created_by_name = serializers.SerializerMethodField()
    return_items_count = serializers.SerializerMethodField()
    total_return_amount = serializers.DecimalField(max_digits=15, decimal_places=2, read_only=True)
    
    class Meta:
        model = Return
        fields = (
            'id', 'sale', 'sale_invoice_number', 'customer', 'customer_name', 'customer_phone',
            'return_number', 'return_date', 'status', 'reason', 'reason_details', 'notes',
            'refund_amount', 'total_return_amount', 'return_items_count',
            'approved_by', 'approved_by_name', 'approved_at', 'processed_by', 'processed_by_name',
            'processed_at', 'is_active', 'created_at', 'updated_at', 'created_by', 'created_by_name'
        )
    
    def get_customer_name(self, obj):
        """Get customer name or Walk-in for null customer"""
        return obj.customer.name if obj.customer else 'Walk-in Customer'
    
    def get_customer_phone(self, obj):
        """Get customer phone or empty string for null customer"""
        return obj.customer.phone if obj.customer else ''
    
    def get_approved_by(self, obj):
        """Get approved by ID as string"""
        return str(obj.approved_by.id) if obj.approved_by and hasattr(obj.approved_by, 'id') else ''
    
    def get_approved_by_name(self, obj):
        """Get approved by username"""
        return obj.approved_by.username if obj.approved_by and hasattr(obj.approved_by, 'username') else ''
    
    def get_processed_by(self, obj):
        """Get processed by ID as string"""
        return str(obj.processed_by.id) if obj.processed_by and hasattr(obj.processed_by, 'id') else ''
    
    def get_processed_by_name(self, obj):
        """Get processed by username"""
        return obj.processed_by.username if obj.processed_by and hasattr(obj.processed_by, 'username') else ''
    
    def get_created_by(self, obj):
        """Get created by ID as string"""
        return str(obj.created_by.id) if obj.created_by and hasattr(obj.created_by, 'id') else ''
    
    def get_created_by_name(self, obj):
        """Get created by username"""
        return obj.created_by.username if obj.created_by and hasattr(obj.created_by, 'username') else ''
    
    def get_return_items_count(self, obj):
        """Get count of return items"""
        return obj.return_items.count()


class RefundListSerializer(serializers.ModelSerializer):
    """Serializer for listing refunds"""
    
    def to_representation(self, instance):
        """Override to add error handling and safe field access"""
        try:
            print(f"🔍 [RefundListSerializer] Serializing refund: {instance.id} - {instance.refund_number}")
            
            # Basic refund data
            data = {
                'id': str(instance.id),
                'refund_number': instance.refund_number or '',
                'amount': float(instance.amount) if instance.amount else 0.0,
                'method': instance.method or '',
                'status': instance.status or '',
                'created_at': instance.created_at.isoformat() if instance.created_at else None,
                'updated_at': instance.updated_at.isoformat() if instance.updated_at else None,
                'reference_number': instance.reference_number or '',
                'notes': instance.notes or '',
                'processed_at': instance.processed_at.isoformat() if instance.processed_at else None,
                'is_active': instance.is_active,
            }
            
            # Try to get return request data with simple access
            try:
                if hasattr(instance, 'return_request') and instance.return_request:
                    data['return_number'] = getattr(instance.return_request, 'return_number', '') or ''
                    data['return_request_id'] = str(instance.return_request.id) if instance.return_request.id else ''
                    data['customer_name'] = getattr(instance.return_request, 'customer_name', '') or 'Walk-in Customer'
                    
                    # Try to get sale invoice number
                    if hasattr(instance.return_request, 'sale') and instance.return_request.sale:
                        data['sale_invoice_number'] = getattr(instance.return_request.sale, 'invoice_number', '') or ''
                    else:
                        data['sale_invoice_number'] = ''
                else:
                    print(f"⚠️ [RefundListSerializer] No return_request found for refund {instance.id}")
                    data['return_number'] = ''
                    data['return_request_id'] = ''
                    data['customer_name'] = 'Walk-in Customer'
                    data['sale_invoice_number'] = ''
            except Exception as e:
                print(f"⚠️ [RefundListSerializer] Error accessing return request: {e}")
                data['return_number'] = ''
                data['return_request_id'] = ''
                data['customer_name'] = 'Walk-in Customer'
                data['sale_invoice_number'] = ''
            
            # Try to get user data
            try:
                if hasattr(instance, 'processed_by') and instance.processed_by:
                    data['processed_by'] = str(instance.processed_by.id)
                    data['processed_by_name'] = getattr(instance.processed_by, 'username', '') or ''
                else:
                    data['processed_by'] = ''
                    data['processed_by_name'] = ''
            except Exception as e:
                print(f"⚠️ [RefundListSerializer] Error accessing processed_by: {e}")
                data['processed_by'] = ''
                data['processed_by_name'] = ''
            
            try:
                if hasattr(instance, 'created_by') and instance.created_by:
                    data['created_by'] = str(instance.created_by.id)
                    data['created_by_name'] = getattr(instance.created_by, 'username', '') or getattr(instance.created_by, 'email', '') or ''
                else:
                    data['created_by'] = ''
                    data['created_by_name'] = ''
            except Exception as e:
                print(f"⚠️ [RefundListSerializer] Error accessing created_by: {e}")
                data['created_by'] = ''
                data['created_by_name'] = ''
            
            print(f"✅ [RefundListSerializer] Final data: {data}")
            return data
            
        except Exception as e:
            print(f"❌ [RefundListSerializer] Critical error: {e}")
            import traceback
            traceback.print_exc()
            return {
                'id': str(instance.id),
                'refund_number': getattr(instance, 'refund_number', 'ERROR'),
                'return_number': '',
                'customer_name': 'Walk-in Customer',
                'amount': '0.00',
                'method': getattr(instance, 'method', 'ERROR'),
                'status': getattr(instance, 'status', 'ERROR'),
                'created_at': getattr(instance, 'created_at', None)
            }
