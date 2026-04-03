# Flexible Tax System for Sales

## Overview

The sales module now includes a comprehensive and flexible tax system that allows users to configure multiple tax types and rates according to Pakistani tax regulations. This system replaces the previous fixed GST-only approach with a dynamic, configurable tax framework.

## Features

### 1. Multiple Tax Types
- **GST (General Sales Tax)**: Standard sales tax with configurable rates
- **FED (Federal Excise Duty)**: Additional excise taxes on specific goods
- **WHT (Withholding Tax)**: Tax deducted at source
- **Additional Tax**: Special taxes for luxury items or specific industries
- **Custom Tax**: User-defined tax rates for special circumstances

### 2. Flexible Tax Configuration
- **Per-Sale Configuration**: Each sale can have different tax combinations
- **Dynamic Rate Management**: Tax rates can be updated over time with effective dates
- **Multiple Tax Application**: Apply multiple tax types to a single sale
- **Historical Accuracy**: Tax rates are captured at the time of sale

### 3. Pakistani Tax Compliance
- **Standard GST Rates**: 17% (default), 12% (textiles), 0% (essential items)
- **FED Rates**: 5% (luxury items), 15% (tobacco), etc.
- **WHT Rates**: 3% (services), 2% (goods)
- **Additional Taxes**: 3% (luxury items)

## How It Works

### Tax Configuration Structure

Each sale stores tax information in a JSON field called `tax_configuration`:

```json
{
  "GST": {
    "name": "Standard GST",
    "percentage": 17.00,
    "amount": 170.00,
    "description": "Standard GST rate for Pakistan"
  },
  "FED": {
    "name": "FED on Luxury Items",
    "percentage": 5.00,
    "amount": 50.00,
    "description": "Federal Excise Duty on luxury items"
  }
}
```

### Tax Calculation Process

1. **Taxable Amount**: `subtotal - overall_discount`
2. **Individual Tax Calculation**: `taxable_amount × tax_percentage ÷ 100`
3. **Total Tax**: Sum of all individual tax amounts
4. **Grand Total**: `subtotal - overall_discount + total_tax`

## Usage Examples

### 1. Creating a Sale with Standard GST

```python
from sales.models import Sales
from customers.models import Customer

# Get customer
customer = Customer.objects.get(id=customer_id)

# Create sale with default tax configuration
sale = Sales.objects.create(
    customer=customer,
    subtotal=Decimal('1000.00'),
    overall_discount=Decimal('50.00'),
    # tax_configuration will be auto-populated with default GST
)
```

### 2. Creating a Sale with Multiple Taxes

```python
# Custom tax configuration
tax_config = {
    "GST": {
        "name": "Standard GST",
        "percentage": 17.00,
        "description": "Standard GST rate"
    },
    "FED": {
        "name": "FED on Luxury Items",
        "percentage": 5.00,
        "description": "Luxury item excise duty"
    },
    "WHT": {
        "name": "WHT on Services",
        "percentage": 3.00,
        "description": "Withholding tax on services"
    }
}

sale = Sales.objects.create(
    customer=customer,
    subtotal=Decimal('1000.00'),
    overall_discount=Decimal('50.00'),
    tax_configuration=tax_config
)
```

### 3. Managing Tax Rates

```python
from sales.models import TaxRate

# Create a new tax rate
TaxRate.objects.create(
    name="Special Industry Tax",
    tax_type="ADDITIONAL",
    percentage=2.50,
    description="Special tax for textile industry",
    effective_from=date(2024, 1, 1)
)

# Get active tax rates
active_rates = TaxRate.objects.filter(is_active=True, is_currently_effective=True)

# Get rates by type
gst_rates = TaxRate.objects.filter(tax_type='GST', is_active=True)
```

## Management Commands

### List All Tax Rates
```bash
python manage.py setup_tax_rates --action=list
```

### List Tax Rates by Type
```bash
python manage.py setup_tax_rates --action=list --tax-type=GST
```

### Create New Tax Rate
```bash
python manage.py setup_tax_rates --action=create \
    --name="Reduced GST for Textiles" \
    --tax-type=GST \
    --percentage=12.00 \
    --description="Reduced GST rate for textile products" \
    --effective-from=2024-01-01
```

### Update Tax Rate
```bash
python manage.py setup_tax_rates --action=update \
    --id=<tax_rate_id> \
    --percentage=18.00
```

### Reset to Default Tax Rates
```bash
python manage.py setup_tax_rates --action=reset
```

## API Usage

### Creating Sales with Tax Configuration

