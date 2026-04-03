
import os
import django
from decimal import Decimal

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from products.models import Product, StockReservation
from sale_items.models import SaleItem
from purchases.models import PurchaseItem
from order_items.models import OrderItem

def merge_products():
    master_id = 'f024d8db-09c2-4a43-9703-7c776fc10acf' # PROD-1DBB0B54
    duplicate_ids = [
        'b229f9bd-d644-4e78-b941-23af80a442b0', # PROD-38AFDE54
        'e9fc292a-6ea6-4d9a-99a2-ba0c97b28292'  # PROD-A264F572
    ]

    master = Product.objects.get(id=master_id)
    print(f"Master Product: {master.name} ({master.sku})")
    print(f"Initial Qty: {master.quantity}")

    total_qty = master.quantity
    total_damaged = master.quantity_damaged

    for dup_id in duplicate_ids:
        dup = Product.objects.get(id=dup_id)
        print(f"\nMerging Duplicate: {dup.name} ({dup.sku})")
        print(f"Qty to add: {dup.quantity}")
        
        # 1. Move StockReservations
        res_count = StockReservation.objects.filter(product=dup).update(product=master)
        print(f"Moved {res_count} Reservations")

        # 2. Move PurchaseItems
        pur_count = PurchaseItem.objects.filter(product=dup).update(product=master)
        print(f"Moved {pur_count} Purchase Items")

        # 3. Move SaleItems
        sale_count = SaleItem.objects.filter(product=dup).update(product=master)
        print(f"Moved {sale_count} Sale Items")

        # 4. Move OrderItems
        order_count = OrderItem.objects.filter(product=dup).update(product=master)
        print(f"Moved {order_count} Order Items")

        # Add quantity
        total_qty += dup.quantity
        total_damaged += dup.quantity_damaged

        # Deactivate duplicate
        dup.is_active = False
        dup.quantity = 0
        # Change name to avoid unique conflicts if any (though usually not an issue with UUID pk, but validation might check)
        dup.name = f"{dup.name} (DELETED DUPLICATE)"
        dup.save()
        print(f"Deactivated duplicate {dup.sku}")

    # Update master
    master.quantity = total_qty
    master.quantity_damaged = total_damaged
    master.save()
    
    # Recalculate derived quantities
    master.update_available_quantity()
    
    print(f"\nFinal Master Qty: {master.quantity}")
    print("Merge Complete!")

if __name__ == "__main__":
    merge_products()
