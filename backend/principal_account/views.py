from rest_framework import status, generics, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.db.models import Q, Sum, Count
from django.utils import timezone
from decimal import Decimal, InvalidOperation
from datetime import datetime, date, timedelta
from .models import PrincipalAccount, PrincipalAccountBalance
from .serializers import (
    PrincipalAccountSerializer,
    PrincipalAccountCreateSerializer,
    PrincipalAccountUpdateSerializer,
    PrincipalAccountListSerializer,
    PrincipalAccountBalanceSerializer,
    PrincipalAccountStatisticsSerializer,
    PrincipalAccountSearchSerializer
)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def principal_account_list_create(request):
    """
    GET: List all principal account transactions with filtering
    POST: Create new principal account transaction
    """
    if request.method == 'GET':
        try:
            # Get query parameters
            show_inactive = request.GET.get('show_inactive', 'false').lower() == 'true'
            page_size = min(int(request.GET.get('page_size', 20)), 100)
            page = int(request.GET.get('page', 1))
            
            # Search and filter parameters
            search = request.GET.get('search', '').strip()
            source_module = request.GET.get('source_module', '').strip()
            transaction_type = request.GET.get('transaction_type', '').strip()
            date_from = request.GET.get('date_from', '').strip()
            date_to = request.GET.get('date_to', '').strip()
            min_amount = request.GET.get('min_amount', '').strip()
            max_amount = request.GET.get('max_amount', '').strip()
            handled_by = request.GET.get('handled_by', '').strip()
            
            # Base queryset
            if show_inactive:
                transactions = PrincipalAccount.objects.all()
            else:
                transactions = PrincipalAccount.objects.filter(is_active=True)
            
            # Apply filters
            if search:
                transactions = transactions.filter(
                    Q(description__icontains=search) |
                    Q(source_id__icontains=search) |
                    Q(notes__icontains=search)
                )
            
            if source_module:
                transactions = transactions.filter(source_module=source_module.upper())
            
            if transaction_type:
                transactions = transactions.filter(type=transaction_type.upper())
            
            if date_from:
                try:
                    date_from = datetime.strptime(date_from, '%Y-%m-%d').date()
                    transactions = transactions.filter(date__gte=date_from)
                except ValueError:
                    pass
            
            if date_to:
                try:
                    date_to = datetime.strptime(date_to, '%Y-%m-%d').date()
                    transactions = transactions.filter(date__lte=date_to)
                except ValueError:
                    pass
            
            if min_amount:
                try:
                    transactions = transactions.filter(amount__gte=Decimal(min_amount))
                except (ValueError, InvalidOperation):
                    pass
            
            if max_amount:
                try:
                    transactions = transactions.filter(amount__lte=Decimal(max_amount))
                except (ValueError, InvalidOperation):
                    pass
            
            if handled_by:
                transactions = transactions.filter(handled_by__icontains=handled_by)
            
            # Ordering
            ordering = request.GET.get('ordering', '-date')
            transactions = transactions.order_by(ordering)
            
            # Pagination
            start = (page - 1) * page_size
            end = start + page_size
            total_count = transactions.count()
            
            transactions_page = transactions[start:end]
            serializer = PrincipalAccountListSerializer(transactions_page, many=True)
            
            return Response({
                'success': True,
                'data': {
                    'transactions': serializer.data,
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
            
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to list principal account transactions.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    elif request.method == 'POST':
        try:
            with transaction.atomic():
                serializer = PrincipalAccountCreateSerializer(
                    data=request.data,
                    context={'request': request}
                )
                
                if serializer.is_valid():
                    # Get current balance
                    balance_obj, created = PrincipalAccountBalance.objects.get_or_create(
                        id=1,
                        defaults={'current_balance': Decimal('0.00')}
                    )
                    
                    # Calculate new balance
                    current_balance = balance_obj.current_balance
                    amount = serializer.validated_data['amount']
                    transaction_type = serializer.validated_data['type']
                    
                    if transaction_type == 'CREDIT':
                        new_balance = current_balance + amount
                    else:
                        new_balance = current_balance - amount
                    
                    # Update transaction data
                    transaction_data = serializer.validated_data.copy()
                    transaction_data['balance_before'] = current_balance
                    transaction_data['balance_after'] = new_balance
                    transaction_data['created_by'] = request.user
                    
                    # Create transaction
                    principal_account = PrincipalAccount.objects.create(**transaction_data)
                    
                    # Update balance
                    balance_obj.current_balance = new_balance
                    balance_obj.last_transaction_id = principal_account.id
                    balance_obj.save()
                    
                    # Return response
                    response_serializer = PrincipalAccountSerializer(principal_account)
                    return Response({
                        'success': True,
                        'message': 'Principal account transaction created successfully.',
                        'data': response_serializer.data
                    }, status=status.HTTP_201_CREATED)
                
                return Response({
                    'success': False,
                    'message': 'Failed to create principal account transaction.',
                    'errors': serializer.errors
                }, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to create principal account transaction.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def principal_account_detail(request, transaction_id):
    """
    GET: Get specific principal account transaction
    PUT: Update principal account transaction
    DELETE: Soft delete principal account transaction
    """
    try:
        principal_account = PrincipalAccount.objects.get(id=transaction_id)
        
        if request.method == 'GET':
            serializer = PrincipalAccountSerializer(principal_account)
            return Response({
                'success': True,
                'data': serializer.data
            }, status=status.HTTP_200_OK)
        
        elif request.method == 'PUT':
            serializer = PrincipalAccountUpdateSerializer(
                principal_account,
                data=request.data,
                partial=True
            )
            
            if serializer.is_valid():
                serializer.save()
                response_serializer = PrincipalAccountSerializer(principal_account)
                return Response({
                    'success': True,
                    'message': 'Principal account transaction updated successfully.',
                    'data': response_serializer.data
                }, status=status.HTTP_200_OK)
            
            return Response({
                'success': False,
                'message': 'Failed to update principal account transaction.',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
        elif request.method == 'DELETE':
            principal_account.is_active = False
            principal_account.save()
            
            return Response({
                'success': True,
                'message': 'Principal account transaction deleted successfully.'
            }, status=status.HTTP_200_OK)
            
    except PrincipalAccount.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Principal account transaction not found.',
            'errors': {'detail': 'Transaction with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to process principal account transaction.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def principal_account_balance(request):
    """Get current principal account balance"""
    try:
        balance_obj, created = PrincipalAccountBalance.objects.get_or_create(
            id=1,
            defaults={'current_balance': Decimal('0.00')}
        )
        
        serializer = PrincipalAccountBalanceSerializer(balance_obj)
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get principal account balance.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def principal_account_statistics(request):
    """Get principal account statistics and analytics"""
    try:
        # Get date range parameters
        days = int(request.GET.get('days', 30))
        end_date = date.today()
        start_date = end_date - timedelta(days=days)
        
        # Get transactions in date range
        transactions = PrincipalAccount.objects.filter(
            date__range=[start_date, end_date],
            is_active=True
        )
        
        # Calculate statistics
        total_credits = transactions.filter(type='CREDIT').aggregate(
            total=Sum('amount')
        )['total'] or Decimal('0.00')
        
        total_debits = transactions.filter(type='DEBIT').aggregate(
            total=Sum('amount')
        )['total'] or Decimal('0.00')
        
        transaction_count = transactions.count()
        
        # Get current balance
        balance_obj, created = PrincipalAccountBalance.objects.get_or_create(
            id=1,
            defaults={'current_balance': Decimal('0.00')}
        )
        current_balance = balance_obj.current_balance
        
        # Module breakdown
        module_breakdown = {}
        for transaction in transactions:
            module = transaction.source_module
            if module not in module_breakdown:
                module_breakdown[module] = {
                    'credits': Decimal('0.00'),
                    'debits': Decimal('0.00'),
                    'count': 0
                }
            
            if transaction.type == 'CREDIT':
                module_breakdown[module]['credits'] += transaction.amount
            else:
                module_breakdown[module]['debits'] += transaction.amount
            
            module_breakdown[module]['count'] += 1
        
        # Monthly trend
        monthly_trend = {}
        for i in range(days):
            current_date = end_date - timedelta(days=i)
            month_key = current_date.strftime('%Y-%m')
            
            if month_key not in monthly_trend:
                monthly_trend[month_key] = {
                    'credits': Decimal('0.00'),
                    'debits': Decimal('0.00'),
                    'balance': Decimal('0.00')
                }
            
            day_transactions = transactions.filter(date=current_date)
            day_credits = day_transactions.filter(type='CREDIT').aggregate(
                total=Sum('amount')
            )['total'] or Decimal('0.00')
            
            day_debits = day_transactions.filter(type='DEBIT').aggregate(
                total=Sum('amount')
            )['total'] or Decimal('0.00')
            
            monthly_trend[month_key]['credits'] += day_credits
            monthly_trend[month_key]['debits'] += day_debits
            monthly_trend[month_key]['balance'] = day_credits - day_debits
        
        # Recent transactions
        recent_transactions = transactions.order_by('-date', '-time')[:10]
        recent_serializer = PrincipalAccountListSerializer(recent_transactions, many=True)
        
        # Prepare statistics data
        stats_data = {
            'total_credits': float(total_credits),
            'total_debits': float(total_debits),
            'current_balance': float(current_balance),
            'transaction_count': transaction_count,
            'module_breakdown': module_breakdown,
            'monthly_trend': monthly_trend,
            'recent_transactions': recent_serializer.data
        }
        
        return Response({
            'success': True,
            'data': stats_data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get principal account statistics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_transaction_from_module(request):
    """
    Create principal account transaction from other modules
    This is called by other modules to record financial transactions
    """
    try:
        with transaction.atomic():
            serializer = PrincipalAccountCreateSerializer(
                data=request.data,
                context={'request': request}
            )
            
            if serializer.is_valid():
                # Get current balance
                balance_obj, created = PrincipalAccountBalance.objects.get_or_create(
                    id=1,
                    defaults={'current_balance': Decimal('0.00')}
                )
                
                # Calculate new balance
                current_balance = balance_obj.current_balance
                amount = serializer.validated_data['amount']
                transaction_type = serializer.validated_data['type']
                
                if transaction_type == 'CREDIT':
                    new_balance = current_balance + amount
                else:
                    new_balance = current_balance - amount
                
                # Update transaction data
                transaction_data = serializer.validated_data.copy()
                transaction_data['balance_before'] = current_balance
                transaction_data['balance_after'] = new_balance
                transaction_data['created_by'] = request.user
                
                # Create transaction
                principal_account = PrincipalAccount.objects.create(**transaction_data)
                
                # Update balance
                balance_obj.current_balance = new_balance
                balance_obj.last_transaction_id = principal_account.id
                balance_obj.save()
                
                return Response({
                    'success': True,
                    'message': 'Transaction recorded successfully.',
                    'data': {
                        'transaction_id': str(principal_account.id),
                        'new_balance': new_balance
                    }
                }, status=status.HTTP_201_CREATED)
            
            return Response({
                'success': False,
                'message': 'Failed to record transaction.',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to record transaction.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

