from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver, Signal
from django.core.cache import cache
from django.utils import timezone
from decimal import Decimal
from .models import AdvancePayment
import logging

logger = logging.getLogger(__name__)

# Custom signals for bulk operations
advance_payment_bulk_updated = Signal()
advance_payment_bulk_created = Signal()
advance_payment_bulk_deleted = Signal()


@receiver(pre_save, sender=AdvancePayment)
def advance_payment_pre_save(sender, instance, **kwargs):
    """Handle advance payment pre-save operations"""
    if instance.pk:  # Existing payment
        try:
            old_instance = AdvancePayment.objects.get(pk=instance.pk)
            
            # Track amount changes
            if old_instance.amount != instance.amount:
                instance._amount_changed = True
                instance._old_amount = old_instance.amount
            
            # Track date changes
            if old_instance.date != instance.date:
                instance._date_changed = True
                instance._old_date = old_instance.date
            
            # Track labor changes
            if old_instance.labor_id != instance.labor_id:
                instance._labor_changed = True
                instance._old_labor_name = old_instance.labor_name
            
            # Track receipt changes
            if old_instance.receipt_image_path != instance.receipt_image_path:
                instance._receipt_changed = True
                
        except AdvancePayment.DoesNotExist:
            pass


@receiver(post_save, sender=AdvancePayment)
def advance_payment_post_save(sender, instance, created, **kwargs):
    """Handle advance payment post-save operations"""
    # Clear related caches
    cache_keys_to_clear = [
        'advance_payment_statistics',
        'today_advance_payments',
        'recent_advance_payments',
        'monthly_advance_report',
        'labor_advance_report',
        f'labor_advance_summary_{instance.labor_id}' if instance.labor_id else None,
        f'advance_payments_by_labor_{instance.labor_id}' if instance.labor_id else None,
    ]
    
    # Remove None values and clear caches
    for key in filter(None, cache_keys_to_clear):
        cache.delete(key)
    
    # Log advance payment creation
    if created:
        logger.info(
            f"New advance payment created: {instance.labor_name} - {instance.amount} PKR "
            f"(Date: {instance.date}, Labor ID: {instance.labor_id}) "
            f"by user {instance.created_by}"
        )
        
        # Log if amount is significant (more than 50% of salary)
        if instance.total_salary and instance.amount > (instance.total_salary * Decimal('0.5')):
            logger.warning(
                f"Large advance payment: {instance.labor_name} received {instance.amount} PKR "
                f"which is {instance.advance_percentage}% of monthly salary"
            )
    
    # Log amount changes
    elif hasattr(instance, '_amount_changed'):
        old_amount = getattr(instance, '_old_amount', 'Unknown')
        logger.info(
            f"Advance payment amount updated: {instance.labor_name} "
            f"Amount changed from {old_amount} to {instance.amount} PKR"
        )
        delattr(instance, '_amount_changed')
        if hasattr(instance, '_old_amount'):
            delattr(instance, '_old_amount')
    
    # Log date changes
    if hasattr(instance, '_date_changed'):
        old_date = getattr(instance, '_old_date', 'Unknown')
        logger.info(
            f"Advance payment date updated: {instance.labor_name} "
            f"Date changed from {old_date} to {instance.date}"
        )
        delattr(instance, '_date_changed')
        if hasattr(instance, '_old_date'):
            delattr(instance, '_old_date')
    
    # Log labor changes
    if hasattr(instance, '_labor_changed'):
        old_labor_name = getattr(instance, '_old_labor_name', 'Unknown')
        logger.info(
            f"Advance payment labor updated: Labor changed from {old_labor_name} "
            f"to {instance.labor_name} for payment of {instance.amount} PKR"
        )
        delattr(instance, '_labor_changed')
        if hasattr(instance, '_old_labor_name'):
            delattr(instance, '_old_labor_name')
    
    # Log receipt changes
    if hasattr(instance, '_receipt_changed'):
        receipt_status = "added" if instance.receipt_image_path else "removed"
        logger.info(
            f"Advance payment receipt {receipt_status}: {instance.labor_name} - "
            f"{instance.amount} PKR ({instance.date})"
        )
        delattr(instance, '_receipt_changed')


