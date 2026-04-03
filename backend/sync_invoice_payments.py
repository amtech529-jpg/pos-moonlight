"""
Script to sync invoice payment amounts from associated sales.
Run: python sync_invoice_payments.py
"""
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

django.setup()

from decimal import Decimal
from sales.models import Invoice

print("Syncing invoice payment amounts from sales...")

invoices = Invoice.objects.filter(is_active=True).select_related('sale')
updated = 0
skipped = 0

for invoice in invoices:
    if invoice.sale:
        sale_paid = invoice.sale.amount_paid or Decimal('0.00')
        grand_total = invoice.total_amount or invoice.sale.grand_total or Decimal('0.00')

        # Only sync if invoice amount_paid doesn't match sale
        if invoice.amount_paid != sale_paid:
            old_paid = invoice.amount_paid
            invoice.amount_paid = sale_paid
            invoice.amount_due = max(grand_total - sale_paid, Decimal('0.00'))
            invoice.total_amount = grand_total

            # Update status accordingly
            if invoice.amount_due <= Decimal('0.00'):
                invoice.status = 'PAID'
            elif invoice.amount_paid > Decimal('0.00'):
                invoice.status = 'PARTIALLY_PAID'

            invoice.save(update_fields=['amount_paid', 'amount_due', 'total_amount', 'status', 'updated_at'])
            print(f"  Updated Invoice {invoice.invoice_number}: paid {old_paid} -> {invoice.amount_paid}, due -> {invoice.amount_due}, status -> {invoice.status}")
            updated += 1
        else:
            skipped += 1

print(f"Done! Updated: {updated}, Skipped (already correct): {skipped}")
