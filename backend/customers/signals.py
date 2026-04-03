from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver, Signal
from django.core.cache import cache
from django.utils import timezone
from .models import Customer
import logging

logger = logging.getLogger(__name__)

# Custom signals for bulk operations
customer_bulk_updated = Signal()
customer_bulk_created = Signal()
customer_bulk_deleted = Signal()
customer_verification_changed = Signal()


@receiver(pre_save, sender=Customer)
def customer_pre_save(sender, instance, **kwargs):
    """Handle customer pre-save operations"""
    if instance.pk:  # Existing customer
        try:
            old_instance = Customer.objects.get(pk=instance.pk)
            
            # Track status changes
            if old_instance.status != instance.status:
                instance._old_status = old_instance.status
            
            # Track verification changes
            if old_instance.phone_verified != instance.phone_verified:
                instance._phone_verification_changed = True
            if old_instance.email_verified != instance.email_verified:
                instance._email_verification_changed = True
                
        except Customer.DoesNotExist:
            pass


@receiver(post_save, sender=Customer)
def customer_post_save(sender, instance, created, **kwargs):
    """Handle customer post-save operations"""
    # Clear related caches
    cache_keys_to_clear = [
        'customer_statistics',
        'new_customers',
        'recent_customers',
        'inactive_customers',
        f'customers_by_status_{instance.status}',
        f'customers_by_type_{instance.customer_type}',
        f'customers_by_city_{instance.city}' if instance.city else None,
        f'customers_by_country_{instance.country}' if instance.country else None,
    ]
    
    # Remove None values and clear caches
    for key in filter(None, cache_keys_to_clear):
        cache.delete(key)
    
    # Log customer creation
    if created:
        logger.info(
            f"New customer created: {instance.name} (ID: {instance.id}) "
            f"Phone: {instance.phone}, Type: {instance.customer_type}, "
            f"Country: {instance.country} by user {instance.created_by}"
        )
        
        # Auto-update status for new customers
        if instance.status != 'NEW':
            instance.status = 'NEW'
            instance.save(update_fields=['status'])
    
    # Log status changes
    elif hasattr(instance, '_old_status'):
        old_status = instance._old_status
        new_status = instance.status
        
        logger.info(
            f"Customer status updated: {instance.name} (ID: {instance.id}) "
            f"from {old_status} to {new_status}"
        )
        delattr(instance, '_old_status')
    
    # Log verification changes
    if hasattr(instance, '_phone_verification_changed'):
        logger.info(
            f"Customer phone verification updated: {instance.name} (ID: {instance.id}) "
            f"Phone {instance.phone} verified: {instance.phone_verified}"
        )
        delattr(instance, '_phone_verification_changed')
    
    if hasattr(instance, '_email_verification_changed'):
        logger.info(
            f"Customer email verification updated: {instance.name} (ID: {instance.id}) "
            f"Email {instance.email} verified: {instance.email_verified}"
        )
        delattr(instance, '_email_verification_changed')


@receiver(post_delete, sender=Customer)
def customer_post_delete(sender, instance, **kwargs):
    """Handle customer deletion"""
    # Clear related caches
    cache_keys_to_clear = [
        'customer_statistics',
        'new_customers',
        'recent_customers',
        'inactive_customers',
        f'customers_by_status_{instance.status}',
        f'customers_by_type_{instance.customer_type}',
        f'customers_by_city_{instance.city}' if instance.city else None,
        f'customers_by_country_{instance.country}' if instance.country else None,
    ]
    
    # Remove None values and clear caches
    for key in filter(None, cache_keys_to_clear):
        cache.delete(key)
    
    # Log customer deletion
    logger.info(
        f"Customer deleted: {instance.name} (ID: {instance.id}) "
        f"Phone: {instance.phone}, Country: {instance.country}"
    )


@receiver(customer_bulk_updated)
def handle_bulk_customer_update(sender, customers, action, **kwargs):
    """Handle bulk customer updates"""
    # Clear caches
    cache.delete('customer_statistics')
    cache.delete('new_customers')
    cache.delete('recent_customers')
    cache.delete('inactive_customers')
    
    # Clear status and type specific caches
    for customer in customers:
        cache.delete(f'customers_by_status_{customer.status}')
        cache.delete(f'customers_by_type_{customer.customer_type}')
        if customer.city:
            cache.delete(f'customers_by_city_{customer.city}')
        if customer.country:
            cache.delete(f'customers_by_country_{customer.country}')
    
    # Log bulk update
    customer_count = len(customers)
    logger.info(f"Bulk customer update completed: {action} applied to {customer_count} customers")
    
    # Specific logging for different actions
    if action == 'mark_vip':
        vip_customers = [c.name for c in customers[:5]]
        if customer_count > 5:
            vip_customers.append(f"and {customer_count - 5} more")
        
        logger.info(
            f"VIP status update: {customer_count} customers marked as VIP: {', '.join(vip_customers)}"
        )
    
    elif action == 'verify_phone':
        logger.info(f"Phone verification: {customer_count} customer phone numbers verified")
    
    elif action == 'verify_email':
        logger.info(f"Email verification: {customer_count} customer emails verified")


