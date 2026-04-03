
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from products.models import Product, StockReservation
from sale_items.models import SaleItem
from purchases.models import PurchaseItem

product_ids = [
    'b229f9bd-d644-4e78-b941-23af80a442b0',
    'e9fc292a-6ea6-4d9a-99a2-ba0c97b28292',
    'f024d8db-09c2-4a43-9703-7c776fc10acf'
]

for pid in product_ids:
    p = Product.objects.get(id=pid)
    sales_count = SaleItem.objects.filter(product=p).count()
    reservations_count = StockReservation.objects.filter(product=p).count()
    purchases_count = PurchaseItem.objects.filter(product=p).count()
    print(f"Product: {p.name} ({p.sku}), Sales: {sales_count}, Reservations: {reservations_count}, Purchases: {purchases_count}")
