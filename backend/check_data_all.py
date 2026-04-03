
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from customers.models import Customer
from products.models import Product
from orders.models import Order
from sales.models import Sales

print(f"Total Customers: {Customer.objects.count()}")
print(f"Total Products: {Product.objects.count()}")
print(f"Total Orders: {Order.objects.count()}")
print(f"Total Sales: {Sales.objects.count()}")