@receiver(post_delete, sender=AdvancePayment)
def advance_payment_post_delete(sender, instance, **kwargs):
    """Handle advance payment deletion"""
    # Clear related caches
    cache_keys_to_clear = [
        'advance_payment_statistics',
        'today_advance_payments',
        'recent_advance_payments',
        'monthly_advance_report',
        'labor_advance_report',
        f'labor_advance_summary_{instance.labor_id}' if instance.labor_id else None,
        f'advance_payments_by_labor_{instance.labor_id}' if instance.labor_id else None,
    ]
    
    # Remove None values and clear caches
    for key in filter(None, cache_keys_to_clear):
        cache.delete(key)
    
    # Log advance payment deletion
    logger.info(
        f"Advance payment deleted: {instance.labor_name} - {instance.amount} PKR "
        f"(Date: {instance.date}, Labor ID: {instance.labor_id})"
    )


@receiver(advance_payment_bulk_updated)
def handle_bulk_advance_payment_update(sender, payments, action, **kwargs):
    """Handle bulk advance payment updates"""
    # Clear caches
    cache.delete('advance_payment_statistics')
    cache.delete('today_advance_payments')
    cache.delete('recent_advance_payments')
    cache.delete('monthly_advance_report')
    cache.delete('labor_advance_report')
    
    # Clear labor-specific caches
    labor_ids = set()
    for payment in payments:
        if payment.labor_id:
            labor_ids.add(payment.labor_id)
    
    for labor_id in labor_ids:
        cache.delete(f'labor_advance_summary_{labor_id}')
        cache.delete(f'advance_payments_by_labor_{labor_id}')
    
    # Log bulk update
    payment_count = len(payments)
    logger.info(f"Bulk advance payment update completed: {action} applied to {payment_count} payments")
    
    # Specific logging for different actions
    if action == 'activate':
        logger.info(f"Advance payment activation: {payment_count} payments activated")
    
    elif action == 'deactivate':
        logger.info(f"Advance payment deactivation: {payment_count} payments deactivated")
    
    elif action == 'delete':
        logger.info(f"Advance payment deletion: {payment_count} payments deleted")


@receiver(advance_payment_bulk_created)
def handle_bulk_advance_payment_creation(sender, payments, **kwargs):
    """Handle bulk advance payment creation"""
    # Clear caches
    cache.delete('advance_payment_statistics')
    cache.delete('today_advance_payments')
    cache.delete('recent_advance_payments')
    cache.delete('monthly_advance_report')
    cache.delete('labor_advance_report')
    
    # Log bulk creation
    payment_count = len(payments)
    logger.info(f"Bulk advance payment creation completed: {payment_count} payments created")
    
    # Log labor breakdown
    labors = {}
    total_amount = 0
    for payment in payments:
        labor_name = payment.labor_name or 'Unknown'
        labors[labor_name] = labors.get(labor_name, 0) + 1
        total_amount += payment.amount
    
    logger.info(f"New advance payments by labor: {', '.join([f'{k}: {v}' for k, v in labors.items()])}")
    logger.info(f"Total amount in bulk creation: {total_amount} PKR")


@receiver(advance_payment_bulk_deleted)
def handle_bulk_advance_payment_deletion(sender, payment_ids, **kwargs):
    """Handle bulk advance payment deletion"""
    # Clear all advance payment-related caches
    cache_keys_to_clear = [
        'advance_payment_statistics',
        'today_advance_payments',
        'recent_advance_payments',
        'monthly_advance_report',
        'labor_advance_report',
    ]
    
    for key in cache_keys_to_clear:
        cache.delete(key)
    
    # Log bulk deletion
    payment_count = len(payment_ids)
    logger.info(f"Bulk advance payment deletion completed: {payment_count} payments deleted")


@receiver(post_save, sender=AdvancePayment)
def advance_payment_data_quality_check(sender, instance, created, **kwargs):
    """Perform data quality checks on advance payment information"""
    issues = []
    
    # Check for unusually high advance amounts
    if instance.total_salary and instance.amount > instance.total_salary:
        issues.append("Advance amount exceeds monthly salary")
    
    # Check for advance percentage
    if instance.advance_percentage > 80:
        issues.append(f"High advance percentage: {instance.advance_percentage}%")
    
    # Check for missing receipt on large amounts
    if instance.amount > Decimal('50000') and not instance.receipt_image_path:
        issues.append("Large advance payment without receipt")
    
    # Check for multiple advances on same day
    if created:
        same_day_payments = AdvancePayment.objects.filter(
            labor=instance.labor,
            date=instance.date,
            is_active=True
        ).exclude(pk=instance.pk).count()
        
        if same_day_payments > 0:
            issues.append("Multiple advance payments on same day")
    
    # Check for advance frequency (more than 3 in a month)
    if created and instance.labor_id:
        month_payments = AdvancePayment.objects.filter(
            labor=instance.labor,
            date__year=instance.date.year,
            date__month=instance.date.month,
            is_active=True
        ).count()
        
        if month_payments > 3:
            issues.append(f"High frequency: {month_payments} advances this month")
    
    # Log data quality issues
    if issues:
        logger.warning(
            f"Advance payment data quality issues for {instance.labor_name} "
            f"({instance.amount} PKR on {instance.date}): {', '.join(issues)}"
        )


