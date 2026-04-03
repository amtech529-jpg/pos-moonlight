import os
import django
import sys
from decimal import Decimal

# Setup Django
sys.path.append('d:\\R_Tech_junior_developer\\moon-light-main\\pos-moonlight-main\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from sales.models import Invoice

def check_one():
    inv = Invoice.objects.get(id='d279a69d-6f11-4c72-9671-e4e87e62f25f')
    print(f"Number: {inv.invoice_number}")
    print(f"Status: {inv.status}")
    print(f"Total: {inv.total_amount}")
    print(f"Paid: {inv.amount_paid}")
    print(f"Write-off: {inv.write_off_amount}")
    print(f"Due: {inv.amount_due}")

if __name__ == "__main__":
    check_one()
