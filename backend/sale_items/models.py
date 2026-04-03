# Sale Items models are defined in the sales app
# This file exists for app structure consistency and backward compatibility

from sales.models import SaleItem

# Re-export SaleItem for backward compatibility
__all__ = ['SaleItem']
