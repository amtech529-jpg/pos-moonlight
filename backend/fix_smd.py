import os
import sys
import django

sys.path.insert(0, 'd:/R_Tech_junior_developer/moon-light-main/pos-moonlight-main/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from products.models import Product, StockReservation
from orders.models import Order
from order_items.models import OrderItem
from orders.signals import sync_order_reservations

p = Product.objects.filter(name='SMD Bulb', is_active=True).first()
print(f'BEFORE: Total={p.quantity}, Available={p.quantity_available}, Reserved={p.quantity_reserved}')

# Problem: Total is 64 but should be 41 (original).
# Old code was subtracting from quantity on confirmation, making it go from 41:
#   - order1 = 13 → 41-13 = 28
#   - We see 64, so total was INCREASED at some point (maybe via purchase/edit)
# Now total must stay as-is and only available must be recalculated.

# Get all confirmed orders using this product 
active_orders = Order.objects.filter(
    order_items__product=p,
    order_items__rented_from_partner=False,
    status__in=['CONFIRMED', 'READY', 'DELIVERED']
).distinct()

print(f'Found {active_orders.count()} confirmed orders using SMD Bulb')
for order in active_orders:
    items = OrderItem.objects.filter(order=order, product=p, rented_from_partner=False)
    for item in items:
        print(f'  Order qty={item.quantity}, status={order.status}')
    sync_order_reservations(order)

p.refresh_from_db()
print(f'AFTER sync: Total={p.quantity}, Available={p.quantity_available}, Reserved={p.quantity_reserved}')

# Now manually recalculate - total booked in all active orders
total_booked = sum(
    i.quantity for i in OrderItem.objects.filter(
        product=p, 
        rented_from_partner=False,
        order__status__in=['CONFIRMED', 'READY', 'DELIVERED'],
        is_active=True
    )
)
print(f'Total booked in active orders: {total_booked}')
correct_available = max(0, p.quantity - total_booked)
print(f'Correct available should be: {correct_available}/{p.quantity}')

# Fix available quantity based on total_booked
p.quantity_reserved = total_booked
p.quantity_available = correct_available
p.save(update_fields=['quantity_reserved', 'quantity_available', 'updated_at'])
print(f'FIXED: {p.quantity_available}/{p.quantity}')
