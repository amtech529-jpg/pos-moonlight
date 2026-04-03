from django.core.management.base import BaseCommand
from labors.models import Labor
from advance_payments.models import AdvancePayment
from decimal import Decimal


class Command(BaseCommand):
    help = 'Test labor methods for advance calculations'

    def handle(self, *args, **options):
        self.stdout.write('Testing Labor Methods...')
        
        # Get all labors with salary
        labors = Labor.objects.filter(salary__gt=0)
        
        if not labors.exists():
            self.stdout.write(self.style.ERROR('No labors found with salary > 0'))
            return
        
        for labor in labors:
            self.stdout.write(f'\n--- Labor: {labor.name} ---')
            self.stdout.write(f'Salary: {labor.salary}')
            
            try:
                # Test remaining monthly salary
                remaining_monthly = labor.remaining_monthly_salary
                self.stdout.write(f'Remaining Monthly Salary: {remaining_monthly}')
                
                # Test total advances
                total_advances = labor.get_total_advances_amount()
                self.stdout.write(f'Total Advances This Month: {total_advances}')
                
                # Test remaining advance amount
                remaining_advance = labor.get_remaining_advance_amount()
                self.stdout.write(f'Remaining Advance Amount: {remaining_advance}')
                
                # Test advance payments
                advance_payments = AdvancePayment.objects.filter(
                    labor=labor,
                    date__year=labor.created_at.year,
                    date__month=labor.created_at.month
                )
                self.stdout.write(f'Advance Payments This Month: {advance_payments.count()}')
                
                for payment in advance_payments:
                    self.stdout.write(f'  - {payment.amount} on {payment.date}')
                
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'Error: {str(e)}'))
        
        self.stdout.write(self.style.SUCCESS('\nTesting completed!'))
