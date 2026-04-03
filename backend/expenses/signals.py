from django.db.models.signals import post_save, post_delete, pre_save, pre_delete
from django.dispatch import receiver
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.core.cache import cache
from decimal import Decimal
import logging

from .models import Expense

User = get_user_model()

# Setup logging
logger = logging.getLogger('expenses')


@receiver(pre_save, sender=Expense)
def expense_pre_save(sender, instance, **kwargs):
    """
    Signal fired before saving an expense
    - Validate business rules
    - Set default values
    - Log changes for audit
    """
    # Check if this is an update or create
    if instance.pk:
        try:
            old_instance = Expense.objects.get(pk=instance.pk)
            instance._old_instance = old_instance
        except Expense.DoesNotExist:
            pass
    
    # Set default time if not provided
    if not instance.time:
        instance.time = timezone.now().time()
    
    # Validate amount is positive
    if instance.amount <= 0:
        logger.warning(f"Attempted to save expense with negative amount: {instance.amount}")
        raise ValueError("Expense amount must be positive")
    
    # Log pre-save information
    logger.info(f"Preparing to save expense: {instance.expense} - {instance.formatted_amount}")


@receiver(post_save, sender=Expense)
def expense_post_save(sender, instance, created, **kwargs):
    """
    Signal fired after saving an expense
    - Send notifications
    - Update cache
    - Log activity
    - Generate alerts for large expenses
    """
    if created:
        # New expense created
        logger.info(f"New expense created: {instance.expense} - {instance.formatted_amount} by {instance.created_by.full_name}")
        
        # Send notification for new expense
        send_expense_notification(instance, action='created')
        
        # Check for large expense alert
        if instance.amount > Decimal('50000.00'):  # Alert for expenses > 50,000 PKR
            send_large_expense_alert(instance)
        
        # Update daily expense cache
        update_daily_expense_cache(instance.date)
        
    else:
        # Existing expense updated
        old_instance = getattr(instance, '_old_instance', None)
        if old_instance:
            # Log changes
            changes = []
            fields_to_check = ['expense', 'amount', 'withdrawal_by', 'category', 'is_active']
            
            for field in fields_to_check:
                old_value = getattr(old_instance, field, None)
                new_value = getattr(instance, field, None)
                if old_value != new_value:
                    changes.append(f"{field}: {old_value} → {new_value}")
            
            if changes:
                logger.info(f"Expense updated - {instance.expense}: {', '.join(changes)}")
                send_expense_notification(instance, action='updated', changes=changes)
        
        # Update cache for both old and new dates if date changed
        if old_instance and old_instance.date != instance.date:
            update_daily_expense_cache(old_instance.date)
            update_daily_expense_cache(instance.date)
        else:
            update_daily_expense_cache(instance.date)
    
    # Clear related caches
    clear_expense_caches()


@receiver(pre_delete, sender=Expense)
def expense_pre_delete(sender, instance, **kwargs):
    """
    Signal fired before deleting an expense
    - Log deletion attempt
    - Validate deletion permissions
    """
    logger.warning(f"Attempting to delete expense: {instance.expense} - {instance.formatted_amount}")
    
    # Store instance data for post_delete signal
    instance._deletion_data = {
        'expense': instance.expense,
        'amount': instance.amount,
        'formatted_amount': instance.formatted_amount,
        'created_by': instance.created_by.full_name,
        'date': instance.date,
        'withdrawal_by': instance.withdrawal_by
    }


@receiver(post_delete, sender=Expense)
def expense_post_delete(sender, instance, **kwargs):
    """
    Signal fired after deleting an expense
    - Log deletion
    - Send notifications
    - Update cache
    """
    deletion_data = getattr(instance, '_deletion_data', {})
    
    logger.warning(f"Expense deleted: {deletion_data.get('expense', 'Unknown')} - {deletion_data.get('formatted_amount', 'Unknown amount')}")
    
    # Send deletion notification
    send_expense_notification(instance, action='deleted', deletion_data=deletion_data)
    
    # Update cache
    if deletion_data.get('date'):
        update_daily_expense_cache(deletion_data['date'])
    
    clear_expense_caches()


