import os
import django
import sys

# Setup Django
sys.path.append('d:\\R_Tech_junior_developer\\moon-light-main\\pos-moonlight-main\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from sales.models import Sales

def check_sales():
    print("--- Sales Objects with INV-2026-0001 ---")
    sales = Sales.objects.filter(invoice_number="INV-2026-0001")
    for s in sales:
        print(f"ID: {s.id}")
        print(f"Customer: {s.customer_name}")
        print(f"Grand Total: {s.grand_total}")
        print(f"Paid: {s.amount_paid}")
        print(f"Remaining: {s.remaining_amount}")

if __name__ == "__main__":
    check_sales()
