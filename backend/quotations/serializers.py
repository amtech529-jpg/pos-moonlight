from rest_framework import serializers
from .models import Quotation, QuotationItem
from products.models import Product
from customers.models import Customer

class QuotationItemSerializer(serializers.ModelSerializer):
    # This field will be writable for manual names but will return product.name if linked to inventory
    product_name = serializers.CharField(required=False, allow_null=True)

    class Meta:
        model = QuotationItem
        fields = [
            'id', 'product', 'product_name', 'quantity', 'rate', 'days', 
            'pricing_type', 'rented_from_partner', 'partner', 'partner_rate', 'total'
        ]
        read_only_fields = ['total']

    def to_representation(self, instance):
        ret = super().to_representation(instance)
        # If there's an inventory product, use its name for the display
        if instance.product:
            ret['product_name'] = instance.product.name
        return ret

class QuotationSerializer(serializers.ModelSerializer):
    items = QuotationItemSerializer(many=True, read_only=True)
    created_by_name = serializers.CharField(source='created_by.email', read_only=True)
    
    class Meta:
        model = Quotation
        fields = [
            'id', 'quotation_number', 'customer', 'company_name', 'customer_name', 
            'customer_phone', 'event_name', 'event_location', 'event_date', 'return_date',
            'valid_until', 'status', 'total_amount', 'discount_amount', 
            'final_amount', 'special_notes', 'items', 'created_at', 'created_by_name'
        ]
        read_only_fields = ['quotation_number', 'total_amount', 'final_amount', 'created_at']

class CreateQuotationSerializer(serializers.ModelSerializer):
    items = QuotationItemSerializer(many=True)

    class Meta:
        model = Quotation
        fields = [
            'id', 'quotation_number', 'customer', 'company_name', 'customer_name', 
            'customer_phone', 'event_name', 'event_location', 'event_date', 'return_date',
            'valid_until', 'status', 'total_amount', 'discount_amount', 
            'final_amount', 'special_notes', 'items', 'created_at'
        ]
        read_only_fields = ['id', 'quotation_number', 'status', 'total_amount', 'final_amount', 'created_at']

    def create(self, validated_data):
        try:
            items_data = validated_data.pop('items')
            user = self.context['request'].user
            print(f"DEBUG: Creating quotation for user {user}")
            print(f"DEBUG: Validated data: {validated_data}")
            
            quotation = Quotation.objects.create(created_by=user, **validated_data)
            print(f"DEBUG: Quotation created with ID {quotation.id}")
            
            for i, item_data in enumerate(items_data):
                print(f"DEBUG: Adding item {i}: {item_data}")
                QuotationItem.objects.create(quotation=quotation, **item_data)
            
            quotation.calculate_totals()
            print(f"DEBUG: Totals calculated. Final amount: {quotation.final_amount}")
            return quotation
        except Exception as e:
            print(f"DEBUG: ERROR in create quotation: {str(e)}")
            import traceback
            traceback.print_exc()
            raise

class UpdateQuotationSerializer(serializers.ModelSerializer):
    items = QuotationItemSerializer(many=True)

    class Meta:
        model = Quotation
        fields = [
            'id', 'quotation_number', 'customer', 'company_name', 'customer_name', 
            'customer_phone', 'event_name', 'event_location', 'event_date', 'return_date',
            'valid_until', 'status', 'total_amount', 'discount_amount', 
            'final_amount', 'special_notes', 'items', 'created_at'
        ]
        read_only_fields = ['id', 'quotation_number', 'total_amount', 'final_amount', 'created_at']

    def update(self, instance, validated_data):
        try:
            items_data = validated_data.pop('items', None)
            
            # Update quotation fields
            for attr, value in validated_data.items():
                setattr(instance, attr, value)
            instance.save()
            
            # Update items if provided
            if items_data is not None:
                # Delete existing items
                instance.items.all().delete()
                
                # Create new items
                for item_data in items_data:
                    QuotationItem.objects.create(quotation=instance, **item_data)
            
            # Recalculate totals
            instance.calculate_totals()
            
            # Auto-sync with Order if it's already converted
            if instance.status == 'CONVERTED':
                from orders.models import Order
                from order_items.models import OrderItem
                
                # Try to find the linked order via description match
                desc_prefix = f"Generated from Quotation {instance.quotation_number}"
                order = Order.objects.filter(description__startswith=desc_prefix).first()
                
                if order:
                    # Update Order details
                    order.total_amount = instance.final_amount
                    order.event_name = instance.event_name
                    order.event_location = instance.event_location
                    order.event_date = instance.event_date
                    order.return_date = instance.return_date
                    order.save()
                    
                    # Update Order items if they were changed
                    if items_data is not None:
                        order.order_items.all().delete()
                        for q_item in instance.items.all():
                            OrderItem.objects.create(
                                order=order,
                                product=q_item.product,
                                product_name=q_item.product_name or (q_item.product.name if q_item.product else "Unknown Item"),
                                quantity=q_item.quantity,
                                rate=q_item.rate,
                                days=q_item.days,
                                pricing_type=q_item.pricing_type,
                                line_total=q_item.total,
                                customization_notes=f"From Quote Item {q_item.id}",
                                rented_from_partner=q_item.rented_from_partner,
                                partner=q_item.partner,
                                partner_rate=q_item.partner_rate
                            )
                    # Recalculate order totals safely
                    order.calculate_totals()

            return instance
        except Exception as e:
            print(f"DEBUG: ERROR in update quotation: {str(e)}")
            import traceback
            traceback.print_exc()
            raise
