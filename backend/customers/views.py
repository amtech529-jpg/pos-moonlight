from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.db.models import Q, ProtectedError
from django.utils import timezone
from datetime import timedelta
from .models import Customer
from .serializers import (
    CustomerSerializer,
    CustomerCreateSerializer,
    CustomerListSerializer,
    CustomerUpdateSerializer,
    CustomerDetailSerializer,
    CustomerStatsSerializer,
    CustomerContactUpdateSerializer,
    CustomerVerificationSerializer,
    CustomerBulkActionSerializer
)
from .signals import (
    customer_bulk_updated,
    customer_bulk_created,
    customer_bulk_deleted,
    customer_verification_changed
)


# Function-based views (following your Product module pattern)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customers_by_country(request, country_name):
    """
    Get customers by country
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get customers by country (case-insensitive)
        customers = Customer.active_customers().filter(country__iexact=country_name)
        customers = customers.select_related('created_by')
        
        # Calculate pagination
        total_count = customers.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        customers = customers[start_index:end_index]
        
        serializer = CustomerListSerializer(customers, many=True)
        
        return Response({
            'success': True,
            'data': {
                'customers': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'country': country_name,
                'total_customers_in_country': total_count
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
            'message': 'Failed to retrieve customers by country.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pakistani_customers(request):
    """
    Get Pakistani customers
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get Pakistani customers
        customers = Customer.active_customers().pakistani_customers()
        customers = customers.select_related('created_by')
        
        # Calculate pagination
        total_count = customers.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        customers = customers[start_index:end_index]
        
        serializer = CustomerListSerializer(customers, many=True)
        
        return Response({
            'success': True,
            'data': {
                'customers': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'filter': 'Pakistani customers',
                'total_pakistani_customers': total_count
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
            'message': 'Failed to retrieve Pakistani customers.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def international_customers(request):
    """
    Get international (non-Pakistani) customers
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get international customers
        customers = Customer.active_customers().international_customers()
        customers = customers.select_related('created_by')
        
        # Calculate pagination
        total_count = customers.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        customers = customers[start_index:end_index]
        
        serializer = CustomerListSerializer(customers, many=True)
        
        return Response({
            'success': True,
            'data': {
                'customers': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'filter': 'International customers',
                'total_international_customers': total_count
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
            'message': 'Failed to retrieve international customers.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_customers(request):
    """
    List all active customers with pagination, search, and filtering
    """
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Search parameters
        search = request.GET.get('search', '').strip()
        customer_type = request.GET.get('customer_type', '').strip()
        status_filter = request.GET.get('status', '').strip()
        city = request.GET.get('city', '').strip()
        country = request.GET.get('country', '').strip()
        country = request.GET.get('country', '').strip()
        verification_filter = request.GET.get('verified', '').strip()
        
        # Date range filters
        created_after = request.GET.get('created_after', '').strip()
        created_before = request.GET.get('created_before', '').strip()
        
        # Sorting
        sort_by = request.GET.get('sort_by', 'name')  # name, created_at, last_order_date
        sort_order = request.GET.get('sort_order', 'asc')  # asc, desc
        
        # Base queryset
        if show_inactive:
            customers = Customer.objects.all()
        else:
            customers = Customer.objects.filter(is_active=True)
        
        # Apply search
        if search:
            customers = customers.filter(
                Q(name__icontains=search) |
                Q(email__icontains=search) |
                Q(phone__icontains=search) |
                Q(business_name__icontains=search)
            )
        
        # Apply filters
        if customer_type:
            customers = customers.filter(customer_type=customer_type)
        
        if status_filter:
            customers = customers.filter(status=status_filter)
        
        if city:
            customers = customers.filter(city__icontains=city)
        
        if country:
            customers = customers.filter(country__icontains=country)
        
        if verification_filter:
            if verification_filter == 'phone':
                customers = customers.filter(phone_verified=True)
            elif verification_filter == 'email':
                customers = customers.filter(email_verified=True)
            elif verification_filter == 'both':
                customers = customers.filter(phone_verified=True, email_verified=True)
        
        # Apply date filters
        if created_after:
            customers = customers.filter(created_at__gte=created_after)
        
        if created_before:
            customers = customers.filter(created_at__lte=created_before)
        
        # Apply sorting
        sort_fields = {
            'name': 'name',
            'created_at': 'created_at',
            'updated_at': 'updated_at',
            'last_order_date': 'last_order_date',
            'status': 'status',
            'customer_type': 'customer_type'
        }
        
        if sort_by in sort_fields:
            order_field = sort_fields[sort_by]
            if sort_order == 'desc':
                order_field = f'-{order_field}'
            customers = customers.order_by(order_field)
        
        # Select related to avoid N+1 queries
        customers = customers.select_related('created_by')
        
        # Calculate pagination
        total_count = customers.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        customers = customers[start_index:end_index]
        
        serializer = CustomerListSerializer(customers, many=True)
        
        return Response({
            'success': True,
            'data': {
                'customers': serializer.data,
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
                    'customer_type': customer_type,
                    'status': status_filter,
                    'city': city,
                    'country': country,
                    'verified': verification_filter,
                    'created_after': created_after,
                    'created_before': created_before,
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
            'message': 'Failed to retrieve customers.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_customer(request):
    """
    Create a new customer
    """
    serializer = CustomerCreateSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                customer = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Customer created successfully.',
                    'data': CustomerDetailSerializer(customer).data
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Customer creation failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Customer creation failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_customer(request, customer_id):
    """
    Retrieve a specific customer by ID
    """
    try:
        customer = Customer.objects.get(id=customer_id)
        serializer = CustomerDetailSerializer(customer)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': 'Customer with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_customer(request, customer_id):
    """
    Update a customer
    """
    try:
        customer = Customer.objects.get(id=customer_id)
        
        serializer = CustomerUpdateSerializer(
            customer,
            data=request.data,
            partial=request.method == 'PATCH'
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    customer = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Customer updated successfully.',
                        'data': CustomerDetailSerializer(customer).data
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Customer update failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Customer update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': 'Customer with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_customer(request, customer_id):
    """
    Hard delete a customer (permanently remove from database)
    """
    try:
        customer = Customer.objects.get(id=customer_id)
        
        # Store customer name for response message
        customer_name = customer.name
        
        # Check if customer has orders (optional safety check)
        # Uncomment this if you have an Order model that references customers
        # if hasattr(customer, 'orders') and customer.orders.exists():
        #     return Response({
        #         'success': False,
        #         'message': 'Cannot delete customer as they have existing orders.',
        #         'errors': {'detail': 'This customer has order history.'}
        #     }, status=status.HTTP_400_BAD_REQUEST)
        
        # Permanently delete the customer
        customer.delete()
        
        return Response({
            'success': True,
            'message': f'Customer "{customer_name}" deleted permanently.'
        }, status=status.HTTP_200_OK)
        
    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': 'Customer with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
        
    except ProtectedError as e:
        return Response({
            'success': False,
            'message': 'Cannot delete customer because of protected foreign keys (e.g., existing sales).',
            'errors': {'detail': 'protected foreign keys'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Customer deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def soft_delete_customer(request, customer_id):
    """
    Soft delete a customer (set is_active=False)
    """
    try:
        customer = Customer.objects.get(id=customer_id)
        
        if not customer.is_active:
            return Response({
                'success': False,
                'message': 'Customer is already inactive.',
                'errors': {'detail': 'This customer has already been soft deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        customer.soft_delete()
        
        return Response({
            'success': True,
            'message': 'Customer soft deleted successfully.'
        }, status=status.HTTP_200_OK)
        
    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': 'Customer with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Customer soft deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def restore_customer(request, customer_id):
    """
    Restore a soft-deleted customer (set is_active=True)
    """
    try:
        customer = Customer.objects.get(id=customer_id)
        
        if customer.is_active:
            return Response({
                'success': False,
                'message': 'Customer is already active.',
                'errors': {'detail': 'This customer is not deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        customer.restore()
        
        return Response({
            'success': True,
            'message': 'Customer restored successfully.',
            'data': CustomerDetailSerializer(customer).data
        }, status=status.HTTP_200_OK)
        
    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': 'Customer with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Customer restoration failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_customers(request):
    """
    Search customers by name, phone, email, business name, or city
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
        
        # Additional filters
        customer_type = request.GET.get('customer_type', '').strip()
        status_filter = request.GET.get('status', '').strip()
        city = request.GET.get('city', '').strip()
        
        # Search customers
        customers = Customer.active_customers().search(query)
        
        # Apply additional filters
        if customer_type and customer_type.upper() in dict(Customer.TYPE_CHOICES):
            customers = customers.filter(customer_type=customer_type.upper())
        
        if status_filter and status_filter.upper() in dict(Customer.STATUS_CHOICES):
            customers = customers.filter(status=status_filter.upper())
        
        if city:
            customers = customers.filter(city__iexact=city)
        
        customers = customers.select_related('created_by')
        
        # Calculate pagination
        total_count = customers.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        customers = customers[start_index:end_index]
        
        serializer = CustomerListSerializer(customers, many=True)
        
        return Response({
            'success': True,
            'data': {
                'customers': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'search_query': query,
                'filters_applied': {
                    'customer_type': customer_type,
                    'status': status_filter,
                    'city': city,
                    'country': country
                }
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
def customers_by_status(request, status_name):
    """
    Get customers by status
    """
    try:
        status_upper = status_name.upper()
        if status_upper not in dict(Customer.STATUS_CHOICES):
            return Response({
                'success': False,
                'message': 'Invalid status.',
                'errors': {'detail': f'Status must be one of: {", ".join(dict(Customer.STATUS_CHOICES).keys())}'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get customers by status
        customers = Customer.customers_by_status(status_upper)
        customers = customers.select_related('created_by')
        
        # Calculate pagination
        total_count = customers.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        customers = customers[start_index:end_index]
        
        serializer = CustomerListSerializer(customers, many=True)
        
        return Response({
            'success': True,
            'data': {
                'customers': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'status': status_name,
                'status_display': dict(Customer.STATUS_CHOICES)[status_upper]
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
            'message': 'Failed to retrieve customers by status.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customers_by_type(request, type_name):
    """
    Get customers by type
    """
    try:
        type_upper = type_name.upper()
        if type_upper not in dict(Customer.TYPE_CHOICES):
            return Response({
                'success': False,
                'message': 'Invalid customer type.',
                'errors': {'detail': f'Type must be one of: {", ".join(dict(Customer.TYPE_CHOICES).keys())}'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get customers by type
        customers = Customer.customers_by_type(type_upper)
        customers = customers.select_related('created_by')
        
        # Calculate pagination
        total_count = customers.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        customers = customers[start_index:end_index]
        
        serializer = CustomerListSerializer(customers, many=True)
        
        return Response({
            'success': True,
            'data': {
                'customers': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'customer_type': type_name,
                'type_display': dict(Customer.TYPE_CHOICES)[type_upper]
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
            'message': 'Failed to retrieve customers by type.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def new_customers(request):
    """
    Get new customers (created within specified days)
    """
    try:
        days = int(request.GET.get('days', 30))
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get new customers
        customers = Customer.new_customers(days=days)
        customers = customers.select_related('created_by')
        
        # Calculate pagination
        total_count = customers.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        customers = customers[start_index:end_index]
        
        serializer = CustomerListSerializer(customers, many=True)
        
        return Response({
            'success': True,
            'data': {
                'customers': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'days': days,
                'description': f'Customers created within the last {days} days'
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
            'message': 'Failed to retrieve new customers.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recent_customers(request):
    """
    Get recently added customers (last 7 days by default)
    """
    try:
        days = int(request.GET.get('days', 7))
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get recent customers
        customers = Customer.recent_customers(days=days)
        customers = customers.select_related('created_by')
        
        # Calculate pagination
        total_count = customers.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        customers = customers[start_index:end_index]
        
        serializer = CustomerListSerializer(customers, many=True)
        
        return Response({
            'success': True,
            'data': {
                'customers': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'days': days,
                'description': f'Customers added in the last {days} days'
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
            'message': 'Failed to retrieve recent customers.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customer_statistics(request):
    """
    Get comprehensive customer statistics
    """
    try:
        stats = Customer.get_statistics()
        serializer = CustomerStatsSerializer(stats)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve customer statistics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_customer_contact(request, customer_id):
    """
    Update customer contact information
    """
    try:
        customer = get_object_or_404(Customer, id=customer_id)
        
        serializer = CustomerContactUpdateSerializer(
            customer,
            data=request.data,
            partial=True
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    customer = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Customer contact information updated successfully.',
                        'data': {
                            'id': str(customer.id),
                            'name': customer.name,
                            'phone': customer.phone,
                            'email': customer.email,
                            'address': customer.address,
                            'city': customer.city
                        }
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Contact update failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Contact update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': 'Customer with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def verify_customer_contact(request, customer_id):
    """
    Verify customer phone or email
    """
    try:
        customer = get_object_or_404(Customer, id=customer_id)
        
        serializer = CustomerVerificationSerializer(data=request.data)
        
        if serializer.is_valid():
            verification_type = serializer.validated_data['verification_type']
            verified = serializer.validated_data['verified']
            
            if verification_type == 'phone':
                if verified:
                    customer.verify_phone()
                else:
                    customer.phone_verified = False
                    customer.save(update_fields=['phone_verified', 'updated_at'])
                
                # Send custom signal
                customer_verification_changed.send(
                    sender=Customer,
                    customer=customer,
                    verification_type='phone',
                    verified=verified
                )
                
                return Response({
                    'success': True,
                    'message': f'Customer phone {"verified" if verified else "unverified"} successfully.',
                    'data': {
                        'customer_id': str(customer.id),
                        'phone': customer.phone,
                        'phone_verified': customer.phone_verified
                    }
                }, status=status.HTTP_200_OK)
            
            elif verification_type == 'email':
                if not customer.email:
                    return Response({
                        'success': False,
                        'message': 'Customer has no email to verify.',
                        'errors': {'detail': 'This customer does not have an email address.'}
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                if verified:
                    customer.verify_email()
                else:
                    customer.email_verified = False
                    customer.save(update_fields=['email_verified', 'updated_at'])
                
                # Send custom signal
                customer_verification_changed.send(
                    sender=Customer,
                    customer=customer,
                    verification_type='email',
                    verified=verified
                )
                
                return Response({
                    'success': True,
                    'message': f'Customer email {"verified" if verified else "unverified"} successfully.',
                    'data': {
                        'customer_id': str(customer.id),
                        'email': customer.email,
                        'email_verified': customer.email_verified
                    }
                }, status=status.HTTP_200_OK)
        
        return Response({
            'success': False,
            'message': 'Verification failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': 'Customer with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Verification failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_customer_actions(request):
    """
    Perform bulk actions on multiple customers
    """
    serializer = CustomerBulkActionSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                customer_ids = serializer.validated_data['customer_ids']
                action = serializer.validated_data['action']
                
                # Get customers
                customers = Customer.objects.filter(id__in=customer_ids)
                if customers.count() != len(customer_ids):
                    return Response({
                        'success': False,
                        'message': 'Some customers were not found.',
                        'errors': {'detail': 'One or more customer IDs are invalid.'}
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                results = []
                
                # Perform action
                if action == 'activate':
                    updated_count = customers.update(is_active=True)
                    message = f'{updated_count} customers activated successfully.'
                
                elif action == 'deactivate':
                    updated_count = customers.update(is_active=False)
                    message = f'{updated_count} customers deactivated successfully.'
                
                elif action == 'mark_regular':
                    updated_count = customers.update(status='REGULAR')
                    message = f'{updated_count} customers marked as Regular.'
                
                elif action == 'mark_vip':
                    updated_count = customers.update(status='VIP')
                    message = f'{updated_count} customers marked as VIP.'
                
                elif action == 'verify_phone':
                    updated_count = customers.update(phone_verified=True)
                    message = f'{updated_count} customer phone numbers verified.'
                
                elif action == 'verify_email':
                    # Only update customers with email addresses
                    updated_count = customers.exclude(
                        Q(email__isnull=True) | Q(email='')
                    ).update(email_verified=True)
                    message = f'{updated_count} customer emails verified.'
                
                # Get updated customer data
                updated_customers = Customer.objects.filter(id__in=customer_ids)
                for customer in updated_customers:
                    results.append({
                        'id': str(customer.id),
                        'name': customer.name,
                        'status': customer.status,
                        'phone_verified': customer.phone_verified,
                        'email_verified': customer.email_verified,
                        'is_active': customer.is_active
                    })
                
                # Send custom signal
                customer_bulk_updated.send(
                    sender=Customer,
                    customers=list(updated_customers),
                    action=action
                )
                
                return Response({
                    'success': True,
                    'message': message,
                    'data': {
                        'action': action,
                        'updated_customers': results,
                        'total_updated': len(results)
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
def update_customer_activity(request, customer_id):
    """
    Update customer activity (last order date, last contact date)
    """
    try:
        customer = get_object_or_404(Customer, id=customer_id)
        
        activity_type = request.data.get('activity_type')
        activity_date = request.data.get('activity_date')  # Optional, defaults to now
        
        if not activity_type:
            return Response({
                'success': False,
                'message': 'Activity type is required.',
                'errors': {'detail': 'Please specify activity_type: "order" or "contact"'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if activity_type not in ['order', 'contact']:
            return Response({
                'success': False,
                'message': 'Invalid activity type.',
                'errors': {'detail': 'Activity type must be "order" or "contact"'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Parse activity date if provided
        if activity_date:
            try:
                from django.utils.dateparse import parse_datetime
                parsed_date = parse_datetime(activity_date)
                if not parsed_date:
                    raise ValueError("Invalid datetime format")
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid activity date format.',
                    'errors': {'detail': 'Use ISO format: YYYY-MM-DDTHH:MM:SSZ'}
                }, status=status.HTTP_400_BAD_REQUEST)
        else:
            parsed_date = None
        
        # Update activity
        if activity_type == 'order':
            customer.update_last_order_date(parsed_date)
            # Auto-update status based on activity
            customer.update_status_based_on_activity()
            
            return Response({
                'success': True,
                'message': 'Customer last order date updated successfully.',
                'data': {
                    'customer_id': str(customer.id),
                    'last_order_date': customer.last_order_date,
                    'status': customer.status
                }
            }, status=status.HTTP_200_OK)
        
        elif activity_type == 'contact':
            customer.update_last_contact_date(parsed_date)
            
            return Response({
                'success': True,
                'message': 'Customer last contact date updated successfully.',
                'data': {
                    'customer_id': str(customer.id),
                    'last_contact_date': customer.last_contact_date
                }
            }, status=status.HTTP_200_OK)
        
    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': 'Customer with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Activity update failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def duplicate_customer(request, customer_id):
    """
    Duplicate an existing customer (useful for creating similar customers)
    """
    try:
        original_customer = get_object_or_404(Customer, id=customer_id)
        
        # Get new data from request
        new_name = request.data.get('name')
        new_phone = request.data.get('phone')
        new_email = request.data.get('email', '')
        
        if not new_name:
            return Response({
                'success': False,
                'message': 'New customer name is required.',
                'errors': {'name': 'This field is required for duplication.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not new_phone:
            return Response({
                'success': False,
                'message': 'New customer phone is required.',
                'errors': {'phone': 'This field is required for duplication.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create duplicate with new contact info
        with transaction.atomic():
            duplicate_data = {
                'name': new_name.strip(),
                'phone': new_phone.strip(),
                'email': new_email.strip() if new_email else None,
                'address': original_customer.address,
                'city': original_customer.city,
                'customer_type': original_customer.customer_type,
                'status': 'NEW',  # New duplicate starts as NEW
                'business_name': original_customer.business_name,
                'tax_number': '',  # Clear tax number for duplicate
                'notes': f"Duplicated from {original_customer.name} ({original_customer.phone})",
                'created_by': request.user
            }
            
            # Validate using serializer
            serializer = CustomerCreateSerializer(
                data=duplicate_data,
                context={'request': request}
            )
            
            if serializer.is_valid():
                duplicate_customer = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Customer duplicated successfully.',
                    'data': CustomerDetailSerializer(duplicate_customer).data
                }, status=status.HTTP_201_CREATED)
            else:
                return Response({
                    'success': False,
                    'message': 'Customer duplication failed.',
                    'errors': serializer.errors
                }, status=status.HTTP_400_BAD_REQUEST)
            
    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': 'Customer with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Customer duplication failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customers_by_city(request, city_name):
    """
    Get customers by city
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get customers by city (case-insensitive)
        customers = Customer.active_customers().filter(city__iexact=city_name)
        customers = customers.select_related('created_by')
        
        # Calculate pagination
        total_count = customers.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        customers = customers[start_index:end_index]
        
        serializer = CustomerListSerializer(customers, many=True)
        
        return Response({
            'success': True,
            'data': {
                'customers': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'city': city_name,
                'total_customers_in_city': total_count
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
            'message': 'Failed to retrieve customers by city.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customer_orders(request, customer_id):
    """
    Get customer's order history (placeholder for future integration)
    """
    try:
        customer = get_object_or_404(Customer, id=customer_id)
        
        # Placeholder response - will be implemented when Order module is available
        return Response({
            'success': True,
            'message': 'Order integration not yet implemented.',
            'data': {
                'customer_id': str(customer.id),
                'customer_name': customer.name,
                'orders': [],
                'total_orders': 0,
                'total_sales_amount': 0.00,
                'last_order_date': customer.last_order_date,
                'note': 'Order history will be available once Order module is integrated.'
            }
        }, status=status.HTTP_200_OK)
        
    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': 'Customer with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customer_sales(request, customer_id):
    """
    Get customer's sales history (placeholder for future integration)
    """
    try:
        customer = get_object_or_404(Customer, id=customer_id)
        
        # Placeholder response - will be implemented when Sales module is available
        return Response({
            'success': True,
            'message': 'Sales integration not yet implemented.',
            'data': {
                'customer_id': str(customer.id),
                'customer_name': customer.name,
                'sales': [],
                'total_sales': 0,
                'total_sales_amount': 0.00,
                'average_sale_amount': 0.00,
                'first_sale_date': None,
                'last_sale_date': None,
                'note': 'Sales history will be available once Sales module is integrated.'
            }
        }, status=status.HTTP_200_OK)
        
    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': 'Customer with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    