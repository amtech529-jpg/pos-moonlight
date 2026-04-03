from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from .models import Payment
from django.db.models import Sum
from decimal import Decimal
import logging

logger = logging.getLogger(__name__)

@receiver(post_save, sender=Payment)
def payment_post_save(sender, instance, created, **kwargs):
    """Update related document totals when payment is saved"""
    update_related_totals(instance)

@receiver(post_delete, sender=Payment)
def payment_post_delete(sender, instance, **kwargs):
    """Update related document totals when payment is deleted"""
    update_related_totals(instance)

def update_related_totals(payment):
    """Recalculate totals for Order or Sale"""
    # Update Order
    if payment.order:
        try:
            order = payment.order
            # Calculate total payments for this order
            total_paid = Payment.objects.filter(order=order, is_active=True).aggregate(
                total=Sum('amount_paid')
            )['total'] or Decimal('0.00')
            
            order.advance_payment = total_paid
            order.calculate_payment_status() # Updates remaining_amount, is_fully_paid
            
            # Use update_fields to minimize side effects, but we DO want Order signals to fire (logging)
            order.save(update_fields=['advance_payment', 'remaining_amount', 'is_fully_paid', 'updated_at'])
            
            logger.info(f"Updated Order #{order.id} payment totals. New total paid: {total_paid}")
            
        except Exception as e:
            logger.error(f"Failed to update order totals for payment {payment.id}: {str(e)}")
            
    # Update Sale if exists
    if payment.sale:
        # Similar logic for Sale if Sale model supports it
        pass