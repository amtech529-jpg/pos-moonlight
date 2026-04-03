from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver, Signal
from django.core.cache import cache
from django.utils import timezone
from .models import Labor
import logging

logger = logging.getLogger(__name__)

# Custom signals for bulk operations
labor_bulk_updated = Signal()
labor_bulk_created = Signal()
labor_bulk_deleted = Signal()


@receiver(pre_save, sender=Labor)
def labor_pre_save(sender, instance, **kwargs):
    """Handle labor pre-save operations"""
    if instance.pk:  # Existing labor
        try:
            old_instance = Labor.objects.get(pk=instance.pk)
            
            # Track phone changes
            if old_instance.phone_number != instance.phone_number:
                instance._phone_changed = True
            
            # Track location changes
            if old_instance.city != instance.city or old_instance.area != instance.area:
                instance._location_changed = True
            
            # Track salary changes
            if old_instance.salary != instance.salary:
                instance._salary_changed = True
                instance._old_salary = old_instance.salary
            
            # Track designation changes
            if old_instance.designation != instance.designation:
                instance._designation_changed = True
                instance._old_designation = old_instance.designation
                
        except Labor.DoesNotExist:
            pass


@receiver(post_save, sender=Labor)
def labor_post_save(sender, instance, created, **kwargs):
    """Handle labor post-save operations"""
    # Clear related caches
    cache_keys_to_clear = [
        'labor_statistics',
        'new_labors',
        'recent_labors',
        'inactive_labors',
        'salary_report',
        f'labors_by_city_{instance.city}' if instance.city else None,
        f'labors_by_area_{instance.area}' if instance.area else None,
        f'labors_by_designation_{instance.designation}' if instance.designation else None,
        f'labors_by_caste_{instance.caste}' if instance.caste else None,
    ]
    
    # Remove None values and clear caches
    for key in filter(None, cache_keys_to_clear):
        cache.delete(key)
    
    # Log labor creation
    if created:
        logger.info(
            f"New labor created: {instance.name} (ID: {instance.id}) "
            f"Designation: {instance.designation}, Salary: {instance.salary}, "
            f"Joining Date: {instance.joining_date}, "
            f"Location: {instance.city}, {instance.area} by user {instance.created_by}"
        )
    
    # Log phone changes
    elif hasattr(instance, '_phone_changed'):
        logger.info(
            f"Labor phone updated: {instance.name} (ID: {instance.id}) "
            f"New phone: {instance.phone_number}"
        )
        delattr(instance, '_phone_changed')
    
    # Log location changes
    if hasattr(instance, '_location_changed'):
        logger.info(
            f"Labor location updated: {instance.name} (ID: {instance.id}) "
            f"New location: {instance.city}, {instance.area}"
        )
        delattr(instance, '_location_changed')
    
    # Log salary changes
    if hasattr(instance, '_salary_changed'):
        old_salary = getattr(instance, '_old_salary', 'Unknown')
        logger.info(
            f"Labor salary updated: {instance.name} (ID: {instance.id}) "
            f"Salary changed from {old_salary} to {instance.salary}"
        )
        delattr(instance, '_salary_changed')
        if hasattr(instance, '_old_salary'):
            delattr(instance, '_old_salary')
    
    # Log designation changes
    if hasattr(instance, '_designation_changed'):
        old_designation = getattr(instance, '_old_designation', 'Unknown')
        logger.info(
            f"Labor designation updated: {instance.name} (ID: {instance.id}) "
            f"Designation changed from {old_designation} to {instance.designation}"
        )
        delattr(instance, '_designation_changed')
        if hasattr(instance, '_old_designation'):
            delattr(instance, '_old_designation')


@receiver(post_delete, sender=Labor)
def labor_post_delete(sender, instance, **kwargs):
    """Handle labor deletion"""
    # Clear related caches
    cache_keys_to_clear = [
        'labor_statistics',
        'new_labors',
        'recent_labors',
        'inactive_labors',
        'salary_report',
        f'labors_by_city_{instance.city}' if instance.city else None,
        f'labors_by_area_{instance.area}' if instance.area else None,
        f'labors_by_designation_{instance.designation}' if instance.designation else None,
        f'labors_by_caste_{instance.caste}' if instance.caste else None,
    ]
    
    # Remove None values and clear caches
    for key in filter(None, cache_keys_to_clear):
        cache.delete(key)
    
    # Log labor deletion
    logger.info(
        f"Labor deleted: {instance.name} (ID: {instance.id}) "
        f"Designation: {instance.designation}, Salary: {instance.salary}, "
        f"Location: {instance.city}, {instance.area}"
    )