def send_expense_notification(expense_instance, action='created', changes=None, deletion_data=None):
    """
    Send email notifications for expense activities
    """
    try:
        # Define recipients (you can customize this based on your needs)
        recipients = []
        
        # Add finance team emails (customize as needed)
        finance_emails = getattr(settings, 'FINANCE_TEAM_EMAILS', [])
        recipients.extend(finance_emails)
        
        # Add admin emails for large expenses
        if hasattr(expense_instance, 'amount') and expense_instance.amount > Decimal('25000.00'):
            admin_emails = getattr(settings, 'ADMIN_EMAILS', [])
            recipients.extend(admin_emails)
        
        if not recipients:
            return  # No recipients configured
        
        # Prepare email content based on action
        if action == 'created':
            subject = f'New Expense Created: {expense_instance.expense}'
            message = f"""
            A new expense has been created:
            
            Expense: {expense_instance.expense}
            Amount: {expense_instance.formatted_amount}
            Authorized by: {expense_instance.withdrawal_by}
            Category: {expense_instance.category or 'N/A'}
            Date: {expense_instance.date}
            Created by: {expense_instance.created_by.full_name}
            
            Description: {expense_instance.description}
            """
            
        elif action == 'updated':
            subject = f'Expense Updated: {expense_instance.expense}'
            changes_text = '\n'.join(changes) if changes else 'No specific changes logged'
            message = f"""
            An expense has been updated:
            
            Expense: {expense_instance.expense}
            Amount: {expense_instance.formatted_amount}
            
            Changes made:
            {changes_text}
            
            Updated on: {timezone.now().strftime('%Y-%m-%d %H:%M:%S')}
            """
            
        elif action == 'deleted':
            subject = f'Expense Deleted: {deletion_data.get("expense", "Unknown")}'
            message = f"""
            An expense has been deleted:
            
            Expense: {deletion_data.get('expense', 'Unknown')}
            Amount: {deletion_data.get('formatted_amount', 'Unknown')}
            Originally authorized by: {deletion_data.get('withdrawal_by', 'Unknown')}
            Original date: {deletion_data.get('date', 'Unknown')}
            Originally created by: {deletion_data.get('created_by', 'Unknown')}
            
            Deleted on: {timezone.now().strftime('%Y-%m-%d %H:%M:%S')}
            """
        
        # Send email (only if email backend is configured properly)
        if hasattr(settings, 'EMAIL_HOST') and settings.EMAIL_HOST:
            send_mail(
                subject=subject,
                message=message,
                from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@example.com'),
                recipient_list=recipients,
                fail_silently=True  # Don't break the app if email fails
            )
            logger.info(f"Expense notification sent: {action} - {subject}")
        
    except Exception as e:
        logger.error(f"Failed to send expense notification: {str(e)}")


def send_large_expense_alert(expense_instance):
    """
    Send special alert for large expenses
    """
    try:
        # Get admin/manager emails
        admin_emails = getattr(settings, 'ADMIN_EMAILS', [])
        manager_emails = getattr(settings, 'MANAGER_EMAILS', [])
        
        recipients = list(set(admin_emails + manager_emails))  # Remove duplicates
        
        if not recipients:
            return
        
        subject = f'🚨 LARGE EXPENSE ALERT: {expense_instance.formatted_amount}'
        message = f"""
        ATTENTION: A large expense has been recorded
        
        ⚠️  AMOUNT: {expense_instance.formatted_amount}
        📝 EXPENSE: {expense_instance.expense}
        👤 AUTHORIZED BY: {expense_instance.withdrawal_by}
        📅 DATE: {expense_instance.date}
        👨‍💼 RECORDED BY: {expense_instance.created_by.full_name}
        🏷️  CATEGORY: {expense_instance.category or 'N/A'}
        
        Description:
        {expense_instance.description}
        
        Please review this expense for approval.
        
        Time: {timezone.now().strftime('%Y-%m-%d %H:%M:%S')}
        """
        
        if hasattr(settings, 'EMAIL_HOST') and settings.EMAIL_HOST:
            send_mail(
                subject=subject,
                message=message,
                from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@example.com'),
                recipient_list=recipients,
                fail_silently=True
            )
            logger.warning(f"Large expense alert sent: {expense_instance.formatted_amount}")
        
    except Exception as e:
        logger.error(f"Failed to send large expense alert: {str(e)}")


