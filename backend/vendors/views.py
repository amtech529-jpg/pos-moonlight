from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.db.models import Q
from django.utils import timezone
from datetime import timedelta
from purchases.serializers import PurchaseSerializer

from .models import Vendor
from .serializers import (
    VendorBulkActionSerializer,
    VendorSerializer,
    VendorCreateSerializer,
    VendorListSerializer,
    VendorStatsSerializer,
    VendorUpdateSerializer,
    VendorDetailSerializer,
    VendorContactUpdateSerializer,
)
from .signals import vendor_bulk_updated
from payments.models import Payment
from payments.serializers import PaymentListSerializer
from django.db.models import Sum


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_vendors(request):
    """
    List all active vendors with pagination, search, and filtering
    """
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Search parameters
        search = request.GET.get('search', '').strip()
        city = request.GET.get('city', '').strip()
        area = request.GET.get('area', '').strip()
        
        # Date range filters
        created_after = request.GET.get('created_after', '').strip()
        created_before = request.GET.get('created_before', '').strip()
        
        # Sorting
        sort_by = request.GET.get('sort_by', 'name')  # name, created_at, business_name
        sort_order = request.GET.get('sort_order', 'asc')  # asc, desc
        
        # Base queryset
        if show_inactive:
            vendors = Vendor.objects.all()
        else:
            vendors = Vendor.active_vendors()
        
        # Apply search filter
        if search:
            vendors = vendors.search(search)
        
        # Apply city filter
        if city:
            vendors = vendors.filter(city__iexact=city)
        
        # Apply area filter
        if area:
            vendors = vendors.filter(area__iexact=area)
        
        # Apply date range filters
        if created_after:
            try:
                vendors = vendors.filter(created_at__date__gte=created_after)
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid created_after date format. Use YYYY-MM-DD.',
                    'errors': {'created_after': 'Invalid date format'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        if created_before:
            try:
                vendors = vendors.filter(created_at__date__lte=created_before)
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid created_before date format. Use YYYY-MM-DD.',
                    'errors': {'created_before': 'Invalid date format'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply sorting
        sort_fields = {
            'name': 'name',
            'business_name': 'business_name',
            'created_at': 'created_at',
            'updated_at': 'updated_at',
            'city': 'city',
            'area': 'area'
        }
        
        if sort_by in sort_fields:
            order_field = sort_fields[sort_by]
            if sort_order == 'desc':
                order_field = f'-{order_field}'
            vendors = vendors.order_by(order_field)
        
        # Select related to avoid N+1 queries
        vendors = vendors.select_related('created_by')
        
        # Calculate pagination
        total_count = vendors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        vendors = vendors[start_index:end_index]
        
        serializer = VendorListSerializer(vendors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'vendors': serializer.data,
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
                    'city': city,
                    'area': area,
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
            'message': 'Failed to retrieve vendors.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_vendor(request):
    """
    Create a new vendor
    """
    serializer = VendorCreateSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                vendor = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Vendor created successfully.',
                    'data': VendorDetailSerializer(vendor).data
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            error_msg = str(e)
            if 'unique constraint' in error_msg.lower() or 'already exists' in error_msg.lower():
                if 'cnic' in error_msg.lower():
                    return Response({
                        'success': False,
                        'message': 'A vendor with this CNIC already exists.',
                        'errors': {'cnic': ['This CNIC is already in use.']}
                    }, status=status.HTTP_400_BAD_REQUEST)
                elif 'phone' in error_msg.lower():
                    return Response({
                        'success': False,
                        'message': 'A vendor with this phone number already exists.',
                        'errors': {'phone': ['This phone number is already in use.']}
                    }, status=status.HTTP_400_BAD_REQUEST)
            
            return Response({
                'success': False,
                'message': 'Vendor creation failed due to server error.',
                'errors': {'error': error_msg}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Vendor creation failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_vendor(request, vendor_id):
    """
    Retrieve a specific vendor by ID
    """
    try:
        vendor = Vendor.objects.get(id=vendor_id)
        serializer = VendorDetailSerializer(vendor)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Vendor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Vendor not found.',
            'errors': {'detail': 'Vendor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Vendor not found.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_vendor(request, vendor_id):
    """
    Update a vendor
    """
    try:
        vendor = Vendor.objects.get(id=vendor_id)
        
        serializer = VendorUpdateSerializer(
            vendor,
            data=request.data,
            partial=request.method == 'PATCH'
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    vendor = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Vendor updated successfully.',
                        'data': VendorDetailSerializer(vendor).data
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                error_msg = str(e)
                if 'unique constraint' in error_msg.lower() or 'already exists' in error_msg.lower():
                    if 'cnic' in error_msg.lower():
                        return Response({
                            'success': False,
                            'message': 'Another vendor with this CNIC already exists.',
                            'errors': {'cnic': ['This CNIC is already in use.']}
                        }, status=status.HTTP_400_BAD_REQUEST)
                    elif 'phone' in error_msg.lower():
                        return Response({
                            'success': False,
                            'message': 'Another vendor with this phone number already exists.',
                            'errors': {'phone': ['This phone number is already in use.']}
                        }, status=status.HTTP_400_BAD_REQUEST)
                
                return Response({
                    'success': False,
                    'message': 'Vendor update failed due to server error.',
                    'errors': {'error': error_msg}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Vendor update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Vendor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Vendor not found.',
            'errors': {'detail': 'Vendor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_vendor(request, vendor_id):
    """
    Hard delete a vendor (permanently remove from database)
    """
    try:
        vendor = Vendor.objects.get(id=vendor_id)
        
        # Store vendor name for response message
        vendor_name = vendor.name
        
        # Check if vendor has payments (optional safety check)
        # Uncomment this if you have a Payment model that references vendors
        # if hasattr(vendor, 'payments') and vendor.payments.exists():
        #     return Response({
        #         'success': False,
        #         'message': 'Cannot delete vendor as they have existing payments.',
        #         'errors': {'detail': 'This vendor has payment history.'}
        #     }, status=status.HTTP_400_BAD_REQUEST)
        
        # Permanently delete the vendor
        vendor.delete()
        
        return Response({
            'success': True,
            'message': f'Vendor "{vendor_name}" deleted permanently.'
        }, status=status.HTTP_200_OK)
        
    except Vendor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Vendor not found.',
            'errors': {'detail': 'Vendor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Vendor deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def soft_delete_vendor(request, vendor_id):
    """
    Soft delete a vendor (set is_active=False)
    """
    try:
        vendor = Vendor.objects.get(id=vendor_id)
        
        if not vendor.is_active:
            return Response({
                'success': False,
                'message': 'Vendor is already inactive.',
                'errors': {'detail': 'This vendor has already been soft deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        vendor.soft_delete()
        
        return Response({
            'success': True,
            'message': 'Vendor soft deleted successfully.'
        }, status=status.HTTP_200_OK)
        
    except Vendor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Vendor not found.',
            'errors': {'detail': 'Vendor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Vendor soft deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def restore_vendor(request, vendor_id):
    """
    Restore a soft-deleted vendor (set is_active=True)
    """
    try:
        vendor = Vendor.objects.get(id=vendor_id)
        
        if vendor.is_active:
            return Response({
                'success': False,
                'message': 'Vendor is already active.',
                'errors': {'detail': 'This vendor is not deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        vendor.restore()
        
        return Response({
            'success': True,
            'message': 'Vendor restored successfully.',
            'data': VendorDetailSerializer(vendor).data
        }, status=status.HTTP_200_OK)
        
    except Vendor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Vendor not found.',
            'errors': {'detail': 'Vendor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Vendor restoration failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_vendor_contact(request, vendor_id):
    """
    Update vendor contact information
    """
    try:
        vendor = Vendor.objects.get(id=vendor_id)
        
        serializer = VendorContactUpdateSerializer(
            vendor,
            data=request.data,
            partial=True
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    vendor = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Vendor contact information updated successfully.',
                        'data': {
                            'id': str(vendor.id),
                            'name': vendor.name,
                            'phone': vendor.phone,
                            'city': vendor.city,
                            'area': vendor.area
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
        
    except Vendor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Vendor not found.',
            'errors': {'detail': 'Vendor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def vendors_by_city(request, city_name):
    """
    Get vendors by city
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get vendors by city (case-insensitive)
        vendors = Vendor.active_vendors().filter(city__iexact=city_name)
        vendors = vendors.select_related('created_by')
        
        # Calculate pagination
        total_count = vendors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        vendors = vendors[start_index:end_index]
        
        serializer = VendorListSerializer(vendors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'vendors': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'city': city_name,
                'total_vendors_in_city': total_count
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
            'message': 'Failed to retrieve vendors by city.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def vendors_by_area(request, area_name):
    """
    Get vendors by area
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get vendors by area (case-insensitive)
        vendors = Vendor.active_vendors().filter(area__iexact=area_name)
        vendors = vendors.select_related('created_by')
        
        # Calculate pagination
        total_count = vendors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        vendors = vendors[start_index:end_index]
        
        serializer = VendorListSerializer(vendors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'vendors': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'area': area_name,
                'total_vendors_in_area': total_count
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
            'message': 'Failed to retrieve vendors by area.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_vendors(request):
    """
    Search vendors by name, business name, phone, CNIC, city, or area
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
        city = request.GET.get('city', '').strip()
        area = request.GET.get('area', '').strip()
        
        # Search vendors
        vendors = Vendor.active_vendors().search(query)
        
        # Apply additional filters
        if city:
            vendors = vendors.filter(city__iexact=city)
        
        if area:
            vendors = vendors.filter(area__iexact=area)
        
        vendors = vendors.select_related('created_by')
        
        # Calculate pagination
        total_count = vendors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        vendors = vendors[start_index:end_index]
        
        serializer = VendorListSerializer(vendors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'vendors': serializer.data,
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
                    'city': city,
                    'area': area
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
def new_vendors(request):
    """
    Get new vendors (created within specified days)
    """
    try:
        days = int(request.GET.get('days', 30))
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get new vendors
        vendors = Vendor.new_vendors(days=days)
        vendors = vendors.select_related('created_by')
        
        # Calculate pagination
        total_count = vendors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        vendors = vendors[start_index:end_index]
        
        serializer = VendorListSerializer(vendors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'vendors': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'days': days,
                'description': f'Vendors created within the last {days} days'
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
            'message': 'Failed to retrieve new vendors.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recent_vendors(request):
    """
    Get recently added vendors (last 7 days by default)
    """
    try:
        days = int(request.GET.get('days', 7))
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get recent vendors
        vendors = Vendor.recent_vendors(days=days)
        vendors = vendors.select_related('created_by')
        
        # Calculate pagination
        total_count = vendors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        vendors = vendors[start_index:end_index]
        
        serializer = VendorListSerializer(vendors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'vendors': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'days': days,
                'description': f'Vendors added in the last {days} days'
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
            'message': 'Failed to retrieve recent vendors.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def vendor_statistics(request):
    """
    Get comprehensive vendor statistics
    """
    try:
        stats = Vendor.get_statistics()
        serializer = VendorStatsSerializer(stats)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve vendor statistics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_vendor_actions(request):
    """
    Perform bulk actions on multiple vendors
    """
    serializer = VendorBulkActionSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                vendor_ids = serializer.validated_data['vendor_ids']
                action = serializer.validated_data['action']
                
                # Get vendors
                vendors = Vendor.objects.filter(id__in=vendor_ids)
                if vendors.count() != len(vendor_ids):
                    return Response({
                        'success': False,
                        'message': 'Some vendors were not found.',
                        'errors': {'detail': 'One or more vendor IDs are invalid.'}
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                results = []
                
                # Perform action
                if action == 'activate':
                    updated_count = vendors.update(is_active=True)
                    message = f'{updated_count} vendors activated successfully.'
                
                elif action == 'deactivate':
                    updated_count = vendors.update(is_active=False)
                    message = f'{updated_count} vendors deactivated successfully.'
                
                # Get updated vendor data
                updated_vendors = Vendor.objects.filter(id__in=vendor_ids)
                for vendor in updated_vendors:
                    results.append({
                        'id': str(vendor.id),
                        'name': vendor.name,
                        'business_name': vendor.business_name,
                        'is_active': vendor.is_active
                    })
                
                # Send custom signal
                vendor_bulk_updated.send(
                    sender=Vendor,
                    vendors=list(updated_vendors),
                    action=action
                )
                
                return Response({
                    'success': True,
                    'message': message,
                    'data': {
                        'action': action,
                        'updated_vendors': results,
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
def duplicate_vendor(request, vendor_id):
    """
    Duplicate an existing vendor (useful for creating similar vendors)
    """
    try:
        original_vendor = get_object_or_404(Vendor, id=vendor_id)
        
        # Get new data from request
        new_name = request.data.get('name')
        new_phone = request.data.get('phone')
        new_cnic = request.data.get('cnic')
        
        if not new_name:
            return Response({
                'success': False,
                'message': 'New vendor name is required.',
                'errors': {'name': 'This field is required for duplication.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not new_phone:
            return Response({
                'success': False,
                'message': 'New vendor phone is required.',
                'errors': {'phone': 'This field is required for duplication.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not new_cnic:
            return Response({
                'success': False,
                'message': 'New vendor CNIC is required.',
                'errors': {'cnic': 'This field is required for duplication.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create duplicate with new contact info
        with transaction.atomic():
            duplicate_data = {
                'name': new_name.strip(),
                'business_name': original_vendor.business_name,
                'cnic': new_cnic.strip(),
                'phone': new_phone.strip(),
                'city': original_vendor.city,
                'area': original_vendor.area,
                'created_by': request.user
            }
            
            # Validate using serializer
            serializer = VendorCreateSerializer(
                data=duplicate_data,
                context={'request': request}
            )
            
            if serializer.is_valid():
                duplicate_vendor = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Vendor duplicated successfully.',
                    'data': VendorDetailSerializer(duplicate_vendor).data
                }, status=status.HTTP_201_CREATED)
            else:
                return Response({
                    'success': False,
                    'message': 'Vendor duplication failed.',
                    'errors': serializer.errors
                }, status=status.HTTP_400_BAD_REQUEST)
            
    except Vendor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Vendor not found.',
            'errors': {'detail': 'Vendor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Vendor duplication failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def vendor_transactions(request, vendor_id):
    """
    Get vendor's transactions (payments and purchases)
    """
    try:
        vendor = Vendor.objects.get(id=vendor_id)
        
        # Get pagination parameters
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get payments
        payments = Payment.objects.filter(vendor=vendor, is_active=True).order_by('-date', '-created_at')
        
        # Calculate summary
        total_payments = payments.count()
        total_amount = payments.aggregate(total=Sum('amount_paid'))['total'] or 0
        
        # Calculate pagination
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        paginated_payments = payments[start_index:end_index]
        
        payment_serializer = PaymentListSerializer(paginated_payments, many=True)
        
        return Response({
            'success': True,
            'data': {
                'vendor_id': str(vendor.id),
                'vendor_name': vendor.name,
                'transactions': payment_serializer.data,
                'summary': {
                    'totalTransactions': total_payments,
                    'totalAmount': float(total_amount),
                    'pendingAmount': 0.0, # Placeholder for now as we don't have Payable model integration here yet
                    'paidAmount': float(total_amount),
                    'lastTransactionDate': payments.first().date if payments.exists() else None,
                },
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_payments,
                    'total_pages': (total_payments + page_size - 1) // page_size,
                },
                'note': 'Transactions retrieved successfully.'
            }
        }, status=status.HTTP_200_OK)
        
    except Vendor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Vendor not found.',
            'errors': {'detail': 'Vendor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
         return Response({
            'success': False,
            'message': 'Failed to retrieve vendor transactions.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def vendor_payments(request, vendor_id):
    """
    Get vendor's payment history (Redirects to transactions for now)
    """
    return vendor_transactions(request, vendor_id)

@api_view(['GET'])
def vendor_purchases(request, vendor_id):
    vendor = Vendor.objects.get(id=vendor_id)
    purchases = vendor.purchases.all()
    serializer = PurchaseSerializer(purchases, many=True)
    return Response(serializer.data)