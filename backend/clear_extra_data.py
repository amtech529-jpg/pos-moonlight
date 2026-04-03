import os
import django

# Setup Django Environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import connection

def clear_additional_data():
    # Additional tables for Inventory, Purchases, HR, Salary, Vendors etc.
    tables = [
        'purchases_purchaseitem',
        'purchases_purchase',
        'labors_salaryslip',
        'labor',
        'advance_payment',
        'stock_reservation',
        'stock_change_log',
        'product',
        'vendor'
    ]

    print("--- Starting Additional Data Cleanup ---")
    
    with connection.cursor() as cursor:
        for table in tables:
            try:
                # TRUNCATE with CASCADE to handle foreign keys
                cursor.execute(f"TRUNCATE TABLE \"{table}\" RESTART IDENTITY CASCADE;")
                print(f"Successfully truncated {table}")
            except Exception as e:
                try:
                    cursor.execute(f"DELETE FROM \"{table}\";")
                    print(f"Successfully deleted from {table}")
                except Exception as e2:
                    print(f"Skipping {table}: {e2}")

    print("--- Additional Cleanup Finished ---")

if __name__ == "__main__":
    clear_additional_data()
