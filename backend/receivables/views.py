from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone
from datetime import date
from .models import Receivable
from .serializers import (
    ReceivableSerializer,
    ReceivableCreateSerializer,
    ReceivableListSerializer,
    ReceivableUpdateSerializer,
    ReceivablePaymentSerializer,
    ReceivableSearchSerializer
)


# Function-based views (following existing pattern)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_receivables(request):
    """
    List all receivables with pagination and filtering
    """
    try:
        # Get query parameters
        show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
        page_size = min(int(request.GET.get('page_size', 20)), 100)  # Max 100 items per page
        page = int(request.GET.get('page', 1))
        
        # Filter receivables
        if show_inactive:
            receivables = Receivable.objects.all()
        else:
            receivables = Receivable.active_receivables()
        
        # Apply search filter if provided
        search = request.GET.get('search', '').strip()
        if search:
            receivables = receivables.search(search)
        
        # Apply status filter
        status_filter = request.GET.get('status', 'all')
        if status_filter == 'overdue':
            receivables = receivables.overdue()
        elif status_filter == 'due_today':
            receivables = receivables.due_today()
        elif status_filter == 'due_this_week':
            receivables = receivables.due_this_week()
        elif status_filter == 'fully_paid':
            receivables = receivables.fully_paid()
        elif status_filter == 'partially_paid':
            receivables = receivables.partially_paid()
        elif status_filter == 'unpaid':
            receivables = receivables.unpaid()
        
        # Apply date range filter
        date_from = request.GET.get('date_from')
        date_to = request.GET.get('date_to')
        if date_from and date_to:
            try:
                receivables = receivables.by_date_range(date_from, date_to)
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid date format. Use YYYY-MM-DD.',
                    'errors': {'detail': 'Date format must be YYYY-MM-DD.'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply expected return date range filter
        exp_from = request.GET.get('expected_return_from')
        exp_to = request.GET.get('expected_return_to')
        if exp_from and exp_to:
            try:
                receivables = receivables.by_expected_return_date_range(exp_from, exp_to)
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid date format. Use YYYY-MM-DD.',
                    'errors': {'detail': 'Date format must be YYYY-MM-DD.'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Apply amount range filter
        amount_min = request.GET.get('amount_min')
        amount_max = request.GET.get('amount_max')
        if amount_min or amount_max:
            try:
                receivables = receivables.amount_range(
                    min_amount=float(amount_min) if amount_min else None,
                    max_amount=float(amount_max) if amount_max else None
                )
            except ValueError:
                return Response({
                    'success': False,
                    'message': 'Invalid amount format.',
                    'errors': {'detail': 'Amount must be a valid number.'}
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Calculate pagination
        total_count = receivables.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        receivables = receivables[start_index:end_index]
        
        serializer = ReceivableListSerializer(receivables, many=True)
        
        return Response({
            'success': True,
            'data': {
                'receivables': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
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
            'message': 'Failed to retrieve receivables.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_receivable(request):
    """
    Create a new receivable
    """
    serializer = ReceivableCreateSerializer(
        data=request.data,
        context={'request': request}
    )
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                receivable = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Receivable created successfully.',
                    'data': ReceivableSerializer(receivable).data
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to create receivable.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    else:
        return Response({
            'success': False,
            'message': 'Invalid data provided.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_receivable(request, receivable_id):
    """
    Get a specific receivable by ID
    """
    try:
        receivable = Receivable.objects.get(id=receivable_id)
        serializer = ReceivableSerializer(receivable)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Receivable.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Receivable not found.',
            'errors': {'detail': 'Receivable with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve receivable.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_receivable(request, receivable_id):
    """
    Update a receivable
    """
    try:
        receivable = Receivable.objects.get(id=receivable_id)
        serializer = ReceivableUpdateSerializer(
            receivable,
            data=request.data,
            partial=True
        )
        
        if serializer.is_valid():
            with transaction.atomic():
                updated_receivable = serializer.save()
                
                return Response({
                    'success': True,
                    'message': 'Receivable updated successfully.',
                    'data': ReceivableSerializer(updated_receivable).data
                }, status=status.HTTP_200_OK)
        else:
            return Response({
                'success': False,
                'message': 'Invalid data provided.',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
            
    except Receivable.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Receivable not found.',
            'errors': {'detail': 'Receivable with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to update receivable.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_receivable(request, receivable_id):
    """
    Soft delete a receivable
    """
    try:
        receivable = Receivable.objects.get(id=receivable_id)
        
        with transaction.atomic():
            receivable.soft_delete()
            
            return Response({
                'success': True,
                'message': 'Receivable deleted successfully.'
            }, status=status.HTTP_200_OK)
            
    except Receivable.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Receivable not found.',
            'errors': {'detail': 'Receivable with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to delete receivable.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def record_payment(request, receivable_id):
    """
    Record a payment/return on a receivable
    """
    try:
        receivable = Receivable.objects.get(id=receivable_id)
        
        if receivable.is_fully_paid():
            return Response({
                'success': False,
                'message': 'Receivable is already fully paid.',
                'errors': {'detail': 'No remaining balance to record payment against.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        serializer = ReceivablePaymentSerializer(
            data=request.data,
            context={'receivable': receivable}
        )
        
        if serializer.is_valid():
            with transaction.atomic():
                payment_amount = serializer.validated_data['payment_amount']
                remaining_balance = receivable.record_payment(payment_amount)
                
                # Update notes if payment notes provided
                payment_notes = serializer.validated_data.get('payment_notes', '')
                if payment_notes:
                    current_notes = receivable.notes or ''
                    receivable.notes = f"{current_notes}\n\nPayment recorded on {timezone.now().strftime('%Y-%m-%d %H:%M')}: {payment_amount} PKR. {payment_notes}".strip()
                    receivable.save(update_fields=['notes', 'updated_at'])
                
                return Response({
                    'success': True,
                    'message': f'Payment of {payment_amount} PKR recorded successfully.',
                    'data': {
                        'receivable_id': receivable.id,
                        'payment_amount': payment_amount,
                        'remaining_balance': remaining_balance,
                        'is_fully_paid': receivable.is_fully_paid()
                    }
                }, status=status.HTTP_200_OK)
        else:
            return Response({
                'success': False,
                'message': 'Invalid payment data.',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
            
    except Receivable.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Receivable not found.',
            'errors': {'detail': 'Receivable with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to record payment.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def restore_receivable(request, receivable_id):
    """
    Restore a soft-deleted receivable
    """
    try:
        receivable = Receivable.objects.get(id=receivable_id)
        
        if receivable.is_active:
            return Response({
                'success': False,
                'message': 'Receivable is already active.',
                'errors': {'detail': 'Receivable is not deleted.'}
            }, status=status.HTTP_400_BAD_REQUEST)
        
        with transaction.atomic():
            receivable.restore()
            
            return Response({
                'success': True,
                'message': 'Receivable restored successfully.',
                'data': ReceivableSerializer(receivable).data
            }, status=status.HTTP_200_OK)
            
    except Receivable.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Receivable not found.',
            'errors': {'detail': 'Receivable with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to restore receivable.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def receivable_summary(request):
    """
    Get summary statistics for receivables
    """
    try:
        # Get summary data
        total_outstanding = Receivable.total_outstanding()
        total_receivables = Receivable.active_receivables().count()
        overdue_count = Receivable.overdue_receivables().count()
        due_today_count = Receivable.active_receivables().due_today().count()
        due_this_week_count = Receivable.active_receivables().due_this_week().count()
        fully_paid_count = Receivable.active_receivables().fully_paid().count()
        
        # Get recent receivables
        recent_receivables = Receivable.active_receivables().recent(days=7)
        recent_serializer = ReceivableListSerializer(recent_receivables[:5], many=True)
        
        # Get overdue receivables
        overdue_receivables = Receivable.overdue_receivables()[:5]
        overdue_serializer = ReceivableListSerializer(overdue_receivables, many=True)
        
        return Response({
            'success': True,
            'data': {
                'summary': {
                    'total_outstanding': total_outstanding,
                    'total_receivables': total_receivables,
                    'overdue_count': overdue_count,
                    'due_today_count': due_today_count,
                    'due_this_week_count': due_this_week_count,
                    'fully_paid_count': fully_paid_count
                },
                'recent_receivables': recent_serializer.data,
                'overdue_receivables': overdue_serializer.data
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve receivable summary.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def search_receivables(request):
    """
    Advanced search for receivables
    """
    try:
        serializer = ReceivableSearchSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                'success': False,
                'message': 'Invalid search parameters.',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get search parameters
        data = serializer.validated_data
        show_inactive = data.get('show_inactive', False)
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Start with base queryset
        if show_inactive:
            receivables = Receivable.objects.all()
        else:
            receivables = Receivable.active_receivables()
        
        # Apply search filters
        if data.get('search'):
            receivables = receivables.search(data['search'])
        
        if data.get('debtor_name'):
            receivables = receivables.by_debtor(data['debtor_name'])
        
        if data.get('debtor_phone'):
            receivables = receivables.by_debtor_phone(data['debtor_phone'])
        
        if data.get('date_from') and data.get('date_to'):
            receivables = receivables.by_date_range(data['date_from'], data['date_to'])
        
        if data.get('expected_return_from') and data.get('expected_return_to'):
            receivables = receivables.by_expected_return_date_range(
                data['expected_return_from'], 
                data['expected_return_to']
            )
        
        if data.get('amount_min') or data.get('amount_max'):
            receivables = receivables.amount_range(
                min_amount=data.get('amount_min'),
                max_amount=data.get('amount_max')
            )
        
        # Apply status filter
        status_filter = data.get('status', 'all')
        if status_filter == 'overdue':
            receivables = receivables.overdue()
        elif status_filter == 'due_today':
            receivables = receivables.due_today()
        elif status_filter == 'due_this_week':
            receivables = receivables.due_this_week()
        elif status_filter == 'fully_paid':
            receivables = receivables.fully_paid()
        elif status_filter == 'partially_paid':
            receivables = receivables.partially_paid()
        elif status_filter == 'unpaid':
            receivables = receivables.unpaid()
        
        # Calculate pagination
        total_count = receivables.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        receivables = receivables[start_index:end_index]
        
        serializer = ReceivableListSerializer(receivables, many=True)
        
        return Response({
            'success': True,
            'data': {
                'receivables': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                }
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to search receivables.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
