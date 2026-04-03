
import os
import django
import sys

# Add backend to path
sys.path.append('d:/R_Tech_junior_developer/moon-light-main/pos-moonlight-main/backend')

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from orders.models import Order
from order_items.models import OrderItem
from payables.models import Payable
from payables.partner_payables import generate_partner_payables
from orders.signals import sync_order_reservations

def run_fix():
    # Order with DJ Electric 15 units
    order_id = '37c88feb-45cd-4661-adb2-12d4dd895541'
    try:
        order = Order.objects.get(id=order_id)
        # Find item to split
        item = OrderItem.objects.filter(order=order, product_name__icontains='DJ Electric', rented_from_partner=True).first()
        
        if not item:
            # Maybe it already split?
            item = OrderItem.objects.filter(order=order, product_name__icontains='DJ Electric', rented_from_partner=False).first()
            if item and item.quantity == 10:
                 print("Item already split. Re-syncing...")
                 Payable.objects.filter(order=order, source_type='PARTNER_RENTAL').delete()
                 sync_order_reservations(order)
                 generate_partner_payables(order)
                 print("Re-sync complete.")
                 return
            print("No item found to split.")
            return

        partner_id = item.partner_id
        product = item.product
        item_qty = item.quantity
        
        print(f"Splitting item: {item.product_name}, Total Qty: {item_qty}")
        
        # 1. Update existing item to 10 (Own Stock)
        item.quantity = 10
        item.rented_from_partner = False
        item.partner = None
        item.save()
        print(f"Updated item 1: {item.product_name}, Qty: 10, Partner: False")
        
        # 2. Create new item for 5 (Partner Rental)
        new_item = OrderItem.objects.create(
            order=order,
            product=product,
            product_name=item.product_name,
            quantity=item_qty - 10,
            rented_from_partner=True,
            partner_id=partner_id,
            rate=item.rate,
            partner_rate=item.partner_rate,
            days=item.days
        )
        print(f"Created item 2: {new_item.product_name}, Qty: {item_qty - 10}, Partner: True")
        
        # 3. Cleanup existing payables for this order (if any)
        Payable.objects.filter(order=order, source_type='PARTNER_RENTAL').delete()
        print("Deleted old partner payables.")
        
        # 4. Re-sync order reservations (this will deduct 10 from stock!)
        sync_order_reservations(order)
        print("Synced order reservations.")
        
        # 5. Re-generate partner payables (this will create payable for 5)
        generate_partner_payables(order)
        print("Generated new partner payables.")
        
        print("\nFix completed successfully!")
        
    except Order.DoesNotExist:
        print(f"Order {order_id} not found.")
    except Exception as e:
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    run_fix()
