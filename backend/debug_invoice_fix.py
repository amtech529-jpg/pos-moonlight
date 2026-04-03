import os
import django
import sys
from decimal import Decimal

# Setup Django
sys.path.append('d:\\R_Tech_junior_developer\\moon-light-main\\pos-moonlight-main\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from sales.models import Invoice, Sales

def debug_invoice(invoice_number):
    try:
        inv = Invoice.objects.get(invoice_number=invoice_number)
        print(f"--- Invoice {invoice_number} ---")
        print(f"Status: {inv.status}")
        print(f"Total: {inv.total_amount}")
        print(f"Paid: {inv.amount_paid}")
        print(f"Write-off: {inv.write_off_amount}")
        print(f"Due: {inv.amount_due}")
        
        if inv.sale:
            print(f"\n--- Associated Sale {inv.sale.invoice_number} ---")
            print(f"Sale Grand Total: {inv.sale.grand_total}")
            print(f"Sale Paid: {inv.sale.amount_paid}")
            print(f"Sale Remaining: {inv.sale.remaining_amount}")
            
        # Try to trigger the fix
        print("\nTriggering save()...")
        inv.save()
        
        # Fresh fetch
        inv.refresh_from_db()
        print(f"\n--- After Save ---")
        print(f"Status: {inv.status}")
        print(f"Write-off: {inv.write_off_amount}")
        print(f"Due: {inv.amount_due}")
        
        if inv.amount_due > 0 and inv.status == 'WRITTEN_OFF':
            print("\n!!! ERROR: Due is still > 0 even with WRITTEN_OFF status !!!")
            # Force fix
            print("Force fixing manually...")
            inv.write_off_amount = inv.total_amount - inv.amount_paid
            inv.amount_due = Decimal('0.00')
            inv.save()
            inv.refresh_from_db()
            print(f"Verified Final Due: {inv.amount_due}")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    debug_invoice("INV-2026-0001")
