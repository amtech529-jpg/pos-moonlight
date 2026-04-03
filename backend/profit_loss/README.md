# Profit and Loss Management System

## Overview

The Profit and Loss (P&L) system is a comprehensive financial analysis tool that calculates business profitability by analyzing income from sales and expenses from various sources. It provides detailed insights into business performance across different time periods.

## Formula

**Gross Profit = Total Sales Income − Cost of Goods Sold (COGS)**

**Net Profit = Gross Profit − (Labor Payments + Vendor Payments + Other Expenses + Zakat)**

**Gross Profit Margin = (Gross Profit / Total Sales Income) × 100**

**Net Profit Margin = (Net Profit / Total Sales Income) × 100**

## Features

### 1. Automated Calculations
- **Sales Income**: Automatically calculated from `sales.grand_total`
- **Cost of Goods Sold (COGS)**: Automatically calculated from `sale_items.product.cost_price × quantity`
- **Labor Payments**: Sum of all payments to labor in the period
- **Vendor Payments**: Sum of all payments to vendors in the period
- **Other Expenses**: Sum of all business expenses
- **Zakat**: Sum of all zakat payments

### 2. Period Analysis
- **Daily**: Day-by-day analysis
- **Weekly**: Week-by-week analysis
- **Monthly**: Month-by-month analysis
- **Quarterly**: Quarter-by-quarter analysis
- **Yearly**: Year-by-year analysis
- **Custom**: User-defined date ranges

### 3. Detailed Breakdowns
- **Expense Categorization**: Labor, vendor, other expenses, and zakat
- **Source Record Tracking**: Count and details of source records used in calculations
- **Calculation History**: Complete audit trail of all calculations performed

### 4. Product Profitability Analysis
- **Per-Product Analysis**: Individual product profit margins
- **Cost Analysis**: Production cost vs. selling price analysis
- **Performance Ranking**: Products ranked by profitability

## API Endpoints

### 1. Calculate Profit and Loss
```
POST /api/v1/profit-loss/calculate/
```
**Request Body:**
```json
{
    "start_date": "2024-01-01",
    "end_date": "2024-01-31",
    "period_type": "MONTHLY",
    "include_calculations": true,
    "calculation_notes": "January 2024 analysis"
}
```

**Response:**
```json
{
    "message": "Profit and loss calculation completed successfully",
    "record": {
        "id": "uuid",
        "period_type": "MONTHLY",
        "start_date": "2024-01-01",
        "end_date": "2024-01-31",
        "total_sales_income": "150000.00",
        "total_cost_of_goods_sold": "90000.00",
        "gross_profit": "60000.00",
        "gross_profit_margin_percentage": "40.00",
        "total_labor_payments": "25000.00",
        "total_vendor_payments": "30000.00",
        "total_expenses": "15000.00",
        "total_zakat": "5000.00",
        "total_expenses_calculated": "75000.00",
        "net_profit": "-15000.00",
        "profit_margin_percentage": "-10.00",
        "total_products_sold": 150,
        "average_order_value": "1000.00",
        "is_profitable": false,
        "expense_breakdown": {
            "cost_of_goods_sold": 90000.0,
            "labor_payments": 25000.0,
            "vendor_payments": 30000.0,
            "other_expenses": 15000.0,
            "zakat": 5000.0,
            "total": 75000.0
        }
    }
}
```

### 2. Get Profit and Loss Records
```
GET /api/v1/profit-loss/records/
GET /api/v1/profit-loss/records/?period_type=MONTHLY
GET /api/v1/profit-loss/records/?start_date=2024-01-01&end_date=2024-01-31
GET /api/v1/profit-loss/records/?is_profitable=true
```

### 3. Get Specific Record
```
GET /api/v1/profit-loss/records/{id}/
```

### 4. Get Summary for Different Periods
```
GET /api/v1/profit-loss/summary/?period_type=CURRENT_MONTH
GET /api/v1/profit-loss/summary/?period_type=CURRENT_YEAR
GET /api/v1/profit-loss/summary/?period_type=LAST_30_DAYS
GET /api/v1/profit-loss/summary/?period_type=LAST_90_DAYS
```

### 5. Product Profitability Analysis
```
GET /api/v1/profit-loss/product-profitability/
GET /api/v1/profit-loss/product-profitability/?start_date=2024-01-01&end_date=2024-01-31
```

### 6. Dashboard Data
```
GET /api/v1/profit-loss/dashboard/
```

## Models

### 1. ProfitLossRecord
Stores calculated profit and loss data for specific periods.

