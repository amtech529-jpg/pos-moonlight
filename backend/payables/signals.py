from datetime import timedelta
from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver, Signal
from django.core.cache import cache
from django.utils import timezone
from .models import Payable, PayablePayment
import logging

logger = logging.getLogger(__name__)

# Custom signals for bulk operations
payable_bulk_updated = Signal()
payable_bulk_created = Signal()
payable_bulk_deleted = Signal()
payable_payment_added = Signal()


@receiver(pre_save, sender=Payable)
def payable_pre_save(sender, instance, **kwargs):
    """Handle payable pre-save operations"""
    try:
        if instance.pk:  # Existing payable
            try:
                old_instance = Payable.objects.get(pk=instance.pk)
                
                # Track amount changes
                if old_instance.amount_borrowed != instance.amount_borrowed:
                    instance._amount_changed = True
                    instance._old_amount = old_instance.amount_borrowed
                
                # Track creditor changes
                if old_instance.creditor_name != instance.creditor_name:
                    instance._creditor_changed = True
                    instance._old_creditor = old_instance.creditor_name
                
                # Track status changes
                if old_instance.status != instance.status:
                    instance._status_changed = True
                    instance._old_status = old_instance.status
                
                # Track priority changes
                if old_instance.priority != instance.priority:
                    instance._priority_changed = True
                    instance._old_priority = old_instance.priority
                    
            except Payable.DoesNotExist:
                pass
    except Exception as e:
        logger.error(f"Error in payable_pre_save: {e}")


@receiver(post_save, sender=Payable)
def payable_post_save(sender, instance, created, **kwargs):
    """Handle payable post-save operations"""
    try:
        # Clear related caches
        cache_keys_to_clear = [
            'payable_statistics',
            'overdue_payables',
            'urgent_payables',
            'payment_schedule',
            f'payables_by_creditor_{instance.creditor_name}',
            f'payables_by_vendor_{instance.vendor_id}' if getattr(instance, 'vendor_id', None) else None,
        ]
        
        # Remove None values and clear caches
        for key in filter(None, cache_keys_to_clear):
            cache.delete(key)
        
        # Log payable creation
        if created:
            logger.info(
                f"New payable created: {instance.creditor_name} - Amount: {instance.amount_borrowed} "
                f"(ID: {instance.id}) Due: {instance.expected_repayment_date} "
                f"Priority: {instance.priority}"
            )
            
            # Check for urgent/overdue conditions
            if instance.priority == 'URGENT':
                logger.warning(
                    f"URGENT payable created: {instance.creditor_name} - {instance.amount_borrowed} "
                    f"due {instance.expected_repayment_date}"
                )
            
            if instance.is_overdue:
                logger.warning(
                    f"OVERDUE payable created: {instance.creditor_name} - {instance.amount_borrowed} "
                    f"was due {instance.expected_repayment_date}"
                )
        
        # Log amount changes
        elif hasattr(instance, '_amount_changed'):
            logger.info(
                f"Payable amount updated: {instance.creditor_name} (ID: {instance.id}) "
                f"Amount changed from {instance._old_amount} to {instance.amount_borrowed}"
            )
            delattr(instance, '_amount_changed')
            delattr(instance, '_old_amount')
        
        # Log creditor changes
        if hasattr(instance, '_creditor_changed'):
            logger.info(
                f"Payable creditor updated: (ID: {instance.id}) "
                f"Creditor changed from {instance._old_creditor} to {instance.creditor_name}"
            )
            delattr(instance, '_creditor_changed')
            delattr(instance, '_old_creditor')
        
        # Log status changes
        if hasattr(instance, '_status_changed'):
            logger.info(
                f"Payable status updated: {instance.creditor_name} (ID: {instance.id}) "
                f"Status changed from {instance._old_status} to {instance.status}"
            )
            
            # Special logging for important status changes
            if instance.status == 'PAID':
                logger.info(
                    f"✅ Payable FULLY PAID: {instance.creditor_name} - {instance.amount_borrowed} "
                    f"completed on {timezone.now().date()}"
                )
            elif instance.status == 'OVERDUE':
                logger.warning(
                    f"⚠️ Payable OVERDUE: {instance.creditor_name} - {instance.balance_remaining} "
                    f"remaining, was due {instance.expected_repayment_date}"
                )
            elif instance.status == 'CANCELLED':
                logger.info(
                    f"❌ Payable CANCELLED: {instance.creditor_name} - {instance.amount_borrowed} "
                    f"cancelled on {timezone.now().date()}"
                )
            
            delattr(instance, '_status_changed')
            delattr(instance, '_old_status')
        
        # Log priority changes
        if hasattr(instance, '_priority_changed'):
            logger.info(
                f"Payable priority updated: {instance.creditor_name} (ID: {instance.id}) "
                f"Priority changed from {instance._old_priority} to {instance.priority}"
            )
            
            if instance.priority == 'URGENT':
                logger.warning(
                    f"🚨 Payable marked URGENT: {instance.creditor_name} - {instance.balance_remaining} "
                    f"remaining, due {instance.expected_repayment_date}"
                )
            
            delattr(instance, '_priority_changed')
            delattr(instance, '_old_priority')
    except Exception as e:
        logger.error(f"Error in payable_post_save: {e}")


