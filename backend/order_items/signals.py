from django.db.models.signals import post_save, pre_save, post_delete
from django.dispatch import receiver, Signal
from django.core.cache import cache
from django.utils import timezone
from django.db import transaction
from .models import OrderItem
import logging
import threading

logger = logging.getLogger(__name__)

# Custom signals for bulk operations
order_item_bulk_updated = Signal()
order_item_bulk_created = Signal()
order_item_bulk_deleted = Signal()

# Thread-local storage for tracking operations
_thread_local = threading.local()


def _is_in_transaction():
    """Check if we're currently in a database transaction"""
    return hasattr(_thread_local, 'in_transaction') and _thread_local.in_transaction


def _mark_transaction_start():
    """Mark the start of a transaction"""
    _thread_local.in_transaction = True


def _mark_transaction_end():
    """Mark the end of a transaction"""
    if hasattr(_thread_local, 'in_transaction'):
        delattr(_thread_local, 'in_transaction')


@receiver(pre_save, sender=OrderItem)
def order_item_pre_save(sender, instance, **kwargs):
    """Handle order item pre-save operations"""
    if instance.pk:  # Existing order item
        try:
            old_instance = OrderItem.objects.get(pk=instance.pk)
            
            # Track quantity changes
            if old_instance.quantity != instance.quantity:
                instance._old_quantity = old_instance.quantity
            
            # Track price changes
            if old_instance.rate != instance.rate:
                instance._old_rate = old_instance.rate
                
        except OrderItem.DoesNotExist:
            pass


@receiver(post_save, sender=OrderItem)
def order_item_post_save(sender, instance, created, **kwargs):
    """Handle order item post-save operations"""
    try:
        # Clear related caches
        cache_keys_to_clear = [
            'order_item_statistics',
            f'order_items_by_order_{instance.order_id}',
            f'order_items_by_product_{instance.product_id}',
            f'order_total_{instance.order_id}',
        ]
        
        # Remove None values and clear caches
        for key in filter(None, cache_keys_to_clear):
            cache.delete(key)
        
        # Log order item creation
        if created:
            logger.info(
                f"New order item created: {instance.product_name} x{instance.quantity} "
                f"for Order {instance.order_id} (Item ID: {instance.id}) "
                f"Rate: PKR {instance.rate}, Total: PKR {instance.line_total}"
            )
            
            # Log customization if present
            if instance.customization_notes:
                logger.info(
                    f"Order item customization: {instance.product_name} (ID: {instance.id}) "
                    f"Notes: {instance.customization_notes}"
                )
        
        # Log quantity changes
        elif hasattr(instance, '_old_quantity'):
            old_qty = instance._old_quantity
            new_qty = instance.quantity
            difference = new_qty - old_qty
            
            logger.info(
                f"Order item quantity updated: {instance.product_name} (ID: {instance.id}) "
                f"from {old_qty} to {new_qty} (difference: {difference:+d}) "
                f"New total: PKR {instance.line_total}"
            )
            delattr(instance, '_old_quantity')
        
        # Log price changes
        elif hasattr(instance, '_old_rate'):
            old_price = instance._old_rate
            new_price = instance.rate
            difference = new_price - old_price
            
            logger.info(
                f"Order item price updated: {instance.product_name} (ID: {instance.id}) "
                f"from PKR {old_price} to PKR {new_price} (difference: PKR {difference:+.2f}) "
                f"New total: PKR {instance.line_total}"
            )
            delattr(instance, '_old_rate')
            
        # ✅ SYNC STOCK RESERVATIONS: Ensure inventory is updated if order is active
        try:
            from orders.signals import sync_order_reservations
            sync_order_reservations(instance.order)
        except ImportError:
            # Avoid circular import or if module not available
            pass
            
    except Exception as e:
        logger.error(f"Error in order_item_post_save signal: {str(e)}")


@receiver(post_delete, sender=OrderItem)
def order_item_post_delete(sender, instance, **kwargs):
    """Handle order item deletion"""
    try:
        # Clear related caches
        cache_keys_to_clear = [
            'order_item_statistics',
            f'order_items_by_order_{instance.order_id}',
            f'order_items_by_product_{instance.product_id}',
            f'order_total_{instance.order_id}',
        ]
        
        # Remove None values and clear caches
        for key in filter(None, cache_keys_to_clear):
            cache.delete(key)
        
        # Log order item deletion
        logger.info(
            f"Order item deleted: {instance.product_name} x{instance.quantity} "
            f"from Order {instance.order_id} (Item ID: {instance.id}) "
            f"Value: PKR {instance.line_total}"
        )
        
        # ✅ SYNC STOCK RESERVATIONS: Ensure inventory is updated when item is removed
        try:
            from orders.signals import sync_order_reservations
            sync_order_reservations(instance.order)
        except ImportError:
            pass
            
    except Exception as e:
        logger.error(f"Error in order_item_post_delete signal: {str(e)}")


