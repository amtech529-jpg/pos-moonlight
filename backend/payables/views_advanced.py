from rest_framework import status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction, models
from django.shortcuts import get_object_or_404
from django.db.models import Q, Sum, Count, Case, When
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
from .models import Payable, PayablePayment
from .serializers import (
    PayableBulkActionSerializer,
    PayableListSerializer,
    PayableStatsSerializer,
    PayableScheduleSerializer,
    CreditorSummarySerializer,
)
from .signals import payable_bulk_updated


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def overdue_payables(request):
    """
    Get all overdue payables
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get overdue payables
        payables = Payable.overdue_payables()
        payables = payables.select_related('created_by', 'vendor')
        
        # Calculate pagination
        total_count = payables.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payables = payables[start_index:end_index]
        
        serializer = PayableListSerializer(payables, many=True)
        
        # Calculate overdue amount
        overdue_amount = Payable.overdue_payables().aggregate(
            total=Sum('balance_remaining')
        )['total'] or Decimal('0.00')
        
        return Response({
            'success': True,
            'data': {
                'payables': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'total_overdue_amount': overdue_amount,
                'description': 'Payables that are past their due date'
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
            'message': 'Failed to retrieve overdue payables.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def urgent_payables(request):
    """
    Get all urgent priority payables
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get urgent payables
        payables = Payable.urgent_payables()
        payables = payables.select_related('created_by', 'vendor')
        
        # Calculate pagination
        total_count = payables.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payables = payables[start_index:end_index]
        
        serializer = PayableListSerializer(payables, many=True)
        
        # Calculate urgent amount
        urgent_amount = Payable.urgent_payables().aggregate(
            total=Sum('balance_remaining')
        )['total'] or Decimal('0.00')
        
        return Response({
            'success': True,
            'data': {
                'payables': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'total_urgent_amount': urgent_amount,
                'description': 'Payables marked as urgent priority'
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
            'message': 'Failed to retrieve urgent payables.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def payables_by_creditor(request, creditor_name):
    """
    Get payables by creditor name
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get payables by creditor (case-insensitive)
        payables = Payable.active_payables().filter(creditor_name__icontains=creditor_name)
        payables = payables.select_related('created_by', 'vendor')
        
        # Calculate pagination
        total_count = payables.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payables = payables[start_index:end_index]
        
        serializer = PayableListSerializer(payables, many=True)
        
        # Calculate totals for this creditor
        creditor_stats = Payable.active_payables().filter(
            creditor_name__icontains=creditor_name
        ).aggregate(
            total_amount=Sum('amount_borrowed'),
            total_paid=Sum('amount_paid'),
            total_outstanding=Sum('balance_remaining')
        )
        
        return Response({
            'success': True,
            'data': {
                'payables': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'creditor_name': creditor_name,
                'creditor_stats': {
                    'total_payables': total_count,
                    'total_borrowed_amount': creditor_stats['total_amount'] or Decimal('0.00'),
                    'total_paid_amount': creditor_stats['total_paid'] or Decimal('0.00'),
                    'total_outstanding_amount': creditor_stats['total_outstanding'] or Decimal('0.00')
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
            'message': 'Failed to retrieve payables by creditor.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def payables_by_vendor(request, vendor_id):
    """
    Get payables linked to a specific vendor
    """
    try:
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get payables by vendor
        payables = Payable.active_payables().filter(vendor_id=vendor_id)
        payables = payables.select_related('created_by', 'vendor')
        
        # Calculate pagination
        total_count = payables.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payables = payables[start_index:end_index]
        
        serializer = PayableListSerializer(payables, many=True)
        
        # Get vendor info
        try:
            from vendors.models import Vendor  # Adjust import as needed
            vendor = Vendor.objects.get(id=vendor_id)
            vendor_info = {
                'id': str(vendor.id),
                'name': vendor.name,
                'business_name': vendor.business_name,
                'phone': vendor.phone
            }
        except:
            vendor_info = None
        
        # Calculate totals for this vendor
        vendor_stats = Payable.active_payables().filter(vendor_id=vendor_id).aggregate(
            total_amount=Sum('amount_borrowed'),
            total_paid=Sum('amount_paid'),
            total_outstanding=Sum('balance_remaining')
        )
        
        return Response({
            'success': True,
            'data': {
                'payables': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'vendor_info': vendor_info,
                'vendor_stats': {
                    'total_payables': total_count,
                    'total_borrowed_amount': vendor_stats['total_amount'] or Decimal('0.00'),
                    'total_paid_amount': vendor_stats['total_paid'] or Decimal('0.00'),
                    'total_outstanding_amount': vendor_stats['total_outstanding'] or Decimal('0.00')
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
            'message': 'Failed to retrieve payables by vendor.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def search_payables(request):
    """
    Search payables by creditor name, reason, notes, phone, or email
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
        status_filter = request.GET.get('status', '').strip()
        priority_filter = request.GET.get('priority', '').strip()
        vendor_id = request.GET.get('vendor_id', '').strip()
        
        # Search payables
        payables = Payable.active_payables().search(query)
        
        # Apply additional filters
        if status_filter:
            payables = payables.filter(status=status_filter)
        
        if priority_filter:
            payables = payables.filter(priority=priority_filter)
        
        if vendor_id:
            payables = payables.filter(vendor_id=vendor_id)
        
        payables = payables.select_related('created_by', 'vendor')
        
        # Calculate pagination
        total_count = payables.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payables = payables[start_index:end_index]
        
        serializer = PayableListSerializer(payables, many=True)
        
        return Response({
            'success': True,
            'data': {
                'payables': serializer.data,
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
                    'status': status_filter,
                    'priority': priority_filter,
                    'vendor_id': vendor_id
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
def payable_statistics(request):
    """
    Get comprehensive payable statistics
    """
    try:
        stats = Payable.get_statistics()
        serializer = PayableStatsSerializer(stats)
        
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve payable statistics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def bulk_payable_actions(request):
    """
    Perform bulk actions on multiple payables
    """
    serializer = PayableBulkActionSerializer(data=request.data)
    
    if serializer.is_valid():
        try:
            with transaction.atomic():
                payable_ids = serializer.validated_data['payable_ids']
                action = serializer.validated_data['action']
                notes = serializer.validated_data.get('notes', '')
                
                # Get payables
                payables = Payable.objects.filter(id__in=payable_ids)
                if payables.count() != len(payable_ids):
                    return Response({
                        'success': False,
                        'message': 'Some payables were not found.',
                        'errors': {'detail': 'One or more payable IDs are invalid.'}
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                results = []
                
                # Perform action
                if action == 'activate':
                    updated_count = payables.update(is_active=True)
                    message = f'{updated_count} payables activated successfully.'
                
                elif action == 'deactivate':
                    updated_count = payables.update(is_active=False)
                    message = f'{updated_count} payables deactivated successfully.'
                
                elif action in ['mark_urgent', 'mark_high', 'mark_medium', 'mark_low']:
                    priority_map = {
                        'mark_urgent': 'URGENT',
                        'mark_high': 'HIGH',
                        'mark_medium': 'MEDIUM',
                        'mark_low': 'LOW'
                    }
                    priority = priority_map[action]
                    updated_count = payables.update(priority=priority)
                    message = f'{updated_count} payables marked as {priority.lower()} priority.'
                
                elif action == 'cancel':
                    # Cancel payables with notes
                    for payable in payables:
                        payable.cancel(notes)
                    updated_count = payables.count()
                    message = f'{updated_count} payables cancelled successfully.'
                
                # Get updated payable data
                updated_payables = Payable.objects.filter(id__in=payable_ids)
                for payable in updated_payables:
                    results.append({
                        'id': str(payable.id),
                        'creditor_name': payable.creditor_name,
                        'amount_borrowed': payable.amount_borrowed,
                        'balance_remaining': payable.balance_remaining,
                        'priority': payable.priority,
                        'status': payable.status,
                        'is_active': payable.is_active
                    })
                
                # Send custom signal
                payable_bulk_updated.send(
                    sender=Payable,
                    payables=list(updated_payables),
                    action=action
                )
                
                return Response({
                    'success': True,
                    'message': message,
                    'data': {
                        'action': action,
                        'updated_payables': results,
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


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def payment_schedule(request):
    """
    Get upcoming payment schedule
    """
    try:
        days = int(request.GET.get('days', 30))
        page_size = min(int(request.GET.get('page_size', 50)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get payables due within specified days
        payables = Payable.due_soon(days=days)
        payables = payables.select_related('vendor').order_by('expected_repayment_date')
        
        # Calculate pagination
        total_count = payables.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        paginated_payables = payables[start_index:end_index]
        
        # Transform to schedule format
        schedule_data = []
        for payable in paginated_payables:
            schedule_data.append({
                'id': payable.id,
                'creditor_name': payable.creditor_name,
                'amount_borrowed': payable.amount_borrowed,
                'balance_remaining': payable.balance_remaining,
                'expected_repayment_date': payable.expected_repayment_date,
                'priority': payable.priority,
                'status': payable.status,
                'days_until_due': payable.days_until_due,
                'is_overdue': payable.is_overdue,
                'priority_color': payable.priority_color,
                'status_color': payable.status_color
            })
        
        serializer = PayableScheduleSerializer(schedule_data, many=True)
        
        # Calculate total amount due
        total_due_amount = payables.aggregate(
            total=Sum('balance_remaining')
        )['total'] or Decimal('0.00')
        
        return Response({
            'success': True,
            'data': {
                'schedule': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'summary': {
                    'days_ahead': days,
                    'total_payables_due': total_count,
                    'total_amount_due': total_due_amount
                }
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
            'message': 'Failed to retrieve payment schedule.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def creditor_summary(request):
    """
    Get summary of all creditors with their payable totals
    """
    try:
        # Get creditor summary data
        creditor_data = Payable.active_payables().values('creditor_name').annotate(
            total_payables=Count('id'),
            total_borrowed_amount=Sum('amount_borrowed'),
            total_outstanding_amount=Sum('balance_remaining'),
            overdue_count=Sum(
                Case(
                    When(
                        expected_repayment_date__lt=timezone.now().date(),
                        is_fully_paid=False,
                        then=1
                    ),
                    default=0,
                    output_field=models.IntegerField()
                )
            ),
            overdue_amount=Sum(
                Case(
                    When(
                        expected_repayment_date__lt=timezone.now().date(),
                        is_fully_paid=False,
                        then='balance_remaining'
                    ),
                    default=Decimal('0.00'),
                    output_field=models.DecimalField(max_digits=12, decimal_places=2)
                )
            )
        ).order_by('-total_outstanding_amount')
        
        # Add contact and vendor info
        summary_data = []
        for creditor in creditor_data:
            # Get latest contact info for this creditor
            latest_payable = Payable.active_payables().filter(
                creditor_name=creditor['creditor_name']
            ).order_by('-created_at').first()
            
            contact_info = {
                'phone': latest_payable.creditor_phone if latest_payable else '',
                'email': latest_payable.creditor_email if latest_payable else ''
            }
            
            vendor_info = {}
            if latest_payable and latest_payable.vendor:
                vendor_info = {
                    'id': str(latest_payable.vendor.id),
                    'name': latest_payable.vendor.name,
                    'business_name': latest_payable.vendor.business_name
                }
            
            summary_data.append({
                'creditor_name': creditor['creditor_name'],
                'total_payables': creditor['total_payables'],
                'total_borrowed_amount': creditor['total_borrowed_amount'] or Decimal('0.00'),
                'total_outstanding_amount': creditor['total_outstanding_amount'] or Decimal('0.00'),
                'overdue_count': creditor['overdue_count'] or 0,
                'overdue_amount': creditor['overdue_amount'] or Decimal('0.00'),
                'contact_info': contact_info,
                'vendor_info': vendor_info
            })
        
        serializer = CreditorSummarySerializer(summary_data, many=True)
        
        return Response({
            'success': True,
            'data': {
                'creditors': serializer.data,
                'total_creditors': len(summary_data)
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve creditor summary.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def due_soon_payables(request):
    """
    Get payables due within specified days (default 7 days)
    """
    try:
        days = int(request.GET.get('days', 7))
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get payables due soon
        payables = Payable.due_soon(days=days)
        payables = payables.select_related('created_by', 'vendor')
        
        # Calculate pagination
        total_count = payables.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payables = payables[start_index:end_index]
        
        serializer = PayableListSerializer(payables, many=True)
        
        # Calculate total amount due soon
        due_soon_amount = Payable.due_soon(days=days).aggregate(
            total=Sum('balance_remaining')
        )['total'] or Decimal('0.00')
        
        return Response({
            'success': True,
            'data': {
                'payables': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'days_ahead': days,
                'total_due_soon_amount': due_soon_amount,
                'description': f'Payables due within the next {days} days'
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
            'message': 'Failed to retrieve due soon payables.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recent_payables(request):
    """
    Get recently created payables (last 30 days by default)
    """
    try:
        days = int(request.GET.get('days', 30))
        page_size = min(int(request.GET.get('page_size', 20)), 100)
        page = int(request.GET.get('page', 1))
        
        # Get recent payables
        payables = Payable.active_payables().recent(days=days)
        payables = payables.select_related('created_by', 'vendor')
        
        # Calculate pagination
        total_count = payables.count()
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        
        payables = payables[start_index:end_index]
        
        serializer = PayableListSerializer(payables, many=True)
        
        return Response({
            'success': True,
            'data': {
                'payables': serializer.data,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                },
                'days': days,
                'description': f'Payables created in the last {days} days'
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
            'message': 'Failed to retrieve recent payables.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    