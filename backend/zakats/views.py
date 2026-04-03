from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from datetime import datetime, timedelta
from .models import Zakat
from .serializers import (
    ZakatSerializer,
    ZakatCreateSerializer,
    ZakatUpdateSerializer,
    ZakatListSerializer,
    ZakatStatisticsSerializer,
    BulkZakatActionSerializer,
    MonthlySummarySerializer,
    BeneficiaryReportSerializer
)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def zakat_list_create(request):
    """
    GET: List all Zakat entries with filtering
    POST: Create new Zakat entry
    """
    if request.method == 'GET':
        # Check if we should show inactive records
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        
        if show_inactive:
            zakat_entries = Zakat.objects.all()  # Include inactive records
        else:
            zakat_entries = Zakat.objects.active()  # Only active records
        
        # Apply filters
        authorized_by = request.GET.get('authorized_by')
        beneficiary_name = request.GET.get('beneficiary_name')  # Match frontend parameter name
        date_from = request.GET.get('date_from')
        date_to = request.GET.get('date_to')
        search = request.GET.get('search')
        
        if authorized_by:
            zakat_entries = zakat_entries.filter(authorized_by=authorized_by)
        
        if beneficiary_name:
            zakat_entries = zakat_entries.filter(beneficiary_name__icontains=beneficiary_name)
        
        if date_from:
            try:
                date_from = datetime.strptime(date_from, '%Y-%m-%d').date()
                zakat_entries = zakat_entries.filter(date__gte=date_from)
            except ValueError:
                pass
        
        if date_to:
            try:
                date_to = datetime.strptime(date_to, '%Y-%m-%d').date()
                zakat_entries = zakat_entries.filter(date__lte=date_to)
            except ValueError:
                pass
        
        if search:
            zakat_entries = zakat_entries.filter(
                Q(name__icontains=search) |
                Q(description__icontains=search) |
                Q(beneficiary_name__icontains=search) |
                Q(notes__icontains=search)
            )
        
        # Ordering
        sort_by = request.GET.get('sort_by', 'date')
        sort_order = request.GET.get('sort_order', 'desc')
        
        # Map sort_by to actual field names
        sort_field_mapping = {
            'date': 'date',
            'amount': 'amount',
            'created_at': 'created_at',
            'beneficiary_name': 'beneficiary_name',
        }
        
        sort_field = sort_field_mapping.get(sort_by, 'date')
        if sort_order == 'asc':
            ordering = sort_field
        else:
            ordering = f'-{sort_field}'
            
        zakat_entries = zakat_entries.order_by(ordering)
        
        # Pagination
        page = int(request.GET.get('page', 1))
        page_size = int(request.GET.get('page_size', 20))
        start = (page - 1) * page_size
        end = start + page_size
        
        total_count = zakat_entries.count()
        zakat_page = zakat_entries[start:end]
        
        serializer = ZakatListSerializer(zakat_page, many=True)
        
        return Response({
            'success': True,
            'data': {
                'zakat_entries': serializer.data,
                'pagination': {
                    'page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end < total_count,
                    'has_previous': page > 1
                }
            }
        }, status=status.HTTP_200_OK)
    
    elif request.method == 'POST':
        serializer = ZakatCreateSerializer(
            data=request.data,
            context={'request': request}
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    zakat_entry = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Zakat entry created successfully.',
                        'data': ZakatSerializer(zakat_entry).data
                    }, status=status.HTTP_201_CREATED)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Zakat entry creation failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Zakat entry creation failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def zakat_detail(request, zakat_id):
    """
    Get Zakat entry details
    """
    try:
        zakat_entry = Zakat.objects.get(id=zakat_id, is_active=True)
        serializer = ZakatSerializer(zakat_entry)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Zakat.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Zakat entry not found.',
            'errors': {'detail': 'Zakat entry with this ID does not exist or is inactive.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve Zakat entry.',
            'error': str(e)
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def zakat_update(request, zakat_id):
    """
    Update Zakat entry
    """
    try:
        zakat_entry = Zakat.objects.get(id=zakat_id, is_active=True)
        
        serializer = ZakatUpdateSerializer(
            zakat_entry,
            data=request.data,
            partial=request.method == 'PATCH'
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    updated_zakat = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Zakat entry updated successfully.',
                        'data': ZakatSerializer(updated_zakat).data
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Zakat entry update failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Zakat entry update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Zakat.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Zakat entry not found.',
            'errors': {'detail': 'Zakat entry with this ID does not exist or is inactive.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Zakat entry not found.',
            'error': str(e)
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def zakat_delete(request, zakat_id):
    """
    Delete Zakat entry (soft delete)
    """
    try:
        zakat_entry = Zakat.objects.get(id=zakat_id, is_active=True)
        
        with transaction.atomic():
            zakat_entry.delete()  # This performs soft delete
            
            return Response({
                'success': True,
                'message': 'Zakat entry deleted successfully.'
            }, status=status.HTTP_200_OK)
            
    except Zakat.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Zakat entry not found.',
            'errors': {'detail': 'Zakat entry with this ID does not exist or is inactive.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to delete Zakat entry.',
            'error': str(e)
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def zakat_by_beneficiary(request, beneficiary_name):
    """
    Get Zakat entries by beneficiary name
    """
    try:
        zakat_entries = Zakat.objects.by_beneficiary(beneficiary_name)
        
        # Apply date filtering if provided
        date_from = request.GET.get('date_from')
        date_to = request.GET.get('date_to')
        
        if date_from:
            try:
                date_from = datetime.strptime(date_from, '%Y-%m-%d').date()
                zakat_entries = zakat_entries.filter(date__gte=date_from)
            except ValueError:
                pass
        
        if date_to:
            try:
                date_to = datetime.strptime(date_to, '%Y-%m-%d').date()
                zakat_entries = zakat_entries.filter(date__lte=date_to)
            except ValueError:
                pass
        
        serializer = ZakatListSerializer(zakat_entries, many=True)
        
        return Response({
            'success': True,
            'data': {
                'beneficiary_name': beneficiary_name,
                'zakat_entries': serializer.data,
                'count': len(serializer.data)
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve Zakat entries.',
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def zakat_by_date_range(request):
    """
    Get Zakat entries within date range
    """
    start_date = request.GET.get('start_date')
    end_date = request.GET.get('end_date')
    
    if not start_date or not end_date:
        return Response({
            'success': False,
            'message': 'Both start_date and end_date are required.'
        }, status=status.HTTP_400_BAD_REQUEST)
    
    try:
        start_date = datetime.strptime(start_date, '%Y-%m-%d').date()
        end_date = datetime.strptime(end_date, '%Y-%m-%d').date()
        
        if start_date > end_date:
            return Response({
                'success': False,
                'message': 'start_date cannot be greater than end_date.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        zakat_entries = Zakat.objects.by_date_range(start_date, end_date)
        serializer = ZakatListSerializer(zakat_entries, many=True)
        
        # Calculate total amount
        total_amount = sum(entry.amount for entry in zakat_entries)
        
        return Response({
            'success': True,
            'data': {
                'date_range': {
                    'start_date': start_date,
                    'end_date': end_date
                },
                'zakat_entries': serializer.data,
                'count': len(serializer.data),
                'total_amount': float(total_amount),
                'formatted_total': f"PKR {total_amount:,.2f}"
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid date format. Use YYYY-MM-DD.'
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve Zakat entries.',
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def zakat_by_authority(request, authority):
    """
    Get Zakat entries by authorization authority
    """
    try:
        # Validate authority
        valid_authorities = [choice[0] for choice in Zakat.AUTHORIZATION_CHOICES]
        if authority not in valid_authorities:
            return Response({
                'success': False,
                'message': f'Invalid authority. Must be one of: {", ".join(valid_authorities)}'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        zakat_entries = Zakat.objects.by_authority(authority)
        
        # Apply date filtering if provided
        date_from = request.GET.get('date_from')
        date_to = request.GET.get('date_to')
        
        if date_from:
            try:
                date_from = datetime.strptime(date_from, '%Y-%m-%d').date()
                zakat_entries = zakat_entries.filter(date__gte=date_from)
            except ValueError:
                pass
        
        if date_to:
            try:
                date_to = datetime.strptime(date_to, '%Y-%m-%d').date()
                zakat_entries = zakat_entries.filter(date__lte=date_to)
            except ValueError:
                pass
        
        serializer = ZakatListSerializer(zakat_entries, many=True)
        
        return Response({
            'success': True,
            'data': {
                'authority': authority,
                'zakat_entries': serializer.data,
                'count': len(serializer.data)
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve Zakat entries.',
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def zakat_statistics(request):
    """
    Get comprehensive Zakat statistics
    """
    try:
        serializer = ZakatStatisticsSerializer({})
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve statistics.',
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def monthly_summary(request):
    """
    Get monthly Zakat summary
    """
    try:
        month = request.GET.get('month', timezone.now().month)
        year = request.GET.get('year', timezone.now().year)
        
        try:
            month = int(month)
            year = int(year)
        except ValueError:
            return Response({
                'success': False,
                'message': 'Invalid month or year format.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if month < 1 or month > 12:
            return Response({
                'success': False,
                'message': 'Month must be between 1 and 12.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        serializer = MonthlySummarySerializer({'month': month, 'year': year})
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve monthly summary.',
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_actions(request):
    """
    Perform bulk actions on Zakat entries
    """
    serializer = BulkZakatActionSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            action = serializer.validated_data['action']
            zakat_ids = serializer.validated_data['zakat_ids']
            
            with transaction.atomic():
                zakat_entries = Zakat.objects.filter(id__in=zakat_ids, is_active=True)
                
                if action == 'delete':
                    for zakat_entry in zakat_entries:
                        zakat_entry.delete()  # Soft delete
                    message = f'Successfully deleted {len(zakat_entries)} Zakat entries.'
                
                elif action == 'deactivate':
                    zakat_entries.update(is_active=False)
                    message = f'Successfully deactivated {len(zakat_entries)} Zakat entries.'
                
                elif action == 'activate':
                    # For activate, we need to include inactive entries
                    zakat_entries = Zakat.objects.filter(id__in=zakat_ids)
                    zakat_entries.update(is_active=True)
                    message = f'Successfully activated {len(zakat_entries)} Zakat entries.'
                
                return Response({
                    'success': True,
                    'message': message,
                    'data': {
                        'action': action,
                        'affected_count': len(zakat_entries)
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


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def beneficiary_report(request):
    """
    Get beneficiary distribution report
    """
    try:
        beneficiary_name = request.GET.get('beneficiary_name', '')
        
        if not beneficiary_name:
            return Response({
                'success': False,
                'message': 'beneficiary_name parameter is required.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        serializer = BeneficiaryReportSerializer({'beneficiary_name': beneficiary_name})
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve beneficiary report.',
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recent_zakat(request):
    """
    Get recent Zakat entries
    """
    try:
        limit = int(request.GET.get('limit', 10))
        if limit > 100:  # Prevent excessive requests
            limit = 100
        
        zakat_entries = Zakat.objects.recent(limit)
        serializer = ZakatListSerializer(zakat_entries, many=True)
        
        return Response({
            'success': True,
            'data': {
                'zakat_entries': serializer.data,
                'count': len(serializer.data)
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve recent Zakat entries.',
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Class-based views alternative (more DRF standard)
class ZakatListCreateAPIView(generics.ListCreateAPIView):
    """Class-based view for listing and creating Zakat entries"""
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        queryset = Zakat.objects.active()
        
        # Apply filters
        authorized_by = self.request.query_params.get('authorized_by')
        beneficiary = self.request.query_params.get('beneficiary')
        date_from = self.request.query_params.get('date_from')
        date_to = self.request.query_params.get('date_to')
        search = self.request.query_params.get('search')
        
        if authorized_by:
            queryset = queryset.filter(authorized_by=authorized_by)
        
        if beneficiary:
            queryset = queryset.filter(beneficiary_name__icontains=beneficiary)
        
        if date_from:
            try:
                date_from = datetime.strptime(date_from, '%Y-%m-%d').date()
                queryset = queryset.filter(date__gte=date_from)
            except ValueError:
                pass
        
        if date_to:
            try:
                date_to = datetime.strptime(date_to, '%Y-%m-%d').date()
                queryset = queryset.filter(date__lte=date_to)
            except ValueError:
                pass
        
        if search:
            queryset = queryset.filter(
                Q(name__icontains=search) |
                Q(description__icontains=search) |
                Q(beneficiary_name__icontains=search) |
                Q(notes__icontains=search)
            )
        
        # Ordering
        ordering = self.request.query_params.get('ordering', '-date')
        queryset = queryset.order_by(ordering)
        
        return queryset
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return ZakatCreateSerializer
        return ZakatListSerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        zakat_entry = serializer.save()
        
        return Response({
            'success': True,
            'message': 'Zakat entry created successfully.',
            'data': ZakatSerializer(zakat_entry).data
        }, status=status.HTTP_201_CREATED)
    
    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        
        # Pagination
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response({
                'success': True,
                'data': serializer.data
            })
        
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'success': True,
            'data': serializer.data
        })


class ZakatDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """Class-based view for Zakat detail operations"""
    queryset = Zakat.objects.filter(is_active=True)
    permission_classes = [IsAuthenticated]
    lookup_field = 'id'
    lookup_url_kwarg = 'zakat_id'
    
    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return ZakatUpdateSerializer
        return ZakatSerializer
    
    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return Response({
            'success': True,
            'data': serializer.data
        })
    
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        updated_zakat = serializer.save()
        
        return Response({
            'success': True,
            'message': 'Zakat entry updated successfully.',
            'data': ZakatSerializer(updated_zakat).data
        })
    
    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.delete()  # Soft delete
        
        return Response({
            'success': True,
            'message': 'Zakat entry deleted successfully.'
        }, status=status.HTTP_200_OK)
    