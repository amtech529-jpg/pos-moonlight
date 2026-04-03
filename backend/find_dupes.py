import os
import django
import sys

# Setup Django
sys.path.append('d:\\R_Tech_junior_developer\\moon-light-main\\pos-moonlight-main\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from sales.models import Invoice

def find_duplicates():
    print("Checking for duplicate invoice numbers...")
    all_invs = Invoice.objects.filter(invoice_number="INV-2026-0001")
    print(f"Count: {all_invs.count()}")
    for inv in all_invs:
        print(f"ID: {inv.id}, Active: {inv.is_active}, Status: {inv.status}, Write-off: {inv.write_off_amount}")

if __name__ == "__main__":
    find_duplicates()
