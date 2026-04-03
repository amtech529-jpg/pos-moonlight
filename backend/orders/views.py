from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.db.models import Q
from decimal import Decimal, InvalidOperation
from datetime import datetime, date
from .models import Order
from .serializers import (
    OrderSerializer,
    OrderCreateSerializer,
    OrderListSerializer,
    OrderUpdateSerializer,
    OrderDetailSerializer,
    OrderStatsSerializer,
    OrderPaymentSerializer,
    OrderStatusUpdateSerializer,
    OrderBulkActionSerializer,
    OrderSearchSerializer,
    OrderCustomerUpdateSerializer
)


# Function-based views (following your pattern)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_orders(request):
    """
    List all active orders with pagination, search, and filtering
    """
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Search parameters
        search = request.GET.get('search', '').strip()
        customer_id = request.GET.get('customer_id', '').strip()
        status_filter = request.GET.get('status', '').strip()
        payment_status = request.GET.get('payment_status', '').strip()
        delivery_status = request.GET.get('delivery_status', '').strip()
        
        # Date range
        date_from = request.GET.get('date_from', '').strip()
        date_to = request.GET.get('date_to', '').strip()
        
        # Value range
        min_value = request.GET.get('min_value', '').strip()
        max_value = request.GET.get('max_value', '').strip()
        
        # Sorting
        sort_by = request.GET.get('sort_by', 'date_ordered')  # date_ordered, total_amount, created_at
        sort_order = request.GET.get('sort_order', 'desc')  # asc, desc
        
        # Base queryset
        if show_inactive:
            orders = Order.objects.all()
        else:
            orders = Order.active_orders()
        
        # Apply search filter
        if search:
            orders = orders.filter(
                Q(customer_name__icontains=search) |
                Q(customer_phone__icontains=search) |
                Q(customer_email__icontains=search) |
                Q(description__icontains=search) |
                Q(id__icontains=search)
            )
        
        # Apply customer filter
        if customer_id:
            orders = orders.filter(customer_id=customer_id)
        
        # Apply status filter
        if status_filter:
            orders = orders.filter(status=status_filter.upper())
        
        # Apply payment status filter
        if payment_status == 'paid':
            orders = orders.filter(is_fully_paid=True)
        elif payment_status == 'unpaid':
            orders = orders.filter(is_fully_paid=False, total_amount__gt=0)
        elif payment_status == 'partial':
            orders = orders.filter(
                advance_payment__gt=0,
                is_fully_paid=False,
                total_amount__gt=0
            )
        
        # Apply delivery status filter
        if delivery_status == 'overdue':
            orders = orders.overdue()
        elif delivery_status == 'due_today':
            orders = orders.due_today()
        elif delivery_status == 'upcoming':
            orders = orders.due_this_week()
        
        # Apply date range filter
        try:
            if date_from:
                date_from_obj = datetime.strptime(date_from, '%Y-%m-%d').date()
                orders = orders.filter(date_ordered__gte=date_from_obj)
            if date_to:
                date_to_obj = datetime.strptime(date_to, '%Y-%m-%d').date()
                orders = orders.filter(date_ordered__lte=date_to_obj)
        except ValueError:
            return Response({
                'success': False,
                'message': 'Invalid date format. Use YYYY-MM-DD.',
                'errors': {'detail': 'Date values must be in YYYY-MM-DD format.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply value range filter
        try:
            if min_value:
                orders = orders.filter(total_amount__gte=Decimal(min_value))
            if max_value:
                orders = orders.filter(total_amount__lte=Decimal(max_value))
        except (InvalidOperation, ValueError):
            return Response({
                'success': False,
                'message': 'Invalid value range.',
                'errors': {'detail': 'Value parameters must be valid numbers.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply sorting
        sort_fields = {
            'date_ordered': 'date_ordered',
            'total_amount': 'total_amount',
            'created_at': 'created_at',
            'customer_name': 'customer_name',
            'status': 'status',
            'expected_delivery_date': 'expected_delivery_date'
        }
        
        if sort_by in sort_fields:
            order_field = sort_fields[sort_by]
            if sort_order == 'desc':
                order_field = f'-{order_field}'
            orders = orders.order_by(order_field)
        
        # Select related to avoid N+1 queries
        orders = orders.select_related('customer', 'created_by')
        
        # Calculate pagination
        total_count = orders.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        orders = orders[start_index:end_index]
        
        serializer = OrderListSerializer(orders, many=True)
        
        return Response({
            'success': True,
            'data': {
                'orders': serializer.data,
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
                    'customer_id': customer_id,
                    'status': status_filter,
                    'payment_status': payment_status,
                    'delivery_status': delivery_status,
                    'date_from': date_from,
                    'date_to': date_to,
                    'min_value': min_value,
                    'max_value': max_value,
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
            'message': 'Failed to retrieve orders.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order(request):
    """
    Create a new order
    """
    serializer = OrderCreateSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                order = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Order created successfully.',
                    'data': OrderDetailSerializer(order).data
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Order creation failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Order creation failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_order(request, order_id):
    """
    Retrieve a specific order by ID
    """
    try:
        order = Order.objects.get(id=order_id)
        serializer = OrderDetailSerializer(order)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Order not found.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_order(request, order_id):
    """
    Update an order
    """
    try:
        order = Order.objects.get(id=order_id)
        
        # Check if order can be modified
        if not order.can_be_modified():
            return Response({
                'success': False,
                'message': 'Order cannot be modified.',
                'errors': {'detail': f'Orders with status {order.get_status_display()} cannot be modified.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        serializer = OrderUpdateSerializer(
            order,
            data=request.data,
            partial=request.method == 'PATCH'
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    order = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Order updated successfully.',
                        'data': OrderDetailSerializer(order).data
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Order update failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Order update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Order.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order not found.',
            'errors': {'detail': 'Order with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_order(request, order_id):
    """
    Hard delete an order (permanently remove from database)
    """
    try:
        order = Order.objects.get(id=order_id)
        
        # Store info for response message
        customer_name = order.customer_name
        order_total = order.total_amount
        
        # Check if order has payments
        if order.advance_payment > 0:
            return Response({
                'success': False,
                'message': 'Cannot delete order with payments.',
                'errors': {'detail': f'Order has PKR {order.advance_payment} in payments. Please process refund first.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Permanently delete the order
        order.delete()
        
        return Response({
            'success': True,
            'message': f'Order for {customer_name} (PKR {order_total}) deleted permanently.'
        }, status=status.HTTP_200_OK)
        
    except Order.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order not found.',
            'errors': {'detail': 'Order with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Order deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def soft_delete_order(request, order_id):
    """
    Soft delete an order (set is_active=False)
    """
    try:
        order = Order.objects.get(id=order_id)
        
        if not order.is_active:
            return Response({
                'success': False,
                'message': 'Order is already inactive.',
                'errors': {'detail': 'This order has already been soft deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        order.soft_delete()
        
        return Response({
            'success': True,
            'message': 'Order soft deleted successfully.'
        }, status=status.HTTP_200_OK)
        
    except Order.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order not found.',
            'errors': {'detail': 'Order with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Order soft deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def restore_order(request, order_id):
    """
    Restore a soft-deleted order (set is_active=True)
    """
    try:
        order = Order.objects.get(id=order_id)
        
        if order.is_active:
            return Response({
                'success': False,
                'message': 'Order is already active.',
                'errors': {'detail': 'This order is not deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        order.restore()
        
        return Response({
            'success': True,
            'message': 'Order restored successfully.',
            'data': OrderDetailSerializer(order).data
        }, status=status.HTTP_200_OK)
        
    except Order.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order not found.',
            'errors': {'detail': 'Order with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Order restoration failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_orders(request):
    """
    Search orders by customer info, description, or order ID
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
        
        # Search orders
        orders = Order.active_orders().filter(
            Q(customer_name__icontains=query) |
            Q(customer_phone__icontains=query) |
            Q(customer_email__icontains=query) |
            Q(description__icontains=query) |
            Q(id__icontains=query)
        )
        orders = orders.select_related('customer', 'created_by')
        
        # Calculate pagination
        total_count = orders.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        orders = orders[start_index:end_index]
        
        serializer = OrderListSerializer(orders, many=True)
        
        return Response({
            'success': True,
            'data': {
                'orders': serializer.data,
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
def orders_by_status(request, status_name):
    """
    Get orders by status
    """
    try:
        # Validate status
        valid_statuses = [choice[0].lower() for choice in Order.STATUS_CHOICES]
        if status_name.lower() not in valid_statuses:
            return Response({
                'success': False,
                'message': 'Invalid status.',
                'errors': {'detail': f'Valid statuses are: {", ".join(valid_statuses)}'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get orders by status
        orders = Order.orders_by_status(status_name)
        orders = orders.select_related('customer', 'created_by')
        
        # Calculate pagination
        total_count = orders.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        orders = orders[start_index:end_index]
        
        serializer = OrderListSerializer(orders, many=True)
        
        return Response({
            'success': True,
            'data': {
                'orders': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'status': status_name.upper(),
                'status_display': dict(Order.STATUS_CHOICES)[status_name.upper()]
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
            'message': 'Failed to retrieve orders by status.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def orders_by_customer(request, customer_id):
    """
    Get orders by customer
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get orders by customer
        orders = Order.orders_by_customer(customer_id)
        orders = orders.select_related('customer', 'created_by')
        
        # Calculate pagination
        total_count = orders.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        orders = orders[start_index:end_index]
        
        serializer = OrderListSerializer(orders, many=True)
        
        return Response({
            'success': True,
            'data': {
                'orders': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'customer_id': customer_id
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
            'message': 'Failed to retrieve orders by customer.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pending_orders(request):
    """
    Get pending orders
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get pending orders
        orders = Order.pending_orders()
        orders = orders.select_related('customer', 'created_by')
        
        # Calculate pagination
        total_count = orders.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        orders = orders[start_index:end_index]
        
        serializer = OrderListSerializer(orders, many=True)
        
        return Response({
            'success': True,
            'data': {
                'orders': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'message': f'{total_count} pending orders'
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
            'message': 'Failed to retrieve pending orders.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def overdue_orders(request):
    """
    Get overdue orders
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get overdue orders
        orders = Order.overdue_orders()
        orders = orders.select_related('customer', 'created_by')
        
        # Calculate pagination
        total_count = orders.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        orders = orders[start_index:end_index]
        
        serializer = OrderListSerializer(orders, many=True)
        
        return Response({
            'success': True,
            'data': {
                'orders': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'alert_message': f'{total_count} orders are overdue for delivery'
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
            'message': 'Failed to retrieve overdue orders.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def unpaid_orders(request):
    """
    Get unpaid orders
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get unpaid orders
        orders = Order.unpaid_orders()
        orders = orders.select_related('customer', 'created_by')
        
        # Calculate pagination
        total_count = orders.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        orders = orders[start_index:end_index]
        
        serializer = OrderListSerializer(orders, many=True)
        
        return Response({
            'success': True,
            'data': {
                'orders': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'message': f'{total_count} orders with pending payments'
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
            'message': 'Failed to retrieve unpaid orders.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recent_orders(request):
    """
    Get recent orders
    """
    try:
        days = int(request.GET.get('days', 7))
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get recent orders
        orders = Order.recent_orders(days=days)
        orders = orders.select_related('customer', 'created_by')
        
        # Calculate pagination
        total_count = orders.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        orders = orders[start_index:end_index]
        
        serializer = OrderListSerializer(orders, many=True)
        
        return Response({
            'success': True,
            'data': {
                'orders': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'days': days,
                'message': f'{total_count} orders from last {days} days'
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid parameters.',
            'errors': {'detail': 'Days, page, and page_size must be valid integers.'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve recent orders.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def order_statistics(request):
    """
    Get comprehensive order statistics
    """
    try:
        stats = Order.get_statistics()
        serializer = OrderStatsSerializer(stats)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve order statistics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_payment(request, order_id):
    """
    Add payment to an order
    """
    try:
        order = get_object_or_404(Order, id=order_id)
        
        serializer = OrderPaymentSerializer(data=request.data)
        
        if serializer.is_valid():
            amount = serializer.validated_data['amount']
            notes = serializer.validated_data.get('notes', '')
            
            # Check if payment exceeds remaining amount
            if amount > order.remaining_amount:
                return Response({
                    'success': False,
                    'message': 'Payment exceeds remaining amount.',
                    'errors': {
                        'detail': f'Remaining amount: PKR {order.remaining_amount}, Payment: PKR {amount}'
                    }
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Create Payment Record
            try:
                from payments.models import Payment
                from django.utils import timezone
                
                payment_method = serializer.validated_data.get('payment_method', 'CASH')
                
                Payment.objects.create(
                    order=order,
                    amount_paid=amount,
                    date=timezone.now().date(),
                    time=timezone.now().time(),
                    payment_method=payment_method,
                    payer_type='CUSTOMER',
                    payer_id=order.customer.id if order.customer else None,
                    created_by=request.user,
                    description=f"Payment for Order #{order.id}: {notes}"
                )
            except Exception as e:
                import logging
                logger = logging.getLogger(__name__)
                logger.error(f"Failed to create payment record for order {order.id}: {str(e)}")
                
                # Fallback: manual update if payment creation failed (though signal handles it normally)
                # But if payment failed, we shouldn't update order?
                # If payment creation failed, maybe we should error out?
                return Response({
                    'success': False,
                    'message': 'Failed to record payment.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

            # Refresh order to get updated totals from signal
            order.refresh_from_db()
            
            # Add notes to description if provided
            if notes:
                order.description += f"\nPayment added: PKR {amount} - {notes}"
                order.save(update_fields=['description', 'updated_at'])
            
            return Response({
                'success': True,
                'message': 'Payment added successfully.',
                'data': {
                    'order_id': str(order.id),
                    'payment_added': float(amount),
                    'new_advance_payment': float(order.advance_payment),
                    'remaining_amount': float(order.remaining_amount),
                    'is_fully_paid': order.is_fully_paid,
                    'payment_percentage': float(order.payment_percentage)
                }
            }, status=status.HTTP_200_OK)
        
        return Response({
            'success': False,
            'message': 'Invalid payment data.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Order.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order not found.',
            'errors': {'detail': 'Order with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Payment addition failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST', 'PATCH', 'PUT'])
@permission_classes([IsAuthenticated])
def update_order_status(request, order_id):
    """
    Update order status
    """
    try:
        order = get_object_or_404(Order, id=order_id)
        
        serializer = OrderStatusUpdateSerializer(data=request.data)
        
        if serializer.is_valid():
            new_status = serializer.validated_data['status']
            notes = serializer.validated_data.get('notes', '')
            
            # Update status
            result = order.update_status(new_status, notes)
            
            return Response({
                'success': True,
                'message': f'Order status updated to {order.get_status_display()}.',
                'data': {
                    'order_id': str(order.id),
                    'old_status': result['old_status'],
                    'new_status': result['new_status'],
                    'status_display': order.get_status_display(),
                    'delivery_status': order.get_delivery_status()
                }
            }, status=status.HTTP_200_OK)
        
        return Response({
            'success': False,
            'message': 'Invalid status data.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Order.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order not found.',
            'errors': {'detail': 'Order with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Status update failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_order_actions(request):
    """
    Bulk actions on orders
    """
    serializer = OrderBulkActionSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                order_ids = serializer.validated_data['order_ids']
                action = serializer.validated_data['action']
                notes = serializer.validated_data.get('notes', '')
                
                orders = Order.objects.filter(id__in=order_ids, is_active=True)
                results = []
                
                for order in orders:
                    if action == 'confirm':
                        if order.status == 'PENDING':
                            order.update_status('CONFIRMED', notes)
                            results.append({'order_id': str(order.id), 'success': True})
                        else:
                            results.append({'order_id': str(order.id), 'success': False, 'reason': 'Not pending'})
                    
                    
                    elif action == 'mark_ready':
                        if order.status == 'CONFIRMED':
                            order.update_status('READY', notes)
                            results.append({'order_id': str(order.id), 'success': True})
                        else:
                            results.append({'order_id': str(order.id), 'success': False, 'reason': 'Not confirmed'})
                    
                    elif action == 'cancel':
                        if order.can_be_cancelled():
                            order.update_status('CANCELLED', notes)
                            results.append({'order_id': str(order.id), 'success': True})
                        else:
                            results.append({'order_id': str(order.id), 'success': False, 'reason': 'Cannot be cancelled'})
                    
                    elif action == 'activate':
                        order.is_active = True
                        order.save(update_fields=['is_active', 'updated_at'])
                        results.append({'order_id': str(order.id), 'success': True})
                    
                    elif action == 'deactivate':
                        order.soft_delete()
                        results.append({'order_id': str(order.id), 'success': True})
                
                successful_count = sum(1 for r in results if r['success'])
                
                return Response({
                    'success': True,
                    'message': f'Bulk action completed. {successful_count} orders processed successfully.',
                    'data': {
                        'action': action,
                        'total_orders': len(order_ids),
                        'successful_orders': successful_count,
                        'results': results
                    }
                }, status=status.HTTP_200_OK)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Bulk action failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Bulk action failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def recalculate_order_totals(request, order_id):
    """
    Recalculate order totals from order items
    """
    try:
        order = get_object_or_404(Order, id=order_id)
        
        # Recalculate totals
        new_total = order.calculate_totals()
        
        return Response({
            'success': True,
            'message': 'Order totals recalculated successfully.',
            'data': {
                'order_id': str(order.id),
                'new_total_amount': float(new_total),
                'remaining_amount': float(order.remaining_amount),
                'is_fully_paid': order.is_fully_paid,
                'payment_percentage': float(order.payment_percentage)
            }
        }, status=status.HTTP_200_OK)
        
    except Order.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order not found.',
            'errors': {'detail': 'Order with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Total recalculation failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_customer_info(request, order_id):
    """
    Update cached customer information in order
    """
    try:
        order = get_object_or_404(Order, id=order_id)
        
        serializer = OrderCustomerUpdateSerializer(data=request.data)
        
        if serializer.is_valid():
            # Update customer info
            for field, value in serializer.validated_data.items():
                setattr(order, field, value)
            
            order.save(update_fields=list(serializer.validated_data.keys()) + ['updated_at'])
            
            return Response({
                'success': True,
                'message': 'Customer information updated successfully.',
                'data': OrderDetailSerializer(order).data
            }, status=status.HTTP_200_OK)
        
        return Response({
            'success': False,
            'message': 'Invalid customer data.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Order.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order not found.',
            'errors': {'detail': 'Order with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Customer info update failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def due_today_orders(request):
    """
    Get orders due for delivery today
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get orders due today
        orders = Order.orders_due_today()
        orders = orders.select_related('customer', 'created_by')
        
        # Calculate pagination
        total_count = orders.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        orders = orders[start_index:end_index]
        
        serializer = OrderListSerializer(orders, many=True)
        
        return Response({
            'success': True,
            'data': {
                'orders': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'alert_message': f'{total_count} orders are due for delivery today'
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
            'message': 'Failed to retrieve orders due today.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def duplicate_order(request, order_id):
    """
    Duplicate an existing order for a customer
    """
    try:
        original_order = get_object_or_404(Order, id=order_id)
        
        # Get optional new customer from request data
        new_customer_id = request.data.get('customer_id')
        
        # Create duplicate
        with transaction.atomic():
            duplicate_data = {
                'customer': original_order.customer,
                'advance_payment': Decimal('0.00'),  # Start with no advance payment
                'description': f"Duplicate of Order #{original_order.id}",
                'status': 'PENDING',
                'created_by': request.user,
                'event_name': original_order.event_name,
                'event_location': original_order.event_location,
                'event_date': original_order.event_date,
                'return_date': original_order.return_date,
            }
            
            # If new customer specified, validate and use it
            if new_customer_id:
                from customers.models import Customer
                try:
                    new_customer = Customer.objects.get(id=new_customer_id, is_active=True)
                    duplicate_data['customer'] = new_customer
                except Customer.DoesNotExist:
                    return Response({
                        'success': False,
                        'message': 'New customer not found.',
                        'errors': {'detail': 'Specified customer does not exist or is inactive.'}
                    }, status=status.HTTP_400_BAD_REQUEST)
            
            duplicate_order = Order.objects.create(**duplicate_data)
            
            # Duplicate order items if they exist
            original_items = original_order.get_order_items()
            duplicated_items = []
            
            for item in original_items:
                from order_items.models import OrderItem
                item_data = {
                    'order': duplicate_order,
                    'product': item.product,
                    'product_name': item.product_name,
                    'quantity': item.quantity,
                    'rate': item.rate,
                    'days': item.days,
                    'customization_notes': item.customization_notes,
                    'line_total': item.line_total,
                    'rented_from_partner': item.rented_from_partner,
                    'partner': item.partner,
                    'partner_rate': item.partner_rate
                }
                duplicate_item = OrderItem.objects.create(**item_data)
                duplicated_items.append(duplicate_item)
            
            # Recalculate order totals
            duplicate_order.calculate_totals()
            
            return Response({
                'success': True,
                'message': f'Order duplicated successfully. {len(duplicated_items)} items copied.',
                'data': OrderDetailSerializer(duplicate_order).data
            }, status=status.HTTP_201_CREATED)
            
    except Order.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Order not found.',
            'errors': {'detail': 'Order with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Order duplication failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def generate_invoice(request, order_id):
    """
    Generate invoice data for an order
    """
    try:
        from django.conf import settings
        
        order = get_object_or_404(Order, id=order_id)
        
        serializer = OrderDetailSerializer(order)
        
        data = serializer.data
        data['invoice_date'] = timezone.now().date()
        data['invoice_number'] = f"INV-{order.id}"
        
        # Add company info (can move to settings later)
        company_info = getattr(settings, 'COMPANY_INFO', {
            'name': 'Moon Light Event Management',
            'phone': '+92 300 1234567',
            'email': 'info@moonlight.com',
            'address': 'Main Market, City'
        })
        data['company_info'] = company_info
        
        return Response({
            'success': True,
            'message': 'Invoice generated successfully.',
            'data': data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to generate invoice.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    