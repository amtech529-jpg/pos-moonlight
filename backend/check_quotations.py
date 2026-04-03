
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from quotations.models import Quotation

print(f"Total Quotations: {Quotation.objects.count()}")

print("\nLast 5 Quotations:")
for q in Quotation.objects.all().order_by('-created_at')[:5]:
    status_text = q.status if hasattr(q, 'status') else 'No Status'
    print(f"ID: {q.id}, Customer: {q.customer_name if hasattr(q, 'customer_name') else 'N/A'}, Status: {status_text}")
