import logging
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.db import transaction
from purchases.models import Purchase, PurchaseItem
from payables.models import Payable

logger = logging.getLogger(__name__)


# ===============================
# STOCK UPDATE ON PURCHASE ITEM
# ===============================
# STOCK UPDATES DISABLED HERE - MOVED TO VIEWS.PY TO PREVENT MULTIPLE UPDATES
@receiver(post_save, sender=PurchaseItem)
def increase_stock_on_purchase_item(sender, instance, created, **kwargs):
    pass # Logic moved to views.py to ensure single source of truth


# ========================================
# STOCK UPDATE ON PURCHASE STATUS CHANGE
# ========================================
# STATUS TRANSITION UPDATES DISABLED HERE - MOVED TO VIEWS.PY
@receiver(pre_save, sender=Purchase)
def handle_purchase_status_transition(sender, instance, **kwargs):
    pass # Logic moved to views.py


# ====================================
# PAYABLE CREATION ON PURCHASE POSTED
# ====================================
@receiver(post_save, sender=Purchase)
def create_or_update_payable_on_purchase(sender, instance, created, **kwargs):
    """
    Create or update payable when a purchase is POSTED.
    """
    # Ignore drafts or zero-total purchases
    if instance.status != "posted" or instance.total <= 0:
        return

    try:
        # ✅ Use date() to ensure it's a date object, not datetime
        purchase_date = instance.purchase_date
        if hasattr(purchase_date, 'date'):
            purchase_date = purchase_date.date()

        payable, payable_created = Payable.objects.get_or_create(
            purchase=instance,
            defaults={
                "vendor": instance.vendor,
                "creditor_name": instance.vendor.name if instance.vendor else "Unknown Vendor",
                "amount_borrowed": instance.total,
                "amount_paid": 0,
                "reason_or_item": f"Purchase {instance.invoice_number or 'N/A'}",
                "date_borrowed": purchase_date,
                "expected_repayment_date": purchase_date,
            }
        )

        # Sync amount if purchase total changes
        if not payable_created and payable.amount_borrowed != instance.total:
            payable.amount_borrowed = instance.total
            payable.save()

        logger.info(f"✅ Payable {'created' if payable_created else 'updated'} for purchase {instance.pk}")
    except Exception as e:
        logger.error(f"❌ Error creating/updating payable for purchase {instance.pk}: {e}")
        # ✅ Don't raise - let the purchase save succeed even if payable creation fails