@receiver(labor_bulk_updated)
def handle_bulk_labor_update(sender, labors, action, **kwargs):
    """Handle bulk labor updates"""
    # Clear caches
    cache.delete('labor_statistics')
    cache.delete('new_labors')
    cache.delete('recent_labors')
    cache.delete('inactive_labors')
    cache.delete('salary_report')
    
    # Clear location and designation specific caches
    for labor in labors:
        if labor.city:
            cache.delete(f'labors_by_city_{labor.city}')
        if labor.area:
            cache.delete(f'labors_by_area_{labor.area}')
        if labor.designation:
            cache.delete(f'labors_by_designation_{labor.designation}')
        if labor.caste:
            cache.delete(f'labors_by_caste_{labor.caste}')
    
    # Log bulk update
    labor_count = len(labors)
    logger.info(f"Bulk labor update completed: {action} applied to {labor_count} labors")
    
    # Specific logging for different actions
    if action == 'activate':
        logger.info(f"Labor activation: {labor_count} labors activated")
    
    elif action == 'deactivate':
        logger.info(f"Labor deactivation: {labor_count} labors deactivated")
    
    elif action == 'update_salary':
        logger.info(f"Labor salary update: {labor_count} labors salary updated")


@receiver(labor_bulk_created)
def handle_bulk_labor_creation(sender, labors, **kwargs):
    """Handle bulk labor creation"""
    # Clear caches
    cache.delete('labor_statistics')
    cache.delete('new_labors')
    cache.delete('salary_report')
    
    # Log bulk creation
    labor_count = len(labors)
    logger.info(f"Bulk labor creation completed: {labor_count} labors created")
    
    # Log location breakdown
    cities = {}
    areas = {}
    designations = {}
    castes = {}
    for labor in labors:
        city = labor.city or 'Unknown'
        area = labor.area or 'Unknown'
        designation = labor.designation or 'Unknown'
        caste = labor.caste or 'Unknown'
        cities[city] = cities.get(city, 0) + 1
        areas[area] = areas.get(area, 0) + 1
        designations[designation] = designations.get(designation, 0) + 1
        castes[caste] = castes.get(caste, 0) + 1
    
    logger.info(f"New labors by city: {', '.join([f'{k}: {v}' for k, v in cities.items()])}")
    logger.info(f"New labors by area: {', '.join([f'{k}: {v}' for k, v in areas.items()])}")
    logger.info(f"New labors by designation: {', '.join([f'{k}: {v}' for k, v in designations.items()])}")
    logger.info(f"New labors by caste: {', '.join([f'{k}: {v}' for k, v in castes.items()])}")


@receiver(labor_bulk_deleted)
def handle_bulk_labor_deletion(sender, labor_ids, **kwargs):
    """Handle bulk labor deletion"""
    # Clear all labor-related caches
    cache_keys_to_clear = [
        'labor_statistics',
        'new_labors',
        'recent_labors',
        'inactive_labors',
        'salary_report',
    ]
    
    for key in cache_keys_to_clear:
        cache.delete(key)
    
    # Log bulk deletion
    labor_count = len(labor_ids)
    logger.info(f"Bulk labor deletion completed: {labor_count} labors deleted")


@receiver(post_save, sender=Labor)
def labor_data_quality_check(sender, instance, created, **kwargs):
    """Perform data quality checks on labor information"""
    issues = []
    
    # Check for potential duplicate names in same designation and city
    if instance.name and instance.designation and instance.city:
        similar_labors = Labor.objects.filter(
            name__iexact=instance.name,
            designation__iexact=instance.designation,
            city__iexact=instance.city,
            is_active=True
        ).exclude(pk=instance.pk)
        
        if similar_labors.exists():
            issues.append("Similar name exists with same designation in same city")
    
    # Check for missing area information
    if not instance.area:
        issues.append("Missing area information")
    
    # Check phone number format
    if instance.phone_number and not instance.phone_number.startswith('+'):
        issues.append("Phone number missing country code")
    
    # Check for reasonable salary ranges
    if instance.salary:
        if instance.salary < 10000:  # Less than 10k PKR
            issues.append("Unusually low salary amount")
        elif instance.salary > 200000:  # More than 200k PKR
            issues.append("Unusually high salary amount")
    
    # Check age vs joining date consistency
    if instance.age and instance.joining_date:
        from datetime import date
        years_since_joining = (date.today() - instance.joining_date).days / 365.25
        if years_since_joining > 5 and instance.age < 20:
            issues.append("Age seems inconsistent with long tenure")
    
    # Log data quality issues
    if issues:
        logger.warning(
            f"Labor data quality issues for {instance.name} (ID: {instance.id}): "
            f"{', '.join(issues)}"
        )


