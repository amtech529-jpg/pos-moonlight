# Urdu Localization Conversion Plan

## ✅ Completed
1. Fixed missing localization keys: `premiumCustomer`, `orderItems`, `page`
2. Added common UI elements: `close`, `notSpecified`, `allStatuses`, `generated`, `sent`, `viewed`, `issued`, `overdue`
3. Added receipt management keys: `createReceipt`, `updateReceipt`, `receiptCreatedSuccessfully`, `receiptUpdatedSuccessfully`, `receiptDeletedSuccessfully`, `noReceiptsFound`
4. Added order creation keys: `createOrder`, `creatingOrder`
5. Added form labels: `selectSale`, `chooseSaleToCreateReceipt`, `dueDate`, `pleaseSelectSale`, `additionalReceiptNotes`

## 🔄 Remaining Work

### Priority 1: Critical UI Elements

#### Sales & Receipt Management
- [ ] Replace hardcoded strings in `receipt_management_widget.dart`:
  - "All Statuses" → Use `allStatuses`
  - "Generated", "Sent", "Viewed" → Use `generated`, `sent`, `viewed`
  - "Clear Filters" → Use `clearFilters`
  - "No receipts found" → Use `noReceiptsFound`
  - "Close" → Use `close`
  - "Edit", "Delete" → Use `edit`, `delete`

- [ ] Replace hardcoded strings in `create_receipt_dialog.dart`:
  - "No sales available" → Use `noSalesAvailable`
  - "Select Sale *" → Use `selectSale`
  - "Choose a sale to create receipt for" → Use `chooseSaleToCreateReceipt`
  - "Payment Method" → Use `paymentMethod`
  - "Notes" → Use `notes`
  - "Additional receipt notes (optional)" → Use `additionalReceiptNotes`
  - "Cancel" → Use `cancel`
  - "Create Receipt" → Use `createReceipt`
  - "Receipt created successfully" → Use `receiptCreatedSuccessfully`

- [ ] Replace hardcoded strings in `edit_receipt_dialog.dart`:
  - "Generated", "Sent", "Viewed" → Use localization keys
  - "Update Receipt" → Use `updateReceipt`
  - "Receipt updated successfully" → Use `receiptUpdatedSuccessfully`

- [ ] Replace hardcoded strings in `edit_invoice_dialog.dart`:
  - "Draft", "Issued", "Sent", "Viewed", "Paid", "Overdue", "Cancelled" → Add and use localization keys
  - "Due Date" → Use `dueDate`

#### Invoice Management
- [ ] Replace hardcoded strings in `invoice_management_widget.dart`
- [ ] Replace hardcoded strings in `create_invoice_dialog.dart`

#### Order Management
- [ ] Replace hardcoded strings in `custom_order_dialog.dart`:
  - "Creating Order..." → Use `creatingOrder`
  - "Create Order" → Use `createOrder`
  - "Cancel" → Use `cancel`

### Priority 2: Forms & Dialogs

#### Principal Account
- [ ] Replace hardcoded strings in `add_principal_acc_dialog.dart`:
  - "Not specified" → Use `notSpecified`
  - "Add Entry" / "Add Ledger Entry" → Add localization key
  - "Amount" → Use `amount`
  - "Date" → Use `date`
  - "Notes" → Use `notes`
  - "Additional notes (optional)" → Add localization key

- [ ] Replace hardcoded strings in `edit_principal_acc_dialog.dart`:
  - "Edit Entry" / "Edit Principal Account Entry" → Add localization key
  - "Amount" → Use `amount`
  - "Not specified" → Use `notSpecified`
  - "Date" → Use `date`
  - "Notes" → Use `notes`
  - "Additional notes (optional)" → Add localization key
  - "Cancel" → Use `cancel`

- [ ] Replace hardcoded strings in `view_principal_acc_dialog.dart`:
  - "View complete transaction information" → Add localization key
  - "Close" → Use `close`
  - "Amount" → Use `amount`
  - "Date" → Use `date`
  - "Additional Notes" → Add localization key

#### Expenses Screen
- [ ] Replace hardcoded strings in `expenses_screen.dart`:
  - "Expenses Management" → Add localization key
  - "Add Expense" → Add localization key
  - "Total Records" → Add localization key
  - "Total Amount" → Use `totalAmount` (add if missing)
  - "Search expenses..." → Add localization key
  - "Search expenses by ID, type, description, amount, or person..." → Add localization key
  - "Filter" → Use `filter`
  - "Retry" → Use `retry`

