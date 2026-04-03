import os
import django

# Setup Django Environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.db import connection

def clear_test_data():
    # Corrected table names from manage.py shell
    tables = [
        'payment',
        'sales_invoice',
        'sales_receipt',
        'tax_rates',
        'order_item',
        'order',
        'sale_item',
        'sales',
        'quotations_quotationitem',
        'quotation',
        'expense',
        'customer'
    ]

    print("--- Starting Final SQL Data Cleanup ---")
    
    with connection.cursor() as cursor:
        for table in tables:
            try:
                # TRUNCATE with CASCADE is the safest way to clear linked data
                cursor.execute(f"TRUNCATE TABLE \"{table}\" RESTART IDENTITY CASCADE;")
                print(f"Successfully truncated {table}")
            except Exception as e:
                try:
                    cursor.execute(f"DELETE FROM \"{table}\";")
                    print(f"Successfully deleted from {table}")
                except Exception as e2:
                    print(f"Skipping {table}: {e2}")

    print("--- Cleanup Finished ---")

if __name__ == "__main__":
    clear_test_data()
