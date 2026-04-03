from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.db.models import Q, ProtectedError
from decimal import Decimal, InvalidOperation
from .models import Product
from .serializers import (
    ProductSerializer,
    ProductCreateSerializer,
    ProductListSerializer,
    ProductUpdateSerializer,
    ProductDetailSerializer,
    ProductStatsSerializer,
    BulkQuantityUpdateSerializer
)


# Function-based views (following your Category module pattern)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_products(request):
    """
    List all active products with pagination, search, and filtering
    """
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Search parameters
        search = request.GET.get('search', '').strip()
        category_id = request.GET.get('category_id', '').strip()
        color = request.GET.get('color', '').strip()
        fabric = request.GET.get('fabric', '').strip()
        stock_level = request.GET.get('stock_level', '').strip()
        
        # Product Type Filters
        is_rental = request.GET.get('is_rental', '').strip().lower()
        is_consumable = request.GET.get('is_consumable', '').strip().lower()
        
        # Price range
        min_price = request.GET.get('min_price', '').strip()
        max_price = request.GET.get('max_price', '').strip()
        
        # Sorting
        sort_by = request.GET.get('sort_by', 'name')  # name, price, quantity, created_at
        sort_order = request.GET.get('sort_order', 'asc')  # asc, desc
        
        # Availability dates
        # Default to today if not provided to ensure real-time availability display
        from django.utils import timezone
        today = timezone.now().date().isoformat()
        start_date_avail = request.GET.get('start_date', today)
        end_date_avail = request.GET.get('end_date', today)
        
        # Base queryset
        if show_inactive:
            products = Product.objects.all()
        else:
            products = Product.active_products()
        
        # Apply search filter
        if search:
            products = products.search(search)
        
        # Apply category filter
        if category_id:
            products = products.filter(category_id=category_id)
        
        # Apply color filter
        if color:
            products = products.filter(color__icontains=color)
        
        # Apply fabric filter
        if fabric:
            products = products.filter(fabric__icontains=fabric)
            
        # Apply type filters
        if is_rental == 'true':
            products = products.filter(is_rental=True)
        elif is_rental == 'false':
            products = products.filter(is_rental=False)
            
        if is_consumable == 'true':
            products = products.filter(is_consumable=True)
        elif is_consumable == 'false':
            products = products.filter(is_consumable=False)
        
        # Apply price range filter
        try:
            if min_price:
                products = products.filter(price__gte=Decimal(min_price))
            if max_price:
                products = products.filter(price__lte=Decimal(max_price))
        except (InvalidOperation, ValueError):
            return Response({
                'success': False,
                'message': 'Invalid price range values.',
                'errors': {'detail': 'Price values must be valid numbers.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply stock level filter
        if stock_level:
            products = products.stock_level(stock_level.upper())
        
        # Apply sorting
        sort_fields = {
            'name': 'name',
            'price': 'price',
            'quantity': 'quantity',
            'created_at': 'created_at',
            'updated_at': 'updated_at'
        }
        
        if sort_by in sort_fields:
            order_field = sort_fields[sort_by]
            if sort_order == 'desc':
                order_field = f'-{order_field}'
            products = products.order_by(order_field)
        
        # Select related to avoid N+1 queries
        products = products.select_related('category', 'created_by')
        
        # Calculate pagination
        total_count = products.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        products = products[start_index:end_index]
        
        # Context for availability calculation
        serializer_context = {
            'request': request,
            'start_date': start_date_avail,
            'end_date': end_date_avail
        }
        
        serializer = ProductListSerializer(products, many=True, context=serializer_context)
        
        return Response({
            'success': True,
            'data': {
                'products': serializer.data,
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
                    'category_id': category_id,
                    'color': color,
                    'fabric': fabric,
                    'stock_level': stock_level,
                    'min_price': min_price,
                    'max_price': max_price,
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
            'message': 'Failed to retrieve products.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_product(request):
    """
    Create a new product
    """
    serializer = ProductCreateSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                product = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Product created successfully.',
                    'data': ProductDetailSerializer(product).data
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Product creation failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Product creation failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_product(request, product_id):
    """
    Retrieve a specific product by ID
    """
    try:
        product = Product.objects.get(id=product_id)
        serializer = ProductDetailSerializer(product)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': 'Product with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_product(request, product_id):
    """
    Update a product
    """
    try:
        product = Product.objects.get(id=product_id)
        
        serializer = ProductUpdateSerializer(
            product,
            data=request.data,
            partial=request.method == 'PATCH'
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    product = serializer.save()
                    # Recalculate available quantity after save
                    # This fixes the "Out of Stock" bug on product edit
                    product.update_available_quantity()
                    product.refresh_from_db()
                    
                    return Response({
                        'success': True,
                        'message': 'Product updated successfully.',
                        'data': ProductDetailSerializer(product).data
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Product update failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Product update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': 'Product with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_product(request, product_id):
    """
    Hard delete a product (permanently remove from database)
    """
    try:
        product = Product.objects.get(id=product_id)
        
        # Store product name for response message
        product_name = product.name
        
        # Check if product is being used in sales (optional safety check)
        # Uncomment this if you have a Sales model that references products
        # if hasattr(product, 'sale_items') and product.sale_items.exists():
        #     return Response({
        #         'success': False,
        #         'message': 'Cannot delete product as it is being used in sales.',
        #         'errors': {'detail': 'This product is currently part of one or more sales.'}
        #     }, status=status.HTTP_400_BAD_REQUEST)
        
        # Permanently delete the product
        product.delete()
        
        return Response({
            'success': True,
            'message': f'Product "{product_name}" deleted permanently.'
        }, status=status.HTTP_200_OK)
        
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': 'Product with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except ProtectedError:
        # Instead of failing, soft delete the product so it doesn't break history
        product.is_active = False
        product.save(update_fields=['is_active'])
        return Response({
            'success': True,
            'message': f'Product "{product_name}" is used in orders. It has been deactivated instead of permanently deleted.'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Product deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def soft_delete_product(request, product_id):
    """
    Soft delete a product (set is_active=False)
    """
    try:
        product = Product.objects.get(id=product_id)
        
        if not product.is_active:
            return Response({
                'success': False,
                'message': 'Product is already inactive.',
                'errors': {'detail': 'This product has already been soft deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        product.soft_delete()
        
        return Response({
            'success': True,
            'message': 'Product soft deleted successfully.'
        }, status=status.HTTP_200_OK)
        
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': 'Product with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Product soft deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def restore_product(request, product_id):
    """
    Restore a soft-deleted product (set is_active=True)
    """
    try:
        product = Product.objects.get(id=product_id)
        
        if product.is_active:
            return Response({
                'success': False,
                'message': 'Product is already active.',
                'errors': {'detail': 'This product is not deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        product.restore()
        
        return Response({
            'success': True,
            'message': 'Product restored successfully.',
            'data': ProductDetailSerializer(product).data
        }, status=status.HTTP_200_OK)
        
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': 'Product with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Product restoration failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_products(request):
    """
    Search products by name, color, fabric, or category
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
        
        # Search products
        products = Product.active_products().search(query)
        products = products.select_related('category', 'created_by')
        
        # Calculate pagination
        total_count = products.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        products = products[start_index:end_index]
        
        serializer = ProductListSerializer(products, many=True)
        
        return Response({
            'success': True,
            'data': {
                'products': serializer.data,
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
def products_by_category(request, category_id):
    """
    Get products by category
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get products by category
        products = Product.products_by_category(category_id)
        products = products.select_related('category', 'created_by')
        
        # Calculate pagination
        total_count = products.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        products = products[start_index:end_index]
        
        serializer = ProductListSerializer(products, many=True)
        
        return Response({
            'success': True,
            'data': {
                'products': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'category_id': category_id
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
            'message': 'Failed to retrieve products by category.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def low_stock_products(request):
    """
    Get products with low stock
    """
    try:
        threshold = int(request.GET.get('threshold', 5))
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get low stock products
        products = Product.low_stock_products(threshold=threshold)
        products = products.select_related('category', 'created_by')
        
        # Calculate pagination
        total_count = products.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        products = products[start_index:end_index]
        
        serializer = ProductListSerializer(products, many=True)
        
        return Response({
            'success': True,
            'data': {
                'products': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'threshold': threshold,
                'alert_message': f'{total_count} products with stock level ≤ {threshold}'
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid parameters.',
            'errors': {'detail': 'Threshold, page, and page_size must be valid integers.'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve low stock products.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def product_statistics(request):
    """
    Get comprehensive product statistics
    """
    try:
        stats = Product.get_statistics()
        serializer = ProductStatsSerializer(stats)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve product statistics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_product_quantity(request, product_id):
    """
    Update product quantity
    """
    try:
        product = Product.objects.get(id=product_id)
        
        new_quantity = request.data.get('quantity')
        if new_quantity is None:
            return Response({
                'success': False,
                'message': 'Quantity is required.',
                'errors': {'detail': 'Please provide quantity in request body.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            new_quantity = int(new_quantity)
            if new_quantity < 0:
                raise ValueError("Quantity cannot be negative")
        except (ValueError, TypeError):
            return Response({
                'success': False,
                'message': 'Invalid quantity value.',
                'errors': {'detail': 'Quantity must be a non-negative integer.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Update quantity
        update_result = product.update_quantity(new_quantity, user=request.user)
        
        return Response({
            'success': True,
            'message': 'Product quantity updated successfully.',
            'data': {
                'product_id': str(product.id),
                'product_name': product.name,
                'old_quantity': update_result['old_quantity'],
                'new_quantity': update_result['new_quantity'],
                'difference': update_result['difference'],
                'stock_status': product.stock_status,
                'stock_status_display': product.stock_status_display
            }
        }, status=status.HTTP_200_OK)
        
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': 'Product with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Quantity update failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_update_quantities(request):
    """
    Bulk update product quantities
    """
    serializer = BulkQuantityUpdateSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                updates = serializer.validated_data['updates']
                results = []
                
                for update in updates:
                    product_id = update['product_id']
                    new_quantity = update['quantity']
                    
                    product = Product.objects.get(id=product_id)
                    update_result = product.update_quantity(new_quantity, user=request.user)
                    
                    results.append({
                        'product_id': product_id,
                        'product_name': product.name,
                        'old_quantity': update_result['old_quantity'],
                        'new_quantity': update_result['new_quantity'],
                        'difference': update_result['difference'],
                        'stock_status': product.stock_status
                    })
                
                return Response({
                    'success': True,
                    'message': f'Successfully updated {len(results)} products.',
                    'data': {
                        'updated_products': results,
                        'total_updated': len(results)
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


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def duplicate_product(request, product_id):
    """
    Duplicate an existing product
    """
    try:
        original_product = Product.objects.get(id=product_id)
        
        # Get new name from request data or auto-generate
        new_name = request.data.get('name', f"{original_product.name} (Copy)")
        
        # Create duplicate
        with transaction.atomic():
            duplicate_data = {
                'name': new_name,
                'detail': original_product.detail,
                'price': original_product.price,
                'color': original_product.color,
                'fabric': original_product.fabric,
                'pieces': original_product.pieces.copy(),
                'quantity': 0,  # Start with 0 quantity for duplicate
                'category': original_product.category,
                'created_by': request.user
            }
            
            duplicate_product = Product.objects.create(**duplicate_data)
            
            return Response({
                'success': True,
                'message': 'Product duplicated successfully.',
                'data': ProductDetailSerializer(duplicate_product).data
            }, status=status.HTTP_201_CREATED)
            
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found.',
            'errors': {'detail': 'Product with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Product duplication failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def check_stock_availability(request):
    """Check real-time stock availability for products"""
    try:
        product_ids = request.GET.getlist('product_ids[]')
        if not product_ids:
            return Response({
                'success': False,
                'message': 'Product IDs are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        products = Product.objects.filter(id__in=product_ids, is_active=True)
        stock_info = []
        
        for product in products:
            stock_info.append({
                'product_id': str(product.id),
                'product_name': product.name,
                'available_quantity': product.quantity,
                'stock_status': product.stock_status,
                'stock_status_display': product.stock_status_display,
                'can_fulfill': product.quantity > 0,
                'low_stock_warning': product.quantity <= 5,
                'out_of_stock': product.quantity == 0,
                'last_updated': product.updated_at.isoformat()
            })
        
        return Response({
            'success': True,
            'data': stock_info,
            'message': 'Stock availability checked successfully'
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error checking stock availability: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def check_date_availability(request):
    """
    Check product availability for a specific date range.
    Used during order creation to verify products are available for the event dates.
    """
    try:
        from datetime import datetime
        
        product_ids = request.data.get('product_ids', [])
        start_date_str = request.data.get('start_date')
        end_date_str = request.data.get('end_date')
        exclude_order_id = request.data.get('exclude_order_id')
        
        if not product_ids or not start_date_str or not end_date_str:
            return Response({
                'success': False,
                'message': 'product_ids, start_date, and end_date are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        start_date = datetime.strptime(start_date_str, '%Y-%m-%d').date()
        end_date = datetime.strptime(end_date_str, '%Y-%m-%d').date()
        
        if start_date > end_date:
            return Response({
                'success': False,
                'message': 'start_date must be before or equal to end_date'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        products = Product.objects.filter(id__in=product_ids, is_active=True)
        availability = []
        
        for product in products:
            available_qty = product.get_available_quantity_for_dates(
                start_date, end_date, exclude_order_id=exclude_order_id
            )
            availability.append({
                'product_id': str(product.id),
                'product_name': product.name,
                'total_quantity': product.quantity,
                'available_quantity': available_qty,
                'is_rental': product.is_rental,
                'is_available': available_qty > 0,
                'start_date': start_date_str,
                'end_date': end_date_str,
            })
        
        all_available = all(item['is_available'] for item in availability)
        
        return Response({
            'success': True,
            'data': {
                'availability': availability,
                'all_available': all_available,
                'start_date': start_date_str,
                'end_date': end_date_str,
            },
            'message': 'Date availability checked successfully'
        })
        
    except ValueError as e:
        return Response({
            'success': False,
            'message': f'Invalid date format. Use YYYY-MM-DD: {str(e)}'
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error checking date availability: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def reserve_stock_for_sale(request):
    """Reserve stock for a pending sale (temporary hold)"""
    try:
        product_id = request.data.get('product_id')
        quantity = request.data.get('quantity')
        sale_id = request.data.get('sale_id')
        reservation_duration = request.data.get('reservation_duration', 30)  # minutes
        
        if not all([product_id, quantity, sale_id]):
            return Response({
                'success': False,
                'message': 'Product ID, quantity, and sale ID are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            product = Product.objects.get(id=product_id, is_active=True)
        except Product.DoesNotExist:
            return Response({
                'success': False,
                'message': 'Product not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        if product.quantity < quantity:
            return Response({
                'success': False,
                'message': f'Insufficient stock. Available: {product.quantity}, Requested: {quantity}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create stock reservation
        from django.utils import timezone
        from datetime import timedelta
        
        reservation = StockReservation.objects.create(
            product=product,
            sale_id=sale_id,
            quantity_reserved=quantity,
            reserved_until=timezone.now() + timedelta(minutes=reservation_duration),
            reserved_by=request.user
        )
        
        # Update product available quantity (reserved stock is not available for other sales)
        product.quantity_available = product.quantity - product.get_reserved_quantity()
        product.save(update_fields=['quantity_available'])
        
        return Response({
            'success': True,
            'data': {
                'reservation_id': str(reservation.id),
                'product_id': str(product.id),
                'quantity_reserved': quantity,
                'reserved_until': reservation.reserved_until.isoformat(),
                'available_quantity': product.quantity_available
            },
            'message': 'Stock reserved successfully'
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error reserving stock: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def confirm_stock_deduction(request):
    """Confirm stock deduction after sale is confirmed"""
    try:
        sale_id = request.data.get('sale_id')
        if not sale_id:
            return Response({
                'success': False,
                'message': 'Sale ID is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get all stock reservations for this sale
        reservations = StockReservation.objects.filter(
            sale_id=sale_id,
            is_active=True
        )
        
        if not reservations.exists():
            return Response({
                'success': False,
                'message': 'No stock reservations found for this sale'
            }, status=status.HTTP_404_NOT_FOUND)
        
        deduction_results = []
        
        for reservation in reservations:
            product = reservation.product
            
            # Deduct stock
            old_quantity = product.quantity
            new_quantity = old_quantity - reservation.quantity_reserved
            
            if new_quantity < 0:
                return Response({
                    'success': False,
                    'message': f'Insufficient stock for product {product.name}'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Update product quantity
            product.quantity = new_quantity
            product.save(update_fields=['quantity', 'updated_at'])
            
            # Mark reservation as confirmed
            reservation.is_confirmed = True
            reservation.confirmed_at = timezone.now()
            reservation.save(update_fields=['is_confirmed', 'confirmed_at'])
            
            deduction_results.append({
                'product_id': str(product.id),
                'product_name': product.name,
                'quantity_deducted': reservation.quantity_reserved,
                'old_quantity': old_quantity,
                'new_quantity': new_quantity,
                'stock_status': product.stock_status,
                'low_stock_warning': product.quantity <= 5
            })
        
        return Response({
            'success': True,
            'data': {
                'sale_id': sale_id,
                'deductions': deduction_results,
                'total_products_updated': len(deduction_results)
            },
            'message': 'Stock deduction confirmed successfully'
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error confirming stock deduction: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_low_stock_alerts(request):
    """Get low stock alerts for products"""
    try:
        threshold = int(request.GET.get('threshold', 5))
        include_out_of_stock = request.GET.get('include_out_of_stock', 'true').lower() == 'true'
        
        query = Product.objects.filter(is_active=True)
        
        if include_out_of_stock:
            query = query.filter(quantity__lte=threshold)
        else:
            query = query.filter(quantity__gt=0, quantity__lte=threshold)
        
        products = query.select_related('category').order_by('quantity', 'name')
        
        alerts = []
        for product in products:
            alerts.append({
                'product_id': str(product.id),
                'product_name': product.name,
                'category_name': product.category.name if product.category else 'Uncategorized',
                'current_quantity': product.quantity,
                'stock_status': product.stock_status,
                'stock_status_display': product.stock_status_display,
                'last_updated': product.updated_at.isoformat(),
                'alert_level': 'CRITICAL' if product.quantity == 0 else 'WARNING',
                'days_since_update': (timezone.now() - product.updated_at).days
            })
        
        return Response({
            'success': True,
            'data': {
                'alerts': alerts,
                'total_alerts': len(alerts),
                'threshold': threshold,
                'critical_count': len([a for a in alerts if a['alert_level'] == 'CRITICAL']),
                'warning_count': len([a for a in alerts if a['alert_level'] == 'WARNING'])
            },
            'message': 'Low stock alerts retrieved successfully'
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error getting low stock alerts: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_update_stock(request):
    """Bulk update stock quantities for multiple products"""
    try:
        updates = request.data.get('updates', [])
        if not updates:
            return Response({
                'success': False,
                'message': 'Updates array is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        results = []
        errors = []
        
        for update in updates:
            try:
                product_id = update.get('product_id')
                new_quantity = update.get('quantity')
                reason = update.get('reason', 'Bulk update')
                
                if not all([product_id, new_quantity is not None]):
                    errors.append({
                        'product_id': product_id,
                        'error': 'Product ID and quantity are required'
                    })
                    continue
                
                try:
                    product = Product.objects.get(id=product_id, is_active=True)
                except Product.DoesNotExist:
                    errors.append({
                        'product_id': product_id,
                        'error': 'Product not found'
                    })
                    continue
                
                old_quantity = product.quantity
                product.quantity = new_quantity
                product.save(update_fields=['quantity', 'updated_at'])
                
                # Log stock change
                StockChangeLog.objects.create(
                    product=product,
                    old_quantity=old_quantity,
                    new_quantity=new_quantity,
                    change_type='BULK_UPDATE',
                    reason=reason,
                    changed_by=request.user
                )
                
                results.append({
                    'product_id': str(product.id),
                    'product_name': product.name,
                    'old_quantity': old_quantity,
                    'new_quantity': new_quantity,
                    'stock_status': product.stock_status,
                    'low_stock_warning': product.quantity <= 5
                })
                
            except Exception as e:
                errors.append({
                    'product_id': update.get('product_id'),
                    'error': str(e)
                })
        
        return Response({
            'success': True,
            'data': {
                'successful_updates': results,
                'errors': errors,
                'total_processed': len(updates),
                'successful_count': len(results),
                'error_count': len(errors)
            },
            'message': f'Bulk stock update completed. {len(results)} successful, {len(errors)} errors'
        })
        
    except Exception as e:
        return Response({
            'success': False,
            'message': f'Error performing bulk stock update: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_by_barcode(request, barcode):
    """Search product by barcode"""
    try:
        product = Product.objects.get(barcode=barcode, is_active=True)
        serializer = ProductSerializer(product)
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
    except Product.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Product not found with the provided barcode'
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to search product by barcode',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def generate_barcode_image(request, product_id):
    """Generate barcode image (EAN-13 format)"""
    try:
        product = Product.objects.get(id=product_id, is_active=True)
        
        if not product.barcode:
            return Response({
                'success': False,
                'message': 'Product does not have a barcode'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Generate barcode image
        try:
            import barcode
            from barcode.writer import ImageWriter
            from io import BytesIO
            import base64
            
            # Use EAN13 format
            ean = barcode.get('ean13', product.barcode, writer=ImageWriter())
            buffer = BytesIO()
            ean.write(buffer)
            
            # Convert to base64
            img_str = base64.b64encode(buffer.getvalue()).decode()
            
            return Response({
                'success': True,
                'data': {
                    'barcode': product.barcode,
                    'sku': product.sku,
                    'product_name': product.name,
                    'image': f'data:image/png;base64,{img_str}'
                }
            }, status=status.HTTP_200_OK)
        except ImportError:
            return Response({
                'success': False,
                'message': 'python-barcode package is not installed. Please install it using: pip install python-barcode[images]'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Product.DoesNotExist:
            return Response({
                'success': False,
                'message': 'Product not found.',
                'errors': {'detail': 'Product with this ID does not exist.'}
            }, status=status.HTTP_404_NOT_FOUND)

        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to generate barcode image',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to generate barcode image',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        