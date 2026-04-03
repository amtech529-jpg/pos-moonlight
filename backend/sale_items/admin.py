# Sale Items admin is defined in the sales app
# This file exists for app structure consistency and backward compatibility

from sales.admin import SaleItemAdmin

# Re-export admin for backward compatibility
__all__ = ['SaleItemAdmin']
