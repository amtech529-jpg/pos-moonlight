import os
import django
import sys
from decimal import Decimal

# Setup Django
sys.path.append('d:\\R_Tech_junior_developer\\moon-light-main\\pos-moonlight-main\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from sales.models import Invoice
from sales.serializers import InvoiceUpdateSerializer
from rest_framework.request import Request
from rest_framework.test import APIRequestFactory

def simulate_update():
    # Target the invoice
    inv = Invoice.objects.get(id='d279a69d-6f11-4c72-9671-e4e87e62f25f')
    print(f"Before simulation: Status={inv.status}, Write-off={inv.write_off_amount}")
    
    # Simulate the data sent by frontend
    data = {
        'status': 'WRITTEN_OFF',
        'write_off_amount': 1100.00, # This is the "wrong" amount from UI
        'notes': 'Simulated update'
    }
    
    # Needs a request for serializer
    factory = APIRequestFactory()
    request = factory.put('/dummy/')
    
    serializer = InvoiceUpdateSerializer(inv, data=data, partial=True, context={'request': Request(request)})
    if serializer.is_valid():
        updated_inv = serializer.save()
        print(f"After simulation: Status={updated_inv.status}, Write-off={updated_inv.write_off_amount}")
    else:
        print(f"Serializer errors: {serializer.errors}")

if __name__ == "__main__":
    simulate_update()
