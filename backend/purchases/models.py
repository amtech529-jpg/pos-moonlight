import uuid
from django.db import models
from django.utils import timezone
from vendors.models import Vendor
from products.models import Product


class Purchase(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    vendor = models.ForeignKey(
        Vendor,
        on_delete=models.PROTECT,
        related_name='purchases'
    )

    invoice_number = models.CharField(max_length=100, blank=True, null=True)
    purchase_date = models.DateField(default=timezone.now)

    subtotal = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    tax = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    # ✅ FIX: Added default=0 to prevent crash during initial creation
    total = models.DecimalField(max_digits=12, decimal_places=2, default=0)

    status = models.CharField(
        max_length=20,
        choices=[('draft', 'Draft'), ('posted', 'Posted')],
        default='posted'
    )

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Purchase {self.id} - {self.vendor.name}"


class PurchaseItem(models.Model):
    purchase = models.ForeignKey(
        Purchase,
        on_delete=models.CASCADE,
        related_name='items'
    )

    product = models.ForeignKey(Product, on_delete=models.PROTECT)

    quantity = models.DecimalField(max_digits=10, decimal_places=2)
    unit_cost = models.DecimalField(max_digits=12, decimal_places=2)
    total_cost = models.DecimalField(max_digits=12, decimal_places=2)
    description = models.TextField(
        blank=True,
        null=True,
        help_text="Description or notes for this purchase item"
    )

    def __str__(self):
        return f"{self.product.name} ({self.quantity})"