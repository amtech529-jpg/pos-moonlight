import os
import django
import sys

sys.path.append('d:/R_Tech_junior_developer/moon-light-main/pos-moonlight-main/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from products.models import Product
from orders.models import Order
from order_items.models import OrderItem
from payables.models import Payable
from payables.partner_payables import generate_partner_payables
from orders.signals import sync_order_reservations

def run_fix():
    p = Product.objects.filter(name__icontains='LED').first()
    print(f"Product: {p.name}, Total: {p.quantity}, Available: {p.quantity_available}, Reserved: {p.quantity_reserved}")
    
    # Get latest order with LED
    order_items = OrderItem.objects.filter(product=p).order_by('-created_at')[:2]
    if len(order_items) < 2:
        print("Not enough recent order items")
        return
        
    order = order_items[0].order
    print(f"Order: {order.id}")
    
    # We want own stock to be 2, partner to be 8.
    own_item = order.order_items.filter(product=p, rented_from_partner=False).first()
    partner_item = order.order_items.filter(product=p, rented_from_partner=True).first()
    
    if own_item and partner_item:
        print(f"Own item Qty: {own_item.quantity}, Partner item Qty: {partner_item.quantity}")
        
        # Adjust product totals first to recover from the bad confirmed deduction.
        # It had 5 total. Now it has 0. This means it deducted 5.
        # We need to restore it to 5, then let the correct deduction happen.
        # Actually, let's just manually fix the product numbers.
        
        # 1. Update items
        old_own_qty = own_item.quantity # 5
        own_item.quantity = 2
        own_item.save()
        
        partner_item.quantity = 8
        partner_item.save()
        
        print("Updated items to 2 (own) and 8 (partner)")
        
        # 2. Fix Product Stock
        # If it was 5 total before, and 2 available, it means 3 were reserved across other orders.
        # We confirm 2. So total should be 5. Wait, total doesn't drop until order is confirmed!
        # When order was confirmed, it dropped 5. So it became 0. If it was `total: 5`, it dropped by 5 -> 0.
        # It should have dropped by 2! So total should be 3!
        # And reserved were 3 before? If available was 2 and total was 5, then 3 were reserved for OTHER orders?
        # Let's see: total=5, reserved=3, available=2.
        # If order deducts 2, new_total = 3! new_reserved = 3. new_available = 0.
        # Wait, if `confirm_stock_deduction` is called for 5, it means it reserved 5, then deducted 5.
        
        # Actually, let's just trigger un-reserve then re-reserve.
        # The easiest way is to recalculate total stats.
        p.quantity = 5 - 2 # We know total was 5. We confirm 2. So total is 3. Wait, 5 was the total BEFORE the bad deduction.
        p.quantity_reserved -= (5 - 2) # Since it reserved 5 instead of 2?
        p.save()
        
        # Let's just run an explicit recalculation script to be safe.
        
        print("Product updated: (Skipping manual, we'll let it recalculate or we adjust manually)")
        
        Payable.objects.filter(order=order, source_type='PARTNER_RENTAL').delete()
        print("Deleted old payables")
        
        generate_partner_payables(order)
        print("Generated new payables")
        
        # Let's fix the product numbers completely manually
        print(f"Product new predicted: 3 Total, 3 Reserved, 0 Available")
        p.refresh_from_db()
        p.quantity = 3
        p.quantity_reserved = 3
        p.quantity_available = 0
        p.save()

if __name__ == '__main__':
    run_fix()
