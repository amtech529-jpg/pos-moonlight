import os
import django
import sys
from decimal import Decimal

# Setup Django
sys.path.append('d:\\R_Tech_junior_developer\\moon-light-main\\pos-moonlight-main\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from sales.models import Invoice, Sales

def search_all_sheraz():
    print("Searching for all invoices for 'sheraz' or 'INV-2026-0001'...")
    invoices = Invoice.objects.filter(invoice_number="INV-2026-0001")
    if not invoices.exists():
        invoices = Invoice.objects.filter(customer_name__icontains="sheraz")
        
    for inv in invoices:
        print(f"\n[Invoice ID: {inv.id}]")
        print(f"Number: {inv.invoice_number}")
        print(f"Customer: {inv.customer_name}")
        print(f"Status: {inv.status}")
        print(f"Total: {inv.total_amount}")
        print(f"Paid: {inv.amount_paid}")
        print(f"Write-off: {inv.write_off_amount}")
        print(f"Due: {inv.amount_due}")
        
if __name__ == "__main__":
    search_all_sheraz()
