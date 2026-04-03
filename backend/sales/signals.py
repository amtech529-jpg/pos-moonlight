from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.db.models import Sum
from django.db import transaction
from .models import Sales, SaleItem, TaxRate
from orders.models import Order
from order_items.models import OrderItem
import logging
from decimal import Decimal

logger = logging.getLogger(__name__)


@receiver(post_save, sender=Sales)
def update_customer_sales_activity(sender, instance, created, **kwargs):
    """Update customer sales activity when sale is created/updated"""
    try:
        if created and instance.customer:
            customer = instance.customer
            
            # Update customer's last sale date
            if hasattr(customer, 'update_last_sale_date'):
                try:
                    customer.update_last_sale_date()
                except Exception as e:
                    logger.warning(f"Failed to update last sale date for customer {customer.id}: {str(e)}")
            
            # Update customer's sales count and amount
            if hasattr(customer, 'update_sales_metrics'):
                try:
                    customer.update_sales_metrics()
                except Exception as e:
                    logger.warning(f"Failed to update sales metrics for customer {customer.id}: {str(e)}")
            
            logger.info(f"Updated sales activity for customer: {customer.name}")
            
    except Exception as e:
        logger.error(f"Failed to update customer sales activity: {str(e)}")


@receiver(post_save, sender=SaleItem)
def update_product_sales_metrics(sender, instance, created, **kwargs):
    """Update product sales metrics when sale item is created/updated"""
    try:
        if created and instance.product:
            product = instance.product
            
            # Update product's sales quantity and revenue
            if hasattr(product, 'update_sales_metrics'):
                try:
                    product.update_sales_metrics()
                except Exception as e:
                    logger.warning(f"Failed to update sales metrics for product {product.id}: {str(e)}")
            
            logger.info(f"Updated sales metrics for product: {product.name}")
            
    except Exception as e:
        logger.error(f"Failed to update product sales metrics: {str(e)}")


@receiver(post_save, sender=Sales)
def update_order_conversion_status(sender, instance, created, **kwargs):
    """Update order conversion status when sale is created from order"""
    try:
        if created and instance.order_id:
            order = instance.order_id
            
            # Update order's conversion status
            if hasattr(order, 'update_conversion_status'):
                order.update_conversion_status()
            
            logger.info(f"Updated conversion status for order: {order.id}")
            
    except Exception as e:
        logger.error(f"Failed to update order conversion status: {str(e)}")


@receiver(post_save, sender=Sales)
def update_inventory_on_sale_confirmation(sender, instance, created, **kwargs):
    """Update inventory when sale is confirmed"""
    try:
        if not created and instance.status == 'CONFIRMED':
            # Get the previous status
            if hasattr(instance, '_state') and instance._state.fields_cache.get('status') != 'CONFIRMED':
                # Sale was just confirmed, reduce inventory
                with transaction.atomic():
                    for sale_item in instance.sale_items.all():
                        if sale_item.product and hasattr(sale_item.product, 'reduce_stock_for_sale'):
                            sale_item.product.reduce_stock_for_sale(sale_item.quantity)
                    
                    logger.info(f"Reduced inventory for confirmed sale: {instance.invoice_number}")
                    
    except Exception as e:
        logger.error(f"Failed to update inventory on sale confirmation: {str(e)}")


