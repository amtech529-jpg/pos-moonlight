
import os
import django
import sys
import traceback
from decimal import Decimal
from datetime import date

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from payables.models import Payable
from vendors.models import Vendor
from django.contrib.auth import get_user_model

User = get_user_model()

def debug_create_payable():
    print("------- STARTING DEBUG PAYABLE CREATION -------")
    try:
        # 1. Get a user (or create one if needed)
        user = User.objects.first()
        if not user:
            print("No user found. Creating dummy user.")
            user = User.objects.create_user(username='debug_user', password='password')
        print(f"Using user: {user}")

        # 2. Prepare payload
        payload = {
            'creditor_name': 'Test Creditor',
            'amount_borrowed': Decimal('1000.00'),
            'amount_paid': Decimal('0.00'),
            'reason_or_item': 'Debug Reason',
            'date_borrowed': date.today(),
            'expected_repayment_date': date.today(),
            'priority': 'MEDIUM',
            'notes': 'Debug Note',
            'created_by': user,
            'source_type': 'MANUAL'
        }
        
        print(f"Payload: {payload}")

        # 3. Attempt creation directly via Model
        print("Attempting to create Payable instance...")
        payable = Payable(**payload)
        
        print("Calling payable.full_clean()...")
        payable.full_clean()
        
        print("Calling payable.save()...")
        payable.save()
        
        print(f"SUCCESS! Payable created with ID: {payable.id}")
        
    except Exception as e:
        print("\n!!!!!!!!!!!!!! CAUGHT EXCEPTION !!!!!!!!!!!!!!")
        print(f"Type: {type(e).__name__}")
        print(f"Message: {str(e)}")
        print("Traceback:")
        traceback.print_exc()
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

if __name__ == '__main__':
    debug_create_payable()
