"""
Invoice generation service.

Creates Invoice objects from Orders or Sales, handles payment allocation,
and manages write-offs for invoice closure.
"""
import logging
from decimal import Decimal
from django.db import transaction
from django.utils import timezone

logger = logging.getLogger(__name__)


@transaction.atomic
def generate_invoice_from_order(order, created_by=None):
    """
    Generate an invoice from an Order.
    
    Args:
        order: Order instance
        created_by: User who is generating the invoice
    
    Returns:
        Invoice instance
    """
    from sales.models import Invoice
    
    # Check if an invoice already exists for this order
    existing = Invoice.objects.filter(order=order, is_active=True).first()
    if existing:
        logger.info(f"Invoice already exists for Order {order.id}: {existing.invoice_number}")
        return existing
    
    # Calculate total from order items
    total_amount = order.total_amount or Decimal('0.00')
    advance_paid = order.advance_payment or Decimal('0.00')
    amount_due = total_amount - advance_paid
    
    invoice = Invoice.objects.create(
        order=order,
        customer=order.customer,
        total_amount=total_amount,
        amount_paid=advance_paid,
        amount_due=max(amount_due, Decimal('0.00')),
        status='ISSUED' if amount_due > Decimal('0.00') else 'PAID',
        notes=f"Generated from Order #{order.id}\nCustomer: {order.customer_name}\nEvent: {order.event_name or 'N/A'}",
        created_by=created_by,
    )
    
    logger.info(
        f"Invoice {invoice.invoice_number} created from Order {order.id}: "
        f"Total PKR {total_amount}, Paid PKR {advance_paid}, Due PKR {amount_due}"
    )
    
    return invoice


@transaction.atomic
def generate_invoice_from_sale(sale, created_by=None):
    """
    Generate an invoice from a Sale.
    
    Args:
        sale: Sales instance
        created_by: User who is generating the invoice
    
    Returns:
        Invoice instance
    """
    from sales.models import Invoice
    
    # Check if invoice already exists
    try:
        existing = sale.invoice
        logger.info(f"Invoice already exists for Sale {sale.id}: {existing.invoice_number}")
        return existing
    except Invoice.DoesNotExist:
        pass
    
    grand_total = sale.grand_total or Decimal('0.00')
    amount_paid = sale.amount_paid or Decimal('0.00')
    amount_due = grand_total - amount_paid
    
    invoice = Invoice.objects.create(
        sale=sale,
        customer=sale.customer,
        order=sale.order_id,  # FK to order if sale originated from one
        total_amount=grand_total,
        amount_paid=amount_paid,
        amount_due=max(amount_due, Decimal('0.00')),
        status='PAID' if amount_due <= Decimal('0.00') else 'ISSUED',
        notes=f"Generated from Sale {sale.invoice_number}\nCustomer: {sale.customer_name}\nCreated by Moon Light Events",
        created_by=created_by,
    )
    
    logger.info(
        f"Invoice {invoice.invoice_number} created from Sale {sale.id}: "
        f"Total PKR {total_amount}, Paid PKR {amount_paid}, Due PKR {amount_due}"
    )
    
    return invoice


@transaction.atomic
def apply_payment_to_invoice(invoice, payment_amount, payment_method='CASH',
                              reference='', created_by=None):
    """
    Apply a payment to an invoice and create a Payment record.
    
    Args:
        invoice: Invoice instance
        payment_amount: Decimal amount to apply
        payment_method: Payment method string
        reference: Optional payment reference
        created_by: User making the payment
    
    Returns:
        tuple: (Payment instance, updated Invoice)
    """
    from payments.models import Payment
    
    if payment_amount <= Decimal('0.00'):
        raise ValueError("Payment amount must be positive")
    
    if payment_amount > invoice.amount_due:
        raise ValueError(
            f"Payment amount PKR {payment_amount} exceeds amount due PKR {invoice.amount_due}"
        )
    
    # Create payment record
    now = timezone.localtime()
    payment = Payment.objects.create(
        payer_type='CUSTOMER',
        order=invoice.order,
        sale=invoice.sale,
        amount_paid=payment_amount,
        payment_method=payment_method,
        description=f"Payment for Invoice {invoice.invoice_number}",
        date=now.date(),
        time=now.time(),
        payment_month=now.date().replace(day=1),
        created_by=created_by,
    )
    
    # Apply to invoice
    invoice.apply_payment(payment_amount)
    
    logger.info(
        f"Payment PKR {payment_amount} applied to Invoice {invoice.invoice_number}. "
        f"Remaining due: PKR {invoice.amount_due}"
    )
    
    return payment, invoice


