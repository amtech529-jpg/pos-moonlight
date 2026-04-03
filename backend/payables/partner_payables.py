"""
Utility functions for auto-generating partner rental payables from orders.

When an order contains items rented from partners (rented_from_partner=True),
this module creates corresponding Payable records to track what is owed to each partner.
"""
import logging
from decimal import Decimal
from datetime import timedelta
from django.db import transaction
from django.utils import timezone

logger = logging.getLogger(__name__)


@transaction.atomic
def generate_partner_payables(order, created_by=None):
    """
    Generate payables for partner-rented items in an order.
    
    Groups items by partner (vendor) and creates one payable per partner.
    
    Args:
        order: Order instance
        created_by: User who triggered the generation
    
    Returns:
        list of created Payable instances
    """
    from order_items.models import OrderItem
    from payables.models import Payable
    
    # Check if payables already exist for this order
    existing = Payable.objects.filter(order=order, source_type='PARTNER_RENTAL', is_active=True)
    if existing.exists():
        logger.info(f"Partner payables already exist for Order {order.id}, skipping.")
        return list(existing)
    
    # Get partner items from this order
    partner_items = OrderItem.objects.filter(
        order=order,
        rented_from_partner=True,
        partner__isnull=False,
        is_active=True
    ).select_related('partner', 'product')
    
    if not partner_items.exists():
        logger.info(f"No partner rental items in Order {order.id}")
        return []
    
    # Group items by partner
    partner_groups = {}
    for item in partner_items:
        partner_id = item.partner_id
        if partner_id not in partner_groups:
            partner_groups[partner_id] = {
                'partner': item.partner,
                'items': [],
                'total': Decimal('0.00')
            }
        
        # Calculate payable amount using partner_rate (what we owe the partner)
        partner_rate = item.partner_rate or item.rate
        item_total = Decimal(str(item.quantity)) * partner_rate * Decimal(str(item.days))
        
        partner_groups[partner_id]['items'].append({
            'product_name': item.product_name or item.product.name,
            'quantity': item.quantity,
            'rate': float(partner_rate),
            'days': item.days,
            'total': float(item_total),
        })
        partner_groups[partner_id]['total'] += item_total
    
    # Create payables for each partner
    created_payables = []
    for partner_id, data in partner_groups.items():
        partner = data['partner']
        
        # Build description of items
        items_description = "\n".join([
            f"  • {item['product_name']} x{item['quantity']} @ PKR {item['rate']}/day x {item['days']} days = PKR {item['total']}"
            for item in data['items']
        ])
        
        # Build simple reason and detailed notes
        total_qty = sum(item['quantity'] for item in data['items'])
        reason = f"Partner Rental (Order #{order.id}) [Qty: {total_qty}]"
        
        detail_notes = (
            f"Auto-generated for Order #{order.id}\n"
            f"Customer: {order.customer_name}\n"
            f"Items:\n" + "\n".join([f"• {item['product_name']} x{item['quantity']}" for item in data['items']])
        )
        
        # Set repayment date (15 days after return date)
        base_date = order.return_date or order.expected_delivery_date or order.date_ordered
        repayment_date = base_date + timedelta(days=15)
        
        payable = Payable.objects.create(
            creditor_name=partner.name,
            creditor_phone=partner.phone or '',
            creditor_email='', 
            vendor=partner,
            order=order,
            source_type='PARTNER_RENTAL',
            amount_borrowed=data['total'],
            reason_or_item=reason,
            date_borrowed=order.date_ordered,
            expected_repayment_date=repayment_date,
            priority='MEDIUM',
            notes=detail_notes,
            created_by=created_by,
        )
        
        created_payables.append(payable)
        
        logger.info(
            f"Created partner payable: {partner.name} - PKR {data['total']} "
            f"for {len(data['items'])} items in Order {order.id}"
        )
    
    return created_payables


def recalculate_partner_payables(order, created_by=None):
    """
    Recalculate partner payables when order items change.
    Deletes old auto-generated payables and creates new ones.
    
    Only recalculates if no payments have been made on existing payables.
    """
    from payables.models import Payable
    
    existing = Payable.objects.filter(
        order=order, source_type='PARTNER_RENTAL', is_active=True
    )
    
    # Check if any payments have been made
    has_payments = any(p.amount_paid > Decimal('0.00') for p in existing)
    
    if has_payments:
        logger.warning(
            f"Cannot recalculate partner payables for Order {order.id}: "
            f"payments already made on existing payables."
        )
        return list(existing)
    
    # Delete old payables
    existing.delete()
    
    # Generate new ones
    return generate_partner_payables(order, created_by)