**Key Fields:**
- `period_type`: Type of period (daily, weekly, monthly, etc.)
- `start_date` / `end_date`: Period boundaries
- `total_sales_income`: Total income from sales
- `total_labor_payments`: Total payments to labor
- `total_vendor_payments`: Total payments to vendors
- `total_expenses`: Total other expenses
- `total_zakat`: Total zakat payments
- `net_profit`: Calculated net profit
- `profit_margin_percentage`: Profit margin as percentage

### 2. ProfitLossCalculation
Stores detailed breakdown of each calculation component.

**Key Fields:**
- `profit_loss_record`: Reference to the main record
- `calculation_type`: Type of calculation (sales, labor, vendor, etc.)
- `source_model`: Source model for the calculation
- `source_count`: Number of source records
- `source_total`: Total amount from source records
- `calculation_details`: JSON field with detailed breakdown

## Usage Examples

### 1. Calculate Monthly Profit and Loss
```python
from datetime import date
from profit_loss.views import ProfitLossCalculationView

# Calculate for January 2024
start_date = date(2024, 1, 1)
end_date = date(2024, 1, 31)

view = ProfitLossCalculationView()
profit_loss_data = view._calculate_profit_loss(start_date, end_date)

print(f"Sales Income: PKR {profit_loss_data['total_sales_income']:,.2f}")
print(f"Total Expenses: PKR {profit_loss_data['total_labor_payments'] + profit_loss_data['total_vendor_payments'] + profit_loss_data['total_expenses'] + profit_loss_data['total_zakat']:,.2f}")
```

### 2. Get Current Month Summary
```python
from profit_loss.views import ProfitLossSummaryView

view = ProfitLossSummaryView()
summary = view._get_current_month_summary()

print(f"Current Month Profit: PKR {summary['net_profit']:,.2f}")
print(f"Profit Margin: {summary['profit_margin_percentage']:.2f}%")
```

### 3. Analyze Product Profitability
```python
from profit_loss.views import ProductProfitabilityView

view = ProductProfitabilityView()
product_data = view._get_product_profitability(start_date, end_date)

for product in product_data:
    print(f"{product['product_name']}: {product['formatted_profit_margin']}")
```

## Admin Interface

The system includes a comprehensive admin interface with:

- **ProfitLossRecordAdmin**: View and manage profit and loss records
- **ProfitLossCalculationAdmin**: View detailed calculation breakdowns
- **Color-coded displays**: Green for profits, red for losses
- **Formatted currency displays**: PKR format with proper formatting
- **Expense breakdowns**: Detailed view of all expense categories
- **Summary statistics**: Comprehensive overview of each period

## Business Logic

### 1. Sales Income Calculation
- Sources from `sales.grand_total` field
- Includes all confirmed and paid sales
- Excludes cancelled or returned sales

### 2. Expense Calculations
- **Labor Payments**: All payments with `payer_type='LABOR'`
- **Vendor Payments**: All payments with `payer_type='VENDOR'`
- **Other Expenses**: All records from `expenses` table
- **Zakat**: All records from `zakats` table

### 3. Profit Calculation
- **Gross Profit**: Sales Income - Total Expenses
- **Profit Margin**: (Net Profit / Sales Income) × 100
- **Profitability Status**: Boolean based on net profit > 0

### 4. Product Profitability
- **Revenue**: Total sales from `sale_items.line_total`
- **Cost**: Product cost price × quantity sold
- **Gross Profit**: Revenue - Cost
- **Profit Margin**: (Gross Profit / Revenue) × 100

## Data Integrity

- **Automatic Calculations**: All derived fields are calculated automatically
- **Validation**: Comprehensive validation of all input data
- **Audit Trail**: Complete history of all calculations performed
- **Soft Deletion**: Records are marked inactive rather than deleted
- **Unique Constraints**: Prevents duplicate calculations for the same period

## Performance Considerations

- **Database Indexes**: Optimized queries with proper indexing
- **Aggregation Queries**: Efficient use of Django ORM aggregations
- **Bulk Operations**: Bulk creation of calculation records
- **Query Optimization**: Prefetch related data to minimize database hits

## Security

- **Authentication Required**: All endpoints require user authentication
- **Permission Checks**: Admin operations restricted to superusers
- **Data Validation**: Comprehensive input validation and sanitization
- **Audit Logging**: Track all changes and calculations

## Future Enhancements

1. **Real-time Updates**: WebSocket integration for live P&L updates
2. **Advanced Analytics**: Trend analysis and forecasting
3. **Export Functionality**: PDF reports and Excel exports
4. **Email Notifications**: Automated P&L reports via email
5. **Mobile App Integration**: Native mobile app support
6. **Multi-currency Support**: Support for different currencies
7. **Tax Calculations**: Integration with tax systems
8. **Budget Comparison**: Compare actual vs. budgeted performance

## Support

For technical support or questions about the Profit and Loss system, please contact the development team or refer to the system documentation.