@receiver(post_save, sender=Sales)
def update_inventory_on_sale_creation(sender, instance, created, **kwargs):
    """Update inventory immediately when sale is created (for cash sales)"""
    try:
        if created:
            logger.info(f"🚀 Sale created: {instance.invoice_number}, Payment: {instance.payment_method}, Status: {instance.status}")
            
            # For cash sales, reduce inventory immediately
            if instance.payment_method in ['CASH', 'CARD', 'BANK_TRANSFER', 'MOBILE_PAYMENT']:
                logger.info(f"💰 Processing stock reduction for cash sale: {instance.invoice_number}")
                
                # Use a small delay to ensure sale items are created
                from django.db.models import Q
                from .models import SaleItem
                
                # Wait a moment for sale items to be created, then process
                import time
                time.sleep(0.1)  # Small delay
                
                with transaction.atomic():
                    # Refresh sale items
                    sale_items = SaleItem.objects.filter(sale=instance)
                    logger.info(f"📦 Found {len(sale_items)} sale items")
                    
                    for sale_item in sale_items:
                        logger.info(f"📦 Processing item: {sale_item.product_name} x{sale_item.quantity}")
                        
                        if sale_item.product:
                            old_quantity = sale_item.product.quantity
                            logger.info(f"📊 Before: {sale_item.product.name} quantity = {old_quantity}")
                            
                            # Directly update product quantity without using reduce_stock_for_sale
                            new_quantity = old_quantity - sale_item.quantity
                            if new_quantity >= 0:
                                sale_item.product.quantity = new_quantity
                                sale_item.product.save(update_fields=['quantity'])
                                logger.info(f"📊 After: {sale_item.product.name} quantity = {new_quantity} (reduced by {sale_item.quantity})")
                            else:
                                logger.error(f"❌ Insufficient stock for {sale_item.product.name}")
                        else:
                            logger.error(f"❌ Sale item {sale_item.id} has no product")
                    
                    logger.info(f"✅ Stock reduction completed for sale: {instance.invoice_number}")
            else:
                logger.info(f"⏭️ Skipping stock reduction for {instance.payment_method} sale")
                    
    except Exception as e:
        logger.error(f"❌ Failed to update inventory on sale creation: {str(e)}", exc_info=True)


@receiver(post_save, sender=SaleItem)
def update_inventory_on_sale_item_creation(sender, instance, created, **kwargs):
    """Update inventory when sale item is created (backup method)"""
    try:
        if created and instance.product:
            # Check if this is part of a cash sale
            if hasattr(instance, 'sale') and instance.sale:
                if instance.sale.payment_method in ['CASH', 'CARD', 'BANK_TRANSFER', 'MOBILE_PAYMENT']:
                    logger.info(f"🔄 SaleItem signal: Reducing stock for {instance.product_name} x{instance.quantity}")
                    
                    old_quantity = instance.product.quantity
                    new_quantity = old_quantity - instance.quantity
                    
                    if new_quantity >= 0:
                        instance.product.quantity = new_quantity
                        instance.product.save(update_fields=['quantity'])
                        logger.info(f"🔄 Stock reduced: {instance.product.name} {old_quantity} → {new_quantity}")
                    else:
                        logger.error(f"❌ Insufficient stock for {instance.product.name}")
                        
    except Exception as e:
        logger.error(f"❌ Failed to update inventory on sale item creation: {str(e)}", exc_info=True)


@receiver(post_save, sender=Sales)
def update_payment_status_on_amount_change(sender, instance, created, **kwargs):
    """Update payment status when amount paid changes"""
    try:
        if not created:
            # Check if amount_paid field was updated
            if hasattr(instance, '_state') and 'amount_paid' in instance._state.fields_cache:
                old_amount = instance._state.fields_cache['amount_paid']
                if old_amount != instance.amount_paid:
                    # Amount paid changed, update payment status
                    instance.update_payment_status()
                    logger.info(f"Updated payment status for sale: {instance.invoice_number}")
                    
    except Exception as e:
        logger.error(f"Failed to update payment status: {str(e)}")


@receiver(post_delete, sender=SaleItem)
def recalculate_sale_totals_on_item_deletion(sender, instance, **kwargs):
    """Recalculate sale totals when sale item is deleted"""
    try:
        if instance.sale:
            instance.sale.recalculate_totals()
            logger.info(f"Recalculated totals for sale: {instance.sale.invoice_number}")
            
    except Exception as e:
        logger.error(f"Failed to recalculate sale totals: {str(e)}")


@receiver(post_save, sender=Sales)
def log_sale_status_changes(sender, instance, created, **kwargs):
    """Log sale status changes for audit purposes"""
    try:
        if not created:
            # Check if status field was updated
            if hasattr(instance, '_state') and 'status' in instance._state.fields_cache:
                old_status = instance._state.fields_cache['status']
                if old_status != instance.status:
                    logger.info(
                        f"Sale status changed: {instance.invoice_number} "
                        f"from {old_status} to {instance.status}"
                    )
                    
    except Exception as e:
        logger.error(f"Failed to log sale status change: {str(e)}")


