from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.db.models import Q
from decimal import Decimal, InvalidOperation
import logging
from .models import OrderItem
from .serializers import (
    OrderItemSerializer,
    OrderItemCreateSerializer,
    OrderItemListSerializer,
    OrderItemUpdateSerializer,
    OrderItemDetailSerializer,
    OrderItemStatsSerializer,
    OrderItemBulkUpdateSerializer,
    OrderItemQuantityUpdateSerializer
)

# Set up logging
logger = logging.getLogger(__name__)


# Function-based views (following your pattern)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_order_items(request):
    """
    List all active order items with pagination, search, and filtering
    """
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Search parameters
        search = request.GET.get('search', '').strip()
        order_id = request.GET.get('order_id', '').strip()
        product_id = request.GET.get('product_id', '').strip()
        
        # Quantity range
        min_quantity = request.GET.get('min_quantity', '').strip()
        max_quantity = request.GET.get('max_quantity', '').strip()
        
        # Price range
        min_price = request.GET.get('min_price', '').strip()
        max_price = request.GET.get('max_price', '').strip()
        
        # Customization filter
        has_customization = request.GET.get('has_customization', '').strip()
        
        # Sorting
        sort_by = request.GET.get('sort_by', 'created_at')  # created_at, quantity, rate, line_total
        sort_order = request.GET.get('sort_order', 'desc')  # asc, desc
        
        # Base queryset
        if show_inactive:
            order_items = OrderItem.objects.all()
        else:
            order_items = OrderItem.active_items()
        
        # Apply search filter
        if search:
            # Use Q objects for complex search across multiple fields
            search_query = Q()
            search_query |= Q(product__name__icontains=search)  # Search in product name
            search_query |= Q(customization_notes__icontains=search)  # Search in customization notes
            search_query |= Q(id__icontains=search)  # Search in order item ID
            search_query |= Q(order__id__icontains=search)  # Search in order ID
            search_query |= Q(product__id__icontains=search)  # Search in product ID
            
            order_items = order_items.filter(search_query)
        
        # Apply order filter
        if order_id:
            order_items = order_items.filter(order_id=order_id)
        
        # Apply product filter
        if product_id:
            order_items = order_items.filter(product_id=product_id)
        
        # Apply quantity range filter
        try:
            if min_quantity:
                order_items = order_items.filter(quantity__gte=int(min_quantity))
            if max_quantity:
                order_items = order_items.filter(quantity__lte=int(max_quantity))
        except (ValueError, TypeError):
            return Response({
                'success': False,
                'message': 'Invalid quantity range values.',
                'errors': {'detail': 'Quantity values must be valid integers.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply price range filter
        try:
            if min_price:
                order_items = order_items.filter(rate__gte=Decimal(min_price))
            if max_price:
                order_items = order_items.filter(rate__lte=Decimal(max_price))
        except (InvalidOperation, ValueError):
            return Response({
                'success': False,
                'message': 'Invalid price range values.',
                'errors': {'detail': 'Price values must be valid numbers.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply customization filter
        if has_customization == 'true':
            order_items = order_items.with_customization()
        elif has_customization == 'false':
            order_items = order_items.without_customization()
        
        # Apply sorting
        sort_fields = {
            'created_at': 'created_at',
            'quantity': 'quantity',
            'rate': 'rate',
            'line_total': 'line_total',
            'product_name': 'product_name'
        }
        
        if sort_by in sort_fields:
            order_field = sort_fields[sort_by]
            if sort_order == 'desc':
                order_field = f'-{order_field}'
            order_items = order_items.order_by(order_field)
        
        # Select related to avoid N+1 queries
        order_items = order_items.select_related('order', 'product')
        
        # Calculate pagination
        total_count = order_items.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        order_items = order_items[start_index:end_index]
        
        serializer = OrderItemListSerializer(order_items, many=True)
        
        return Response({
            'success': True,
            'data': {
                'order_items': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'filters_applied': {
                    'search': search,
                    'order_id': order_id,
                    'product_id': product_id,
                    'min_quantity': min_quantity,
                    'max_quantity': max_quantity,
                    'min_price': min_price,
                    'max_price': max_price,
                    'has_customization': has_customization,
                    'sort_by': sort_by,
                    'sort_order': sort_order
                }
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError as e:
        return Response({
            'success': False,
            'message': 'Invalid pagination parameters.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve order items.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order_item(request):
    """
    Create a new order item with performance optimizations
    """
    import time
    start_time = time.time()
    
    try:
        logger.info(f"Starting order item creation for request data: {request.data}")
        
        serializer = OrderItemCreateSerializer(
            data=request.data,
            context={'request': request}
        )
        
        validation_start = time.time()
        if serializer.is_valid():
            validation_time = time.time() - validation_start
            logger.info(f"Validation completed in {validation_time:.3f}s")
            
            try:
                with transaction.atomic():
                    # Use select_related to optimize the query
                    save_start = time.time()
                    order_item = serializer.save()
                    save_time = time.time() - save_start
                    logger.info(f"Order item saved in {save_time:.3f}s")
                    
                    # Return response immediately without additional queries
                    total_time = time.time() - start_time
                    logger.info(f"Order item creation completed successfully in {total_time:.3f}s")
                    
                    return Response({
                        'success': True,
                        'message': 'Order item created successfully.',
                        'data': OrderItemDetailSerializer(order_item).data
                    }, status=status.HTTP_201_CREATED)
                    
            except Exception as e:
                total_time = time.time() - start_time
                logger.error(f"Error creating order item after {total_time:.3f}s: {str(e)}")
                return Response({
                    'success': False,
                    'message': 'Order item creation failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        else:
            validation_time = time.time() - validation_start
            total_time = time.time() - start_time
            logger.warning(f"Validation failed after {validation_time:.3f}s, total time: {total_time:.3f}s")
            logger.warning(f"Validation errors: {serializer.errors}")
            
            return Response({
                'success': False,
                'message': 'Order item creation failed.',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
    except Exception as e:
        total_time = time.time() - start_time
        logger.error(f"Unexpected error in create_order_item after {total_time:.3f}s: {str(e)}")
        return Response({
            'success': False,
            'message': 'An unexpected error occurred.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_order_item(request, order_item_id):
    """
    Retrieve a specific order item by ID
    """
    try:
        order_item = OrderItem.objects.get(id=order_item_id)
        serializer = OrderItemDetailSerializer(order_item)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Order item not found.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_order_item(request, order_item_id):
    """
    Update an order item
    """
    try:
        order_item = OrderItem.objects.get(id=order_item_id)
        
        serializer = OrderItemUpdateSerializer(
            order_item,
            data=request.data,
            partial=request.method == 'PATCH'
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    order_item = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Order item updated successfully.',
                        'data': OrderItemDetailSerializer(order_item).data
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Order item update failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Order item update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except OrderItem.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order item not found.',
            'errors': {'detail': 'Order item with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_order_item(request, order_item_id):
    """
    Hard delete an order item (permanently remove from database)
    """
    try:
        order_item = OrderItem.objects.get(id=order_item_id)
        
        # Store info for response message
        product_name = order_item.product_name
        quantity = order_item.quantity
        
        # Check if order item can be deleted (no related sales, etc.)
        if hasattr(order_item, 'has_been_sold') and order_item.has_been_sold():
            return Response({
                'success': False,
                'message': 'Cannot delete order item that has been sold.',
                'errors': {'detail': 'This order item has been converted to sales and cannot be deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Permanently delete the order item
        order_item.delete()
        
        return Response({
            'success': True,
            'message': f'Order item "{product_name} x{quantity}" deleted permanently.'
        }, status=status.HTTP_204_NO_CONTENT)
        
    except OrderItem.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order item not found.',
            'errors': {'detail': 'Order item with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Order item deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def soft_delete_order_item(request, order_item_id):
    """
    Soft delete an order item (set is_active=False)
    """
    try:
        order_item = OrderItem.objects.get(id=order_item_id)
        
        if not order_item.is_active:
            return Response({
                'success': False,
                'message': 'Order item is already inactive.',
                'errors': {'detail': 'This order item has already been soft deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        order_item.soft_delete()
        
        return Response({
            'success': True,
            'message': 'Order item soft deleted successfully.',
            'data': OrderItemDetailSerializer(order_item).data
        }, status=status.HTTP_200_OK)
        
    except OrderItem.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order item not found.',
            'errors': {'detail': 'Order item with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Order item soft deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def restore_order_item(request, order_item_id):
    """
    Restore a soft-deleted order item (set is_active=True)
    """
    try:
        order_item = OrderItem.objects.get(id=order_item_id)
        
        if order_item.is_active:
            return Response({
                'success': False,
                'message': 'Order item is already active.',
                'errors': {'detail': 'This order item is not deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        order_item.restore()
        
        return Response({
            'success': True,
            'message': 'Order item restored successfully.',
            'data': OrderItemDetailSerializer(order_item).data
        }, status=status.HTTP_200_OK)
        
    except OrderItem.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order item not found.',
            'errors': {'detail': 'Order item with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Order item restoration failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_order_items(request):
    """
    Search order items by product name, customization notes, etc.
    """
    try:
        query = request.GET.get('q', '').strip()
        if not query:
            return Response({
                'success': False,
                'message': 'Search query is required.',
                'errors': {'detail': 'Please provide a search query parameter "q".'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Search order items
        order_items = OrderItem.active_items().filter(
            Q(product_name__icontains=query) |
            Q(customization_notes__icontains=query) |
            Q(product__name__icontains=query) |
            Q(product__color__icontains=query) |
            Q(product__fabric__icontains=query)
        )
        order_items = order_items.select_related('order', 'product')
        
        # Calculate pagination
        total_count = order_items.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        order_items = order_items[start_index:end_index]
        
        serializer = OrderItemListSerializer(order_items, many=True)
        
        return Response({
            'success': True,
            'data': {
                'order_items': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'search_query': query
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid pagination parameters.',
            'errors': {'detail': 'Page and page_size must be valid integers.'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Search failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def order_items_by_order(request, order_id):
    """
    Get order items by order
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get order items by order
        order_items = OrderItem.items_by_order(order_id)
        order_items = order_items.select_related('product')
        
        # Calculate pagination
        total_count = order_items.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        order_items = order_items[start_index:end_index]
        
        serializer = OrderItemListSerializer(order_items, many=True)
        
        return Response({
            'success': True,
            'data': {
                'order_items': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'order_id': order_id
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid pagination parameters.',
            'errors': {'detail': 'Page and page_size must be valid integers.'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve order items by order.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def order_items_by_product(request, product_id):
    """
    Get order items by product
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get order items by product
        order_items = OrderItem.items_by_product(product_id)
        order_items = order_items.select_related('order')
        
        # Calculate pagination
        total_count = order_items.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        order_items = order_items[start_index:end_index]
        
        serializer = OrderItemListSerializer(order_items, many=True)
        
        return Response({
            'success': True,
            'data': {
                'order_items': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'product_id': product_id
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid pagination parameters.',
            'errors': {'detail': 'Page and page_size must be valid integers.'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve order items by product.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def order_item_statistics(request):
    """
    Get comprehensive order item statistics
    """
    try:
        stats = OrderItem.get_statistics()
        serializer = OrderItemStatsSerializer(stats)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve order item statistics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_order_item_quantity(request, order_item_id):
    """
    Update order item quantity
    """
    try:
        order_item = OrderItem.objects.get(id=order_item_id)
        
        serializer = OrderItemQuantityUpdateSerializer(data=request.data)
        
        if serializer.is_valid():
            new_quantity = serializer.validated_data['quantity']
            
            # Check stock availability
            if order_item.product:
                current_quantity = order_item.quantity
                quantity_difference = new_quantity - current_quantity
                
                if quantity_difference > 0:  # Increasing quantity
                    available_stock = order_item.product.quantity
                    if available_stock < quantity_difference:
                        return Response({
                            'success': False,
                            'message': 'Not enough stock available.',
                            'errors': {
                                'detail': f'Available: {available_stock}, Additional needed: {quantity_difference}'
                            }
                        }, status=status.HTTP_400_BAD_REQUEST)
            
            # Update quantity
            update_result = order_item.update_quantity(new_quantity)
            
            return Response({
                'success': True,
                'message': 'Order item quantity updated successfully.',
                'data': {
                    'order_item_id': str(order_item.id),
                    'product_name': order_item.product_name,
                    'old_quantity': update_result['old_quantity'],
                    'new_quantity': update_result['new_quantity'],
                    'difference': update_result['difference'],
                    'new_line_total': order_item.line_total
                }
            }, status=status.HTTP_200_OK)
        
        return Response({
            'success': False,
            'message': 'Invalid quantity.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except OrderItem.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order item not found.',
            'errors': {'detail': 'Order item with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Quantity update failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_update_order_items(request):
    """
    Bulk update order items
    """
    serializer = OrderItemBulkUpdateSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                updates = serializer.validated_data['updates']
                results = []
                
                for update in updates:
                    order_item_id = update['order_item_id']
                    fields = update['fields']
                    
                    order_item = OrderItem.objects.get(id=order_item_id)
                    
                    # Update fields
                    for field, value in fields.items():
                        if field == 'quantity':
                            update_result = order_item.update_quantity(value)
                            results.append({
                                'order_item_id': order_item_id,
                                'field': field,
                                'old_value': update_result['old_quantity'],
                                'new_value': update_result['new_quantity']
                            })
                        elif field == 'rate':
                            update_result = order_item.update_rate(value)
                            results.append({
                                'order_item_id': order_item_id,
                                'field': field,
                                'old_value': float(update_result['old_price']),
                                'new_value': float(update_result['new_price'])
                            })
                        else:  # customization_notes
                            setattr(order_item, field, value)
                            order_item.save(update_fields=[field, 'updated_at'])
                            results.append({
                                'order_item_id': order_item_id,
                                'field': field,
                                'new_value': value
                            })
                
                return Response({
                    'success': True,
                    'message': f'Successfully updated {len(results)} order item fields.',
                    'data': {
                        'updated_fields': results,
                        'total_updates': len(results)
                    }
                }, status=status.HTTP_200_OK)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Bulk update failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Bulk update failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def items_with_customization(request):
    """
    Get order items that have customization notes
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get items with customization
        order_items = OrderItem.active_items().with_customization()
        order_items = order_items.select_related('order', 'product')
        
        # Calculate pagination
        total_count = order_items.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        order_items = order_items[start_index:end_index]
        
        serializer = OrderItemListSerializer(order_items, many=True)
        
        return Response({
            'success': True,
            'data': {
                'order_items': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'message': f'{total_count} order items with customization notes'
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid pagination parameters.',
            'errors': {'detail': 'Page and page_size must be valid integers.'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve customized order items.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def duplicate_order_item(request, order_item_id):
    """
    Duplicate an existing order item (for adding to different order)
    """
    try:
        original_item = get_object_or_404(OrderItem, id=order_item_id)
        
        # Get target order from request data
        target_order_id = request.data.get('order_id')
        if not target_order_id:
            return Response({
                'success': False,
                'message': 'Target order ID is required.',
                'errors': {'detail': 'Please provide order_id in request body.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate target order exists
        from orders.models import Order
        try:
            target_order = Order.objects.get(id=target_order_id, is_active=True)
        except Order.DoesNotExist:
            return Response({
                'success': False,
                'message': 'Target order not found.',
                'errors': {'detail': 'Target order does not exist or is inactive.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if product already exists in target order
        if OrderItem.objects.filter(
            order=target_order, 
            product=original_item.product, 
            is_active=True
        ).exists():
            return Response({
                'success': False,
                'message': 'Product already exists in target order.',
                'errors': {'detail': 'This product is already in the target order.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create duplicate
        with transaction.atomic():
            duplicate_data = {
                'order': target_order,
                'product': original_item.product,
                'product_name': original_item.product_name,
                'quantity': original_item.quantity,
                'unit_price': original_item.unit_price,
                'customization_notes': original_item.customization_notes,
                'line_total': original_item.line_total
            }
            
            duplicate_item = OrderItem.objects.create(**duplicate_data)
            
            return Response({
                'success': True,
                'message': 'Order item duplicated successfully.',
                'data': OrderItemDetailSerializer(duplicate_item).data
            }, status=status.HTTP_201_CREATED)
            
    except OrderItem.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order item not found.',
            'errors': {'detail': 'Order item with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Order item duplication failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)