@receiver(post_delete, sender=Payable)
def payable_post_delete(sender, instance, **kwargs):
    """Handle payable deletion"""
    # Clear related caches
    cache_keys_to_clear = [
        'payable_statistics',
        'overdue_payables',
        'urgent_payables',
        'payment_schedule',
        f'payables_by_creditor_{instance.creditor_name}',
        f'payables_by_vendor_{instance.vendor_id}' if instance.vendor_id else None,
    ]
    
    # Remove None values and clear caches
    for key in filter(None, cache_keys_to_clear):
        cache.delete(key)
    
    # Log payable deletion
    logger.info(
        f"Payable deleted: {instance.creditor_name} - Amount: {instance.amount_borrowed} "
        f"(ID: {instance.id}) Status: {instance.status} "
        f"Balance: {instance.balance_remaining}"
    )
@receiver(post_save, sender=PayablePayment)
def payable_payment_post_save(sender, instance, created, **kwargs):
    """Handle payable payment creation"""
    if created:
        # Clear related caches
        cache.delete('payable_statistics')
        cache.delete('payment_schedule')
        cache.delete(f'payables_by_creditor_{instance.payable.creditor_name}')
        if instance.payable.vendor_id:
            cache.delete(f'payables_by_vendor_{instance.payable.vendor_id}')
        
        # Log payment
        creator = instance.created_by.email if instance.created_by else "System/Unknown"
        logger.info(
            f"💰 Payment added: {instance.amount} to {instance.payable.creditor_name} "
            f"(Payable ID: {instance.payable.id}) on {instance.payment_date} "
            f"by {creator}"
        )
        
        # Check if payable is now fully paid
        instance.payable.refresh_from_db()
        if instance.payable.is_fully_paid:
            logger.info(
                f"🎉 Payable COMPLETED: {instance.payable.creditor_name} - "
                f"{instance.payable.amount_borrowed} fully paid with this payment"
            )
        
        # Send payment signal
        payable_payment_added.send(
            sender=PayablePayment,
            payment=instance,
            payable=instance.payable
        )


@receiver(payable_bulk_updated)
def handle_bulk_payable_update(sender, payables, action, **kwargs):
    """Handle bulk payable updates"""
    # Clear caches
    cache.delete('payable_statistics')
    cache.delete('overdue_payables')
    cache.delete('urgent_payables')
    cache.delete('payment_schedule')
    
    # Clear creditor and vendor specific caches
    for payable in payables:
        cache.delete(f'payables_by_creditor_{payable.creditor_name}')
        if payable.vendor_id:
            cache.delete(f'payables_by_vendor_{payable.vendor_id}')
    
    # Log bulk update
    payable_count = len(payables)
    logger.info(f"Bulk payable update completed: {action} applied to {payable_count} payables")
    
    # Specific logging for different actions
    if action == 'activate':
        logger.info(f"Payable activation: {payable_count} payables activated")
    
    elif action == 'deactivate':
        logger.info(f"Payable deactivation: {payable_count} payables deactivated")
    
    elif action.startswith('mark_'):
        priority = action.replace('mark_', '').upper()
        logger.info(f"Payable priority update: {payable_count} payables marked as {priority}")
        
        if priority == 'URGENT':
            total_amount = sum(p.balance_remaining for p in payables if not p.is_fully_paid)
            logger.warning(
                f"🚨 {payable_count} payables marked URGENT with total outstanding: {total_amount}"
            )
    
    elif action == 'cancel':
        total_amount = sum(p.balance_remaining for p in payables if not p.is_fully_paid)
        logger.info(f"Payable cancellation: {payable_count} payables cancelled, "
                   f"total cancelled amount: {total_amount}")