@receiver(customer_bulk_created)
def handle_bulk_customer_creation(sender, customers, **kwargs):
    """Handle bulk customer creation"""
    # Clear caches
    cache.delete('customer_statistics')
    cache.delete('new_customers')
    
    # Log bulk creation
    customer_count = len(customers)
    logger.info(f"Bulk customer creation completed: {customer_count} customers created")
    
    # Log customer types and countries breakdown
    individual_count = sum(1 for c in customers if c.customer_type == 'INDIVIDUAL')
    business_count = sum(1 for c in customers if c.customer_type == 'BUSINESS')
    
    # Country breakdown
    countries = {}
    for customer in customers:
        country = customer.country or 'Unknown'
        countries[country] = countries.get(country, 0) + 1
    
    logger.info(
        f"New customers breakdown: {individual_count} Individual, {business_count} Business"
    )
    logger.info(f"Countries: {', '.join([f'{k}: {v}' for k, v in countries.items()])}")


@receiver(customer_bulk_deleted)
def handle_bulk_customer_deletion(sender, customer_ids, **kwargs):
    """Handle bulk customer deletion"""
    # Clear all customer-related caches
    cache_keys_to_clear = [
        'customer_statistics',
        'new_customers',
        'recent_customers',
        'inactive_customers',
    ]
    
    for key in cache_keys_to_clear:
        cache.delete(key)
    
    # Log bulk deletion
    customer_count = len(customer_ids)
    logger.info(f"Bulk customer deletion completed: {customer_count} customers deleted")


@receiver(customer_verification_changed)
def handle_customer_verification_change(sender, customer, verification_type, verified, **kwargs):
    """Handle customer verification status changes"""
    # Clear verification-related caches
    cache.delete('customer_statistics')
    
    # Log verification change
    logger.info(
        f"Customer verification updated: {customer.name} (ID: {customer.id}) "
        f"{verification_type} verification set to {verified}"
    )
    
    # Log successful verification
    if verified:
        contact_info = getattr(customer, verification_type)
        logger.info(
            f"Customer {verification_type} verified: {customer.name} ({contact_info})"
        )


@receiver(post_save, sender=Customer)
def schedule_verification_reminders(sender, instance, created, **kwargs):
    """Schedule verification reminders for unverified contacts"""
    if created:
        # Schedule phone verification reminder if not verified
        if not instance.phone_verified:
            logger.info(
                f"Phone verification reminder scheduled for customer: {instance.name} "
                f"({instance.phone})"
            )
        
        # Schedule email verification reminder if email provided but not verified
        if instance.email and not instance.email_verified:
            logger.info(
                f"Email verification reminder scheduled for customer: {instance.name} "
                f"({instance.email})"
            )


@receiver(post_save, sender=Customer)
def customer_data_quality_check(sender, instance, created, **kwargs):
    """Perform data quality checks on customer information"""
    issues = []
    
    # Check for missing email on business customers
    if instance.customer_type == 'BUSINESS' and not instance.email:
        issues.append("Business customer missing email address")
    
    # Check for missing address on VIP customers
    if instance.status == 'VIP' and not instance.address:
        issues.append("VIP customer missing address information")
    
    # Check for unverified contact info on regular/VIP customers
    if instance.status in ['REGULAR', 'VIP']:
        if not instance.phone_verified:
            issues.append("Regular/VIP customer has unverified phone")
        if instance.email and not instance.email_verified:
            issues.append("Regular/VIP customer has unverified email")
    
    # Check for international customers without country specified
    if instance.country == 'Pakistan' and instance.phone and not instance.phone.startswith('+92'):
        issues.append("Non-Pakistani phone but country set to Pakistan")
    
    # Log data quality issues
    if issues:
        logger.warning(
            f"Customer data quality issues for {instance.name} (ID: {instance.id}): "
            f"{', '.join(issues)}"
        )
        