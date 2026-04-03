import os
import django
import pandas as pd
import datetime
import sys

# Add project root to path
sys.path.append(os.getcwd())

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from customers.models import Customer
from products.models import Product

def test_export(model_class, name):
    print(f"Testing export for {name}...")
    queryset = model_class.objects.all()
    if not queryset.exists():
        print(f"No data for {name}, creating dummy data...")
        # Create dummy data if needed
        pass
        
    data = list(queryset.values())
    df = pd.DataFrame(data)

    print(f"Data frame created. Columns: {df.columns}")
    # print(f"Data types: {df.dtypes}")

    # Simulate the fix logic
    import uuid
    for col in df.columns:
        if df[col].dtype == 'object':
            first_valid_idx = df[col].first_valid_index()
            if first_valid_idx is not None:
                 val = df.at[first_valid_idx, col]
                 if isinstance(val, uuid.UUID):
                     print(f"Converting UUID col: {col}")
                     df[col] = df[col].astype(str)

    for col in df.select_dtypes(include=['datetime64[ns, UTC]', 'datetime64[ns]']).columns:
         if hasattr(df[col].dt, 'tz') and df[col].dt.tz is not None:
             print(f"Removing timezone from: {col}")
             df[col] = df[col].dt.tz_localize(None)

    print("Attempting to export...")
    try:
        with pd.ExcelWriter(f'test_export_{name}.xlsx', engine='openpyxl') as writer:
            df.to_excel(writer, index=False, sheet_name=name)
        print(f"Export successful for {name}!")
        try:
            os.remove(f'test_export_{name}.xlsx')
        except:
            pass
    except Exception as e:
        print(f"Export failed for {name}: {e}")
        import traceback
        traceback.print_exc()

test_export(Customer, 'customers')
test_export(Product, 'products')
