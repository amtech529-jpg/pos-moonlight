from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.db.models import Q, Sum
from django.utils import timezone
from datetime import datetime, timedelta, date
from decimal import Decimal
from .models import Expense
from .serializers import (
    ExpenseSerializer,
    ExpenseCreateSerializer,
    ExpenseUpdateSerializer,
    ExpenseListSerializer,
    ExpenseStatisticsSerializer,
    MonthlySummarySerializer
)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def expenses_list_create(request):
    """
    GET: List all expenses with filtering
    POST: Create new expense
    """
    if request.method == 'GET':
        try:
            expenses = Expense.objects.active()
            
            # Apply filters
            withdrawal_by = request.GET.get('withdrawal_by')
            category = request.GET.get('category')
            date_from = request.GET.get('date_from')
            date_to = request.GET.get('date_to')
            search = request.GET.get('search')
            
            if withdrawal_by:
                expenses = expenses.filter(withdrawal_by=withdrawal_by)
            
            if category:
                expenses = expenses.filter(category=category)
            
            if date_from:
                try:
                    date_from = datetime.strptime(date_from, '%Y-%m-%d').date()
                    expenses = expenses.filter(date__gte=date_from)
                except ValueError:
                    pass
            
            if date_to:
                try:
                    date_to = datetime.strptime(date_to, '%Y-%m-%d').date()
                    expenses = expenses.filter(date__lte=date_to)
                except ValueError:
                    pass
            
            if search:
                expenses = expenses.filter(
                    Q(expense__icontains=search) |
                    Q(description__icontains=search) |
                    Q(category__icontains=search) |
                    Q(notes__icontains=search)
                )
            
            # Ordering
            ordering = request.GET.get('ordering', '-date')
            expenses = expenses.order_by(ordering)
            
            # Pagination
            page = int(request.GET.get('page', 1))
            page_size = int(request.GET.get('page_size', 20))
            start = (page - 1) * page_size
            end = start + page_size
            
            total_count = expenses.count()
            expenses_page = expenses[start:end]
            
            serializer = ExpenseListSerializer(expenses_page, many=True)
            
            return Response({
                'success': True,
                'data': {
                    'expenses': serializer.data,
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
                'message': 'Failed to list expenses.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    elif request.method == 'POST':
        try:
            serializer = ExpenseCreateSerializer(
                data=request.data,
                context={'request': request}
            )
            
            if serializer.is_valid():
                # Create expense first (outside of Principal Account transaction)
                expense = serializer.save(created_by=request.user)
                
                # AdvancePayment creation is handled by ExpenseCreateSerializer.create
                
                # Try to update Principal Account (but don't fail if it errors)
                try:
                    from principal_account.models import PrincipalAccount, PrincipalAccountBalance
                    
                    with transaction.atomic():
                        # Get current balance
                        balance_obj, created = PrincipalAccountBalance.objects.get_or_create(
                            id=1,
                            defaults={'current_balance': Decimal('0.00')}
                        )
                        
                        # Calculate new balance
                        current_balance = balance_obj.current_balance
                        amount = expense.amount
                        new_balance = current_balance - amount  # Expense is a debit
                        
                        # Create principal account transaction
                        PrincipalAccount.objects.create(
                            date=expense.date,
                            time=expense.time,
                            source_module='EXPENSES',
                            source_id=str(expense.id),
                            description=f"Expense: {expense.expense} - {expense.description}",
                            type='DEBIT',
                            amount=amount,
                            balance_before=current_balance,
                            balance_after=new_balance,
                            handled_by=expense.withdrawal_by,
                            notes=expense.notes,
                            created_by=request.user
                        )
                        
                        # Update balance
                        balance_obj.current_balance = new_balance
                        balance_obj.save()
                        
                except Exception as e:
                    # Log the error but don't fail the expense creation
                    print(f"Principal Account update failed: {e}")
                
                response_serializer = ExpenseSerializer(expense)
                return Response({
                    'success': True,
                    'message': 'Expense created successfully.',
                    'data': response_serializer.data
                }, status=status.HTTP_201_CREATED)
                
            return Response({
                'success': False,
                'message': 'Failed to create expense.',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            return Response({
                'success': False,
                'message': 'Failed to create expense.',
                'errors': {'detail': str(e)}
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        

@api_view(['GET', 'DELETE'])
@permission_classes([IsAuthenticated])
def expense_detail(request, expense_id):
    """
    GET: Get specific expense
    DELETE: Soft delete expense
    """
    try:
        expense = Expense.objects.get(id=expense_id)
        
        if request.method == 'GET':
            serializer = ExpenseSerializer(expense)
            return Response({
                'success': True,
                'data': serializer.data
            }, status=status.HTTP_200_OK)
        
        elif request.method == 'DELETE':
            # Use the model's soft delete method
            expense.delete()
            
            return Response({
                'success': True,
                'message': 'Expense deleted successfully.'
            }, status=status.HTTP_200_OK)
            
    except Expense.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Expense not found.',
            'errors': {'detail': 'Expense with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to process expense.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def expense_statistics(request):
    """Get expense statistics and analytics"""
    try:
        # Get date range parameters
        days = int(request.GET.get('days', 30))
        end_date = date.today()
        start_date = end_date - timedelta(days=days)
        
        # Get expenses in date range
        expenses = Expense.objects.filter(
            date__range=[start_date, end_date],
            is_active=True
        )
        
        # Calculate statistics
        total_amount = expenses.aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        expense_count = expenses.count()
        
        # Category breakdown
        category_breakdown = {}
        for expense in expenses:
            category = expense.category or 'Uncategorized'
            if category not in category_breakdown:
                category_breakdown[category] = {
                    'amount': Decimal('0.00'),
                    'count': 0
                }
            category_breakdown[category]['amount'] += expense.amount
            category_breakdown[category]['count'] += 1
        
        # Person breakdown
        person_breakdown = {}
        for expense in expenses:
            person = expense.withdrawal_by
            if person not in person_breakdown:
                person_breakdown[person] = {
                    'amount': Decimal('0.00'),
                    'count': 0
                }
            person_breakdown[person]['amount'] += expense.amount
            person_breakdown[person]['count'] += 1
        
        # Monthly trend
        monthly_trend = {}
        for i in range(days):
            current_date = end_date - timedelta(days=i)
            month_key = current_date.strftime('%Y-%m')
            
            if month_key not in monthly_trend:
                monthly_trend[month_key] = {
                    'amount': Decimal('0.00'),
                    'count': 0
                }
            
            day_expenses = expenses.filter(date=current_date)
            day_amount = day_expenses.aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
            day_count = day_expenses.count()
            
            monthly_trend[month_key]['amount'] += day_amount
            monthly_trend[month_key]['count'] += day_count
        
        # Recent expenses
        recent_expenses = expenses.order_by('-date', '-time')[:10]
        recent_serializer = ExpenseListSerializer(recent_expenses, many=True)
        
        # Prepare statistics data
        stats_data = {
            'total_amount': total_amount,
            'expense_count': expense_count,
            'category_breakdown': category_breakdown,
            'person_breakdown': person_breakdown,
            'monthly_trend': monthly_trend,
            'recent_expenses': recent_serializer.data
        }
        
        serializer = ExpenseStatisticsSerializer(stats_data)
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get expense statistics.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def expense_monthly_summary(request):
    """Get monthly expense summary"""
    try:
        year = int(request.GET.get('year', datetime.now().year))
        month = int(request.GET.get('month', datetime.now().month))
        
        # Get expenses for specific month
        start_date = date(year, month, 1)
        if month == 12:
            end_date = date(year + 1, 1, 1) - timedelta(days=1)
        else:
            end_date = date(year, month + 1, 1) - timedelta(days=1)
        
        expenses = Expense.objects.filter(
            date__range=[start_date, end_date],
            is_active=True
        )
        
        # Calculate summary
        total_amount = expenses.aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
        expense_count = expenses.count()
        
        # Daily breakdown
        daily_breakdown = {}
        for i in range(1, end_date.day + 1):
            current_date = date(year, month, i)
            day_expenses = expenses.filter(date=current_date)
            day_amount = day_expenses.aggregate(total=Sum('amount'))['total'] or Decimal('0.00')
            day_count = day_expenses.count()
            
            daily_breakdown[current_date.day] = {
                'amount': day_amount,
                'count': day_count
            }
        
        # Category summary
        category_summary = {}
        for expense in expenses:
            category = expense.category or 'Uncategorized'
            if category not in category_summary:
                category_summary[category] = {
                    'amount': Decimal('0.00'),
                    'count': 0
                }
            category_summary[category]['amount'] += expense.amount
            category_summary[category]['count'] += 1
        
        # Prepare summary data
        summary_data = {
            'year': year,
            'month': month,
            'total_amount': total_amount,
            'expense_count': expense_count,
            'daily_breakdown': daily_breakdown,
            'category_summary': category_summary
        }
        
        serializer = MonthlySummarySerializer(summary_data)
        return Response({
            'success': True,
            'data': serializer.data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to get monthly expense summary.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def expense_update(request, expense_id):
    """Update an existing expense"""
    try:
        expense = Expense.objects.get(id=expense_id, is_active=True)
        
        serializer = ExpenseUpdateSerializer(
            expense,
            data=request.data,
            partial=True
        )
        
        if serializer.is_valid():
            # Check if amount changed for Principal Account integration
            old_amount = expense.amount
            
            # Save expense first (outside of Principal Account transaction)
            expense = serializer.save()
            
            # AdvancePayment syncing is handled by ExpenseUpdateSerializer.update
            
            # Try to update Principal Account (but don't fail if it errors)
            if old_amount != expense.amount:
                try:
                    from principal_account.models import PrincipalAccount, PrincipalAccountBalance
                    
                    with transaction.atomic():
                        # Get current balance
                        balance_obj, created = PrincipalAccountBalance.objects.get_or_create(
                            id=1,
                            defaults={'current_balance': Decimal('0.00')}
                        )
                        
                        # Calculate balance difference
                        amount_diff = old_amount - expense.amount
                        
                        # Create transaction record
                        PrincipalAccount.objects.create(
                            date=expense.date,
                            time=expense.time,
                            source_module='EXPENSES',
                            source_id=str(expense.id),
                            description=f'Expense update: {expense.expense}',
                            type='DEBIT' if amount_diff > 0 else 'CREDIT',
                            amount=abs(amount_diff),
                            balance_before=balance_obj.current_balance,
                            balance_after=balance_obj.current_balance + amount_diff,
                            handled_by=expense.withdrawal_by,
                            notes=f'Amount adjusted from {old_amount} to {expense.amount}',
                            created_by=request.user
                        )
                        
                        # Update balance
                        balance_obj.current_balance += amount_diff
                        balance_obj.save()
                        
                except Exception as e:
                    # Log the error but don't fail the expense update
                    print(f"Principal Account update failed: {e}")
            
            return Response({
                'success': True,
                'message': 'Expense updated successfully.',
                'data': ExpenseSerializer(expense).data
            }, status=status.HTTP_200_OK)
            
        return Response({
            'success': False,
            'message': 'Invalid expense data.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
        
    except Expense.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Expense not found.',
            'errors': {'detail': 'Expense with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to update expense.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def expense_delete(request, expense_id):
    """Soft delete an expense"""
    try:
        expense = Expense.objects.get(id=expense_id, is_active=True)
        
        # Soft delete the expense using the model's delete method
        expense.delete()  # This calls the soft delete method
        
        # Try to update Principal Account (but don't fail if it errors)
        try:
            from principal_account.models import PrincipalAccount, PrincipalAccountBalance
            
            with transaction.atomic():
                # Get current balance
                balance_obj, created = PrincipalAccountBalance.objects.get_or_create(
                    id=1,
                    defaults={'current_balance': Decimal('0.00')}
                )
                
                # Create refund transaction
                PrincipalAccount.objects.create(
                    date=expense.date,
                    time=expense.time,
                    source_module='EXPENSES',
                    source_id=str(expense.id),
                    description=f'Expense deleted: {expense.expense}',
                    type='CREDIT',
                    amount=expense.amount,
                    balance_before=balance_obj.current_balance,
                    balance_after=balance_obj.current_balance + expense.amount,
                    handled_by=expense.withdrawal_by,
                    notes=f'Refund for deleted expense: {expense.description}',
                    created_by=request.user
                )
                
                # Update balance (refund increases balance)
                balance_obj.current_balance += expense.amount
                balance_obj.save()
                
        except Exception as e:
            # Log the error but don't fail the expense deletion
            print(f"Principal Account update failed: {e}")
        
        return Response({
            'success': True,
            'message': 'Expense deleted successfully.'
        }, status=status.HTTP_200_OK)
        
    except Expense.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Expense not found.',
            'errors': {'detail': 'Expense with this ID does not exist.'}
        }, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to delete expense.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def expenses_by_authority(request, authority):
    """Get expenses by withdrawal authority"""
    try:
        expenses = Expense.objects.active().filter(withdrawal_by=authority)
        
        # Apply pagination
        page = int(request.GET.get('page', 1))
        page_size = int(request.GET.get('page_size', 20))
        start = (page - 1) * page_size
        end = start + page_size
        
        total_count = expenses.count()
        expenses_page = expenses[start:end]
        
        serializer = ExpenseListSerializer(expenses_page, many=True)
        
        return Response({
            'success': True,
            'data': {
                'expenses': serializer.data,
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
            'message': 'Failed to fetch expenses by authority.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def expenses_by_category(request, category):
    """Get expenses by category"""
    try:
        expenses = Expense.objects.active().filter(category=category)
        
        # Apply pagination
        page = int(request.GET.get('page', 1))
        page_size = int(request.GET.get('page_size', 20))
        start = (page - 1) * page_size
        end = start + page_size
        
        total_count = expenses.count()
        expenses_page = expenses[start:end]
        
        serializer = ExpenseListSerializer(expenses_page, many=True)
        
        return Response({
            'success': True,
            'data': {
                'expenses': serializer.data,
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
            'message': 'Failed to fetch expenses by category.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def expenses_by_date_range(request):
    """Get expenses within a date range"""
    try:
        date_from = request.GET.get('date_from')
        date_to = request.GET.get('date_to')
        
        if not date_from or not date_to:
            return Response({
                'success': False,
                'message': 'Both date_from and date_to parameters are required.',
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            date_from = datetime.strptime(date_from, '%Y-%m-%d').date()
            date_to = datetime.strptime(date_to, '%Y-%m-%d').date()
        except ValueError:
            return Response({
                'success': False,
                'message': 'Invalid date format. Use YYYY-MM-DD.',
            }, status=status.HTTP_400_BAD_REQUEST)
        
        expenses = Expense.objects.active().filter(
            date__gte=date_from,
            date__lte=date_to
        )
        
        # Apply pagination
        page = int(request.GET.get('page', 1))
        page_size = int(request.GET.get('page_size', 20))
        start = (page - 1) * page_size
        end = start + page_size
        
        total_count = expenses.count()
        expenses_page = expenses[start:end]
        
        serializer = ExpenseListSerializer(expenses_page, many=True)
        
        return Response({
            'success': True,
            'data': {
                'expenses': serializer.data,
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
            'message': 'Failed to fetch expenses by date range.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recent_expenses(request):
    """Get recent expenses (last 30 days)"""
    try:
        thirty_days_ago = timezone.now().date() - timedelta(days=30)
        expenses = Expense.objects.active().filter(date__gte=thirty_days_ago)
        
        # Apply pagination
        page = int(request.GET.get('page', 1))
        page_size = int(request.GET.get('page_size', 20))
        start = (page - 1) * page_size
        end = start + page_size
        
        total_count = expenses.count()
        expenses_page = expenses[start:end]
        
        serializer = ExpenseListSerializer(expenses_page, many=True)
        
        return Response({
            'success': True,
            'data': {
                'expenses': serializer.data,
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
            'message': 'Failed to fetch recent expenses.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)






    

    