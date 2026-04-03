from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from sales.models import SaleItem
from .serializers import SaleItemSerializer, SaleItemListSerializer, SaleItemCreateSerializer, SaleItemUpdateSerializer


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_sale_items(request):
    """List sale items with filtering"""
    try:
        sale_id = request.GET.get('sale_id', '').strip()
        product_id = request.GET.get('product_id', '').strip()
        
        sale_items = SaleItem.objects.active()
        
        if sale_id:
            sale_items = sale_items.by_sale(sale_id)
        
        if product_id:
            sale_items = sale_items.by_product(product_id)
        
        serializer = SaleItemListSerializer(sale_items, many=True)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to list sale items.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_sale_item(request, item_id):
    """Get sale item details"""
    try:
        sale_item = get_object_or_404(SaleItem, id=item_id, is_active=True)
        serializer = SaleItemSerializer(sale_item)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except SaleItem.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Sale item not found.'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve sale item.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_sale_item(request):
    """Create a new sale item"""
    
    serializer = SaleItemCreateSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            sale_item = serializer.save()
            
            # Recalculate sale totals
            sale_item.sale.recalculate_totals()
            
            return Response({
                'success': True,
                'message': 'Sale item created successfully.',
                'data': SaleItemSerializer(sale_item).data
            }, status=status.HTTP_201_CREATED)
            
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to create sale item.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Sale item creation failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_sale_item(request, item_id):
    """Update sale item"""
    
    try:
        sale_item = get_object_or_404(SaleItem, id=item_id, is_active=True)
        
        if request.method == 'PUT':
            serializer = SaleItemUpdateSerializer(sale_item, data=request.data)
        else:
            serializer = SaleItemUpdateSerializer(sale_item, data=request.data, partial=True)
        
        if serializer.is_valid():
            updated_item = serializer.save()
            
            # Recalculate sale totals
            updated_item.sale.recalculate_totals()
            
            return Response({
                'success': True,
                'message': 'Sale item updated successfully.',
                'data': SaleItemSerializer(updated_item).data
            }, status=status.HTTP_200_OK)
        
        return Response({
            'success': False,
            'message': 'Sale item update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except SaleItem.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Sale item not found.'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to update sale item.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_sale_item(request, item_id):
    """Delete sale item"""
    try:
        sale_item = get_object_or_404(SaleItem, id=item_id, is_active=True)
        
        sale_item.is_active = False
        sale_item.save()
        
        # Recalculate sale totals
        sale_item.sale.recalculate_totals()
        
        return Response({
            'success': True,
            'message': 'Sale item deleted successfully.'
        }, status=status.HTTP_200_OK)
        
    except SaleItem.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Sale item not found.'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to delete sale item.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
