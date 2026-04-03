import os
import django
import sys

# Add the backend directory to sys.path
sys.path.append('d:/R_Tech_junior_developer/moon-light-main/pos-moonlight-main/backend')

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from labors.models import Labor
from advance_payments.models import AdvancePayment
from expenses.models import Expense

print("--- Labors ---")
for labor in Labor.objects.all():
    advances = AdvancePayment.objects.filter(labor=labor, is_active=True)
    total_advances = sum(a.amount for a in advances)
    print(f"Name: {labor.name}")
    print(f"  Monthly Salary: {labor.salary}")
    print(f"  Remaining Salary: {labor.remaining_monthly_salary}")
    print(f"  Total Advances Record: {total_advances}")
    print(f"  Calculation (Salary - Advances): {labor.salary - total_advances}")
    print("---")

print("\n--- Recent Expenses with Salary Deduction ---")
for exp in Expense.objects.filter(is_salary_deductible=True).order_by('-created_at')[:5]:
    print(f"Expense: {exp.expense}")
    print(f"  Amount: {exp.amount}")
    print(f"  Labor: {exp.deductible_labor.name if exp.deductible_labor else 'None'}")
    print(f"  ID: {exp.id}")
    advance = AdvancePayment.objects.filter(source_id=str(exp.id)).first()
    print(f"  Advance Payment Attached: {True if advance else False}")
    if advance:
        print(f"    Advance Active: {advance.is_active}")
        print(f"    Advance Amount: {advance.amount}")