#### Payment Screen
- [ ] Replace hardcoded strings in `payment_screen.dart`:
  - "Retry" → Use `retry`

### Priority 3: Product & Sales UI

#### Product Grid
- [ ] Replace hardcoded strings in `product_grid.dart`:
  - "Discount:" → Use `discount`
  - "Cancel" → Use `cancel`
  - "Added {product} with {discount} discount" → Add localization key with parameters
  - "Add with Discount" → Add localization key

#### Cart Sidebar
- [ ] Replace hardcoded strings in `cart_sidebar.dart`:
  - "Tax ({percentage}%)" → Add localization key with parameter

### Priority 4: Validation & Error Messages

#### Labor Dialogs
- [ ] Replace hardcoded validation messages in `add_labor_dialog.dart`:
  - "Please enter a salary" → Add localization key
  - "Please enter a valid salary" → Add localization key
  - "Please select a gender" → Add localization key
  - "Monthly Salary *" → Add localization key
  - "Enter salary" / "Enter monthly salary in PKR" → Add localization key
  - "Gender *" → Add localization key
  - "Select gender" → Add localization key
  - "Male", "Female", "Other" → Add localization keys
  - "Age *" → Add localization key

- [ ] Replace hardcoded validation messages in `delete_labor_dialog.dart`:
  - "Please confirm that you understand this action" → Add localization key
  - "Please confirm that you understand the consequences of permanent deletion" → Add localization key
  - "Please type the labor name exactly to confirm permanent deletion" → Add localization key
  - "Please complete all confirmation steps" → Add localization key

#### Vendor Dialogs
- [ ] Replace hardcoded validation messages in `delete_vendor_dialog.dart`:
  - Similar validation messages as labor dialogs

### Priority 5: Status Values & Dropdowns

#### Common Status Values Needed
- [ ] Add status values:
  - "Draft" → Already exists as `draft`
  - "Issued" → Added as `issued`
  - "Overdue" → Added as `overdue`
  - "Cancelled" → Already exists as `cancelled`
  - "Paid" → Already exists as `paid`
  - "Partial" → Already exists as `partial`
  - "Unpaid" → Already exists as `unpaid`

### Priority 6: Statistics & Labels

#### Dashboard & Screens
- [ ] Replace hardcoded strings in `expenses_screen.dart`:
  - "Total Records" → Add localization key
  - "Total Amount" → Add localization key (or use `totalAmount`)

- [ ] Replace hardcoded strings in `principal_acc_screen.dart`:
  - "Add Entry" / "Add Ledger Entry" → Add localization key
  - "Total Entries" → Add localization key
  - "Total Credits" → Add localization key
  - "Total Debits" → Add localization key
  - "Search ledger entries..." → Add localization key
  - "Search by ID, description, amount, source module, or handler..." → Add localization key

## 📝 Notes

1. **Pattern to Follow**: When replacing hardcoded strings:
   ```dart
   // Before:
   Text('Cancel')
   
   // After:
   Text(AppLocalizations.of(context)!.cancel)
   ```

2. **Parameters**: For strings with dynamic values, use parameterized localization:
   ```dart
   // In ARB file:
   "addedProductWithDiscount": "Added {product} with {discount} discount",
   "@addedProductWithDiscount": {
     "placeholders": {
       "product": {"type": "String"},
       "discount": {"type": "String"}
     }
   }
   
   // In code:
   AppLocalizations.of(context)!.addedProductWithDiscount(productName, discountValue)
   ```

3. **Common Keys Already Available**:
   - `cancel`, `save`, `edit`, `delete`, `add`, `view`, `search`, `filter`, `export`
   - `name`, `phone`, `email`, `address`, `notes`, `date`, `amount`, `price`, `quantity`
   - `status`, `actions`, `total`, `subtotal`, `tax`, `discount`, `grandTotal`
   - `paid`, `unpaid`, `partial`, `draft`, `confirmed`, `delivered`, `cancelled`

4. **Testing**: After each batch of conversions:
   - Run `flutter gen-l10n` to regenerate localization files
   - Test the UI in both English and Urdu
   - Verify all strings are properly localized

## 🎯 Next Steps

1. Start with Priority 1 items (Sales & Receipt Management)
2. Move to Priority 2 (Forms & Dialogs)
3. Continue with remaining priorities
4. Test thoroughly after each section
5. Update this document as work progresses

