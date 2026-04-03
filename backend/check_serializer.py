import os
import django
import sys
from decimal import Decimal

# Setup Django
sys.path.append('d:\\R_Tech_junior_developer\\moon-light-main\\pos-moonlight-main\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from sales.models import Invoice
from sales.serializers import InvoiceListSerializer

def check_serializer():
    inv = Invoice.objects.get(id='d279a69d-6f11-4c72-9671-e4e87e62f25f')
    serializer = InvoiceListSerializer(inv)
    print(f"Serializer Data: {serializer.data}")

if __name__ == "__main__":
    check_serializer()