@receiver(payable_bulk_created)
def handle_bulk_payable_creation(sender, payables, **kwargs):
    """Handle bulk payable creation"""
    # Clear caches
    cache.delete('payable_statistics')
    cache.delete('payment_schedule')
    
    # Log bulk creation
    payable_count = len(payables)
    total_amount = sum(p.amount_borrowed for p in payables)
    logger.info(f"Bulk payable creation completed: {payable_count} payables created, "
               f"total amount: {total_amount}")
    
    # Log creditor breakdown
    creditors = {}
    priorities = {}
    for payable in payables:
        creditor = payable.creditor_name
        priority = payable.priority
        
        creditors[creditor] = creditors.get(creditor, 0) + 1
        priorities[priority] = priorities.get(priority, 0) + 1
    
    logger.info(f"New payables by creditor: {', '.join([f'{k}: {v}' for k, v in creditors.items()])}")
    logger.info(f"New payables by priority: {', '.join([f'{k}: {v}' for k, v in priorities.items()])}")
    
    # Check for urgent payables
    urgent_count = priorities.get('URGENT', 0)
    if urgent_count > 0:
        logger.warning(f"⚠️ {urgent_count} URGENT payables created in bulk operation")


@receiver(payable_bulk_deleted)
def handle_bulk_payable_deletion(sender, payable_ids, **kwargs):
    """Handle bulk payable deletion"""
    # Clear all payable-related caches
    cache_keys_to_clear = [
        'payable_statistics',
        'overdue_payables',
        'urgent_payables',
        'payment_schedule',
    ]
    
    for key in cache_keys_to_clear:
        cache.delete(key)
    
    # Log bulk deletion
    payable_count = len(payable_ids)
    logger.info(f"Bulk payable deletion completed: {payable_count} payables deleted")


@receiver(pre_save, sender=Payable)
def validate_payable_business_rules(sender, instance, **kwargs):
    """Additional business rule validation"""
    try:
        # Check for potential duplicate payables to same creditor
        if instance.creditor_name:
            duplicate_payables = Payable.objects.filter(
                creditor_name__iexact=instance.creditor_name,
                date_borrowed=instance.date_borrowed,
                amount_borrowed=instance.amount_borrowed,
                is_active=True
            ).exclude(pk=instance.pk)
            
            if duplicate_payables.exists():
                logger.warning(
                    f"Potential duplicate payable detected: {instance.creditor_name} - "
                    f"{instance.amount_borrowed} on {instance.date_borrowed}"
                )
        
        # Check for large amounts
        if instance.amount_borrowed and instance.amount_borrowed > 100000:  # 100K threshold
            logger.warning(
                f"Large payable amount detected: {instance.creditor_name} - "
                f"{instance.amount_borrowed} (ID: {instance.id})"
            )
        
        # Check for very old due dates
        if instance.expected_repayment_date:
            days_overdue = (timezone.now().date() - instance.expected_repayment_date).days
            if days_overdue > 90 and not instance.is_fully_paid:  # 90 days overdue
                logger.warning(
                    f"Very old overdue payable: {instance.creditor_name} - "
                    f"{instance.balance_remaining} overdue by {days_overdue} days"
                )
    except Exception as e:
        logger.error(f"Error in validate_payable_business_rules: {e}")


