
import os
import django
from decimal import Decimal
from django.utils import timezone

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from orders.models import Order
from customers.models import Customer
from products.models import Product
from order_items.models import OrderItem

def create_test_order():
    try:
        customer = Customer.objects.first()
        if not customer:
            print("No customer found to create order.")
            return

        product = Product.objects.first()
        if not product:
            print("No product found to create order.")
            return

        order = Order.objects.create(
            customer=customer,
            customer_name=customer.name,
            customer_phone=customer.phone,
            total_amount=Decimal('1000.00'),
            advance_payment=Decimal('200.00'),
            remaining_amount=Decimal('800.00'),
            date_ordered=timezone.now(),
            description="Test Order from Script",
            status='PENDING',
            is_active=True
        )

        OrderItem.objects.create(
            order=order,
            product=product,
            product_name=product.name,
            quantity=1,
            rate=Decimal('1000.00'),
            line_total=Decimal('1000.00')
        )

        print(f"Successfully created test order with ID: {order.id}")
    except Exception as e:
        print(f"Error creating test order: {e}")

if __name__ == "__main__":
    create_test_order()
