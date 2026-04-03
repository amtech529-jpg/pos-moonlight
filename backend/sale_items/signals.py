# Sale Items signals are defined in the sales app
# This file exists for app structure consistency and backward compatibility

from sales.signals import (
    update_product_sales_metrics,
    recalculate_sale_totals_on_item_deletion
)

# Re-export signals for backward compatibility
__all__ = [
    'update_product_sales_metrics',
    'recalculate_sale_totals_on_item_deletion'
]
