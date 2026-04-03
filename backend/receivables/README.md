# Receivables Module

## Overview
The Receivables module manages money lent to debtors, tracking loans, payments, and outstanding balances. It provides comprehensive functionality for managing financial receivables with support for payment tracking, overdue management, and integration with sales.

## Features

### Core Functionality
- **Receivable Management**: Create, read, update, and soft delete receivables
- **Payment Tracking**: Record partial and full payments with automatic balance calculation
- **Overdue Management**: Track overdue receivables with day counting
- **Status Tracking**: Monitor payment status (unpaid, partially paid, fully paid)
- **Soft Deletion**: Preserve data integrity with soft delete functionality

### Advanced Features
- **Search & Filtering**: Advanced search with multiple criteria
- **Date Range Filtering**: Filter by lending date and expected return date
- **Amount Range Filtering**: Filter by amount ranges
- **Status Filtering**: Filter by payment status and overdue status
- **Pagination**: Built-in pagination with configurable page sizes

### Business Intelligence
- **Summary Statistics**: Total outstanding amounts, counts by status
- **Overdue Tracking**: Identify and manage overdue receivables
- **Payment History**: Track all payment transactions
- **Reporting Ready**: Structured data for analytics and reporting

## Model Structure

### Receivable Model
```python
class Receivable(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4)
    debtor_name = models.CharField(max_length=200)
    debtor_phone = models.CharField(max_length=20)
    amount_given = models.DecimalField(max_digits=15, decimal_places=2)
    reason_or_item = models.TextField()
    date_lent = models.DateField(default=timezone.now)
    expected_return_date = models.DateField(null=True, blank=True)
    amount_returned = models.DecimalField(max_digits=15, decimal_places=2, default=0.00)
    balance_remaining = models.DecimalField(max_digits=15, decimal_places=2, default=0.00)
    notes = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL)
    related_sale = models.ForeignKey(Sales, on_delete=models.SET_NULL, null=True, blank=True)
```

### Key Fields
- **debtor_name**: Name of the person who owes money
- **debtor_phone**: Contact phone number
- **amount_given**: Total amount lent
- **reason_or_item**: Purpose or description of the loan
- **date_lent**: When the money was lent
- **expected_return_date**: Expected repayment date
- **amount_returned**: Amount already paid back
- **balance_remaining**: Automatically calculated remaining balance
- **related_sale**: Optional link to sales if receivable is from a sale transaction

## API Endpoints

### Basic CRUD Operations
- `GET /api/v1/receivables/` - List all receivables with pagination
- `POST /api/v1/receivables/create/` - Create new receivable
- `GET /api/v1/receivables/{id}/` - Get specific receivable
- `PUT/PATCH /api/v1/receivables/{id}/update/` - Update receivable
- `DELETE /api/v1/receivables/{id}/delete/` - Soft delete receivable

### Special Operations
- `POST /api/v1/receivables/{id}/record-payment/` - Record a payment
- `POST /api/v1/receivables/{id}/restore/` - Restore deleted receivable

### Business Intelligence
- `GET /api/v1/receivables/summary/` - Get summary statistics
- `POST /api/v1/receivables/search/` - Advanced search with filters

## Usage Examples

### Creating a Receivable
```python
# Create a new receivable
receivable_data = {
    'debtor_name': 'John Doe',
    'debtor_phone': '+92-300-1234567',
    'amount_given': 10000.00,
    'reason_or_item': 'Business loan for shop renovation',
    'expected_return_date': '2024-02-01',
    'notes': 'Monthly installments of 5000 PKR'
}

response = requests.post('/api/v1/receivables/create/', json=receivable_data)
```

### Recording a Payment
```python
# Record a payment
payment_data = {
    'payment_amount': 3000.00,
    'payment_notes': 'First installment received'
}

response = requests.post(f'/api/v1/receivables/{receivable_id}/record-payment/', json=payment_data)
```

### Searching Receivables
```python
# Advanced search
search_data = {
    'search': 'John',
    'status': 'overdue',
    'date_from': '2024-01-01',
    'date_to': '2024-01-31',
    'amount_min': 5000,
    'amount_max': 15000
}

response = requests.post('/api/v1/receivables/search/', json=search_data)
```

