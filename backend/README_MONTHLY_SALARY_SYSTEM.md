# Monthly Salary Tracking System for Labors

## Overview
This system implements proper monthly salary tracking for labors, ensuring that advance payments are deducted from the current month's salary balance and reset monthly.

## Key Changes

### 1. Labor Model Updates
- **`remaining_monthly_salary`**: Tracks remaining salary for the current month
- **`current_month`**: Tracks the month number (1-12) for salary resets
- **`current_year`**: Tracks the year for salary resets

### 2. Automatic Monthly Reset
- **Automatic Reset**: When a labor is saved, the system checks if it's a new month
- **Salary Restoration**: If it's a new month, `remaining_monthly_salary` is reset to full `salary`
- **Monthly Tracking**: `current_month` and `current_year` are updated to track when resets occur

### 3. Advance Payment Integration
- **Deduction**: Each advance payment deducts from `remaining_monthly_salary`
- **Validation**: Prevents advances exceeding the remaining monthly balance
- **Updates**: Handles both new payments and payment modifications

## How It Works

### Monthly Reset Logic
```python
def _reset_monthly_salary_if_needed(self):
    today = date.today()
    current_month = today.month
    current_year = today.year
    
    # If it's a new month, reset the remaining salary
    if self.current_month != current_month or self.current_year != current_year:
        self.remaining_monthly_salary = self.salary
        self.current_month = current_month
        self.current_year = current_year
```

### Advance Payment Deduction
```python
def deduct_advance_payment(self, amount):
    if amount > self.remaining_monthly_salary:
        raise ValidationError(f"Advance amount {amount} exceeds remaining monthly salary {self.remaining_monthly_salary}")
    
    self.remaining_monthly_salary -= amount
    return self.remaining_monthly_salary
```

## Database Migration

### Migration 0002: Add Monthly Salary Fields
- Adds `remaining_monthly_salary`, `current_month`, `current_year` fields
- Sets default values for existing records

### Migration 0003: Initialize Existing Data
- Sets existing labors' `remaining_monthly_salary` to their full salary
- Initializes `current_month` and `current_year` to current date

## Management Commands

### Reset Monthly Salaries
```bash
python manage.py reset_monthly_salaries
```

**Options:**
- `--force`: Force reset even if not a new month

**Use Cases:**
- Monthly cron job to reset all labors
- Manual reset when needed
- Testing and development

## Frontend Integration

### Labor Model
- Updated to use `remainingMonthlySalary` instead of `remainingAdvanceBalance`
- Shows real-time remaining salary for current month

### Validation
- Frontend validates against `remainingMonthlySalary`
- Prevents advances exceeding monthly balance
- Shows clear salary breakdown in UI

## Benefits

1. **Accurate Tracking**: Real-time remaining salary for each month
2. **Monthly Reset**: Automatic salary restoration each month
3. **Prevent Overdrafts**: Cannot advance more than monthly salary
4. **Clear Visibility**: Users can see exactly how much salary remains
5. **Audit Trail**: Complete history of salary deductions

## Example Workflow

1. **January 1st**: Labor starts with `remaining_monthly_salary = 50000` (full salary)
2. **January 15th**: Advance payment of 15000 → `remaining_monthly_salary = 35000`
3. **January 20th**: Another advance of 10000 → `remaining_monthly_salary = 25000`
4. **February 1st**: Automatic reset → `remaining_monthly_salary = 50000` (new month)
5. **February 10th**: Advance payment of 20000 → `remaining_monthly_salary = 30000`

## Cron Job Setup

Add to your crontab to run monthly:
```bash
# Reset monthly salaries on the 1st of each month at 00:01
1 0 1 * * cd /path/to/your/project && python manage.py reset_monthly_salaries
```

## Testing

### Test Cases
1. **New Month Reset**: Verify salary resets when month changes
2. **Advance Deduction**: Verify salary decreases with each advance
3. **Validation**: Verify cannot exceed remaining monthly salary
4. **Update Handling**: Verify amount changes properly update remaining salary
5. **Refund Handling**: Verify decreasing amounts properly refund salary

### Test Commands
```bash
# Test monthly reset
python manage.py reset_monthly_salaries --force

# Check specific labor
python manage.py shell
>>> from labors.models import Labor
>>> labor = Labor.objects.first()
>>> print(f"Salary: {labor.salary}, Remaining: {labor.remaining_monthly_salary}")
```