@receiver(post_save, sender=Payable)
def payable_analytics_tracking(sender, instance, created, **kwargs):
    """Track payable analytics and patterns"""
    try:
        if created:
            # Track creation patterns
            today = timezone.now().date()
            
            # Count payables created today
            today_count = Payable.objects.filter(
                date_borrowed=today,
                created_at__date=today
            ).count()
            
            # Count payables for this creditor
            creditor_count = Payable.objects.filter(
                creditor_name__iexact=instance.creditor_name,
                is_active=True
            ).count()
            
            # Log analytics
            logger.info(
                f"Payable analytics: {today_count} payables created today, "
                f"{creditor_count} total active payables for {instance.creditor_name}"
            )
            
            # Check for potential payment scheduling issues
            if getattr(instance, 'vendor_id', None):
                try:
                    if hasattr(instance.vendor, 'payables'):
                        vendor_payables = instance.vendor.payables.filter(
                            is_active=True,
                            is_fully_paid=False
                        ).count()
                        
                        if vendor_payables > 5:  # More than 5 active payables to same vendor
                            logger.warning(
                                f"Multiple payables to vendor: {instance.vendor.name} now has "
                                f"{vendor_payables} active payables"
                            )
                except Exception as e:
                    logger.warning(f"Error tracking vendor payables analytics: {e}")
    except Exception as e:
        logger.error(f"Error in payable_analytics_tracking: {e}")


@receiver(payable_payment_added)
def handle_payment_notifications(sender, payment, payable, **kwargs):
    """Handle payment-related notifications and analytics"""
    # Log payment patterns
    recent_payments = PayablePayment.objects.filter(
        payable=payable,
        payment_date__gte=timezone.now().date() - timedelta(days=30)
    ).count()
    
    logger.info(
        f"Payment pattern: {recent_payments} payments made to {payable.creditor_name} "
        f"in the last 30 days"
    )
    
    # Check for rapid payments (potential data entry errors)
    recent_rapid_payments = PayablePayment.objects.filter(
        payable=payable,
        payment_date=payment.payment_date
    ).count()
    
    if recent_rapid_payments > 1:
        logger.warning(
            f"Multiple payments on same date: {recent_rapid_payments} payments "
            f"to {payable.creditor_name} on {payment.payment_date}"
        )
    
    # Log payment completion
    if payable.is_fully_paid:
        days_to_complete = (payment.payment_date - payable.date_borrowed).days
        logger.info(
            f"Payment completion metrics: {payable.creditor_name} payable completed "
            f"in {days_to_complete} days (borrowed: {payable.date_borrowed}, "
            f"completed: {payment.payment_date})"
        )


@receiver(post_save, sender=Payable)
def check_overdue_alerts(sender, instance, created, **kwargs):
    """Check for overdue conditions and generate alerts"""
    if not created and instance.is_overdue and not instance.is_fully_paid:
        days_overdue = abs(instance.days_until_due)
        
        # Different alert levels based on days overdue
        if days_overdue <= 7:
            logger.info(
                f"📅 Recently overdue: {instance.creditor_name} - {instance.balance_remaining} "
                f"overdue by {days_overdue} days"
            )
        elif days_overdue <= 30:
            logger.warning(
                f"⚠️ Moderately overdue: {instance.creditor_name} - {instance.balance_remaining} "
                f"overdue by {days_overdue} days"
            )
        else:
            logger.error(
                f"🚨 SEVERELY overdue: {instance.creditor_name} - {instance.balance_remaining} "
                f"overdue by {days_overdue} days - IMMEDIATE ATTENTION REQUIRED"
            )


@receiver(pre_save, sender=PayablePayment)
def validate_payment_business_rules(sender, instance, **kwargs):
    """Validate payment business rules"""
    if instance.payable:
        # Check for payments on weekends (potential data entry errors)
        if instance.payment_date.weekday() >= 5:  # Saturday = 5, Sunday = 6
            logger.info(
                f"Weekend payment recorded: {instance.amount} to {instance.payable.creditor_name} "
                f"on {instance.payment_date}"
            )
        
        # Check for future dated payments
        if instance.payment_date > timezone.now().date():
            logger.warning(
                f"Future-dated payment: {instance.amount} to {instance.payable.creditor_name} "
                f"dated {instance.payment_date}"
            )
        
        # Check for very old payments
        days_old = (timezone.now().date() - instance.payment_date).days
        if days_old > 30:
            logger.warning(
                f"Old payment entry: {instance.amount} to {instance.payable.creditor_name} "
                f"payment date {instance.payment_date} ({days_old} days ago)"
            )
            

