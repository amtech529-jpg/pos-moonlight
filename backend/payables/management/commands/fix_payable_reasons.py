from django.core.management.base import BaseCommand
from django.db import transaction, models
from payables.models import Payable


class Command(BaseCommand):
    help = 'Fix existing payable records with null reason_or_item fields'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be updated without making changes',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        
        # Find all payables with null or empty reason_or_item
        payables_without_reason = Payable.objects.filter(
            models.Q(reason_or_item__isnull=True) | 
            models.Q(reason_or_item='')
        )
        
        count = payables_without_reason.count()
        
        if count == 0:
            self.stdout.write(
                self.style.SUCCESS('No payables found with null/empty reason_or_item fields.')
            )
            return
        
        self.stdout.write(f'Found {count} payables with null/empty reason_or_item fields.')
        
        if dry_run:
            self.stdout.write('DRY RUN - No changes will be made.')
            for payable in payables_without_reason[:5]:  # Show first 5
                self.stdout.write(f'  - {payable.id}: {payable.creditor_name}')
            if count > 5:
                self.stdout.write(f'  ... and {count - 5} more')
            return
        
        # Update the records
        updated_count = 0
        with transaction.atomic():
            for payable in payables_without_reason:
                # Generate a default reason based on available data
                if payable.notes and payable.notes.strip():
                    # Use notes if available
                    default_reason = payable.notes[:100]  # Truncate to reasonable length
                else:
                    # Generate a generic reason
                    default_reason = f"Borrowed amount for {payable.creditor_name}"
                
                payable.reason_or_item = default_reason
                payable.save(update_fields=['reason_or_item', 'updated_at'])
                updated_count += 1
                
                self.stdout.write(f'  Updated {payable.id}: {payable.creditor_name}')
        
        self.stdout.write(
            self.style.SUCCESS(f'Successfully updated {updated_count} payables.')
        )
