import os
import django
import sys

# Setup Django
sys.path.append('d:\\R_Tech_junior_developer\\moon-light-main\\pos-moonlight-main\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from sales.models import Sales

def count_sales():
    print(f"Total Sales count: {Sales.objects.count()}")
    for s in Sales.objects.all()[:10]:
        print(f"ID: {s.id}, Invoice: {s.invoice_number}")

if __name__ == "__main__":
    count_sales()
