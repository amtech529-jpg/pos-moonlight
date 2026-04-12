from rest_framework import serializers
from .models import Purchase, PurchaseItem
from products.models import Product

class PurchaseItemSerializer(serializers.ModelSerializer):
    product_name = serializers.ReadOnlyField(source='product.name')
    category_name = serializers.ReadOnlyField(source='product.category.name')

    class Meta:
        model = PurchaseItem
        fields = ['product', 'product_name', 'category_name', 'quantity', 'unit_cost', 'retail_price', 'total_cost', 'description']

class PurchaseSerializer(serializers.ModelSerializer):
    items = PurchaseItemSerializer(many=True)
    # ✅ FIX: Send the vendor name directly from the backend
    vendor_name = serializers.ReadOnlyField(source='vendor.name')

    class Meta:
        model = Purchase
        fields = [
            'id',
            'vendor',
            'vendor_name', # ✅ Added here
            'invoice_number',
            'purchase_date',
            'subtotal',
            'tax',
            'total',
            'status',
            'items',
        ]
        read_only_fields = ['subtotal', 'total', 'vendor_name']

    def create(self, validated_data):
        items_data = validated_data.pop('items')

        # Initialize total=0 to satisfy DB constraint
        purchase = Purchase.objects.create(total=0, subtotal=0, **validated_data)

        subtotal = 0
        for item in items_data:
            product = item['product']
            quantity = item['quantity']
            unit_cost = item['unit_cost']
            # ✅ Round to 2 decimal places to prevent precision errors
            total_cost = round(quantity * unit_cost, 2)

            PurchaseItem.objects.create(
                purchase=purchase,
                product=product,
                quantity=quantity,
                unit_cost=unit_cost,
                retail_price=item.get('retail_price', 0), # ✅ Added
                total_cost=total_cost,
                description=item.get('description', '')
            )
            
            # Stock update removed from here to prevent double-counting (Views handle it)
            subtotal += total_cost

        purchase.subtotal = round(subtotal, 2)
        purchase.total = round(subtotal + purchase.tax, 2)
        purchase.save()

        return purchase

    def update(self, instance, validated_data):
        items_data = validated_data.pop('items', [])

        # Update top-level fields
        instance.vendor = validated_data.get('vendor', instance.vendor)
        instance.invoice_number = validated_data.get('invoice_number', instance.invoice_number)
        instance.purchase_date = validated_data.get('purchase_date', instance.purchase_date)
        instance.tax = validated_data.get('tax', instance.tax)
        instance.status = validated_data.get('status', instance.status)

        # Stock reversal removed from here (Views handle it)
        old_items.delete()

        # Create new items
        subtotal = 0
        for item in items_data:
            product = item['product']
            quantity = item['quantity']
            unit_cost = item['unit_cost']
            total_cost = round(quantity * unit_cost, 2)

            PurchaseItem.objects.create(
                purchase=instance,
                product=product,
                quantity=quantity,
                unit_cost=unit_cost,
                retail_price=item.get('retail_price', 0), # ✅ Added
                total_cost=total_cost,
                description=item.get('description', '')
            )

            # Stock update removed from here (Views handle it)
            subtotal += total_cost

        instance.subtotal = round(subtotal, 2)
        instance.total = round(subtotal + instance.tax, 2)
        instance.save()

        return instance