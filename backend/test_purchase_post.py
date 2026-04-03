import os
import django
import json
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from rest_framework.request import Request
from rest_framework.test import APIRequestFactory

from purchases.serializers import PurchaseSerializer
from vendors.models import Vendor
from products.models import Product
from categories.models import Category

def test_purchase_post():
    # Get a vendor
    vendor = Vendor.objects.first()
    if not vendor:
        print("Creating a dummy vendor...")
        vendor = Vendor.objects.create(name="Test Vendor", phone="03001234567")
    
    # Get a product
    product = Product.objects.first()
    if not product:
        print("Creating a dummy product...")
        cat, _ = Category.objects.get_or_create(name="Test Cat")
        product = Product.objects.create(name="Test Product", category=cat, price=100, quantity=10)

    data = {
        "vendor": str(vendor.id),
        "invoice_number": "INV-123",
        "purchase_date": "2024-03-04T12:00:00.000Z",
        "subtotal": "100.00",
        "tax": "0.00",
        "total": "100.00",
        "status": "posted",
        "items": [
            {
                "product": str(product.id),
                "quantity": "1.00",
                "unit_cost": "100.00",
                "total_cost": "100.00",
                "description": "Test"
            }
        ]
    }

    serializer = PurchaseSerializer(data=data)
    if serializer.is_valid():
        print("Serializer is VALID")
    else:
        print("Serializer ERRORS:")
        print(json.dumps(serializer.errors, indent=2))

if __name__ == '__main__':
    test_purchase_post()
