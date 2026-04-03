from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver
from django.core.cache import cache
from django.utils import timezone
from .models import Product
import logging

logger = logging.getLogger(__name__)


@receiver(pre_save, sender=Product)
def product_pre_save(sender, instance, **kwargs):
    """
    Handle product pre-save operations
    """
    # Track quantity changes for logging
    if instance.pk:  # Existing product
        try:
            old_instance = Product.objects.get(pk=instance.pk)
            if old_instance.quantity != instance.quantity:
                # Store old quantity for post_save signal
                instance._old_quantity = old_instance.quantity
        except Product.DoesNotExist:
            pass


@receiver(post_save, sender=Product)
def product_post_save(sender, instance, created, **kwargs):
    """
    Handle product post-save operations
    """
    # Clear related caches
    cache_keys_to_clear = [
        'product_statistics',
        f'products_by_category_{instance.category_id}',
        'low_stock_products',
        'out_of_stock_products',
    ]
    
    for key in cache_keys_to_clear:
        cache.delete(key)
    
    # Log product creation
    if created:
        logger.info(
            f"New product created: {instance.name} (ID: {instance.id}) "
            f"by user {instance.created_by}"
        )
    
    # Log quantity changes
    elif hasattr(instance, '_old_quantity'):
        old_qty = instance._old_quantity
        new_qty = instance.quantity
        difference = new_qty - old_qty
        
        logger.info(
            f"Product quantity updated: {instance.name} (ID: {instance.id}) "
            f"from {old_qty} to {new_qty} (difference: {difference:+d})"
        )
        
        # Check for low stock alert
        if instance.is_low_stock() and not old_qty <= 5:
            logger.warning(
                f"Low stock alert: {instance.name} (ID: {instance.id}) "
                f"now has {instance.quantity} units remaining"
            )
        
        # Check for out of stock alert
        if instance.quantity == 0 and old_qty > 0:
            logger.warning(
                f"Out of stock alert: {instance.name} (ID: {instance.id}) "
                f"is now out of stock"
            )
        
        # Clean up the temporary attribute
        delattr(instance, '_old_quantity')


@receiver(post_delete, sender=Product)
def product_post_delete(sender, instance, **kwargs):
    """
    Handle product deletion
    """
    # Clear related caches
    cache_keys_to_clear = [
        'product_statistics',
        f'products_by_category_{instance.category_id}',
        'low_stock_products',
        'out_of_stock_products',
    ]
    
    for key in cache_keys_to_clear:
        cache.delete(key)
    
    # Log product deletion
    logger.info(
        f"Product deleted: {instance.name} (ID: {instance.id})"
    )


# Optional: Custom signal for bulk operations
from django.dispatch import Signal

# Custom signals
product_quantity_bulk_updated = Signal()
product_bulk_created = Signal()
product_bulk_deleted = Signal()


@receiver(product_quantity_bulk_updated)
def handle_bulk_quantity_update(sender, products, **kwargs):
    """
    Handle bulk quantity updates
    """
    # Clear caches
    cache.delete('product_statistics')
    cache.delete('low_stock_products')
    cache.delete('out_of_stock_products')
    
    # Log bulk update
    product_count = len(products)
    logger.info(f"Bulk quantity update completed for {product_count} products")
    
    # Check for low stock products after bulk update
    low_stock_products = [p for p in products if p.is_low_stock()]
    if low_stock_products:
        product_names = [p.name for p in low_stock_products[:5]]
        if len(low_stock_products) > 5:
            product_names.append(f"and {len(low_stock_products) - 5} more")
        
        logger.warning(
            f"Low stock alert after bulk update: {len(low_stock_products)} products "
            f"need restocking: {', '.join(product_names)}"
        )


@receiver(product_bulk_created)
def handle_bulk_product_creation(sender, products, **kwargs):
    """
    Handle bulk product creation
    """
    # Clear caches
    cache.delete('product_statistics')
    
    # Log bulk creation
    product_count = len(products)
    logger.info(f"Bulk product creation completed: {product_count} products created")


@receiver(product_bulk_deleted)
def handle_bulk_product_deletion(sender, product_ids, **kwargs):
    """
    Handle bulk product deletion
    """
    # Clear all product-related caches
    cache_keys_to_clear = [
        'product_statistics',
        'low_stock_products',
        'out_of_stock_products',
    ]
    
    for key in cache_keys_to_clear:
        cache.delete(key)
    
    # Log bulk deletion
    product_count = len(product_ids)
    logger.info(f"Bulk product deletion completed: {product_count} products deleted")
    