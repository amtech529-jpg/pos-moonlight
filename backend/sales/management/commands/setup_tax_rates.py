from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from decimal import Decimal
from datetime import date
from sales.models import TaxRate


class Command(BaseCommand):
    help = 'Set up and manage tax rates for the sales system'

    def add_arguments(self, parser):
        parser.add_argument(
            '--action',
            choices=['list', 'create', 'update', 'delete', 'reset'],
            default='list',
            help='Action to perform on tax rates'
        )
        parser.add_argument(
            '--tax-type',
            choices=['GST', 'FED', 'WHT', 'ADDITIONAL', 'CUSTOM'],
            help='Type of tax to work with'
        )
        parser.add_argument(
            '--name',
            help='Name of the tax rate'
        )
        parser.add_argument(
            '--percentage',
            type=float,
            help='Tax percentage rate'
        )
        parser.add_argument(
            '--description',
            help='Description of when this tax rate applies'
        )
        parser.add_argument(
            '--effective-from',
            help='Date from which this tax rate is effective (YYYY-MM-DD)'
        )
        parser.add_argument(
            '--effective-to',
            help='Date until which this tax rate is effective (YYYY-MM-DD)'
        )
        parser.add_argument(
            '--id',
            help='ID of the tax rate to update or delete'
        )

    def handle(self, *args, **options):
        action = options['action']
        
        if action == 'list':
            self.list_tax_rates(options)
        elif action == 'create':
            self.create_tax_rate(options)
        elif action == 'update':
            self.update_tax_rate(options)
        elif action == 'delete':
            self.delete_tax_rate(options)
        elif action == 'reset':
            self.reset_tax_rates(options)

    def list_tax_rates(self, options):
        """List all tax rates"""
        tax_type = options.get('tax_type')
        
        if tax_type:
            tax_rates = TaxRate.objects.filter(tax_type=tax_type)
        else:
            tax_rates = TaxRate.objects.all()
        
        if not tax_rates.exists():
            self.stdout.write(self.style.WARNING('No tax rates found.'))
            return
        
        self.stdout.write(self.style.SUCCESS(f'Found {tax_rates.count()} tax rate(s):'))
        self.stdout.write('')
        
        for tax_rate in tax_rates:
            status = '✓ Active' if tax_rate.is_active else '✗ Inactive'
            effective = 'Currently Effective' if tax_rate.is_currently_effective else 'Not Currently Effective'
            
            self.stdout.write(f'ID: {tax_rate.id}')
            self.stdout.write(f'Name: {tax_rate.name}')
            self.stdout.write(f'Type: {tax_rate.get_tax_type_display()}')
            self.stdout.write(f'Rate: {tax_rate.percentage}%')
            self.stdout.write(f'Status: {status}')
            self.stdout.write(f'Effectiveness: {effective}')
            self.stdout.write(f'Effective From: {tax_rate.effective_from}')
            if tax_rate.effective_to:
                self.stdout.write(f'Effective To: {tax_rate.effective_to}')
            self.stdout.write(f'Description: {tax_rate.description or "No description"}')
            self.stdout.write('-' * 50)

    def create_tax_rate(self, options):
        """Create a new tax rate"""
        required_fields = ['name', 'tax_type', 'percentage']
        missing_fields = [field for field in required_fields if not options.get(field)]
        
        if missing_fields:
            raise CommandError(f'Missing required fields: {", ".join(missing_fields)}')
        
        try:
            with transaction.atomic():
                tax_rate = TaxRate.objects.create(
                    name=options['name'],
                    tax_type=options['tax_type'],
                    percentage=Decimal(str(options['percentage'])),
                    description=options.get('description', ''),
                    effective_from=self._parse_date(options.get('effective_from')) or date.today(),
                    effective_to=self._parse_date(options.get('effective_to')) if options.get('effective_to') else None
                )
                
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Successfully created tax rate: {tax_rate.name} ({tax_rate.percentage}%)'
                    )
                )
                
        except Exception as e:
            raise CommandError(f'Failed to create tax rate: {str(e)}')

    def update_tax_rate(self, options):
        """Update an existing tax rate"""
        if not options.get('id'):
            raise CommandError('Tax rate ID is required for updates')
        
        try:
            tax_rate = TaxRate.objects.get(id=options['id'])
        except TaxRate.DoesNotExist:
            raise CommandError(f'Tax rate with ID {options["id"]} not found')
        
        try:
            with transaction.atomic():
                if options.get('name'):
                    tax_rate.name = options['name']
                if options.get('tax_type'):
                    tax_rate.tax_type = options['tax_type']
                if options.get('percentage'):
                    tax_rate.percentage = Decimal(str(options['percentage']))
                if options.get('description') is not None:
                    tax_rate.description = options['description']
                if options.get('effective_from'):
                    tax_rate.effective_from = self._parse_date(options['effective_from'])
                if options.get('effective_to'):
                    tax_rate.effective_to = self._parse_date(options['effective_to'])
                
                tax_rate.save()
                
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Successfully updated tax rate: {tax_rate.name} ({tax_rate.percentage}%)'
                    )
                )
                
        except Exception as e:
            raise CommandError(f'Failed to update tax rate: {str(e)}')

    def delete_tax_rate(self, options):
        """Delete a tax rate"""
        if not options.get('id'):
            raise CommandError('Tax rate ID is required for deletion')
        
        try:
            tax_rate = TaxRate.objects.get(id=options['id'])
        except TaxRate.DoesNotExist:
            raise CommandError(f'Tax rate with ID {options["id"]} not found')
        
        try:
            name = tax_rate.name
            tax_rate.delete()
            self.stdout.write(
                self.style.SUCCESS(f'Successfully deleted tax rate: {name}')
            )
        except Exception as e:
            raise CommandError(f'Failed to delete tax rate: {str(e)}')

    def reset_tax_rates(self, options):
        """Reset tax rates to default values"""
        try:
            with transaction.atomic():
                # Delete all existing tax rates
                deleted_count = TaxRate.objects.all().delete()[0]
                self.stdout.write(f'Deleted {deleted_count} existing tax rates')
                
                # Create default tax rates
                self._create_default_tax_rates()
                
                self.stdout.write(
                    self.style.SUCCESS('Successfully reset tax rates to defaults')
                )
                
        except Exception as e:
            raise CommandError(f'Failed to reset tax rates: {str(e)}')

    def _create_default_tax_rates(self):
        """Create default tax rates for Pakistan"""
        default_rates = [
            {
                'name': 'Standard GST',
                'tax_type': 'GST',
                'percentage': Decimal('17.00'),
                'description': 'Standard General Sales Tax rate for most goods and services in Pakistan'
            },
            {
                'name': 'Reduced GST (Textiles)',
                'tax_type': 'GST',
                'percentage': Decimal('12.00'),
                'description': 'Reduced GST rate for textile and clothing items'
            },
            {
                'name': 'Zero GST (Essential Items)',
                'tax_type': 'GST',
                'percentage': Decimal('0.00'),
                'description': 'Zero GST rate for essential food items and medicines'
            },
            {
                'name': 'FED on Luxury Items',
                'tax_type': 'FED',
                'percentage': Decimal('5.00'),
                'description': 'Federal Excise Duty on luxury and non-essential items'
            },
            {
                'name': 'FED on Tobacco',
                'tax_type': 'FED',
                'percentage': Decimal('15.00'),
                'description': 'Federal Excise Duty on tobacco products'
            },
            {
                'name': 'WHT on Services',
                'tax_type': 'WHT',
                'percentage': Decimal('3.00'),
                'description': 'Withholding Tax on services provided'
            },
            {
                'name': 'WHT on Goods',
                'tax_type': 'WHT',
                'percentage': Decimal('2.00'),
                'description': 'Withholding Tax on goods supplied'
            },
            {
                'name': 'Additional Tax (Luxury)',
                'tax_type': 'ADDITIONAL',
                'percentage': Decimal('3.00'),
                'description': 'Additional tax on luxury items and high-value transactions'
            },
            {
                'name': 'Custom Tax Rate',
                'tax_type': 'CUSTOM',
                'percentage': Decimal('0.00'),
                'description': 'Custom tax rate for special circumstances (to be configured per sale)'
            }
        ]
        
        for rate_data in default_rates:
            TaxRate.objects.create(
                effective_from=date.today(),
                is_active=True,
                **rate_data
            )

    def _parse_date(self, date_string):
        """Parse date string in YYYY-MM-DD format"""
        if not date_string:
            return None
        
        try:
            return date.fromisoformat(date_string)
        except ValueError:
            raise CommandError(f'Invalid date format: {date_string}. Use YYYY-MM-DD format.')
