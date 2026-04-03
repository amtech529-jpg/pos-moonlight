from django.db.models.signals import post_save, post_delete, pre_save, pre_delete
from django.dispatch import receiver
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.core.cache import cache
from decimal import Decimal
import logging

from .models import Zakat

User = get_user_model()

# Setup logging
logger = logging.getLogger('zakat')


@receiver(pre_save, sender=Zakat)
def zakat_pre_save(sender, instance, **kwargs):
    """
    Signal fired before saving a Zakat entry
    - Validate business rules
    - Set default values
    - Log changes for audit
    """
    # Check if this is an update or create
    if instance.pk:
        try:
            old_instance = Zakat.objects.get(pk=instance.pk)
            instance._old_instance = old_instance
        except Zakat.DoesNotExist:
            pass
    
    # Set default time if not provided
    if not instance.time:
        instance.time = timezone.now().time()
    
    # Validate amount is positive
    if instance.amount <= 0:
        logger.warning(f"Attempted to save Zakat with negative amount: {instance.amount}")
        raise ValueError("Zakat amount must be positive")
    
    # Validate beneficiary name is provided
    if not instance.beneficiary_name or not instance.beneficiary_name.strip():
        logger.warning(f"Attempted to save Zakat without beneficiary name")
        raise ValueError("Beneficiary name is required for all Zakat entries")
    
    # Log pre-save information
    logger.info(f"Preparing to save Zakat: {instance.name} - {instance.formatted_amount} for {instance.beneficiary_name}")


@receiver(post_save, sender=Zakat)
def zakat_post_save(sender, instance, created, **kwargs):
    """
    Signal fired after saving a Zakat entry
    - Send notifications
    - Update cache
    - Log activity
    - Generate alerts for large distributions
    """
    if created:
        # New Zakat entry created
        logger.info(f"New Zakat entry created: {instance.name} - {instance.formatted_amount} for {instance.beneficiary_name} by {instance.created_by.full_name}")
        
        # Send notification for new Zakat entry
        send_zakat_notification(instance, action='created')
        
        # Check for large Zakat alert
        if instance.amount > Decimal('50000.00'):  # Alert for Zakat > 50,000 PKR
            send_large_zakat_alert(instance)
        
        # Update daily Zakat cache
        update_daily_zakat_cache(instance.date)
        
    else:
        # Existing Zakat entry updated
        old_instance = getattr(instance, '_old_instance', None)
        if old_instance:
            # Log changes
            changes = []
            fields_to_check = ['name', 'amount', 'authorized_by', 'beneficiary_name', 'is_active']
            
            for field in fields_to_check:
                old_value = getattr(old_instance, field, None)
                new_value = getattr(instance, field, None)
                if old_value != new_value:
                    changes.append(f"{field}: {old_value} → {new_value}")
            
            if changes:
                logger.info(f"Zakat entry updated - {instance.name}: {', '.join(changes)}")
                send_zakat_notification(instance, action='updated', changes=changes)
        
        # Update cache for both old and new dates if date changed
        if old_instance and old_instance.date != instance.date:
            update_daily_zakat_cache(old_instance.date)
            update_daily_zakat_cache(instance.date)
        else:
            update_daily_zakat_cache(instance.date)
    
    # Clear related caches
    clear_zakat_caches()


@receiver(pre_delete, sender=Zakat)
def zakat_pre_delete(sender, instance, **kwargs):
    """
    Signal fired before deleting a Zakat entry
    - Log deletion attempt
    - Validate deletion permissions
    """
    logger.warning(f"Attempting to delete Zakat entry: {instance.name} - {instance.formatted_amount} for {instance.beneficiary_name}")
    
    # Store instance data for post_delete signal
    instance._deletion_data = {
        'name': instance.name,
        'amount': instance.amount,
        'formatted_amount': instance.formatted_amount,
        'created_by': instance.created_by.full_name,
        'date': instance.date,
        'authorized_by': instance.authorized_by,
        'beneficiary_name': instance.beneficiary_name
    }


