import os
import django
import sys
from decimal import Decimal

# Setup Django
sys.path.append('d:\\R_Tech_junior_developer\\moon-light-main\\pos-moonlight-main\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from sales.models import Invoice, Sales

def check_linked_sale():
    inv = Invoice.objects.get(id='d279a69d-6f11-4c72-9671-e4e87e62f25f')
    print(f"--- Invoice INV-2026-0001 ---")
    print(f"Sale ID: {inv.sale_id}")
    if inv.sale:
        print(f"--- Linked Sale Transaction ---")
        print(f"Invoice Number: {inv.sale.invoice_number}")
        print(f"Grand Total: {inv.sale.grand_total}")
        print(f"Amount Paid: {inv.sale.amount_paid}")
        print(f"Remaining: {inv.sale.remaining_amount}")
    else:
        print("No linked sale object!")

if __name__ == "__main__":
    check_linked_sale()
