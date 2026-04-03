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
from .models import AdvancePayment
from labors.models import Labor
from .serializers import (
    AdvancePaymentBulkActionSerializer,
    AdvancePaymentSerializer,
    AdvancePaymentCreateSerializer,
    AdvancePaymentListSerializer,
    AdvancePaymentStatsSerializer,
    AdvancePaymentUpdateSerializer,
    AdvancePaymentDetailSerializer,
    AdvancePaymentFilterSerializer,
    LaborAdvanceSummarySerializer,
)
from .signals import advance_payment_bulk_updated


# ==================== BASIC CRUD OPERATIONS ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_advance_payments(request):
    """
    List all advance payments with pagination, search, and filtering
    """
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Search parameters
        search = request.GET.get('search', '').strip()
        labor_name = request.GET.get('labor_name', '').strip()
        labor_role = request.GET.get('labor_role', '').strip()
        labor_phone = request.GET.get('labor_phone', '').strip()
        
        # Amount range filters
        min_amount = request.GET.get('min_amount', '').strip()
        max_amount = request.GET.get('max_amount', '').strip()
        
        # Date range filters
        date_from = request.GET.get('date_from', '').strip()
        date_to = request.GET.get('date_to', '').strip()
        
        # Receipt filter
        has_receipt = request.GET.get('has_receipt', '').strip()
        
        # Sorting
        sort_by = request.GET.get('sort_by', 'date')  # date, amount, labor_name, created_at
        sort_order = request.GET.get('sort_order', 'desc')  # asc, desc
        
        # Base queryset
        if show_inactive:
            payments = AdvancePayment.objects.all()
        else:
            payments = AdvancePayment.objects.filter(is_active=True)
        
        # Apply search filter
        if search:
            payments = payments.search(search)
        
        # Apply filters
        if labor_name:
            payments = payments.filter(labor_name__icontains=labor_name)
        
        if labor_role:
            payments = payments.filter(labor_role__icontains=labor_role)
        
        if labor_phone:
            payments = payments.filter(labor_phone__icontains=labor_phone)
        
        # Apply amount range filters
        if min_amount:
            try:
                payments = payments.filter(amount__gte=Decimal(min_amount))
            except (ValueError, TypeError):
                return Response({
                    'success': False,
                    'message': 'Invalid min_amount value.',
                    'errors': {'min_amount': 'Must be a valid number'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        if max_amount:
            try:
                payments = payments.filter(amount__lte=Decimal(max_amount))
            except (ValueError, TypeError):
                return Response({
                    'success': False,
                    'message': 'Invalid max_amount value.',
                    'errors': {'max_amount': 'Must be a valid number'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply date range filters
        if date_from:
            try:
                payments = payments.filter(date__gte=date_from)
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid date_from format. Use YYYY-MM-DD.',
                    'errors': {'date_from': 'Invalid date format'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        if date_to:
            try:
                payments = payments.filter(date__lte=date_to)
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid date_to format. Use YYYY-MM-DD.',
                    'errors': {'date_to': 'Invalid date format'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply receipt filter
        if has_receipt.lower() == 'true':
            payments = payments.exclude(receipt_image_path='')
        elif has_receipt.lower() == 'false':
            payments = payments.filter(receipt_image_path='')
        
        # Apply sorting
        sort_fields = {
            'date': 'date',
            'amount': 'amount',
            'labor_name': 'labor_name',
            'labor_role': 'labor_role',
            'created_at': 'created_at',
            'updated_at': 'updated_at'
        }
        
        if sort_by in sort_fields:
            order_field = sort_fields[sort_by]
            if sort_order == 'desc':
                order_field = f'-{order_field}'
            payments = payments.order_by(order_field, '-time')
        
        # Select related to avoid N+1 queries
        payments = payments.select_related('labor', 'created_by')
        
        # Calculate pagination
        total_count = payments.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payments = payments[start_index:end_index]
        
        serializer = AdvancePaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'data': {
                'advance_payments': serializer.data,
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
                    'labor_name': labor_name,
                    'labor_role': labor_role,
                    'labor_phone': labor_phone,
                    'min_amount': min_amount,
                    'max_amount': max_amount,
                    'date_from': date_from,
                    'date_to': date_to,
                    'has_receipt': has_receipt,
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
            'message': 'Failed to retrieve advance payments.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_advance_payment(request):
    """
    Create a new advance payment
    """
    serializer = AdvancePaymentCreateSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                advance_payment = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Advance payment created successfully.',
                    'data': AdvancePaymentDetailSerializer(advance_payment).data
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Advance payment creation failed due to server error.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return Response({
        'success': False,
        'message': 'Advance payment creation failed.',
        'errors': serializer.errors
    }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_advance_payment(request, payment_id):
    """
    Retrieve a specific advance payment by ID
    """
    try:
        payment = AdvancePayment.objects.get(id=payment_id)
        serializer = AdvancePaymentDetailSerializer(payment)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Advance payment not found.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_advance_payment(request, payment_id):
    """
    Update an advance payment
    """
    try:
        payment = AdvancePayment.objects.get(id=payment_id)
        
        serializer = AdvancePaymentUpdateSerializer(
            payment,
            data=request.data,
            partial=request.method == 'PATCH'
        )
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    payment = serializer.save()
                    
                    return Response({
                        'success': True,
                        'message': 'Advance payment updated successfully.',
                        'data': AdvancePaymentDetailSerializer(payment).data
                    }, status=status.HTTP_200_OK)
                    
            except Exception as e:
                return Response({
                    'success': False,
                    'message': 'Advance payment update failed due to server error.',
                    'errors': {'detail': str(e)}
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        return Response({
            'success': False,
            'message': 'Advance payment update failed.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except AdvancePayment.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Advance payment not found.',
            'errors': {'detail': 'Advance payment with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_advance_payment(request, payment_id):
    """
    Hard delete an advance payment (permanently remove from database)
    """
    try:
        payment = AdvancePayment.objects.get(id=payment_id)
        
        # Store payment details for response message
        payment_info = f"{payment.labor_name} - {payment.amount} PKR ({payment.date})"
        
        # Permanently delete the payment
        payment.delete()
        
        return Response({
            'success': True,
            'message': f'Advance payment "{payment_info}" deleted permanently.'
        }, status=status.HTTP_200_OK)
        
    except AdvancePayment.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Advance payment not found.',
            'errors': {'detail': 'Advance payment with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Advance payment deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def soft_delete_advance_payment(request, payment_id):
    """
    Soft delete an advance payment (set is_active=False)
    """
    try:
        payment = AdvancePayment.objects.get(id=payment_id)
        
        if not payment.is_active:
            return Response({
                'success': False,
                'message': 'Advance payment is already inactive.',
                'errors': {'detail': 'This advance payment has already been soft deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        payment.soft_delete()
        
        return Response({
            'success': True,
            'message': 'Advance payment soft deleted successfully.'
        }, status=status.HTTP_200_OK)
        
    except AdvancePayment.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Advance payment not found.',
            'errors': {'detail': 'Advance payment with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Advance payment soft deletion failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def restore_advance_payment(request, payment_id):
    """
    Restore a soft-deleted advance payment (set is_active=True)
    """
    try:
        payment = AdvancePayment.objects.get(id=payment_id)
        
        if payment.is_active:
            return Response({
                'success': False,
                'message': 'Advance payment is already active.',
                'errors': {'detail': 'This advance payment is not deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        payment.restore()
        
        return Response({
            'success': True,
            'message': 'Advance payment restored successfully.',
            'data': AdvancePaymentDetailSerializer(payment).data
        }, status=status.HTTP_200_OK)
        
    except AdvancePayment.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Advance payment not found.',
            'errors': {'detail': 'Advance payment with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Advance payment restoration failed.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ==================== FILTERING AND SEARCH OPERATIONS ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def payments_by_labor(request, labor_id):
    """
    Get advance payments for a specific labor
    """
    try:
        # Verify labor exists
        labor = Labor.objects.get(id=labor_id)
        
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get payments for this labor
        payments = AdvancePayment.objects.filter(labor_id=labor_id, is_active=True)
        payments = payments.select_related('created_by')
        
        # Calculate pagination
        total_count = payments.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payments = payments[start_index:end_index]
        
        serializer = AdvancePaymentListSerializer(payments, many=True)
        
        # Get labor advance summary
        summary = AdvancePayment.get_labor_advance_summary(labor_id)
        
        return Response({
            'success': True,
            'data': {
                'advance_payments': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'labor': {
                    'id': str(labor.id),
                    'name': labor.name,
                    'designation': labor.designation,
                    'salary': str(labor.salary)
                },
                'summary': summary
            }
        }, status=status.HTTP_200_OK)
        
    except Labor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Labor not found.',
            'errors': {'detail': 'Labor with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid pagination parameters.',
            'errors': {'detail': 'Page and page_size must be valid integers.'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve advance payments for labor.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def payments_by_date_range(request):
    """
    Get advance payments within a date range
    """
    try:
        date_from = request.GET.get('date_from')
        date_to = request.GET.get('date_to')
        
        if not date_from or not date_to:
            return Response({
                'success': False,
                'message': 'Both date_from and date_to parameters are required.',
                'errors': {'detail': 'Please provide date_from and date_to in YYYY-MM-DD format.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get payments within date range
        payments = AdvancePayment.objects.filter(
            date__range=[date_from, date_to],
            is_active=True
        )
        payments = payments.select_related('labor', 'created_by')
        
        # Calculate pagination
        total_count = payments.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payments = payments[start_index:end_index]
        
        serializer = AdvancePaymentListSerializer(payments, many=True)
        
        # Calculate total amount for the period
        total_amount = AdvancePayment.objects.filter(
            date__range=[date_from, date_to],
            is_active=True
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        
        return Response({
            'success': True,
            'data': {
                'advance_payments': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'date_range': {
                    'from': date_from,
                    'to': date_to
                },
                'total_amount': str(total_amount),
                'summary': {
                    'total_payments': total_count,
                    'total_amount': str(total_amount),
                    'average_amount': str(total_amount / total_count if total_count > 0 else 0)
                }
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError as e:
        return Response({
            'success': False,
            'message': 'Invalid date format or pagination parameters.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve advance payments by date range.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_advance_payments(request):
    """
    Search advance payments by labor name, phone, role, or description
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
        date_from = request.GET.get('date_from', '').strip()
        date_to = request.GET.get('date_to', '').strip()
        min_amount = request.GET.get('min_amount', '').strip()
        max_amount = request.GET.get('max_amount', '').strip()
        
        # Search payments
        payments = AdvancePayment.objects.filter(is_active=True).search(query)
        
        # Apply additional filters
        if date_from:
            payments = payments.filter(date__gte=date_from)
        
        if date_to:
            payments = payments.filter(date__lte=date_to)
        
        if min_amount:
            try:
                payments = payments.filter(amount__gte=Decimal(min_amount))
            except (ValueError, TypeError):
                return Response({
                    'success': False,
                    'message': 'Invalid min_amount value.',
                    'errors': {'min_amount': 'Must be a valid number'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        if max_amount:
            try:
                payments = payments.filter(amount__lte=Decimal(max_amount))
            except (ValueError, TypeError):
                return Response({
                    'success': False,
                    'message': 'Invalid max_amount value.',
                    'errors': {'max_amount': 'Must be a valid number'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        payments = payments.select_related('labor', 'created_by')
        
        # Calculate pagination
        total_count = payments.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payments = payments[start_index:end_index]
        
        serializer = AdvancePaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'data': {
                'advance_payments': serializer.data,
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
                    'date_from': date_from,
                    'date_to': date_to,
                    'min_amount': min_amount,
                    'max_amount': max_amount
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
def today_payments(request):
    """
    Get today's advance payments
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get today's payments
        payments = AdvancePayment.objects.today().filter(is_active=True)
        payments = payments.select_related('labor', 'created_by')
        
        # Calculate pagination
        total_count = payments.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payments = payments[start_index:end_index]
        
        serializer = AdvancePaymentListSerializer(payments, many=True)
        
        # Calculate today's total
        today_total = AdvancePayment.objects.today().filter(is_active=True).aggregate(
            total=Sum('amount')
        )['total'] or Decimal('0.00')
        
        return Response({
            'success': True,
            'data': {
                'advance_payments': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'date': date.today().isoformat(),
                'summary': {
                    'total_payments': total_count,
                    'total_amount': str(today_total)
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
            'message': 'Failed to retrieve today\'s advance payments.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recent_payments(request):
    """
    Get recent advance payments (last 7 days by default)
    """
    try:
        days = int(request.GET.get('days', 7))
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get recent payments
        payments = AdvancePayment.objects.recent(days=days).filter(is_active=True)
        payments = payments.select_related('labor', 'created_by')
        
        # Calculate pagination
        total_count = payments.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payments = payments[start_index:end_index]
        
        serializer = AdvancePaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'data': {
                'advance_payments': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'days': days,
                'description': f'Advance payments from the last {days} days'
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
            'message': 'Failed to retrieve recent advance payments.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ==================== ANALYTICS AND REPORTING ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def advance_payment_statistics(request):
    """
    Get comprehensive advance payment statistics
    """
    try:
        stats = AdvancePayment.get_statistics()
        serializer = AdvancePaymentStatsSerializer(stats)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve advance payment statistics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def monthly_report(request):
    """
    Get monthly advance payment report
    """
    try:
        year = int(request.GET.get('year', date.today().year))
        month = int(request.GET.get('month', date.today().month))
        
        # Get monthly payments
        payments = AdvancePayment.objects.filter(
            date__year=year,
            date__month=month,
            is_active=True
        )
        
        # Monthly statistics
        monthly_stats = payments.aggregate(
            total_payments=Count('id'),
            total_amount=Sum('amount'),
            avg_amount=Avg('amount'),
            min_amount=Min('amount'),
            max_amount=Max('amount')
        )
        
        # Daily breakdown
        daily_breakdown = list(
            payments.values('date')
            .annotate(
                payment_count=Count('id'),
                daily_amount=Sum('amount')
            )
            .order_by('date')
        )
        
        # Labor breakdown
        labor_breakdown = list(
            payments.values('labor_name', 'labor_role')
            .annotate(
                payment_count=Count('id'),
                total_amount=Sum('amount')
            )
            .order_by('-total_amount')[:15]
        )
        
        # Top payment days
        top_days = list(
            payments.values('date')
            .annotate(daily_total=Sum('amount'))
            .order_by('-daily_total')[:10]
        )
        
        return Response({
            'success': True,
            'data': {
                'month': f"{year}-{month:02d}",
                'monthly_statistics': monthly_stats,
                'daily_breakdown': daily_breakdown,
                'labor_breakdown': labor_breakdown,
                'top_payment_days': top_days,
                'generated_at': timezone.now().isoformat()
            }
        }, status=status.HTTP_200_OK)
        
    except ValueError:
        return Response({
            'success': False,
            'message': 'Invalid year or month parameter.',
            'errors': {'detail': 'Year and month must be valid integers.'}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to generate monthly report.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def labor_advance_report(request):
    """
    Get advance payment report by labor
    """
    try:
        # Get active labors with advance payments
        labors_with_advances = Labor.objects.filter(
            advance_payments__is_active=True,
            is_active=True
        ).distinct()
        
        labor_report = []
        
        for labor in labors_with_advances:
            summary = AdvancePayment.get_labor_advance_summary(labor.id)
            labor_report.append({
                'labor_id': str(labor.id),
                'labor_name': labor.name,
                'labor_role': labor.designation,
                'labor_salary': str(labor.salary),
                'total_advances': str(summary['total_advances']),
                'payment_count': summary['payment_count'],
                'last_payment_date': summary['last_payment_date'],
                'this_month_advances': str(summary['this_month_advances']),
                'advance_percentage': round(
                    (summary['total_advances'] / labor.salary * 100) 
                    if labor.salary > 0 else 0, 2
                )
            })
        
        # Sort by total advances (descending)
        labor_report.sort(key=lambda x: float(x['total_advances']), reverse=True)
        
        # Calculate totals
        total_advances = sum(float(item['total_advances']) for item in labor_report)
        total_payments = sum(item['payment_count'] for item in labor_report)
        
        return Response({
            'success': True,
            'data': {
                'labor_advance_report': labor_report,
                'summary': {
                    'total_labors_with_advances': len(labor_report),
                    'total_advance_amount': total_advances,
                    'total_payments': total_payments,
                    'average_advance_per_labor': total_advances / len(labor_report) if labor_report else 0
                },
                'generated_at': timezone.now().isoformat()
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to generate labor advance report.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# ==================== BULK OPERATIONS ====================

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_advance_payment_actions(request):
    """
    Perform bulk actions on multiple advance payments
    """
    serializer = AdvancePaymentBulkActionSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                payment_ids = serializer.validated_data['payment_ids']
                action = serializer.validated_data['action']
                
                # Get payments
                payments = AdvancePayment.objects.filter(id__in=payment_ids)
                if payments.count() != len(payment_ids):
                    return Response({
                        'success': False,
                        'message': 'Some advance payments were not found.',
                        'errors': {'detail': 'One or more payment IDs are invalid.'}
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                results = []
                
                # Perform action
                if action == 'activate':
                    updated_count = payments.update(is_active=True)
                    message = f'{updated_count} advance payments activated successfully.'
                
                elif action == 'deactivate':
                    updated_count = payments.update(is_active=False)
                    message = f'{updated_count} advance payments deactivated successfully.'
                
                elif action == 'delete':
                    payment_info = [f"{p.labor_name} - {p.amount} PKR" for p in payments]
                    payments.delete()
                    message = f'{len(payment_info)} advance payments deleted permanently.'
                    
                    return Response({
                        'success': True,
                        'message': message,
                        'data': {
                            'action': action,
                            'deleted_payments': payment_info,
                            'total_deleted': len(payment_info)
                        }
                    }, status=status.HTTP_200_OK)
                
                # Get updated payment data for activate/deactivate
                updated_payments = AdvancePayment.objects.filter(id__in=payment_ids)
                for payment in updated_payments:
                    results.append({
                        'id': str(payment.id),
                        'labor_name': payment.labor_name,
                        'amount': str(payment.amount),
                        'date': payment.date.isoformat(),
                        'is_active': payment.is_active
                    })
                
                # Send custom signal
                advance_payment_bulk_updated.send(
                    sender=AdvancePayment,
                    payments=list(updated_payments),
                    action=action
                )
                
                return Response({
                    'success': True,
                    'message': message,
                    'data': {
                        'action': action,
                        'updated_payments': results,
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


# ==================== UTILITY OPERATIONS ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def payments_with_receipts(request):
    """
    Get advance payments that have receipt images
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get payments with receipts
        payments = AdvancePayment.objects.with_receipts().filter(is_active=True)
        payments = payments.select_related('labor', 'created_by')
        
        # Calculate pagination
        total_count = payments.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payments = payments[start_index:end_index]
        
        serializer = AdvancePaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'data': {
                'advance_payments': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'description': 'Advance payments with receipt images'
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
            'message': 'Failed to retrieve payments with receipts.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def payments_without_receipts(request):
    """
    Get advance payments that don't have receipt images
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get payments without receipts
        payments = AdvancePayment.objects.without_receipts().filter(is_active=True)
        payments = payments.select_related('labor', 'created_by')
        
        # Calculate pagination
        total_count = payments.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payments = payments[start_index:end_index]
        
        serializer = AdvancePaymentListSerializer(payments, many=True)
        
        return Response({
            'success': True,
            'data': {
                'advance_payments': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'description': 'Advance payments without receipt images'
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
            'message': 'Failed to retrieve payments without receipts.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def labor_advance_summary(request, labor_id):
    """
    Get advance payment summary for a specific labor
    """
    try:
        # Verify labor exists
        labor = get_object_or_404(Labor, id=labor_id)
        
        # Get advance summary
        summary = AdvancePayment.get_labor_advance_summary(labor_id)
        
        # Add labor details
        summary.update({
            'labor_id': str(labor.id),
            'labor_name': labor.name,
            'labor_role': labor.designation,
            'current_salary': labor.salary,
            'remaining_salary_balance': labor.salary - summary['this_month_advances']
        })
        
        serializer = LaborAdvanceSummarySerializer(summary)
        
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
            'message': 'Failed to retrieve labor advance summary.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    