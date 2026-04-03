# Payments Module

This module manages various types of payments in the system including labor payments, vendor payments, order payments, and sale payments.

## Features

- **Multi-entity Support**: Payments can be made to/for labors, vendors, orders, and sales
- **Flexible Payment Methods**: Cash, bank transfer, mobile payment, check, card, etc.
- **Bonus & Deduction Tracking**: Support for additional payments and deductions
- **Receipt Management**: Image upload for payment receipts
- **Payment Periods**: Track payments by month and mark final payments
- **Comprehensive Filtering**: Search and filter by various criteria
- **Statistics & Reporting**: Built-in analytics and reporting features

## Models

### Payment
The main model that tracks all payment transactions with the following key fields:

- **Entity Relationships**: `labor`, `vendor`, `order`, `sale`
- **Financial Fields**: `amount_paid`, `bonus`, `deduction`, `net_amount`
- **Payment Details**: `payment_month`, `is_final_payment`, `payment_method`
- **Metadata**: `date`, `time`, `receipt_image_path`, `created_by`

## API Endpoints

### Function-based Views
- `GET /api/v1/payments/` - List payments with filtering and pagination
- `POST /api/v1/payments/create/` - Create new payment
- `GET /api/v1/payments/{id}/` - Get payment details
- `PUT/PATCH /api/v1/payments/{id}/update/` - Update payment
- `DELETE /api/v1/payments/{id}/delete/` - Hard delete payment
- `POST /api/v1/payments/{id}/soft-delete/` - Soft delete payment
- `POST /api/v1/payments/{id}/restore/` - Restore soft-deleted payment
- `GET /api/v1/payments/statistics/` - Get payment statistics
- `POST /api/v1/payments/{id}/mark-final/` - Mark payment as final

### Class-based Views
- `PaymentListCreateAPIView` - List and create payments
- `PaymentRetrieveUpdateDestroyAPIView` - Retrieve, update, and delete payments

## Usage Examples

### Creating a Labor Payment
```python
payment = Payment.objects.create(
    labor=labor_instance,
    amount_paid=Decimal('15000.00'),
    bonus=Decimal('1000.00'),
    deduction=Decimal('500.00'),
    payment_month=date.today(),
    is_final_payment=True,
    payment_method='BANK_TRANSFER',
    description='Monthly salary payment',
    date=date.today(),
    time=timezone.now().time(),
    created_by=user
)
```

### Filtering Payments
```python
# Get payments for specific labor
payments = Payment.objects.by_labor(labor_id)

# Get payments by date range
payments = Payment.objects.by_date_range(start_date, end_date)

# Get final payments
final_payments = Payment.objects.final_payments()

# Search payments
search_results = Payment.objects.search('labor name')
```

### Getting Statistics
```python
stats = Payment.get_statistics()
print(f"Total payments: {stats['total_payments']}")
print(f"Total amount: {stats['total_amount']}")
print(f"Net amount: {stats['net_amount']}")
```

## Admin Interface

The module includes a comprehensive Django admin interface with:
- List display with key payment information
- Advanced filtering and search capabilities
- Bulk actions for payment management
- Organized fieldsets for better data entry
- Performance optimizations with select_related

## Signals

The module includes Django signals for:
- Logging payment operations
- Updating related entity information
- Triggering statistics updates
- Maintaining data consistency

## Testing

Comprehensive test coverage including:
- Model validation and methods
- Serializer functionality
- View behavior and responses
- API endpoint testing
- Edge cases and error handling

## Dependencies

- Django 4.x
- Django REST Framework
- Pillow (for image handling)
- PostgreSQL (recommended database)

## Configuration

The module is automatically configured when added to `INSTALLED_APPS` in Django settings. No additional configuration is required.

## Security

- All endpoints require authentication
- Input validation and sanitization
- File upload security for receipts
- Proper permission handling
- Audit trail with created_by tracking
