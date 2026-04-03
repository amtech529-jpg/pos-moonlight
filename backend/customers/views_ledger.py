# backend/customers/views_ledger.py
"""
Customer Ledger API
Provides comprehensive transaction history for customers including:
- Sales
- Payments
- Receivables
- Returns
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

from customers.models import Customer
from sales.models import Sales, Invoice
from receivables.models import Receivable
from payments.models import Payment


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def customer_ledger(request, customer_id):
    """
    Get comprehensive customer ledger with all transactions and running balance
    
    Query Parameters:
    - page: Page number (default: 1)
    - page_size: Items per page (default: 50, max: 100)
    - start_date: Filter from date (YYYY-MM-DD)
    - end_date: Filter to date (YYYY-MM-DD)
    - transaction_type: Filter by type (SALE, PAYMENT, RECEIVABLE, RETURN)
    
    Returns:
    - Chronological list of all customer transactions
    - Running balance after each transaction
    - Summary statistics
    - Pagination info
    """
    try:
        # Get customer
        customer = Customer.objects.get(id=customer_id, is_active=True)
        
        # Pagination parameters
        page_size = min(int(request.GET.get('page_size', 50)), 100)
        page = int(request.GET.get('page', 1))
        
        # Date filtering
        start_date_str = request.GET.get('start_date')
        end_date_str = request.GET.get('end_date')
        transaction_type = request.GET.get('transaction_type', '').upper()
        
        from django.utils.dateparse import parse_date
        import datetime
        from django.utils import timezone
        
        start_datetime = None
        end_datetime = None
        start_date_obj = None
        end_date_obj = None

        if start_date_str:
            parsed_start = parse_date(start_date_str)
            if parsed_start:
                start_date_obj = parsed_start
                start_datetime = datetime.datetime.combine(parsed_start, datetime.time.min).replace(tzinfo=timezone.get_current_timezone())
        
        if end_date_str:
            parsed_end = parse_date(end_date_str)
            if parsed_end:
                end_date_obj = parsed_end
                end_datetime = datetime.datetime.combine(parsed_end, datetime.time.max).replace(tzinfo=timezone.get_current_timezone())
        
        # Get all entries before start_date to calculate opening balance
        opening_balance = Decimal('0.00')
        if start_date_obj:
            # Sales before start_date
            prev_sales = Sales.objects.filter(
                customer=customer, date_of_sale__lt=start_datetime, is_active=True
            ).exclude(status='CANCELLED').aggregate(total=Sum('grand_total'))['total'] or Decimal('0.00')
            
            # Additional invoices before start_date (not linked to sales)
            prev_invoices = Invoice.objects.filter(
                customer=customer, issue_date__lt=start_datetime, sale__isnull=True, is_active=True
            ).aggregate(total=Sum('total_amount'))['total'] or Decimal('0.00')
            
            # Receivables before start_date
            prev_receivables = Receivable.objects.filter(
                Q(debtor_phone=customer.phone) | Q(debtor_name__icontains=customer.name),
                date_lent__lt=start_date_obj, is_active=True
            ).aggregate(total=Sum('amount_given'))['total'] or Decimal('0.00')
            
            # Payments before start_date
            prev_payments = Payment.objects.filter(
                Q(sale__customer=customer) | Q(order__customer=customer) | Q(payer_id=customer.id, payer_type='CUSTOMER'),
                date__lt=start_date_obj, is_active=True
            ).aggregate(total=Sum('amount_paid'))['total'] or Decimal('0.00')
            
            # Receivable returns before start_date
            prev_rec_returns = Receivable.objects.filter(
                Q(debtor_phone=customer.phone) | Q(debtor_name__icontains=customer.name),
                updated_at__lt=start_datetime, is_active=True
            ).aggregate(total=Sum('amount_returned'))['total'] or Decimal('0.00')
            
            # Write-offs before start_date
            prev_writeoffs = Invoice.objects.filter(
                customer=customer, updated_at__lt=start_datetime, is_active=True
            ).aggregate(total=Sum('write_off_amount'))['total'] or Decimal('0.00')
            
            opening_balance = prev_sales + prev_invoices + prev_receivables - prev_payments - prev_rec_returns - prev_writeoffs

        # Initialize ledger entries list
        ledger_entries = []
        
        # Add opening balance entry if it's not zero
        if opening_balance != 0:
            ledger_entries.append({
                'id': 'OPENING_BALANCE',
                'type': 'OPENING',
                'transaction_type': 'DEBIT' if opening_balance > 0 else 'CREDIT',
                'amount': float(abs(opening_balance)),
                'date': start_date_str if start_date_str else timezone.now().date().strftime('%Y-%m-%d'),
                'time': '00:00:00',
                'description': 'Opening Balance',
                'reference_number': 'OPEN',
                'source_module': 'LEDGER',
                'balance': float(opening_balance),
                'details': {'opening_balance': float(opening_balance)}
            })
        
        # =====================================================
        # 1. GET ALL SALES FOR THIS CUSTOMER
        # =====================================================
        sales_query = Sales.objects.filter(
            customer=customer,
            is_active=True
        ).exclude(status='CANCELLED')
        
        if start_datetime:
            sales_query = sales_query.filter(date_of_sale__gte=start_datetime)
        if end_datetime:
            sales_query = sales_query.filter(date_of_sale__lte=end_datetime)
        
        sales = sales_query.order_by('date_of_sale', 'created_at')
        
        for sale in sales:
            ledger_entries.append({
                'id': str(sale.id),
                'type': 'SALE',
                'transaction_type': 'DEBIT',  # Customer owes money
                'amount': float(sale.grand_total),
                'date': sale.date_of_sale.strftime('%Y-%m-%d'),
                'time': sale.created_at.strftime('%H:%M:%S'),
                'description': f'Sale Invoice #{sale.invoice_number}',
                'reference_number': sale.invoice_number,
                'reference_id': str(sale.id),
                'source_module': 'SALES',
                'payment_status': 'PAID' if sale.is_fully_paid else 'PENDING',
                'details': {
                    'invoice_number': sale.invoice_number,
                    'total_amount': float(sale.grand_total),
                    'tax_amount': float(sale.tax_amount),
                    'discount': float(sale.overall_discount),
                    'grand_total': float(sale.grand_total),
                    'items_count': sale.sale_items.count() if hasattr(sale, 'sale_items') else 0
                }
            })
        
        # =====================================================
        # 2. GET ALL PAYMENTS FROM THIS CUSTOMER
        # =====================================================
        # Payments linked to sales or orders for this customer
        payments_query = Payment.objects.filter(
            Q(sale__customer=customer) | Q(order__customer=customer) | Q(payer_id=customer.id, payer_type='CUSTOMER'),
            is_active=True
        ).distinct()
        
        if start_date_obj:
            payments_query = payments_query.filter(date__gte=start_date_obj)
        if end_date_obj:
            payments_query = payments_query.filter(date__lte=end_date_obj)
        
        payments = payments_query.order_by('date', 'time')
        
        for payment in payments:
            ledger_entries.append({
                'id': str(payment.id),
                'type': 'PAYMENT',
                'transaction_type': 'CREDIT',  # Customer paid money
                'amount': float(payment.amount_paid),
                'date': payment.date.strftime('%Y-%m-%d'),
                'time': payment.time.strftime('%H:%M:%S'),
                'description': f'Payment received - {payment.payment_method}',
                'reference_number': f'PAY-{str(payment.id)[:8].upper()}',
                'reference_id': str(payment.id),
                'source_module': 'PAYMENTS',
                'payment_method': payment.payment_method,
                'details': {
                    'payment_method': payment.payment_method,
                    'amount_paid': float(payment.amount_paid),
                    'related_sale': payment.sale.invoice_number if payment.sale else (f"ORD-{str(payment.order.id)[:8].upper()}" if payment.order else None),
                    'description': payment.description or ''
                }
            })
            
        # =====================================================
        # 2B. GET ALL INVOICES FOR THIS CUSTOMER (Not linked to sales to avoid duplication)
        # =====================================================
        invoices_query = Invoice.objects.filter(
            Q(customer=customer) | Q(order__customer=customer),
            sale__isnull=True,
            is_active=True
        ).exclude(status='CANCELLED')
        
        if start_datetime:
            invoices_query = invoices_query.filter(issue_date__gte=start_datetime)
        if end_datetime:
            invoices_query = invoices_query.filter(issue_date__lte=end_datetime)
            
        invoices = invoices_query.order_by('issue_date')
        
        for invoice in invoices:
            ledger_entries.append({
                'id': str(invoice.id),
                'type': 'INVOICE',
                'transaction_type': 'DEBIT',
                'amount': float(invoice.total_amount),
                'date': invoice.issue_date.strftime('%Y-%m-%d'),
                'time': invoice.issue_date.strftime('%H:%M:%S'),
                'description': f'Invoice #{invoice.invoice_number} (Order/General)',
                'reference_number': invoice.invoice_number,
                'reference_id': str(invoice.id),
                'source_module': 'INVOICES',
                'payment_status': invoice.status,
                'details': {
                    'invoice_number': invoice.invoice_number,
                    'total_amount': float(invoice.total_amount),
                    'amount_due': float(invoice.amount_due)
                }
            })

        # =====================================================
        # 3. GET ALL RECEIVABLES FOR THIS CUSTOMER
        # =====================================================
        # Receivables are amounts lent to customer (customer owes us)
        receivables_query = Receivable.objects.filter(
            Q(debtor_phone=customer.phone) | Q(debtor_name__icontains=customer.name),
            is_active=True
        )
        
        if start_date_obj:
            receivables_query = receivables_query.filter(date_lent__gte=start_date_obj)
        if end_date_obj:
            receivables_query = receivables_query.filter(date_lent__lte=end_date_obj)
        
        receivables = receivables_query.order_by('date_lent')
        
        for receivable in receivables:
            # Add the lending transaction
            ledger_entries.append({
                'id': str(receivable.id),
                'type': 'RECEIVABLE',
                'transaction_type': 'DEBIT',  # Customer owes money
                'amount': float(receivable.amount_given),
                'date': receivable.date_lent.strftime('%Y-%m-%d'),
                'time': receivable.created_at.strftime('%H:%M:%S'),
                'description': f'Amount lent: {receivable.reason_or_item}',
                'reference_number': f'REC-{str(receivable.id)[:8].upper()}',
                'reference_id': str(receivable.id),
                'source_module': 'RECEIVABLES',
                'status': 'PAID' if receivable.balance_remaining == 0 else 'PARTIAL' if receivable.amount_returned > 0 else 'PENDING',
                'details': {
                    'amount_lent': float(receivable.amount_given),
                    'amount_returned': float(receivable.amount_returned),
                    'balance_remaining': float(receivable.balance_remaining),
                    'reason': receivable.reason_or_item,
                    'expected_return_date': receivable.expected_return_date.strftime('%Y-%m-%d') if receivable.expected_return_date else None,
                    'status': 'PAID' if receivable.balance_remaining == 0 else 'PARTIAL' if receivable.amount_returned > 0 else 'PENDING'
                }
            })
            
            # If customer has returned money, add credit entry
            if receivable.amount_returned > 0:
                # Use updated_at for return date since there's no specific return_date field
                return_date = receivable.updated_at.date() if hasattr(receivable.updated_at, 'date') else receivable.date_lent
                ledger_entries.append({
                    'id': f"{receivable.id}_return",
                    'type': 'RECEIVABLE_PAYMENT',
                    'transaction_type': 'CREDIT',  # Customer paid back
                    'amount': float(receivable.amount_returned),
                    'date': return_date.strftime('%Y-%m-%d'),
                    'time': receivable.updated_at.strftime('%H:%M:%S'),
                    'description': f'Payment received for: {receivable.reason_or_item}',
                    'reference_number': f'REC-{str(receivable.id)[:8].upper()}-RETURN',
                    'reference_id': str(receivable.id),
                    'source_module': 'RECEIVABLES',
                    'status': 'PAID' if receivable.balance_remaining == 0 else 'PARTIAL',
                    'details': {
                        'parent_receivable_id': str(receivable.id),
                        'amount_returned': float(receivable.amount_returned),
                        'balance_remaining': float(receivable.balance_remaining)
                    }
                })
        
        # =====================================================
        # 4. GET ALL WRITE-OFFS & CLOSURES FOR THIS CUSTOMER
        # =====================================================
        writeoffs_query = Invoice.objects.filter(
            customer=customer,
            write_off_amount__gt=0,
            is_active=True
        )
        
        if start_datetime:
            writeoffs_query = writeoffs_query.filter(updated_at__gte=start_datetime)
        if end_datetime:
            writeoffs_query = writeoffs_query.filter(updated_at__lte=end_datetime)
            
        for inv in writeoffs_query:
            ledger_entries.append({
                'id': f'WO_{inv.id}',
                'type': 'WRITE_OFF',
                'transaction_type': 'CREDIT',  # Reduces customer debt
                'amount': float(inv.write_off_amount),
                'date': inv.updated_at.strftime('%Y-%m-%d'),
                'time': inv.updated_at.strftime('%H:%M:%S'),
                'description': f'Balance Write-off/Closure - Invoice #{inv.invoice_number}',
                'reference_number': inv.invoice_number,
                'reference_id': str(inv.id),
                'source_module': 'INVOICES',
                'details': {
                    'invoice_number': inv.invoice_number,
                    'write_off_amount': float(inv.write_off_amount),
                    'final_status': inv.status
                }
            })
            
        # =====================================================
        # 5. SORT ALL ENTRIES BY DATE & TIME
        # =====================================================
        ledger_entries.sort(key=lambda x: (x['date'], x['time']))
        
        # =====================================================
        # 5. CALCULATE RUNNING BALANCE & ADD debit/credit
        # =====================================================
        running_balance = opening_balance
        for entry in ledger_entries:
            if entry['id'] == 'OPENING_BALANCE':
                # Opening balance entry
                entry['debit'] = float(abs(opening_balance)) if opening_balance > 0 else 0.0
                entry['credit'] = float(abs(opening_balance)) if opening_balance < 0 else 0.0
                continue
                
            amount = float(entry.get('amount', 0))
            if entry['transaction_type'] == 'DEBIT':
                entry['debit'] = amount
                entry['credit'] = 0.0
                running_balance += Decimal(str(amount))
            else:
                entry['debit'] = 0.0
                entry['credit'] = amount
                running_balance -= Decimal(str(amount))
            
            entry['balance'] = float(running_balance)
        
        # =====================================================
        # 6. FILTER BY TRANSACTION TYPE (if specified)
        # =====================================================
        if transaction_type and transaction_type in ['SALE', 'PAYMENT', 'RECEIVABLE', 'RECEIVABLE_PAYMENT']:
            ledger_entries = [e for e in ledger_entries if e['type'] == transaction_type]
        
        # =====================================================
        # 7. CALCULATE SUMMARY STATISTICS
        # =====================================================
        total_sales = sum(e['amount'] for e in ledger_entries if e['type'] == 'SALE')
        total_invoices = sum(e['amount'] for e in ledger_entries if e['type'] == 'INVOICE')
        total_payments = sum(e['amount'] for e in ledger_entries if e['type'] == 'PAYMENT')
        total_receivables = sum(e['amount'] for e in ledger_entries if e['type'] == 'RECEIVABLE')
        total_receivable_payments = sum(e['amount'] for e in ledger_entries if e['type'] == 'RECEIVABLE_PAYMENT')
        total_write_offs = sum(e['amount'] for e in ledger_entries if e['type'] == 'WRITE_OFF')
        
        total_debit = total_sales + total_invoices + total_receivables
        total_credit = total_payments + total_receivable_payments + total_write_offs
        outstanding_balance = total_debit - total_credit
        
        summary = {
            'customer_id': str(customer.id),
            'customer_name': customer.name,
            'customer_phone': customer.phone,
            'customer_email': customer.email or '',
            'total_transactions': len(ledger_entries),
            'total_sales': float(total_sales),
            'total_sales_count': len([e for e in ledger_entries if e['type'] == 'SALE']),
            'total_payments': float(total_payments),
            'total_payments_count': len([e for e in ledger_entries if e['type'] == 'PAYMENT']),
            'total_receivables': float(total_receivables),
            'total_receivables_count': len([e for e in ledger_entries if e['type'] == 'RECEIVABLE']),
            'total_receivable_payments': float(total_receivable_payments),
            'total_write_offs': float(total_write_offs),
            'total_debit': float(total_debit),
            'total_credit': float(total_credit),
            'outstanding_balance': float(outstanding_balance),
            'current_balance': float(running_balance),
            'first_transaction_date': ledger_entries[0]['date'] if ledger_entries else None,
            'last_transaction_date': ledger_entries[-1]['date'] if ledger_entries else None,
        }
        
        # =====================================================
        # 8. PAGINATION
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
            'message': 'Customer ledger retrieved successfully'
        }, status=status.HTTP_200_OK)
        
    except Customer.DoesNotExist:
        return Response({
            'success': False,
            'message': 'Customer not found.',
            'errors': {'detail': 'Customer with this ID does not exist or is inactive.'}
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
            'message': 'Failed to retrieve customer ledger.',
            'errors': {'detail': str(e)}
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)