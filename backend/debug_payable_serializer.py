
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
from payables.serializers import PayableDetailSerializer, PayableCreateSerializer
from vendors.models import Vendor
from django.contrib.auth import get_user_model

User = get_user_model()

def debug_create_payable_with_serializer():
    print("------- STARTING DEBUG PAYABLE SERIALIZER TEST -------")
    try:
        # 1. Get a user
        user = User.objects.first()
        if not user:
            print("No user found. Creating dummy user.")
            user = User.objects.create_user(username='debug_serializer_user', password='password')
        print(f"Using user: {user}")

        # 2. Prepare payload
        payload = {
            'creditor_name': 'Test Creditor Serializer',
            'amount_borrowed': Decimal('500.00'),
            'amount_paid': Decimal('0.00'),
            'reason_or_item': 'Debug Serializer Reason',
            'date_borrowed': date.today(),
            'expected_repayment_date': date.today(),
            'priority': 'LOW',
            'notes': 'Debug Serializer Note',
            'created_by': user,
            'source_type': 'MANUAL'
        }
        
        # 3. Create object
        print("Creating Payable instance...")
        payable = Payable.objects.create(**payload)
        print(f"Payable created with ID: {payable.id}")
        
        # 4. Attempt Serialization (THIS IS LIKELY WHERE IT FAILS)
        print("Attempting to Serialize using PayableDetailSerializer...")
        serializer = PayableDetailSerializer(payable)
        data = serializer.data
        
        print("SUCCESS! Serialized Data keys:")
        print(data.keys())
        
        # Clean up
        payable.delete()
        print("Test payable deleted.")
        
    except Exception as e:
        print("\n!!!!!!!!!!!!!! CAUGHT EXCEPTION DURING SERIALIZATION !!!!!!!!!!!!!!")
        print(f"Type: {type(e).__name__}")
        print(f"Message: {str(e)}")
        print("Traceback:")
        traceback.print_exc()
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

if __name__ == '__main__':
    debug_create_payable_with_serializer()