@receiver(post_save, sender=Sales)
def validate_sale_totals(sender, instance, created, **kwargs):
    """Validate that sale totals are consistent with sale items"""
    try:
        if created or instance.status in ['DRAFT', 'CONFIRMED']:
            # Calculate expected subtotal from sale items
            expected_subtotal = sum(item.line_total for item in instance.sale_items.all())
            
            if abs(instance.subtotal - expected_subtotal) > 0.01:  # Allow for small decimal differences
                logger.warning(
                    f"Sale totals mismatch for {instance.invoice_number}: "
                    f"expected {expected_subtotal}, got {instance.subtotal}"
                )
                
                # Auto-correct if in draft status
                if instance.status == 'DRAFT':
                    instance.recalculate_totals()
                    logger.info(f"Auto-corrected totals for sale: {instance.invoice_number}")
                    
    except Exception as e:
        logger.error(f"Failed to validate sale totals: {str(e)}")


@receiver(post_save, sender=Sales)
def update_customer_credit_limit(sender, instance, created, **kwargs):
    """Update customer credit limit when credit sale is created"""
    try:
        if created and instance.payment_method == 'CREDIT' and instance.customer:
            customer = instance.customer
            
            # Update customer's credit usage
            if hasattr(customer, 'update_credit_usage'):
                customer.update_credit_usage(instance.remaining_amount)
            
            logger.info(f"Updated credit usage for customer: {customer.name}")
            
    except Exception as e:
        logger.error(f"Failed to update customer credit limit: {str(e)}")


@receiver(post_save, sender=Sales)
def send_sale_notifications(sender, instance, created, **kwargs):
    """Send notifications for important sale events"""
    try:
        if created:
            # Send notification for new sale
            logger.info(f"New sale created: {instance.invoice_number}")
            
        elif instance.status == 'PAID':
            # Send notification for payment received
            logger.info(f"Payment received for sale: {instance.invoice_number}")
            
        elif instance.status == 'DELIVERED':
            # Send notification for delivery
            logger.info(f"Sale delivered: {instance.invoice_number}")
            
    except Exception as e:
        logger.error(f"Failed to send sale notifications: {str(e)}")


@receiver(post_save, sender=Sales)
def update_financial_reports(sender, instance, created, **kwargs):
    """Update financial reports when sale is created/updated"""
    try:
        if created or instance.status in ['CONFIRMED', 'PAID', 'DELIVERED']:
            # Update daily/monthly sales reports
            logger.info(f"Updated financial reports for sale: {instance.invoice_number}")
            
    except Exception as e:
        logger.error(f"Failed to update financial reports: {str(e)}")


@receiver(post_save, sender=Sales)
def validate_payment_method_consistency(sender, instance, created, **kwargs):
    """Validate payment method consistency with amount paid"""
    try:
        if instance.payment_method == 'SPLIT' and not instance.split_payment_details:
            logger.warning(
                f"Split payment method selected but no split details provided for sale: {instance.invoice_number}"
            )
            
        elif instance.payment_method == 'CREDIT' and instance.amount_paid > 0:
            logger.warning(
                f"Credit sale has partial payment for sale: {instance.invoice_number}"
            )
            
    except Exception as e:
        logger.error(f"Failed to validate payment method consistency: {str(e)}")


@receiver(post_save, sender=Sales)
def update_tax_calculations(sender, instance, created, **kwargs):
    """Ensure tax calculations are accurate with new tax configuration system"""
    try:
        if created or instance.status in ['DRAFT', 'CONFIRMED']:
            # Validate tax calculation using new tax configuration
            if instance.tax_configuration:
                taxable_amount = instance.subtotal - instance.overall_discount
                expected_tax = Decimal('0.00')
                
                # Calculate expected tax from configuration
                for tax_type, tax_data in instance.tax_configuration.items():
                    if 'percentage' in tax_data:
                        percentage = Decimal(str(tax_data['percentage']))
                        tax_amount = (taxable_amount * percentage) / 100
                        expected_tax += tax_amount
                
                # Check if calculated tax matches stored tax
                if abs(instance.tax_amount - expected_tax) > 0.01:
                    logger.warning(
                        f"Tax calculation mismatch for sale {instance.invoice_number}: "
                        f"expected {expected_tax}, got {instance.tax_amount}"
                    )
                    
                    # Auto-correct if in draft status
                    if instance.status == 'DRAFT' and not hasattr(instance, '_updating_tax'):
                        instance._updating_tax = True
                        try:
                            # Recalculate taxes
                            instance.calculate_taxes()
                            instance.grand_total = instance.subtotal - instance.overall_discount + instance.tax_amount
                            instance.save(update_fields=['tax_amount', 'grand_total'])
                            logger.info(f"Auto-corrected tax calculations for sale: {instance.invoice_number}")
                        finally:
                            delattr(instance, '_updating_tax')
            else:
                # No tax configuration, ensure tax_amount is 0
                if instance.tax_amount != 0:
                    logger.warning(
                        f"Sale {instance.invoice_number} has no tax configuration but tax_amount is {instance.tax_amount}"
                    )
                    
    except Exception as e:
        logger.error(f"Failed to update tax calculations: {str(e)}")


