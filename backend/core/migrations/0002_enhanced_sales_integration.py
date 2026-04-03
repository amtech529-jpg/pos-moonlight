# Generated manually for enhanced sales integration

import django.db.models.deletion
import django.utils.timezone
from decimal import Decimal
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('sales', '0001_initial'),
        ('sale_items', '0001_initial'),
        ('customers', '0001_initial'),
        ('products', '0001_initial'),
        ('orders', '0001_initial'),
        ('order_items', '0001_initial'),
    ]

    operations = [
        # Add conversion tracking fields to Order model
        migrations.AddField(
            model_name='order',
            name='conversion_status',
            field=models.CharField(
                choices=[
                    ('NOT_CONVERTED', 'Not Converted'),
                    ('PARTIALLY_CONVERTED', 'Partially Converted'),
                    ('FULLY_CONVERTED', 'Fully Converted'),
                ],
                default='NOT_CONVERTED',
                help_text='Status of order conversion to sales',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='order',
            name='converted_sales_amount',
            field=models.DecimalField(
                decimal_places=2,
                default=Decimal('0.00'),
                help_text='Total amount converted to sales',
                max_digits=15,
            ),
        ),
        migrations.AddField(
            model_name='order',
            name='conversion_date',
            field=models.DateTimeField(
                blank=True,
                help_text='Date when order was first converted to sale',
                null=True,
            ),
        ),
        
        # Add indexes for better performance
        migrations.AddIndex(
            model_name='order',
            index=models.Index(fields=['conversion_status'], name='order_conversion_status_idx'),
        ),
        migrations.AddIndex(
            model_name='order',
            index=models.Index(fields=['conversion_date'], name='order_conversion_date_idx'),
        ),
    ]
