from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.db.models import Q, Sum, Avg, Count, Min, Max
from django.utils import timezone
from datetime import timedelta, date
from decimal import Decimal
from .models import Labor, SalarySlip
from .serializers import (
    LaborBulkActionSerializer,
    LaborSerializer,
    LaborCreateSerializer,
    LaborListSerializer,
    LaborStatsSerializer,
    LaborUpdateSerializer,
    LaborDetailSerializer,
    LaborContactUpdateSerializer,
    LaborSalaryUpdateSerializer,
    SalarySlipSerializer,
    SalaryGenerationSerializer,
)
from .signals import labor_bulk_updated
from payments.models import Payment
from payments.serializers import PaymentListSerializer
from advance_payments.models import AdvancePayment
from advance_payments.serializers import AdvancePaymentListSerializer
from django.db.models import Sum
from . import models


# ==================== BASIC CRUD OPERATIONS ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_labors(request):
    """
    List all active labors with pagination, search, and filtering
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
        designation = request.GET.get('designation', '').strip()
        caste = request.GET.get('caste', '').strip()
        gender = request.GET.get('gender', '').strip()
        
        # Salary range filters
        min_salary = request.GET.get('min_salary', '').strip()
        max_salary = request.GET.get('max_salary', '').strip()
        
        # Age range filters
        min_age = request.GET.get('min_age', '').strip()
        max_age = request.GET.get('max_age', '').strip()
        
        # Date range filters
        joined_after = request.GET.get('joined_after', '').strip()
        joined_before = request.GET.get('joined_before', '').strip()
        
        # Sorting
        sort_by = request.GET.get('sort_by', 'name')  # name, joining_date, salary, age
        sort_order = request.GET.get('sort_order', 'asc')  # asc, desc
        
        # Base queryset
        if show_inactive:
            labors = Labor.objects.all()
        else:
            labors = Labor.active_labors()
        
        # Apply search filter
        if search:
            labors = labors.search(search)
        
        # Apply filters
        if city:
            labors = labors.filter(city__iexact=city)
        
        if area:
            labors = labors.filter(area__iexact=area)
        
        if designation:
            labors = labors.filter(designation__iexact=designation)
        
        if caste:
            labors = labors.filter(caste__iexact=caste)
        
        if gender:
            labors = labors.filter(gender=gender)
        
        # Apply salary range filters
        if min_salary:
            try:
                labors = labors.filter(salary__gte=Decimal(min_salary))
            except (ValueError, TypeError):
                return Response({
                    'success': False,
                    'message': 'Invalid min_salary value.',
                    'errors': {'min_salary': 'Must be a valid number'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        if max_salary:
            try:
                labors = labors.filter(salary__lte=Decimal(max_salary))
            except (ValueError, TypeError):
                return Response({
                    'success': False,
                    'message': 'Invalid max_salary value.',
                    'errors': {'max_salary': 'Must be a valid number'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply age range filters
        if min_age:
            try:
                labors = labors.filter(age__gte=int(min_age))
            except (ValueError, TypeError):
                return Response({
                    'success': False,
                    'message': 'Invalid min_age value.',
                    'errors': {'min_age': 'Must be a valid integer'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        if max_age:
            try:
                labors = labors.filter(age__lte=int(max_age))
            except (ValueError, TypeError):
                return Response({
                    'success': False,
                    'message': 'Invalid max_age value.',
                    'errors': {'max_age': 'Must be a valid integer'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply date range filters
        if joined_after:
            try:
                labors = labors.filter(joining_date__gte=joined_after)
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid joined_after date format. Use YYYY-MM-DD.',
                    'errors': {'joined_after': 'Invalid date format'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        if joined_before:
            try:
                labors = labors.filter(joining_date__lte=joined_before)
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid joined_before date format. Use YYYY-MM-DD.',
                    'errors': {'joined_before': 'Invalid date format'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply sorting
        sort_fields = {
            'name': 'name',
            'joining_date': 'joining_date',
            'salary': 'salary',
            'age': 'age',
            'designation': 'designation',
            'caste': 'caste',
            'city': 'city',
            'area': 'area',
            'created_at': 'created_at',
            'updated_at': 'updated_at'
        }
        
        if sort_by in sort_fields:
            order_field = sort_fields[sort_by]
            if sort_order == 'desc':
                order_field = f'-{order_field}'
            labors = labors.order_by(order_field)
        
        # Select related to avoid N+1 queries
        labors = labors.select_related('created_by')
        
        # Calculate pagination
        total_count = labors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        labors = labors[start_index:end_index]
        
        serializer = LaborListSerializer(labors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'labors': serializer.data,
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
                    'designation': designation,
                    'caste': caste,
                    'gender': gender,
                    'min_salary': min_salary,
                    'max_salary': max_salary,
                    'min_age': min_age,
                    'max_age': max_age,
                    'joined_after': joined_after,
                    'joined_before': joined_before,
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
            'message': 'Failed to retrieve labors.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_labor(request):
    """
    Create a new labor
    """
    serializer = LaborCreateSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                labor = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Labor created successfully.',
                    'data': LaborDetailSerializer(labor).data
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            error_msg = str(e)
            # If it's a unique constraint error from database, try to attribute it
            if 'unique constraint' in error_msg.lower() or 'already exists' in error_msg.lower():
                if 'cnic' in error_msg.lower():
                    return Response({
                        'success': False,
                        'message': 'A labor with this CNIC already exists.',
                        'errors': {'cnic': ['This CNIC is already in use by another labor.']}
                    }, status=status.HTTP_400_BAD_REQUEST)
                elif 'phone_number' in error_msg.lower():
                    return Response({
                        'success': False,
                        'message': 'A labor with this phone number already exists.',
                        'errors': {'phone_number': ['This phone number is already in use.']}
                    }, status=status.HTTP_400_BAD_REQUEST)
            
            return Response({
                'success': False,
                'message': 'Labor creation failed due to server error.',
                'errors': {'error': error_msg}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Labor creation failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_labor(request, labor_id):
    """
    Retrieve a specific labor by ID
    """
    try:
        labor = Labor.objects.get(id=labor_id)
        serializer = LaborDetailSerializer(labor)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Labor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Labor not found.',
            'errors': {'detail': 'Labor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Labor not found.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_labor(request, labor_id):
    """
    Update a labor
    """
    try:
        labor = Labor.objects.get(id=labor_id)
        
        serializer = LaborUpdateSerializer(
            labor,
            data=request.data,
            partial=request.method == 'PATCH'
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    labor = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Labor updated successfully.',
                        'data': LaborDetailSerializer(labor).data
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                error_msg = str(e)
                # If it's a unique constraint error from database, try to attribute it
                if 'unique constraint' in error_msg.lower() or 'already exists' in error_msg.lower():
                    if 'cnic' in error_msg.lower():
                        return Response({
                            'success': False,
                            'message': 'Another labor with this CNIC already exists.',
                            'errors': {'cnic': ['This CNIC is already in use.']}
                        }, status=status.HTTP_400_BAD_REQUEST)
                
                return Response({
                    'success': False,
                    'message': 'Labor update failed due to server error.',
                    'errors': {'error': error_msg}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Labor update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Labor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Labor not found.',
            'errors': {'detail': 'Labor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_labor(request, labor_id):
    """
    Hard delete a labor (permanently remove from database)
    """
    try:
        labor = Labor.objects.get(id=labor_id)
        
        # Store labor name for response message
        labor_name = labor.name
        
        # Check if labor has payments (optional safety check)
        # Uncomment this if you have a Payment model that references labors
        # if hasattr(labor, 'payments') and labor.payments.exists():
        #     return Response({
        #         'success': False,
        #         'message': 'Cannot delete labor as they have existing payments.',
        #         'errors': {'detail': 'This labor has payment history.'}
        #     }, status=status.HTTP_400_BAD_REQUEST)
        
        # Permanently delete the labor
        labor.delete()
        
        return Response({
            'success': True,
            'message': f'Labor "{labor_name}" deleted permanently.'
        }, status=status.HTTP_200_OK)
        
    except Labor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Labor not found.',
            'errors': {'detail': 'Labor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Labor deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def soft_delete_labor(request, labor_id):
    """
    Soft delete a labor (set is_active=False)
    """
    try:
        labor = Labor.objects.get(id=labor_id)
        
        if not labor.is_active:
            return Response({
                'success': False,
                'message': 'Labor is already inactive.',
                'errors': {'detail': 'This labor has already been soft deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        labor.soft_delete()
        
        return Response({
            'success': True,
            'message': 'Labor soft deleted successfully.'
        }, status=status.HTTP_200_OK)
        
    except Labor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Labor not found.',
            'errors': {'detail': 'Labor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Labor soft deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def restore_labor(request, labor_id):
    """
    Restore a soft-deleted labor (set is_active=True)
    """
    try:
        labor = Labor.objects.get(id=labor_id)
        
        if labor.is_active:
            return Response({
                'success': False,
                'message': 'Labor is already active.',
                'errors': {'detail': 'This labor is not deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        labor.restore()
        
        return Response({
            'success': True,
            'message': 'Labor restored successfully.',
            'data': LaborDetailSerializer(labor).data
        }, status=status.HTTP_200_OK)
        
    except Labor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Labor not found.',
            'errors': {'detail': 'Labor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Labor restoration failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_labor_contact(request, labor_id):
    """
    Update labor contact information
    """
    try:
        labor = Labor.objects.get(id=labor_id)
        
        serializer = LaborContactUpdateSerializer(
            labor,
            data=request.data,
            partial=True
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    labor = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Labor contact information updated successfully.',
                        'data': {
                            'id': str(labor.id),
                            'name': labor.name,
                            'phone_number': labor.phone_number,
                            'city': labor.city,
                            'area': labor.area
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
        
    except Labor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Labor not found.',
            'errors': {'detail': 'Labor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT'])
@permission_classes([IsAuthenticated])
def update_labor_salary(request, labor_id):
    """
    Update labor salary and designation
    """
    try:
        labor = Labor.objects.get(id=labor_id)
        
        serializer = LaborSalaryUpdateSerializer(
            labor,
            data=request.data,
            partial=True
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    old_salary = labor.salary
                    old_designation = labor.designation
                    
                    labor = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Labor salary/designation updated successfully.',
                        'data': {
                            'id': str(labor.id),
                            'name': labor.name,
                            'designation': labor.designation,
                            'old_designation': old_designation,
                            'salary': str(labor.salary),
                            'old_salary': str(old_salary)
                        }
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Salary/designation update failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Salary/designation update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Labor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Labor not found.',
            'errors': {'detail': 'Labor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


# ==================== FILTERING AND SEARCH OPERATIONS ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def labors_by_city(request, city_name):
    """
    Get labors by city
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get labors by city (case-insensitive)
        labors = Labor.active_labors().filter(city__iexact=city_name)
        labors = labors.select_related('created_by')
        
        # Calculate pagination
        total_count = labors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        labors = labors[start_index:end_index]
        
        serializer = LaborListSerializer(labors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'labors': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'city': city_name,
                'total_labors_in_city': total_count
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
            'message': 'Failed to retrieve labors by city.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def labors_by_area(request, area_name):
    """
    Get labors by area
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get labors by area (case-insensitive)
        labors = Labor.active_labors().filter(area__iexact=area_name)
        labors = labors.select_related('created_by')
        
        # Calculate pagination
        total_count = labors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        labors = labors[start_index:end_index]
        
        serializer = LaborListSerializer(labors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'labors': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'area': area_name,
                'total_labors_in_area': total_count
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
            'message': 'Failed to retrieve labors by area.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def labors_by_designation(request, designation_name):
    """
    Get labors by designation
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get labors by designation (case-insensitive)
        labors = Labor.active_labors().filter(designation__iexact=designation_name)
        labors = labors.select_related('created_by')
        
        # Calculate pagination
        total_count = labors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        labors = labors[start_index:end_index]
        
        serializer = LaborListSerializer(labors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'labors': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'designation': designation_name,
                'total_labors_with_designation': total_count
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
            'message': 'Failed to retrieve labors by designation.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_labors(request):
    """
    Search labors by name, cnic, phone, caste, designation, city, or area
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
        designation = request.GET.get('designation', '').strip()
        caste = request.GET.get('caste', '').strip()
        gender = request.GET.get('gender', '').strip()
        
        # Search labors
        labors = Labor.active_labors().search(query)
        
        # Apply additional filters
        if city:
            labors = labors.filter(city__iexact=city)
        
        if area:
            labors = labors.filter(area__iexact=area)
        
        if designation:
            labors = labors.filter(designation__iexact=designation)
        
        if caste:
            labors = labors.filter(caste__iexact=caste)
        
        if gender:
            labors = labors.filter(gender=gender)
        
        labors = labors.select_related('created_by')
        
        # Calculate pagination
        total_count = labors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        labors = labors[start_index:end_index]
        
        serializer = LaborListSerializer(labors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'labors': serializer.data,
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
                    'area': area,
                    'designation': designation,
                    'caste': caste,
                    'gender': gender
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
def new_labors(request):
    """
    Get new labors (joined within specified days)
    """
    try:
        days = int(request.GET.get('days', 30))
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get new labors
        labors = Labor.new_labors(days=days)
        labors = labors.select_related('created_by')
        
        # Calculate pagination
        total_count = labors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        labors = labors[start_index:end_index]
        
        serializer = LaborListSerializer(labors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'labors': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'days': days,
                'description': f'Labors joined within the last {days} days'
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
            'message': 'Failed to retrieve new labors.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recent_labors(request):
    """
    Get recently joined labors (last 7 days by default)
    """
    try:
        days = int(request.GET.get('days', 7))
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get recent labors
        labors = Labor.recent_labors(days=days)
        labors = labors.select_related('created_by')
        
        # Calculate pagination
        total_count = labors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        labors = labors[start_index:end_index]
        
        serializer = LaborListSerializer(labors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'labors': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'days': days,
                'description': f'Labors joined in the last {days} days'
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
            'message': 'Failed to retrieve recent labors.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ==================== ANALYTICS AND REPORTING ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def labor_statistics(request):
    """
    Get comprehensive labor statistics
    """
    try:
        stats = Labor.get_statistics()
        serializer = LaborStatsSerializer(stats)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve labor statistics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def salary_report(request):
    """
    Get salary report and analytics
    """
    try:
        # Get active labors
        labors = Labor.active_labors()
        
        # Salary statistics
        salary_stats = labors.aggregate(
            total_salary_cost=Sum('salary'),
            avg_salary=Avg('salary'),
            min_salary=Min('salary'),
            max_salary=Max('salary'),
            total_labors=Count('id')
        )
        
        # Salary breakdown by designation
        designation_salary = list(
            labors.values('designation')
            .annotate(
                count=Count('id'),
                total_salary=Sum('salary'),
                avg_salary=Avg('salary')
            )
            .order_by('-total_salary')
        )
        
        # Salary breakdown by city
        city_salary = list(
            labors.values('city')
            .annotate(
                count=Count('id'),
                total_salary=Sum('salary'),
                avg_salary=Avg('salary')
            )
            .order_by('-total_salary')
        )
        
        # Salary breakdown by gender
        gender_salary = list(
            labors.values('gender')
            .annotate(
                count=Count('id'),
                total_salary=Sum('salary'),
                avg_salary=Avg('salary')
            )
            .order_by('-total_salary')
        )
        
        # Salary ranges
        salary_ranges = {
            'under_20k': labors.filter(salary__lt=20000).count(),
            '20k_to_35k': labors.filter(salary__gte=20000, salary__lt=35000).count(),
            '35k_to_50k': labors.filter(salary__gte=35000, salary__lt=50000).count(),
            '50k_to_75k': labors.filter(salary__gte=50000, salary__lt=75000).count(),
            'above_75k': labors.filter(salary__gte=75000).count(),
        }
        
        return Response({
            'success': True,
            'data': {
                'salary_statistics': salary_stats,
                'designation_breakdown': designation_salary,
                'city_breakdown': city_salary,
                'gender_breakdown': gender_salary,
                'salary_ranges': salary_ranges,
                'generated_at': timezone.now().isoformat()
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to generate salary report.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def demographics_report(request):
    """
    Get demographics report and analytics
    """
    try:
        # Get active labors
        labors = Labor.active_labors()
        
        # Age statistics
        age_stats = labors.aggregate(
            avg_age=Avg('age'),
            min_age=Min('age'),
            max_age=Max('age'),
            total_labors=Count('id')
        )
        
        # Age groups
        age_groups = {
            '16_to_25': labors.filter(age__gte=16, age__lte=25).count(),
            '26_to_35': labors.filter(age__gte=26, age__lte=35).count(),
            '36_to_45': labors.filter(age__gte=36, age__lte=45).count(),
            '46_to_55': labors.filter(age__gte=46, age__lte=55).count(),
            'above_55': labors.filter(age__gt=55).count(),
        }
        
        # Gender breakdown
        gender_breakdown = list(
            labors.values('gender')
            .annotate(count=Count('id'))
            .order_by('gender')
        )
        
        # Caste breakdown (top 10)
        caste_breakdown = list(
            labors.exclude(caste='')
            .values('caste')
            .annotate(count=Count('id'))
            .order_by('-count')[:10]
        )
        
        # Location breakdown
        location_breakdown = list(
            labors.values('city', 'area')
            .annotate(count=Count('id'))
            .order_by('-count')[:15]
        )
        
        return Response({
            'success': True,
            'data': {
                'age_statistics': age_stats,
                'age_groups': age_groups,
                'gender_breakdown': gender_breakdown,
                'caste_breakdown': caste_breakdown,
                'location_breakdown': location_breakdown,
                'generated_at': timezone.now().isoformat()
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to generate demographics report.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ==================== BULK OPERATIONS ====================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_labor_actions(request):
    """
    Perform bulk actions on multiple labors
    """
    serializer = LaborBulkActionSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                labor_ids = serializer.validated_data['labor_ids']
                action = serializer.validated_data['action']
                
                # Get labors
                labors = Labor.objects.filter(id__in=labor_ids)
                if labors.count() != len(labor_ids):
                    return Response({
                        'success': False,
                        'message': 'Some labors were not found.',
                        'errors': {'detail': 'One or more labor IDs are invalid.'}
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                results = []
                
                # Perform action
                if action == 'activate':
                    updated_count = labors.update(is_active=True)
                    message = f'{updated_count} labors activated successfully.'
                
                elif action == 'deactivate':
                    updated_count = labors.update(is_active=False)
                    message = f'{updated_count} labors deactivated successfully.'
                
                elif action == 'update_salary':
                    salary_amount = serializer.validated_data.get('salary_amount')
                    salary_percentage = serializer.validated_data.get('salary_percentage')
                    
                    if salary_amount:
                        # Set fixed salary amount
                        updated_count = labors.update(salary=salary_amount)
                        message = f'{updated_count} labors salary updated to {salary_amount}.'
                    
                    elif salary_percentage:
                        # Apply percentage change
                        updated_count = 0
                        for labor in labors:
                            multiplier = 1 + (salary_percentage / 100)
                            new_salary = labor.salary * Decimal(str(multiplier))
                            labor.salary = new_salary.quantize(Decimal('0.01'))
                            labor.save(update_fields=['salary', 'updated_at'])
                            updated_count += 1
                        
                        message = f'{updated_count} labors salary updated by {salary_percentage}%.'
                
                # Get updated labor data
                updated_labors = Labor.objects.filter(id__in=labor_ids)
                for labor in updated_labors:
                    results.append({
                        'id': str(labor.id),
                        'name': labor.name,
                        'designation': labor.designation,
                        'salary': str(labor.salary),
                        'is_active': labor.is_active
                    })
                
                # Send custom signal
                labor_bulk_updated.send(
                    sender=Labor,
                    labors=list(updated_labors),
                    action=action
                )
                
                return Response({
                    'success': True,
                    'message': message,
                    'data': {
                        'action': action,
                        'updated_labors': results,
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
def duplicate_labor(request, labor_id):
    """
    Duplicate an existing labor (useful for creating similar labors)
    """
    try:
        original_labor = get_object_or_404(Labor, id=labor_id)
        
        # Get new data from request
        new_name = request.data.get('name')
        new_phone = request.data.get('phone_number')
        new_cnic = request.data.get('cnic')
        
        if not new_name:
            return Response({
                'success': False,
                'message': 'New labor name is required.',
                'errors': {'name': 'This field is required for duplication.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not new_phone:
            return Response({
                'success': False,
                'message': 'New labor phone is required.',
                'errors': {'phone_number': 'This field is required for duplication.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not new_cnic:
            return Response({
                'success': False,
                'message': 'New labor CNIC is required.',
                'errors': {'cnic': 'This field is required for duplication.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Create duplicate with new contact info
        with transaction.atomic():
            duplicate_data = {
                'name': new_name.strip(),
                'cnic': new_cnic.strip(),
                'phone_number': new_phone.strip(),
                'caste': original_labor.caste,
                'designation': original_labor.designation,
                'joining_date': date.today(),  # Set today as joining date
                'salary': original_labor.salary,
                'area': original_labor.area,
                'city': original_labor.city,
                'gender': original_labor.gender,
                'age': request.data.get('age', original_labor.age),
                'created_by': request.user
            }
            
            # Validate using serializer
            serializer = LaborCreateSerializer(
                data=duplicate_data,
                context={'request': request}
            )
            
            if serializer.is_valid():
                duplicate_labor = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Labor duplicated successfully.',
                    'data': LaborDetailSerializer(duplicate_labor).data
                }, status=status.HTTP_201_CREATED)
            else:
                return Response({
                    'success': False,
                    'message': 'Labor duplication failed.',
                    'errors': serializer.errors
                }, status=status.HTTP_400_BAD_REQUEST)
            
    except Labor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Labor not found.',
            'errors': {'detail': 'Labor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Labor duplication failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def labor_payments(request, labor_id):
    """
    Get labor's payment history (Advance and Regular)
    """
    try:
        labor = Labor.objects.get(id=labor_id)
        
        # Get Advance Payments
        advance_payments = AdvancePayment.objects.filter(labor=labor, is_active=True).order_by('-date', '-created_at')
        advance_serializer = AdvancePaymentListSerializer(advance_payments, many=True)
        
        # Get Regular Payments
        regular_payments = Payment.objects.filter(labor=labor, is_active=True).order_by('-date', '-created_at')
        regular_serializer = PaymentListSerializer(regular_payments, many=True)
        
        # Calculate Totals
        total_advance = advance_payments.aggregate(total=Sum('amount'))['total'] or 0
        total_payment = regular_payments.aggregate(total=Sum('amount_paid'))['total'] or 0
        
        return Response({
            'success': True,
            'message': 'Labor payments retrieved successfully.',
            'data': {
                'labor_id': str(labor.id),
                'labor_name': labor.name,
                'advance_payments': advance_serializer.data,
                'regular_payments': regular_serializer.data,
                'total_advance_amount': float(total_advance),
                'total_payments_amount': float(total_payment),
                'remaining_advance_balance': float(labor.remaining_monthly_salary), # This represents the remaining salary available
                'last_payment_date': regular_payments.first().date if regular_payments.exists() else None,
                'note': 'Payments retrieved successfully.'
            }
        }, status=status.HTTP_200_OK)
        
    except Labor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Labor not found.',
            'errors': {'detail': 'Labor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    # Add these functions to your views.py file

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def labors_by_caste(request, caste_name):
    """
    Get labors by caste
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get labors by caste (case-insensitive)
        labors = Labor.active_labors().filter(caste__iexact=caste_name)
        labors = labors.select_related('created_by')
        
        # Calculate pagination
        total_count = labors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        labors = labors[start_index:end_index]
        
        serializer = LaborListSerializer(labors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'labors': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'caste': caste_name,
                'total_labors_with_caste': total_count
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
            'message': 'Failed to retrieve labors by caste.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def labors_by_gender(request, gender):
    """
    Get labors by gender
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Validate gender
        valid_genders = ['M', 'F', 'O', 'Male', 'Female', 'Other']
        if gender not in valid_genders:
            return Response({
                'success': False,
                'message': 'Invalid gender parameter.',
                'errors': {'detail': 'Gender must be M, F, O, Male, Female, or Other.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Convert full gender names to single letter codes
        gender_map = {'Male': 'M', 'Female': 'F', 'Other': 'O'}
        gender_code = gender_map.get(gender, gender)
        
        # Get labors by gender
        labors = Labor.active_labors().filter(gender=gender_code)
        labors = labors.select_related('created_by')
        
        # Calculate pagination
        total_count = labors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        labors = labors[start_index:end_index]
        
        serializer = LaborListSerializer(labors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'labors': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'gender': gender,
                'gender_code': gender_code,
                'total_labors_with_gender': total_count
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
            'message': 'Failed to retrieve labors by gender.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def labors_by_salary_range(request):
    """
    Get labors by salary range
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get salary range parameters
        min_salary = request.GET.get('min_salary', '').strip()
        max_salary = request.GET.get('max_salary', '').strip()
        
        if not min_salary and not max_salary:
            return Response({
                'success': False,
                'message': 'At least one salary parameter is required.',
                'errors': {'detail': 'Please provide min_salary and/or max_salary parameters.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Start with active labors
        labors = Labor.active_labors()
        
        # Apply salary filters
        if min_salary:
            try:
                labors = labors.filter(salary__gte=Decimal(min_salary))
            except (ValueError, TypeError):
                return Response({
                    'success': False,
                    'message': 'Invalid min_salary value.',
                    'errors': {'min_salary': 'Must be a valid number'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        if max_salary:
            try:
                labors = labors.filter(salary__lte=Decimal(max_salary))
            except (ValueError, TypeError):
                return Response({
                    'success': False,
                    'message': 'Invalid max_salary value.',
                    'errors': {'max_salary': 'Must be a valid number'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        labors = labors.select_related('created_by')
        
        # Calculate pagination
        total_count = labors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        labors = labors[start_index:end_index]
        
        serializer = LaborListSerializer(labors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'labors': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'salary_range': {
                    'min_salary': min_salary or 'No minimum',
                    'max_salary': max_salary or 'No maximum'
                },
                'total_labors_in_range': total_count
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
            'message': 'Failed to retrieve labors by salary range.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def labors_by_age_range(request):
    """
    Get labors by age range
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get age range parameters
        min_age = request.GET.get('min_age', '').strip()
        max_age = request.GET.get('max_age', '').strip()
        
        if not min_age and not max_age:
            return Response({
                'success': False,
                'message': 'At least one age parameter is required.',
                'errors': {'detail': 'Please provide min_age and/or max_age parameters.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Start with active labors
        labors = Labor.active_labors()
        
        # Apply age filters
        if min_age:
            try:
                labors = labors.filter(age__gte=int(min_age))
            except (ValueError, TypeError):
                return Response({
                    'success': False,
                    'message': 'Invalid min_age value.',
                    'errors': {'min_age': 'Must be a valid integer'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        if max_age:
            try:
                labors = labors.filter(age__lte=int(max_age))
            except (ValueError, TypeError):
                return Response({
                    'success': False,
                    'message': 'Invalid max_age value.',
                    'errors': {'max_age': 'Must be a valid integer'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        labors = labors.select_related('created_by')
        
        # Calculate pagination
        total_count = labors.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        labors = labors[start_index:end_index]
        
        serializer = LaborListSerializer(labors, many=True)
        
        return Response({
            'success': True,
            'data': {
                'labors': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'age_range': {
                    'min_age': min_age or 'No minimum',
                    'max_age': max_age or 'No maximum'
                },
                'total_labors_in_range': total_count
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
            'message': 'Failed to retrieve labors by age range.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def experience_report(request):
    """
    Get work experience report and analytics
    """
    try:
        # Get active labors
        labors = Labor.active_labors()
        
        # Work experience statistics (in years)
        experience_stats = {}
        total_experience_days = 0
        labor_count = 0
        
        experience_data = []
        for labor in labors:
            exp_years = labor.work_experience_years
            exp_days = labor.work_experience_days
            total_experience_days += exp_days
            labor_count += 1
            
            experience_data.append({
                'labor_id': str(labor.id),
                'name': labor.name,
                'designation': labor.designation,
                'joining_date': labor.joining_date.strftime('%Y-%m-%d'),
                'experience_years': exp_years,
                'experience_days': exp_days
            })
        
        if labor_count > 0:
            avg_experience_days = total_experience_days / labor_count
            avg_experience_years = round(avg_experience_days / 365.25, 1)
        else:
            avg_experience_days = 0
            avg_experience_years = 0
        
        # Experience groups
        experience_groups = {
            'less_than_1_year': labors.filter(joining_date__gt=date.today() - timedelta(days=365)).count(),
            '1_to_2_years': labors.filter(
                joining_date__lte=date.today() - timedelta(days=365),
                joining_date__gt=date.today() - timedelta(days=730)
            ).count(),
            '2_to_5_years': labors.filter(
                joining_date__lte=date.today() - timedelta(days=730),
                joining_date__gt=date.today() - timedelta(days=1825)
            ).count(),
            '5_to_10_years': labors.filter(
                joining_date__lte=date.today() - timedelta(days=1825),
                joining_date__gt=date.today() - timedelta(days=3650)
            ).count(),
            'more_than_10_years': labors.filter(
                joining_date__lte=date.today() - timedelta(days=3650)
            ).count(),
        }
        
        # Experience by designation
        designation_experience = list(
            labors.values('designation')
            .annotate(
                count=Count('id'),
                avg_days=Avg(models.F('joining_date') - date.today()) * -1,  # Convert to positive
            )
            .order_by('-count')[:10]
        )
        
        # Process designation experience to add years
        for item in designation_experience:
            if item['avg_days']:
                item['avg_experience_years'] = round(item['avg_days'] / 365.25, 1)
            else:
                item['avg_experience_years'] = 0
        
        # Experience by city
        city_experience = list(
            labors.values('city')
            .annotate(
                count=Count('id'),
                avg_days=Avg(models.F('joining_date') - date.today()) * -1,
            )
            .order_by('-count')[:10]
        )
        
        # Process city experience to add years
        for item in city_experience:
            if item['avg_days']:
                item['avg_experience_years'] = round(item['avg_days'] / 365.25, 1)
            else:
                item['avg_experience_years'] = 0
        
        # Long-tenure labors (more than 5 years)
        long_tenure_labors = list(
            labors.filter(joining_date__lte=date.today() - timedelta(days=1825))
            .values('id', 'name', 'designation', 'joining_date', 'salary')
            .order_by('joining_date')[:20]
        )
        
        # Convert joining_date to string and add experience years
        for labor in long_tenure_labors:
            joining_date = labor['joining_date']
            exp_days = (date.today() - joining_date).days
            labor['joining_date'] = joining_date.strftime('%Y-%m-%d')
            labor['experience_years'] = round(exp_days / 365.25, 1)
            labor['id'] = str(labor['id'])  # Convert UUID to string
        
        # Retention rate calculation
        one_year_ago = date.today() - timedelta(days=365)
        labors_joined_before_one_year = labors.filter(joining_date__lte=one_year_ago).count()
        still_active_after_one_year = labors.filter(
            joining_date__lte=one_year_ago,
            is_active=True
        ).count()
        
        retention_rate = (
            (still_active_after_one_year / labors_joined_before_one_year * 100)
            if labors_joined_before_one_year > 0 else 0
        )
        
        return Response({
            'success': True,
            'data': {
                'overall_statistics': {
                    'total_labors': labor_count,
                    'average_experience_years': avg_experience_years,
                    'average_experience_days': round(avg_experience_days, 1),
                    'retention_rate_percentage': round(retention_rate, 1)
                },
                'experience_groups': experience_groups,
                'designation_experience': designation_experience,
                'city_experience': city_experience,
                'long_tenure_labors': long_tenure_labors,
                'generated_at': timezone.now().isoformat()
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to generate experience report.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
# ==================== SALARY MANAGEMENT OPERATIONS ====================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def generate_salary_slips(request):
    """
    Generate salary slips for all active active labors for a given month/year
    """
    serializer = SalaryGenerationSerializer(data=request.data)
    if not serializer.is_valid():
        return Response({
            'success': False,
            'message': 'Invalid data',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
    
    month = serializer.validated_data['month']
    year = serializer.validated_data['year']
    
    # Check if slips already exist
    existing_count = SalarySlip.objects.filter(month=month, year=year).count()
    if existing_count > 0 and not request.data.get('force', False):
        return Response({
            'success': False,
            'message': f'Salary slips for {month}/{year} already exist ({existing_count} slips). Use "force=true" to regenerate (this will delete existing unpaid slips).',
        }, status=status.HTTP_409_CONFLICT)
    
    try:
        with transaction.atomic():
            # Delete existing PENDING slips if force=true
            if request.data.get('force', False):
                SalarySlip.objects.filter(month=month, year=year, status='PENDING').delete()
            
            from advance_payments.models import AdvancePayment
            from django.db.models import Sum
            
            labors = Labor.active_labors()
            generated_slips = []
            
            # Additional bonuses/deductions from request
            bulk_deductions = Decimal(str(request.data.get('deductions', 0)))
            bulk_bonuses = Decimal(str(request.data.get('bonuses', 0)))
            
            for labor in labors:
                # Skip if slip already exists
                if SalarySlip.objects.filter(labor=labor, month=month, year=year).exists():
                    continue

                # Calculate Salary Components
                base_salary = labor.salary
                
                # Fetch total advances for THIS month and year
                month_advances = AdvancePayment.objects.filter(
                    labor=labor,
                    date__month=month,
                    date__year=year,
                    is_active=True
                ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
                
                # Incentives: fixed_incentive + bulk_bonuses
                total_bonuses = labor.fixed_incentive + bulk_bonuses
                
                slip = SalarySlip(
                    labor=labor,
                    month=month,
                    year=year,
                    base_salary=base_salary,
                    total_advances=month_advances,
                    deductions=bulk_deductions,
                    bonuses=total_bonuses,
                    created_by=request.user
                )
                slip.save()
                generated_slips.append(slip)
            
            return Response({
                'success': True,
                'message': f'Generated {len(generated_slips)} salary slips for {month}/{year}.',
                'data': SalarySlipSerializer(generated_slips, many=True).data
            }, status=status.HTTP_201_CREATED)
            
    except Exception as e:
        error_msg = str(e)
        if 'unique constraint' in error_msg.lower() or 'already exists' in error_msg.lower():
            return Response({
                'success': False,
                'message': 'Duplicate salary slip detected. Have you already generated slips for this month?',
                'errors': {'error': 'A salary slip already exists for one of the selected employees for this period.'}
            }, status=status.HTTP_409_CONFLICT)
            
        return Response({
            'success': False,
            'message': 'Failed to generate salary slips',
            'errors': {'error': error_msg}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_salary_slips(request):
    """
    List salary slips with filtering
    """
    month = request.GET.get('month')
    year = request.GET.get('year')
    status_param = request.GET.get('status')
    labor_id = request.GET.get('labor_id')
    
    queryset = SalarySlip.objects.all()
    
    if month:
        try:
            queryset = queryset.filter(month=int(month))
        except ValueError:
            pass
            
    if year:
        try:
            queryset = queryset.filter(year=int(year))
        except ValueError:
            pass
            
    if status_param: 
        queryset = queryset.filter(status=status_param.upper())
        
    if labor_id: 
        queryset = queryset.filter(labor_id=labor_id)
    
    # Pagination
    page = int(request.GET.get('page', 1))
    page_size = int(request.GET.get('page_size', 20))
    start = (page - 1) * page_size
    end = start + page_size
    
    total_count = queryset.count()
    data = queryset[start:end]
    
    serializer = SalarySlipSerializer(data, many=True)
    
    return Response({
        'success': True,
        'data': {
            'slips': serializer.data,
            'pagination': {
                'page': page,
                'page_size': page_size,
                'total_count': total_count
            }
        }
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_salary_status(request, slip_id):
    """
    Mark salary slip as PAID or PENDING
    """
    try:
        slip = SalarySlip.objects.get(id=slip_id)
        new_status = request.data.get('status', 'PAID').upper()
        
        if new_status not in ['PAID', 'PENDING']:
             return Response({'success': False, 'message': 'Invalid status'}, status=400)
             
        slip.status = new_status
        if new_status == 'PAID':
            slip.payment_date = timezone.now().date()
        else:
            slip.payment_date = None
            
        slip.save()
        
        return Response({
            'success': True,
            'message': f'Salary slip marked as {new_status}',
            'data': SalarySlipSerializer(slip).data
        })
    except SalarySlip.DoesNotExist:
        return Response({'success': False, 'message': 'Slip not found'}, status=404)
