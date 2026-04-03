from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver, Signal
from django.core.cache import cache
from django.utils import timezone
from .models import Vendor
import logging

logger = logging.getLogger(__name__)

# Custom signals for bulk operations
vendor_bulk_updated = Signal()
vendor_bulk_created = Signal()
vendor_bulk_deleted = Signal()


@receiver(pre_save, sender=Vendor)
def vendor_pre_save(sender, instance, **kwargs):
    """Handle vendor pre-save operations"""
    if instance.pk:  # Existing vendor
        try:
            old_instance = Vendor.objects.get(pk=instance.pk)
            
            # Track phone changes
            if old_instance.phone != instance.phone:
                instance._phone_changed = True
            
            # Track location changes
            if old_instance.city != instance.city or old_instance.area != instance.area:
                instance._location_changed = True
                
        except Vendor.DoesNotExist:
            pass


@receiver(post_save, sender=Vendor)
def vendor_post_save(sender, instance, created, **kwargs):
    """Handle vendor post-save operations"""
    # Clear related caches
    cache_keys_to_clear = [
        'vendor_statistics',
        'new_vendors',
        'recent_vendors',
        'inactive_vendors',
        f'vendors_by_city_{instance.city}' if instance.city else None,
        f'vendors_by_area_{instance.area}' if instance.area else None,
    ]
    
    # Remove None values and clear caches
    for key in filter(None, cache_keys_to_clear):
        cache.delete(key)
    
    # Log vendor creation
    if created:
        logger.info(
            f"New vendor created: {instance.name} (ID: {instance.id}) "
            f"Business: {instance.business_name}, Phone: {instance.phone}, "
            f"Location: {instance.city}, {instance.area} by user {instance.created_by}"
        )
    
    # Log phone changes
    elif hasattr(instance, '_phone_changed'):
        logger.info(
            f"Vendor phone updated: {instance.name} (ID: {instance.id}) "
            f"New phone: {instance.phone}"
        )
        delattr(instance, '_phone_changed')
    
    # Log location changes
    if hasattr(instance, '_location_changed'):
        logger.info(
            f"Vendor location updated: {instance.name} (ID: {instance.id}) "
            f"New location: {instance.city}, {instance.area}"
        )
        delattr(instance, '_location_changed')


@receiver(post_delete, sender=Vendor)
def vendor_post_delete(sender, instance, **kwargs):
    """Handle vendor deletion"""
    # Clear related caches
    cache_keys_to_clear = [
        'vendor_statistics',
        'new_vendors',
        'recent_vendors',
        'inactive_vendors',
        f'vendors_by_city_{instance.city}' if instance.city else None,
        f'vendors_by_area_{instance.area}' if instance.area else None,
    ]
    
    # Remove None values and clear caches
    for key in filter(None, cache_keys_to_clear):
        cache.delete(key)
    
    # Log vendor deletion
    logger.info(
        f"Vendor deleted: {instance.name} (ID: {instance.id}) "
        f"Business: {instance.business_name}, Phone: {instance.phone}, "
        f"Location: {instance.city}, {instance.area}"
    )


@receiver(vendor_bulk_updated)
def handle_bulk_vendor_update(sender, vendors, action, **kwargs):
    """Handle bulk vendor updates"""
    # Clear caches
    cache.delete('vendor_statistics')
    cache.delete('new_vendors')
    cache.delete('recent_vendors')
    cache.delete('inactive_vendors')
    
    # Clear location specific caches
    for vendor in vendors:
        if vendor.city:
            cache.delete(f'vendors_by_city_{vendor.city}')
        if vendor.area:
            cache.delete(f'vendors_by_area_{vendor.area}')
    
    # Log bulk update
    vendor_count = len(vendors)
    logger.info(f"Bulk vendor update completed: {action} applied to {vendor_count} vendors")
    
    # Specific logging for different actions
    if action == 'activate':
        logger.info(f"Vendor activation: {vendor_count} vendors activated")
    
    elif action == 'deactivate':
        logger.info(f"Vendor deactivation: {vendor_count} vendors deactivated")


