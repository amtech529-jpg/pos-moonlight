# backend/vendors/views_ledger.py
"""
Vendor Ledger API
Provides comprehensive transaction history for vendors including:
- Payables (what we owe them)
- Payments (what we paid them)
- Purchases (future integration)
- Running balance calculation
"""

from django.db.models import Sum, Q, F
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from decimal import Decimal
from datetime import datetime, timedelta
from django.utils import timezone

from vendors.models import Vendor
from payables.models import Payable
from payments.models import Payment


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def vendor_ledger(request, vendor_id):
    """
    Get comprehensive vendor ledger with all transactions and running balance
    
    Query Parameters:
    - page: Page number (default: 1)
    - page_size: Items per page (default: 50, max: 100)
    - start_date: Filter from date (YYYY-MM-DD)
    - end_date: Filter to date (YYYY-MM-DD)
    - transaction_type: Filter by type (PAYABLE, PAYMENT)
    
    Returns:
    - Chronological list of all vendor transactions
    - Running balance after each transaction (how much we owe vendor)
    - Summary statistics
    - Pagination info
    """
    try:
        # Get vendor
        vendor = Vendor.objects.get(id=vendor_id, is_active=True)
        
        # Pagination parameters
        page_size = min(int(request.GET.get('page_size', 50)), 100)
        page = int(request.GET.get('page', 1))
        
        # Date filtering
        start_date = request.GET.get('start_date')
        end_date = request.GET.get('end_date')
        transaction_type = request.GET.get('transaction_type', '').upper()
        
        # Initialize ledger entries list
        ledger_entries = []
        
        # =====================================================
        # 1. GET ALL PAYABLES FOR THIS VENDOR
        # =====================================================
        # Payables are amounts we owe to the vendor
        payables_query = Payable.objects.filter(
            vendor=vendor,
            is_active=True
        )
        
        if start_date:
            payables_query = payables_query.filter(date_borrowed__gte=start_date)
        if end_date:
            payables_query = payables_query.filter(date_borrowed__lte=end_date)
        
        payables = payables_query.order_by('date_borrowed', 'created_at')
        
        for payable in payables:
            # Add the borrowing transaction (we owe vendor)
            ledger_entries.append({
                'id': str(payable.id),
                'type': 'PAYABLE',
                'transaction_type': 'CREDIT',  # We owe vendor money
                'amount': float(payable.amount_borrowed),
                'date': payable.date_borrowed.strftime('%Y-%m-%d'),
                'time': payable.created_at.strftime('%H:%M:%S'),
                'description': f'Amount borrowed: {payable.reason_or_item}',
                'reference_number': f'PAY-{str(payable.id)[:8].upper()}',
                'reference_id': str(payable.id),
                'source_module': 'PAYABLES',
                'status': payable.status,
                'details': {
                    'amount_borrowed': float(payable.amount_borrowed),
                    'amount_paid': float(payable.amount_paid),
                    'balance_remaining': float(payable.balance_remaining),
                    'reason': payable.reason_or_item,
                    'expected_return_date': payable.expected_repayment_date.strftime('%Y-%m-%d') if payable.expected_repayment_date else None,
                    'creditor_name': payable.creditor_name,
                    'creditor_phone': payable.creditor_phone,
                    'status': payable.status
                }
            })
            
            # If we've made payments, add debit entries
            if payable.amount_paid > 0:
                # Use updated_at for payment date since there's no specific return_date field
                payment_date = payable.updated_at.date() if hasattr(payable.updated_at, 'date') else payable.date_borrowed
                ledger_entries.append({
                    'id': f"{payable.id}_payment",
                    'type': 'PAYABLE_PAYMENT',
                    'transaction_type': 'DEBIT',  # We paid vendor
                    'amount': float(payable.amount_paid),
                    'date': payment_date.strftime('%Y-%m-%d'),
                    'time': payable.updated_at.strftime('%H:%M:%S'),
                    'description': f'Payment made for: {payable.reason_or_item}',
                    'reference_number': f'PAY-{str(payable.id)[:8].upper()}-PMT',
                    'reference_id': str(payable.id),
                    'source_module': 'PAYABLES',
                    'status': payable.status,
                    'details': {
                        'parent_payable_id': str(payable.id),
                        'amount_paid': float(payable.amount_paid),
                        'balance_remaining': float(payable.balance_remaining)
                    }
                })
        
        # =====================================================
        # 2. GET ALL PAYMENTS TO THIS VENDOR
        # =====================================================
        # Direct payments to vendor (e.g., salary, services)
        payments_query = Payment.objects.filter(
            vendor=vendor,
            is_active=True
        )
        
        if start_date:
            payments_query = payments_query.filter(date__gte=start_date)
        if end_date:
            payments_query = payments_query.filter(date__lte=end_date)
        
        payments = payments_query.order_by('date', 'time')
        
        for payment in payments:
            ledger_entries.append({
                'id': str(payment.id),
                'type': 'PAYMENT',
                'transaction_type': 'DEBIT',  # We paid vendor
                'amount': float(payment.amount_paid),
                'date': payment.date.strftime('%Y-%m-%d'),
                'time': payment.time.strftime('%H:%M:%S'),
                'description': f'Payment made - {payment.payment_method}',
                'reference_number': f'PMT-{str(payment.id)[:8].upper()}',
                'reference_id': str(payment.id),
                'source_module': 'PAYMENTS',
                'payment_method': payment.payment_method,
                'details': {
                    'payment_method': payment.payment_method,
                    'amount_paid': float(payment.amount_paid),
                    'bonus': float(payment.bonus) if payment.bonus else 0.0,
                    'deduction': float(payment.deduction) if payment.deduction else 0.0,
                    'payer_type': payment.payer_type,
                    'description': payment.description or ''
                }
            })
        
        # =====================================================
        # 3. SORT ALL ENTRIES BY DATE & TIME
        # =====================================================
        ledger_entries.sort(key=lambda x: (x['date'], x['time']))
        
        # =====================================================
        # 4. CALCULATE RUNNING BALANCE & TRANSFORM FOR FRONTEND
        # =====================================================
        # Positive balance = We owe vendor
        # Negative balance = Vendor owes us (rare)
        running_balance = Decimal('0.00')
        for entry in ledger_entries:
            if entry['transaction_type'] == 'CREDIT':
                # We owe vendor money (payables)
                running_balance += Decimal(str(entry['amount']))
            else:
                # We paid vendor (payments)
                running_balance -= Decimal(str(entry['amount']))
            
            entry['balance'] = float(running_balance)
            
            # Transform entry to match frontend expectations
            if entry['transaction_type'] == 'CREDIT':
                entry['debit'] = 0.0
                entry['credit'] = float(entry['amount'])
            else:
                entry['debit'] = float(entry['amount'])
                entry['credit'] = 0.0
            
            # Map backend type to frontend transaction_type
            entry['transaction_type'] = entry['type']  # Use 'type' as 'transaction_type' for frontend
        
        # =====================================================
        # 5. FILTER BY TRANSACTION TYPE (if specified)
        # =====================================================
        if transaction_type and transaction_type in ['PAYABLE', 'PAYMENT', 'PAYABLE_PAYMENT']:
            ledger_entries = [e for e in ledger_entries if e['type'] == transaction_type]
        
        # =====================================================
        # 6. CALCULATE SUMMARY STATISTICS
        # =====================================================
        total_payables = sum(e['amount'] for e in ledger_entries if e['type'] == 'PAYABLE')
        total_payments = sum(e['amount'] for e in ledger_entries if e['type'] == 'PAYMENT')
        total_payable_payments = sum(e['amount'] for e in ledger_entries if e['type'] == 'PAYABLE_PAYMENT')
        
        total_credit = total_payables  # What we owe
        total_debit = total_payments + total_payable_payments  # What we paid
        outstanding_balance = total_credit - total_debit
        
        summary = {
            'vendor_id': str(vendor.id),
            'vendor_name': vendor.name,
            'vendor_business_name': vendor.business_name or '',
            'vendor_phone': vendor.phone,
            'total_transactions': len(ledger_entries),
            'total_payables': float(total_payables),
            'total_payables_count': len([e for e in ledger_entries if e['type'] == 'PAYABLE']),
            'total_payments': float(total_payments + total_payable_payments),
            'total_payments_count': len([e for e in ledger_entries if e['type'] in ['PAYMENT', 'PAYABLE_PAYMENT']]),
            'total_debits': float(total_debit),  # What we paid (matching frontend)
            'total_credits': float(total_credit),  # What we owe (matching frontend)
            'opening_balance': 0.0,  # Starting balance (always 0 for now)
            'closing_balance': float(running_balance),  # Current running balance
            'outstanding_balance': float(outstanding_balance),  # Net amount we owe
            'first_transaction_date': ledger_entries[0]['date'] if ledger_entries else None,
            'last_transaction_date': ledger_entries[-1]['date'] if ledger_entries else None,
            'vendor_status': 'CREDITOR' if outstanding_balance > 0 else 'SETTLED',
        }
        
        # =====================================================
        # 7. PAGINATION
        # =====================================================
        total_count = len(ledger_entries)
        start_index = (page - 1) * page_size
        end_index = start_index + page_size
        paginated_entries = ledger_entries[start_index:end_index]
        
        return Response({
            'success': True,
            'data': {
                'ledger_entries': paginated_entries,
                'summary': summary,
                'pagination': {
                    'current_page': page,
                    'page_size': page_size,
                    'total_count': total_count,
                    'total_pages': (total_count + page_size - 1) // page_size if total_count > 0 else 0,
                    'has_next': end_index < total_count,
                    'has_previous': page > 1
                }
            },
            'message': 'Vendor ledger retrieved successfully'
        }, status=status.HTTP_200_OK)
        
    except Vendor.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Vendor not found.',
            'errors': {'detail': 'Vendor with this ID does not exist or is inactive.'}
        }, status=status.HTTP_404_NOT_FOUND)
    
    except ValueError as e:
        return Response({
            'success': False,
            'message': 'Invalid parameters.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            'success': False,
            'message': 'Failed to retrieve vendor ledger.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)