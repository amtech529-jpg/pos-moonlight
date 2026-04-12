from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction, models
from vendors.models import Vendor
from products.models import Product
from .models import Purchase, PurchaseItem
from .serializers import PurchaseSerializer

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def purchase_list(request):
    """
    List all purchases or create a new purchase
    """
    if request.method == 'GET':
        try:
            purchases = Purchase.objects.all().order_by('-created_at')
            
            # Vendor filter
            vendor_id = request.query_params.get('vendor')
            if vendor_id:
                purchases = purchases.filter(vendor_id=vendor_id)
            
            # Search by invoice number or vendor name
            search = request.query_params.get('search')
            if search:
                purchases = purchases.filter(
                    models.Q(invoice_number__icontains=search) |
                    models.Q(vendor__name__icontains=search)
                )
            
            # Date range filter
            date_from = request.query_params.get('date_from')
            date_to = request.query_params.get('date_to')
            if date_from:
                purchases = purchases.filter(purchase_date__gte=date_from)
            if date_to:
                purchases = purchases.filter(purchase_date__lte=date_to)
            
            # Status filter
            status_filter = request.query_params.get('status')
            if status_filter:
                purchases = purchases.filter(status=status_filter)
            
            serializer = PurchaseSerializer(purchases, many=True)
            
            return Response({
                'success': True,
                'data': serializer.data
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to fetch purchases.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    elif request.method == 'POST':
        try:
            with transaction.atomic():
                serializer = PurchaseSerializer(data=request.data)
                if serializer.is_valid():
                    purchase = serializer.save()
                    
                    # Apply stock increment for new creation (since removed from serializer)
                    for item in purchase.items.all():
                        try:
                            product = item.product
                            product.update_quantity(product.quantity + item.quantity)
                            # ✅ Update selling price and cost price if provided
                            if item.retail_price > 0:
                                product.price = item.retail_price
                            if item.unit_cost > 0:
                                product.cost_price = item.unit_cost
                            product.save()
                        except Exception as e:
                            print(f"Error updating stock/price on create: {e}")

                    return Response({
                        'success': True,
                        'message': 'Purchase created successfully.',
                        'data': serializer.data
                    }, status=status.HTTP_201_CREATED)
                
                return Response({
                    'success': False,
                    'message': 'Failed to create purchase.',
                    'errors': serializer.errors
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'An error occurred while creating purchase.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def purchase_detail(request, pk):
    """
    Retrieve, update or delete a specific purchase
    """
    try:
        purchase = Purchase.objects.get(pk=pk)
    except Purchase.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Purchase not found.',
            'errors': {'detail': 'Purchase with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = PurchaseSerializer(purchase)
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)

    elif request.method == 'PUT':
        try:
            with transaction.atomic():
                data = request.data

                # --- Update top-level fields ---
                vendor_id = data.get('vendor')
                if vendor_id:
                    purchase.vendor = Vendor.objects.get(pk=vendor_id)

                purchase.invoice_number = data.get('invoice_number', purchase.invoice_number)
                purchase.purchase_date = data.get('purchase_date', purchase.purchase_date)
                purchase.tax = float(data.get('tax', purchase.tax))
                purchase.status = data.get('status', purchase.status)

                # --- Record old quantities to reverse later ---
                old_items_map = {item.id: (item.product, item.quantity) for item in purchase.items.all()}

                # --- Remove old items, reverse their stock ---
                for item_id, (product, old_quantity) in old_items_map.items():
                    try:
                        # Reverse the stock: subtract old quantity from current stock
                        new_qty = max(0, product.quantity - old_quantity)
                        product.update_quantity(new_qty)
                    except Exception as e:
                        logger.error(f"Error reversing stock for product {product.id}: {e}")

                purchase.items.all().delete()

                # --- Create new items ---
                items_data = data.get('items', [])
                subtotal = 0
                for item_data in items_data:
                    product = Product.objects.get(pk=item_data['product'])
                    quantity = float(item_data.get('quantity', 0))
                    unit_cost = float(item_data.get('unit_cost', 0))
                    total_cost = round(quantity * unit_cost, 2)

                    PurchaseItem.objects.create(
                        purchase=purchase,
                        product=product,
                        quantity=quantity,
                        unit_cost=unit_cost,
                        retail_price=float(item_data.get('retail_price', 0)),
                        total_cost=total_cost,
                        description=item_data.get('description') or ''
                    )

                    try:
                        # Apply new stock: add new quantity to current stock
                        product.update_quantity(product.quantity + int(quantity))
                        # ✅ Update selling price and cost price if provided
                        new_retail = float(item_data.get('retail_price', 0))
                        if new_retail > 0:
                            product.price = new_retail
                        if unit_cost > 0:
                            product.cost_price = unit_cost
                        product.save()
                    except Exception as e:
                        logger.error(f"Error applying new stock/price for product {product.id}: {e}")

                    subtotal += total_cost

                purchase.subtotal = round(subtotal, 2)
                purchase.total = round(subtotal + purchase.tax, 2)
                purchase.save()

                # Return updated purchase using the read serializer
                serializer = PurchaseSerializer(purchase)
                return Response({
                    'success': True,
                    'message': 'Purchase updated successfully.',
                    'data': serializer.data
                }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'message': 'An error occurred while updating purchase.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    elif request.method == 'DELETE':
        try:
            with transaction.atomic():
                # --- Reverse stock before deleting ---
                for item in purchase.items.all():
                    try:
                        product = item.product
                        product.update_quantity(product.quantity - item.quantity)
                    except Exception:
                        pass
                        
                purchase.delete()
                
            return Response({
                'success': True,
                'message': 'Purchase deleted successfully.'
            }, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({
                'success': False,
                'message': 'An error occurred while deleting purchase.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