@receiver(vendor_bulk_created)
def handle_bulk_vendor_creation(sender, vendors, **kwargs):
    """Handle bulk vendor creation"""
    # Clear caches
    cache.delete('vendor_statistics')
    cache.delete('new_vendors')
    
    # Log bulk creation
    vendor_count = len(vendors)
    logger.info(f"Bulk vendor creation completed: {vendor_count} vendors created")
    
    # Log location breakdown
    cities = {}
    areas = {}
    for vendor in vendors:
        city = vendor.city or 'Unknown'
        area = vendor.area or 'Unknown'
        cities[city] = cities.get(city, 0) + 1
        areas[area] = areas.get(area, 0) + 1
    
    logger.info(f"New vendors by city: {', '.join([f'{k}: {v}' for k, v in cities.items()])}")
    logger.info(f"New vendors by area: {', '.join([f'{k}: {v}' for k, v in areas.items()])}")


@receiver(vendor_bulk_deleted)
def handle_bulk_vendor_deletion(sender, vendor_ids, **kwargs):
    """Handle bulk vendor deletion"""
    # Clear all vendor-related caches
    cache_keys_to_clear = [
        'vendor_statistics',
        'new_vendors',
        'recent_vendors',
        'inactive_vendors',
    ]
    
    for key in cache_keys_to_clear:
        cache.delete(key)
    
    # Log bulk deletion
    vendor_count = len(vendor_ids)
    logger.info(f"Bulk vendor deletion completed: {vendor_count} vendors deleted")


@receiver(post_save, sender=Vendor)
def vendor_data_quality_check(sender, instance, created, **kwargs):
    """Perform data quality checks on vendor information"""
    issues = []
    
    # Check for potential duplicate business names in same city
    if instance.business_name and instance.city:
        similar_vendors = Vendor.objects.filter(
            business_name__iexact=instance.business_name,
            city__iexact=instance.city,
            is_active=True
        ).exclude(pk=instance.pk)
        
        if similar_vendors.exists():
            issues.append("Similar business name exists in same city")
    
    # Check for missing area information
    if not instance.area:
        issues.append("Missing area information")
    
    # Check phone number format
    if instance.phone and not instance.phone.startswith('+'):
        issues.append("Phone number missing country code")
    
    # Log data quality issues
    if issues:
        logger.warning(
            f"Vendor data quality issues for {instance.name} (ID: {instance.id}): "
            f"{', '.join(issues)}"
        )


@receiver(post_save, sender=Vendor)
def vendor_location_analytics(sender, instance, created, **kwargs):
    """Track vendor location analytics"""
    if created:
        # This could be used to track vendor distribution metrics
        # You might want to implement location-based alerts here
        
        from datetime import timedelta
        today = timezone.now().date()
        
        # Count vendors in same city today
        city_count = Vendor.objects.filter(
            city__iexact=instance.city,
            created_at__date=today
        ).count()
        
        # Count vendors in same area today  
        area_count = Vendor.objects.filter(
            area__iexact=instance.area,
            created_at__date=today
        ).count()
        
        # Log location analytics
        logger.info(
            f"Vendor location analytics: {instance.city} now has {city_count} vendors added today, "
            f"{instance.area} has {area_count} vendors added today"
        )


@receiver(pre_save, sender=Vendor)
def validate_vendor_data_integrity(sender, instance, **kwargs):
    """Additional data integrity validation"""
    # Check for potential duplicate CNIC (soft warning)
    if instance.cnic:
        duplicate_cnic = Vendor.objects.filter(
            cnic=instance.cnic,
            is_active=True
        ).exclude(pk=instance.pk)
        
        if duplicate_cnic.exists():
            logger.warning(
                f"Duplicate CNIC detected for vendor {instance.name}: {instance.cnic}"
            )
    
    # Check for potential duplicate phone numbers (soft warning)
    if instance.phone:
        duplicate_phones = Vendor.objects.filter(
            phone=instance.phone,
            is_active=True
        ).exclude(pk=instance.pk)
        
        if duplicate_phones.exists():
            logger.warning(
                f"Duplicate phone number detected for vendor {instance.name}: {instance.phone}"
            )
    
    # Validate business name consistency
    if instance.business_name and len(instance.business_name.strip()) < 2:
        logger.warning(
            f"Short business name detected for vendor {instance.name}: '{instance.business_name}'"
        )
        