
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from products.models import Product
from django.db.models import Count

duplicates = Product.objects.values('name', 'category__name').annotate(name_count=Count('id')).filter(name_count__gt=1)

if not duplicates:
    print("No duplicate product names found.")
else:
    print(f"Found {len(duplicates)} duplicate product names:")
    for duplicate in duplicates:
        name = duplicate['name']
        cat_name = duplicate['category__name']
        count = duplicate['name_count']
        print(f"Name: {name}, Category: {cat_name}, Count: {count}")
        
        # List the details of these duplicates
        products = Product.objects.filter(name=name, category__name=cat_name)
        for p in products:
            print(f"  - ID: {p.id}, SKU: {p.sku}, Serial: {p.serial_number}, Color: {p.color}, Fabric: {p.fabric}, Qty: {p.quantity}, Active: {p.is_active}")
