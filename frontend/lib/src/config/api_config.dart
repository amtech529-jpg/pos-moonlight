class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';
  // static const String baseUrl = 'https://pos-moonlight-production.up.railway.app/api/v1';
  // static const String baseUrl =
  //     'https://django-flutter-pos-production.up.railway.app/api/v1';
  static const String dashboardAnalytics = '/analytics/dashboard/';
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String logout = '/auth/logout/';
  static const String profile = '/auth/profile/';
  static const String updateProfile = '/auth/profile/update/';
  static const String changePassword = '/auth/change-password/';

  static const String categories = '/categories/';
  static const String createCategory = '/categories/create/';

  static String getCategoryById(String id) => '/categories/$id/';
  static String updateCategory(String id) => '/categories/$id/update/';
  static String deleteCategory(String id) => '/categories/$id/delete/';
  static String softDeleteCategory(String id) => '/categories/$id/soft-delete/';
  static String restoreCategory(String id) => '/categories/$id/restore/';

  static const String products = '/products/';
  static const String createProduct = '/products/create/';

  static String getProductById(String id) => '/products/$id/';
  static String updateProduct(String id) => '/products/$id/update/';
  static String deleteProduct(String id) => '/products/$id/delete/';
  static String softDeleteProduct(String id) => '/products/$id/soft-delete/';
  static String restoreProduct(String id) => '/products/$id/restore/';

  static const String searchProducts = '/products/search/';
  static String productsByCategory(String categoryId) =>
      '/products/category/$categoryId/';
  static const String lowStockProducts = '/products/low-stock/';
  static const String productStatistics = '/products/statistics/';

  static String updateProductQuantity(String id) => '/products/$id/quantity/';
  static const String bulkUpdateQuantities =
      '/products/bulk-update-quantities/';
  static String duplicateProduct(String id) => '/products/$id/duplicate/';

  // Real-time Inventory Integration endpoints
  static const String checkStockAvailability = '/products/check-stock/';
  static const String checkDateAvailability = '/products/check-date-availability/';
  static const String reserveStockForSale = '/products/reserve-stock/';
  static const String confirmStockDeduction = '/products/confirm-deduction/';
  static const String getLowStockAlerts = '/products/low-stock-alerts/';
  static const String bulkUpdateStock = '/products/bulk-update-stock/';

  static const String customers = '/customers/';
  static const String createCustomer = '/customers/create/';

  static String getCustomerById(String id) => '/customers/$id/';
  static String updateCustomer(String id) => '/customers/$id/update/';
  static String deleteCustomer(String id) => '/customers/$id/delete/';
  static String softDeleteCustomer(String id) => '/customers/$id/soft-delete/';
  static String restoreCustomer(String id) => '/customers/$id/restore/';

  static const String searchCustomers = '/customers/search/';
  static String customersByStatus(String status) =>
      '/customers/status/$status/';
  static String customersByType(String type) => '/customers/type/$type/';
  static String customersByCity(String city) => '/customers/city/$city/';
  static String customersByCountry(String country) =>
      '/customers/country/$country/';

  static const String pakistaniCustomers = '/customers/pakistani/';
  static const String internationalCustomers = '/customers/international/';
  static const String newCustomers = '/customers/new/';
  static const String recentCustomers = '/customers/recent/';

  static const String customerStatistics = '/customers/statistics/';

  static String updateCustomerContact(String id) => '/customers/$id/contact/';
  static String verifyCustomerContact(String id) => '/customers/$id/verify/';

  static String updateCustomerActivity(String id) => '/customers/$id/activity/';

  static const String bulkCustomerActions = '/customers/bulk-actions/';

  static String duplicateCustomer(String id) => '/customers/$id/duplicate/';

  // Quick Customer Lookup & History (for POS)
  static const String quickCustomerLookup = '/customers/quick-lookup/';
  static String getCustomerHistory(String id) => '/customers/$id/history/';
  static String getCustomerSummary(String id) => '/customers/$id/summary/';
  static const String searchCustomersAdvanced = '/customers/search-advanced/';

  static String customerOrders(String id) => '/customers/$id/orders/';
  static String customerSales(String id) => '/customers/$id/sales/';

  // Sales API endpoints
  static const String sales = '/sales/';
  static const String createSale = '/sales/create/';
  static String getSaleById(String id) => '/sales/$id/';
  static String updateSale(String id) => '/sales/$id/update/';
  static String deleteSale(String id) => '/sales/$id/delete/';
  static String softDeleteSale(String id) => '/sales/$id/soft-delete/';
  static String restoreSale(String id) => '/sales/$id/restore/';
  static const String searchSales = '/sales/search/';
  static String salesByStatus(String status) => '/sales/status/$status/';
  static String salesByCustomer(String customerId) =>
      '/sales/customer/$customerId/';
  static String salesByPaymentMethod(String method) =>
      '/sales/payment-method/$method/';
  static const String pendingSales = '/sales/pending/';
  static const String paidSales = '/sales/paid/';
  static const String unpaidSales = '/sales/unpaid/';
  static const String recentSales = '/sales/recent/';
  static const String todaySales = '/sales/today/';
  static const String thisMonthSales = '/sales/this-month/';
  static const String thisYearSales = '/sales/this-year/';
  static const String salesStatistics = '/sales/statistics/';
  static String addSalePayment(String id) => '/sales/$id/add-payment/';
  static String updateSaleStatus(String id) => '/sales/$id/update-status/';
  static const String bulkSaleActions = '/sales/bulk-action/';
  static String recalculateSaleTotals(String id) => '/sales/$id/recalculate/';
  static const String createFromOrder = '/sales/create-from-order/';
  static String customerSalesHistory(String customerId) =>
      '/sales/by-customer/$customerId/';

  // Invoice Management API endpoints
  static const String invoices = '/sales/invoices/';
  static const String createInvoice = '/sales/invoices/create/';
  static String getInvoiceById(String id) => '/sales/invoices/$id/';
  static String updateInvoice(String id) => '/sales/invoices/$id/update/';
  static String deleteInvoice(String id) => '/sales/invoices/$id/delete/';
  static String generateInvoicePdf(String id) =>
      '/sales/invoices/$id/generate-pdf/';
  static String generateInvoiceThermalPrint(String id) =>
      '/sales/invoices/$id/thermal-print/';

  // Receipt Management API endpoints
  static const String receipts = '/sales/receipts/';
  static const String createReceipt = '/sales/receipts/create/';
  static String getReceiptById(String id) => '/sales/receipts/$id/';
  static String updateReceipt(String id) => '/sales/receipts/$id/update/';
  static String deleteReceipt(String id) => '/sales/receipts/$id/delete/';
  static String generateReceiptPdf(String id) =>
      '/sales/receipts/$id/generate-pdf/';

  // Returns & Refunds API endpoints
  static const String returns = '/sales/returns/';
  static const String returnsEndpoint = '/sales/returns/';
  static const String rentalReturnsEndpoint = '/rental-returns/';
  static const String createReturn = '/sales/returns/create/';
  static String getReturnById(String id) => '/sales/returns/$id/';
  static String updateReturn(String id) => '/sales/returns/$id/update/';
  static String deleteReturn(String id) => '/sales/returns/$id/delete/';
  static String approveReturn(String id) => '/sales/returns/$id/approve/';
  static String processReturn(String id) => '/sales/returns/$id/process/';
  static String getReturnItems(String id) => '/sales/returns/$id/items/';
  static String getReturnStatistics = '/sales/returns/statistics/';
  static String getCustomerReturnHistory(String customerId) =>
      '/sales/returns/customer/$customerId/history/';
  static String getSaleReturnDetails(String saleId) =>
      '/sales/returns/sale/$saleId/returns/';

  // Refunds API endpoints
  static const String refunds = '/sales/returns/refunds/';
  static const String createRefund = '/sales/returns/refunds/create/';
  static String getRefundById(String id) => '/sales/returns/refunds/$id/';
  static String updateRefund(String id) => '/sales/returns/refunds/$id/update/';
  static String deleteRefund(String id) => '/sales/returns/refunds/$id/delete/';
  static String processRefund(String id) =>
      '/sales/returns/refunds/$id/process/';
  static String failRefund(String id) => '/sales/returns/refunds/$id/fail/';
  static String cancelRefund(String id) => '/sales/returns/refunds/$id/cancel/';

  // Sale Items API endpoints
  static const String saleItems = '/sales/items/';
  static const String createSaleItem = '/sales/items/create/';
  static const String saleItemsCacheKey = 'sale_items_cache';
  static String getSaleItemById(String id) => '/sales/items/$id/';
  static String updateSaleItem(String id) => '/sales/items/$id/update/';
  static String deleteSaleItem(String id) => '/sales/items/$id/delete/';
  static String softDeleteSaleItem(String id) =>
      '/sales/items/$id/soft-delete/';
  static String restoreSaleItem(String id) => '/sales/items/$id/restore/';
  static const String searchSaleItems = '/sales/items/search/';
  static String saleItemsBySale(String saleId) => '/sales/items/sale/$saleId/';
  static String saleItemsByProduct(String productId) =>
      '/sales/items/product/$productId/';

  // Tax Rates API endpoints
  static const String taxRates = '/tax-rates/';
  static const String createTaxRate = '/tax-rates/create/';
  static String getTaxRateById(String id) => '/tax-rates/$id/';
  static String updateTaxRate(String id) => '/tax-rates/$id/update/';
  static String deleteTaxRate(String id) => '/tax-rates/$id/delete/';
  static String softDeleteTaxRate(String id) => '/tax-rates/$id/soft-delete/';
  static String restoreTaxRate(String id) => '/tax-rates/$id/restore/';
  static const String searchTaxRates = '/tax-rates/search/';
  static String taxRatesByType(String type) => '/tax-rates/type/$type/';
  static String taxRatesByStatus(String status) => '/tax-rates/status/$status/';
  static const String activeTaxRates = '/tax-rates/active/';
  static const String effectiveTaxRates = '/tax-rates/effective/';
  static const String taxRateStatistics = '/tax-rates/statistics/';

  // Payment Processing API endpoints
  static const String processPayment = '/payments/process/';
  static const String processSplitPayment = '/payments/split/';

  // Analytics & Reporting API endpoints
  static const String getSalesAnalytics = '/analytics/sales/';
  static const String getSalesTrends = '/analytics/sales/trends/';
  static const String getCustomerAnalytics = '/analytics/customers/';
  static const String getProductAnalytics = '/analytics/products/';
  static const String getFinancialAnalytics = '/analytics/financial/';
  static const String getRevenueAnalytics = '/analytics/revenue/';
  static const String getProfitMarginAnalytics = '/analytics/profit-margin/';
  static const String getTaxAnalytics = '/analytics/tax/';
  static const String getPerformanceAnalytics = '/analytics/performance/';
  static const String generateReport = '/analytics/reports/generate/';
  static const String getReportTemplates = '/analytics/reports/templates/';
  static const String exportAnalyticsData = '/analytics/export/';
  static const String getDashboardAnalytics = '/analytics/dashboard/';
  static const String reminders = '/analytics/reminders/';
  static const String getRealTimeAnalytics = '/analytics/real-time/';

  static const String vendors = '/vendors/';
  static const String createVendor = '/vendors/create/';

  static String getVendorById(String id) => '/vendors/$id/';
  static String updateVendor(String id) => '/vendors/$id/update/';
  static String deleteVendor(String id) => '/vendors/$id/delete/';

  static String softDeleteVendor(String id) => '/vendors/$id/soft-delete/';
  static String restoreVendor(String id) => '/vendors/$id/restore/';

  static const String searchVendors = '/vendors/search/';
  static String vendorsByCity(String cityName) => '/vendors/city/$cityName/';
  static String vendorsByArea(String areaName) => '/vendors/area/$areaName/';

  static const String newVendors = '/vendors/new/';
  static const String recentVendors = '/vendors/recent/';

  static const String vendorStatistics = '/vendors/statistics/';

  static String updateVendorContact(String id) =>
      '/vendors/$id/contact/update/';

  static const String bulkVendorActions = '/vendors/bulk-actions/';

  static String duplicateVendor(String id) => '/vendors/$id/duplicate/';

  static String vendorPayments(String id) => '/vendors/$id/payments/';
  static String vendorTransactions(String id) => '/vendors/$id/transactions/';

  static const String labors = '/labors/';
  static const String createLabor = '/labors/create/';

  static String getLaborById(String id) => '/labors/$id/';
  static String updateLabor(String id) => '/labors/$id/update/';
  static String deleteLabor(String id) => '/labors/$id/delete/';

  static String softDeleteLabor(String id) => '/labors/$id/soft-delete/';
  static String restoreLabor(String id) => '/labors/$id/restore/';

  static const String searchLabors = '/labors/search/';
  static String laborsByCity(String cityName) => '/labors/city/$cityName/';
  static String laborsByArea(String areaName) => '/labors/area/$areaName/';
  static String laborsByDesignation(String designationName) =>
      '/labors/designation/$designationName/';
  static String laborsByCaste(String casteName) => '/labors/caste/$casteName/';
  static String laborsByGender(String gender) => '/labors/gender/$gender/';
  static const String laborsBySalaryRange = '/labors/salary-range/';
  static const String laborsByAgeRange = '/labors/age-range/';

  static const String newLabors = '/labors/new/';
  static const String recentLabors = '/labors/recent/';

  static const String laborStatistics = '/labors/statistics/';
  static const String laborSalaryReport = '/labors/salary-report/';
  static const String laborDemographicsReport = '/labors/demographics-report/';
  static const String laborExperienceReport = '/labors/experience-report/';

  static String updateLaborContact(String id) => '/labors/$id/contact/update/';
  static String updateLaborSalary(String id) => '/labors/$id/salary/update/';

  static const String bulkLaborActions = '/labors/bulk-actions/';

  static String duplicateLabor(String id) => '/labors/$id/duplicate/';

  static String laborPayments(String id) => '/labors/$id/payments/';
  
  // Salary Slips
  static const String salarySlips = '/labors/salary-slips/';
  static const String generateSalarySlips = '/labors/salary-slips/generate/';
  static String updateSalarySlipStatus(String id) => '/labors/salary-slips/$id/status/';


  static String getSearchLabors() => searchLabors;
  static String getLaborsBySalaryRange() => laborsBySalaryRange;
  static String getLaborsByAgeRange() => laborsByAgeRange;
  static String getNewLabors() => newLabors;
  static String getRecentLabors() => recentLabors;
  static String getLaborStatistics() => laborStatistics;
  static String getLaborSalaryReport() => laborSalaryReport;
  static String getLaborDemographicsReport() => laborDemographicsReport;
  static String getLaborExperienceReport() => laborExperienceReport;
  static String getBulkLaborActions() => bulkLaborActions;

  static const String zakats = '/zakats/';
  static const String createZakat = '/zakats/';

  static String getZakatById(String id) => '/zakats/$id/';
  static String updateZakat(String id) => '/zakats/$id/update/';
  static String deleteZakat(String id) => '/zakats/$id/delete/';

  static const String searchZakats = '/zakats/search/';
  static String zakatsByBeneficiary(String beneficiaryName) =>
      '/zakats/by-beneficiary/$beneficiaryName/';
  static String zakatsByAuthority(String authority) =>
      '/zakats/by-authority/$authority/';
  static const String zakatsByDateRange = '/zakats/by-date-range/';

  static const String zakatStatistics = '/zakats/statistics/';
  static const String zakatMonthlySummary = '/zakats/monthly-summary/';
  static const String zakatBeneficiaryReport = '/zakats/beneficiary-report/';
  static const String recentZakats = '/zakats/recent/';

  static const String bulkZakatActions = '/zakats/bulk-actions/';

  static String duplicateZakat(String id) => '/zakats/$id/duplicate/';
  static String verifyZakat(String id) => '/zakats/$id/verify/';
  static String unverifyZakat(String id) => '/zakats/$id/unverify/';
  static String archiveZakat(String id) => '/zakats/$id/archive/';
  static String unarchiveZakat(String id) => '/zakats/$id/unarchive/';

  static const String orders = '/orders/';
  static const String createOrder = '/orders/create/';

  static String getOrderById(String id) => '/orders/$id/';
  static String updateOrder(String id) => '/orders/$id/update/';
  static String deleteOrder(String id) => '/orders/$id/delete/';
  static String softDeleteOrder(String id) => '/orders/$id/soft-delete/';
  static String restoreOrder(String id) => '/orders/$id/restore/';

  static const String searchOrders = '/orders/search/';
  static String ordersByStatus(String status) => '/orders/status/$status/';
  static String ordersByCustomer(String customerId) =>
      '/orders/customer/$customerId/';

  static const String pendingOrders = '/orders/pending/';
  static const String overdueOrders = '/orders/overdue/';
  static const String unpaidOrders = '/orders/unpaid/';
  static const String recentOrders = '/orders/recent/';
  static const String dueTodayOrders = '/orders/due-today/';

  static const String orderStatistics = '/orders/statistics/';

  static String addOrderPayment(String id) => '/orders/$id/payment/';

  static String updateOrderStatus(String id) => '/orders/$id/status/';
  static const String bulkOrderActions = '/orders/bulk-actions/';

  static String recalculateOrderTotals(String id) => '/orders/$id/recalculate/';
  static String updateOrderCustomerInfo(String id) =>
      '/orders/$id/customer-info/';
  static String duplicateOrder(String id) => '/orders/$id/duplicate/';

  static const String orderItems = '/order-items/';
  static const String createOrderItem = '/order-items/create/';

  static String getOrderItemById(String id) => '/order-items/$id/';
  static String updateOrderItem(String id) => '/order-items/$id/update/';
  static String deleteOrderItem(String id) => '/order-items/$id/delete/';
  static String softDeleteOrderItem(String id) =>
      '/order-items/$id/soft-delete/';
  static String restoreOrderItem(String id) => '/order-items/$id/restore/';

  static const String searchOrderItems = '/order-items/search/';
  static String orderItemsByOrder(String orderId) =>
      '/order-items/order/$orderId/';
  static String orderItemsByProduct(String productId) =>
      '/order-items/product/$productId/';

  // Quotations API endpoints
  static const String quotations = '/quotations/';
  static const String createQuotation = '/quotations/';
  static String getQuotationById(String id) => '/quotations/$id/';
  static String updateQuotation(String id) => '/quotations/$id/';
  static String deleteQuotation(String id) => '/quotations/$id/';
  static String convertQuotationToOrder(String id) => '/quotations/$id/convert_to_order/';

  // Purchases API endpoints
  static const String purchases = '/purchases/';
  static String getPurchaseById(String id) => '/purchases/$id/';

  static const String expenses = '/expenses/';
  static const String createExpense = '/expenses/';

  static String getExpenseById(String id) => '/expenses/$id/';
  static String updateExpense(String id) => '/expenses/$id/update/';
  static String deleteExpense(String id) => '/expenses/$id/delete/';

  static String expensesByAuthority(String authority) =>
      '/expenses/by-authority/$authority/';
  static String expensesByCategory(String category) =>
      '/expenses/by-category/$category/';
  static const String expensesByDateRange = '/expenses/by-date-range/';

  static const String expenseStatistics = '/expenses/statistics/';
  static const String expenseMonthlySummary = '/expenses/monthly-summary/';
  static const String recentExpenses = '/expenses/recent/';

  // Advance Payments API endpoints
  static const String advancePayments = '/advance-payments/';
  static const String createAdvancePayment = '/advance-payments/create/';
  static String getAdvancePaymentById(String id) => '/advance-payments/$id/';
  static String updateAdvancePayment(String id) =>
      '/advance-payments/$id/update/';
  static String deleteAdvancePayment(String id) =>
      '/advance-payments/$id/delete/';
  static String softDeleteAdvancePayment(String id) =>
      '/advance-payments/$id/soft-delete/';
  static String restoreAdvancePayment(String id) =>
      '/advance-payments/$id/restore/';
  static const String searchAdvancePayments = '/advance-payments/search/';
  static String paymentsByLabor(String laborId) =>
      '/advance-payments/labor/$laborId/';
  static const String paymentsByDateRange = '/advance-payments/date-range/';
  static const String todayPayments = '/advance-payments/today/';
  static const String recentPayments = '/advance-payments/recent/';
  static const String advancePaymentStatistics =
      '/advance-payments/statistics/';
  static const String monthlyReport = '/advance-payments/monthly-report/';
  static const String laborAdvanceReport =
      '/advance-payments/labor-advance-report/';
  static const String bulkAdvancePaymentActions =
      '/advance-payments/bulk-actions/';
  static const String paymentsWithReceipts = '/advance-payments/with-receipts/';
  static const String paymentsWithoutReceipts =
      '/advance-payments/without-receipts/';
  static String laborAdvanceSummary(String laborId) =>
      '/advance-payments/labor/$laborId/summary/';

  // Payments API endpoints
  static const String payments = '/payments/';
  static const String createPayment = '/payments/create/';
  static String getPaymentById(String id) => '/payments/$id/';
  static String updatePayment(String id) => '/payments/$id/update/';
  static String deletePayment(String id) => '/payments/$id/delete/';
  static String softDeletePayment(String id) => '/payments/$id/soft-delete/';
  static String restorePayment(String id) => '/payments/$id/restore/';
  static const String searchPayments = '/payments/search/';
  static String paymentsByLaborId(String laborId) =>
      '/payments/by-labor/$laborId/';
  static String paymentsByVendorId(String vendorId) =>
      '/payments/by-vendor/$vendorId/';
  static String paymentsByOrderId(String orderId) =>
      '/payments/by-order/$orderId/';
  static String paymentsBySaleId(String saleId) => '/payments/by-sale/$saleId/';
  static const String paymentDateRange = '/payments/by-date-range/';
  static String paymentsByMethod(String method) =>
      '/payments/by-payment-method/$method/';
  static const String paymentWithReceipts = '/payments/with-receipts/';
  static const String paymentWithoutReceipts = '/payments/without-receipts/';
  static const String paymentRecent = '/payments/recent/';
  static const String paymentToday = '/payments/today/';
  static const String paymentThisMonth = '/payments/this-month/';
  static const String paymentThisYear = '/payments/this-year/';
  static const String paymentStatistics = '/payments/statistics/';
  static const String paymentSummary = '/payments/summary/';
  static String markAsFinalPayment(String id) => '/payments/$id/mark-final/';

  // Payables API endpoints
  static const String payables = '/payables/';
  static const String createPayable = '/payables/create/';
  static String getPayableById(String id) => '/payables/$id/';
  static String updatePayable(String id) => '/payables/$id/update/';
  static String deletePayable(String id) => '/payables/$id/delete/';
  static String softDeletePayable(String id) => '/payables/$id/soft-delete/';
  static String restorePayable(String id) => '/payables/$id/restore/';
  static const String searchPayables = '/payables/search/';
  static String payablesByCreditor(String creditorName) =>
      '/payables/creditor/$creditorName/';
  static String payablesByVendor(String vendorId) =>
      '/payables/vendor/$vendorId/';
  static const String overduePayables = '/payables/overdue/';
  static const String urgentPayables = '/payables/urgent/';
  static const String dueSoonPayables = '/payables/due-soon/';
  static const String recentPayables = '/payables/recent/';
  static const String payableStatistics = '/payables/statistics/';
  static const String paymentSchedule = '/payables/payment-schedule/';
  static const String creditorSummary = '/payables/creditor-summary/';
  static const String bulkPayableActions = '/payables/bulk-actions/';
  static String addPayablePayment(String id) => '/payables/$id/payment/';
  static String updatePayableContact(String id) =>
      '/payables/$id/contact/update/';

  // Partner payable generation
  static const String generatePartnerPayables =
      '/payables/generate-partner-payables/';

  // Invoice generation & payment endpoints
  static const String generateInvoiceFromOrder =
      '/sales/invoices/generate-from-order/';
  static String applyInvoicePayment(String id) =>
      '/sales/invoices/$id/apply-payment/';
  static String writeOffInvoice(String id) => '/sales/invoices/$id/write-off/';
  static const String invoiceLedger = '/sales/invoices/ledger/';

  // Rental return tally & stock endpoints
  static const String rentalReturnCreate = '/rental-returns/create/';
  static String rentalReturnTally(String id) => '/rental-returns/$id/tally/';
  static String rentalReturnRestoreStock(String id) =>
      '/rental-returns/$id/restore-stock/';
  static String rentalReturnDamageRecovery(String id) =>
      '/rental-returns/$id/damage-recovery/';
  static String deleteRentalReturn(String id) => '/rental-returns/$id/delete/';
  static const String rentalReturnStatistics = '/rental-returns/statistics/';


  // Profit Loss endpoints
  static const String _profitLossBase = '/profit-loss';

  // Main profit loss endpoints
  static const String calculateProfitLoss = '$_profitLossBase/calculate/';
  static const String profitLossRecords = '$_profitLossBase/records/';
  static const String profitLossSummary = '$_profitLossBase/summary/';
  static const String productProfitability =
      '$_profitLossBase/product-profitability/';
  static const String profitLossDashboard = '$_profitLossBase/dashboard/';

  // Dynamic endpoints
  static String getProfitLossRecordById(String id) =>
      '$_profitLossBase/records/$id/';

  // Principal Account endpoints
  static const String principalAccount = '/principal-account/';
  static const String createPrincipalAccount = '/principal-account/';
  static String getPrincipalAccountById(String id) => '/principal-account/$id/';
  static String updatePrincipalAccount(String id) => '/principal-account/$id/';
  static String deletePrincipalAccount(String id) => '/principal-account/$id/';

  static String vendorLedger(String id) => '/vendors/$id/ledger/';
  static String customerLedger(String id) => '/customers/$id/ledger/';

  static const String principalAccountBalance = '/principal-account/balance/';
  static const String principalAccountStatistics =
      '/principal-account/statistics/';
  static const String createPrincipalAccountFromModule =
      '/principal-account/create-from-module/';

  // Cache keys
  static const String profitLossCacheKey = 'profit_loss_records_cache';
  static const String profitLossSummaryCacheKey = 'profit_loss_summary_cache';
  static const String profitLossDashboardCacheKey =
      'profit_loss_dashboard_cache';

  // Cache keys for expenses
  static const String expensesCacheKey = 'cached_expenses';
  static const String expenseStatsCacheKey = 'cached_expense_stats';

  static const String itemsWithCustomization = '/order-items/customized/';

  static const String orderItemStatistics = '/order-items/statistics/';

  static String updateOrderItemQuantity(String id) =>
      '/order-items/$id/quantity/';
  static const String bulkUpdateOrderItems = '/order-items/bulk-update/';

  static String duplicateOrderItem(String id) => '/order-items/$id/duplicate/';

  static const int connectTimeout = 60000;
  static const int receiveTimeout = 60000;
  static const int sendTimeout = 60000;

  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String categoriesCacheKey = 'cached_categories';
  static const String productsCacheKey = 'cached_products';
  static const String productStatsCacheKey = 'cached_product_stats';
  static const String customersCacheKey = 'cached_customers';
  static const String customerStatsCacheKey = 'cached_customer_stats';
  static const String vendorsCacheKey = 'cached_vendors';
  static const String vendorStatsCacheKey = 'cached_vendor_stats';
  static const String laborsCacheKey = 'cached_labors';
  static const String laborStatsCacheKey = 'cached_labor_stats';
  static const String laborSalaryReportCacheKey = 'cached_labor_salary_report';
  static const String laborDemographicsReportCacheKey =
      'cached_labor_demographics_report';
  static const String zakatsCacheKey = 'cached_zakats';
  static const String zakatStatsCacheKey = 'cached_zakat_stats';
  static const String advancePaymentsCacheKey = 'cached_advance_payments';
  static const String advancePaymentStatsCacheKey =
      'cached_advance_payment_stats';
  static const String paymentsCacheKey = 'cached_payments';
  static const String paymentStatsCacheKey = 'cached_payment_stats';
  static const String payablesCacheKey = 'cached_payables';
  static const String payableStatsCacheKey = 'cached_payable_stats';
  static const String ordersCacheKey = 'cached_orders';
  static const String orderStatsCacheKey = 'cached_order_stats';
  static const String orderItemsCacheKey = 'cached_order_items';
  static const String salesCacheKey = 'cached_sales';
  static const String saleStatsCacheKey = 'cached_sale_stats';
  static const String purchasesCacheKey = 'cached_purchases';

  // Principal Account cache keys
  static const String principalAccountCacheKey = 'cached_principal_accounts';
  static const String principalAccountStatsCacheKey =
      'cached_principal_account_stats';
  static const String principalAccountBalanceCacheKey =
      'cached_principal_account_balance';

  static const String taxRatesCacheKey = 'cached_tax_rates';

  // Data Management
  static const String dataManagement = '/data-management/';
  static String exportData(String model) => '${dataManagement}export/$model/';
  static String importData(String model) => '${dataManagement}import/$model/';
  static String templateData(String model) => '${dataManagement}template/$model/';

  // Reports
  static const String reports = '/analytics/reports/';
  static const String topCustomersReport = '${reports}top-customers/';
  static const String topProductsReport = '${reports}top-products/';
  static const String revenueReport = '${reports}revenue/';
  static const String monthlyRevenueReport = '${reports}monthly-revenue/';
  static const String businessPerformance = '${reports}business-performance/';
  static const String toolUsageReport = '${reports}tool-usage/';

  static String getFullUrl(String endpoint) {
    return baseUrl + endpoint;
  }
}