## QuerySet Methods

### Built-in Filters
- `.active()` - Get only active receivables
- `.overdue()` - Get overdue receivables
- `.due_today()` - Get receivables due today
- `.due_this_week()` - Get receivables due this week
- `.fully_paid()` - Get fully paid receivables
- `.partially_paid()` - Get partially paid receivables
- `.unpaid()` - Get completely unpaid receivables

### Search Methods
- `.search(query)` - Search by debtor name, phone, reason, or notes
- `.by_debtor(name)` - Filter by debtor name
- `.by_date_range(start, end)` - Filter by lending date range
- `.amount_range(min, max)` - Filter by amount range

## Business Logic

### Automatic Calculations
- **Balance Calculation**: Automatically calculates `balance_remaining` on save
- **Payment Validation**: Prevents overpayment and validates payment amounts
- **Date Validation**: Ensures expected return date is not before lending date

### Status Methods
- `is_overdue()` - Check if receivable is overdue
- `days_overdue()` - Calculate days overdue
- `is_fully_paid()` - Check if fully paid
- `is_partially_paid()` - Check if partially paid

### Payment Management
- `record_payment(amount)` - Record a payment and update balance
- Automatic balance recalculation
- Payment history tracking in notes

## Integration Points

### Sales Integration
- Optional relationship to sales transactions
- Links receivables to customer sales with remaining amounts
- Enables tracking of customer credit situations

### User Management
- Tracks who created each receivable
- User-based permissions and access control
- Audit trail for all operations

## Security & Permissions

### Authentication
- All endpoints require authentication
- JWT token-based access control

### Authorization
- Users can manage receivables they created
- Superusers have full access
- Granular permissions for different operations

### Data Protection
- Soft deletion preserves data integrity
- Audit trail for all changes
- User-based access restrictions

## Admin Interface

### Django Admin Features
- Comprehensive list view with status indicators
- Color-coded status display
- Advanced filtering and search
- Bulk actions (mark as paid, mark as overdue)
- CSV export functionality
- Permission-based field access

### Admin Actions
- Mark selected receivables as fully paid
- Mark selected receivables as overdue
- Export selected receivables to CSV

## Testing

### Test Coverage
- Model validation tests
- QuerySet method tests
- Business logic tests
- API endpoint tests
- Permission tests

### Running Tests
```bash
# Run all tests
python manage.py test receivables

# Run specific test class
python manage.py test receivables.tests.ReceivableModelTest

# Run with coverage
coverage run --source='.' manage.py test receivables
```

## Migration

### Database Setup
```bash
# Create and apply migrations
python manage.py makemigrations receivables
python manage.py migrate

# Check migration status
python manage.py showmigrations receivables
```

### Dependencies
- Requires `sales` app for optional sales integration
- Uses custom User model from `posapi`
- PostgreSQL database recommended for production

## Performance Considerations

### Database Optimization
- Strategic indexes on frequently queried fields
- Efficient QuerySet methods for common operations
- Pagination to handle large datasets

### Caching Strategy
- Prepared for Redis integration
- Query result caching opportunities
- Summary statistics caching

## Future Enhancements

### Planned Features
- Email/SMS notifications for overdue receivables
- Automated reminder system
- Interest calculation for long-term loans
- Payment schedule management
- Advanced reporting and analytics
- Mobile app integration

### Integration Opportunities
- Accounting software integration
- Banking system integration
- Customer relationship management (CRM)
- Financial reporting tools

## Support & Maintenance

### Documentation
- Comprehensive API documentation
- Code comments and docstrings
- Usage examples and best practices

### Monitoring
- Signal-based logging
- Performance monitoring
- Error tracking and reporting

### Updates
- Regular security updates
- Feature enhancements
- Bug fixes and improvements

## Contributing

### Development Guidelines
- Follow existing code patterns
- Maintain test coverage
- Update documentation
- Follow Django best practices

### Code Standards
- PEP 8 compliance
- Comprehensive error handling
- Input validation and sanitization
- Security-first approach