@transaction.atomic
def write_off_invoice_balance(invoice, amount=None, reason='', created_by=None):
    """
    Write off the remaining balance on an invoice for closure.
    
    If amount is None, writes off the full remaining balance.
    
    Args:
        invoice: Invoice instance
        amount: Optional specific amount to write off (defaults to full balance)
        reason: Reason for write-off
        created_by: User performing the write-off
    
    Returns:
        Updated Invoice instance
    """
    if amount is None:
        amount = invoice.amount_due
    
    if amount <= Decimal('0.00'):
        raise ValueError("Write-off amount must be positive")
    
    if amount > invoice.amount_due:
        raise ValueError(
            f"Write-off amount PKR {amount} exceeds amount due PKR {invoice.amount_due}"
        )
    
    invoice.apply_write_off(amount, reason)
    
    logger.info(
        f"Write-off PKR {amount} applied to Invoice {invoice.invoice_number}. "
        f"Reason: {reason or 'No reason given'}. "
        f"Remaining due: PKR {invoice.amount_due}"
    )
    
    return invoice


def get_invoice_ledger(customer_id=None, start_date=None, end_date=None):
    """
    Get invoice ledger summary, optionally filtered by customer and date range.
    
    Returns dict with totals and outstanding invoices.
    """
    from sales.models import Invoice
    from django.db.models import Sum
    
    from django.utils import timezone
    from django.utils.dateparse import parse_date
    import datetime
    
    invoices = Invoice.objects.filter(is_active=True)
    
    if customer_id:
        invoices = invoices.filter(customer_id=customer_id)
        
    if start_date:
        if isinstance(start_date, str):
            parsed_start = parse_date(start_date)
            if parsed_start:
                invoices = invoices.filter(issue_date__gte=datetime.datetime.combine(parsed_start, datetime.time.min).replace(tzinfo=timezone.get_current_timezone()))
        else:
            invoices = invoices.filter(issue_date__date__gte=start_date)
            
    if end_date:
        if isinstance(end_date, str):
            parsed_end = parse_date(end_date)
            if parsed_end:
                invoices = invoices.filter(issue_date__lte=datetime.datetime.combine(parsed_end, datetime.time.max).replace(tzinfo=timezone.get_current_timezone()))
        else:
            invoices = invoices.filter(issue_date__date__lte=end_date)
    
    # Calculate totals, excluding cancelled invoices
    stats_invoices = invoices.exclude(status='CANCELLED')
    
    totals = stats_invoices.aggregate(
        total_invoiced=Sum('total_amount'),
        total_paid=Sum('amount_paid'),
        total_written_off=Sum('write_off_amount'),
    )
    
    # Total due should strictly reflect active pending balances
    total_due = stats_invoices.exclude(
        status__in=['CLOSED', 'WRITTEN_OFF', 'PAID']
    ).aggregate(due=Sum('amount_due'))['due'] or Decimal('0.00')
    
    totals['total_due'] = total_due
    
    from django.utils import timezone
    now = timezone.now().date()
    total_overdue = invoices.filter(
        due_date__lt=now,
        is_active=True
    ).exclude(
        status__in=['PAID', 'CANCELLED', 'WRITTEN_OFF', 'CLOSED']
    ).aggregate(overdue=Sum('amount_due'))['overdue'] or Decimal('0.00')
    
    all_invoices = invoices.order_by('-issue_date')
    
    return {
        'totals': {k: v or Decimal('0.00') for k, v in totals.items()},
        'total_overdue': total_overdue,
        'ledger_count': all_invoices.count(),
        'ledger_entries': [
            {
                'id': str(inv.id),
                'invoice_number': inv.invoice_number,
                'total_amount': float(inv.total_amount),
                'amount_paid': float(inv.amount_paid),
                'amount_due': float(inv.amount_due),
                'write_off_amount': float(inv.write_off_amount) if hasattr(inv, 'write_off_amount') else 0.0,
                'date': inv.issue_date.strftime('%Y-%m-%d') if inv.issue_date else None,
                'due_date': inv.due_date.isoformat() if inv.due_date else None,
                'is_overdue': inv.is_overdue,
                'status': inv.status,
                'customer_name': inv.customer.name if inv.customer else 'N/A',
                'sale_id': str(inv.sale.id) if inv.sale else None,
                'order_id': str(inv.order.id) if inv.order else None,
            }
            for inv in all_invoices[:100]
        ],
    }