@receiver(order_item_bulk_updated)
def handle_bulk_order_item_update(sender, order_items, action, **kwargs):
    """Handle bulk order item updates"""
    try:
        # Clear caches
        cache.delete('order_item_statistics')
        
        # Clear order-specific caches
        order_ids = set(item.order_id for item in order_items)
        for order_id in order_ids:
            cache.delete(f'order_items_by_order_{order_id}')
            cache.delete(f'order_total_{order_id}')
        
        # Clear product-specific caches
        product_ids = set(item.product_id for item in order_items)
        for product_id in product_ids:
            cache.delete(f'order_items_by_product_{product_id}')
        
        # Log bulk update
        item_count = len(order_items)
        logger.info(f"Bulk order item update completed: {action} applied to {item_count} items")
        
        # Specific logging for different actions
        if action == 'quantity_update':
            total_quantity = sum(item.quantity for item in order_items)
            logger.info(f"Quantity update: {item_count} items, total quantity: {total_quantity}")
        
        elif action == 'price_update':
            total_value = sum(item.line_total for item in order_items)
            logger.info(f"Price update: {item_count} items, total value: PKR {total_value}")
            
    except Exception as e:
        logger.error(f"Error in handle_bulk_order_item_update signal: {str(e)}")


@receiver(order_item_bulk_created)
def handle_bulk_order_item_creation(sender, order_items, **kwargs):
    """Handle bulk order item creation"""
    try:
        # Clear caches
        cache.delete('order_item_statistics')
        
        # Clear order-specific caches
        order_ids = set(item.order_id for item in order_items)
        for order_id in order_ids:
            cache.delete(f'order_items_by_order_{order_id}')
            cache.delete(f'order_total_{order_id}')
        
        # Log bulk creation
        item_count = len(order_items)
        total_quantity = sum(item.quantity for item in order_items)
        total_value = sum(item.line_total for item in order_items)
        
        logger.info(f"Bulk order item creation completed: {item_count} items created")
        logger.info(f"Total quantity: {total_quantity}, Total value: PKR {total_value}")
        
        # Order breakdown
        order_breakdown = {}
        for item in order_items:
            order_id = str(item.order_id)
            if order_id not in order_breakdown:
                order_breakdown[order_id] = {'count': 0, 'value': 0}
            order_breakdown[order_id]['count'] += 1
            order_breakdown[order_id]['value'] += item.line_total
        
        logger.info(f"Items added to {len(order_breakdown)} orders")
        
    except Exception as e:
        logger.error(f"Error in handle_bulk_order_item_creation signal: {str(e)}")


@receiver(order_item_bulk_deleted)
def handle_bulk_order_item_deletion(sender, order_item_ids, **kwargs):
    """Handle bulk order item deletion"""
    try:
        # Clear all order item-related caches
        cache_keys_to_clear = [
            'order_item_statistics',
        ]
        
        for key in cache_keys_to_clear:
            cache.delete(key)
        
        # Log bulk deletion
        item_count = len(order_item_ids)
        logger.info(f"Bulk order item deletion completed: {item_count} items deleted")
        
    except Exception as e:
        logger.error(f"Error in handle_bulk_order_item_deletion signal: {str(e)}")


def _update_order_totals_async(order_id):
    """Update order totals asynchronously to prevent timeout"""
    try:
        from orders.models import Order
        
        with transaction.atomic():
            order = Order.objects.get(id=order_id)
            if order:
                # Recalculate order total
                order.calculate_totals()
                logger.info(
                    f"Order totals updated for Order {order.id}: "
                    f"Total: PKR {order.total_amount}, "
                    f"Remaining: PKR {order.remaining_amount}"
                )
    except Exception as e:
        logger.error(f"Failed to update order totals for order {order_id}: {str(e)}")


# Signal to update order totals when order items change
@receiver([post_save, post_delete], sender=OrderItem)
def update_order_totals(sender, instance, **kwargs):
    """Update parent order totals when order items change"""
    try:
        # Skip if we're in a transaction to prevent recursion
        if _is_in_transaction():
            return
            
        # Update order totals asynchronously to prevent timeout
        thread = threading.Thread(
            target=_update_order_totals_async,
            args=(instance.order_id,),
            daemon=True
        )
        thread.start()
        
    except Exception as e:
        logger.error(f"Failed to schedule order totals update for order {instance.order_id}: {str(e)}")


# Signal for stock validation warnings
@receiver(post_save, sender=OrderItem)
def check_stock_availability(sender, instance, created, **kwargs):
    """Check stock availability and log warnings"""
    try:
        if created and instance.product:
            # Check if order quantity exceeds current stock
            if instance.quantity > instance.product.quantity:
                logger.warning(
                    f"Stock shortage: Order item {instance.id} requests {instance.quantity} "
                    f"of {instance.product_name}, but only {instance.product.quantity} available"
                )
            
            # Check if this order item will cause low stock
            remaining_stock = instance.product.quantity - instance.quantity
            if remaining_stock <= 5 and remaining_stock > 0:
                logger.warning(
                    f"Low stock warning: {instance.product_name} will have {remaining_stock} "
                    f"units remaining after fulfilling order item {instance.id}"
                )
            elif remaining_stock <= 0:
                logger.warning(
                    f"Out of stock warning: {instance.product_name} will be out of stock "
                    f"after fulfilling order item {instance.id}"
                )
                
    except Exception as e:
        logger.error(f"Error in check_stock_availability signal: {str(e)}")


# Transaction management signals
@receiver(post_save, sender=OrderItem)
def mark_transaction_start(sender, instance, **kwargs):
    """Mark the start of a transaction when order item is saved"""
    if not _is_in_transaction():
        _mark_transaction_start()


@receiver(post_save, sender=OrderItem)
def mark_transaction_end(sender, instance, **kwargs):
    """Mark the end of a transaction after order item is saved"""
    if _is_in_transaction():
        _mark_transaction_end()
            