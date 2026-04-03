#!/usr/bin/env python
"""
Script to recalculate all sales totals
Run this script to fix issues with sales showing 0 subtotal and quantities
"""

import os
import sys
import django

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'settings')
django.setup()

from sales.models import Sales
from django.db import transaction

def recalculate_all_sales():
    """Recalculate totals for all sales"""
    try:
        print("🔄 Starting recalculation of all sales...")
        
        # Get all active sales
        sales = Sales.objects.filter(is_active=True)
        total_count = sales.count()
        
        print(f"📊 Found {total_count} active sales to recalculate")
        
        with transaction.atomic():
            for i, sale in enumerate(sales, 1):
                try:
                    # Store old values for comparison
                    old_subtotal = sale.subtotal
                    old_grand_total = sale.grand_total
                    old_items_count = sale.total_items
                    
                    # Recalculate
                    sale.recalculate_totals()
                    
                    # Check if values changed
                    new_subtotal = sale.subtotal
                    new_grand_total = sale.grand_total
                    new_items_count = sale.total_items
                    
                    if (old_subtotal != new_subtotal or 
                        old_grand_total != new_grand_total or
                        old_items_count != new_items_count):
                        print(f"✅ [{i}/{total_count}] {sale.invoice_number}: "
                              f"Items: {old_items_count}→{new_items_count}, "
                              f"Subtotal: {old_subtotal}→{new_subtotal}, "
                              f"Grand Total: {old_grand_total}→{new_grand_total}")
                    else:
                        print(f"⏸️ [{i}/{total_count}] {sale.invoice_number}: No changes needed")
                        
                except Exception as e:
                    print(f"❌ [{i}/{total_count}] Error recalculating {sale.invoice_number}: {e}")
        
        print("🎉 Recalculation completed!")
        
    except Exception as e:
        print(f"❌ Error during recalculation: {e}")
        return False
    
    return True

if __name__ == "__main__":
    success = recalculate_all_sales()
    sys.exit(0 if success else 1)