@receiver(post_save, sender=Labor)
def labor_analytics(sender, instance, created, **kwargs):
    """Track labor analytics and insights"""
    if created:
        from datetime import timedelta, date
        today = date.today()
        
        # Count labors by designation today
        designation_count = Labor.objects.filter(
            designation__iexact=instance.designation,
            created_at__date=today
        ).count()
        
        # Count labors in same city today
        city_count = Labor.objects.filter(
            city__iexact=instance.city,
            created_at__date=today
        ).count()
        
        # Count labors in same area today
        area_count = Labor.objects.filter(
            area__iexact=instance.area,
            created_at__date=today
        ).count()
        
        # Log analytics
        logger.info(
            f"Labor analytics: {instance.designation} now has {designation_count} labors added today, "
            f"{instance.city} has {city_count} labors added today, "
            f"{instance.area} has {area_count} labors added today"
        )


@receiver(pre_save, sender=Labor)
def validate_labor_data_integrity(sender, instance, **kwargs):
    """Additional data integrity validation"""
    # Check for potential duplicate CNIC (soft warning)
    if instance.cnic:
        duplicate_cnic = Labor.objects.filter(
            cnic=instance.cnic,
            is_active=True
        ).exclude(pk=instance.pk)
        
        if duplicate_cnic.exists():
            logger.warning(
                f"Duplicate CNIC detected for labor {instance.name}: {instance.cnic}"
            )
    
    # Check for potential duplicate phone numbers (soft warning)
    if instance.phone_number:
        duplicate_phones = Labor.objects.filter(
            phone_number=instance.phone_number,
            is_active=True
        ).exclude(pk=instance.pk)
        
        if duplicate_phones.exists():
            logger.warning(
                f"Duplicate phone number detected for labor {instance.name}: {instance.phone_number}"
            )
    
    # Validate designation consistency
    if instance.designation and len(instance.designation.strip()) < 2:
        logger.warning(
            f"Short designation detected for labor {instance.name}: '{instance.designation}'"
        )
    
    # Validate salary vs designation consistency (basic check)
    if instance.salary and instance.designation:
        # This could be expanded with more sophisticated logic
        common_designations = {
            'helper': (15000, 25000),
            'laborer': (20000, 35000),
            'supervisor': (40000, 80000),
            'manager': (60000, 120000),
        }
        
        designation_lower = instance.designation.lower()
        for key, (min_salary, max_salary) in common_designations.items():
            if key in designation_lower:
                if not (min_salary <= instance.salary <= max_salary):
                    logger.warning(
                        f"Salary {instance.salary} seems unusual for designation {instance.designation} "
                        f"for labor {instance.name}"
                    )
                break


@receiver(post_save, sender=Labor)
def labor_security_audit(sender, instance, created, **kwargs):
    """Security and compliance audit logging"""
    if created:
        logger.info(
            f"AUDIT: New labor record created - Name: {instance.name}, "
            f"CNIC: {instance.cnic}, Designation: {instance.designation}, "
            f"Salary: {instance.salary}, Created by: {instance.created_by}"
        )
    else:
        # Log significant updates
        changes = []
        if hasattr(instance, '_salary_changed'):
            changes.append(f"salary updated to {instance.salary}")
        if hasattr(instance, '_designation_changed'):
            changes.append(f"designation updated to {instance.designation}")
        if hasattr(instance, '_phone_changed'):
            changes.append(f"phone updated to {instance.phone_number}")
        if hasattr(instance, '_location_changed'):
            changes.append(f"location updated to {instance.city}, {instance.area}")
        
        if changes:
            logger.info(
                f"AUDIT: Labor record updated - Name: {instance.name}, "
                f"Changes: {'; '.join(changes)}"
            )
            