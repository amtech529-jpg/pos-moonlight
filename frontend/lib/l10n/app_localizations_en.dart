// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Moon Light Events - Premium Management';

  @override
  String get welcomeBack => 'Welcome Back to';

  @override
  String get brandName => 'Moon Light Events';

  @override
  String get tagline => 'Making your special moments magical.\nPremium event planning and management for your unforgettable celebrations.';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get searchReturns => 'Search Returns';

  @override
  String get serverErrorTryAgainLater => 'Server error. Please try again later.';

  @override
  String get accessDashboard => 'Access your premium dashboard';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get deactivatedSuccessfully => 'Deactivated successfully';

  @override
  String get showing => 'Showing';

  @override
  String get pleaseConfirmAction => 'Please confirm this action';

  @override
  String get deletedPermanently => 'Deleted permanently';

  @override
  String get failedToDelete => 'Failed to delete';

  @override
  String get pleaseConfirmConsequences => 'This action cannot be undone. Are you sure?';

  @override
  String pleaseTypeVendorName(Object vendorName) {
    return 'Please type \'$vendorName\' to confirm';
  }

  @override
  String get pleaseCompleteConfirmation => 'Please complete the confirmation step';

  @override
  String get location => 'Location';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get loginSuccess => 'Welcome back! Login successful.';

  @override
  String get loginFailed => 'Login failed. Please check your credentials.';

  @override
  String get unexpectedError => 'An unexpected error occurred. Please try again.';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get sales => 'Sales';

  @override
  String get products => 'Products';

  @override
  String get customers => 'Customers';

  @override
  String get orders => 'Orders';

  @override
  String get payments => 'Payments';

  @override
  String get invoices => 'Invoices';

  @override
  String get receipts => 'Receipts';

  @override
  String get expenses => 'Expenses';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get search => 'Search';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get tax => 'Tax';

  @override
  String get discount => 'Discount';

  @override
  String get grandTotal => 'Grand Total';

  @override
  String get quantity => 'Quantity';

  @override
  String get price => 'Price';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get status => 'Status';

  @override
  String get actions => 'Actions';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get address => 'Address';

  @override
  String get notes => 'Notes';

  @override
  String get category => 'Category';

  @override
  String get vendor => 'Vendor';

  @override
  String get zakat => 'Zakat';

  @override
  String get profitLoss => 'Profit & Loss';

  @override
  String get advancePayment => 'Advance Payment';

  @override
  String get receivables => 'Receivables';

  @override
  String get payables => 'Payables';

  @override
  String get principalAccount => 'Principal Account';

  @override
  String get returns => 'Returns';

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get partial => 'Partial';

  @override
  String get draft => 'Draft';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get delivered => 'Delivered';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String get bankTransfer => 'Bank Transfer';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data available';

  @override
  String error(String error) {
    return 'Error';
  }

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';

  @override
  String get posSystem => 'Sales';

  @override
  String get selectProductsManageSales => 'Select products and manage sales transactions';

  @override
  String get todaySales => 'Today Sales';

  @override
  String get revenue => 'Revenue';

  @override
  String get purchasesTagline => 'Track and manage inventory supply and purchase records';

  @override
  String get newPurchase => 'New Purchase';

  @override
  String get totalInvestment => 'Total Investment';

  @override
  String get enterInvoiceRef => 'Enter Invoice Reference';

  @override
  String get purchaseDate => 'Purchase Date';

  @override
  String get purchasedProducts => 'Purchased Products';

  @override
  String get addProductRow => 'Add Product Row';

  @override
  String get unitCost => 'Unit Cost';

  @override
  String get taxAdjustment => 'Tax / Adjustment';

  @override
  String get savePurchase => 'Save Purchase';

  @override
  String get validationError => 'Validation Error';

  @override
  String get enterInvoiceNumberError => 'Please enter an Invoice Number.';

  @override
  String get selectVendorError => 'Please select a Vendor.';

  @override
  String get addOneProductError => 'Please add at least one product to the purchase.';

  @override
  String selectProductError(Object itemIndex) {
    return 'Item #$itemIndex: Please select a product.';
  }

  @override
  String invalidQtyError(Object itemIndex) {
    return 'Item #$itemIndex: Quantity must be greater than 0.';
  }

  @override
  String get savePurchaseFailed => 'Failed to save purchase';

  @override
  String get purchaseDetails => 'Purchase Details';

  @override
  String get purchasedItems => 'Purchased Items';

  @override
  String get printInvoice => 'Print Invoice';

  @override
  String get filterPurchases => 'Filter Purchases';

  @override
  String get fromDate => 'From Date';

  @override
  String get toDate => 'To Date';

  @override
  String get resetAll => 'Reset All';

  @override
  String get unknownVendor => 'Unknown Vendor';

  @override
  String get deletePurchaseConfirm => 'Are you sure you want to delete this purchase?';

  @override
  String get noPurchasesFound => 'No Purchases Found';

  @override
  String get noPurchasesMatchFilter => 'No purchases match the current filter';

  @override
  String get viewHistory => 'View History';

  @override
  String get currentTime => 'Current Time';

  @override
  String get salesHistory => 'Sales Transaction History';

  @override
  String get viewManageSales => 'View and manage all sales transactions';

  @override
  String get searchSales => 'Search sales by invoice, customer, phone...';

  @override
  String get allStatus => 'All Status';

  @override
  String get export => 'Export';

  @override
  String get exportingSalesData => 'Exporting sales data...';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get searchProductsExpanded => 'Search products by name, color, fabric...';

  @override
  String get filter => 'Filter';

  @override
  String get screenTooSmall => 'Screen Too Small';

  @override
  String get screenTooSmallMessage => 'This application requires a minimum screen width of 750px for optimal experience. Please use a larger screen or rotate your device.';

  @override
  String get all => 'All';

  @override
  String get checkout => 'Checkout';

  @override
  String get cart => 'Cart';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get removeFromCart => 'Remove from Cart';

  @override
  String get clearCart => 'Clear Cart';

  @override
  String get customer => 'Customer';

  @override
  String get selectCustomer => 'Select Customer';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get paidAmount => 'Paid Amount';

  @override
  String get remainingAmount => 'Remaining Amount';

  @override
  String get invoice => 'Invoice';

  @override
  String get view => 'View';

  @override
  String get confirmLogout => 'Confirm Logout';

  @override
  String get loggingOut => 'Logging out...';

  @override
  String get logoutSuccess => 'Successfully logged out. See you soon!';

  @override
  String get notEnoughStock => 'Not enough stock';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get cartIsEmpty => 'Cart is Empty';

  @override
  String get addProductsToStartSale => 'Add products to start a sale';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get walkInCustomer => 'Walk-in Customer';

  @override
  String get proceedToCheckout => 'Proceed to Checkout';

  @override
  String get clearCartQuestion => 'Are you sure you want to remove all items from the cart?';

  @override
  String get noProductsFound => 'No Products Found';

  @override
  String get noProductsAvailable => 'No Products Available';

  @override
  String get tryAdjustingSearch => 'Try adjusting your search or filter criteria';

  @override
  String get addProductsToInventory => 'Add products to your inventory to start selling';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get items => 'items';

  @override
  String get productsManagement => 'Products Management';

  @override
  String get productManagementDescription => 'Manage product inventory and details with comprehensive tools';

  @override
  String get manageInventory => 'Manage inventory';

  @override
  String get addProduct => 'Add Product';

  @override
  String get exportCompleted => 'Export completed!';

  @override
  String get retry => 'Retry';

  @override
  String get totalProducts => 'Total Products';

  @override
  String get inStock => 'In Stock';

  @override
  String get totalValue => 'Total Value';

  @override
  String get value => 'Value';

  @override
  String get searchProductsHint => 'Search products by ID, name, color, fabric, or pieces...';

  @override
  String get customerManagement => 'Customer Management';

  @override
  String get customerManagementDescription => 'Organize and manage your customer relationships with comprehensive tools';

  @override
  String get customerManagementShortDescription => 'Manage customer relationships';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get totalCustomers => 'Total Customers';

  @override
  String get newThisMonth => 'New This Month';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get recentBuyers => 'Recent Buyers';

  @override
  String get newCustomer => 'New';

  @override
  String get recent => 'Recent';

  @override
  String get searchCustomersHint => 'Search customers by name, phone, email...';

  @override
  String get searchCustomersShortHint => 'Search customers...';

  @override
  String get hideInactive => 'Hide Inactive';

  @override
  String get showInactive => 'Show Inactive';

  @override
  String get clearAll => 'Clear All';

  @override
  String get customerDataExported => 'Customer data exported successfully';

  @override
  String get failedToExportData => 'Failed to export data';

  @override
  String get loadingCustomers => 'Loading customers...';

  @override
  String get noCustomersFound => 'No customers found';

  @override
  String get adjustFilters => 'Try adjusting your filters or adding new customers.';

  @override
  String get failedToRefreshCustomers => 'Failed to refresh customers';

  @override
  String get viewLedger => 'View Ledger';

  @override
  String get addNewCustomer => 'Add New Customer';

  @override
  String get createNewCustomerProfile => 'Create a new customer profile';

  @override
  String get customerAddedSuccessfully => 'Customer added successfully';

  @override
  String get failedToAddCustomer => 'Failed to add customer';

  @override
  String get lastPurchase => 'Last Purchase';

  @override
  String get logoutMessage => 'Are you sure you want to logout from your account?';

  @override
  String get logoutError => 'Logged out locally due to an error.';

  @override
  String get brandTagline => 'Premium POS';

  @override
  String get welcomeToPos => 'Welcome to Moon Light Events';

  @override
  String get welcomeTagline => 'Premium Event Management - Your Complete Celebration Solution';

  @override
  String get today => 'Today';

  @override
  String get totalIncome => 'Total Income';

  @override
  String get totalExpenses => 'Total Expenses';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get activeCustomers => 'Active Customers';

  @override
  String get activeVendors => 'Active Vendors';

  @override
  String get pendingReturns => 'Pending Returns';

  @override
  String get salesOverview => 'Sales Overview';

  @override
  String get last6Months => 'Last 6 months performance';

  @override
  String get revenueTarget => 'Revenue Target';

  @override
  String get customerGrowth => 'Customer Growth';

  @override
  String get vendorPartnerships => 'Vendor Partnerships';

  @override
  String get conversionRate => 'Conversion Rate';

  @override
  String get topCustomers => 'Top Customers';

  @override
  String get vipCustomer => 'VIP Customer';

  @override
  String get corporateClient => 'Corporate Client';

  @override
  String get regularCustomer => 'Regular Customer';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get newCustomerRegistered => 'New customer registered';

  @override
  String get newVendorRegistered => 'New vendor registered';

  @override
  String get customerPurchaseCompleted => 'Customer purchase completed';

  @override
  String get vendorDeliveryReceived => 'Vendor delivery received';

  @override
  String get underConstruction => 'This page is under construction.';

  @override
  String get comingSoon => 'Coming soon with amazing features!';

  @override
  String get backToDashboard => 'Back to Dashboard';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get newOrder => 'New Order';

  @override
  String get createOrder => 'Create order';

  @override
  String get processPayment => 'Process payment';

  @override
  String get viewAnalytics => 'View analytics';

  @override
  String get viewAll => 'View All';

  @override
  String get recentOrders => 'Recent Orders';

  @override
  String get monthlyPerformance => 'Monthly Performance';

  @override
  String get payment => 'Payment';

  @override
  String get searchProductsShortHint => 'Search products...';

  @override
  String get premiumCustomer => 'Premium Customer';

  @override
  String get orderItems => 'Order Items';

  @override
  String get page => 'Page';

  @override
  String get close => 'Close';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get generated => 'Generated';

  @override
  String get created => 'Created';

  @override
  String get sent => 'Sent';

  @override
  String get viewed => 'Viewed';

  @override
  String get issued => 'Issued';

  @override
  String get overdue => 'Overdue';

  @override
  String get createReceipt => 'Create Receipt';

  @override
  String get updateReceipt => 'Update Receipt';

  @override
  String get creatingOrder => 'Creating Order...';

  @override
  String get noSalesAvailable => 'No sales available';

  @override
  String get noReceiptsFound => 'No receipts found';

  @override
  String get receiptCreatedSuccessfully => 'Receipt created successfully';

  @override
  String get receiptUpdatedSuccessfully => 'Receipt updated successfully';

  @override
  String get receiptDeletedSuccessfully => 'Receipt deleted successfully';

  @override
  String get selectSale => 'Select Sale';

  @override
  String get chooseSaleToCreateReceipt => 'Choose a sale to create receipt for';

  @override
  String get dueDate => 'Due Date';

  @override
  String get pleaseSelectSale => 'Please select a sale';

  @override
  String get additionalReceiptNotes => 'Additional receipt notes (optional)';

  @override
  String get type => 'Type';

  @override
  String get active => 'Active';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get weekAgo => 'week ago';

  @override
  String get monthAgo => 'month ago';

  @override
  String get yearAgo => 'year ago';

  @override
  String get characters => 'characters';

  @override
  String get optional => 'optional';

  @override
  String get updated => 'Updated';

  @override
  String get popular => 'Popular';

  @override
  String get manageProductCategories => 'Manage product categories';

  @override
  String get searchCategoriesHint => 'Search categories by name, ID, or description';

  @override
  String get growth => 'Growth';

  @override
  String get cities => 'Cities';

  @override
  String get citiesCovered => 'Cities Covered';

  @override
  String get searchVendorsHint => 'Search vendors by name, business, CNIC, or phone';

  @override
  String get city => 'City';

  @override
  String get area => 'Area';

  @override
  String get pleaseFixErrors => 'Please fix the following errors';

  @override
  String get profile => 'Profile';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get businessInformation => 'Business Information';

  @override
  String get additionalInformation => 'Additional Information';

  @override
  String get locationInformation => 'Location Information';

  @override
  String get fullName => 'Full Name';

  @override
  String get pleaseEnter => 'Please enter';

  @override
  String get mustBeAtLeast => 'must be at least';

  @override
  String get mustBeLessThan => 'must be less than';

  @override
  String get businessName => 'Business Name';

  @override
  String get cnic => 'CNIC';

  @override
  String get cnicFormat => 'XXXXX-XXXXXXX-X';

  @override
  String get pleaseEnterValid => 'Please enter a valid';

  @override
  String get phoneFormat => '+923001234567';

  @override
  String get outOf => 'of';

  @override
  String get refineVendorList => 'Refine your vendor list with filters';

  @override
  String get showInactiveVendorsOnly => 'Show inactive vendors only';

  @override
  String get onlyDeactivatedVendorsShown => 'Only deactivated vendors will be shown';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get clearAllFilters => 'Clear All Filters';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get restore => 'Restore';

  @override
  String get areYouSureDeactivate => 'Are you sure you want to deactivate';

  @override
  String get actionCanBeReversed => 'This action can be reversed';

  @override
  String get failedToDeactivate => 'Failed to deactivate';

  @override
  String get areYouSureRestore => 'Are you sure you want to restore';

  @override
  String get failedToRestore => 'Failed to restore';

  @override
  String get restoredSuccessfully => 'restored successfully';

  @override
  String get failedToLoad => 'Failed to Load';

  @override
  String get noVendorsFound => 'No Vendors Found';

  @override
  String get startByAddingFirstVendor => 'Start by adding your first vendor to manage your suppliers effectively';

  @override
  String get firstVendor => 'First Vendor';

  @override
  String get details => 'Details';

  @override
  String get complete => 'Complete';

  @override
  String get information => 'Information';

  @override
  String get since => 'since';

  @override
  String get daysOld => 'days old';

  @override
  String get fullAddress => 'Full Address';

  @override
  String get activitySummary => 'Activity Summary';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get updatedSuccessfully => 'updated successfully';

  @override
  String get failedToUpdate => 'Failed to update';

  @override
  String get updating => 'updating';

  @override
  String get noChangesDetected => 'No changes detected';

  @override
  String get discardChanges => 'Discard Changes?';

  @override
  String get discardChangesMessage => 'You have unsaved changes. Are you sure you want to discard them?';

  @override
  String get continueEditing => 'Continue Editing';

  @override
  String get discard => 'Discard';

  @override
  String get unsavedChanges => 'You have unsaved changes';

  @override
  String get modified => 'Modified';

  @override
  String get update => 'Update';

  @override
  String get product => 'Product';

  @override
  String get newProduct => 'New Product';

  @override
  String get createNewProductEntry => 'Create a new product entry';

  @override
  String get detail => 'Detail';

  @override
  String get description => 'Description';

  @override
  String get cost => 'Cost';

  @override
  String get costPriceCannotExceedSellingPrice => 'Cost price cannot exceed selling price';

  @override
  String get costPriceInfo => 'Setting cost price enables profit margin calculations and better financial analysis';

  @override
  String get qty => 'Qty';

  @override
  String get colorName => 'Color Name';

  @override
  String get fabricType => 'Fabric Type';

  @override
  String get fabricName => 'Fabric Name';

  @override
  String get pleaseSelectAtLeastOnePiece => 'Please select at least one piece';

  @override
  String get failedToAdd => 'Failed to add';

  @override
  String get addedSuccessfully => 'added successfully';

  @override
  String get select => 'Select';

  @override
  String get pleaseSelect => 'Please select';

  @override
  String get labors => 'Employees';

  @override
  String get laborManagement => 'Employee Management';

  @override
  String get laborManagementDescription => 'Organize and manage your employee workforce with comprehensive tools';

  @override
  String get organizeAndManageLaborWorkforce => 'Organize and manage employee workforce';

  @override
  String get manageLaborWorkforce => 'Manage employee workforce';

  @override
  String get failedToRefresh => 'Failed to refresh';

  @override
  String get preparingExport => 'Preparing export...';

  @override
  String get dataExportCompleted => 'data export completed successfully';

  @override
  String get newLabel => 'New';

  @override
  String get searchLaborsHint => 'Search employees by name, CNIC, phone, role...';

  @override
  String get filters => 'Filters';

  @override
  String get designation => 'Role';

  @override
  String get caste => 'Caste';

  @override
  String get gender => 'Gender';

  @override
  String get receivable => 'Receivable';

  @override
  String get receivablesManagement => 'Receivables Management';

  @override
  String get receivablesManagementDescription => 'Track and manage amounts lent to customers and suppliers';

  @override
  String get manageAmountsLent => 'Manage amounts lent';

  @override
  String get amountsLent => 'Amounts lent';

  @override
  String get amountLent => 'Amount Lent';

  @override
  String get amountReturned => 'Amount Returned';

  @override
  String get outstanding => 'Outstanding';

  @override
  String get returned => 'Returned';

  @override
  String get searchReceivablesHint => 'Search by debtor name, phone, reason, or notes...';

  @override
  String get inactive => 'Inactive';

  @override
  String get id => 'ID';

  @override
  String get debtor => 'Debtor';

  @override
  String get debtorDetails => 'Debtor Details';

  @override
  String get amounts => 'Amounts';

  @override
  String get reasonItem => 'Reason/Item';

  @override
  String get dates => 'Dates';

  @override
  String get returnDate => 'Return Date';

  @override
  String get progress => 'Progress';

  @override
  String get remaining => 'remaining';

  @override
  String get lent => 'Lent';

  @override
  String get daysOverdue => 'days overdue';

  @override
  String get viewDetails => 'View Details';

  @override
  String get deleteText => 'Delete';

  @override
  String get noReceivablesFound => 'No Receivables Found';

  @override
  String get startByAddingFirstReceivable => 'Start by adding your first receivable record to track amounts lent to customers and suppliers';

  @override
  String get firstReceivable => 'First Receivable';

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String get deactivateVendor => 'Deactivate Vendor';

  @override
  String get actionCannotBeUndone => 'This action cannot be undone';

  @override
  String get vendorCanBeRestoredLater => 'Vendor can be restored later';

  @override
  String get permanentDeletionWarning => 'Permanent Deletion Warning';

  @override
  String get deactivationNotice => 'Deactivation Notice';

  @override
  String get permanentDeletionWarningMessage => 'This will permanently remove all vendor data from the database. This action cannot be reversed.';

  @override
  String get deactivationNoticeMessage => 'This will deactivate the vendor but preserve all data. The vendor can be restored later if needed.';

  @override
  String get chooseDeletionType => 'Choose deletion type:';

  @override
  String get permanentDelete => 'Permanent Delete';

  @override
  String get removesFromDatabasePermanently => 'Removes from database permanently';

  @override
  String get hideButCanBeRestored => 'Hide but can be restored';

  @override
  String get vendorSince => 'Vendor since';

  @override
  String get days => 'days';

  @override
  String get understandPermanentDeletion => 'I understand this will permanently delete the vendor';

  @override
  String get understandDeactivation => 'I understand this will deactivate the vendor';

  @override
  String get understandActionCannotBeUndone => 'I understand this action cannot be undone and will affect related records';

  @override
  String get typeVendorNameToConfirm => 'Type the vendor name to confirm permanent deletion:';

  @override
  String get expected => 'Expected';

  @override
  String get payable => 'Payable';

  @override
  String get payablesManagement => 'Payables Management';

  @override
  String get payablesManagementDescription => 'Track and manage amounts owed to creditors efficiently';

  @override
  String get manageCreditorPayables => 'Manage creditor payables';

  @override
  String get creditorPayables => 'Creditor payables';

  @override
  String get totalPayables => 'Total Payables';

  @override
  String get totalBorrowed => 'Total Borrowed';

  @override
  String get totalPaid => 'Total Paid';

  @override
  String get balanceDue => 'Balance Due';

  @override
  String get borrowed => 'Borrowed';

  @override
  String get due => 'Due';

  @override
  String get searchPayablesHint => 'Search by ID, creditor name, phone, reason, or status...';

  @override
  String get refresh => 'Refresh';

  @override
  String get paymentManagement => 'Payment Management';

  @override
  String get paymentManagementDescription => 'Track and manage employee salary payments efficiently';

  @override
  String get trackManageSalaryPayments => 'Track and manage salary payments';

  @override
  String get trackSalaryPayments => 'Track salary payments';

  @override
  String get totalRecords => 'Total Records';

  @override
  String get thisMonth => 'This Month';

  @override
  String get thisWeek => 'This Week';

  @override
  String get searchPaymentsHint => 'Search by ID, employee name, payment method, month, or description...';

  @override
  String get advancePaymentManagement => 'Advance Payment Management';

  @override
  String get advancePaymentManagementDescription => 'Track and manage employee advance payments efficiently';

  @override
  String get advancePayments => 'Advance Payments';

  @override
  String get manageLaborPayments => 'Manage employee payments';

  @override
  String get totalPayments => 'Total Payments';

  @override
  String get withReceipts => 'With Receipts';

  @override
  String get loadingAdvancePayments => 'Loading advance payments...';

  @override
  String get searchAdvancePaymentsHint => 'Search by ID, employee name, phone, role, or description...';

  @override
  String get dataRefreshedSuccessfully => 'Data refreshed successfully';

  @override
  String get expense => 'Expense';

  @override
  String get expensesManagement => 'Expenses Management';

  @override
  String get expensesManagementDescription => 'Track and manage business expenses efficiently';

  @override
  String get trackBusinessExpenses => 'Track business expenses';

  @override
  String get trackExpenses => 'Track expenses';

  @override
  String get thisYear => 'This Year';

  @override
  String get searchExpensesHint => 'Search expenses by ID, type, description, amount, or person...';

  @override
  String get zakatManagement => 'Zakat Management';

  @override
  String get zakatManagementDescription => 'Track and manage zakat contributions efficiently';

  @override
  String get trackZakatContributions => 'Track zakat contributions';

  @override
  String get trackContributions => 'Track contributions';

  @override
  String get searchZakatHint => 'Search zakat by ID, title, beneficiary, or amount...';

  @override
  String get profitLossStatement => 'Profit & Loss Statement';

  @override
  String get profitLossStatementDescription => 'Financial performance analysis and profitability tracking';

  @override
  String get profitLossShort => 'P&L';

  @override
  String get financialPerformanceAnalysis => 'Financial performance analysis';

  @override
  String get financialAnalysis => 'Financial analysis';

  @override
  String get period => 'Period';

  @override
  String get report => 'Report';

  @override
  String get preparing => 'Preparing';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get calculatingProfitLoss => 'Calculating Profit & Loss...';

  @override
  String get noFinancialDataAvailable => 'No Financial Data Available';

  @override
  String get selectPeriodToViewAnalysis => 'Select a period to view profit and loss analysis';

  @override
  String get overview => 'Overview';

  @override
  String get expenseBreakdown => 'Expense Breakdown';

  @override
  String get ofExpenses => 'of expenses';

  @override
  String get profitable => 'PROFITABLE';

  @override
  String get loss => 'LOSS';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get clearErrors => 'Clear Errors';

  @override
  String get operationCompletedSuccessfully => 'Operation completed successfully';

  @override
  String get taxManagement => 'Tax Management';

  @override
  String get taxManagementDescription => 'Manage tax rates and configurations';

  @override
  String get addTaxRate => 'Add Tax Rate';

  @override
  String get searchTaxRatesHint => 'Search tax rates...';

  @override
  String get taxRates => 'Tax Rates';

  @override
  String get noTaxRatesFound => 'No Tax Rates Found';

  @override
  String get addFirstTaxRate => 'Add your first tax rate to get started';

  @override
  String get statistics => 'Statistics';

  @override
  String get totalTaxRates => 'Total Tax Rates';

  @override
  String get activeRates => 'Active Rates';

  @override
  String get activate => 'Activate';

  @override
  String get deleteTaxRate => 'Delete Tax Rate';

  @override
  String get deleteTaxRateConfirmation => 'Are you sure you want to delete';

  @override
  String get editTaxRate => 'Edit Tax Rate';

  @override
  String get taxName => 'Tax Name';

  @override
  String get taxType => 'Tax Type';

  @override
  String get taxPercentage => 'Tax Percentage (%)';

  @override
  String get pleaseEnterTaxName => 'Please enter a tax name';

  @override
  String get pleaseEnterTaxPercentage => 'Please enter a tax percentage';

  @override
  String get pleaseEnterValidPercentage => 'Please enter a valid percentage (0-100)';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get returnManagement => 'Return Management';

  @override
  String get titleReceiptManagement => 'Receipt Management';

  @override
  String get receivableDetails => 'Receivable Details';

  @override
  String get viewCompleteReceivableInformation => 'View complete receivable information';

  @override
  String get debtorInformation => 'Debtor Information';

  @override
  String get amountBreakdown => 'Amount Breakdown';

  @override
  String get amountGiven => 'Amount Given:';

  @override
  String get balanceRemaining => 'Balance Remaining:';

  @override
  String get returnProgress => 'Return Progress';

  @override
  String get dateLent => 'Date Lent';

  @override
  String get expectedReturnDate => 'Expected Return Date';

  @override
  String get expectedReturn => 'Expected Return';

  @override
  String get transactionDetails => 'Transaction Details';

  @override
  String get editReceivable => 'Edit Receivable';

  @override
  String get editReceivableDetails => 'Edit Receivable Details';

  @override
  String get updateReceivableInformation => 'Update receivable information';

  @override
  String get debtorName => 'Debtor Name';

  @override
  String get enterName => 'Enter name';

  @override
  String get enterDebtorFullName => 'Enter debtor full name';

  @override
  String get pleaseEnterDebtorName => 'Please enter debtor name';

  @override
  String get nameMustBeAtLeast2Characters => 'Name must be at least 2 characters';

  @override
  String get enterPhone => 'Enter Your Phone Number';

  @override
  String get enterPhoneNumber => 'Enter phone number (+92XXXXXXXXXX)';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter phone number';

  @override
  String get pleaseEnterValidPhoneNumber => 'Please enter a valid phone number';

  @override
  String get amountGivenPkr => 'Amount Given (PKR)';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get pleaseEnterAmount => 'Please enter amount';

  @override
  String get pleaseEnterValidAmount => 'Please enter valid amount';

  @override
  String get amountReturnedPkr => 'Amount Returned (PKR)';

  @override
  String get enterReturned => 'Enter returned';

  @override
  String get enterValidAmount => 'Enter valid amount';

  @override
  String get cannotExceedAmountGiven => 'Cannot exceed amount given';

  @override
  String get reasonForLending => 'Reason for lending';

  @override
  String get enterReasonForLendingOrItemDescription => 'Enter reason for lending or item description';

  @override
  String get pleaseEnterReasonOrItem => 'Please enter reason or item';

  @override
  String get pleaseProvideMoreDetails => 'Please provide more details';

  @override
  String get notesOptional => 'Notes (Optional)';

  @override
  String get additionalNotes => 'Additional notes';

  @override
  String get enterAdditionalNotesOrTerms => 'Enter additional notes or terms';

  @override
  String get selectDate => 'Select date';

  @override
  String get updateReceivable => 'Update Receivable';

  @override
  String get receivableUpdatedSuccessfully => 'Receivable updated successfully!';

  @override
  String get amountReturnedCannotExceedAmountGiven => 'Amount returned cannot exceed amount given';

  @override
  String get expectedReturnDateCannotBeBeforeDateLent => 'Expected return date cannot be before date lent';

  @override
  String get addReceivable => 'Add Receivable';

  @override
  String get addNewReceivable => 'Add New Receivable';

  @override
  String get recordAmountLentToCustomerOrSupplier => 'Record amount lent to customer or supplier';

  @override
  String get amountDetails => 'Amount Details';

  @override
  String get enterAmountGivenToDebtor => 'Enter amount given to debtor';

  @override
  String get pleaseEnterAmountGiven => 'Please enter amount given';

  @override
  String get optionalIfAnyAmountAlreadyReturned => 'Optional - if any amount already returned';

  @override
  String get dateInformation => 'Date Information';

  @override
  String get lendingPeriod => 'Lending period:';

  @override
  String get pleaseSelectValidReturnDate => 'Please select a valid return date';

  @override
  String get receivableAddedSuccessfully => 'Receivable added successfully!';

  @override
  String get addLabor => 'Add Employee';

  @override
  String get addNewLabor => 'Add New Employee';

  @override
  String get createNewLaborRecord => 'Create a new employee record';

  @override
  String get fullNameRequired => 'Full Name *';

  @override
  String get enterWorkersFullName => 'Enter worker\'s full name';

  @override
  String get pleaseEnterName => 'Please enter a name';

  @override
  String get nameMustBeLessThan50Characters => 'Name must be less than 50 characters';

  @override
  String get cnicRequired => 'CNIC *';

  @override
  String get enterCnic => 'Enter CNIC';

  @override
  String get enterCnicFormat => 'Enter CNIC (e.g., 42101-1234567-1)';

  @override
  String get pleaseEnterCnic => 'Please enter a CNIC';

  @override
  String get pleaseEnterValidCnicFormat => 'Please enter a valid CNIC (XXXXX-XXXXXXX-X)';

  @override
  String get enterCaste => 'Enter caste';

  @override
  String get enterCasteOptional => 'Enter caste (optional)';

  @override
  String get phoneNumberRequired => 'Phone Number *';

  @override
  String get enterPhoneNumberFormat => 'Enter phone number (e.g., +923001234567)';

  @override
  String get pleaseEnterValidPhoneNumberFormat => 'Please enter a valid phone number (+92XXXXXXXXXX)';

  @override
  String get cityRequired => 'City *';

  @override
  String get enterCity => 'Enter city';

  @override
  String get pleaseEnterCity => 'Please enter city';

  @override
  String get areaRequired => 'Area *';

  @override
  String get enterArea => 'Enter area';

  @override
  String get pleaseEnterArea => 'Please enter area';

  @override
  String get employmentInformation => 'Employment Information';

  @override
  String get designationRequired => 'Role *';

  @override
  String get enterDesignation => 'Enter role';

  @override
  String get enterJobDesignation => 'Enter job role (e.g., Tailor, Operator)';

  @override
  String get pleaseEnterDesignation => 'Please enter a role';

  @override
  String get joiningDateRequired => 'Joining Date *';

  @override
  String get selectJoiningDate => 'Select joining date';

  @override
  String get monthlySalaryRequired => 'Monthly Salary *';

  @override
  String get enterSalary => 'Enter salary';

  @override
  String get enterMonthlySalaryInPkr => 'Enter monthly salary in PKR';

  @override
  String get pleaseEnterSalary => 'Please enter a salary';

  @override
  String get pleaseEnterValidSalary => 'Please enter a valid salary';

  @override
  String get genderRequired => 'Gender *';

  @override
  String get selectGender => 'Select gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get pleaseSelectGender => 'Please select a gender';

  @override
  String get ageRequired => 'Age *';

  @override
  String get enterAge => 'Enter age';

  @override
  String get enterAgeMinimum18Years => 'Enter age (minimum 18 years)';

  @override
  String get pleaseEnterAge => 'Please enter an age';

  @override
  String get ageMustBeAtLeast18 => 'Age must be at least 18';

  @override
  String get ageMustBeLessThan65 => 'Age must be less than 65';

  @override
  String get laborCreatedSuccessfully => 'Employee created successfully!';

  @override
  String get failedToCreateLabor => 'Failed to create employee';

  @override
  String get errorCreatingLabor => 'Error creating employee:';

  @override
  String get pleaseFixFollowingErrors => 'Please fix the following errors:';

  @override
  String get nameIsRequired => 'Name is required';

  @override
  String get cnicIsRequired => 'CNIC is required';

  @override
  String get phoneNumberIsRequired => 'Phone number is required';

  @override
  String get casteIsRequired => 'Caste is required';

  @override
  String get designationIsRequired => 'Role is required';

  @override
  String get areaIsRequired => 'Area is required';

  @override
  String get cityIsRequired => 'City is required';

  @override
  String get genderIsRequired => 'Gender is required';

  @override
  String get joiningDateCannotBeInFuture => 'Joining date cannot be in the future';

  @override
  String get salaryIsRequired => 'Salary is required';

  @override
  String get pleaseEnterValidSalaryAmount => 'Please enter a valid salary amount';

  @override
  String get ageIsRequired => 'Age is required';

  @override
  String get pleaseEnterValidAge => 'Please enter a valid age';

  @override
  String get salary => 'Salary';

  @override
  String get joinedDate => 'Joined Date';

  @override
  String get recentLabel => 'RECENT';

  @override
  String get laborStatusUpdatedSuccessfully => 'Employee status updated successfully!';

  @override
  String get failedToUpdateLaborStatus => 'Failed to update employee status';

  @override
  String get errorUpdatingLaborStatus => 'Error updating employee status:';

  @override
  String get loadingLaborDetails => 'Loading employee details...';

  @override
  String get laborDetails => 'Employee Details';

  @override
  String get completeLaborInformation => 'Complete employee information';

  @override
  String get joined => 'Joined';

  @override
  String get daysExperience => 'days experience';

  @override
  String get years => 'years';

  @override
  String get age => 'Age';

  @override
  String get workInformation => 'Work Information';

  @override
  String get experience => 'Experience';

  @override
  String get joiningDate => 'Joining Date';

  @override
  String get financialInformation => 'Financial Information';

  @override
  String get monthlySalary => 'Monthly Salary';

  @override
  String get totalAdvances => 'Total Advances';

  @override
  String get remainingMonthlySalary => 'Remaining Monthly Salary';

  @override
  String get remainingAdvanceAmount => 'Remaining Advance Amount';

  @override
  String get totalAdvancesThisMonth => 'Total Advances This Month';

  @override
  String get paymentRecords => 'Payment Records';

  @override
  String get lastPayment => 'Last Payment';

  @override
  String get statusInformation => 'Status Information';

  @override
  String get createdBy => 'Created By';

  @override
  String get newLabor => 'New Employee';

  @override
  String get restoreLabor => 'Restore Employee';

  @override
  String get deactivateLabor => 'Deactivate Employee';

  @override
  String areYouSureDeactivateLabor(String name) {
    return 'Are you sure you want to deactivate $name? This action can be reversed.';
  }

  @override
  String areYouSureRestoreLabor(String name) {
    return 'Are you sure you want to restore $name?';
  }

  @override
  String get failedToDeactivateLabor => 'Failed to deactivate employee';

  @override
  String get laborDeactivatedSuccessfully => 'Employee deactivated successfully';

  @override
  String get failedToRestoreLabor => 'Failed to restore employee';

  @override
  String get laborRestoredSuccessfully => 'Employee restored successfully';

  @override
  String get failedToLoadLabors => 'Failed to Load Employees';

  @override
  String get unexpectedErrorOccurred => 'An unexpected error occurred';

  @override
  String get noLaborsFound => 'No Employees Found';

  @override
  String get startByAddingFirstLabor => 'Start by adding your first employee to manage your workforce effectively';

  @override
  String get addFirstLabor => 'Add First Employee';

  @override
  String get filterLabors => 'Filter Employees';

  @override
  String get refineYourLaborList => 'Refine your employee list with filters';

  @override
  String get searchLabors => 'Search Employees';

  @override
  String get laborStatus => 'Employee Status';

  @override
  String get searchByNameCnicPhoneDesignation => 'Search by name, CNIC, phone, or role';

  @override
  String get showInactiveLaborsOnly => 'Show inactive employees only';

  @override
  String get onlyDeactivatedLaborsWillBeShown => 'Only deactivated employees will be shown';

  @override
  String get enterCityName => 'Enter city name';

  @override
  String get enterAreaName => 'Enter area name';

  @override
  String get principalAccountLedger => 'Principal Account Ledger';

  @override
  String get trackAllCashMovements => 'Track all cash movements and maintain financial balance';

  @override
  String get trackCashMovementsAndBalance => 'Track cash movements and balance';

  @override
  String get ledger => 'Ledger';

  @override
  String get cashMovements => 'Cash movements';

  @override
  String get addEntry => 'Add Entry';

  @override
  String get addLedgerEntry => 'Add Ledger Entry';

  @override
  String get currentBalance => 'Current Balance';

  @override
  String get totalEntries => 'Total Entries';

  @override
  String get totalCredits => 'Total Credits';

  @override
  String get totalDebits => 'Total Debits';

  @override
  String get credits => 'Credits';

  @override
  String get debits => 'Debits';

  @override
  String get searchLedgerEntries => 'Search ledger entries...';

  @override
  String get searchByIdDescriptionAmount => 'Search by ID, description, amount, source module, or handler...';

  @override
  String get receivableDeletedSuccessfully => 'Receivable deleted successfully!';

  @override
  String get deleteReceivable => 'Delete Receivable';

  @override
  String get deleteReceivableRecord => 'Delete Receivable Record';

  @override
  String get thisActionCannotBeUndone => 'This action cannot be undone';

  @override
  String get areYouSureDeleteReceivable => 'Are you sure you want to delete this receivable?';

  @override
  String get areYouAbsolutelySureDeleteReceivable => 'Are you absolutely sure you want to delete this receivable record?';

  @override
  String get amountGivenLabel => 'Amount Given:';

  @override
  String get balanceRemainingLabel => 'Balance Remaining:';

  @override
  String get phoneLabel => 'Phone:';

  @override
  String get statusLabel => 'Status:';

  @override
  String get expectedReturnLabel => 'Expected Return:';

  @override
  String get daysOverdueLabel => 'Days Overdue:';

  @override
  String get reasonItemLabel => 'Reason/Item:';

  @override
  String get willPermanentlyDeleteReceivable => 'This will permanently delete the receivable record.';

  @override
  String get willPermanentlyDeleteReceivableAndData => 'This will permanently delete the receivable record and all associated data. This action cannot be undone.';

  @override
  String get filterAndSortProducts => 'Filter & Sort Products';

  @override
  String get refineYourProductList => 'Refine your product list with advanced filters';

  @override
  String get productCategory => 'Product Category';

  @override
  String get productAttributes => 'Product Attributes';

  @override
  String get stockLevel => 'Stock Level';

  @override
  String get priceRangePKR => 'Price Range (PKR)';

  @override
  String get sortOptions => 'Sort Options';

  @override
  String get allCategories => 'All Categories';

  @override
  String get allColors => 'All Colors';

  @override
  String get allFabrics => 'All Fabrics';

  @override
  String get allStockLevels => 'All Stock Levels';

  @override
  String get inStockHigh => 'In Stock (High)';

  @override
  String get mediumStock => 'Medium Stock';

  @override
  String get minPrice => 'Min Price';

  @override
  String get maxPrice => 'Max Price';

  @override
  String get noLimit => 'No limit';

  @override
  String get sortBy => 'Sort By';

  @override
  String get dateCreated => 'Date Created';

  @override
  String get dateUpdated => 'Date Updated';

  @override
  String get sortOrder => 'Sort Order';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get minPriceCannotBeGreaterThanMax => 'Minimum price cannot be greater than maximum price';

  @override
  String get filtersAppliedSuccessfully => 'Filters applied successfully';

  @override
  String get filtersCleared => 'Filters cleared';

  @override
  String get enterProductName => 'Enter product name';

  @override
  String get enterProductDetails => 'Enter product details';

  @override
  String get enterPrice => 'Enter price';

  @override
  String get enterQuantity => 'Enter quantity';

  @override
  String get enterColor => 'Enter color';

  @override
  String get enterFabric => 'Enter fabric';

  @override
  String get enterMinPrice => 'Enter minimum price';

  @override
  String get enterVendorName => 'Enter vendor name';

  @override
  String get enterBusinessName => 'Enter business name';

  @override
  String get enterCnicNumber => 'Enter CNIC number';

  @override
  String get enterPhoneWithCode => 'Enter phone (+92XXXXXXXXXX)';

  @override
  String get enterFullAddress => 'Enter full address';

  @override
  String get enterCustomerName => 'Enter customer name';

  @override
  String get enterCustomerFullName => 'Enter customer\'s full name';

  @override
  String get enterCustomerPhone => 'Enter customer phone number';

  @override
  String get enterCustomerEmail => 'Enter customer email address';

  @override
  String get enterCustomerAddress => 'Enter customer address';

  @override
  String get enterCustomerCity => 'Enter customer city';

  @override
  String get enterCustomerCountry => 'Enter customer country';

  @override
  String get enterCustomerBusinessName => 'Enter customer business name';

  @override
  String get enterCustomerTaxNumber => 'Enter customer tax or NTN number';

  @override
  String get enterCustomerNotes => 'Enter customer notes';

  @override
  String get enterAdditionalNotes => 'Enter additional notes';

  @override
  String get addZakat => 'Add Zakat';

  @override
  String get addNewZakatRecord => 'Add New Zakat Record';

  @override
  String get recordYourZakatContribution => 'Record your zakat contribution';

  @override
  String get titleOptional => 'Title (Optional)';

  @override
  String get enterTitle => 'Enter title';

  @override
  String get enterZakatContributionTitle => 'Enter zakat contribution title';

  @override
  String get enterDescription => 'Enter description';

  @override
  String get enterDescriptionPurposeOfZakat => 'Enter description/purpose of zakat';

  @override
  String get pleaseEnterDescription => 'Please enter description';

  @override
  String get descriptionMustBeAtLeast5Characters => 'Description must be at least 5 characters';

  @override
  String get amountPkr => 'Amount (PKR)';

  @override
  String get enterZakatAmountInPkr => 'Enter zakat amount in PKR';

  @override
  String get pleaseEnterValidAmountGreaterThanZero => 'Please enter a valid amount greater than zero';

  @override
  String get beneficiaryName => 'Beneficiary Name';

  @override
  String get enterBeneficiaryName => 'Enter beneficiary name';

  @override
  String get enterNameOfRecipientBeneficiary => 'Enter name of recipient/beneficiary';

  @override
  String get pleaseEnterBeneficiaryName => 'Please enter beneficiary name';

  @override
  String get beneficiaryNameMustBeAtLeast2Characters => 'Beneficiary name must be at least 2 characters';

  @override
  String get beneficiaryContactOptional => 'Beneficiary Contact (Optional)';

  @override
  String get enterContact => 'Enter contact';

  @override
  String get enterBeneficiaryContactNumber => 'Enter beneficiary contact number';

  @override
  String get authorizedBy => 'Authorized By';

  @override
  String get selectAuthorizingPerson => 'Select authorizing person';

  @override
  String get pleaseSelectAuthorizedPerson => 'Please select an authorized person';

  @override
  String get dateAndTime => 'Date & Time';

  @override
  String get at => 'at';

  @override
  String get additionalNotesOptional => 'Additional Notes (Optional)';

  @override
  String get enterNotes => 'Enter notes';

  @override
  String get enterAdditionalNotesOrReligiousConsiderations => 'Enter additional notes or religious considerations';

  @override
  String get addZakatRecord => 'Add Zakat Record';

  @override
  String get zakatRecordAddedSuccessfully => 'Zakat record added successfully!';

  @override
  String get failedToAddZakatRecord => 'Failed to add zakat record';

  @override
  String get zakatContribution => 'Zakat Contribution';

  @override
  String get zakatId => 'Zakat ID';

  @override
  String get title => 'Title';

  @override
  String get beneficiary => 'Beneficiary';

  @override
  String get authority => 'Authority';

  @override
  String get noNotes => 'No notes';

  @override
  String showingZakatRecords(int start, int end, int total) {
    return 'Showing $start-$end of $total zakat records';
  }

  @override
  String pageOfPages(int current, int total) {
    return '$current of $total';
  }

  @override
  String get filterZakatRecords => 'Filter Zakat Records';

  @override
  String get refineYourZakatList => 'Refine your zakat list with filters';

  @override
  String get searchZakatRecords => 'Search Zakat Records';

  @override
  String get recordStatus => 'Record Status';

  @override
  String get authorizationAuthority => 'Authorization Authority';

  @override
  String get dateRange => 'Date Range';

  @override
  String get searchByNameDescriptionBeneficiaryOrNotes => 'Search by name, description, beneficiary, or notes';

  @override
  String get showInactiveRecordsOnly => 'Show inactive records only';

  @override
  String get onlyDeactivatedZakatRecordsWillBeShown => 'Only deactivated zakat records will be shown';

  @override
  String get selectAuthorizationAuthority => 'Select Authorization Authority';

  @override
  String get clearAuthorityFilter => 'Clear Authority Filter';

  @override
  String get selectDateRange => 'Select Date Range';

  @override
  String get noDateRangeSelected => 'No date range selected';

  @override
  String get clearDateRange => 'Clear Date Range';

  @override
  String get selectStartDate => 'Select Start Date';

  @override
  String get selectEndDate => 'Select End Date';

  @override
  String get failedToLoadZakatRecords => 'Failed to Load Zakat Records';

  @override
  String get noZakatRecordsFound => 'No Zakat Records Found';

  @override
  String get startByAddingFirstZakatRecord => 'Start by adding your first zakat record to track your contributions effectively';

  @override
  String get addFirstZakatRecord => 'Add First Zakat Record';

  @override
  String get archived => 'Archived';

  @override
  String get verified => 'Verified';

  @override
  String get zakatDetails => 'Zakat Details';

  @override
  String get viewCompleteZakatContributionInformation => 'View complete zakat contribution information';

  @override
  String get zakatTitle => 'Zakat Title';

  @override
  String get zakatAmount => 'Zakat Amount';

  @override
  String get contributionAmount => 'Contribution Amount';

  @override
  String get beneficiaryInformation => 'Beneficiary Information';

  @override
  String get time => 'Time';

  @override
  String get descriptionAndPurpose => 'Description & Purpose';

  @override
  String get authorizationAndStatus => 'Authorization & Status';

  @override
  String get editZakat => 'Edit Zakat';

  @override
  String get editZakatRecord => 'Edit Zakat Record';

  @override
  String get updateZakatInformation => 'Update zakat information';

  @override
  String get pleaseEnterTitle => 'Please enter title';

  @override
  String get zakatRecordUpdatedSuccessfully => 'Zakat record updated successfully!';

  @override
  String get failedToUpdateZakatRecord => 'Failed to update zakat record';

  @override
  String get updateZakat => 'Update Zakat';

  @override
  String get deleteZakat => 'Delete Zakat';

  @override
  String get deleteZakatRecord => 'Delete Zakat Record';

  @override
  String get zakatRecordDeletedSuccessfully => 'Zakat record deleted successfully!';

  @override
  String get failedToDeleteZakatRecord => 'Failed to delete zakat record';

  @override
  String get areYouSureYouWantToDeleteThisZakatRecord => 'Are you sure you want to delete this zakat record?';

  @override
  String get areYouAbsolutelySureYouWantToDeleteThisZakatRecord => 'Are you absolutely sure you want to delete this zakat record?';

  @override
  String get thisWillPermanentlyDeleteTheZakatRecord => 'This will permanently delete the zakat record.';

  @override
  String get thisWillPermanentlyDeleteTheZakatRecordAndAllAssociatedData => 'This will permanently delete the zakat record and all associated data. This action cannot be undone.';

  @override
  String get calculationSummary => 'Calculation Summary';

  @override
  String get costOfGoods => 'Cost of Goods';

  @override
  String get totalSalesRevenueForThePeriod => 'Total sales revenue for the period';

  @override
  String get directCostsOfProductsSold => 'Direct costs of products sold';

  @override
  String get incomeMinusCostOfGoodsSold => 'Income minus cost of goods sold';

  @override
  String get finalProfitAfterAllExpenses => 'Final profit after all expenses';

  @override
  String get totalSalesRevenue => 'Total sales revenue';

  @override
  String get directCosts => 'Direct costs';

  @override
  String get incomeMinusCogs => 'Income - COGS';

  @override
  String get finalProfit => 'Final profit';

  @override
  String get sourceRecordsBreakdown => 'Source Records Breakdown';

  @override
  String get salesRecords => 'Sales Records';

  @override
  String get laborPayments => 'Employee Payments';

  @override
  String get notAvailable => 'N/A';

  @override
  String get vendorPayments => 'Vendor Payments';

  @override
  String get otherExpenses => 'Other Expenses';

  @override
  String get labor => 'Employee';

  @override
  String get vendors => 'Vendors';

  @override
  String get calculationFormula => 'Calculation Formula';

  @override
  String get stepOneGrossProfit => '1. Gross Profit';

  @override
  String get stepTwoTotalExpenses => '2. Total Expenses';

  @override
  String get laborPlusVendorPlusOtherPlusZakat => 'Employee + Vendor + Other + Zakat';

  @override
  String get stepThreeNetProfit => '3. Net Profit';

  @override
  String get grossProfitMinusTotalExpenses => 'Gross Profit - Total Expenses';

  @override
  String get grossProfitMargin => 'Gross Profit Margin';

  @override
  String get grossProfitDivideIncomeMultiply100 => 'Gross Profit / Income × 100';

  @override
  String get netProfitMargin => 'Net Profit Margin';

  @override
  String get netProfitDivideIncomeMultiply100 => 'Net Profit / Income × 100';

  @override
  String get periodInformation => 'Period Information';

  @override
  String get periodType => 'Period Type';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get noCalculationDataAvailable => 'No Calculation Data Available';

  @override
  String get calculationDetailsWillAppearHere => 'Calculation details will appear here once profit and loss data is available';

  @override
  String get loadingDashboardData => 'Loading dashboard data...';

  @override
  String get salesGrowth => 'Sales Growth';

  @override
  String get expenseGrowth => 'Expense Growth';

  @override
  String get profitGrowth => 'Profit Growth';

  @override
  String get increased => 'Increased';

  @override
  String get decreased => 'Decreased';

  @override
  String get noChange => 'No Change';

  @override
  String get currentMonth => 'Current Month';

  @override
  String get previousMonth => 'Previous Month';

  @override
  String get current => 'Current';

  @override
  String get previous => 'Previous';

  @override
  String get businessTrends => 'Business Trends';

  @override
  String get salesTrend => 'Sales Trend';

  @override
  String get profitTrend => 'Profit Trend';

  @override
  String get increasing => 'Increasing';

  @override
  String get decreasing => 'Decreasing';

  @override
  String get stable => 'Stable';

  @override
  String get income => 'Income';

  @override
  String get grossProfit => 'Gross Profit';

  @override
  String get netProfit => 'Net Profit';

  @override
  String get profit => 'Profit';

  @override
  String get exportFormat => 'Export Format';

  @override
  String get chooseTheFormatForYourProfitAndLossReport => 'Choose the format for your Profit & Loss report:';

  @override
  String get pdfReport => 'PDF Report';

  @override
  String get professionalDocumentWithChartsAndFormatting => 'Professional document with charts and formatting';

  @override
  String get excelSpreadsheet => 'Excel Spreadsheet';

  @override
  String get dataInSpreadsheetFormatForAnalysis => 'Data in spreadsheet format for analysis';

  @override
  String get profitMargin => 'Profit Margin';

  @override
  String get netLoss => 'Net Loss';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get custom => 'Custom';

  @override
  String get applyRange => 'Apply Range';

  @override
  String get productProfitabilityAnalysis => 'Product Profitability Analysis';

  @override
  String analyzingProductsAcrossDifferentCategories(int count) {
    return 'Analyzing $count products across different categories';
  }

  @override
  String productsCount(int count) {
    return '$count Products';
  }

  @override
  String get rank => 'Rank';

  @override
  String get unitsSold => 'Units Sold';

  @override
  String get marginPercent => 'Margin %';

  @override
  String get sortDescending => 'Sort Descending';

  @override
  String get sortAscending => 'Sort Ascending';

  @override
  String get summaryStatistics => 'Summary Statistics';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get totalProfit => 'Total Profit';

  @override
  String get totalCost => 'Total Cost';

  @override
  String get avgProfitMargin => 'Avg Profit Margin';

  @override
  String get profitableProducts => 'Profitable Products';

  @override
  String get units => 'Units';

  @override
  String get loadingProductData => 'Loading Product Data...';

  @override
  String get pleaseWaitWhileWeFetchTheLatestProfitabilityInformation => 'Please wait while we fetch the latest profitability information.';

  @override
  String get errorLoadingData => 'Error Loading Data';

  @override
  String get anUnexpectedErrorOccurredWhileLoadingProductData => 'An unexpected error occurred while loading product data.';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get productProfitabilityDataIsBeingLoaded => 'Product profitability data is being loaded.\nThis includes revenue, costs, profit margins, and rankings.';

  @override
  String get refreshData => 'Refresh Data';

  @override
  String get addPayable => 'Add Payable';

  @override
  String get addNewPayable => 'Add New Payable';

  @override
  String get recordAmountOwedToCreditor => 'Record amount owed to creditor';

  @override
  String get creditorInformation => 'Creditor Information';

  @override
  String get creditorName => 'Creditor Name';

  @override
  String get enterCreditorFullName => 'Enter creditor full name';

  @override
  String get pleaseEnterCreditorName => 'Please enter creditor name';

  @override
  String get enterPhoneNumberWithFormat => 'Enter phone number (+92XXXXXXXXXX)';

  @override
  String get pleaseEnterAValidPhoneNumber => 'Please enter a valid phone number';

  @override
  String get emailOptional => 'Email (Optional)';

  @override
  String get enterCreditorEmailAddress => 'Enter creditor email address';

  @override
  String get amountBorrowedPKR => 'Amount Borrowed (PKR)';

  @override
  String get enterAmountBorrowedFromCreditor => 'Enter amount borrowed from creditor';

  @override
  String get pleaseEnterAmountBorrowed => 'Please enter amount borrowed';

  @override
  String get pleaseEnterAValidAmount => 'Please enter a valid amount';

  @override
  String get amountPaidPKR => 'Amount Paid (PKR)';

  @override
  String get optionalIfAnyAmountAlreadyPaid => 'Optional - if any amount already paid';

  @override
  String get cannotExceedAmountBorrowed => 'Cannot exceed amount borrowed';

  @override
  String get additionalDetails => 'Additional Details';

  @override
  String get enterReasonForBorrowingOrItemDescription => 'Enter reason for borrowing or item description';

  @override
  String get pleaseEnterReasonOrItemDescription => 'Please enter reason or item description';

  @override
  String get vendorOptional => 'Vendor (Optional)';

  @override
  String get selectVendorIfCreditorIsARegisteredVendor => 'Select vendor if creditor is a registered vendor';

  @override
  String get noVendor => 'No vendor';

  @override
  String get priorityLevel => 'Priority Level';

  @override
  String get selectPriorityLevelForThisPayable => 'Select priority level for this payable';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get urgent => 'Urgent';

  @override
  String get enterAdditionalNotesOrPaymentHistory => 'Enter additional notes or payment history';

  @override
  String get dateBorrowed => 'Date Borrowed';

  @override
  String get expectedRepaymentDate => 'Expected Repayment Date';

  @override
  String get selectBorrowedDate => 'Select Borrowed Date';

  @override
  String get selectExpectedRepaymentDate => 'Select Expected Repayment Date';

  @override
  String borrowingPeriodDays(int days) {
    return 'Borrowing period: $days days';
  }

  @override
  String get pleaseSelectAValidRepaymentDate => 'Please select a valid repayment date';

  @override
  String get expectedRepaymentDateCannotBeBeforeDateBorrowed => 'Expected repayment date cannot be before date borrowed';

  @override
  String get failedToAddPayablePleaseTryAgain => 'Failed to add payable. Please try again.';

  @override
  String get payableAddedSuccessfully => 'Payable added successfully!';

  @override
  String get enterReason => 'Enter reason';

  @override
  String get deletePayable => 'Delete Payable';

  @override
  String get deletePayableRecord => 'Delete Payable Record';

  @override
  String get areYouSureYouWantToDeleteThisPayable => 'Are you sure you want to delete this payable?';

  @override
  String get areYouAbsolutelySureYouWantToDeleteThisPayableRecord => 'Are you absolutely sure you want to delete this payable record?';

  @override
  String get amountBorrowed => 'Amount Borrowed';

  @override
  String get expectedRepayment => 'Expected Repayment';

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String get thisWillPermanentlyDeleteThePayableRecord => 'This will permanently delete the payable record.';

  @override
  String get thisWillPermanentlyDeleteThePayableRecordAndAllAssociatedData => 'This will permanently delete the payable record and all associated data. This action cannot be undone.';

  @override
  String get payableDeletedSuccessfully => 'Payable deleted successfully!';

  @override
  String get editPayable => 'Edit Payable';

  @override
  String get editPayableDetails => 'Edit Payable Details';

  @override
  String get updatePayableInformation => 'Update payable information';

  @override
  String get enterCreditorEmail => 'Enter creditor email';

  @override
  String get additionalAmountToPayPKR => 'Additional Amount to Pay (PKR)';

  @override
  String get enterAdditionalAmount => 'Enter additional amount';

  @override
  String get totalPaymentCannotExceedAmountBorrowed => 'Total payment cannot exceed amount borrowed';

  @override
  String get paymentSummary => 'Payment Summary';

  @override
  String get currentPaid => 'Current Paid';

  @override
  String get additionalPayment => 'Additional Payment';

  @override
  String get totalAfterUpdate => 'Total After Update';

  @override
  String get reasonForBorrowing => 'Reason for borrowing';

  @override
  String get updatePayable => 'Update Payable';

  @override
  String get amountPaidCannotExceedAmountBorrowed => 'Amount paid cannot exceed amount borrowed';

  @override
  String get payableUpdatedSuccessfully => 'Payable updated successfully!';

  @override
  String get payableId => 'Payable ID';

  @override
  String get creditor => 'Creditor';

  @override
  String showingPayableRecords(int start, int end, int total) {
    return 'Showing $start-$end of $total payable records';
  }

  @override
  String get priority => 'Priority';

  @override
  String get filterPayables => 'Filter Payables';

  @override
  String get applyFiltersToFindSpecificPayables => 'Apply filters to find specific payables';

  @override
  String get searchByCreditorNameReasonNotes => 'Search by creditor name, reason, notes...';

  @override
  String get statusAndPriority => 'Status & Priority';

  @override
  String get selectStatus => 'Select status';

  @override
  String get paidStatus => 'Paid';

  @override
  String get partiallyPaid => 'Partially Paid';

  @override
  String get selectPriority => 'Select priority';

  @override
  String get allPriorities => 'All Priorities';

  @override
  String get selectVendor => 'Select vendor';

  @override
  String get allVendors => 'All Vendors';

  @override
  String get dateRanges => 'Date Ranges';

  @override
  String get dueAfter => 'Due After';

  @override
  String get dueBefore => 'Due Before';

  @override
  String get borrowedAfter => 'Borrowed After';

  @override
  String get borrowedBefore => 'Borrowed Before';

  @override
  String get creditorDetails => 'Creditor Details';

  @override
  String get repaymentDate => 'Repayment Date';

  @override
  String pkrRemaining(String amount) {
    return 'PKR $amount remaining';
  }

  @override
  String daysOverdueCount(int count) {
    return '$count days overdue';
  }

  @override
  String get noPayablesFound => 'No Payables Found';

  @override
  String get startByAddingYourFirstPayableRecord => 'Start by adding your first payable record to track amounts borrowed from suppliers and creditors';

  @override
  String get addFirstPayable => 'Add First Payable';

  @override
  String get failedToLoadPayables => 'Failed to Load Payables';

  @override
  String get anUnexpectedErrorOccurred => 'An unexpected error occurred';

  @override
  String get startByAddingYourFirstPayableRecordToTrackYourBorrowingsEffectively => 'Start by adding your first payable record to track your borrowings effectively';

  @override
  String get addFirstPayableRecord => 'Add First Payable Record';

  @override
  String get fullyPaid => 'Fully Paid';

  @override
  String get pending => 'Pending';

  @override
  String get payableDetails => 'Payable Details';

  @override
  String get viewCompletePayableInformation => 'View complete payable information';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get amountPaid => 'Amount Paid';

  @override
  String get paymentProgress => 'Payment Progress';

  @override
  String get notUpdated => 'Not updated';

  @override
  String get productName => 'Product Name';

  @override
  String get costPrice => 'Cost Price';

  @override
  String get color => 'Color';

  @override
  String get fabric => 'Fabric';

  @override
  String get stockStatus => 'Stock Status';

  @override
  String get pieces => 'Pieces';

  @override
  String get createdDate => 'Created Date';

  @override
  String get noDetails => 'No details';

  @override
  String get noPieces => 'No pieces';

  @override
  String get noProductRecordsFound => 'No Product Records Found';

  @override
  String get startByAddingYourFirstProductToManageInventoryEfficiently => 'Start by adding your first product to manage inventory efficiently';

  @override
  String get addFirstProduct => 'Add First Product';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get oneWeekAgo => '1 week ago';

  @override
  String weeksAgo(int count) {
    return '$count weeks ago';
  }

  @override
  String get oneMonthAgo => '1 month ago';

  @override
  String monthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String get oneYearAgo => '1 year ago';

  @override
  String yearsAgo(int count) {
    return '$count years ago';
  }

  @override
  String get productDetails => 'Product Details';

  @override
  String get viewCompleteProductInformation => 'View complete product information';

  @override
  String get unnamedProduct => 'Unnamed Product';

  @override
  String get noDetailsProvided => 'No details provided';

  @override
  String get setCostPriceToCalculateProfitMargin => 'Set cost price to calculate profit margin';

  @override
  String unitsCount(int count) {
    return '$count units';
  }

  @override
  String get unknown => 'Unknown';

  @override
  String get productPieces => 'Product Pieces';

  @override
  String get noPiecesSpecified => 'No pieces specified';

  @override
  String get productActive => 'Product Active';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get editProductDetails => 'Edit Product Details';

  @override
  String get updateProductInformation => 'Update product information';

  @override
  String get productUpdatedSuccessfully => 'Product updated successfully!';

  @override
  String get failedToUpdateProduct => 'Failed to update product';

  @override
  String get productDetail => 'Product Detail';

  @override
  String get enterDetails => 'Enter details';

  @override
  String get enterProductDescriptionDetails => 'Enter product description/details';

  @override
  String get pleaseEnterProductDetails => 'Please enter product details';

  @override
  String get productDetailMustBeAtLeast5Characters => 'Product detail must be at least 5 characters';

  @override
  String get enterPricePkr => 'Enter price (PKR)';

  @override
  String get pleaseEnterPrice => 'Please enter price';

  @override
  String get pleaseEnterValidPrice => 'Please enter a valid price';

  @override
  String get enterCost => 'Enter cost';

  @override
  String get enterCostPricePkrOptional => 'Enter cost price (PKR) - Optional';

  @override
  String get pleaseEnterValidCostPrice => 'Please enter a valid cost price';

  @override
  String get enterQty => 'Enter qty';

  @override
  String get pleaseEnterQuantity => 'Please enter quantity';

  @override
  String get pleaseEnterValidQuantity => 'Please enter a valid quantity';

  @override
  String get loadingCategories => 'Loading categories...';

  @override
  String get noCategoriesAvailablePleaseAddCategoriesFirst => 'No categories available. Please add categories first.';

  @override
  String get noId => 'No ID';

  @override
  String get selectCategory => 'Select category';

  @override
  String get selectProductCategory => 'Select product category';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get enterColorName => 'Enter color name (e.g., Red, Blue, Turquoise)';

  @override
  String get pleaseEnterColor => 'Please enter a color';

  @override
  String get colorNameMustBeAtLeast2Characters => 'Color name must be at least 2 characters';

  @override
  String get enterFabricType => 'Enter fabric type (e.g., Cotton, Silk, Chiffon)';

  @override
  String get pleaseEnterFabric => 'Please enter a fabric';

  @override
  String get fabricNameMustBeAtLeast2Characters => 'Fabric name must be at least 2 characters';

  @override
  String get productNameMustBeAtLeast2Characters => 'Product name must be at least 2 characters';

  @override
  String get pleaseEnterProductName => 'Please enter a product name';

  @override
  String get updateProduct => 'Update Product';

  @override
  String get addPayment => 'Add Payment';

  @override
  String get addLaborPayment => 'Add Employee Payment';

  @override
  String get recordNewPaymentWithReceipt => 'Record new payment to employee with receipt';

  @override
  String get paymentAddedSuccessfully => 'Payment added successfully!';

  @override
  String get pleaseSelectAtLeastOneEntity => 'Please select at least one entity (employee, vendor, order, or sale)';

  @override
  String get pleaseSelectPaymentMethod => 'Please select a payment method';

  @override
  String get pleaseSelectPaymentMonth => 'Please select a payment month';

  @override
  String netAmountCannotExceedRemaining(String amount) {
    return 'Net amount cannot exceed remaining amount of PKR $amount';
  }

  @override
  String get paymentAmount => 'Payment Amount';

  @override
  String get paymentDetails => 'Payment Details';

  @override
  String get receiptImageOptional => 'Receipt Image (Optional)';

  @override
  String get uploadReceiptForBetterRecordKeeping => 'Upload receipt image for better record keeping';

  @override
  String get entityType => 'Entity Type';

  @override
  String get selectEntityType => 'Select entity type';

  @override
  String get pleaseSelectEntityType => 'Please select entity type';

  @override
  String get selectLabor => 'Select Employee';

  @override
  String get chooseLaborForPayment => 'Choose employee for payment';

  @override
  String get pleaseSelectLabor => 'Please select a employee';

  @override
  String get vendorId => 'Vendor ID';

  @override
  String get pleaseEnterVendorId => 'Please enter vendor ID';

  @override
  String get customerType => 'Customer Type';

  @override
  String get selectCustomerType => 'Select customer type';

  @override
  String get order => 'Order';

  @override
  String get sale => 'Sale';

  @override
  String enterOrderSaleId(String type) {
    return 'Enter $type ID';
  }

  @override
  String get paymentMonth => 'Payment Month';

  @override
  String get selectPaymentMonth => 'Select payment month';

  @override
  String get paymentAmountPkr => 'Payment Amount (PKR)';

  @override
  String get enterPaymentAmountPkr => 'Enter payment amount (PKR)';

  @override
  String get pleaseEnterPaymentAmount => 'Please enter payment amount';

  @override
  String get bonusPkr => 'Bonus (PKR)';

  @override
  String get optionalBonus => 'Optional bonus';

  @override
  String get pleaseEnterValidBonusAmount => 'Please enter a valid bonus amount';

  @override
  String get deductionPkr => 'Deduction (PKR)';

  @override
  String get optionalDeduction => 'Optional deduction';

  @override
  String get pleaseEnterValidDeductionAmount => 'Please enter a valid deduction amount';

  @override
  String get enterPaymentDescriptionOrNotes => 'Enter payment description or notes';

  @override
  String get selectTime => 'Select time';

  @override
  String get finalPaymentForMonth => 'Final Payment for Month';

  @override
  String get thisCompletesPaymentForSelectedMonth => 'This completes the payment for the selected month';

  @override
  String get markThisAsFinalPaymentForMonth => 'Mark this as the final payment for the month';

  @override
  String get netPaymentAmount => 'Net Payment Amount';

  @override
  String remainingAfterPayment(String amount) {
    return 'Remaining after payment: PKR $amount';
  }

  @override
  String get paymentReceiptOptional => 'Payment Receipt (Optional)';

  @override
  String get selectPaymentMethod => 'Select payment method';

  @override
  String get enter => 'Enter';

  @override
  String get editPayment => 'Edit Payment';

  @override
  String get editPaymentDetails => 'Edit Payment Details';

  @override
  String get updatePaymentInformation => 'Update payment information';

  @override
  String get paymentUpdatedSuccessfully => 'Payment updated successfully!';

  @override
  String netAmountCannotExceedAvailable(String amount) {
    return 'Net amount cannot exceed available amount of PKR $amount';
  }

  @override
  String get selectLaborForPayment => 'Select employee for payment';

  @override
  String get available => 'Available';

  @override
  String get enterValidBonus => 'Enter valid bonus';

  @override
  String get enterValidDeduction => 'Enter valid deduction';

  @override
  String get netAmount => 'Net Amount';

  @override
  String get receiptImageSelected => 'Receipt image selected';

  @override
  String get tapToSelectReceiptImage => 'Tap to select receipt image';

  @override
  String get updatePayment => 'Update Payment';

  @override
  String get paymentId => 'Payment ID';

  @override
  String get desc => 'Desc';

  @override
  String get noDescription => 'No description';

  @override
  String get net => 'Net';

  @override
  String get paymentFilters => 'Payment Filters';

  @override
  String get searchByLaborVendorDescription => 'Search by employee name, vendor, description...';

  @override
  String get entityFilters => 'Entity Filters';

  @override
  String get allLabors => 'All Employees';

  @override
  String get payerType => 'Payer Type';

  @override
  String get selectPayerType => 'Select payer type';

  @override
  String get allTypes => 'All Types';

  @override
  String get allMethods => 'All Methods';

  @override
  String get finalPayment => 'Final Payment';

  @override
  String get selectFinalPaymentStatus => 'Select final payment status';

  @override
  String get finalOnly => 'Final Only';

  @override
  String get partialOnly => 'Partial Only';

  @override
  String get hasReceipt => 'Has Receipt';

  @override
  String get selectReceiptStatus => 'Select receipt status';

  @override
  String get withReceipt => 'With Receipt';

  @override
  String get withoutReceipt => 'Without Receipt';

  @override
  String get selectVisibility => 'Select visibility';

  @override
  String get showAll => 'Show All';

  @override
  String get activeOnly => 'Active Only';

  @override
  String get paymentDateFrom => 'Payment Date From';

  @override
  String get paymentDateTo => 'Payment Date To';

  @override
  String get paymentMonthFrom => 'Payment Month From';

  @override
  String get paymentMonthTo => 'Payment Month To';

  @override
  String get amountRangePkr => 'Amount Range (PKR)';

  @override
  String get minimumAmount => 'Minimum Amount';

  @override
  String get maximumAmount => 'Maximum Amount';

  @override
  String get selectSortField => 'Select sort field';

  @override
  String get paymentDate => 'Payment Date';

  @override
  String get laborName => 'Employee Name';

  @override
  String get selectSortOrder => 'Select sort order';

  @override
  String get receiptImage => 'Receipt Image';

  @override
  String get paymentReceipt => 'Payment Receipt';

  @override
  String get baseAmount => 'Base Amount';

  @override
  String get bonus => 'Bonus';

  @override
  String get deduction => 'Deduction';

  @override
  String get noReceiptAvailable => 'No Receipt Available';

  @override
  String get noReceiptAvailableShort => 'No receipt available. Add one for better records.';

  @override
  String get noReceiptAvailableLong => 'No receipt image was uploaded for this payment. Consider adding a receipt for better record keeping.';

  @override
  String get addReceiptImage => 'Add Receipt Image';

  @override
  String get receiptUploadedSaveToUpdate => 'Receipt uploaded! Please save the payment to update.';

  @override
  String get paymentInfo => 'Payment Info';

  @override
  String get receipt => 'Receipt';

  @override
  String get missing => 'Missing';

  @override
  String get viewReceipt => 'View Receipt';

  @override
  String get addReceipt => 'Add Receipt';

  @override
  String get noPaymentRecordsFound => 'No Payment Records Found';

  @override
  String get startByAddingFirstPaymentRecord => 'Start by adding your first payment record to track employee payments efficiently';

  @override
  String get addFirstPayment => 'Add First Payment';

  @override
  String get failedToLoadPayments => 'Failed to Load Payments';

  @override
  String get noPaymentsFound => 'No Payments Found';

  @override
  String get startByAddingFirstPaymentToTrack => 'Start by adding your first payment record to track your transactions effectively';

  @override
  String get withBonus => 'With Bonus';

  @override
  String get withDeduction => 'With Deduction';

  @override
  String get purchases => 'Purchases';

  @override
  String get regularPayment => 'Regular Payment';

  @override
  String get viewPaymentDetails => 'View Payment Details';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get paymentInformation => 'Payment Information';

  @override
  String get payerInformation => 'Payer Information';

  @override
  String get payerId => 'Payer ID';

  @override
  String get orderId => 'Order ID';

  @override
  String get saleId => 'Sale ID';

  @override
  String get isFinalPayment => 'Is Final Payment';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get systemInformation => 'System Information';

  @override
  String get amountIsRequired => 'Amount is required';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get paymentMethodIsRequired => 'Payment method is required';

  @override
  String get payerTypeIsRequired => 'Payer type is required';

  @override
  String get receiptAvailable => 'Receipt Available';

  @override
  String get failedToUpdatePayment => 'Failed to update payment';

  @override
  String get errorUpdatingPayment => 'Error updating payment';

  @override
  String get january => 'January';

  @override
  String get february => 'February';

  @override
  String get march => 'March';

  @override
  String get april => 'April';

  @override
  String get may => 'May';

  @override
  String get june => 'June';

  @override
  String get july => 'July';

  @override
  String get august => 'August';

  @override
  String get september => 'September';

  @override
  String get october => 'October';

  @override
  String get november => 'November';

  @override
  String get december => 'December';

  @override
  String get viewPaymentDetailsAndReceipt => 'View payment details and receipt';

  @override
  String get addReceiptForThisPayment => 'Add receipt for this payment';

  @override
  String get laborRole => 'Employee Role';

  @override
  String get laborPhone => 'Employee Phone';

  @override
  String get paymentDeletedSuccessfully => 'Payment deleted successfully!';

  @override
  String get deletePayment => 'Delete Payment';

  @override
  String get deletePaymentRecord => 'Delete Payment Record';

  @override
  String get areYouSureDeletePayment => 'Are you sure you want to delete this payment?';

  @override
  String get areYouAbsolutelySureDeletePayment => 'Are you absolutely sure you want to delete this payment record?';

  @override
  String get thisWillPermanentlyDeletePayment => 'This will permanently delete the payment record.';

  @override
  String get thisWillPermanentlyDeletePaymentLong => 'This will permanently delete the payment record and all associated data. This action cannot be undone.';

  @override
  String get failedToDeleteProduct => 'Failed to delete product';

  @override
  String get productDeletedPermanently => 'Product deleted permanently!';

  @override
  String get productDeactivatedSuccessfully => 'Product deactivated successfully!';

  @override
  String get productCanBeRestoredLater => 'Product can be restored later';

  @override
  String get completelyRemovesFromDatabase => 'Completely removes from database';

  @override
  String get hidesButCanBeRestored => 'Hides but can be restored';

  @override
  String get totalInventoryValue => 'Total Inventory Value';

  @override
  String get iUnderstandPermanentDelete => 'I understand this will permanently delete the product and cannot be undone';

  @override
  String get iUnderstandDeactivate => 'I understand this will deactivate the product';

  @override
  String get deactivateProduct => 'Deactivate Product';

  @override
  String get editOrder => 'Edit Order';

  @override
  String get updateOrderInformation => 'Update order information';

  @override
  String get orderUpdatedSuccessfully => 'Order updated successfully!';

  @override
  String get orderUpdateFailed => 'Order Update Failed';

  @override
  String get invalidStatusTransition => 'Invalid Status Transition';

  @override
  String get cannotChangeStatusFrom => 'You cannot change the status from';

  @override
  String get validNextStatusesAre => 'Valid next statuses are';

  @override
  String get ok => 'OK';

  @override
  String get serverErrorOccurred => 'Server error occurred. Please try again or contact support.';

  @override
  String get invalidStatusSelected => 'Invalid status selected. Please choose a valid status.';

  @override
  String get invalidDateFormat => 'Invalid date format. Please select a valid delivery date.';

  @override
  String get deliveryDateCannotBeBeforeOrderDate => 'Delivery date cannot be before the order date.';

  @override
  String get advancePaymentCannotExceedTotal => 'Advance payment cannot exceed the total order amount.';

  @override
  String get orderCannotBeModified => 'This order cannot be modified in its current status.';

  @override
  String get orderCannotHaveStatusChanged => 'This order cannot have its status changed.';

  @override
  String get invalidStatusTransitionFrom => 'Invalid status transition. From';

  @override
  String get youCanOnlyChangeTo => 'you can only change to';

  @override
  String get customerInformation => 'Customer Information';

  @override
  String get customerSince => 'Customer since';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get orderDescription => 'Order Description';

  @override
  String get describeOrderDetails => 'Describe the order details (e.g., products, specifications)';

  @override
  String get pleaseEnterOrderDescription => 'Please enter order description';

  @override
  String get descriptionMustBeAtLeast10Characters => 'Description must be at least 10 characters';

  @override
  String get descriptionMustBeLessThan500Characters => 'Description must be less than 500 characters';

  @override
  String get orderStatus => 'Order Status';

  @override
  String get currentStatus => 'Current Status';

  @override
  String get validNextStatuses => 'Valid next statuses';

  @override
  String get totalAmountPKR => 'Total Amount (PKR)';

  @override
  String get totalOrderAmount => 'Total order amount';

  @override
  String get advancePaymentPKR => 'Advance Payment (PKR)';

  @override
  String get enterAdvancePaymentAmount => 'Enter advance payment amount';

  @override
  String get pleaseEnterAdvancePayment => 'Please enter advance payment';

  @override
  String get remainingAmountPKR => 'Remaining Amount (PKR)';

  @override
  String get remainingAmountToBePaid => 'Remaining amount to be paid';

  @override
  String get deliveryInformation => 'Delivery Information';

  @override
  String get orderDate => 'Order Date';

  @override
  String get dateWhenOrderWasPlaced => 'Date when order was placed';

  @override
  String get selectExpectedDeliveryDate => 'Select Expected Delivery Date';

  @override
  String get expectedDelivery => 'Expected Delivery';

  @override
  String get updateOrder => 'Update Order';

  @override
  String get inProduction => 'In Production';

  @override
  String get ready => 'Ready';

  @override
  String get orderItemsManagement => 'Order Items Management';

  @override
  String get searchOrderItemsByProductDescriptionOrNotes => 'Search order items by product, description, or notes...';

  @override
  String get addItem => 'Add Item';

  @override
  String get totalItems => 'Total Items';

  @override
  String get activeItems => 'Active Items';

  @override
  String get totalQuantity => 'Total Quantity';

  @override
  String get loadingOrderItems => 'Loading order items...';

  @override
  String get errorLoadingOrderItems => 'Error Loading Order Items';

  @override
  String get noOrderItemsFound => 'No Order Items Found';

  @override
  String get orderDoesntHaveItemsYet => 'This order doesn\'t have any items yet. Add your first order item to get started.';

  @override
  String get addFirstItem => 'Add First Item';

  @override
  String get activeSearch => 'Active Search';

  @override
  String get clearSearch => 'Clear Search';

  @override
  String get orderItemsRefreshedSuccessfully => 'Order items refreshed successfully';

  @override
  String get advancePaymentCannotBeNegative => 'Advance payment cannot be negative';

  @override
  String get orderID => 'Order ID';

  @override
  String get delivery => 'Delivery';

  @override
  String get noPhone => 'No phone';

  @override
  String get item => 'item';

  @override
  String get noItems => 'No items';

  @override
  String get addItemsToSeeTotal => 'Add items to see total';

  @override
  String get noDate => 'No date';

  @override
  String get errorDisplayingOrder => 'Error displaying order';

  @override
  String get confirmOrder => 'Confirm Order';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get startProduction => 'Start Production';

  @override
  String get markAsReady => 'Mark as Ready';

  @override
  String get markAsDelivered => 'Mark as Delivered';

  @override
  String get changeOrderStatus => 'Change Order Status';

  @override
  String get areYouSureChangeStatusTo => 'Are you sure you want to change the status of order';

  @override
  String get changeStatus => 'Change Status';

  @override
  String get failedToUpdateOrderStatus => 'Failed to update order status';

  @override
  String get orderStatusUpdatedTo => 'Order status updated to';

  @override
  String get successfully => 'successfully';

  @override
  String get deactivateOrder => 'Deactivate Order';

  @override
  String get areYouSureDeactivateOrder => 'Are you sure you want to deactivate order';

  @override
  String get thisActionCanBeReversed => 'This action can be reversed.';

  @override
  String get failedToDeactivateOrder => 'Failed to deactivate order';

  @override
  String get orderDeactivatedSuccessfully => 'Order deactivated successfully';

  @override
  String get restoreOrder => 'Restore Order';

  @override
  String get areYouSureRestoreOrder => 'Are you sure you want to restore order';

  @override
  String get failedToRestoreOrder => 'Failed to restore order';

  @override
  String get orderRestoredSuccessfully => 'Order restored successfully';

  @override
  String get failedToLoadOrders => 'Failed to Load Orders';

  @override
  String get noOrdersFound => 'No Orders Found';

  @override
  String get startManagingCustomerOrders => 'Start managing your customer orders by creating your first order. Track deliveries, manage payments, and keep customers informed.';

  @override
  String get createNewOrder => 'Create New Order';

  @override
  String get noOrdersMatchSearch => 'No orders match your search criteria';

  @override
  String get tryAdjustingSearchTerms => 'Try adjusting your search terms or filters to find what you\'re looking for.';

  @override
  String get selectProduct => 'Select Product';

  @override
  String get selectProductForOrder => 'Select Product for Order';

  @override
  String get chooseProductToAddToOrder => 'Choose a product to add to the order';

  @override
  String get pleaseSelectProduct => 'Please select a product';

  @override
  String get searchProductsShort => 'Search products';

  @override
  String get searchProductsByNameFabricOrColor => 'Search products by name, fabric, or color...';

  @override
  String get availableProducts => 'Available Products';

  @override
  String get tryAdjustingYourSearchTerms => 'Try adjusting your search terms';

  @override
  String get selectedProductDetails => 'Selected Product Details';

  @override
  String get customizationNotesOptional => 'Customization Notes (Optional)';

  @override
  String get specialInstructionsOrCustomizationNotes => 'Special instructions or customization notes';

  @override
  String get notesMustBeLessThan500Characters => 'Notes must be less than 500 characters';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get quantityMustBeGreaterThanZero => 'Quantity must be greater than 0';

  @override
  String get only => 'Only';

  @override
  String get unitsAvailable => 'units available';

  @override
  String get addToOrder => 'Add to Order';

  @override
  String get viewOrder => 'View Order';

  @override
  String get completeOrderInformation => 'Complete order information';

  @override
  String get orderInformation => 'Order Information';

  @override
  String get paymentPercentage => 'Payment Percentage';

  @override
  String get orderItemsManagedSeparately => 'Order items are managed separately. Use the Order Items module to view and manage products in this order.';

  @override
  String get daysSinceOrdered => 'Days Since Ordered';

  @override
  String get daysUntilDelivery => 'Days Until Delivery';

  @override
  String get isOverdue => 'Is Overdue';

  @override
  String get conversionStatus => 'Conversion Status';

  @override
  String get convertedSalesAmount => 'Converted Sales Amount';

  @override
  String get conversionDate => 'Conversion Date';

  @override
  String get isActive => 'Is Active';

  @override
  String get createdAt => 'Created At';

  @override
  String get customerName => 'Customer Name';

  @override
  String get editLabor => 'Edit Employee';

  @override
  String get editLaborDetails => 'Edit Employee Details';

  @override
  String get updateWorkerInformation => 'Update worker information';

  @override
  String get laborUpdatedSuccessfully => 'Employee updated successfully!';

  @override
  String get failedToUpdateLabor => 'Failed to update employee';

  @override
  String get errorUpdatingLabor => 'Error updating employee';

  @override
  String get updateLabor => 'Update Employee';

  @override
  String get enterWorkerFullName => 'Enter worker\'s full name';

  @override
  String get enterCNIC => 'Enter CNIC';

  @override
  String get enterCNICFormat => 'Enter CNIC (e.g., 42101-1234567-1)';

  @override
  String get pleaseEnterCNIC => 'Please enter a CNIC';

  @override
  String get pleaseEnterValidCNIC => 'Please enter a valid CNIC (XXXXX-XXXXXXX-X)';

  @override
  String get enterMonthlySalaryInPKR => 'Enter monthly salary in PKR';

  @override
  String get laborCanBeRestoredLater => 'Employee can be restored later';

  @override
  String get laborID => 'Employee ID';

  @override
  String get iUnderstandActionCannotBeUndone => 'I understand this action cannot be undone and will affect related records';

  @override
  String get typeLaborNameToConfirm => 'Type the employee name to confirm permanent deletion:';

  @override
  String get laborDeletedPermanently => 'Employee deleted permanently!';

  @override
  String get failedToDeleteLabor => 'Failed to delete employee';

  @override
  String get pleaseConfirmYouUnderstandThisAction => 'Please confirm that you understand this action';

  @override
  String get pleaseConfirmYouUnderstandConsequences => 'Please confirm that you understand the consequences of permanent deletion';

  @override
  String get pleaseTypeLaborNameExactly => 'Please type the employee name exactly to confirm permanent deletion';

  @override
  String get pleaseCompleteAllConfirmationSteps => 'Please complete all confirmation steps';

  @override
  String get country => 'Country';

  @override
  String get pleaseTryAgainOrContactSupport => 'Please try again later or contact support.';

  @override
  String get failedToDeleteCategory => 'Failed to delete category';

  @override
  String get categoryDeletedPermanently => 'Category deleted permanently!';

  @override
  String get categoryDeactivatedSuccessfully => 'Category deactivated successfully!';

  @override
  String get deactivateCategory => 'Deactivate Category';

  @override
  String get categoryCanBeRestoredLater => 'Category can be restored later';

  @override
  String get iUnderstandPermanentDeleteCategory => 'I understand this will permanently delete the category and cannot be undone';

  @override
  String get iUnderstandDeactivateCategory => 'I understand this will deactivate the category';

  @override
  String get categoryUpdatedSuccessfully => 'Category updated successfully!';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get updateCategoryInformation => 'Update category information';

  @override
  String get categoryName => 'Category Name';

  @override
  String get enterCategoryName => 'Enter category name';

  @override
  String get enterCategoryNameHint => 'Enter category name (e.g., Bridal Dresses)';

  @override
  String get pleaseEnterCategoryName => 'Please enter a category name';

  @override
  String get categoryNameMinLength => 'Category name must be at least 2 characters';

  @override
  String get categoryNameMaxLength => 'Category name must be less than 50 characters';

  @override
  String get enterDescriptionOptional => 'Enter description (optional)';

  @override
  String get enterCategoryDescriptionOptional => 'Enter category description (optional)';

  @override
  String get descriptionMaxLength => 'Description must be less than 200 characters';

  @override
  String get updateCategory => 'Update Category';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get searchPlaceholder => 'Search products, orders, customers...';

  @override
  String get addNew => 'Add New';

  @override
  String get completed => 'Completed';

  @override
  String get inProgress => 'In Progress';

  @override
  String get lastSixMonthsPerformance => 'Last 6 months performance';

  @override
  String get sixMonths => '6M';

  @override
  String get target => 'Target';

  @override
  String get activeProducts => 'Active Products';

  @override
  String get dailySales => 'Daily Sales';

  @override
  String get monthlySales => 'Monthly Sales';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get addNewExpense => 'Add New Expense';

  @override
  String get recordNewExpenseEntry => 'Record a new expense entry';

  @override
  String get enterExpense => 'Enter expense';

  @override
  String get enterExpenseTypeCategory => 'Enter expense type/category';

  @override
  String get pleaseEnterExpenseType => 'Please enter expense type';

  @override
  String get expenseMinLength => 'Expense must be at least 2 characters';

  @override
  String get enterExpenseDescription => 'Enter expense description/details';

  @override
  String get descriptionMinLength => 'Description must be at least 5 characters';

  @override
  String get enterAmountPKR => 'Enter amount (PKR)';

  @override
  String get withdrawalBy => 'Withdrawal By';

  @override
  String get selectWhoMadeWithdrawal => 'Select who made the withdrawal';

  @override
  String get pleaseSelectWhoMadeWithdrawal => 'Please select who made the withdrawal';

  @override
  String get selectDateTime => 'Select Date & Time';

  @override
  String get selectExpenseDateTime => 'Select Expense Date & Time';

  @override
  String get expenseAddedSuccessfully => 'Expense added successfully!';

  @override
  String get deleteExpense => 'Delete Expense';

  @override
  String get deleteExpenseRecord => 'Delete Expense Record';

  @override
  String get confirmDeleteExpenseShort => 'Are you sure you want to delete this expense record?';

  @override
  String get confirmDeleteExpenseLong => 'Are you absolutely sure you want to delete this expense record?';

  @override
  String get deleteWarningShort => 'This will permanently delete the expense record.';

  @override
  String get deleteWarningLong => 'This will permanently delete the expense record and all associated data. This action cannot be undone.';

  @override
  String get expenseDeletedSuccessfully => 'Expense deleted successfully!';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get editExpenseRecord => 'Edit Expense Record';

  @override
  String get updateExpenseInformation => 'Update expense information';

  @override
  String get updateExpense => 'Update Expense';

  @override
  String get expenseUpdatedSuccessfully => 'Expense updated successfully!';

  @override
  String get pleaseAcceptTerms => 'Please accept the terms and conditions';

  @override
  String get accountCreatedSuccessfully => 'Account created successfully! Welcome to Al Noor.';

  @override
  String get registrationFailedMessage => 'Registration failed. Please check the details below.';

  @override
  String get joinOur => 'Join Our';

  @override
  String get premiumFamily => 'Premium Family';

  @override
  String get signupWelcomeMessage => 'Begin your journey with us and discover the epitome of luxury fashion. \nCreate your account to access exclusive collections and personalized service.';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinExclusiveCommunity => 'Join our exclusive community';

  @override
  String get enterYourFullName => 'Enter your full name';

  @override
  String get pleaseEnterFullName => 'Please enter your full name';

  @override
  String get nameMinLength => 'Name must be at least 2 characters';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get createStrongPassword => 'Create a strong password';

  @override
  String get pleaseEnterPassword => 'Please enter a password';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get passwordMustContain => 'Password must contain uppercase, lowercase, and number';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get reenterPassword => 'Re-enter your password';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get iAgreeToThe => 'I agree to the ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get and => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get registrationFailed => 'Registration Failed';

  @override
  String get alreadyHaveAccount => 'Already have account?';

  @override
  String get filterExpenseRecords => 'Filter Expense Records';

  @override
  String get refineExpenseList => 'Refine your expense list with filters';

  @override
  String get searchExpenseRecords => 'Search Expense Records';

  @override
  String get searchByExpenseHint => 'Search by expense name, description, or amount';

  @override
  String get expenseCategory => 'Expense Category';

  @override
  String get enterExpenseCategory => 'Enter expense category';

  @override
  String get selectWithdrawalAuthority => 'Select Withdrawal Authority';

  @override
  String get clearWithdrawalFilter => 'Clear Withdrawal Filter';

  @override
  String get expenseId => 'Expense ID';

  @override
  String get noExpenseRecordsFound => 'No Expense Records Found';

  @override
  String get startAddingFirstExpense => 'Start by adding your first expense record to track business spending';

  @override
  String get addFirstExpense => 'Add First Expense';

  @override
  String get errorLoadingExpenses => 'Error loading expenses';

  @override
  String get pleaseTryAgainLater => 'Please try again later or check your internet connection.';

  @override
  String get retryLoading => 'Retry Loading';

  @override
  String get expenseDetails => 'Expense Details';

  @override
  String get viewCompleteExpenseInfo => 'View complete expense information';

  @override
  String get amountInformation => 'Amount Information';

  @override
  String get withdrawalInformation => 'Withdrawal Information';

  @override
  String get expenseDescription => 'Expense Description';

  @override
  String get recordCreated => 'Record Created:';

  @override
  String get expenseRecord => 'Expense Record';

  @override
  String get hour => 'Hour';

  @override
  String get minute => 'Minute';

  @override
  String get selected => 'Selected';

  @override
  String get open => 'Open';

  @override
  String get explorer => 'Explorer';

  @override
  String get copy => 'Copy';

  @override
  String get remove => 'Remove';

  @override
  String get viewImage => 'View Image';

  @override
  String get invalidImageFile => 'Invalid image file. Please select a valid image (max 10MB).';

  @override
  String get receiptUploadedSuccessfully => 'Receipt image uploaded successfully!';

  @override
  String get failedToUploadImage => 'Failed to upload image';

  @override
  String get receiptImageRemoved => 'Receipt image removed';

  @override
  String get failedToOpenImage => 'Failed to open image';

  @override
  String get failedToShowInExplorer => 'Failed to show in explorer';

  @override
  String get imageCopiedToClipboard => 'Image copied to clipboard!';

  @override
  String get failedToCopyToClipboard => 'Failed to copy to clipboard';

  @override
  String get clickToSelectReceiptImage => 'Click to select receipt image';

  @override
  String get supportedFormats => 'Supported formats: JPG, PNG, BMP, GIF (max 10MB)';

  @override
  String get supportedFormatsShort => 'JPG, PNG, BMP, GIF (max 10MB)';

  @override
  String get browseFiles => 'Browse Files';

  @override
  String get processingImageFile => 'Processing image file...';

  @override
  String get openingFileDialog => 'Opening file dialog...';

  @override
  String get validatingImageFile => 'Validating image file...';

  @override
  String get savingToAppDirectory => 'Saving to application directory...';

  @override
  String get finalizing => 'Finalizing...';

  @override
  String get replaceImage => 'Replace Image';

  @override
  String get replace => 'Replace';

  @override
  String get file => 'File';

  @override
  String get size => 'Size';

  @override
  String get added => 'Added';

  @override
  String get loadingFileInfo => 'Loading file info...';

  @override
  String get receiptImageViewer => 'Receipt Image Viewer';

  @override
  String get openInExternalViewer => 'Open in External Viewer';

  @override
  String get showInExplorer => 'Show in Explorer';

  @override
  String get copyToClipboard => 'Copy to Clipboard';

  @override
  String get failedToOpen => 'Failed to open';

  @override
  String get failedToCopy => 'Failed to copy';

  @override
  String get loadingImage => 'Loading image...';

  @override
  String get failedToLoadImage => 'Failed to load image';

  @override
  String get openWithExternalViewer => 'Open with External Viewer';

  @override
  String get failed => 'Failed';

  @override
  String get removeImage => 'Remove Image';

  @override
  String get viewFullScreen => 'View Full Screen';

  @override
  String get processing => 'Processing...';

  @override
  String get tapToChangeImage => 'Tap to change image';

  @override
  String get tapToAddImage => 'Tap to add image';

  @override
  String get supports => 'Supports';

  @override
  String get max => 'Max';

  @override
  String get fileSizeMustBeLessThan => 'File size must be less than';

  @override
  String get errorPickingImage => 'Error picking image';

  @override
  String get realTimeInventory => 'Real-Time Inventory';

  @override
  String get refreshInventory => 'Refresh Inventory';

  @override
  String get noStockInformationAvailable => 'No stock information available';

  @override
  String get stockInformation => 'Stock Information';

  @override
  String get unknownProduct => 'Unknown Product';

  @override
  String get allProductsHaveSufficientStock => 'All products have sufficient stock';

  @override
  String get lowStockAlerts => 'Low Stock Alerts';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get critical => 'CRITICAL';

  @override
  String get currentStock => 'Current Stock';

  @override
  String get refreshStock => 'Refresh Stock';

  @override
  String get viewAlerts => 'View Alerts';

  @override
  String get noLowStockAlertsAtThisTime => 'No low stock alerts at this time.';

  @override
  String get addNewOrderItem => 'Add New Order Item';

  @override
  String get productNameIsRequired => 'Product name is required';

  @override
  String get customizationNotes => 'Customization Notes';

  @override
  String get quantityIsRequired => 'Quantity is required';

  @override
  String get unitPriceIsRequired => 'Unit price is required';

  @override
  String get addOrderItem => 'Add Order Item';

  @override
  String get pleaseSelectAnOrder => 'Please select an order';

  @override
  String get pleaseSelectAProduct => 'Please select a product';

  @override
  String get orderItemCreatedSuccessfully => 'Order item created successfully';

  @override
  String get failedToCreateOrderItem => 'Failed to create order item';

  @override
  String get selectOrder => 'Select Order';

  @override
  String get typeCustomerNameToSearch => 'Type customer name to search...';

  @override
  String get searchByCustomerName => 'Search by customer name...';

  @override
  String get typeProductNameToSearch => 'Type product name to search...';

  @override
  String get searchByProductName => 'Search by product name...';

  @override
  String get selectAnOrder => 'Select an order...';

  @override
  String get selectAProduct => 'Select a product...';

  @override
  String get deleteOrderItem => 'Delete Order Item';

  @override
  String get removeThisOrderItemPermanently => 'Remove this order item permanently';

  @override
  String get orderItemDeletedSuccessfully => 'Order item deleted successfully!';

  @override
  String get failedToDeleteOrderItem => 'Failed to delete order item';

  @override
  String get irreversibleAction => 'Irreversible Action';

  @override
  String get deleteWarningMessage => 'This action will permanently delete the order item and cannot be undone. Please review the details below before proceeding.';

  @override
  String get orderItemSummary => 'Order Item Summary';

  @override
  String get productId => 'Product ID';

  @override
  String get lineTotal => 'Line Total';

  @override
  String get impactAnalysis => 'Impact Analysis';

  @override
  String get financialImpact => 'Financial Impact';

  @override
  String willBeRemovedFromOrderTotal(String amount) {
    return '$amount will be removed from order total';
  }

  @override
  String get inventoryImpact => 'Inventory Impact';

  @override
  String quantityWillBeAffected(int quantity) {
    return 'Quantity $quantity will be affected';
  }

  @override
  String get salesImpact => 'Sales Impact';

  @override
  String get itemHasBeenSoldWarning => 'This item has been sold and deletion may affect sales records';

  @override
  String get finalConfirmation => 'Final Confirmation';

  @override
  String get areYouSureDeleteOrderItem => 'Are you absolutely sure you want to delete this order item?';

  @override
  String get deleteOrderItemWarningPoints => '• This action cannot be undone\n• All associated data will be permanently removed\n• This may affect order totals and inventory\n• Consider archiving instead if you need to preserve records';

  @override
  String get editOrderItem => 'Edit Order Item';

  @override
  String get updateOrderItemInformation => 'Update order item information';

  @override
  String get changingOrderNotAllowed => 'Changing the order is not allowed. Please create a new order item instead.';

  @override
  String get changingProductNotAllowed => 'Changing the product is not allowed. Please create a new order item instead.';

  @override
  String get orderItemUpdatedSuccessfully => 'Order item updated successfully!';

  @override
  String get failedToUpdateOrderItem => 'Failed to update order item';

  @override
  String get productInformation => 'Product Information';

  @override
  String get orderItemDetails => 'Order Item Details';

  @override
  String get quantityMustBePositive => 'Quantity must be a positive number';

  @override
  String get unitPricePKR => 'Unit Price (PKR)';

  @override
  String get enterUnitPrice => 'Enter unit price';

  @override
  String get pleaseEnterUnitPrice => 'Please enter unit price';

  @override
  String get unitPriceMustBePositive => 'Unit price must be a positive number';

  @override
  String get enterCustomizationNotes => 'Enter any customization notes or special requirements';

  @override
  String get notesMustBeLessThan500 => 'Notes must be less than 500 characters';

  @override
  String get updateOrderItem => 'Update Order Item';

  @override
  String get orderItemFilters => 'Order Item Filters';

  @override
  String get customizeOrderItemSearch => 'Customize your order item search and filtering';

  @override
  String get activeFilters => 'Active Filters';

  @override
  String get basicFilters => 'Basic Filters';

  @override
  String get allOrders => 'All Orders';

  @override
  String get allProducts => 'All Products';

  @override
  String get searchAndTextFilters => 'Search & Text Filters';

  @override
  String get searchQuery => 'Search Query';

  @override
  String get searchInProductNames => 'Search in product names, customization notes, or IDs';

  @override
  String get numericRangeFilters => 'Numeric Range Filters';

  @override
  String get minQuantity => 'Min Quantity';

  @override
  String get minimumQuantity => 'Minimum quantity';

  @override
  String maxQuantity(int max) {
    return 'Max Quantity';
  }

  @override
  String get maximumQuantity => 'Maximum quantity';

  @override
  String get minPricePKR => 'Min Price (PKR)';

  @override
  String get minimumUnitPrice => 'Minimum unit price';

  @override
  String get maxPricePKR => 'Max Price (PKR)';

  @override
  String get maximumUnitPrice => 'Maximum unit price';

  @override
  String get dateAndStatusFilters => 'Date & Status Filters';

  @override
  String get dateFrom => 'Date From';

  @override
  String get dateTo => 'Date To';

  @override
  String get showInactiveItems => 'Show Inactive Items';

  @override
  String get hasCustomizationNotes => 'Has Customization Notes';

  @override
  String get sortingOptions => 'Sorting Options';

  @override
  String get updatedDate => 'Updated Date';

  @override
  String get areYouSureYouWantTo => 'Are you sure you want to';

  @override
  String get areYouSureYouWantToCreateACopyOf => 'Are you sure you want to create a copy of';

  @override
  String get failedToUpdateItemStatus => 'Failed to update item status';

  @override
  String get activatedSuccessfully => 'activated successfully';

  @override
  String get failedToDuplicateItem => 'Failed to duplicate item';

  @override
  String get orderItemDuplicatedSuccessfully => 'Order item duplicated successfully';

  @override
  String get orderItemDetailsExportedSuccessfully => 'Order item details exported successfully';

  @override
  String get failedToExport => 'Failed to export';

  @override
  String get failedToLoadOrderItems => 'Failed to Load Order Items';

  @override
  String get startManagingYourOrderItems => 'Start managing your order items by adding products to track inventory, pricing, and customizations for customer orders.';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get orderItem => 'Order Item';

  @override
  String get viewOrderItem => 'View Order Item';

  @override
  String get completeOrderItemInformation => 'Complete order item information';

  @override
  String get orderItemId => 'Order Item ID';

  @override
  String get productInfo => 'Product Info';

  @override
  String get noAdditionalProductDetailsAvailable => 'No additional product details available';

  @override
  String get activeStatus => 'Active Status';

  @override
  String get soldStatus => 'Sold Status';

  @override
  String get remainingToSell => 'Remaining to Sell';

  @override
  String get timestamps => 'Timestamps';

  @override
  String get updatedAt => 'Updated At';

  @override
  String get noCustomizationNotesAvailable => 'No customization notes available';

  @override
  String get brand => 'Brand';

  @override
  String get material => 'Material';

  @override
  String get style => 'Style';

  @override
  String get noAdditionalDetails => 'No additional details';

  @override
  String get additionalProductInformationAvailable => 'Additional product information available';

  @override
  String get addedToCart => 'added to cart';

  @override
  String stockAvailable(int quantity) {
    return 'Stock';
  }

  @override
  String get min => 'Min';

  @override
  String get customPrice => 'Custom Price';

  @override
  String get customPricePkr => 'Custom Price (PKR)';

  @override
  String get itemDiscountOptional => 'Item Discount (Optional)';

  @override
  String clearDiscount(String amount) {
    return 'Clear Discount';
  }

  @override
  String get specialInstructions => 'Special Instructions';

  @override
  String get anySpecialRequirements => 'Any special requirements, alterations, or notes...';

  @override
  String get checkoutAndPayment => 'Checkout & Payment';

  @override
  String get completeTheSaleTransaction => 'Complete the sale transaction';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get credit => 'Credit';

  @override
  String get split => 'Split';

  @override
  String get splitPaymentDetails => 'Split Payment Details';

  @override
  String get cashAmount => 'Cash Amount';

  @override
  String get cardAmount => 'Card Amount';

  @override
  String get bankTransferAmount => 'Bank Transfer Amount';

  @override
  String get pleaseEnterAmountPaid => 'Please enter amount paid';

  @override
  String get change => 'Change';

  @override
  String get hideAdvancedOptions => 'Hide Advanced Options';

  @override
  String get showAdvancedOptions => 'Show Advanced Options';

  @override
  String get advancedOptions => 'Advanced Options';

  @override
  String get overallDiscountPkr => 'Overall Discount (PKR)';

  @override
  String get gstPercentage => 'GST Percentage (%)';

  @override
  String get additionalTax => 'Additional Tax (%)';

  @override
  String get anySpecialInstructionsOrRemarks => 'Any special instructions or remarks...';

  @override
  String get completeSale => 'Complete Sale';

  @override
  String get saleCompleted => 'Sale Completed!';

  @override
  String get transactionProcessedSuccessfully => 'Transaction processed successfully';

  @override
  String get invoiceNumber => 'Invoice Number';

  @override
  String get printFunctionalityToBeImplemented => 'Print functionality to be implemented';

  @override
  String get printReceipt => 'Print Receipt';

  @override
  String get newSale => 'New Sale';

  @override
  String get navigateToSalesManagementToContinue => 'Navigate to Sales Management to continue';

  @override
  String get createNewInvoice => 'Create New Invoice';

  @override
  String get selectSaleRequired => 'Select Sale *';

  @override
  String get chooseASaleToCreateInvoiceFor => 'Choose a sale to create invoice for';

  @override
  String get pleaseSelectASale => 'Please select a sale';

  @override
  String get dueDateRequired => 'Due Date *';

  @override
  String get selectDueDate => 'Select due date';

  @override
  String get additionalInvoiceNotesOptional => 'Additional invoice notes (optional)';

  @override
  String get termsAndConditions => 'Terms & Conditions';

  @override
  String get invoiceTermsAndConditions => 'Invoice terms and conditions';

  @override
  String get standardTermsAndConditionsApply => 'Standard terms and conditions apply';

  @override
  String get createInvoice => 'Create Invoice';

  @override
  String get invoiceCreatedSuccessfully => 'Invoice created successfully';

  @override
  String get failedToCreateInvoice => 'Failed to create invoice';

  @override
  String get receiptManagement => 'Receipt Management';

  @override
  String get pleaseSelectALabor => 'Please select an employee';

  @override
  String get amountCannotExceedRemainingAdvanceAmount => 'Amount cannot exceed remaining advance amount of';

  @override
  String get failedToAddAdvancePayment => 'Failed to add advance payment';

  @override
  String get advancePaymentAddedSuccessfully => 'Advance payment added successfully';

  @override
  String get selectDateAndTime => 'Select Date & Time';

  @override
  String get uploadReceiptImageForBetterRecordKeeping => 'Upload receipt image for better record keeping';

  @override
  String get selectALabor => 'Select an employee';

  @override
  String get advanceAmountPkr => 'Advance Amount (PKR)';

  @override
  String get enterAdvanceAmountPkr => 'Enter advance amount (PKR)';

  @override
  String get pleaseEnterAdvanceAmount => 'Please enter advance amount';

  @override
  String get amountExceedsRemainingSalary => 'Amount exceeds remaining monthly salary';

  @override
  String get enterReasonForAdvancePayment => 'Enter reason for advance payment';

  @override
  String get salaryCalculation => 'Salary Calculation';

  @override
  String get originalSalary => 'Original Salary';

  @override
  String get currentMonthAdvances => 'Current Month Advances';

  @override
  String get remainingForMonth => 'Remaining for Month';

  @override
  String get newAdvance => 'New Advance';

  @override
  String get afterAdvance => 'After Advance';

  @override
  String get filterAdvancePayments => 'Filter Advance Payments';

  @override
  String get applyFiltersToFindSpecificAdvancePayments => 'Apply filters to find specific advance payments';

  @override
  String get searchAdvancePayments => 'Search advance payments...';

  @override
  String get allLaborers => 'All Employeeers';

  @override
  String get receiptAndSorting => 'Receipt & Sorting';

  @override
  String get showInactiveRecords => 'Show Inactive Records';

  @override
  String showingAdvancePayments(Object end, Object start, Object total) {
    return 'Showing $start-$end of $total advance payments';
  }

  @override
  String get failedToLoadAdvancePayments => 'Failed to Load Advance Payments';

  @override
  String get noAdvancePaymentRecordsFound => 'No Advance Payment Records Found';

  @override
  String get startByAddingYourFirstAdvancePaymentRecord => 'Start by adding your first advance payment record to track employee payments effectively';

  @override
  String get addFirstAdvancePayment => 'Add First Advance Payment';

  @override
  String get highAmount => 'High Amount';

  @override
  String get failedToDeleteAdvancePayment => 'Failed to delete advance payment';

  @override
  String get advancePaymentDeletedSuccessfully => 'Advance payment deleted successfully!';

  @override
  String get deleteAdvancePayment => 'Delete Advance Payment';

  @override
  String get areYouSureDeleteThisPayment => 'Are you sure you want to delete this payment?';

  @override
  String get areYouAbsolutelySureDeleteAdvancePayment => 'Are you absolutely sure you want to delete this advance payment record?';

  @override
  String get thisWillPermanentlyDeleteThePaymentRecord => 'This will permanently delete the payment record.';

  @override
  String get thisWillPermanentlyDeleteAdvancePaymentRecord => 'This will permanently delete the advance payment record and all associated data. This action cannot be undone.';

  @override
  String get amountIncreaseCannotExceedRemainingAdvanceAmount => 'Amount increase cannot exceed remaining advance amount of';

  @override
  String get advancePaymentUpdatedSuccessfully => 'Advance payment updated successfully!';

  @override
  String get editAdvancePayment => 'Edit Advance Payment';

  @override
  String get laborInformation => 'Employee Information';

  @override
  String get advancePaymentDetails => 'Advance Payment Details';

  @override
  String get viewCompletePaymentInformation => 'View complete payment information';

  @override
  String get role => 'Role';

  @override
  String get advanceAmount => 'Advance Amount';

  @override
  String get paymentDescription => 'Payment Description';

  @override
  String get receiptInformation => 'Receipt Information';

  @override
  String get receiptImageAvailable => 'Receipt image available';

  @override
  String get salaryInformation => 'Salary Information';

  @override
  String get totalSalary => 'Total Salary';

  @override
  String get viewReceiptDetailsAndImage => 'View receipt details and image';

  @override
  String get recurringExpense => 'Recurring Expense';

  @override
  String get deductFromSalary => 'Deduct from Salary';

  @override
  String get selectEmployeeForDeduction => 'Select employee for deduction';

  @override
  String get ofSalary => 'of salary';

  @override
  String get used => 'used';

  @override
  String get receiptImagePreview => 'Receipt Image Preview';

  @override
  String get receiptUploadFunctionalityToBeImplemented => 'Receipt upload functionality to be implemented';

  @override
  String get areYouSureLogoutFromYourAccount => 'Are you sure you want to logout from your account?';

  @override
  String get forgotPasswordComingSoon => 'Forgot password feature coming soon!';

  @override
  String get successfullyLoggedOutSeeSoon => 'Successfully logged out. See you soon!';

  @override
  String get loggedOutLocallyDueToError => 'Logged out locally due to an error.';

  @override
  String get createNewReceipt => 'Create New Receipt';

  @override
  String get chooseASaleToCreateReceiptFor => 'Choose a sale to create receipt for';

  @override
  String get additionalReceiptNotesOptional => 'Additional receipt notes (optional)';

  @override
  String get failedToCreateReceipt => 'Failed to create receipt';

  @override
  String get addPrincipalAccountEntry => 'Add Principal Account Entry';

  @override
  String get recordANewLedgerTransaction => 'Record a new ledger transaction';

  @override
  String get sourceModule => 'Source Module';

  @override
  String get pleaseSelectSourceModule => 'Please select source module';

  @override
  String get transactionType => 'Transaction Type';

  @override
  String get pleaseSelectTransactionType => 'Please select transaction type';

  @override
  String get creditMoneyIn => 'Credit (Money In)';

  @override
  String get debitMoneyOut => 'Debit (Money Out)';

  @override
  String get sourceID => 'Source ID';

  @override
  String get referenceIDOptional => 'Reference ID (optional)';

  @override
  String get referenceIDFromSourceModuleOptional => 'Reference ID from source module (optional)';

  @override
  String get enterTransactionDescription => 'Enter transaction description';

  @override
  String get enterTransactionAmountPKR => 'Enter transaction amount (PKR)';

  @override
  String get handledByOptional => 'Handled By (Optional)';

  @override
  String get selectTransactionDateTime => 'Select Transaction Date & Time';

  @override
  String get additionalNotesOrDetailsOptional => 'Additional notes or details (optional)';

  @override
  String get principalAccountEntryAddedSuccessfully => 'Principal account entry added successfully!';

  @override
  String get principalAccountDetails => 'Principal Account Details';

  @override
  String get viewCompleteTransactionInformation => 'View complete transaction information';

  @override
  String get sourceModuleInformation => 'Source Module Information';

  @override
  String get module => 'Module';

  @override
  String get balanceInformation => 'Balance Information';

  @override
  String get balanceAfterTransaction => 'Balance After Transaction';

  @override
  String get handlerInformation => 'Handler Information';

  @override
  String get transactionDescription => 'Transaction Description';

  @override
  String get ledgerEntry => 'Ledger Entry';

  @override
  String get transactions => 'Transactions';

  @override
  String get entryID => 'Entry ID';

  @override
  String get balanceAfter => 'Balance After';

  @override
  String get handledBy => 'Handled By';

  @override
  String get exportAccountEntry => 'Export account entry';

  @override
  String get noPrincipalAccountRecordsFound => 'No Principal Account Records Found';

  @override
  String get startByAddingYourFirstPrincipalAccountEntry => 'Start by adding your first principal account entry to track all cash movements';

  @override
  String get addFirstEntry => 'Add First Entry';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get editPrincipalAccountEntry => 'Edit Principal Account Entry';

  @override
  String get updateTransactionInformation => 'Update transaction information';

  @override
  String get updateEntry => 'Update Entry';

  @override
  String get principalAccountEntryUpdatedSuccessfully => 'Principal account entry updated successfully!';

  @override
  String get deleteEntry => 'Delete Entry';

  @override
  String get deletePrincipalAccountEntry => 'Delete Principal Account Entry';

  @override
  String get areYouSureYouWantToDeleteThisEntry => 'Are you sure you want to delete this principal account entry?';

  @override
  String get areYouAbsolutelySureYouWantToDeleteThisEntry => 'Are you absolutely sure you want to delete this principal account entry?';

  @override
  String get thisWillPermanentlyDeleteTheEntry => 'This will permanently delete the principal account entry and affect balance calculations.';

  @override
  String get thisWillPermanentlyDeleteTheEntryFull => 'This will permanently delete the principal account entry and may affect balance calculations. This action cannot be undone.';

  @override
  String get principalAccountEntryDeletedSuccessfully => 'Principal account entry deleted successfully!';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get aboutApp => 'About App';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get enableDarkThemeForApplication => 'Enable dark theme for the application';

  @override
  String get alNoorFashionPOS => 'Al Noor POS';

  @override
  String get version => 'Version';

  @override
  String get aPremiumPointOfSaleSolution => 'A premium point of sale solution designed for fashion retail businesses. Manage your inventory, customers, and sales with elegance.';

  @override
  String get createNewReturn => 'Create New Return';

  @override
  String get enterSaleId => 'Enter sale ID';

  @override
  String get saleIdRequired => 'Sale ID is required';

  @override
  String get customerId => 'Customer ID';

  @override
  String get enterCustomerId => 'Enter customer ID';

  @override
  String get customerIdRequired => 'Customer ID is required';

  @override
  String get returnReason => 'Return Reason';

  @override
  String get selectReason => 'Select a reason';

  @override
  String get reasonDefective => 'Defective Product';

  @override
  String get reasonWrongSize => 'Wrong Size';

  @override
  String get reasonWrongColor => 'Wrong Color';

  @override
  String get reasonQualityIssue => 'Quality Issue';

  @override
  String get reasonChangeMind => 'Customer Changed Mind';

  @override
  String get reasonDamagedTransit => 'Damaged in Transit';

  @override
  String get reasonOther => 'Other';

  @override
  String get selectReturnReason => 'Please select a return reason';

  @override
  String get reasonDetails => 'Reason Details';

  @override
  String get specifyReason => 'Please specify the reason';

  @override
  String get provideReasonDetails => 'Please provide reason details';

  @override
  String get returnItems => 'Return Items';

  @override
  String get noItemsAdded => 'No return items added';

  @override
  String get clickAddItem => 'Click \"Add Item\" to add items to return';

  @override
  String get removeItem => 'Remove Item';

  @override
  String get saleItemId => 'Sale Item ID';

  @override
  String get enterSaleItemId => 'Enter sale item ID';

  @override
  String get saleItemIdRequired => 'Sale item ID is required';

  @override
  String get quantityRequired => 'Quantity is required';

  @override
  String get quantityPositive => 'Quantity must be a positive number';

  @override
  String get condition => 'Condition';

  @override
  String get selectCondition => 'Select condition';

  @override
  String get conditionNew => 'New';

  @override
  String get conditionGood => 'Good';

  @override
  String get conditionFair => 'Fair';

  @override
  String get conditionPoor => 'Poor';

  @override
  String get conditionDamaged => 'Damaged';

  @override
  String get selectConditionError => 'Please select condition';

  @override
  String get conditionNotes => 'Condition Notes';

  @override
  String get conditionNotesHint => 'Additional notes about condition';

  @override
  String get notesHint => 'Any additional notes about the return';

  @override
  String get createReturn => 'Create Return';

  @override
  String get addOneItem => 'Please add at least one return item';

  @override
  String get createdSuccessfully => 'Return created successfully';

  @override
  String get failedToCreate => 'Failed to create return';

  @override
  String errorCreating(String error) {
    return 'Error creating return: $error';
  }

  @override
  String get none => 'None';

  @override
  String get red => 'Red';

  @override
  String get blue => 'Blue';

  @override
  String get green => 'Green';

  @override
  String get purple => 'Purple';

  @override
  String get pink => 'Pink';

  @override
  String get orange => 'Orange';

  @override
  String get customizeAndAdd => 'Customize & Add';

  @override
  String customizedAddedToCart(String productName) {
    return 'Customized $productName added to cart';
  }

  @override
  String get quantityAndPricing => 'Quantity & Pricing';

  @override
  String get enterValidPrice => 'Please enter a valid price';

  @override
  String get sizeAndFitting => 'Size & Fitting';

  @override
  String get fitting => 'Fitting';

  @override
  String get fittingStyle => 'Fitting Style';

  @override
  String get customizationOptions => 'Customization Options';

  @override
  String get embroideryWork => 'Embroidery Work';

  @override
  String get embroidery => 'Embroidery';

  @override
  String get fabricQuality => 'Fabric Quality';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get additionalServices => 'Additional Services';

  @override
  String get expressDelivery => 'Express Delivery';

  @override
  String get expressDeliveryDesc => 'Get your order in 2-3 days (+PKR 1,000)';

  @override
  String get expressDeliveryRequired => 'Express Delivery Required';

  @override
  String get giftWrapping => 'Gift Wrapping';

  @override
  String get giftWrappingDesc => 'Beautiful gift packaging (+PKR 500)';

  @override
  String get giftWrappingRequired => 'Gift Wrapping Required';

  @override
  String get additionalRequirements => 'Additional Requirements';

  @override
  String get additionalRequirementsHint => 'Any special requirements, measurements, design preferences, or delivery instructions...';

  @override
  String basePriceQuantity(int quantity) {
    return 'Base Price × $quantity:';
  }

  @override
  String get customSizeLabel => 'Custom Size';

  @override
  String get customTailoring => 'Custom Tailoring';

  @override
  String get slimFit => 'Slim Fit';

  @override
  String get subtotalWithCustomizations => 'Subtotal with Customizations:';

  @override
  String get itemDiscount => 'Item Discount:';

  @override
  String youSave(String amount) {
    return 'You save PKR $amount';
  }

  @override
  String get deleteSale => 'Delete Sale';

  @override
  String get deleteSaleRecord => 'Delete Sale Record';

  @override
  String get areYouSureDeleteSale => 'Are you sure you want to delete this sale?';

  @override
  String get areYouAbsolutelySure => 'Are you absolutely sure you want to delete this sale record?';

  @override
  String get permanentDeleteWarningShort => 'This will permanently delete the sale record and all associated data.';

  @override
  String get permanentDeleteWarningLong => 'This will permanently delete the sale record, payment information, and all associated data. This action cannot be undone.';

  @override
  String get deleting => 'Deleting...';

  @override
  String get deleteSaleButton => 'Delete Sale';

  @override
  String get saleDeletedSuccessfully => 'Sale record deleted successfully!';

  @override
  String get editInvoice => 'Edit Invoice';

  @override
  String editInvoiceWithNumber(String invoiceNumber) {
    return 'Edit Invoice - $invoiceNumber';
  }

  @override
  String get statusRequired => 'Status *';

  @override
  String get selectInvoiceStatus => 'Select invoice status';

  @override
  String get pleaseSelectStatus => 'Please select a status';

  @override
  String get clearDueDate => 'Clear due date';

  @override
  String get additionalInvoiceNotes => 'Additional invoice notes (optional)';

  @override
  String get invoiceTermsConditions => 'Invoice terms and conditions';

  @override
  String get standardTermsConditions => 'Standard terms and conditions apply';

  @override
  String get updateInvoice => 'Update Invoice';

  @override
  String get invoiceUpdatedSuccessfully => 'Invoice updated successfully';

  @override
  String get failedToUpdateInvoice => 'Failed to update invoice';

  @override
  String get editReceipt => 'Edit Receipt';

  @override
  String editReceiptWithNumber(String receiptNumber) {
    return 'Edit Receipt - $receiptNumber';
  }

  @override
  String get failedToUpdateReceipt => 'Failed to update receipt';

  @override
  String get editSale => 'Edit Sale';

  @override
  String get editSaleDetails => 'Edit Sale Details';

  @override
  String get saleSummaryReadOnly => 'Sale Summary (Read-Only)';

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String get gst => 'GST';

  @override
  String get editableFields => 'Editable Fields';

  @override
  String get amountPaidPkr => 'Amount Paid (PKR)';

  @override
  String get enterAmountPaid => 'Please enter amount paid';

  @override
  String get partialStatus => 'Partial';

  @override
  String get unpaidStatus => 'Unpaid';

  @override
  String get specialInstructionsOrRemarks => 'Any special instructions or remarks...';

  @override
  String get amountPaying => 'Amount Paying';

  @override
  String get updateSale => 'Update Sale';

  @override
  String get saleUpdatedSuccessfully => 'Sale updated successfully!';

  @override
  String get existingOrders => 'Existing Orders';

  @override
  String get deliveryDate => 'Delivery Date';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get inProgressStatus => 'In Progress';

  @override
  String get completedStatus => 'Completed';

  @override
  String get deliveredStatus => 'Delivered';

  @override
  String get cancelledStatus => 'Cancelled';

  @override
  String productAddedToOrder(String productName, String orderId) {
    return '$productName added to order $orderId';
  }

  @override
  String get searchByInvoiceNumberCustomerOrSale => 'Search by invoice number, customer, or sale';

  @override
  String get noInvoicesFound => 'No invoices found';

  @override
  String get createNewInvoiceUsingButton => 'Create a new invoice using the + button';

  @override
  String get generatePdf => 'Generate PDF';

  @override
  String get invoiceDetails => 'Invoice Details';

  @override
  String invoiceDetailsWithNumber(String invoiceNumber) {
    return 'Invoice Details - $invoiceNumber';
  }

  @override
  String get saleInvoiceNumber => 'Sale Invoice Number';

  @override
  String get issueDate => 'Issue Date';

  @override
  String get invoicePdfGeneratedSuccessfully => 'Invoice PDF generated successfully';

  @override
  String deleteInvoiceWithNumber(String invoiceNumber) {
    return 'Delete Invoice - $invoiceNumber';
  }

  @override
  String get areYouSureDeleteInvoice => 'Are you sure you want to delete this invoice?';

  @override
  String get invoiceDeletedSuccessfully => 'Invoice deleted successfully';

  @override
  String get orderCreated => 'Order Created!';

  @override
  String get customOrderCreatedSuccessfully => 'Custom order created successfully';

  @override
  String get advanceReceived => 'Advance Received:';

  @override
  String get printOrder => 'Print Order';

  @override
  String get done => 'Done';

  @override
  String get printFunctionalityWillBeImplemented => 'Print functionality will be implemented';

  @override
  String get paymentConfirmation => 'Payment Confirmation';

  @override
  String get paymentComplete => 'Payment Complete';

  @override
  String get paymentInProgress => 'Payment in Progress';

  @override
  String get previouslyPaid => 'Previously Paid:';

  @override
  String get thisPayment => 'This Payment:';

  @override
  String get newBalance => 'New Balance:';

  @override
  String get creditDebitCard => 'Credit/Debit Card';

  @override
  String get mobilePayment => 'Mobile Payment';

  @override
  String get check => 'Check';

  @override
  String get amountExceedsBalance => 'Amount exceeds remaining balance';

  @override
  String get referenceOptional => 'Reference (Optional)';

  @override
  String get transactionReferenceOrReceipt => 'Transaction reference or receipt number';

  @override
  String get additionalNotesAboutPayment => 'Additional notes about this payment';

  @override
  String get confirmPayment => 'Confirm Payment';

  @override
  String get paymentConfirmed => 'Payment Confirmed';

  @override
  String get paymentProcessedSuccessfully => 'Payment has been processed successfully!';

  @override
  String get continue_ => 'Continue';

  @override
  String get paymentError => 'Payment Error';

  @override
  String get invalidPaymentAmount => 'Invalid payment amount. Please check the amount and try again.';

  @override
  String get paymentProcessingFailed => 'Payment processing failed. Please try again.';

  @override
  String errorOccurred(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get paymentWorkflowDashboard => 'Payment Workflow Dashboard';

  @override
  String get refreshDashboard => 'Refresh Dashboard';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get pendingPayments => 'Pending Payments';

  @override
  String get completionRate => 'Completion Rate';

  @override
  String get paymentProgressOverview => 'Payment Progress Overview';

  @override
  String get paymentCompletion => 'Payment Completion';

  @override
  String get recentWorkflowActivities => 'Recent Workflow Activities';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String get collected => 'Collected';

  @override
  String get updateSaleStatus => 'Update Sale Status';

  @override
  String get selectActionToPerform => 'Select an action to perform:';

  @override
  String get cancelSale => 'Cancel Sale';

  @override
  String get returnSale => 'Return Sale';

  @override
  String get unknownAction => 'Unknown Action';

  @override
  String get processAdditionalPayment => 'Process additional payment for this sale';

  @override
  String get markSaleAsDelivered => 'Mark the sale as delivered to customer';

  @override
  String get cancelSaleAndRestoreInventory => 'Cancel this sale and restore inventory';

  @override
  String get processReturnForDeliveredSale => 'Process return for delivered sale';

  @override
  String get noDescriptionAvailable => 'No description available';

  @override
  String get markedAsDelivered => 'Marked as delivered';

  @override
  String get saleCancelled => 'Sale cancelled';

  @override
  String get saleReturned => 'Sale returned';

  @override
  String get awaitingPayment => 'Awaiting Payment';

  @override
  String get partialPayment => 'Partial Payment';

  @override
  String get moreActions => 'More Actions';

  @override
  String get applyDiscount => 'Apply Discount';

  @override
  String get quickDiscounts => 'Quick Discounts';

  @override
  String get originalPrice => 'Original Price:';

  @override
  String get finalPrice => 'Final Price:';

  @override
  String get addWithDiscount => 'Add with Discount';

  @override
  String addedWithDiscount(String productName, String discount) {
    return 'Added $productName with $discount discount';
  }

  @override
  String get quickAddWithDefaultOptions => 'Quick add with default options';

  @override
  String get setSizeQualityEmbroidery => 'Set size, quality, embroidery, and options';

  @override
  String get applyDiscountBeforeAdding => 'Add discount before adding to cart';

  @override
  String get createCustomOrder => 'Create Custom Order';

  @override
  String get scheduleDeliveryAndAdvance => 'Schedule delivery and take advance';

  @override
  String get searchByReceiptCustomerPayment => 'Search by receipt number, customer, or payment';

  @override
  String get createNewReceiptUsingButton => 'Create a new receipt using the + button';

  @override
  String receiptDetails(String receiptNumber) {
    return 'Receipt Details - $receiptNumber';
  }

  @override
  String get receiptNumber => 'Receipt Number';

  @override
  String get generatedAt => 'Generated At';

  @override
  String deleteReceipt(String receiptNumber) {
    return 'Delete Receipt - $receiptNumber';
  }

  @override
  String get areYouSureDeleteReceipt => 'Are you sure you want to delete this receipt?';

  @override
  String get refunds => 'Refunds';

  @override
  String get searchByReturnCustomerInvoice => 'Search by return number, customer, or invoice';

  @override
  String get allReasons => 'All Reasons';

  @override
  String get defective => 'Defective';

  @override
  String get wrongSize => 'Wrong Size';

  @override
  String get wrongColor => 'Wrong Color';

  @override
  String get qualityIssue => 'Quality Issue';

  @override
  String get customerChangedMind => 'Customer Changed Mind';

  @override
  String get damagedInTransit => 'Damaged in Transit';

  @override
  String get approved => 'Approved';

  @override
  String get processed => 'Processed';

  @override
  String get rejected => 'Rejected';

  @override
  String get noReturnsFound => 'No returns found';

  @override
  String get createNewReturnUsingButton => 'Create a new return using the + button';

  @override
  String get noRefundsFound => 'No refunds found';

  @override
  String get refundsWillAppearHere => 'Refunds will appear here when returns are processed';

  @override
  String get approve => 'Approve';

  @override
  String get approvedAt => 'Approved At';

  @override
  String get processedAt => 'Processed At';

  @override
  String get returnStatistics => 'Return Statistics';

  @override
  String get totalReturns => 'Total Returns';

  @override
  String get approvedReturns => 'Approved Returns';

  @override
  String get totalRefunds => 'Total Refunds';

  @override
  String get statusBreakdown => 'Status Breakdown';

  @override
  String returnDetails(String returnNumber) {
    return 'Return Details - $returnNumber';
  }

  @override
  String get saleInvoice => 'Sale Invoice';

  @override
  String refundDetails(String refundNumber) {
    return 'Refund Details - $refundNumber';
  }

  @override
  String get returnId => 'Return ID';

  @override
  String approveReturn(String returnNumber) {
    return 'Approve Return - $returnNumber';
  }

  @override
  String get areYouSureApproveReturn => 'Are you sure you want to approve this return?';

  @override
  String get approvalReasonOptional => 'Approval Reason (Optional)';

  @override
  String get returnApprovedSuccessfully => 'Return approved successfully';

  @override
  String processReturn(String returnNumber) {
    return 'Process Return - $returnNumber';
  }

  @override
  String get processReturnAndInitiateRefund => 'Process this return and initiate refund?';

  @override
  String get refundAmount => 'Refund Amount';

  @override
  String get refundMethod => 'Refund Method';

  @override
  String get refundMethodHint => 'e.g., Cash, Bank Transfer, etc.';

  @override
  String get returnProcessedSuccessfully => 'Return processed successfully';

  @override
  String get provideValidRefundAmountAndMethod => 'Please provide valid refund amount and method';

  @override
  String cancelReturn(String returnNumber) {
    return 'Cancel Return - $returnNumber';
  }

  @override
  String get areYouSureCancelReturn => 'Are you sure you want to cancel this return?';

  @override
  String get cancellationReasonRequired => 'Cancellation Reason (Required)';

  @override
  String get provideCancellationReason => 'Please provide a cancellation reason';

  @override
  String get returnCancelledSuccessfully => 'Return cancelled successfully';

  @override
  String editReturn(String returnNumber) {
    return 'Edit Return - $returnNumber';
  }

  @override
  String get returnUpdatedSuccessfully => 'Return updated successfully';

  @override
  String deleteReturn(String returnNumber) {
    return 'Delete Return - $returnNumber';
  }

  @override
  String get areYouSureDeleteReturn => 'Are you sure you want to delete this return?';

  @override
  String get returnDeletedSuccessfully => 'Return deleted successfully';

  @override
  String processRefund(String refundNumber) {
    return 'Process Refund - $refundNumber';
  }

  @override
  String get referenceNumberOptional => 'Reference Number (Optional)';

  @override
  String get processingNotesOptional => 'Processing Notes (Optional)';

  @override
  String get refundProcessedSuccessfully => 'Refund processed successfully';

  @override
  String get processRefundAction => 'Process Refund';

  @override
  String editRefund(String refundNumber) {
    return 'Edit Refund - $refundNumber';
  }

  @override
  String amountCannotBeChanged(String amount) {
    return 'Amount: PKR $amount (Cannot be changed)';
  }

  @override
  String get refundUpdatedSuccessfully => 'Refund updated successfully';

  @override
  String deleteRefund(String refundNumber) {
    return 'Delete Refund - $refundNumber';
  }

  @override
  String get areYouSureDeleteRefund => 'Are you sure you want to delete this refund?';

  @override
  String get refundDeletedSuccessfully => 'Refund deleted successfully';

  @override
  String get createNewSale => 'Create New Sale';

  @override
  String get pleaseEnterInvoiceNumber => 'Please enter an invoice number';

  @override
  String get pleaseEnterCustomerName => 'Please enter customer name';

  @override
  String get pleaseEnterCustomerPhone => 'Please enter customer phone';

  @override
  String get overallDiscountRs => 'Overall Discount (Rs.)';

  @override
  String get invoiced => 'INVOICED';

  @override
  String get saleItems => 'Sale Items';

  @override
  String get noSaleItemsAdded => 'No Sale Items Added';

  @override
  String get addItemsToSale => 'Add items to this sale';

  @override
  String get taxConfiguration => 'Tax Configuration';

  @override
  String get totalTax => 'Total Tax';

  @override
  String get createSale => 'Create Sale';

  @override
  String get addSaleItemFunctionalityToBeImplemented => 'Add Sale Item functionality to be implemented';

  @override
  String get pleaseAddAtLeastOneSaleItem => 'Please add at least one sale item';

  @override
  String errorSavingSale(String error) {
    return 'Error saving sale: $error';
  }

  @override
  String get reason => 'Reason';

  @override
  String get method => 'Method';

  @override
  String get process => 'Process';

  @override
  String get reference => 'Reference';

  @override
  String get refundNumber => 'Refund Number';

  @override
  String get saleDate => 'Sale Date';

  @override
  String get customerPhone => 'Customer Phone';

  @override
  String get summary => 'Summary';

  @override
  String get noSalesRecordsFound => 'No Sales Records Found';

  @override
  String get completeFirstSaleMessage => 'Complete your first sale to see transaction records here';

  @override
  String printReceiptFor(String invoice) {
    return 'Print receipt for $invoice';
  }

  @override
  String get addCustomTax => 'Add Custom Tax';

  @override
  String get refreshTaxRates => 'Refresh Tax Rates';

  @override
  String get noTaxRatesAvailable => 'No Tax Rates Available';

  @override
  String get contactAdministratorToSetupTaxRates => 'Contact administrator to set up tax rates';

  @override
  String get rate => 'Rate';

  @override
  String get totalTaxAmount => 'Total Tax Amount';

  @override
  String get totalTaxPercentage => 'Total Tax Percentage';

  @override
  String get addTax => 'Add Tax';

  @override
  String get saleDetails => 'Sale Details';

  @override
  String get saleInvoiceDetails => 'Sale Invoice Details';

  @override
  String get dateTime => 'Date & Time';

  @override
  String get note => 'Note';

  @override
  String get noSplitPaymentDetails => 'No split payment details';

  @override
  String get overallDiscount => 'Overall Discount';

  @override
  String get notesRemarks => 'Notes & Remarks';

  @override
  String get noNotesAvailable => 'No notes available';

  @override
  String printingReceiptFor(String invoice) {
    return 'Printing receipt for $invoice';
  }

  @override
  String get invoiceHash => 'Invoice #';

  @override
  String get subTotal => 'Subtotal';

  @override
  String get action => 'Actions';

  @override
  String get deletePurchase => 'Delete Purchase';

  @override
  String get loadingData => 'Loading data...';

  @override
  String get pendingOrders => 'Pending orders';

  @override
  String get returnNumber => 'Return Number';

  @override
  String get pleaseSelectVendor => 'Please select a vendor';

  @override
  String get loadingLabors => 'Loading employees...';

  @override
  String get loadingVendors => 'Loading vendors...';

  @override
  String get loadingOrders => 'Loading orders...';

  @override
  String get loadingSales => 'Loading sales...';

  @override
  String get confirmDelete => 'Are you sure you want to delete this purchase?';

  @override
  String get deleteSuccess => 'Purchase deleted successfully';

  @override
  String get editPurchase => 'Edit Purchase';

  @override
  String get apply => 'Apply';

  @override
  String get scannerTitle => 'Barcode Scanner';

  @override
  String get scannerReady => 'Ready to scan...';

  @override
  String get scannerScanning => 'Scanning...';

  @override
  String get scannerLabel => 'Barcode';

  @override
  String get scannerHint => 'Type or scan barcode';

  @override
  String get scannerInvalidFormat => 'Invalid barcode format';

  @override
  String get scannerDuplicateScan => 'Duplicate barcode scan';

  @override
  String get scannerProductNotFound => 'Product not found';

  @override
  String scannerFound(String productName) {
    return 'Found: $productName';
  }

  @override
  String scannerFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String scannerAddedToCart(String productName) {
    return 'Added $productName to cart';
  }

  @override
  String get scannerAddToCartFailed => 'Failed to add product to cart';

  @override
  String get userLogin => 'User Login';

  @override
  String get userRegistration => 'User Registration';

  @override
  String get registerHere => 'Register here';

  @override
  String get enterFullName => 'Enter Your Full Name';

  @override
  String get login => 'Login';

  @override
  String get userManagement => 'User Management';

  @override
  String get createNewUser => 'Create New User';

  @override
  String get rolePermissionMatrix => 'Role & Permission Matrix';

  @override
  String get userName => 'User Name';

  @override
  String get orderRental => 'Order & Rental';

  @override
  String get invoicePayments => 'Invoice & Payments';

  @override
  String get approvalWorkflow => 'Approval Workflow for Sensitive actions';

  @override
  String get userRoles => 'User Roles';

  @override
  String get reportsAnalytics => 'Reports & Analytics';

  @override
  String get manageReportsSub => 'Manage your Reports here\'s';

  @override
  String get newCustomersStat => 'New Customer\'s';

  @override
  String get thisMonthStat => 'this Month';

  @override
  String get eventsStat => 'Events';

  @override
  String get itemsStat => 'Items';

  @override
  String get timeFilter => 'Time Filter';

  @override
  String get searchReport => 'Search Report';

  @override
  String get downloadPdfReport => 'Download PDF Report';

  @override
  String get exportToExcel => 'Export to Excel';

  @override
  String get monthlyRevenueAnalysis => 'Monthly Revenue Analysis';

  @override
  String get categoryWiseDemand => 'Category-wise Demand';

  @override
  String get mostRentedItemReports => 'Most Rented Item Reports';

  @override
  String get itemName => 'Item Name';

  @override
  String get rentDays => 'Rent Days';

  @override
  String get clientName => 'Client Name';

  @override
  String get totalBill => 'Total Bill';

  @override
  String get stageLight => 'Stage Light';

  @override
  String get smdScreens => 'SMD Screens';

  @override
  String get totalEvents => 'Total Events';

  @override
  String get inventory => 'Inventory';

  @override
  String get purchase => 'Purchase';

  @override
  String get quotations => 'Quotations';

  @override
  String get failedToUpdatePayablePleaseTryAgain => 'Failed to update payable. Please try again.';
}
