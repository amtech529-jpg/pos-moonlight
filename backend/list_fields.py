import os
import django
import sys

# Setup Django
sys.path.append('d:\\R_Tech_junior_developer\\moon-light-main\\pos-moonlight-main\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from sales.models import Invoice

def list_fields():
    print("--- Invoice Fields ---")
    for field in Invoice._meta.fields:
        print(f"Name: {field.name}")

if __name__ == "__main__":
    list_fields()
