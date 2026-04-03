
import os
import django
import sys
import json

# Setup django
sys.path.append('d:/R_Tech_junior_developer/moon-light-main/pos-moonlight-main/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.conf import settings
settings.ALLOWED_HOSTS = ['*']

from rest_framework.test import APIClient
from django.contrib.auth import get_user_model
from labors.models import Labor

def check_list_api():
    client = APIClient()
    User = get_user_model()
    user = User.objects.first()
    client.force_authenticate(user=user)
    
    # 1. List ALL
    print("--- ALL SLIPS ---")
    response = client.get('/api/v1/labors/salary-slips/')
    print(f"Status: {response.status_code}")
    print(json.dumps(response.data, indent=2, default=str))
    
    # 2. List with month/year
    print("\n--- MONTH 2 YEAR 2026 ---")
    response = client.get('/api/v1/labors/salary-slips/', {'month': 2, 'year': 2026})
    print(f"Status: {response.status_code}")
    print(json.dumps(response.data, indent=2, default=str))

    # 3. List with labor_id
    labor = Labor.objects.first()
    if labor:
        print(f"\n--- LABOR {labor.name} ({labor.id}) ---")
        response = client.get('/api/v1/labors/salary-slips/', {'labor_id': str(labor.id)})
        print(f"Status: {response.status_code}")
        print(json.dumps(response.data, indent=2, default=str))

if __name__ == "__main__":
    check_list_api()
