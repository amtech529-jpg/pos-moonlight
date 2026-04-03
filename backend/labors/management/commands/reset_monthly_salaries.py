from django.core.management.base import BaseCommand
from labors.models import Labor
from datetime import date


class Command(BaseCommand):
    help = 'Reset monthly salaries for all labors (run monthly)'

    def add_arguments(self, parser):
        parser.add_argument(
            '--force',
            action='store_true',
            help='Force reset even if not a new month',
        )

    def handle(self, *args, **options):
        today = date.today()
        current_month = today.month
        current_year = today.year
        
        updated_count = 0
        skipped_count = 0
        
        for labor in Labor.objects.filter(is_active=True):
            if options['force'] or labor.current_month != current_month or labor.current_year != current_year:
                labor.remaining_monthly_salary = labor.salary
                labor.current_month = current_month
                labor.current_year = current_year
                labor.save(update_fields=['remaining_monthly_salary', 'current_month', 'current_year'])
                updated_count += 1
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Reset salary for {labor.name}: {labor.salary} PKR'
                    )
                )
            else:
                skipped_count += 1
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully reset {updated_count} labors, skipped {skipped_count} labors'
            )
        )