@receiver(post_save, sender=AdvancePayment)
def advance_payment_analytics(sender, instance, created, **kwargs):
    """Track advance payment analytics and insights"""
    if created:
        from datetime import date
        from django.db import models
        today = date.today()
        
        # Count advances by labor today
        labor_advances_today = AdvancePayment.objects.filter(
            labor=instance.labor,
            date=today,
            is_active=True
        ).count()
        
        # Count total advances today
        total_advances_today = AdvancePayment.objects.filter(
            date=today,
            is_active=True
        ).count()
        
        # Calculate today's total amount
        today_amount = AdvancePayment.objects.filter(
            date=today,
            is_active=True
        ).aggregate(total=models.Sum('amount'))['total'] or Decimal('0')
        
        # Log analytics
        logger.info(
            f"Advance payment analytics: {instance.labor_name} now has {labor_advances_today} "
            f"advances today. Total advances today: {total_advances_today}, "
            f"Total amount today: {today_amount} PKR"
        )


@receiver(pre_save, sender=AdvancePayment)
def validate_advance_payment_data_integrity(sender, instance, **kwargs):
    """Additional data integrity validation"""
    # Check for potential duplicate payments
    if instance.labor_id and instance.date and instance.amount:
        duplicate_payments = AdvancePayment.objects.filter(
            labor=instance.labor,
            date=instance.date,
            amount=instance.amount,
            is_active=True
        ).exclude(pk=instance.pk)
        
        if duplicate_payments.exists():
            logger.warning(
                f"Potential duplicate advance payment detected: {instance.labor_name} - "
                f"{instance.amount} PKR on {instance.date}"
            )
    
    # Validate amount vs labor salary consistency
    if instance.labor_id and instance.amount and instance.total_salary:
        # Convert to Decimal for proper calculation
        salary_limit = instance.total_salary * Decimal('1.5')  # More than 150% of salary
        if instance.amount > salary_limit:
            logger.warning(
                f"Extremely high advance amount for {instance.labor_name}: "
                f"{instance.amount} PKR (Salary: {instance.total_salary} PKR)"
            )
    
    # Check for backdated payments (more than 30 days old)
    if instance.date:
        from datetime import timedelta, date
        thirty_days_ago = date.today() - timedelta(days=30)
        if instance.date < thirty_days_ago:
            logger.warning(
                f"Backdated advance payment: {instance.labor_name} - "
                f"{instance.amount} PKR dated {instance.date}"
            )


@receiver(post_save, sender=AdvancePayment)
def advance_payment_security_audit(sender, instance, created, **kwargs):
    """Security and compliance audit logging"""
    if created:
        logger.info(
            f"AUDIT: New advance payment record created - Labor: {instance.labor_name}, "
            f"Amount: {instance.amount} PKR, Date: {instance.date}, "
            f"Receipt: {'Yes' if instance.receipt_image_path else 'No'}, "
            f"Created by: {instance.created_by}"
        )
    else:
        # Log significant updates
        changes = []
        if hasattr(instance, '_amount_changed'):
            changes.append(f"amount updated to {instance.amount} PKR")
        if hasattr(instance, '_date_changed'):
            changes.append(f"date updated to {instance.date}")
        if hasattr(instance, '_labor_changed'):
            changes.append(f"labor updated to {instance.labor_name}")
        if hasattr(instance, '_receipt_changed'):
            receipt_status = "added" if instance.receipt_image_path else "removed"
            changes.append(f"receipt {receipt_status}")
        
        if changes:
            logger.info(
                f"AUDIT: Advance payment record updated - Labor: {instance.labor_name}, "
                f"Payment ID: {instance.id}, Changes: {'; '.join(changes)}"
            )
            