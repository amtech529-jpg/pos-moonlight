# Generated migration for making CNIC field nullable

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('vendors', '0001_initial'),
    ]

    operations = [
        migrations.AlterField(
            model_name='vendor',
            name='cnic',
            field=models.CharField(
                blank=True,
                help_text='Pakistani CNIC in format: 12345-1234567-1 (optional)',
                max_length=15,
                null=True,
                unique=True,
                validators=[
                    'vendors.validators.validate_pakistani_cnic'
                ]
            ),
        ),
    ]