@receiver(post_delete, sender=Zakat)
def zakat_post_delete(sender, instance, **kwargs):
    """
    Signal fired after deleting a Zakat entry
    - Log deletion
    - Send notifications
    - Update cache
    """
    deletion_data = getattr(instance, '_deletion_data', {})
    
    logger.warning(f"Zakat entry deleted: {deletion_data.get('name', 'Unknown')} - {deletion_data.get('formatted_amount', 'Unknown amount')} for {deletion_data.get('beneficiary_name', 'Unknown beneficiary')}")
    
    # Send deletion notification
    send_zakat_notification(instance, action='deleted', deletion_data=deletion_data)
    
    # Update cache
    if deletion_data.get('date'):
        update_daily_zakat_cache(deletion_data['date'])
    
    clear_zakat_caches()


def send_zakat_notification(zakat_instance, action='created', changes=None, deletion_data=None):
    """
    Send email notifications for Zakat activities
    """
    try:
        # Define recipients (you can customize this based on your needs)
        recipients = []
        
        # Add Islamic affairs team emails (customize as needed)
        islamic_affairs_emails = getattr(settings, 'ISLAMIC_AFFAIRS_EMAILS', [])
        recipients.extend(islamic_affairs_emails)
        
        # Add admin emails for large distributions
        if hasattr(zakat_instance, 'amount') and zakat_instance.amount > Decimal('25000.00'):
            admin_emails = getattr(settings, 'ADMIN_EMAILS', [])
            recipients.extend(admin_emails)
        
        if not recipients:
            return  # No recipients configured
        
        # Prepare email content based on action
        if action == 'created':
            subject = f'New Zakat Distribution: {zakat_instance.name}'
            message = f"""
            بسم الله الرحمن الرحيم
            
            A new Zakat distribution has been recorded:
            
            Distribution Name: {zakat_instance.name}
            Amount: {zakat_instance.formatted_amount}
            Authorized by: {zakat_instance.authorized_by}
            Beneficiary: {zakat_instance.beneficiary_name}
            Contact: {zakat_instance.beneficiary_contact or 'N/A'}
            Date: {zakat_instance.date}
            Recorded by: {zakat_instance.created_by.full_name}
            
            Description: {zakat_instance.description}
            
            Additional Notes: {zakat_instance.notes or 'None'}
            
            May Allah accept this charitable giving.
            """
            
        elif action == 'updated':
            subject = f'Zakat Distribution Updated: {zakat_instance.name}'
            changes_text = '\n'.join(changes) if changes else 'No specific changes logged'
            message = f"""
            بسم الله الرحمن الرحيم
            
            A Zakat distribution has been updated:
            
            Distribution Name: {zakat_instance.name}
            Amount: {zakat_instance.formatted_amount}
            Beneficiary: {zakat_instance.beneficiary_name}
            
            Changes made:
            {changes_text}
            
            Updated on: {timezone.now().strftime('%Y-%m-%d %H:%M:%S')}
            """
            
        elif action == 'deleted':
            subject = f'Zakat Distribution Deleted: {deletion_data.get("name", "Unknown")}'
            message = f"""
            بسم الله الرحمن الرحيم
            
            A Zakat distribution has been deleted:
            
            Distribution Name: {deletion_data.get('name', 'Unknown')}
            Amount: {deletion_data.get('formatted_amount', 'Unknown')}
            Originally authorized by: {deletion_data.get('authorized_by', 'Unknown')}
            Original beneficiary: {deletion_data.get('beneficiary_name', 'Unknown')}
            Original date: {deletion_data.get('date', 'Unknown')}
            Originally recorded by: {deletion_data.get('created_by', 'Unknown')}
            
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
            logger.info(f"Zakat notification sent: {action} - {subject}")
        
    except Exception as e:
        logger.error(f"Failed to send Zakat notification: {str(e)}")


def send_large_zakat_alert(zakat_instance):
    """
    Send special alert for large Zakat distributions
    """
    try:
        # Get admin/manager emails
        admin_emails = getattr(settings, 'ADMIN_EMAILS', [])
        manager_emails = getattr(settings, 'MANAGER_EMAILS', [])
        islamic_affairs_emails = getattr(settings, 'ISLAMIC_AFFAIRS_EMAILS', [])
        
        recipients = list(set(admin_emails + manager_emails + islamic_affairs_emails))  # Remove duplicates
        
        if not recipients:
            return
        
        subject = f'🕌 LARGE ZAKAT DISTRIBUTION ALERT: {zakat_instance.formatted_amount}'
        message = f"""
        بسم الله الرحمن الرحيم
        
        ATTENTION: A large Zakat distribution has been recorded
        
        ⚠️  AMOUNT: {zakat_instance.formatted_amount}
        📝 DISTRIBUTION: {zakat_instance.name}
        👤 AUTHORIZED BY: {zakat_instance.authorized_by}
        🏠 BENEFICIARY: {zakat_instance.beneficiary_name}
        📞 CONTACT: {zakat_instance.beneficiary_contact or 'N/A'}
        📅 DATE: {zakat_instance.date}
        👨‍💼 RECORDED BY: {zakat_instance.created_by.full_name}
        
        Description:
        {zakat_instance.description}
        
        Notes:
        {zakat_instance.notes or 'None'}
        
        Please review this Zakat distribution for compliance with Islamic principles.
        
        Time: {timezone.now().strftime('%Y-%m-%d %H:%M:%S')}
        
        May Allah accept this charitable giving and bless the beneficiary.
        """
        
        if hasattr(settings, 'EMAIL_HOST') and settings.EMAIL_HOST:
            send_mail(
                subject=subject,
                message=message,
                from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@example.com'),
                recipient_list=recipients,
                fail_silently=True
            )
            logger.warning(f"Large Zakat distribution alert sent: {zakat_instance.formatted_amount}")
        
    except Exception as e:
        logger.error(f"Failed to send large Zakat alert: {str(e)}")


def update_daily_zakat_cache(date):
    """
    Update daily Zakat cache for dashboard
    """
    try:
        from django.db.models import Sum
        
        # Calculate daily total
        daily_total = Zakat.objects.filter(
            date=date,
            is_active=True
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')
        
        # Cache for 1 hour
        cache_key = f'daily_zakat_{date.strftime("%Y%m%d")}'
        cache.set(cache_key, float(daily_total), 3600)
        
        logger.info(f"Updated daily Zakat cache for {date}: {daily_total}")
        
    except Exception as e:
        logger.error(f"Failed to update daily Zakat cache: {str(e)}")


def clear_zakat_caches():
    """
    Clear Zakat-related caches
    """
    try:
        # List of cache keys to clear
        cache_keys = [
            'zakat_statistics',
            'monthly_zakat_summary',
            'recent_zakat',
            'zakat_by_authority',
            'zakat_by_beneficiary',
            'beneficiary_report'
        ]
        
        cache.delete_many(cache_keys)
        logger.info("Cleared Zakat caches")
        
    except Exception as e:
        logger.error(f"Failed to clear Zakat caches: {str(e)}")


# Custom signals for Zakat approval workflow (if needed in future)
import django.dispatch

zakat_approved = django.dispatch.Signal()
zakat_rejected = django.dispatch.Signal()


@receiver(zakat_approved)
def handle_zakat_approval(sender, zakat, approver, **kwargs):
    """
    Handle Zakat distribution approval
    """
    logger.info(f"Zakat distribution approved: {zakat.name} by {approver.full_name}")
    
    # Send approval notification
    try:
        if hasattr(settings, 'EMAIL_HOST') and settings.EMAIL_HOST:
            send_mail(
                subject=f'Zakat Distribution Approved: {zakat.name}',
                message=f"""
                بسم الله الرحمن الرحيم
                
                Your Zakat distribution has been approved:
                
                Distribution: {zakat.name}
                Amount: {zakat.formatted_amount}
                Beneficiary: {zakat.beneficiary_name}
                Approved by: {approver.full_name}
                Date: {timezone.now().strftime('%Y-%m-%d %H:%M:%S')}
                
                May Allah accept this charitable giving.
                """,
                from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@example.com'),
                recipient_list=[zakat.created_by.email],
                fail_silently=True
            )
    except Exception as e:
        logger.error(f"Failed to send Zakat approval notification: {str(e)}")


@receiver(zakat_rejected)
def handle_zakat_rejection(sender, zakat, rejector, reason, **kwargs):
    """
    Handle Zakat distribution rejection
    """
    logger.info(f"Zakat distribution rejected: {zakat.name} by {rejector.full_name}")
    
    # Send rejection notification
    try:
        if hasattr(settings, 'EMAIL_HOST') and settings.EMAIL_HOST:
            send_mail(
                subject=f'Zakat Distribution Rejected: {zakat.name}',
                message=f"""
                بسم الله الرحمن الرحيم
                
                Your Zakat distribution has been rejected:
                
                Distribution: {zakat.name}
                Amount: {zakat.formatted_amount}
                Beneficiary: {zakat.beneficiary_name}
                Rejected by: {rejector.full_name}
                Reason: {reason}
                Date: {timezone.now().strftime('%Y-%m-%d %H:%M:%S')}
                
                Please contact the Islamic affairs team for more information.
                """,
                from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@example.com'),
                recipient_list=[zakat.created_by.email],
                fail_silently=True
            )
    except Exception as e:
        logger.error(f"Failed to send Zakat rejection notification: {str(e)}")


# Utility functions for manual signal triggering
def trigger_zakat_approval(zakat, approver):
    """
    Manually trigger Zakat approval signal
    """
    zakat_approved.send(sender=Zakat, zakat=zakat, approver=approver)


def trigger_zakat_rejection(zakat, rejector, reason="Not specified"):
    """
    Manually trigger Zakat rejection signal
    """
    zakat_rejected.send(sender=Zakat, zakat=zakat, rejector=rejector, reason=reason)


# Signal for beneficiary verification (custom business logic)
beneficiary_verified = django.dispatch.Signal()


@receiver(beneficiary_verified)
def handle_beneficiary_verification(sender, zakat, verifier, verification_notes, **kwargs):
    """
    Handle beneficiary verification process
    """
    logger.info(f"Beneficiary verified for Zakat: {zakat.name} - {zakat.beneficiary_name} by {verifier.full_name}")
    
    # Update Zakat notes with verification info
    verification_text = f"\n\nBeneficiary verified by {verifier.full_name} on {timezone.now().strftime('%Y-%m-%d %H:%M:%S')}\nVerification Notes: {verification_notes}"
    
    if zakat.notes:
        zakat.notes += verification_text
    else:
        zakat.notes = verification_text.strip()
    
    zakat.save(update_fields=['notes'])
    
    # Send verification notification
    try:
        if hasattr(settings, 'EMAIL_HOST') and settings.EMAIL_HOST:
            islamic_affairs_emails = getattr(settings, 'ISLAMIC_AFFAIRS_EMAILS', [])
            if islamic_affairs_emails:
                send_mail(
                    subject=f'Beneficiary Verified: {zakat.beneficiary_name}',
                    message=f"""
                    بسم الله الرحمن الرحيم
                    
                    Beneficiary verification completed:
                    
                    Zakat Distribution: {zakat.name}
                    Beneficiary: {zakat.beneficiary_name}
                    Amount: {zakat.formatted_amount}
                    Verified by: {verifier.full_name}
                    Verification Notes: {verification_notes}
                    
                    Date: {timezone.now().strftime('%Y-%m-%d %H:%M:%S')}
                    """,
                    from_email=getattr(settings, 'DEFAULT_FROM_EMAIL', 'noreply@example.com'),
                    recipient_list=islamic_affairs_emails,
                    fail_silently=True
                )
    except Exception as e:
        logger.error(f"Failed to send beneficiary verification notification: {str(e)}")


def trigger_beneficiary_verification(zakat, verifier, verification_notes="Beneficiary eligibility confirmed"):
    """
    Manually trigger beneficiary verification signal
    """
    beneficiary_verified.send(
        sender=Zakat, 
        zakat=zakat, 
        verifier=verifier, 
        verification_notes=verification_notes
    )
    