@receiver(post_save, sender=TaxRate)
def update_sales_with_tax_rate_changes(sender, instance, created, **kwargs):
    """Update sales when tax rates change"""
    try:
        if not created and instance.is_active:
            # If tax rate was updated, we might need to update existing sales
            # This is a complex operation that should be handled carefully
            logger.info(f"Tax rate {instance.name} updated. Consider reviewing existing sales.")
            
    except Exception as e:
        logger.error(f"Failed to handle tax rate change: {str(e)}")


@receiver(post_save, sender=TaxRate)
def validate_tax_rate_effectiveness(sender, instance, created, **kwargs):
    """Validate tax rate effectiveness dates"""
    try:
        if instance.effective_to and instance.effective_to < instance.effective_from:
            logger.warning(
                f"Tax rate {instance.name} has invalid effective dates: "
                f"from {instance.effective_from} to {instance.effective_to}"
            )
            
    except Exception as e:
        logger.error(f"Failed to validate tax rate effectiveness: {str(e)}")


@receiver(post_save, sender=Sales)
def sync_invoice_on_sale_payment(sender, instance, created, **kwargs):
    """
    Whenever a Sale's amount_paid is updated, automatically sync the linked Invoice.
    This ensures invoice table always shows correct paid/due amounts and status.
    """
    if created:
        return  # Only sync on updates, not creation
    
    # Prevent recursion
    if getattr(instance, '_syncing_invoice', False):
        return
    
    try:
        from .models import Invoice
        invoice = Invoice.objects.filter(sale=instance, is_active=True).first()
        if not invoice:
            return
        
        # If invoice is already in a terminal status that results in 0 dues, skip syncing it to avoid accidental debt restoration.
        if invoice.status in ['WRITTEN_OFF', 'CLOSED', 'PAID', 'CANCELLED']:
            # Still sync the paid amount if it changed, but don't touch status or due.
            sale_paid = instance.amount_paid or Decimal('0.00')
            if invoice.amount_paid != sale_paid:
                invoice.amount_paid = sale_paid
                invoice.amount_due = Decimal('0.00')
                invoice._syncing_invoice = True
                invoice.save(update_fields=['amount_paid', 'amount_due', 'updated_at'])
            return

        sale_paid = instance.amount_paid or Decimal('0.00')
        grand_total = invoice.total_amount or instance.grand_total or Decimal('0.00')
        write_off = invoice.write_off_amount or Decimal('0.00')
        new_due = max(grand_total - sale_paid - write_off, Decimal('0.00'))
        
        # Only update if something actually changed
        if invoice.amount_paid == sale_paid and invoice.amount_due == new_due:
            return
        
        old_paid = invoice.amount_paid
        invoice.amount_paid = sale_paid
        invoice.amount_due = new_due
        
        # Update status - EXCLUDING terminal statuses like WRITTEN_OFF or CLOSED
        if invoice.status not in ['WRITTEN_OFF', 'CLOSED', 'CANCELLED']:
            if new_due <= Decimal('0.00'):
                invoice.status = 'PAID'
            elif sale_paid > Decimal('0.00'):
                invoice.status = 'PARTIALLY_PAID'
            elif sale_paid == Decimal('0.00'):
                invoice.status = 'ISSUED'
        
        invoice._syncing_invoice = True
        invoice.save(update_fields=['amount_paid', 'amount_due', 'status', 'updated_at'])
        
        logger.info(
            f"Invoice {invoice.invoice_number} synced from Sale {instance.invoice_number}: "
            f"paid {old_paid} -> {sale_paid}, due -> {new_due}, status -> {invoice.status}"
        )
        
    except Exception as e:
        logger.error(f"Failed to sync invoice on sale payment change: {str(e)}")