def update_daily_expense_cache(date):
    """
    Update daily expense cache for dashboard
    """
    try:
        from django.db.models import Sum
        
        # Calculate daily total
        daily_total = Expense.objects.filter(
            date=date,
            is_active=True
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')
        
        # Cache for 1 hour
        cache_key = f'daily_expense_{date.strftime("%Y%m%d")}'
        cache.set(cache_key, float(daily_total), 3600)
        
        logger.info(f"Updated daily expense cache for {date}: {daily_total}")
        
    except Exception as e:
        logger.error(f"Failed to update daily expense cache: {str(e)}")


def clear_expense_caches():
    """
    Clear expense-related caches
    """
    try:
        # List of cache keys to clear
        cache_keys = [
            'expense_statistics',
            'monthly_expense_summary',
            'recent_expenses',
            'expense_by_authority',
            'expense_by_category'
        ]
        
        cache.delete_many(cache_keys)
        logger.info("Cleared expense caches")
        
    except Exception as e:
        logger.error(f"Failed to clear expense caches: {str(e)}")


# Custom signal for expense approval workflow (if needed in future)
import django.dispatch

expense_approved = django.dispatch.Signal()
expense_rejected = django.dispatch.Signal()


@receiver(expense_approved)
def handle_expense_approval(sender, expense, approver, **kwargs):
    """
    Handle expense approval
    """
    logger.info(f"Expense approved: {expense.expense} by {approver.full_name}")
    
    # Send approval notification
    try:
        if hasattr(settings, 'EMAIL_HOST') and settings.EMAIL_HOST:
            send_mail(
                subject=f'Expense Approved: {expense.expense}',
                message=f"""
                Your expense has been approved:
                
                Expense: {expense.expense}
                Amount: {expense.formatted_amount}
                Approved by: {approver.full_name}
                Date: {timezone.now().strftime('%Y-%m-%d %H:%M:%S')}
                """,
                from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@example.com'),
                recipient_list=[expense.created_by.email],
                fail_silently=True
            )
    except Exception as e:
        logger.error(f"Failed to send approval notification: {str(e)}")


@receiver(expense_rejected)
def handle_expense_rejection(sender, expense, rejector, reason, **kwargs):
    """
    Handle expense rejection
    """
    logger.info(f"Expense rejected: {expense.expense} by {rejector.full_name}")
    
    # Send rejection notification
    try:
        if hasattr(settings, 'EMAIL_HOST') and settings.EMAIL_HOST:
            send_mail(
                subject=f'Expense Rejected: {expense.expense}',
                message=f"""
                Your expense has been rejected:
                
                Expense: {expense.expense}
                Amount: {expense.formatted_amount}
                Rejected by: {rejector.full_name}
                Reason: {reason}
                Date: {timezone.now().strftime('%Y-%m-%d %H:%M:%S')}
                
                Please contact finance team for more information.
                """,
                from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@example.com'),
                recipient_list=[expense.created_by.email],
                fail_silently=True
            )
    except Exception as e:
        logger.error(f"Failed to send rejection notification: {str(e)}")


# Utility functions for manual signal triggering
def trigger_expense_approval(expense, approver):
    """
    Manually trigger expense approval signal
    """
    expense_approved.send(sender=Expense, expense=expense, approver=approver)


def trigger_expense_rejection(expense, rejector, reason="Not specified"):
    """
    Manually trigger expense rejection signal
    """
    expense_rejected.send(sender=Expense, expense=expense, rejector=rejector, reason=reason)
    