```json
POST /api/v1/sales/create/
{
    "customer": "customer_uuid",
    "overall_discount": "50.00",
    "tax_configuration": {
        "GST": {
            "name": "Standard GST",
            "percentage": 17.00
        },
        "FED": {
            "name": "FED on Luxury Items",
            "percentage": 5.00
        }
    },
    "payment_method": "CASH",
    "notes": "Luxury item sale with multiple taxes"
}
```

### Updating Tax Configuration

```json
PATCH /api/v1/sales/{sale_id}/update/
{
    "tax_configuration": {
        "GST": {
            "name": "Reduced GST",
            "percentage": 12.00
        }
    }
}
```

## Admin Interface

### TaxRate Admin
- **List View**: Shows all tax rates with status and effectiveness
- **Create/Edit**: Full CRUD operations for tax rates
- **Validation**: Ensures proper date ranges and percentage values
- **Status Management**: Activate/deactivate tax rates

### Sales Admin
- **Tax Configuration**: JSON editor for tax configuration
- **Tax Breakdown**: Visual display of applied taxes
- **Tax Summary**: Quick overview of tax types and amounts
- **Validation**: Ensures tax calculations are accurate

## Migration from Old System

### Automatic Migration
The system automatically handles migration from the old GST-only system:

1. **Existing Sales**: Keep working with legacy `gst_percentage` field
2. **New Sales**: Use new `tax_configuration` system
3. **Backward Compatibility**: Legacy field is auto-populated from tax configuration

### Manual Migration
To migrate existing sales to use the new tax system:

```python
from sales.models import Sales

# Update existing sales to use new tax configuration
for sale in Sales.objects.all():
    if not sale.tax_configuration:
        # Create default GST configuration
        sale.tax_configuration = {
            "GST": {
                "name": "Standard GST",
                "percentage": float(sale.gst_percentage),
                "amount": float(sale.tax_amount),
                "description": "Migrated from legacy GST system"
            }
        }
        sale.save(update_fields=['tax_configuration'])
```

## Best Practices

### 1. Tax Rate Management
- **Use Descriptive Names**: Clear names help identify tax purposes
- **Set Effective Dates**: Use date ranges for temporary tax rates
- **Document Descriptions**: Explain when and why tax rates apply
- **Regular Review**: Update tax rates according to government changes

### 2. Sale Creation
- **Validate Tax Configuration**: Ensure percentages are within valid ranges
- **Use Default Rates**: Let the system auto-populate common tax combinations
- **Document Special Cases**: Use custom tax rates for unique situations
- **Test Calculations**: Verify tax calculations before finalizing sales

### 3. Compliance
- **Keep Records**: Maintain tax rate history for audit purposes
- **Regular Updates**: Stay current with government tax rate changes
- **Documentation**: Keep detailed records of tax applications
- **Validation**: Ensure tax calculations meet regulatory requirements

## Troubleshooting

### Common Issues

1. **Tax Calculation Mismatch**
   - Check if tax configuration is properly formatted
   - Verify tax percentages are valid numbers
   - Ensure taxable amount calculation is correct

2. **Missing Tax Configuration**
   - System will auto-populate with default GST
   - Check if TaxRate records exist and are active
   - Verify effective dates are current

3. **Invalid Tax Rates**
   - Ensure percentages are between 0 and 100
   - Check if tax rates are currently effective
   - Validate date ranges for tax rate effectiveness

### Debug Commands

```bash
# Check tax rate status
python manage.py setup_tax_rates --action=list

# Verify tax calculations
python manage.py shell
>>> from sales.models import Sales
>>> sale = Sales.objects.first()
>>> sale.calculate_taxes()
>>> print(sale.tax_configuration)
```

## Future Enhancements

### Planned Features
- **Tax Rate Templates**: Pre-configured tax combinations for common scenarios
- **Automatic Updates**: Integration with government tax rate APIs
- **Advanced Validation**: Business rule validation for tax combinations
- **Reporting**: Enhanced tax reporting and analytics
- **Audit Trail**: Complete history of tax rate changes

### Integration Points
- **Accounting Systems**: Export tax data to accounting software
- **Government Portals**: Direct integration with FBR systems
- **Compliance Tools**: Automated compliance checking
- **Analytics**: Tax impact analysis and reporting

## Support

For questions or issues with the tax system:

1. **Check Documentation**: Review this README and model documentation
2. **Use Management Commands**: Leverage built-in tax management tools
3. **Review Admin Interface**: Use Django admin for visual management
4. **Check Logs**: Review application logs for error details
5. **Validate Data**: Use model validation methods to check data integrity

## Conclusion

The new flexible tax system provides a robust, compliant, and user-friendly way to manage multiple tax types and rates in your sales system. It maintains backward compatibility while offering powerful new capabilities for complex tax scenarios.

By following the best practices outlined in this document, you can effectively manage your tax requirements and ensure compliance with Pakistani tax regulations.
