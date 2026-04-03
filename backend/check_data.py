
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from orders.models import Order
from sales.models import Sales

print(f"Total Orders: {Order.objects.count()}")
print(f"Active Orders: {Order.objects.filter(is_active=True).count()}")
print(f"Inactive Orders: {Order.objects.filter(is_active=False).count()}")

print("\nLast 5 Orders:")
for order in Order.objects.order_by('-created_at')[:5]:
    print(f"ID: {order.id}, Customer: {order.customer_name}, Status: {order.status}, Active: {order.is_active}")

print(f"\nTotal Sales: {Sales.objects.count()}")
print(f"Active Sales: {Sales.objects.filter(is_active=True).count()}")
