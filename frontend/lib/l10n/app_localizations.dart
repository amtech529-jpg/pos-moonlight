import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Moon Light Events - Premium Management'**
  String get appTitle;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back to'**
  String get welcomeBack;

  /// No description provided for @brandName.
  ///
  /// In en, this message translates to:
  /// **'Moon Light Events'**
  String get brandName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Making your special moments magical.\nPremium event planning and management for your unforgettable celebrations.'**
  String get tagline;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @searchReturns.
  ///
  /// In en, this message translates to:
  /// **'Search Returns'**
  String get searchReturns;

  /// No description provided for @serverErrorTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverErrorTryAgainLater;

  /// No description provided for @accessDashboard.
  ///
  /// In en, this message translates to:
  /// **'Access your premium dashboard'**
  String get accessDashboard;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @deactivatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deactivated successfully'**
  String get deactivatedSuccessfully;

  /// No description provided for @showing.
  ///
  /// In en, this message translates to:
  /// **'Showing'**
  String get showing;

  /// No description provided for @pleaseConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Please confirm this action'**
  String get pleaseConfirmAction;

  /// No description provided for @deletedPermanently.
  ///
  /// In en, this message translates to:
  /// **'Deleted permanently'**
  String get deletedPermanently;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get failedToDelete;

  /// No description provided for @pleaseConfirmConsequences.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Are you sure?'**
  String get pleaseConfirmConsequences;

  /// No description provided for @pleaseTypeVendorName.
  ///
  /// In en, this message translates to:
  /// **'Please type \'{vendorName}\' to confirm'**
  String pleaseTypeVendorName(Object vendorName);

  /// No description provided for @pleaseCompleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Please complete the confirmation step'**
  String get pleaseCompleteConfirmation;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Login successful.'**
  String get loginSuccess;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your credentials.'**
  String get loginFailed;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unexpectedError;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @receipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receipts;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @vendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendor;

  /// No description provided for @zakat.
  ///
  /// In en, this message translates to:
  /// **'Zakat'**
  String get zakat;

  /// No description provided for @profitLoss.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get profitLoss;

  /// No description provided for @advancePayment.
  ///
  /// In en, this message translates to:
  /// **'Advance Payment'**
  String get advancePayment;

  /// No description provided for @receivables.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get receivables;

  /// No description provided for @payables.
  ///
  /// In en, this message translates to:
  /// **'Payables'**
  String get payables;

  /// No description provided for @principalAccount.
  ///
  /// In en, this message translates to:
  /// **'Principal Account'**
  String get principalAccount;

  /// No description provided for @returns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get returns;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String error(String error);

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @posSystem.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get posSystem;

  /// No description provided for @selectProductsManageSales.
  ///
  /// In en, this message translates to:
  /// **'Select products and manage sales transactions'**
  String get selectProductsManageSales;

  /// No description provided for @todaySales.
  ///
  /// In en, this message translates to:
  /// **'Today Sales'**
  String get todaySales;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @purchasesTagline.
  ///
  /// In en, this message translates to:
  /// **'Track and manage inventory supply and purchase records'**
  String get purchasesTagline;

  /// No description provided for @newPurchase.
  ///
  /// In en, this message translates to:
  /// **'New Purchase'**
  String get newPurchase;

  /// No description provided for @totalInvestment.
  ///
  /// In en, this message translates to:
  /// **'Total Investment'**
  String get totalInvestment;

  /// No description provided for @enterInvoiceRef.
  ///
  /// In en, this message translates to:
  /// **'Enter Invoice Reference'**
  String get enterInvoiceRef;

  /// No description provided for @purchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get purchaseDate;

  /// No description provided for @purchasedProducts.
  ///
  /// In en, this message translates to:
  /// **'Purchased Products'**
  String get purchasedProducts;

  /// No description provided for @addProductRow.
  ///
  /// In en, this message translates to:
  /// **'Add Product Row'**
  String get addProductRow;

  /// No description provided for @unitCost.
  ///
  /// In en, this message translates to:
  /// **'Unit Cost'**
  String get unitCost;

  /// No description provided for @taxAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Tax / Adjustment'**
  String get taxAdjustment;

  /// No description provided for @savePurchase.
  ///
  /// In en, this message translates to:
  /// **'Save Purchase'**
  String get savePurchase;

  /// No description provided for @validationError.
  ///
  /// In en, this message translates to:
  /// **'Validation Error'**
  String get validationError;

  /// No description provided for @enterInvoiceNumberError.
  ///
  /// In en, this message translates to:
  /// **'Please enter an Invoice Number.'**
  String get enterInvoiceNumberError;

  /// No description provided for @selectVendorError.
  ///
  /// In en, this message translates to:
  /// **'Please select a Vendor.'**
  String get selectVendorError;

  /// No description provided for @addOneProductError.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one product to the purchase.'**
  String get addOneProductError;

  /// No description provided for @selectProductError.
  ///
  /// In en, this message translates to:
  /// **'Item #{itemIndex}: Please select a product.'**
  String selectProductError(Object itemIndex);

  /// No description provided for @invalidQtyError.
  ///
  /// In en, this message translates to:
  /// **'Item #{itemIndex}: Quantity must be greater than 0.'**
  String invalidQtyError(Object itemIndex);

  /// No description provided for @savePurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save purchase'**
  String get savePurchaseFailed;

  /// No description provided for @purchaseDetails.
  ///
  /// In en, this message translates to:
  /// **'Purchase Details'**
  String get purchaseDetails;

  /// No description provided for @purchasedItems.
  ///
  /// In en, this message translates to:
  /// **'Purchased Items'**
  String get purchasedItems;

  /// No description provided for @printInvoice.
  ///
  /// In en, this message translates to:
  /// **'Print Invoice'**
  String get printInvoice;

  /// No description provided for @filterPurchases.
  ///
  /// In en, this message translates to:
  /// **'Filter Purchases'**
  String get filterPurchases;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From Date'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To Date'**
  String get toDate;

  /// No description provided for @resetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get resetAll;

  /// No description provided for @unknownVendor.
  ///
  /// In en, this message translates to:
  /// **'Unknown Vendor'**
  String get unknownVendor;

  /// No description provided for @deletePurchaseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this purchase?'**
  String get deletePurchaseConfirm;

  /// No description provided for @noPurchasesFound.
  ///
  /// In en, this message translates to:
  /// **'No Purchases Found'**
  String get noPurchasesFound;

  /// No description provided for @noPurchasesMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No purchases match the current filter'**
  String get noPurchasesMatchFilter;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @currentTime.
  ///
  /// In en, this message translates to:
  /// **'Current Time'**
  String get currentTime;

  /// No description provided for @salesHistory.
  ///
  /// In en, this message translates to:
  /// **'Sales Transaction History'**
  String get salesHistory;

  /// No description provided for @viewManageSales.
  ///
  /// In en, this message translates to:
  /// **'View and manage all sales transactions'**
  String get viewManageSales;

  /// No description provided for @searchSales.
  ///
  /// In en, this message translates to:
  /// **'Search sales by invoice, customer, phone...'**
  String get searchSales;

  /// No description provided for @allStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get allStatus;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportingSalesData.
  ///
  /// In en, this message translates to:
  /// **'Exporting sales data...'**
  String get exportingSalesData;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @searchProductsExpanded.
  ///
  /// In en, this message translates to:
  /// **'Search products by name, color, fabric...'**
  String get searchProductsExpanded;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @screenTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Screen Too Small'**
  String get screenTooSmall;

  /// No description provided for @screenTooSmallMessage.
  ///
  /// In en, this message translates to:
  /// **'This application requires a minimum screen width of 750px for optimal experience. Please use a larger screen or rotate your device.'**
  String get screenTooSmallMessage;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @removeFromCart.
  ///
  /// In en, this message translates to:
  /// **'Remove from Cart'**
  String get removeFromCart;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear Cart'**
  String get clearCart;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get selectCustomer;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get paidAmount;

  /// No description provided for @remainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining Amount'**
  String get remainingAmount;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged out. See you soon!'**
  String get logoutSuccess;

  /// No description provided for @notEnoughStock.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock'**
  String get notEnoughStock;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @cartIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Cart is Empty'**
  String get cartIsEmpty;

  /// No description provided for @addProductsToStartSale.
  ///
  /// In en, this message translates to:
  /// **'Add products to start a sale'**
  String get addProductsToStartSale;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @walkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Customer'**
  String get walkInCustomer;

  /// No description provided for @proceedToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Checkout'**
  String get proceedToCheckout;

  /// No description provided for @clearCartQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all items from the cart?'**
  String get clearCartQuestion;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No Products Found'**
  String get noProductsFound;

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Products Available'**
  String get noProductsAvailable;

  /// No description provided for @tryAdjustingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filter criteria'**
  String get tryAdjustingSearch;

  /// No description provided for @addProductsToInventory.
  ///
  /// In en, this message translates to:
  /// **'Add products to your inventory to start selling'**
  String get addProductsToInventory;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @productsManagement.
  ///
  /// In en, this message translates to:
  /// **'Products Management'**
  String get productsManagement;

  /// No description provided for @productManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage product inventory and details with comprehensive tools'**
  String get productManagementDescription;

  /// No description provided for @manageInventory.
  ///
  /// In en, this message translates to:
  /// **'Manage inventory'**
  String get manageInventory;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @exportCompleted.
  ///
  /// In en, this message translates to:
  /// **'Export completed!'**
  String get exportCompleted;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @totalProducts.
  ///
  /// In en, this message translates to:
  /// **'Total Products'**
  String get totalProducts;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock'**
  String get inStock;

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValue;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @searchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search products by ID, name, color, fabric, or pieces...'**
  String get searchProductsHint;

  /// No description provided for @customerManagement.
  ///
  /// In en, this message translates to:
  /// **'Customer Management'**
  String get customerManagement;

  /// No description provided for @customerManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Organize and manage your customer relationships with comprehensive tools'**
  String get customerManagementDescription;

  /// No description provided for @customerManagementShortDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage customer relationships'**
  String get customerManagementShortDescription;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @totalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get totalCustomers;

  /// No description provided for @newThisMonth.
  ///
  /// In en, this message translates to:
  /// **'New This Month'**
  String get newThisMonth;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSales;

  /// No description provided for @recentBuyers.
  ///
  /// In en, this message translates to:
  /// **'Recent Buyers'**
  String get recentBuyers;

  /// No description provided for @newCustomer.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newCustomer;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @searchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers by name, phone, email...'**
  String get searchCustomersHint;

  /// No description provided for @searchCustomersShortHint.
  ///
  /// In en, this message translates to:
  /// **'Search customers...'**
  String get searchCustomersShortHint;

  /// No description provided for @hideInactive.
  ///
  /// In en, this message translates to:
  /// **'Hide Inactive'**
  String get hideInactive;

  /// No description provided for @showInactive.
  ///
  /// In en, this message translates to:
  /// **'Show Inactive'**
  String get showInactive;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @customerDataExported.
  ///
  /// In en, this message translates to:
  /// **'Customer data exported successfully'**
  String get customerDataExported;

  /// No description provided for @failedToExportData.
  ///
  /// In en, this message translates to:
  /// **'Failed to export data'**
  String get failedToExportData;

  /// No description provided for @loadingCustomers.
  ///
  /// In en, this message translates to:
  /// **'Loading customers...'**
  String get loadingCustomers;

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// No description provided for @adjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or adding new customers.'**
  String get adjustFilters;

  /// No description provided for @failedToRefreshCustomers.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh customers'**
  String get failedToRefreshCustomers;

  /// No description provided for @viewLedger.
  ///
  /// In en, this message translates to:
  /// **'View Ledger'**
  String get viewLedger;

  /// No description provided for @addNewCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add New Customer'**
  String get addNewCustomer;

  /// No description provided for @createNewCustomerProfile.
  ///
  /// In en, this message translates to:
  /// **'Create a new customer profile'**
  String get createNewCustomerProfile;

  /// No description provided for @customerAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Customer added successfully'**
  String get customerAddedSuccessfully;

  /// No description provided for @failedToAddCustomer.
  ///
  /// In en, this message translates to:
  /// **'Failed to add customer'**
  String get failedToAddCustomer;

  /// No description provided for @lastPurchase.
  ///
  /// In en, this message translates to:
  /// **'Last Purchase'**
  String get lastPurchase;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from your account?'**
  String get logoutMessage;

  /// No description provided for @logoutError.
  ///
  /// In en, this message translates to:
  /// **'Logged out locally due to an error.'**
  String get logoutError;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'Premium POS'**
  String get brandTagline;

  /// No description provided for @welcomeToPos.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Moon Light Events'**
  String get welcomeToPos;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Premium Event Management - Your Complete Celebration Solution'**
  String get welcomeTagline;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @activeCustomers.
  ///
  /// In en, this message translates to:
  /// **'Active Customers'**
  String get activeCustomers;

  /// No description provided for @activeVendors.
  ///
  /// In en, this message translates to:
  /// **'Active Vendors'**
  String get activeVendors;

  /// No description provided for @pendingReturns.
  ///
  /// In en, this message translates to:
  /// **'Pending Returns'**
  String get pendingReturns;

  /// No description provided for @salesOverview.
  ///
  /// In en, this message translates to:
  /// **'Sales Overview'**
  String get salesOverview;

  /// No description provided for @last6Months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months performance'**
  String get last6Months;

  /// No description provided for @revenueTarget.
  ///
  /// In en, this message translates to:
  /// **'Revenue Target'**
  String get revenueTarget;

  /// No description provided for @customerGrowth.
  ///
  /// In en, this message translates to:
  /// **'Customer Growth'**
  String get customerGrowth;

  /// No description provided for @vendorPartnerships.
  ///
  /// In en, this message translates to:
  /// **'Vendor Partnerships'**
  String get vendorPartnerships;

  /// No description provided for @conversionRate.
  ///
  /// In en, this message translates to:
  /// **'Conversion Rate'**
  String get conversionRate;

  /// No description provided for @topCustomers.
  ///
  /// In en, this message translates to:
  /// **'Top Customers'**
  String get topCustomers;

  /// No description provided for @vipCustomer.
  ///
  /// In en, this message translates to:
  /// **'VIP Customer'**
  String get vipCustomer;

  /// No description provided for @corporateClient.
  ///
  /// In en, this message translates to:
  /// **'Corporate Client'**
  String get corporateClient;

  /// No description provided for @regularCustomer.
  ///
  /// In en, this message translates to:
  /// **'Regular Customer'**
  String get regularCustomer;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @newCustomerRegistered.
  ///
  /// In en, this message translates to:
  /// **'New customer registered'**
  String get newCustomerRegistered;

  /// No description provided for @newVendorRegistered.
  ///
  /// In en, this message translates to:
  /// **'New vendor registered'**
  String get newVendorRegistered;

  /// No description provided for @customerPurchaseCompleted.
  ///
  /// In en, this message translates to:
  /// **'Customer purchase completed'**
  String get customerPurchaseCompleted;

  /// No description provided for @vendorDeliveryReceived.
  ///
  /// In en, this message translates to:
  /// **'Vendor delivery received'**
  String get vendorDeliveryReceived;

  /// No description provided for @underConstruction.
  ///
  /// In en, this message translates to:
  /// **'This page is under construction.'**
  String get underConstruction;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon with amazing features!'**
  String get comingSoon;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get newOrder;

  /// No description provided for @createOrder.
  ///
  /// In en, this message translates to:
  /// **'Create order'**
  String get createOrder;

  /// No description provided for @processPayment.
  ///
  /// In en, this message translates to:
  /// **'Process payment'**
  String get processPayment;

  /// No description provided for @viewAnalytics.
  ///
  /// In en, this message translates to:
  /// **'View analytics'**
  String get viewAnalytics;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @recentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get recentOrders;

  /// No description provided for @monthlyPerformance.
  ///
  /// In en, this message translates to:
  /// **'Monthly Performance'**
  String get monthlyPerformance;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @searchProductsShortHint.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProductsShortHint;

  /// No description provided for @premiumCustomer.
  ///
  /// In en, this message translates to:
  /// **'Premium Customer'**
  String get premiumCustomer;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderItems;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @generated.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get generated;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @viewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get viewed;

  /// No description provided for @issued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get issued;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @createReceipt.
  ///
  /// In en, this message translates to:
  /// **'Create Receipt'**
  String get createReceipt;

  /// No description provided for @updateReceipt.
  ///
  /// In en, this message translates to:
  /// **'Update Receipt'**
  String get updateReceipt;

  /// No description provided for @creatingOrder.
  ///
  /// In en, this message translates to:
  /// **'Creating Order...'**
  String get creatingOrder;

  /// No description provided for @noSalesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No sales available'**
  String get noSalesAvailable;

  /// No description provided for @noReceiptsFound.
  ///
  /// In en, this message translates to:
  /// **'No receipts found'**
  String get noReceiptsFound;

  /// No description provided for @receiptCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Receipt created successfully'**
  String get receiptCreatedSuccessfully;

  /// No description provided for @receiptUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Receipt updated successfully'**
  String get receiptUpdatedSuccessfully;

  /// No description provided for @receiptDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Receipt deleted successfully'**
  String get receiptDeletedSuccessfully;

  /// No description provided for @selectSale.
  ///
  /// In en, this message translates to:
  /// **'Select Sale'**
  String get selectSale;

  /// No description provided for @chooseSaleToCreateReceipt.
  ///
  /// In en, this message translates to:
  /// **'Choose a sale to create receipt for'**
  String get chooseSaleToCreateReceipt;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @pleaseSelectSale.
  ///
  /// In en, this message translates to:
  /// **'Please select a sale'**
  String get pleaseSelectSale;

  /// No description provided for @additionalReceiptNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional receipt notes (optional)'**
  String get additionalReceiptNotes;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdated;

  /// No description provided for @weekAgo.
  ///
  /// In en, this message translates to:
  /// **'week ago'**
  String get weekAgo;

  /// No description provided for @monthAgo.
  ///
  /// In en, this message translates to:
  /// **'month ago'**
  String get monthAgo;

  /// No description provided for @yearAgo.
  ///
  /// In en, this message translates to:
  /// **'year ago'**
  String get yearAgo;

  /// No description provided for @characters.
  ///
  /// In en, this message translates to:
  /// **'characters'**
  String get characters;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @manageProductCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage product categories'**
  String get manageProductCategories;

  /// No description provided for @searchCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Search categories by name, ID, or description'**
  String get searchCategoriesHint;

  /// No description provided for @growth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get growth;

  /// No description provided for @cities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get cities;

  /// No description provided for @citiesCovered.
  ///
  /// In en, this message translates to:
  /// **'Cities Covered'**
  String get citiesCovered;

  /// No description provided for @searchVendorsHint.
  ///
  /// In en, this message translates to:
  /// **'Search vendors by name, business, CNIC, or phone'**
  String get searchVendorsHint;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @pleaseFixErrors.
  ///
  /// In en, this message translates to:
  /// **'Please fix the following errors'**
  String get pleaseFixErrors;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @businessInformation.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformation;

  /// No description provided for @additionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInformation;

  /// No description provided for @locationInformation.
  ///
  /// In en, this message translates to:
  /// **'Location Information'**
  String get locationInformation;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @pleaseEnter.
  ///
  /// In en, this message translates to:
  /// **'Please enter'**
  String get pleaseEnter;

  /// No description provided for @mustBeAtLeast.
  ///
  /// In en, this message translates to:
  /// **'must be at least'**
  String get mustBeAtLeast;

  /// No description provided for @mustBeLessThan.
  ///
  /// In en, this message translates to:
  /// **'must be less than'**
  String get mustBeLessThan;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @cnic.
  ///
  /// In en, this message translates to:
  /// **'CNIC'**
  String get cnic;

  /// No description provided for @cnicFormat.
  ///
  /// In en, this message translates to:
  /// **'XXXXX-XXXXXXX-X'**
  String get cnicFormat;

  /// No description provided for @pleaseEnterValid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid'**
  String get pleaseEnterValid;

  /// No description provided for @phoneFormat.
  ///
  /// In en, this message translates to:
  /// **'+923001234567'**
  String get phoneFormat;

  /// No description provided for @outOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get outOf;

  /// No description provided for @refineVendorList.
  ///
  /// In en, this message translates to:
  /// **'Refine your vendor list with filters'**
  String get refineVendorList;

  /// No description provided for @showInactiveVendorsOnly.
  ///
  /// In en, this message translates to:
  /// **'Show inactive vendors only'**
  String get showInactiveVendorsOnly;

  /// No description provided for @onlyDeactivatedVendorsShown.
  ///
  /// In en, this message translates to:
  /// **'Only deactivated vendors will be shown'**
  String get onlyDeactivatedVendorsShown;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @clearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear All Filters'**
  String get clearAllFilters;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @areYouSureDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate'**
  String get areYouSureDeactivate;

  /// No description provided for @actionCanBeReversed.
  ///
  /// In en, this message translates to:
  /// **'This action can be reversed'**
  String get actionCanBeReversed;

  /// No description provided for @failedToDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Failed to deactivate'**
  String get failedToDeactivate;

  /// No description provided for @areYouSureRestore.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore'**
  String get areYouSureRestore;

  /// No description provided for @failedToRestore.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore'**
  String get failedToRestore;

  /// No description provided for @restoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'restored successfully'**
  String get restoredSuccessfully;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load'**
  String get failedToLoad;

  /// No description provided for @noVendorsFound.
  ///
  /// In en, this message translates to:
  /// **'No Vendors Found'**
  String get noVendorsFound;

  /// No description provided for @startByAddingFirstVendor.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first vendor to manage your suppliers effectively'**
  String get startByAddingFirstVendor;

  /// No description provided for @firstVendor.
  ///
  /// In en, this message translates to:
  /// **'First Vendor'**
  String get firstVendor;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @since.
  ///
  /// In en, this message translates to:
  /// **'since'**
  String get since;

  /// No description provided for @daysOld.
  ///
  /// In en, this message translates to:
  /// **'days old'**
  String get daysOld;

  /// No description provided for @fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get fullAddress;

  /// No description provided for @activitySummary.
  ///
  /// In en, this message translates to:
  /// **'Activity Summary'**
  String get activitySummary;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @updatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'updated successfully'**
  String get updatedSuccessfully;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get failedToUpdate;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'updating'**
  String get updating;

  /// No description provided for @noChangesDetected.
  ///
  /// In en, this message translates to:
  /// **'No changes detected'**
  String get noChangesDetected;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get discardChanges;

  /// No description provided for @discardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to discard them?'**
  String get discardChangesMessage;

  /// No description provided for @continueEditing.
  ///
  /// In en, this message translates to:
  /// **'Continue Editing'**
  String get continueEditing;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @modified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get modified;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @newProduct.
  ///
  /// In en, this message translates to:
  /// **'New Product'**
  String get newProduct;

  /// No description provided for @createNewProductEntry.
  ///
  /// In en, this message translates to:
  /// **'Create a new product entry'**
  String get createNewProductEntry;

  /// No description provided for @detail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detail;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @costPriceCannotExceedSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost price cannot exceed selling price'**
  String get costPriceCannotExceedSellingPrice;

  /// No description provided for @costPriceInfo.
  ///
  /// In en, this message translates to:
  /// **'Setting cost price enables profit margin calculations and better financial analysis'**
  String get costPriceInfo;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @colorName.
  ///
  /// In en, this message translates to:
  /// **'Color Name'**
  String get colorName;

  /// No description provided for @fabricType.
  ///
  /// In en, this message translates to:
  /// **'Fabric Type'**
  String get fabricType;

  /// No description provided for @fabricName.
  ///
  /// In en, this message translates to:
  /// **'Fabric Name'**
  String get fabricName;

  /// No description provided for @pleaseSelectAtLeastOnePiece.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one piece'**
  String get pleaseSelectAtLeastOnePiece;

  /// No description provided for @failedToAdd.
  ///
  /// In en, this message translates to:
  /// **'Failed to add'**
  String get failedToAdd;

  /// No description provided for @addedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'added successfully'**
  String get addedSuccessfully;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @pleaseSelect.
  ///
  /// In en, this message translates to:
  /// **'Please select'**
  String get pleaseSelect;

  /// No description provided for @labors.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get labors;

  /// No description provided for @laborManagement.
  ///
  /// In en, this message translates to:
  /// **'Employee Management'**
  String get laborManagement;

  /// No description provided for @laborManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Organize and manage your employee workforce with comprehensive tools'**
  String get laborManagementDescription;

  /// No description provided for @organizeAndManageLaborWorkforce.
  ///
  /// In en, this message translates to:
  /// **'Organize and manage employee workforce'**
  String get organizeAndManageLaborWorkforce;

  /// No description provided for @manageLaborWorkforce.
  ///
  /// In en, this message translates to:
  /// **'Manage employee workforce'**
  String get manageLaborWorkforce;

  /// No description provided for @failedToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh'**
  String get failedToRefresh;

  /// No description provided for @preparingExport.
  ///
  /// In en, this message translates to:
  /// **'Preparing export...'**
  String get preparingExport;

  /// No description provided for @dataExportCompleted.
  ///
  /// In en, this message translates to:
  /// **'data export completed successfully'**
  String get dataExportCompleted;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @searchLaborsHint.
  ///
  /// In en, this message translates to:
  /// **'Search employees by name, CNIC, phone, role...'**
  String get searchLaborsHint;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @designation.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get designation;

  /// No description provided for @caste.
  ///
  /// In en, this message translates to:
  /// **'Caste'**
  String get caste;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @receivable.
  ///
  /// In en, this message translates to:
  /// **'Receivable'**
  String get receivable;

  /// No description provided for @receivablesManagement.
  ///
  /// In en, this message translates to:
  /// **'Receivables Management'**
  String get receivablesManagement;

  /// No description provided for @receivablesManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Track and manage amounts lent to customers and suppliers'**
  String get receivablesManagementDescription;

  /// No description provided for @manageAmountsLent.
  ///
  /// In en, this message translates to:
  /// **'Manage amounts lent'**
  String get manageAmountsLent;

  /// No description provided for @amountsLent.
  ///
  /// In en, this message translates to:
  /// **'Amounts lent'**
  String get amountsLent;

  /// No description provided for @amountLent.
  ///
  /// In en, this message translates to:
  /// **'Amount Lent'**
  String get amountLent;

  /// No description provided for @amountReturned.
  ///
  /// In en, this message translates to:
  /// **'Amount Returned'**
  String get amountReturned;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @returned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get returned;

  /// No description provided for @searchReceivablesHint.
  ///
  /// In en, this message translates to:
  /// **'Search by debtor name, phone, reason, or notes...'**
  String get searchReceivablesHint;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @debtor.
  ///
  /// In en, this message translates to:
  /// **'Debtor'**
  String get debtor;

  /// No description provided for @debtorDetails.
  ///
  /// In en, this message translates to:
  /// **'Debtor Details'**
  String get debtorDetails;

  /// No description provided for @amounts.
  ///
  /// In en, this message translates to:
  /// **'Amounts'**
  String get amounts;

  /// No description provided for @reasonItem.
  ///
  /// In en, this message translates to:
  /// **'Reason/Item'**
  String get reasonItem;

  /// No description provided for @dates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get dates;

  /// No description provided for @returnDate.
  ///
  /// In en, this message translates to:
  /// **'Return Date'**
  String get returnDate;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// No description provided for @lent.
  ///
  /// In en, this message translates to:
  /// **'Lent'**
  String get lent;

  /// No description provided for @daysOverdue.
  ///
  /// In en, this message translates to:
  /// **'days overdue'**
  String get daysOverdue;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @deleteText.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteText;

  /// No description provided for @noReceivablesFound.
  ///
  /// In en, this message translates to:
  /// **'No Receivables Found'**
  String get noReceivablesFound;

  /// No description provided for @startByAddingFirstReceivable.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first receivable record to track amounts lent to customers and suppliers'**
  String get startByAddingFirstReceivable;

  /// No description provided for @firstReceivable.
  ///
  /// In en, this message translates to:
  /// **'First Receivable'**
  String get firstReceivable;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @deactivateVendor.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Vendor'**
  String get deactivateVendor;

  /// No description provided for @actionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get actionCannotBeUndone;

  /// No description provided for @vendorCanBeRestoredLater.
  ///
  /// In en, this message translates to:
  /// **'Vendor can be restored later'**
  String get vendorCanBeRestoredLater;

  /// No description provided for @permanentDeletionWarning.
  ///
  /// In en, this message translates to:
  /// **'Permanent Deletion Warning'**
  String get permanentDeletionWarning;

  /// No description provided for @deactivationNotice.
  ///
  /// In en, this message translates to:
  /// **'Deactivation Notice'**
  String get deactivationNotice;

  /// No description provided for @permanentDeletionWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove all vendor data from the database. This action cannot be reversed.'**
  String get permanentDeletionWarningMessage;

  /// No description provided for @deactivationNoticeMessage.
  ///
  /// In en, this message translates to:
  /// **'This will deactivate the vendor but preserve all data. The vendor can be restored later if needed.'**
  String get deactivationNoticeMessage;

  /// No description provided for @chooseDeletionType.
  ///
  /// In en, this message translates to:
  /// **'Choose deletion type:'**
  String get chooseDeletionType;

  /// No description provided for @permanentDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanent Delete'**
  String get permanentDelete;

  /// No description provided for @removesFromDatabasePermanently.
  ///
  /// In en, this message translates to:
  /// **'Removes from database permanently'**
  String get removesFromDatabasePermanently;

  /// No description provided for @hideButCanBeRestored.
  ///
  /// In en, this message translates to:
  /// **'Hide but can be restored'**
  String get hideButCanBeRestored;

  /// No description provided for @vendorSince.
  ///
  /// In en, this message translates to:
  /// **'Vendor since'**
  String get vendorSince;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @understandPermanentDeletion.
  ///
  /// In en, this message translates to:
  /// **'I understand this will permanently delete the vendor'**
  String get understandPermanentDeletion;

  /// No description provided for @understandDeactivation.
  ///
  /// In en, this message translates to:
  /// **'I understand this will deactivate the vendor'**
  String get understandDeactivation;

  /// No description provided for @understandActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'I understand this action cannot be undone and will affect related records'**
  String get understandActionCannotBeUndone;

  /// No description provided for @typeVendorNameToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type the vendor name to confirm permanent deletion:'**
  String get typeVendorNameToConfirm;

  /// No description provided for @expected.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get expected;

  /// No description provided for @payable.
  ///
  /// In en, this message translates to:
  /// **'Payable'**
  String get payable;

  /// No description provided for @payablesManagement.
  ///
  /// In en, this message translates to:
  /// **'Payables Management'**
  String get payablesManagement;

  /// No description provided for @payablesManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Track and manage amounts owed to creditors efficiently'**
  String get payablesManagementDescription;

  /// No description provided for @manageCreditorPayables.
  ///
  /// In en, this message translates to:
  /// **'Manage creditor payables'**
  String get manageCreditorPayables;

  /// No description provided for @creditorPayables.
  ///
  /// In en, this message translates to:
  /// **'Creditor payables'**
  String get creditorPayables;

  /// No description provided for @totalPayables.
  ///
  /// In en, this message translates to:
  /// **'Total Payables'**
  String get totalPayables;

  /// No description provided for @totalBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Total Borrowed'**
  String get totalBorrowed;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @balanceDue.
  ///
  /// In en, this message translates to:
  /// **'Balance Due'**
  String get balanceDue;

  /// No description provided for @borrowed.
  ///
  /// In en, this message translates to:
  /// **'Borrowed'**
  String get borrowed;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @searchPayablesHint.
  ///
  /// In en, this message translates to:
  /// **'Search by ID, creditor name, phone, reason, or status...'**
  String get searchPayablesHint;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @paymentManagement.
  ///
  /// In en, this message translates to:
  /// **'Payment Management'**
  String get paymentManagement;

  /// No description provided for @paymentManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Track and manage employee salary payments efficiently'**
  String get paymentManagementDescription;

  /// No description provided for @trackManageSalaryPayments.
  ///
  /// In en, this message translates to:
  /// **'Track and manage salary payments'**
  String get trackManageSalaryPayments;

  /// No description provided for @trackSalaryPayments.
  ///
  /// In en, this message translates to:
  /// **'Track salary payments'**
  String get trackSalaryPayments;

  /// No description provided for @totalRecords.
  ///
  /// In en, this message translates to:
  /// **'Total Records'**
  String get totalRecords;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @searchPaymentsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by ID, employee name, payment method, month, or description...'**
  String get searchPaymentsHint;

  /// No description provided for @advancePaymentManagement.
  ///
  /// In en, this message translates to:
  /// **'Advance Payment Management'**
  String get advancePaymentManagement;

  /// No description provided for @advancePaymentManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Track and manage employee advance payments efficiently'**
  String get advancePaymentManagementDescription;

  /// No description provided for @advancePayments.
  ///
  /// In en, this message translates to:
  /// **'Advance Payments'**
  String get advancePayments;

  /// No description provided for @manageLaborPayments.
  ///
  /// In en, this message translates to:
  /// **'Manage employee payments'**
  String get manageLaborPayments;

  /// No description provided for @totalPayments.
  ///
  /// In en, this message translates to:
  /// **'Total Payments'**
  String get totalPayments;

  /// No description provided for @withReceipts.
  ///
  /// In en, this message translates to:
  /// **'With Receipts'**
  String get withReceipts;

  /// No description provided for @loadingAdvancePayments.
  ///
  /// In en, this message translates to:
  /// **'Loading advance payments...'**
  String get loadingAdvancePayments;

  /// No description provided for @searchAdvancePaymentsHint.
  ///
  /// In en, this message translates to:
  /// **'Search by ID, employee name, phone, role, or description...'**
  String get searchAdvancePaymentsHint;

  /// No description provided for @dataRefreshedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data refreshed successfully'**
  String get dataRefreshedSuccessfully;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @expensesManagement.
  ///
  /// In en, this message translates to:
  /// **'Expenses Management'**
  String get expensesManagement;

  /// No description provided for @expensesManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Track and manage business expenses efficiently'**
  String get expensesManagementDescription;

  /// No description provided for @trackBusinessExpenses.
  ///
  /// In en, this message translates to:
  /// **'Track business expenses'**
  String get trackBusinessExpenses;

  /// No description provided for @trackExpenses.
  ///
  /// In en, this message translates to:
  /// **'Track expenses'**
  String get trackExpenses;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @searchExpensesHint.
  ///
  /// In en, this message translates to:
  /// **'Search expenses by ID, type, description, amount, or person...'**
  String get searchExpensesHint;

  /// No description provided for @zakatManagement.
  ///
  /// In en, this message translates to:
  /// **'Zakat Management'**
  String get zakatManagement;

  /// No description provided for @zakatManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Track and manage zakat contributions efficiently'**
  String get zakatManagementDescription;

  /// No description provided for @trackZakatContributions.
  ///
  /// In en, this message translates to:
  /// **'Track zakat contributions'**
  String get trackZakatContributions;

  /// No description provided for @trackContributions.
  ///
  /// In en, this message translates to:
  /// **'Track contributions'**
  String get trackContributions;

  /// No description provided for @searchZakatHint.
  ///
  /// In en, this message translates to:
  /// **'Search zakat by ID, title, beneficiary, or amount...'**
  String get searchZakatHint;

  /// No description provided for @profitLossStatement.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss Statement'**
  String get profitLossStatement;

  /// No description provided for @profitLossStatementDescription.
  ///
  /// In en, this message translates to:
  /// **'Financial performance analysis and profitability tracking'**
  String get profitLossStatementDescription;

  /// No description provided for @profitLossShort.
  ///
  /// In en, this message translates to:
  /// **'P&L'**
  String get profitLossShort;

  /// No description provided for @financialPerformanceAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Financial performance analysis'**
  String get financialPerformanceAnalysis;

  /// No description provided for @financialAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Financial analysis'**
  String get financialAnalysis;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @calculatingProfitLoss.
  ///
  /// In en, this message translates to:
  /// **'Calculating Profit & Loss...'**
  String get calculatingProfitLoss;

  /// No description provided for @noFinancialDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Financial Data Available'**
  String get noFinancialDataAvailable;

  /// No description provided for @selectPeriodToViewAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Select a period to view profit and loss analysis'**
  String get selectPeriodToViewAnalysis;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @expenseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Expense Breakdown'**
  String get expenseBreakdown;

  /// No description provided for @ofExpenses.
  ///
  /// In en, this message translates to:
  /// **'of expenses'**
  String get ofExpenses;

  /// No description provided for @profitable.
  ///
  /// In en, this message translates to:
  /// **'PROFITABLE'**
  String get profitable;

  /// No description provided for @loss.
  ///
  /// In en, this message translates to:
  /// **'LOSS'**
  String get loss;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @clearErrors.
  ///
  /// In en, this message translates to:
  /// **'Clear Errors'**
  String get clearErrors;

  /// No description provided for @operationCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Operation completed successfully'**
  String get operationCompletedSuccessfully;

  /// No description provided for @taxManagement.
  ///
  /// In en, this message translates to:
  /// **'Tax Management'**
  String get taxManagement;

  /// No description provided for @taxManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage tax rates and configurations'**
  String get taxManagementDescription;

  /// No description provided for @addTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Add Tax Rate'**
  String get addTaxRate;

  /// No description provided for @searchTaxRatesHint.
  ///
  /// In en, this message translates to:
  /// **'Search tax rates...'**
  String get searchTaxRatesHint;

  /// No description provided for @taxRates.
  ///
  /// In en, this message translates to:
  /// **'Tax Rates'**
  String get taxRates;

  /// No description provided for @noTaxRatesFound.
  ///
  /// In en, this message translates to:
  /// **'No Tax Rates Found'**
  String get noTaxRatesFound;

  /// No description provided for @addFirstTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Add your first tax rate to get started'**
  String get addFirstTaxRate;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @totalTaxRates.
  ///
  /// In en, this message translates to:
  /// **'Total Tax Rates'**
  String get totalTaxRates;

  /// No description provided for @activeRates.
  ///
  /// In en, this message translates to:
  /// **'Active Rates'**
  String get activeRates;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @deleteTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Delete Tax Rate'**
  String get deleteTaxRate;

  /// No description provided for @deleteTaxRateConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get deleteTaxRateConfirmation;

  /// No description provided for @editTaxRate.
  ///
  /// In en, this message translates to:
  /// **'Edit Tax Rate'**
  String get editTaxRate;

  /// No description provided for @taxName.
  ///
  /// In en, this message translates to:
  /// **'Tax Name'**
  String get taxName;

  /// No description provided for @taxType.
  ///
  /// In en, this message translates to:
  /// **'Tax Type'**
  String get taxType;

  /// No description provided for @taxPercentage.
  ///
  /// In en, this message translates to:
  /// **'Tax Percentage (%)'**
  String get taxPercentage;

  /// No description provided for @pleaseEnterTaxName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a tax name'**
  String get pleaseEnterTaxName;

  /// No description provided for @pleaseEnterTaxPercentage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a tax percentage'**
  String get pleaseEnterTaxPercentage;

  /// No description provided for @pleaseEnterValidPercentage.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid percentage (0-100)'**
  String get pleaseEnterValidPercentage;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @returnManagement.
  ///
  /// In en, this message translates to:
  /// **'Return Management'**
  String get returnManagement;

  /// No description provided for @titleReceiptManagement.
  ///
  /// In en, this message translates to:
  /// **'Receipt Management'**
  String get titleReceiptManagement;

  /// No description provided for @receivableDetails.
  ///
  /// In en, this message translates to:
  /// **'Receivable Details'**
  String get receivableDetails;

  /// No description provided for @viewCompleteReceivableInformation.
  ///
  /// In en, this message translates to:
  /// **'View complete receivable information'**
  String get viewCompleteReceivableInformation;

  /// No description provided for @debtorInformation.
  ///
  /// In en, this message translates to:
  /// **'Debtor Information'**
  String get debtorInformation;

  /// No description provided for @amountBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Amount Breakdown'**
  String get amountBreakdown;

  /// No description provided for @amountGiven.
  ///
  /// In en, this message translates to:
  /// **'Amount Given:'**
  String get amountGiven;

  /// No description provided for @balanceRemaining.
  ///
  /// In en, this message translates to:
  /// **'Balance Remaining:'**
  String get balanceRemaining;

  /// No description provided for @returnProgress.
  ///
  /// In en, this message translates to:
  /// **'Return Progress'**
  String get returnProgress;

  /// No description provided for @dateLent.
  ///
  /// In en, this message translates to:
  /// **'Date Lent'**
  String get dateLent;

  /// No description provided for @expectedReturnDate.
  ///
  /// In en, this message translates to:
  /// **'Expected Return Date'**
  String get expectedReturnDate;

  /// No description provided for @expectedReturn.
  ///
  /// In en, this message translates to:
  /// **'Expected Return'**
  String get expectedReturn;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @editReceivable.
  ///
  /// In en, this message translates to:
  /// **'Edit Receivable'**
  String get editReceivable;

  /// No description provided for @editReceivableDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Receivable Details'**
  String get editReceivableDetails;

  /// No description provided for @updateReceivableInformation.
  ///
  /// In en, this message translates to:
  /// **'Update receivable information'**
  String get updateReceivableInformation;

  /// No description provided for @debtorName.
  ///
  /// In en, this message translates to:
  /// **'Debtor Name'**
  String get debtorName;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @enterDebtorFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter debtor full name'**
  String get enterDebtorFullName;

  /// No description provided for @pleaseEnterDebtorName.
  ///
  /// In en, this message translates to:
  /// **'Please enter debtor name'**
  String get pleaseEnterDebtorName;

  /// No description provided for @nameMustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMustBeAtLeast2Characters;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Phone Number'**
  String get enterPhone;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number (+92XXXXXXXXXX)'**
  String get enterPhoneNumber;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @pleaseEnterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterValidPhoneNumber;

  /// No description provided for @amountGivenPkr.
  ///
  /// In en, this message translates to:
  /// **'Amount Given (PKR)'**
  String get amountGivenPkr;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get pleaseEnterAmount;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @amountReturnedPkr.
  ///
  /// In en, this message translates to:
  /// **'Amount Returned (PKR)'**
  String get amountReturnedPkr;

  /// No description provided for @enterReturned.
  ///
  /// In en, this message translates to:
  /// **'Enter returned'**
  String get enterReturned;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter valid amount'**
  String get enterValidAmount;

  /// No description provided for @cannotExceedAmountGiven.
  ///
  /// In en, this message translates to:
  /// **'Cannot exceed amount given'**
  String get cannotExceedAmountGiven;

  /// No description provided for @reasonForLending.
  ///
  /// In en, this message translates to:
  /// **'Reason for lending'**
  String get reasonForLending;

  /// No description provided for @enterReasonForLendingOrItemDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter reason for lending or item description'**
  String get enterReasonForLendingOrItemDescription;

  /// No description provided for @pleaseEnterReasonOrItem.
  ///
  /// In en, this message translates to:
  /// **'Please enter reason or item'**
  String get pleaseEnterReasonOrItem;

  /// No description provided for @pleaseProvideMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Please provide more details'**
  String get pleaseProvideMoreDetails;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notesOptional;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional notes'**
  String get additionalNotes;

  /// No description provided for @enterAdditionalNotesOrTerms.
  ///
  /// In en, this message translates to:
  /// **'Enter additional notes or terms'**
  String get enterAdditionalNotesOrTerms;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @updateReceivable.
  ///
  /// In en, this message translates to:
  /// **'Update Receivable'**
  String get updateReceivable;

  /// No description provided for @receivableUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Receivable updated successfully!'**
  String get receivableUpdatedSuccessfully;

  /// No description provided for @amountReturnedCannotExceedAmountGiven.
  ///
  /// In en, this message translates to:
  /// **'Amount returned cannot exceed amount given'**
  String get amountReturnedCannotExceedAmountGiven;

  /// No description provided for @expectedReturnDateCannotBeBeforeDateLent.
  ///
  /// In en, this message translates to:
  /// **'Expected return date cannot be before date lent'**
  String get expectedReturnDateCannotBeBeforeDateLent;

  /// No description provided for @addReceivable.
  ///
  /// In en, this message translates to:
  /// **'Add Receivable'**
  String get addReceivable;

  /// No description provided for @addNewReceivable.
  ///
  /// In en, this message translates to:
  /// **'Add New Receivable'**
  String get addNewReceivable;

  /// No description provided for @recordAmountLentToCustomerOrSupplier.
  ///
  /// In en, this message translates to:
  /// **'Record amount lent to customer or supplier'**
  String get recordAmountLentToCustomerOrSupplier;

  /// No description provided for @amountDetails.
  ///
  /// In en, this message translates to:
  /// **'Amount Details'**
  String get amountDetails;

  /// No description provided for @enterAmountGivenToDebtor.
  ///
  /// In en, this message translates to:
  /// **'Enter amount given to debtor'**
  String get enterAmountGivenToDebtor;

  /// No description provided for @pleaseEnterAmountGiven.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount given'**
  String get pleaseEnterAmountGiven;

  /// No description provided for @optionalIfAnyAmountAlreadyReturned.
  ///
  /// In en, this message translates to:
  /// **'Optional - if any amount already returned'**
  String get optionalIfAnyAmountAlreadyReturned;

  /// No description provided for @dateInformation.
  ///
  /// In en, this message translates to:
  /// **'Date Information'**
  String get dateInformation;

  /// No description provided for @lendingPeriod.
  ///
  /// In en, this message translates to:
  /// **'Lending period:'**
  String get lendingPeriod;

  /// No description provided for @pleaseSelectValidReturnDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid return date'**
  String get pleaseSelectValidReturnDate;

  /// No description provided for @receivableAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Receivable added successfully!'**
  String get receivableAddedSuccessfully;

  /// No description provided for @addLabor.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addLabor;

  /// No description provided for @addNewLabor.
  ///
  /// In en, this message translates to:
  /// **'Add New Employee'**
  String get addNewLabor;

  /// No description provided for @createNewLaborRecord.
  ///
  /// In en, this message translates to:
  /// **'Create a new employee record'**
  String get createNewLaborRecord;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get fullNameRequired;

  /// No description provided for @enterWorkersFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter worker\'s full name'**
  String get enterWorkersFullName;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get pleaseEnterName;

  /// No description provided for @nameMustBeLessThan50Characters.
  ///
  /// In en, this message translates to:
  /// **'Name must be less than 50 characters'**
  String get nameMustBeLessThan50Characters;

  /// No description provided for @cnicRequired.
  ///
  /// In en, this message translates to:
  /// **'CNIC *'**
  String get cnicRequired;

  /// No description provided for @enterCnic.
  ///
  /// In en, this message translates to:
  /// **'Enter CNIC'**
  String get enterCnic;

  /// No description provided for @enterCnicFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter CNIC (e.g., 42101-1234567-1)'**
  String get enterCnicFormat;

  /// No description provided for @pleaseEnterCnic.
  ///
  /// In en, this message translates to:
  /// **'Please enter a CNIC'**
  String get pleaseEnterCnic;

  /// No description provided for @pleaseEnterValidCnicFormat.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid CNIC (XXXXX-XXXXXXX-X)'**
  String get pleaseEnterValidCnicFormat;

  /// No description provided for @enterCaste.
  ///
  /// In en, this message translates to:
  /// **'Enter caste'**
  String get enterCaste;

  /// No description provided for @enterCasteOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter caste (optional)'**
  String get enterCasteOptional;

  /// No description provided for @phoneNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone Number *'**
  String get phoneNumberRequired;

  /// No description provided for @enterPhoneNumberFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number (e.g., +923001234567)'**
  String get enterPhoneNumberFormat;

  /// No description provided for @pleaseEnterValidPhoneNumberFormat.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number (+92XXXXXXXXXX)'**
  String get pleaseEnterValidPhoneNumberFormat;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City *'**
  String get cityRequired;

  /// No description provided for @enterCity.
  ///
  /// In en, this message translates to:
  /// **'Enter city'**
  String get enterCity;

  /// No description provided for @pleaseEnterCity.
  ///
  /// In en, this message translates to:
  /// **'Please enter city'**
  String get pleaseEnterCity;

  /// No description provided for @areaRequired.
  ///
  /// In en, this message translates to:
  /// **'Area *'**
  String get areaRequired;

  /// No description provided for @enterArea.
  ///
  /// In en, this message translates to:
  /// **'Enter area'**
  String get enterArea;

  /// No description provided for @pleaseEnterArea.
  ///
  /// In en, this message translates to:
  /// **'Please enter area'**
  String get pleaseEnterArea;

  /// No description provided for @employmentInformation.
  ///
  /// In en, this message translates to:
  /// **'Employment Information'**
  String get employmentInformation;

  /// No description provided for @designationRequired.
  ///
  /// In en, this message translates to:
  /// **'Role *'**
  String get designationRequired;

  /// No description provided for @enterDesignation.
  ///
  /// In en, this message translates to:
  /// **'Enter role'**
  String get enterDesignation;

  /// No description provided for @enterJobDesignation.
  ///
  /// In en, this message translates to:
  /// **'Enter job role (e.g., Tailor, Operator)'**
  String get enterJobDesignation;

  /// No description provided for @pleaseEnterDesignation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a role'**
  String get pleaseEnterDesignation;

  /// No description provided for @joiningDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Joining Date *'**
  String get joiningDateRequired;

  /// No description provided for @selectJoiningDate.
  ///
  /// In en, this message translates to:
  /// **'Select joining date'**
  String get selectJoiningDate;

  /// No description provided for @monthlySalaryRequired.
  ///
  /// In en, this message translates to:
  /// **'Monthly Salary *'**
  String get monthlySalaryRequired;

  /// No description provided for @enterSalary.
  ///
  /// In en, this message translates to:
  /// **'Enter salary'**
  String get enterSalary;

  /// No description provided for @enterMonthlySalaryInPkr.
  ///
  /// In en, this message translates to:
  /// **'Enter monthly salary in PKR'**
  String get enterMonthlySalaryInPkr;

  /// No description provided for @pleaseEnterSalary.
  ///
  /// In en, this message translates to:
  /// **'Please enter a salary'**
  String get pleaseEnterSalary;

  /// No description provided for @pleaseEnterValidSalary.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid salary'**
  String get pleaseEnterValidSalary;

  /// No description provided for @genderRequired.
  ///
  /// In en, this message translates to:
  /// **'Gender *'**
  String get genderRequired;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select gender'**
  String get selectGender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @pleaseSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Please select a gender'**
  String get pleaseSelectGender;

  /// No description provided for @ageRequired.
  ///
  /// In en, this message translates to:
  /// **'Age *'**
  String get ageRequired;

  /// No description provided for @enterAge.
  ///
  /// In en, this message translates to:
  /// **'Enter age'**
  String get enterAge;

  /// No description provided for @enterAgeMinimum18Years.
  ///
  /// In en, this message translates to:
  /// **'Enter age (minimum 18 years)'**
  String get enterAgeMinimum18Years;

  /// No description provided for @pleaseEnterAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter an age'**
  String get pleaseEnterAge;

  /// No description provided for @ageMustBeAtLeast18.
  ///
  /// In en, this message translates to:
  /// **'Age must be at least 18'**
  String get ageMustBeAtLeast18;

  /// No description provided for @ageMustBeLessThan65.
  ///
  /// In en, this message translates to:
  /// **'Age must be less than 65'**
  String get ageMustBeLessThan65;

  /// No description provided for @laborCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Employee created successfully!'**
  String get laborCreatedSuccessfully;

  /// No description provided for @failedToCreateLabor.
  ///
  /// In en, this message translates to:
  /// **'Failed to create employee'**
  String get failedToCreateLabor;

  /// No description provided for @errorCreatingLabor.
  ///
  /// In en, this message translates to:
  /// **'Error creating employee:'**
  String get errorCreatingLabor;

  /// No description provided for @pleaseFixFollowingErrors.
  ///
  /// In en, this message translates to:
  /// **'Please fix the following errors:'**
  String get pleaseFixFollowingErrors;

  /// No description provided for @nameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameIsRequired;

  /// No description provided for @cnicIsRequired.
  ///
  /// In en, this message translates to:
  /// **'CNIC is required'**
  String get cnicIsRequired;

  /// No description provided for @phoneNumberIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneNumberIsRequired;

  /// No description provided for @casteIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Caste is required'**
  String get casteIsRequired;

  /// No description provided for @designationIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Role is required'**
  String get designationIsRequired;

  /// No description provided for @areaIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Area is required'**
  String get areaIsRequired;

  /// No description provided for @cityIsRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get cityIsRequired;

  /// No description provided for @genderIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Gender is required'**
  String get genderIsRequired;

  /// No description provided for @joiningDateCannotBeInFuture.
  ///
  /// In en, this message translates to:
  /// **'Joining date cannot be in the future'**
  String get joiningDateCannotBeInFuture;

  /// No description provided for @salaryIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Salary is required'**
  String get salaryIsRequired;

  /// No description provided for @pleaseEnterValidSalaryAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid salary amount'**
  String get pleaseEnterValidSalaryAmount;

  /// No description provided for @ageIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Age is required'**
  String get ageIsRequired;

  /// No description provided for @pleaseEnterValidAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid age'**
  String get pleaseEnterValidAge;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @joinedDate.
  ///
  /// In en, this message translates to:
  /// **'Joined Date'**
  String get joinedDate;

  /// No description provided for @recentLabel.
  ///
  /// In en, this message translates to:
  /// **'RECENT'**
  String get recentLabel;

  /// No description provided for @laborStatusUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Employee status updated successfully!'**
  String get laborStatusUpdatedSuccessfully;

  /// No description provided for @failedToUpdateLaborStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update employee status'**
  String get failedToUpdateLaborStatus;

  /// No description provided for @errorUpdatingLaborStatus.
  ///
  /// In en, this message translates to:
  /// **'Error updating employee status:'**
  String get errorUpdatingLaborStatus;

  /// No description provided for @loadingLaborDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading employee details...'**
  String get loadingLaborDetails;

  /// No description provided for @laborDetails.
  ///
  /// In en, this message translates to:
  /// **'Employee Details'**
  String get laborDetails;

  /// No description provided for @completeLaborInformation.
  ///
  /// In en, this message translates to:
  /// **'Complete employee information'**
  String get completeLaborInformation;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joined;

  /// No description provided for @daysExperience.
  ///
  /// In en, this message translates to:
  /// **'days experience'**
  String get daysExperience;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @workInformation.
  ///
  /// In en, this message translates to:
  /// **'Work Information'**
  String get workInformation;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @joiningDate.
  ///
  /// In en, this message translates to:
  /// **'Joining Date'**
  String get joiningDate;

  /// No description provided for @financialInformation.
  ///
  /// In en, this message translates to:
  /// **'Financial Information'**
  String get financialInformation;

  /// No description provided for @monthlySalary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Salary'**
  String get monthlySalary;

  /// No description provided for @totalAdvances.
  ///
  /// In en, this message translates to:
  /// **'Total Advances'**
  String get totalAdvances;

  /// No description provided for @remainingMonthlySalary.
  ///
  /// In en, this message translates to:
  /// **'Remaining Monthly Salary'**
  String get remainingMonthlySalary;

  /// No description provided for @remainingAdvanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining Advance Amount'**
  String get remainingAdvanceAmount;

  /// No description provided for @totalAdvancesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Total Advances This Month'**
  String get totalAdvancesThisMonth;

  /// No description provided for @paymentRecords.
  ///
  /// In en, this message translates to:
  /// **'Payment Records'**
  String get paymentRecords;

  /// No description provided for @lastPayment.
  ///
  /// In en, this message translates to:
  /// **'Last Payment'**
  String get lastPayment;

  /// No description provided for @statusInformation.
  ///
  /// In en, this message translates to:
  /// **'Status Information'**
  String get statusInformation;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created By'**
  String get createdBy;

  /// No description provided for @newLabor.
  ///
  /// In en, this message translates to:
  /// **'New Employee'**
  String get newLabor;

  /// No description provided for @restoreLabor.
  ///
  /// In en, this message translates to:
  /// **'Restore Employee'**
  String get restoreLabor;

  /// No description provided for @deactivateLabor.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Employee'**
  String get deactivateLabor;

  /// No description provided for @areYouSureDeactivateLabor.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate {name}? This action can be reversed.'**
  String areYouSureDeactivateLabor(String name);

  /// No description provided for @areYouSureRestoreLabor.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore {name}?'**
  String areYouSureRestoreLabor(String name);

  /// No description provided for @failedToDeactivateLabor.
  ///
  /// In en, this message translates to:
  /// **'Failed to deactivate employee'**
  String get failedToDeactivateLabor;

  /// No description provided for @laborDeactivatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Employee deactivated successfully'**
  String get laborDeactivatedSuccessfully;

  /// No description provided for @failedToRestoreLabor.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore employee'**
  String get failedToRestoreLabor;

  /// No description provided for @laborRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Employee restored successfully'**
  String get laborRestoredSuccessfully;

  /// No description provided for @failedToLoadLabors.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Employees'**
  String get failedToLoadLabors;

  /// No description provided for @unexpectedErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedErrorOccurred;

  /// No description provided for @noLaborsFound.
  ///
  /// In en, this message translates to:
  /// **'No Employees Found'**
  String get noLaborsFound;

  /// No description provided for @startByAddingFirstLabor.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first employee to manage your workforce effectively'**
  String get startByAddingFirstLabor;

  /// No description provided for @addFirstLabor.
  ///
  /// In en, this message translates to:
  /// **'Add First Employee'**
  String get addFirstLabor;

  /// No description provided for @filterLabors.
  ///
  /// In en, this message translates to:
  /// **'Filter Employees'**
  String get filterLabors;

  /// No description provided for @refineYourLaborList.
  ///
  /// In en, this message translates to:
  /// **'Refine your employee list with filters'**
  String get refineYourLaborList;

  /// No description provided for @searchLabors.
  ///
  /// In en, this message translates to:
  /// **'Search Employees'**
  String get searchLabors;

  /// No description provided for @laborStatus.
  ///
  /// In en, this message translates to:
  /// **'Employee Status'**
  String get laborStatus;

  /// No description provided for @searchByNameCnicPhoneDesignation.
  ///
  /// In en, this message translates to:
  /// **'Search by name, CNIC, phone, or role'**
  String get searchByNameCnicPhoneDesignation;

  /// No description provided for @showInactiveLaborsOnly.
  ///
  /// In en, this message translates to:
  /// **'Show inactive employees only'**
  String get showInactiveLaborsOnly;

  /// No description provided for @onlyDeactivatedLaborsWillBeShown.
  ///
  /// In en, this message translates to:
  /// **'Only deactivated employees will be shown'**
  String get onlyDeactivatedLaborsWillBeShown;

  /// No description provided for @enterCityName.
  ///
  /// In en, this message translates to:
  /// **'Enter city name'**
  String get enterCityName;

  /// No description provided for @enterAreaName.
  ///
  /// In en, this message translates to:
  /// **'Enter area name'**
  String get enterAreaName;

  /// No description provided for @principalAccountLedger.
  ///
  /// In en, this message translates to:
  /// **'Principal Account Ledger'**
  String get principalAccountLedger;

  /// No description provided for @trackAllCashMovements.
  ///
  /// In en, this message translates to:
  /// **'Track all cash movements and maintain financial balance'**
  String get trackAllCashMovements;

  /// No description provided for @trackCashMovementsAndBalance.
  ///
  /// In en, this message translates to:
  /// **'Track cash movements and balance'**
  String get trackCashMovementsAndBalance;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// No description provided for @cashMovements.
  ///
  /// In en, this message translates to:
  /// **'Cash movements'**
  String get cashMovements;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @addLedgerEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Ledger Entry'**
  String get addLedgerEntry;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @totalEntries.
  ///
  /// In en, this message translates to:
  /// **'Total Entries'**
  String get totalEntries;

  /// No description provided for @totalCredits.
  ///
  /// In en, this message translates to:
  /// **'Total Credits'**
  String get totalCredits;

  /// No description provided for @totalDebits.
  ///
  /// In en, this message translates to:
  /// **'Total Debits'**
  String get totalDebits;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @debits.
  ///
  /// In en, this message translates to:
  /// **'Debits'**
  String get debits;

  /// No description provided for @searchLedgerEntries.
  ///
  /// In en, this message translates to:
  /// **'Search ledger entries...'**
  String get searchLedgerEntries;

  /// No description provided for @searchByIdDescriptionAmount.
  ///
  /// In en, this message translates to:
  /// **'Search by ID, description, amount, source module, or handler...'**
  String get searchByIdDescriptionAmount;

  /// No description provided for @receivableDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Receivable deleted successfully!'**
  String get receivableDeletedSuccessfully;

  /// No description provided for @deleteReceivable.
  ///
  /// In en, this message translates to:
  /// **'Delete Receivable'**
  String get deleteReceivable;

  /// No description provided for @deleteReceivableRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Receivable Record'**
  String get deleteReceivableRecord;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get thisActionCannotBeUndone;

  /// No description provided for @areYouSureDeleteReceivable.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this receivable?'**
  String get areYouSureDeleteReceivable;

  /// No description provided for @areYouAbsolutelySureDeleteReceivable.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure you want to delete this receivable record?'**
  String get areYouAbsolutelySureDeleteReceivable;

  /// No description provided for @amountGivenLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount Given:'**
  String get amountGivenLabel;

  /// No description provided for @balanceRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Balance Remaining:'**
  String get balanceRemainingLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone:'**
  String get phoneLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get statusLabel;

  /// No description provided for @expectedReturnLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected Return:'**
  String get expectedReturnLabel;

  /// No description provided for @daysOverdueLabel.
  ///
  /// In en, this message translates to:
  /// **'Days Overdue:'**
  String get daysOverdueLabel;

  /// No description provided for @reasonItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason/Item:'**
  String get reasonItemLabel;

  /// No description provided for @willPermanentlyDeleteReceivable.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the receivable record.'**
  String get willPermanentlyDeleteReceivable;

  /// No description provided for @willPermanentlyDeleteReceivableAndData.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the receivable record and all associated data. This action cannot be undone.'**
  String get willPermanentlyDeleteReceivableAndData;

  /// No description provided for @filterAndSortProducts.
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort Products'**
  String get filterAndSortProducts;

  /// No description provided for @refineYourProductList.
  ///
  /// In en, this message translates to:
  /// **'Refine your product list with advanced filters'**
  String get refineYourProductList;

  /// No description provided for @productCategory.
  ///
  /// In en, this message translates to:
  /// **'Product Category'**
  String get productCategory;

  /// No description provided for @productAttributes.
  ///
  /// In en, this message translates to:
  /// **'Product Attributes'**
  String get productAttributes;

  /// No description provided for @stockLevel.
  ///
  /// In en, this message translates to:
  /// **'Stock Level'**
  String get stockLevel;

  /// No description provided for @priceRangePKR.
  ///
  /// In en, this message translates to:
  /// **'Price Range (PKR)'**
  String get priceRangePKR;

  /// No description provided for @sortOptions.
  ///
  /// In en, this message translates to:
  /// **'Sort Options'**
  String get sortOptions;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @allColors.
  ///
  /// In en, this message translates to:
  /// **'All Colors'**
  String get allColors;

  /// No description provided for @allFabrics.
  ///
  /// In en, this message translates to:
  /// **'All Fabrics'**
  String get allFabrics;

  /// No description provided for @allStockLevels.
  ///
  /// In en, this message translates to:
  /// **'All Stock Levels'**
  String get allStockLevels;

  /// No description provided for @inStockHigh.
  ///
  /// In en, this message translates to:
  /// **'In Stock (High)'**
  String get inStockHigh;

  /// No description provided for @mediumStock.
  ///
  /// In en, this message translates to:
  /// **'Medium Stock'**
  String get mediumStock;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @noLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get noLimit;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort By'**
  String get sortBy;

  /// No description provided for @dateCreated.
  ///
  /// In en, this message translates to:
  /// **'Date Created'**
  String get dateCreated;

  /// No description provided for @dateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Date Updated'**
  String get dateUpdated;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrder;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @minPriceCannotBeGreaterThanMax.
  ///
  /// In en, this message translates to:
  /// **'Minimum price cannot be greater than maximum price'**
  String get minPriceCannotBeGreaterThanMax;

  /// No description provided for @filtersAppliedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Filters applied successfully'**
  String get filtersAppliedSuccessfully;

  /// No description provided for @filtersCleared.
  ///
  /// In en, this message translates to:
  /// **'Filters cleared'**
  String get filtersCleared;

  /// No description provided for @enterProductName.
  ///
  /// In en, this message translates to:
  /// **'Enter product name'**
  String get enterProductName;

  /// No description provided for @enterProductDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter product details'**
  String get enterProductDetails;

  /// No description provided for @enterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter price'**
  String get enterPrice;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get enterQuantity;

  /// No description provided for @enterColor.
  ///
  /// In en, this message translates to:
  /// **'Enter color'**
  String get enterColor;

  /// No description provided for @enterFabric.
  ///
  /// In en, this message translates to:
  /// **'Enter fabric'**
  String get enterFabric;

  /// No description provided for @enterMinPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter minimum price'**
  String get enterMinPrice;

  /// No description provided for @enterVendorName.
  ///
  /// In en, this message translates to:
  /// **'Enter vendor name'**
  String get enterVendorName;

  /// No description provided for @enterBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Enter business name'**
  String get enterBusinessName;

  /// No description provided for @enterCnicNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter CNIC number'**
  String get enterCnicNumber;

  /// No description provided for @enterPhoneWithCode.
  ///
  /// In en, this message translates to:
  /// **'Enter phone (+92XXXXXXXXXX)'**
  String get enterPhoneWithCode;

  /// No description provided for @enterFullAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter full address'**
  String get enterFullAddress;

  /// No description provided for @enterCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Enter customer name'**
  String get enterCustomerName;

  /// No description provided for @enterCustomerFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter customer\'s full name'**
  String get enterCustomerFullName;

  /// No description provided for @enterCustomerPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter customer phone number'**
  String get enterCustomerPhone;

  /// No description provided for @enterCustomerEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter customer email address'**
  String get enterCustomerEmail;

  /// No description provided for @enterCustomerAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter customer address'**
  String get enterCustomerAddress;

  /// No description provided for @enterCustomerCity.
  ///
  /// In en, this message translates to:
  /// **'Enter customer city'**
  String get enterCustomerCity;

  /// No description provided for @enterCustomerCountry.
  ///
  /// In en, this message translates to:
  /// **'Enter customer country'**
  String get enterCustomerCountry;

  /// No description provided for @enterCustomerBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Enter customer business name'**
  String get enterCustomerBusinessName;

  /// No description provided for @enterCustomerTaxNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter customer tax or NTN number'**
  String get enterCustomerTaxNumber;

  /// No description provided for @enterCustomerNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter customer notes'**
  String get enterCustomerNotes;

  /// No description provided for @enterAdditionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter additional notes'**
  String get enterAdditionalNotes;

  /// No description provided for @addZakat.
  ///
  /// In en, this message translates to:
  /// **'Add Zakat'**
  String get addZakat;

  /// No description provided for @addNewZakatRecord.
  ///
  /// In en, this message translates to:
  /// **'Add New Zakat Record'**
  String get addNewZakatRecord;

  /// No description provided for @recordYourZakatContribution.
  ///
  /// In en, this message translates to:
  /// **'Record your zakat contribution'**
  String get recordYourZakatContribution;

  /// No description provided for @titleOptional.
  ///
  /// In en, this message translates to:
  /// **'Title (Optional)'**
  String get titleOptional;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter title'**
  String get enterTitle;

  /// No description provided for @enterZakatContributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter zakat contribution title'**
  String get enterZakatContributionTitle;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// No description provided for @enterDescriptionPurposeOfZakat.
  ///
  /// In en, this message translates to:
  /// **'Enter description/purpose of zakat'**
  String get enterDescriptionPurposeOfZakat;

  /// No description provided for @pleaseEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter description'**
  String get pleaseEnterDescription;

  /// No description provided for @descriptionMustBeAtLeast5Characters.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 5 characters'**
  String get descriptionMustBeAtLeast5Characters;

  /// No description provided for @amountPkr.
  ///
  /// In en, this message translates to:
  /// **'Amount (PKR)'**
  String get amountPkr;

  /// No description provided for @enterZakatAmountInPkr.
  ///
  /// In en, this message translates to:
  /// **'Enter zakat amount in PKR'**
  String get enterZakatAmountInPkr;

  /// No description provided for @pleaseEnterValidAmountGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount greater than zero'**
  String get pleaseEnterValidAmountGreaterThanZero;

  /// No description provided for @beneficiaryName.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary Name'**
  String get beneficiaryName;

  /// No description provided for @enterBeneficiaryName.
  ///
  /// In en, this message translates to:
  /// **'Enter beneficiary name'**
  String get enterBeneficiaryName;

  /// No description provided for @enterNameOfRecipientBeneficiary.
  ///
  /// In en, this message translates to:
  /// **'Enter name of recipient/beneficiary'**
  String get enterNameOfRecipientBeneficiary;

  /// No description provided for @pleaseEnterBeneficiaryName.
  ///
  /// In en, this message translates to:
  /// **'Please enter beneficiary name'**
  String get pleaseEnterBeneficiaryName;

  /// No description provided for @beneficiaryNameMustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary name must be at least 2 characters'**
  String get beneficiaryNameMustBeAtLeast2Characters;

  /// No description provided for @beneficiaryContactOptional.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary Contact (Optional)'**
  String get beneficiaryContactOptional;

  /// No description provided for @enterContact.
  ///
  /// In en, this message translates to:
  /// **'Enter contact'**
  String get enterContact;

  /// No description provided for @enterBeneficiaryContactNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter beneficiary contact number'**
  String get enterBeneficiaryContactNumber;

  /// No description provided for @authorizedBy.
  ///
  /// In en, this message translates to:
  /// **'Authorized By'**
  String get authorizedBy;

  /// No description provided for @selectAuthorizingPerson.
  ///
  /// In en, this message translates to:
  /// **'Select authorizing person'**
  String get selectAuthorizingPerson;

  /// No description provided for @pleaseSelectAuthorizedPerson.
  ///
  /// In en, this message translates to:
  /// **'Please select an authorized person'**
  String get pleaseSelectAuthorizedPerson;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateAndTime;

  /// No description provided for @at.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get at;

  /// No description provided for @additionalNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes (Optional)'**
  String get additionalNotesOptional;

  /// No description provided for @enterNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter notes'**
  String get enterNotes;

  /// No description provided for @enterAdditionalNotesOrReligiousConsiderations.
  ///
  /// In en, this message translates to:
  /// **'Enter additional notes or religious considerations'**
  String get enterAdditionalNotesOrReligiousConsiderations;

  /// No description provided for @addZakatRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Zakat Record'**
  String get addZakatRecord;

  /// No description provided for @zakatRecordAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Zakat record added successfully!'**
  String get zakatRecordAddedSuccessfully;

  /// No description provided for @failedToAddZakatRecord.
  ///
  /// In en, this message translates to:
  /// **'Failed to add zakat record'**
  String get failedToAddZakatRecord;

  /// No description provided for @zakatContribution.
  ///
  /// In en, this message translates to:
  /// **'Zakat Contribution'**
  String get zakatContribution;

  /// No description provided for @zakatId.
  ///
  /// In en, this message translates to:
  /// **'Zakat ID'**
  String get zakatId;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @beneficiary.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary'**
  String get beneficiary;

  /// No description provided for @authority.
  ///
  /// In en, this message translates to:
  /// **'Authority'**
  String get authority;

  /// No description provided for @noNotes.
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get noNotes;

  /// No description provided for @showingZakatRecords.
  ///
  /// In en, this message translates to:
  /// **'Showing {start}-{end} of {total} zakat records'**
  String showingZakatRecords(int start, int end, int total);

  /// No description provided for @pageOfPages.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String pageOfPages(int current, int total);

  /// No description provided for @filterZakatRecords.
  ///
  /// In en, this message translates to:
  /// **'Filter Zakat Records'**
  String get filterZakatRecords;

  /// No description provided for @refineYourZakatList.
  ///
  /// In en, this message translates to:
  /// **'Refine your zakat list with filters'**
  String get refineYourZakatList;

  /// No description provided for @searchZakatRecords.
  ///
  /// In en, this message translates to:
  /// **'Search Zakat Records'**
  String get searchZakatRecords;

  /// No description provided for @recordStatus.
  ///
  /// In en, this message translates to:
  /// **'Record Status'**
  String get recordStatus;

  /// No description provided for @authorizationAuthority.
  ///
  /// In en, this message translates to:
  /// **'Authorization Authority'**
  String get authorizationAuthority;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @searchByNameDescriptionBeneficiaryOrNotes.
  ///
  /// In en, this message translates to:
  /// **'Search by name, description, beneficiary, or notes'**
  String get searchByNameDescriptionBeneficiaryOrNotes;

  /// No description provided for @showInactiveRecordsOnly.
  ///
  /// In en, this message translates to:
  /// **'Show inactive records only'**
  String get showInactiveRecordsOnly;

  /// No description provided for @onlyDeactivatedZakatRecordsWillBeShown.
  ///
  /// In en, this message translates to:
  /// **'Only deactivated zakat records will be shown'**
  String get onlyDeactivatedZakatRecordsWillBeShown;

  /// No description provided for @selectAuthorizationAuthority.
  ///
  /// In en, this message translates to:
  /// **'Select Authorization Authority'**
  String get selectAuthorizationAuthority;

  /// No description provided for @clearAuthorityFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Authority Filter'**
  String get clearAuthorityFilter;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get selectDateRange;

  /// No description provided for @noDateRangeSelected.
  ///
  /// In en, this message translates to:
  /// **'No date range selected'**
  String get noDateRangeSelected;

  /// No description provided for @clearDateRange.
  ///
  /// In en, this message translates to:
  /// **'Clear Date Range'**
  String get clearDateRange;

  /// No description provided for @selectStartDate.
  ///
  /// In en, this message translates to:
  /// **'Select Start Date'**
  String get selectStartDate;

  /// No description provided for @selectEndDate.
  ///
  /// In en, this message translates to:
  /// **'Select End Date'**
  String get selectEndDate;

  /// No description provided for @failedToLoadZakatRecords.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Zakat Records'**
  String get failedToLoadZakatRecords;

  /// No description provided for @noZakatRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No Zakat Records Found'**
  String get noZakatRecordsFound;

  /// No description provided for @startByAddingFirstZakatRecord.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first zakat record to track your contributions effectively'**
  String get startByAddingFirstZakatRecord;

  /// No description provided for @addFirstZakatRecord.
  ///
  /// In en, this message translates to:
  /// **'Add First Zakat Record'**
  String get addFirstZakatRecord;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @zakatDetails.
  ///
  /// In en, this message translates to:
  /// **'Zakat Details'**
  String get zakatDetails;

  /// No description provided for @viewCompleteZakatContributionInformation.
  ///
  /// In en, this message translates to:
  /// **'View complete zakat contribution information'**
  String get viewCompleteZakatContributionInformation;

  /// No description provided for @zakatTitle.
  ///
  /// In en, this message translates to:
  /// **'Zakat Title'**
  String get zakatTitle;

  /// No description provided for @zakatAmount.
  ///
  /// In en, this message translates to:
  /// **'Zakat Amount'**
  String get zakatAmount;

  /// No description provided for @contributionAmount.
  ///
  /// In en, this message translates to:
  /// **'Contribution Amount'**
  String get contributionAmount;

  /// No description provided for @beneficiaryInformation.
  ///
  /// In en, this message translates to:
  /// **'Beneficiary Information'**
  String get beneficiaryInformation;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @descriptionAndPurpose.
  ///
  /// In en, this message translates to:
  /// **'Description & Purpose'**
  String get descriptionAndPurpose;

  /// No description provided for @authorizationAndStatus.
  ///
  /// In en, this message translates to:
  /// **'Authorization & Status'**
  String get authorizationAndStatus;

  /// No description provided for @editZakat.
  ///
  /// In en, this message translates to:
  /// **'Edit Zakat'**
  String get editZakat;

  /// No description provided for @editZakatRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit Zakat Record'**
  String get editZakatRecord;

  /// No description provided for @updateZakatInformation.
  ///
  /// In en, this message translates to:
  /// **'Update zakat information'**
  String get updateZakatInformation;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter title'**
  String get pleaseEnterTitle;

  /// No description provided for @zakatRecordUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Zakat record updated successfully!'**
  String get zakatRecordUpdatedSuccessfully;

  /// No description provided for @failedToUpdateZakatRecord.
  ///
  /// In en, this message translates to:
  /// **'Failed to update zakat record'**
  String get failedToUpdateZakatRecord;

  /// No description provided for @updateZakat.
  ///
  /// In en, this message translates to:
  /// **'Update Zakat'**
  String get updateZakat;

  /// No description provided for @deleteZakat.
  ///
  /// In en, this message translates to:
  /// **'Delete Zakat'**
  String get deleteZakat;

  /// No description provided for @deleteZakatRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Zakat Record'**
  String get deleteZakatRecord;

  /// No description provided for @zakatRecordDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Zakat record deleted successfully!'**
  String get zakatRecordDeletedSuccessfully;

  /// No description provided for @failedToDeleteZakatRecord.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete zakat record'**
  String get failedToDeleteZakatRecord;

  /// No description provided for @areYouSureYouWantToDeleteThisZakatRecord.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this zakat record?'**
  String get areYouSureYouWantToDeleteThisZakatRecord;

  /// No description provided for @areYouAbsolutelySureYouWantToDeleteThisZakatRecord.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure you want to delete this zakat record?'**
  String get areYouAbsolutelySureYouWantToDeleteThisZakatRecord;

  /// No description provided for @thisWillPermanentlyDeleteTheZakatRecord.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the zakat record.'**
  String get thisWillPermanentlyDeleteTheZakatRecord;

  /// No description provided for @thisWillPermanentlyDeleteTheZakatRecordAndAllAssociatedData.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the zakat record and all associated data. This action cannot be undone.'**
  String get thisWillPermanentlyDeleteTheZakatRecordAndAllAssociatedData;

  /// No description provided for @calculationSummary.
  ///
  /// In en, this message translates to:
  /// **'Calculation Summary'**
  String get calculationSummary;

  /// No description provided for @costOfGoods.
  ///
  /// In en, this message translates to:
  /// **'Cost of Goods'**
  String get costOfGoods;

  /// No description provided for @totalSalesRevenueForThePeriod.
  ///
  /// In en, this message translates to:
  /// **'Total sales revenue for the period'**
  String get totalSalesRevenueForThePeriod;

  /// No description provided for @directCostsOfProductsSold.
  ///
  /// In en, this message translates to:
  /// **'Direct costs of products sold'**
  String get directCostsOfProductsSold;

  /// No description provided for @incomeMinusCostOfGoodsSold.
  ///
  /// In en, this message translates to:
  /// **'Income minus cost of goods sold'**
  String get incomeMinusCostOfGoodsSold;

  /// No description provided for @finalProfitAfterAllExpenses.
  ///
  /// In en, this message translates to:
  /// **'Final profit after all expenses'**
  String get finalProfitAfterAllExpenses;

  /// No description provided for @totalSalesRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total sales revenue'**
  String get totalSalesRevenue;

  /// No description provided for @directCosts.
  ///
  /// In en, this message translates to:
  /// **'Direct costs'**
  String get directCosts;

  /// No description provided for @incomeMinusCogs.
  ///
  /// In en, this message translates to:
  /// **'Income - COGS'**
  String get incomeMinusCogs;

  /// No description provided for @finalProfit.
  ///
  /// In en, this message translates to:
  /// **'Final profit'**
  String get finalProfit;

  /// No description provided for @sourceRecordsBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Source Records Breakdown'**
  String get sourceRecordsBreakdown;

  /// No description provided for @salesRecords.
  ///
  /// In en, this message translates to:
  /// **'Sales Records'**
  String get salesRecords;

  /// No description provided for @laborPayments.
  ///
  /// In en, this message translates to:
  /// **'Employee Payments'**
  String get laborPayments;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @vendorPayments.
  ///
  /// In en, this message translates to:
  /// **'Vendor Payments'**
  String get vendorPayments;

  /// No description provided for @otherExpenses.
  ///
  /// In en, this message translates to:
  /// **'Other Expenses'**
  String get otherExpenses;

  /// No description provided for @labor.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get labor;

  /// No description provided for @vendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get vendors;

  /// No description provided for @calculationFormula.
  ///
  /// In en, this message translates to:
  /// **'Calculation Formula'**
  String get calculationFormula;

  /// No description provided for @stepOneGrossProfit.
  ///
  /// In en, this message translates to:
  /// **'1. Gross Profit'**
  String get stepOneGrossProfit;

  /// No description provided for @stepTwoTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'2. Total Expenses'**
  String get stepTwoTotalExpenses;

  /// No description provided for @laborPlusVendorPlusOtherPlusZakat.
  ///
  /// In en, this message translates to:
  /// **'Employee + Vendor + Other + Zakat'**
  String get laborPlusVendorPlusOtherPlusZakat;

  /// No description provided for @stepThreeNetProfit.
  ///
  /// In en, this message translates to:
  /// **'3. Net Profit'**
  String get stepThreeNetProfit;

  /// No description provided for @grossProfitMinusTotalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit - Total Expenses'**
  String get grossProfitMinusTotalExpenses;

  /// No description provided for @grossProfitMargin.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit Margin'**
  String get grossProfitMargin;

  /// No description provided for @grossProfitDivideIncomeMultiply100.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit / Income × 100'**
  String get grossProfitDivideIncomeMultiply100;

  /// No description provided for @netProfitMargin.
  ///
  /// In en, this message translates to:
  /// **'Net Profit Margin'**
  String get netProfitMargin;

  /// No description provided for @netProfitDivideIncomeMultiply100.
  ///
  /// In en, this message translates to:
  /// **'Net Profit / Income × 100'**
  String get netProfitDivideIncomeMultiply100;

  /// No description provided for @periodInformation.
  ///
  /// In en, this message translates to:
  /// **'Period Information'**
  String get periodInformation;

  /// No description provided for @periodType.
  ///
  /// In en, this message translates to:
  /// **'Period Type'**
  String get periodType;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @noCalculationDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Calculation Data Available'**
  String get noCalculationDataAvailable;

  /// No description provided for @calculationDetailsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Calculation details will appear here once profit and loss data is available'**
  String get calculationDetailsWillAppearHere;

  /// No description provided for @loadingDashboardData.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard data...'**
  String get loadingDashboardData;

  /// No description provided for @salesGrowth.
  ///
  /// In en, this message translates to:
  /// **'Sales Growth'**
  String get salesGrowth;

  /// No description provided for @expenseGrowth.
  ///
  /// In en, this message translates to:
  /// **'Expense Growth'**
  String get expenseGrowth;

  /// No description provided for @profitGrowth.
  ///
  /// In en, this message translates to:
  /// **'Profit Growth'**
  String get profitGrowth;

  /// No description provided for @increased.
  ///
  /// In en, this message translates to:
  /// **'Increased'**
  String get increased;

  /// No description provided for @decreased.
  ///
  /// In en, this message translates to:
  /// **'Decreased'**
  String get decreased;

  /// No description provided for @noChange.
  ///
  /// In en, this message translates to:
  /// **'No Change'**
  String get noChange;

  /// No description provided for @currentMonth.
  ///
  /// In en, this message translates to:
  /// **'Current Month'**
  String get currentMonth;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous Month'**
  String get previousMonth;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @businessTrends.
  ///
  /// In en, this message translates to:
  /// **'Business Trends'**
  String get businessTrends;

  /// No description provided for @salesTrend.
  ///
  /// In en, this message translates to:
  /// **'Sales Trend'**
  String get salesTrend;

  /// No description provided for @profitTrend.
  ///
  /// In en, this message translates to:
  /// **'Profit Trend'**
  String get profitTrend;

  /// No description provided for @increasing.
  ///
  /// In en, this message translates to:
  /// **'Increasing'**
  String get increasing;

  /// No description provided for @decreasing.
  ///
  /// In en, this message translates to:
  /// **'Decreasing'**
  String get decreasing;

  /// No description provided for @stable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stable;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @grossProfit.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit'**
  String get grossProfit;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @exportFormat.
  ///
  /// In en, this message translates to:
  /// **'Export Format'**
  String get exportFormat;

  /// No description provided for @chooseTheFormatForYourProfitAndLossReport.
  ///
  /// In en, this message translates to:
  /// **'Choose the format for your Profit & Loss report:'**
  String get chooseTheFormatForYourProfitAndLossReport;

  /// No description provided for @pdfReport.
  ///
  /// In en, this message translates to:
  /// **'PDF Report'**
  String get pdfReport;

  /// No description provided for @professionalDocumentWithChartsAndFormatting.
  ///
  /// In en, this message translates to:
  /// **'Professional document with charts and formatting'**
  String get professionalDocumentWithChartsAndFormatting;

  /// No description provided for @excelSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Excel Spreadsheet'**
  String get excelSpreadsheet;

  /// No description provided for @dataInSpreadsheetFormatForAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Data in spreadsheet format for analysis'**
  String get dataInSpreadsheetFormatForAnalysis;

  /// No description provided for @profitMargin.
  ///
  /// In en, this message translates to:
  /// **'Profit Margin'**
  String get profitMargin;

  /// No description provided for @netLoss.
  ///
  /// In en, this message translates to:
  /// **'Net Loss'**
  String get netLoss;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @applyRange.
  ///
  /// In en, this message translates to:
  /// **'Apply Range'**
  String get applyRange;

  /// No description provided for @productProfitabilityAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Product Profitability Analysis'**
  String get productProfitabilityAnalysis;

  /// No description provided for @analyzingProductsAcrossDifferentCategories.
  ///
  /// In en, this message translates to:
  /// **'Analyzing {count} products across different categories'**
  String analyzingProductsAcrossDifferentCategories(int count);

  /// No description provided for @productsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Products'**
  String productsCount(int count);

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @unitsSold.
  ///
  /// In en, this message translates to:
  /// **'Units Sold'**
  String get unitsSold;

  /// No description provided for @marginPercent.
  ///
  /// In en, this message translates to:
  /// **'Margin %'**
  String get marginPercent;

  /// No description provided for @sortDescending.
  ///
  /// In en, this message translates to:
  /// **'Sort Descending'**
  String get sortDescending;

  /// No description provided for @sortAscending.
  ///
  /// In en, this message translates to:
  /// **'Sort Ascending'**
  String get sortAscending;

  /// No description provided for @summaryStatistics.
  ///
  /// In en, this message translates to:
  /// **'Summary Statistics'**
  String get summaryStatistics;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @totalProfit.
  ///
  /// In en, this message translates to:
  /// **'Total Profit'**
  String get totalProfit;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @avgProfitMargin.
  ///
  /// In en, this message translates to:
  /// **'Avg Profit Margin'**
  String get avgProfitMargin;

  /// No description provided for @profitableProducts.
  ///
  /// In en, this message translates to:
  /// **'Profitable Products'**
  String get profitableProducts;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @loadingProductData.
  ///
  /// In en, this message translates to:
  /// **'Loading Product Data...'**
  String get loadingProductData;

  /// No description provided for @pleaseWaitWhileWeFetchTheLatestProfitabilityInformation.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we fetch the latest profitability information.'**
  String get pleaseWaitWhileWeFetchTheLatestProfitabilityInformation;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Data'**
  String get errorLoadingData;

  /// No description provided for @anUnexpectedErrorOccurredWhileLoadingProductData.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred while loading product data.'**
  String get anUnexpectedErrorOccurredWhileLoadingProductData;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @productProfitabilityDataIsBeingLoaded.
  ///
  /// In en, this message translates to:
  /// **'Product profitability data is being loaded.\nThis includes revenue, costs, profit margins, and rankings.'**
  String get productProfitabilityDataIsBeingLoaded;

  /// No description provided for @refreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh Data'**
  String get refreshData;

  /// No description provided for @addPayable.
  ///
  /// In en, this message translates to:
  /// **'Add Payable'**
  String get addPayable;

  /// No description provided for @addNewPayable.
  ///
  /// In en, this message translates to:
  /// **'Add New Payable'**
  String get addNewPayable;

  /// No description provided for @recordAmountOwedToCreditor.
  ///
  /// In en, this message translates to:
  /// **'Record amount owed to creditor'**
  String get recordAmountOwedToCreditor;

  /// No description provided for @creditorInformation.
  ///
  /// In en, this message translates to:
  /// **'Creditor Information'**
  String get creditorInformation;

  /// No description provided for @creditorName.
  ///
  /// In en, this message translates to:
  /// **'Creditor Name'**
  String get creditorName;

  /// No description provided for @enterCreditorFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter creditor full name'**
  String get enterCreditorFullName;

  /// No description provided for @pleaseEnterCreditorName.
  ///
  /// In en, this message translates to:
  /// **'Please enter creditor name'**
  String get pleaseEnterCreditorName;

  /// No description provided for @enterPhoneNumberWithFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number (+92XXXXXXXXXX)'**
  String get enterPhoneNumberWithFormat;

  /// No description provided for @pleaseEnterAValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterAValidPhoneNumber;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get emailOptional;

  /// No description provided for @enterCreditorEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter creditor email address'**
  String get enterCreditorEmailAddress;

  /// No description provided for @amountBorrowedPKR.
  ///
  /// In en, this message translates to:
  /// **'Amount Borrowed (PKR)'**
  String get amountBorrowedPKR;

  /// No description provided for @enterAmountBorrowedFromCreditor.
  ///
  /// In en, this message translates to:
  /// **'Enter amount borrowed from creditor'**
  String get enterAmountBorrowedFromCreditor;

  /// No description provided for @pleaseEnterAmountBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount borrowed'**
  String get pleaseEnterAmountBorrowed;

  /// No description provided for @pleaseEnterAValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterAValidAmount;

  /// No description provided for @amountPaidPKR.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid (PKR)'**
  String get amountPaidPKR;

  /// No description provided for @optionalIfAnyAmountAlreadyPaid.
  ///
  /// In en, this message translates to:
  /// **'Optional - if any amount already paid'**
  String get optionalIfAnyAmountAlreadyPaid;

  /// No description provided for @cannotExceedAmountBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Cannot exceed amount borrowed'**
  String get cannotExceedAmountBorrowed;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional Details'**
  String get additionalDetails;

  /// No description provided for @enterReasonForBorrowingOrItemDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter reason for borrowing or item description'**
  String get enterReasonForBorrowingOrItemDescription;

  /// No description provided for @pleaseEnterReasonOrItemDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter reason or item description'**
  String get pleaseEnterReasonOrItemDescription;

  /// No description provided for @vendorOptional.
  ///
  /// In en, this message translates to:
  /// **'Vendor (Optional)'**
  String get vendorOptional;

  /// No description provided for @selectVendorIfCreditorIsARegisteredVendor.
  ///
  /// In en, this message translates to:
  /// **'Select vendor if creditor is a registered vendor'**
  String get selectVendorIfCreditorIsARegisteredVendor;

  /// No description provided for @noVendor.
  ///
  /// In en, this message translates to:
  /// **'No vendor'**
  String get noVendor;

  /// No description provided for @priorityLevel.
  ///
  /// In en, this message translates to:
  /// **'Priority Level'**
  String get priorityLevel;

  /// No description provided for @selectPriorityLevelForThisPayable.
  ///
  /// In en, this message translates to:
  /// **'Select priority level for this payable'**
  String get selectPriorityLevelForThisPayable;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @enterAdditionalNotesOrPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Enter additional notes or payment history'**
  String get enterAdditionalNotesOrPaymentHistory;

  /// No description provided for @dateBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Date Borrowed'**
  String get dateBorrowed;

  /// No description provided for @expectedRepaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Expected Repayment Date'**
  String get expectedRepaymentDate;

  /// No description provided for @selectBorrowedDate.
  ///
  /// In en, this message translates to:
  /// **'Select Borrowed Date'**
  String get selectBorrowedDate;

  /// No description provided for @selectExpectedRepaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Select Expected Repayment Date'**
  String get selectExpectedRepaymentDate;

  /// No description provided for @borrowingPeriodDays.
  ///
  /// In en, this message translates to:
  /// **'Borrowing period: {days} days'**
  String borrowingPeriodDays(int days);

  /// No description provided for @pleaseSelectAValidRepaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid repayment date'**
  String get pleaseSelectAValidRepaymentDate;

  /// No description provided for @expectedRepaymentDateCannotBeBeforeDateBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Expected repayment date cannot be before date borrowed'**
  String get expectedRepaymentDateCannotBeBeforeDateBorrowed;

  /// No description provided for @failedToAddPayablePleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to add payable. Please try again.'**
  String get failedToAddPayablePleaseTryAgain;

  /// No description provided for @payableAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payable added successfully!'**
  String get payableAddedSuccessfully;

  /// No description provided for @enterReason.
  ///
  /// In en, this message translates to:
  /// **'Enter reason'**
  String get enterReason;

  /// No description provided for @deletePayable.
  ///
  /// In en, this message translates to:
  /// **'Delete Payable'**
  String get deletePayable;

  /// No description provided for @deletePayableRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Payable Record'**
  String get deletePayableRecord;

  /// No description provided for @areYouSureYouWantToDeleteThisPayable.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this payable?'**
  String get areYouSureYouWantToDeleteThisPayable;

  /// No description provided for @areYouAbsolutelySureYouWantToDeleteThisPayableRecord.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure you want to delete this payable record?'**
  String get areYouAbsolutelySureYouWantToDeleteThisPayableRecord;

  /// No description provided for @amountBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Amount Borrowed'**
  String get amountBorrowed;

  /// No description provided for @expectedRepayment.
  ///
  /// In en, this message translates to:
  /// **'Expected Repayment'**
  String get expectedRepayment;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysCount(int count);

  /// No description provided for @thisWillPermanentlyDeleteThePayableRecord.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the payable record.'**
  String get thisWillPermanentlyDeleteThePayableRecord;

  /// No description provided for @thisWillPermanentlyDeleteThePayableRecordAndAllAssociatedData.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the payable record and all associated data. This action cannot be undone.'**
  String get thisWillPermanentlyDeleteThePayableRecordAndAllAssociatedData;

  /// No description provided for @payableDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payable deleted successfully!'**
  String get payableDeletedSuccessfully;

  /// No description provided for @editPayable.
  ///
  /// In en, this message translates to:
  /// **'Edit Payable'**
  String get editPayable;

  /// No description provided for @editPayableDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Payable Details'**
  String get editPayableDetails;

  /// No description provided for @updatePayableInformation.
  ///
  /// In en, this message translates to:
  /// **'Update payable information'**
  String get updatePayableInformation;

  /// No description provided for @enterCreditorEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter creditor email'**
  String get enterCreditorEmail;

  /// No description provided for @additionalAmountToPayPKR.
  ///
  /// In en, this message translates to:
  /// **'Additional Amount to Pay (PKR)'**
  String get additionalAmountToPayPKR;

  /// No description provided for @enterAdditionalAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter additional amount'**
  String get enterAdditionalAmount;

  /// No description provided for @totalPaymentCannotExceedAmountBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Total payment cannot exceed amount borrowed'**
  String get totalPaymentCannotExceedAmountBorrowed;

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get paymentSummary;

  /// No description provided for @currentPaid.
  ///
  /// In en, this message translates to:
  /// **'Current Paid'**
  String get currentPaid;

  /// No description provided for @additionalPayment.
  ///
  /// In en, this message translates to:
  /// **'Additional Payment'**
  String get additionalPayment;

  /// No description provided for @totalAfterUpdate.
  ///
  /// In en, this message translates to:
  /// **'Total After Update'**
  String get totalAfterUpdate;

  /// No description provided for @reasonForBorrowing.
  ///
  /// In en, this message translates to:
  /// **'Reason for borrowing'**
  String get reasonForBorrowing;

  /// No description provided for @updatePayable.
  ///
  /// In en, this message translates to:
  /// **'Update Payable'**
  String get updatePayable;

  /// No description provided for @amountPaidCannotExceedAmountBorrowed.
  ///
  /// In en, this message translates to:
  /// **'Amount paid cannot exceed amount borrowed'**
  String get amountPaidCannotExceedAmountBorrowed;

  /// No description provided for @payableUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payable updated successfully!'**
  String get payableUpdatedSuccessfully;

  /// No description provided for @payableId.
  ///
  /// In en, this message translates to:
  /// **'Payable ID'**
  String get payableId;

  /// No description provided for @creditor.
  ///
  /// In en, this message translates to:
  /// **'Creditor'**
  String get creditor;

  /// No description provided for @showingPayableRecords.
  ///
  /// In en, this message translates to:
  /// **'Showing {start}-{end} of {total} payable records'**
  String showingPayableRecords(int start, int end, int total);

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @filterPayables.
  ///
  /// In en, this message translates to:
  /// **'Filter Payables'**
  String get filterPayables;

  /// No description provided for @applyFiltersToFindSpecificPayables.
  ///
  /// In en, this message translates to:
  /// **'Apply filters to find specific payables'**
  String get applyFiltersToFindSpecificPayables;

  /// No description provided for @searchByCreditorNameReasonNotes.
  ///
  /// In en, this message translates to:
  /// **'Search by creditor name, reason, notes...'**
  String get searchByCreditorNameReasonNotes;

  /// No description provided for @statusAndPriority.
  ///
  /// In en, this message translates to:
  /// **'Status & Priority'**
  String get statusAndPriority;

  /// No description provided for @selectStatus.
  ///
  /// In en, this message translates to:
  /// **'Select status'**
  String get selectStatus;

  /// No description provided for @paidStatus.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidStatus;

  /// No description provided for @partiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get partiallyPaid;

  /// No description provided for @selectPriority.
  ///
  /// In en, this message translates to:
  /// **'Select priority'**
  String get selectPriority;

  /// No description provided for @allPriorities.
  ///
  /// In en, this message translates to:
  /// **'All Priorities'**
  String get allPriorities;

  /// No description provided for @selectVendor.
  ///
  /// In en, this message translates to:
  /// **'Select vendor'**
  String get selectVendor;

  /// No description provided for @allVendors.
  ///
  /// In en, this message translates to:
  /// **'All Vendors'**
  String get allVendors;

  /// No description provided for @dateRanges.
  ///
  /// In en, this message translates to:
  /// **'Date Ranges'**
  String get dateRanges;

  /// No description provided for @dueAfter.
  ///
  /// In en, this message translates to:
  /// **'Due After'**
  String get dueAfter;

  /// No description provided for @dueBefore.
  ///
  /// In en, this message translates to:
  /// **'Due Before'**
  String get dueBefore;

  /// No description provided for @borrowedAfter.
  ///
  /// In en, this message translates to:
  /// **'Borrowed After'**
  String get borrowedAfter;

  /// No description provided for @borrowedBefore.
  ///
  /// In en, this message translates to:
  /// **'Borrowed Before'**
  String get borrowedBefore;

  /// No description provided for @creditorDetails.
  ///
  /// In en, this message translates to:
  /// **'Creditor Details'**
  String get creditorDetails;

  /// No description provided for @repaymentDate.
  ///
  /// In en, this message translates to:
  /// **'Repayment Date'**
  String get repaymentDate;

  /// No description provided for @pkrRemaining.
  ///
  /// In en, this message translates to:
  /// **'PKR {amount} remaining'**
  String pkrRemaining(String amount);

  /// No description provided for @daysOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days overdue'**
  String daysOverdueCount(int count);

  /// No description provided for @noPayablesFound.
  ///
  /// In en, this message translates to:
  /// **'No Payables Found'**
  String get noPayablesFound;

  /// No description provided for @startByAddingYourFirstPayableRecord.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first payable record to track amounts borrowed from suppliers and creditors'**
  String get startByAddingYourFirstPayableRecord;

  /// No description provided for @addFirstPayable.
  ///
  /// In en, this message translates to:
  /// **'Add First Payable'**
  String get addFirstPayable;

  /// No description provided for @failedToLoadPayables.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Payables'**
  String get failedToLoadPayables;

  /// No description provided for @anUnexpectedErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get anUnexpectedErrorOccurred;

  /// No description provided for @startByAddingYourFirstPayableRecordToTrackYourBorrowingsEffectively.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first payable record to track your borrowings effectively'**
  String get startByAddingYourFirstPayableRecordToTrackYourBorrowingsEffectively;

  /// No description provided for @addFirstPayableRecord.
  ///
  /// In en, this message translates to:
  /// **'Add First Payable Record'**
  String get addFirstPayableRecord;

  /// No description provided for @fullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Fully Paid'**
  String get fullyPaid;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @payableDetails.
  ///
  /// In en, this message translates to:
  /// **'Payable Details'**
  String get payableDetails;

  /// No description provided for @viewCompletePayableInformation.
  ///
  /// In en, this message translates to:
  /// **'View complete payable information'**
  String get viewCompletePayableInformation;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @amountPaid.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid'**
  String get amountPaid;

  /// No description provided for @paymentProgress.
  ///
  /// In en, this message translates to:
  /// **'Payment Progress'**
  String get paymentProgress;

  /// No description provided for @notUpdated.
  ///
  /// In en, this message translates to:
  /// **'Not updated'**
  String get notUpdated;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost Price'**
  String get costPrice;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @fabric.
  ///
  /// In en, this message translates to:
  /// **'Fabric'**
  String get fabric;

  /// No description provided for @stockStatus.
  ///
  /// In en, this message translates to:
  /// **'Stock Status'**
  String get stockStatus;

  /// No description provided for @pieces.
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get pieces;

  /// No description provided for @createdDate.
  ///
  /// In en, this message translates to:
  /// **'Created Date'**
  String get createdDate;

  /// No description provided for @noDetails.
  ///
  /// In en, this message translates to:
  /// **'No details'**
  String get noDetails;

  /// No description provided for @noPieces.
  ///
  /// In en, this message translates to:
  /// **'No pieces'**
  String get noPieces;

  /// No description provided for @noProductRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No Product Records Found'**
  String get noProductRecordsFound;

  /// No description provided for @startByAddingYourFirstProductToManageInventoryEfficiently.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first product to manage inventory efficiently'**
  String get startByAddingYourFirstProductToManageInventoryEfficiently;

  /// No description provided for @addFirstProduct.
  ///
  /// In en, this message translates to:
  /// **'Add First Product'**
  String get addFirstProduct;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @oneWeekAgo.
  ///
  /// In en, this message translates to:
  /// **'1 week ago'**
  String get oneWeekAgo;

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks ago'**
  String weeksAgo(int count);

  /// No description provided for @oneMonthAgo.
  ///
  /// In en, this message translates to:
  /// **'1 month ago'**
  String get oneMonthAgo;

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String monthsAgo(int count);

  /// No description provided for @oneYearAgo.
  ///
  /// In en, this message translates to:
  /// **'1 year ago'**
  String get oneYearAgo;

  /// No description provided for @yearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} years ago'**
  String yearsAgo(int count);

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @viewCompleteProductInformation.
  ///
  /// In en, this message translates to:
  /// **'View complete product information'**
  String get viewCompleteProductInformation;

  /// No description provided for @unnamedProduct.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Product'**
  String get unnamedProduct;

  /// No description provided for @noDetailsProvided.
  ///
  /// In en, this message translates to:
  /// **'No details provided'**
  String get noDetailsProvided;

  /// No description provided for @setCostPriceToCalculateProfitMargin.
  ///
  /// In en, this message translates to:
  /// **'Set cost price to calculate profit margin'**
  String get setCostPriceToCalculateProfitMargin;

  /// No description provided for @unitsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} units'**
  String unitsCount(int count);

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @productPieces.
  ///
  /// In en, this message translates to:
  /// **'Product Pieces'**
  String get productPieces;

  /// No description provided for @noPiecesSpecified.
  ///
  /// In en, this message translates to:
  /// **'No pieces specified'**
  String get noPiecesSpecified;

  /// No description provided for @productActive.
  ///
  /// In en, this message translates to:
  /// **'Product Active'**
  String get productActive;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @editProductDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Product Details'**
  String get editProductDetails;

  /// No description provided for @updateProductInformation.
  ///
  /// In en, this message translates to:
  /// **'Update product information'**
  String get updateProductInformation;

  /// No description provided for @productUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully!'**
  String get productUpdatedSuccessfully;

  /// No description provided for @failedToUpdateProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to update product'**
  String get failedToUpdateProduct;

  /// No description provided for @productDetail.
  ///
  /// In en, this message translates to:
  /// **'Product Detail'**
  String get productDetail;

  /// No description provided for @enterDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter details'**
  String get enterDetails;

  /// No description provided for @enterProductDescriptionDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter product description/details'**
  String get enterProductDescriptionDetails;

  /// No description provided for @pleaseEnterProductDetails.
  ///
  /// In en, this message translates to:
  /// **'Please enter product details'**
  String get pleaseEnterProductDetails;

  /// No description provided for @productDetailMustBeAtLeast5Characters.
  ///
  /// In en, this message translates to:
  /// **'Product detail must be at least 5 characters'**
  String get productDetailMustBeAtLeast5Characters;

  /// No description provided for @enterPricePkr.
  ///
  /// In en, this message translates to:
  /// **'Enter price (PKR)'**
  String get enterPricePkr;

  /// No description provided for @pleaseEnterPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter price'**
  String get pleaseEnterPrice;

  /// No description provided for @pleaseEnterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get pleaseEnterValidPrice;

  /// No description provided for @enterCost.
  ///
  /// In en, this message translates to:
  /// **'Enter cost'**
  String get enterCost;

  /// No description provided for @enterCostPricePkrOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter cost price (PKR) - Optional'**
  String get enterCostPricePkrOptional;

  /// No description provided for @pleaseEnterValidCostPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid cost price'**
  String get pleaseEnterValidCostPrice;

  /// No description provided for @enterQty.
  ///
  /// In en, this message translates to:
  /// **'Enter qty'**
  String get enterQty;

  /// No description provided for @pleaseEnterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter quantity'**
  String get pleaseEnterQuantity;

  /// No description provided for @pleaseEnterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid quantity'**
  String get pleaseEnterValidQuantity;

  /// No description provided for @loadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Loading categories...'**
  String get loadingCategories;

  /// No description provided for @noCategoriesAvailablePleaseAddCategoriesFirst.
  ///
  /// In en, this message translates to:
  /// **'No categories available. Please add categories first.'**
  String get noCategoriesAvailablePleaseAddCategoriesFirst;

  /// No description provided for @noId.
  ///
  /// In en, this message translates to:
  /// **'No ID'**
  String get noId;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get selectCategory;

  /// No description provided for @selectProductCategory.
  ///
  /// In en, this message translates to:
  /// **'Select product category'**
  String get selectProductCategory;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @enterColorName.
  ///
  /// In en, this message translates to:
  /// **'Enter color name (e.g., Red, Blue, Turquoise)'**
  String get enterColorName;

  /// No description provided for @pleaseEnterColor.
  ///
  /// In en, this message translates to:
  /// **'Please enter a color'**
  String get pleaseEnterColor;

  /// No description provided for @colorNameMustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Color name must be at least 2 characters'**
  String get colorNameMustBeAtLeast2Characters;

  /// No description provided for @enterFabricType.
  ///
  /// In en, this message translates to:
  /// **'Enter fabric type (e.g., Cotton, Silk, Chiffon)'**
  String get enterFabricType;

  /// No description provided for @pleaseEnterFabric.
  ///
  /// In en, this message translates to:
  /// **'Please enter a fabric'**
  String get pleaseEnterFabric;

  /// No description provided for @fabricNameMustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Fabric name must be at least 2 characters'**
  String get fabricNameMustBeAtLeast2Characters;

  /// No description provided for @productNameMustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Product name must be at least 2 characters'**
  String get productNameMustBeAtLeast2Characters;

  /// No description provided for @pleaseEnterProductName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product name'**
  String get pleaseEnterProductName;

  /// No description provided for @updateProduct.
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get updateProduct;

  /// No description provided for @addPayment.
  ///
  /// In en, this message translates to:
  /// **'Add Payment'**
  String get addPayment;

  /// No description provided for @addLaborPayment.
  ///
  /// In en, this message translates to:
  /// **'Add Employee Payment'**
  String get addLaborPayment;

  /// No description provided for @recordNewPaymentWithReceipt.
  ///
  /// In en, this message translates to:
  /// **'Record new payment to employee with receipt'**
  String get recordNewPaymentWithReceipt;

  /// No description provided for @paymentAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment added successfully!'**
  String get paymentAddedSuccessfully;

  /// No description provided for @pleaseSelectAtLeastOneEntity.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one entity (employee, vendor, order, or sale)'**
  String get pleaseSelectAtLeastOneEntity;

  /// No description provided for @pleaseSelectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get pleaseSelectPaymentMethod;

  /// No description provided for @pleaseSelectPaymentMonth.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment month'**
  String get pleaseSelectPaymentMonth;

  /// No description provided for @netAmountCannotExceedRemaining.
  ///
  /// In en, this message translates to:
  /// **'Net amount cannot exceed remaining amount of PKR {amount}'**
  String netAmountCannotExceedRemaining(String amount);

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount'**
  String get paymentAmount;

  /// No description provided for @paymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get paymentDetails;

  /// No description provided for @receiptImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Receipt Image (Optional)'**
  String get receiptImageOptional;

  /// No description provided for @uploadReceiptForBetterRecordKeeping.
  ///
  /// In en, this message translates to:
  /// **'Upload receipt image for better record keeping'**
  String get uploadReceiptForBetterRecordKeeping;

  /// No description provided for @entityType.
  ///
  /// In en, this message translates to:
  /// **'Entity Type'**
  String get entityType;

  /// No description provided for @selectEntityType.
  ///
  /// In en, this message translates to:
  /// **'Select entity type'**
  String get selectEntityType;

  /// No description provided for @pleaseSelectEntityType.
  ///
  /// In en, this message translates to:
  /// **'Please select entity type'**
  String get pleaseSelectEntityType;

  /// No description provided for @selectLabor.
  ///
  /// In en, this message translates to:
  /// **'Select Employee'**
  String get selectLabor;

  /// No description provided for @chooseLaborForPayment.
  ///
  /// In en, this message translates to:
  /// **'Choose employee for payment'**
  String get chooseLaborForPayment;

  /// No description provided for @pleaseSelectLabor.
  ///
  /// In en, this message translates to:
  /// **'Please select a employee'**
  String get pleaseSelectLabor;

  /// No description provided for @vendorId.
  ///
  /// In en, this message translates to:
  /// **'Vendor ID'**
  String get vendorId;

  /// No description provided for @pleaseEnterVendorId.
  ///
  /// In en, this message translates to:
  /// **'Please enter vendor ID'**
  String get pleaseEnterVendorId;

  /// No description provided for @customerType.
  ///
  /// In en, this message translates to:
  /// **'Customer Type'**
  String get customerType;

  /// No description provided for @selectCustomerType.
  ///
  /// In en, this message translates to:
  /// **'Select customer type'**
  String get selectCustomerType;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sale;

  /// No description provided for @enterOrderSaleId.
  ///
  /// In en, this message translates to:
  /// **'Enter {type} ID'**
  String enterOrderSaleId(String type);

  /// No description provided for @paymentMonth.
  ///
  /// In en, this message translates to:
  /// **'Payment Month'**
  String get paymentMonth;

  /// No description provided for @selectPaymentMonth.
  ///
  /// In en, this message translates to:
  /// **'Select payment month'**
  String get selectPaymentMonth;

  /// No description provided for @paymentAmountPkr.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount (PKR)'**
  String get paymentAmountPkr;

  /// No description provided for @enterPaymentAmountPkr.
  ///
  /// In en, this message translates to:
  /// **'Enter payment amount (PKR)'**
  String get enterPaymentAmountPkr;

  /// No description provided for @pleaseEnterPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter payment amount'**
  String get pleaseEnterPaymentAmount;

  /// No description provided for @bonusPkr.
  ///
  /// In en, this message translates to:
  /// **'Bonus (PKR)'**
  String get bonusPkr;

  /// No description provided for @optionalBonus.
  ///
  /// In en, this message translates to:
  /// **'Optional bonus'**
  String get optionalBonus;

  /// No description provided for @pleaseEnterValidBonusAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid bonus amount'**
  String get pleaseEnterValidBonusAmount;

  /// No description provided for @deductionPkr.
  ///
  /// In en, this message translates to:
  /// **'Deduction (PKR)'**
  String get deductionPkr;

  /// No description provided for @optionalDeduction.
  ///
  /// In en, this message translates to:
  /// **'Optional deduction'**
  String get optionalDeduction;

  /// No description provided for @pleaseEnterValidDeductionAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid deduction amount'**
  String get pleaseEnterValidDeductionAmount;

  /// No description provided for @enterPaymentDescriptionOrNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter payment description or notes'**
  String get enterPaymentDescriptionOrNotes;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @finalPaymentForMonth.
  ///
  /// In en, this message translates to:
  /// **'Final Payment for Month'**
  String get finalPaymentForMonth;

  /// No description provided for @thisCompletesPaymentForSelectedMonth.
  ///
  /// In en, this message translates to:
  /// **'This completes the payment for the selected month'**
  String get thisCompletesPaymentForSelectedMonth;

  /// No description provided for @markThisAsFinalPaymentForMonth.
  ///
  /// In en, this message translates to:
  /// **'Mark this as the final payment for the month'**
  String get markThisAsFinalPaymentForMonth;

  /// No description provided for @netPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Net Payment Amount'**
  String get netPaymentAmount;

  /// No description provided for @remainingAfterPayment.
  ///
  /// In en, this message translates to:
  /// **'Remaining after payment: PKR {amount}'**
  String remainingAfterPayment(String amount);

  /// No description provided for @paymentReceiptOptional.
  ///
  /// In en, this message translates to:
  /// **'Payment Receipt (Optional)'**
  String get paymentReceiptOptional;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get selectPaymentMethod;

  /// No description provided for @enter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enter;

  /// No description provided for @editPayment.
  ///
  /// In en, this message translates to:
  /// **'Edit Payment'**
  String get editPayment;

  /// No description provided for @editPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Payment Details'**
  String get editPaymentDetails;

  /// No description provided for @updatePaymentInformation.
  ///
  /// In en, this message translates to:
  /// **'Update payment information'**
  String get updatePaymentInformation;

  /// No description provided for @paymentUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment updated successfully!'**
  String get paymentUpdatedSuccessfully;

  /// No description provided for @netAmountCannotExceedAvailable.
  ///
  /// In en, this message translates to:
  /// **'Net amount cannot exceed available amount of PKR {amount}'**
  String netAmountCannotExceedAvailable(String amount);

  /// No description provided for @selectLaborForPayment.
  ///
  /// In en, this message translates to:
  /// **'Select employee for payment'**
  String get selectLaborForPayment;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @enterValidBonus.
  ///
  /// In en, this message translates to:
  /// **'Enter valid bonus'**
  String get enterValidBonus;

  /// No description provided for @enterValidDeduction.
  ///
  /// In en, this message translates to:
  /// **'Enter valid deduction'**
  String get enterValidDeduction;

  /// No description provided for @netAmount.
  ///
  /// In en, this message translates to:
  /// **'Net Amount'**
  String get netAmount;

  /// No description provided for @receiptImageSelected.
  ///
  /// In en, this message translates to:
  /// **'Receipt image selected'**
  String get receiptImageSelected;

  /// No description provided for @tapToSelectReceiptImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to select receipt image'**
  String get tapToSelectReceiptImage;

  /// No description provided for @updatePayment.
  ///
  /// In en, this message translates to:
  /// **'Update Payment'**
  String get updatePayment;

  /// No description provided for @paymentId.
  ///
  /// In en, this message translates to:
  /// **'Payment ID'**
  String get paymentId;

  /// No description provided for @desc.
  ///
  /// In en, this message translates to:
  /// **'Desc'**
  String get desc;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @paymentFilters.
  ///
  /// In en, this message translates to:
  /// **'Payment Filters'**
  String get paymentFilters;

  /// No description provided for @searchByLaborVendorDescription.
  ///
  /// In en, this message translates to:
  /// **'Search by employee name, vendor, description...'**
  String get searchByLaborVendorDescription;

  /// No description provided for @entityFilters.
  ///
  /// In en, this message translates to:
  /// **'Entity Filters'**
  String get entityFilters;

  /// No description provided for @allLabors.
  ///
  /// In en, this message translates to:
  /// **'All Employees'**
  String get allLabors;

  /// No description provided for @payerType.
  ///
  /// In en, this message translates to:
  /// **'Payer Type'**
  String get payerType;

  /// No description provided for @selectPayerType.
  ///
  /// In en, this message translates to:
  /// **'Select payer type'**
  String get selectPayerType;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @allMethods.
  ///
  /// In en, this message translates to:
  /// **'All Methods'**
  String get allMethods;

  /// No description provided for @finalPayment.
  ///
  /// In en, this message translates to:
  /// **'Final Payment'**
  String get finalPayment;

  /// No description provided for @selectFinalPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Select final payment status'**
  String get selectFinalPaymentStatus;

  /// No description provided for @finalOnly.
  ///
  /// In en, this message translates to:
  /// **'Final Only'**
  String get finalOnly;

  /// No description provided for @partialOnly.
  ///
  /// In en, this message translates to:
  /// **'Partial Only'**
  String get partialOnly;

  /// No description provided for @hasReceipt.
  ///
  /// In en, this message translates to:
  /// **'Has Receipt'**
  String get hasReceipt;

  /// No description provided for @selectReceiptStatus.
  ///
  /// In en, this message translates to:
  /// **'Select receipt status'**
  String get selectReceiptStatus;

  /// No description provided for @withReceipt.
  ///
  /// In en, this message translates to:
  /// **'With Receipt'**
  String get withReceipt;

  /// No description provided for @withoutReceipt.
  ///
  /// In en, this message translates to:
  /// **'Without Receipt'**
  String get withoutReceipt;

  /// No description provided for @selectVisibility.
  ///
  /// In en, this message translates to:
  /// **'Select visibility'**
  String get selectVisibility;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get showAll;

  /// No description provided for @activeOnly.
  ///
  /// In en, this message translates to:
  /// **'Active Only'**
  String get activeOnly;

  /// No description provided for @paymentDateFrom.
  ///
  /// In en, this message translates to:
  /// **'Payment Date From'**
  String get paymentDateFrom;

  /// No description provided for @paymentDateTo.
  ///
  /// In en, this message translates to:
  /// **'Payment Date To'**
  String get paymentDateTo;

  /// No description provided for @paymentMonthFrom.
  ///
  /// In en, this message translates to:
  /// **'Payment Month From'**
  String get paymentMonthFrom;

  /// No description provided for @paymentMonthTo.
  ///
  /// In en, this message translates to:
  /// **'Payment Month To'**
  String get paymentMonthTo;

  /// No description provided for @amountRangePkr.
  ///
  /// In en, this message translates to:
  /// **'Amount Range (PKR)'**
  String get amountRangePkr;

  /// No description provided for @minimumAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum Amount'**
  String get minimumAmount;

  /// No description provided for @maximumAmount.
  ///
  /// In en, this message translates to:
  /// **'Maximum Amount'**
  String get maximumAmount;

  /// No description provided for @selectSortField.
  ///
  /// In en, this message translates to:
  /// **'Select sort field'**
  String get selectSortField;

  /// No description provided for @paymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get paymentDate;

  /// No description provided for @laborName.
  ///
  /// In en, this message translates to:
  /// **'Employee Name'**
  String get laborName;

  /// No description provided for @selectSortOrder.
  ///
  /// In en, this message translates to:
  /// **'Select sort order'**
  String get selectSortOrder;

  /// No description provided for @receiptImage.
  ///
  /// In en, this message translates to:
  /// **'Receipt Image'**
  String get receiptImage;

  /// No description provided for @paymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Payment Receipt'**
  String get paymentReceipt;

  /// No description provided for @baseAmount.
  ///
  /// In en, this message translates to:
  /// **'Base Amount'**
  String get baseAmount;

  /// No description provided for @bonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get bonus;

  /// No description provided for @deduction.
  ///
  /// In en, this message translates to:
  /// **'Deduction'**
  String get deduction;

  /// No description provided for @noReceiptAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Receipt Available'**
  String get noReceiptAvailable;

  /// No description provided for @noReceiptAvailableShort.
  ///
  /// In en, this message translates to:
  /// **'No receipt available. Add one for better records.'**
  String get noReceiptAvailableShort;

  /// No description provided for @noReceiptAvailableLong.
  ///
  /// In en, this message translates to:
  /// **'No receipt image was uploaded for this payment. Consider adding a receipt for better record keeping.'**
  String get noReceiptAvailableLong;

  /// No description provided for @addReceiptImage.
  ///
  /// In en, this message translates to:
  /// **'Add Receipt Image'**
  String get addReceiptImage;

  /// No description provided for @receiptUploadedSaveToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Receipt uploaded! Please save the payment to update.'**
  String get receiptUploadedSaveToUpdate;

  /// No description provided for @paymentInfo.
  ///
  /// In en, this message translates to:
  /// **'Payment Info'**
  String get paymentInfo;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missing;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get viewReceipt;

  /// No description provided for @addReceipt.
  ///
  /// In en, this message translates to:
  /// **'Add Receipt'**
  String get addReceipt;

  /// No description provided for @noPaymentRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No Payment Records Found'**
  String get noPaymentRecordsFound;

  /// No description provided for @startByAddingFirstPaymentRecord.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first payment record to track employee payments efficiently'**
  String get startByAddingFirstPaymentRecord;

  /// No description provided for @addFirstPayment.
  ///
  /// In en, this message translates to:
  /// **'Add First Payment'**
  String get addFirstPayment;

  /// No description provided for @failedToLoadPayments.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Payments'**
  String get failedToLoadPayments;

  /// No description provided for @noPaymentsFound.
  ///
  /// In en, this message translates to:
  /// **'No Payments Found'**
  String get noPaymentsFound;

  /// No description provided for @startByAddingFirstPaymentToTrack.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first payment record to track your transactions effectively'**
  String get startByAddingFirstPaymentToTrack;

  /// No description provided for @withBonus.
  ///
  /// In en, this message translates to:
  /// **'With Bonus'**
  String get withBonus;

  /// No description provided for @withDeduction.
  ///
  /// In en, this message translates to:
  /// **'With Deduction'**
  String get withDeduction;

  /// No description provided for @purchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchases;

  /// No description provided for @regularPayment.
  ///
  /// In en, this message translates to:
  /// **'Regular Payment'**
  String get regularPayment;

  /// No description provided for @viewPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'View Payment Details'**
  String get viewPaymentDetails;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @paymentInformation.
  ///
  /// In en, this message translates to:
  /// **'Payment Information'**
  String get paymentInformation;

  /// No description provided for @payerInformation.
  ///
  /// In en, this message translates to:
  /// **'Payer Information'**
  String get payerInformation;

  /// No description provided for @payerId.
  ///
  /// In en, this message translates to:
  /// **'Payer ID'**
  String get payerId;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @saleId.
  ///
  /// In en, this message translates to:
  /// **'Sale ID'**
  String get saleId;

  /// No description provided for @isFinalPayment.
  ///
  /// In en, this message translates to:
  /// **'Is Final Payment'**
  String get isFinalPayment;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @systemInformation.
  ///
  /// In en, this message translates to:
  /// **'System Information'**
  String get systemInformation;

  /// No description provided for @amountIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountIsRequired;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @paymentMethodIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Payment method is required'**
  String get paymentMethodIsRequired;

  /// No description provided for @payerTypeIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Payer type is required'**
  String get payerTypeIsRequired;

  /// No description provided for @receiptAvailable.
  ///
  /// In en, this message translates to:
  /// **'Receipt Available'**
  String get receiptAvailable;

  /// No description provided for @failedToUpdatePayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to update payment'**
  String get failedToUpdatePayment;

  /// No description provided for @errorUpdatingPayment.
  ///
  /// In en, this message translates to:
  /// **'Error updating payment'**
  String get errorUpdatingPayment;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @viewPaymentDetailsAndReceipt.
  ///
  /// In en, this message translates to:
  /// **'View payment details and receipt'**
  String get viewPaymentDetailsAndReceipt;

  /// No description provided for @addReceiptForThisPayment.
  ///
  /// In en, this message translates to:
  /// **'Add receipt for this payment'**
  String get addReceiptForThisPayment;

  /// No description provided for @laborRole.
  ///
  /// In en, this message translates to:
  /// **'Employee Role'**
  String get laborRole;

  /// No description provided for @laborPhone.
  ///
  /// In en, this message translates to:
  /// **'Employee Phone'**
  String get laborPhone;

  /// No description provided for @paymentDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment deleted successfully!'**
  String get paymentDeletedSuccessfully;

  /// No description provided for @deletePayment.
  ///
  /// In en, this message translates to:
  /// **'Delete Payment'**
  String get deletePayment;

  /// No description provided for @deletePaymentRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Payment Record'**
  String get deletePaymentRecord;

  /// No description provided for @areYouSureDeletePayment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this payment?'**
  String get areYouSureDeletePayment;

  /// No description provided for @areYouAbsolutelySureDeletePayment.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure you want to delete this payment record?'**
  String get areYouAbsolutelySureDeletePayment;

  /// No description provided for @thisWillPermanentlyDeletePayment.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the payment record.'**
  String get thisWillPermanentlyDeletePayment;

  /// No description provided for @thisWillPermanentlyDeletePaymentLong.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the payment record and all associated data. This action cannot be undone.'**
  String get thisWillPermanentlyDeletePaymentLong;

  /// No description provided for @failedToDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete product'**
  String get failedToDeleteProduct;

  /// No description provided for @productDeletedPermanently.
  ///
  /// In en, this message translates to:
  /// **'Product deleted permanently!'**
  String get productDeletedPermanently;

  /// No description provided for @productDeactivatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product deactivated successfully!'**
  String get productDeactivatedSuccessfully;

  /// No description provided for @productCanBeRestoredLater.
  ///
  /// In en, this message translates to:
  /// **'Product can be restored later'**
  String get productCanBeRestoredLater;

  /// No description provided for @completelyRemovesFromDatabase.
  ///
  /// In en, this message translates to:
  /// **'Completely removes from database'**
  String get completelyRemovesFromDatabase;

  /// No description provided for @hidesButCanBeRestored.
  ///
  /// In en, this message translates to:
  /// **'Hides but can be restored'**
  String get hidesButCanBeRestored;

  /// No description provided for @totalInventoryValue.
  ///
  /// In en, this message translates to:
  /// **'Total Inventory Value'**
  String get totalInventoryValue;

  /// No description provided for @iUnderstandPermanentDelete.
  ///
  /// In en, this message translates to:
  /// **'I understand this will permanently delete the product and cannot be undone'**
  String get iUnderstandPermanentDelete;

  /// No description provided for @iUnderstandDeactivate.
  ///
  /// In en, this message translates to:
  /// **'I understand this will deactivate the product'**
  String get iUnderstandDeactivate;

  /// No description provided for @deactivateProduct.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Product'**
  String get deactivateProduct;

  /// No description provided for @editOrder.
  ///
  /// In en, this message translates to:
  /// **'Edit Order'**
  String get editOrder;

  /// No description provided for @updateOrderInformation.
  ///
  /// In en, this message translates to:
  /// **'Update order information'**
  String get updateOrderInformation;

  /// No description provided for @orderUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order updated successfully!'**
  String get orderUpdatedSuccessfully;

  /// No description provided for @orderUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Order Update Failed'**
  String get orderUpdateFailed;

  /// No description provided for @invalidStatusTransition.
  ///
  /// In en, this message translates to:
  /// **'Invalid Status Transition'**
  String get invalidStatusTransition;

  /// No description provided for @cannotChangeStatusFrom.
  ///
  /// In en, this message translates to:
  /// **'You cannot change the status from'**
  String get cannotChangeStatusFrom;

  /// No description provided for @validNextStatusesAre.
  ///
  /// In en, this message translates to:
  /// **'Valid next statuses are'**
  String get validNextStatusesAre;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @serverErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Server error occurred. Please try again or contact support.'**
  String get serverErrorOccurred;

  /// No description provided for @invalidStatusSelected.
  ///
  /// In en, this message translates to:
  /// **'Invalid status selected. Please choose a valid status.'**
  String get invalidStatusSelected;

  /// No description provided for @invalidDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid date format. Please select a valid delivery date.'**
  String get invalidDateFormat;

  /// No description provided for @deliveryDateCannotBeBeforeOrderDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery date cannot be before the order date.'**
  String get deliveryDateCannotBeBeforeOrderDate;

  /// No description provided for @advancePaymentCannotExceedTotal.
  ///
  /// In en, this message translates to:
  /// **'Advance payment cannot exceed the total order amount.'**
  String get advancePaymentCannotExceedTotal;

  /// No description provided for @orderCannotBeModified.
  ///
  /// In en, this message translates to:
  /// **'This order cannot be modified in its current status.'**
  String get orderCannotBeModified;

  /// No description provided for @orderCannotHaveStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'This order cannot have its status changed.'**
  String get orderCannotHaveStatusChanged;

  /// No description provided for @invalidStatusTransitionFrom.
  ///
  /// In en, this message translates to:
  /// **'Invalid status transition. From'**
  String get invalidStatusTransitionFrom;

  /// No description provided for @youCanOnlyChangeTo.
  ///
  /// In en, this message translates to:
  /// **'you can only change to'**
  String get youCanOnlyChangeTo;

  /// No description provided for @customerInformation.
  ///
  /// In en, this message translates to:
  /// **'Customer Information'**
  String get customerInformation;

  /// No description provided for @customerSince.
  ///
  /// In en, this message translates to:
  /// **'Customer since'**
  String get customerSince;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @orderDescription.
  ///
  /// In en, this message translates to:
  /// **'Order Description'**
  String get orderDescription;

  /// No description provided for @describeOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'Describe the order details (e.g., products, specifications)'**
  String get describeOrderDetails;

  /// No description provided for @pleaseEnterOrderDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter order description'**
  String get pleaseEnterOrderDescription;

  /// No description provided for @descriptionMustBeAtLeast10Characters.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 10 characters'**
  String get descriptionMustBeAtLeast10Characters;

  /// No description provided for @descriptionMustBeLessThan500Characters.
  ///
  /// In en, this message translates to:
  /// **'Description must be less than 500 characters'**
  String get descriptionMustBeLessThan500Characters;

  /// No description provided for @orderStatus.
  ///
  /// In en, this message translates to:
  /// **'Order Status'**
  String get orderStatus;

  /// No description provided for @currentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get currentStatus;

  /// No description provided for @validNextStatuses.
  ///
  /// In en, this message translates to:
  /// **'Valid next statuses'**
  String get validNextStatuses;

  /// No description provided for @totalAmountPKR.
  ///
  /// In en, this message translates to:
  /// **'Total Amount (PKR)'**
  String get totalAmountPKR;

  /// No description provided for @totalOrderAmount.
  ///
  /// In en, this message translates to:
  /// **'Total order amount'**
  String get totalOrderAmount;

  /// No description provided for @advancePaymentPKR.
  ///
  /// In en, this message translates to:
  /// **'Advance Payment (PKR)'**
  String get advancePaymentPKR;

  /// No description provided for @enterAdvancePaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter advance payment amount'**
  String get enterAdvancePaymentAmount;

  /// No description provided for @pleaseEnterAdvancePayment.
  ///
  /// In en, this message translates to:
  /// **'Please enter advance payment'**
  String get pleaseEnterAdvancePayment;

  /// No description provided for @remainingAmountPKR.
  ///
  /// In en, this message translates to:
  /// **'Remaining Amount (PKR)'**
  String get remainingAmountPKR;

  /// No description provided for @remainingAmountToBePaid.
  ///
  /// In en, this message translates to:
  /// **'Remaining amount to be paid'**
  String get remainingAmountToBePaid;

  /// No description provided for @deliveryInformation.
  ///
  /// In en, this message translates to:
  /// **'Delivery Information'**
  String get deliveryInformation;

  /// No description provided for @orderDate.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDate;

  /// No description provided for @dateWhenOrderWasPlaced.
  ///
  /// In en, this message translates to:
  /// **'Date when order was placed'**
  String get dateWhenOrderWasPlaced;

  /// No description provided for @selectExpectedDeliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Select Expected Delivery Date'**
  String get selectExpectedDeliveryDate;

  /// No description provided for @expectedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Expected Delivery'**
  String get expectedDelivery;

  /// No description provided for @updateOrder.
  ///
  /// In en, this message translates to:
  /// **'Update Order'**
  String get updateOrder;

  /// No description provided for @inProduction.
  ///
  /// In en, this message translates to:
  /// **'In Production'**
  String get inProduction;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @orderItemsManagement.
  ///
  /// In en, this message translates to:
  /// **'Order Items Management'**
  String get orderItemsManagement;

  /// No description provided for @searchOrderItemsByProductDescriptionOrNotes.
  ///
  /// In en, this message translates to:
  /// **'Search order items by product, description, or notes...'**
  String get searchOrderItemsByProductDescriptionOrNotes;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @activeItems.
  ///
  /// In en, this message translates to:
  /// **'Active Items'**
  String get activeItems;

  /// No description provided for @totalQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total Quantity'**
  String get totalQuantity;

  /// No description provided for @loadingOrderItems.
  ///
  /// In en, this message translates to:
  /// **'Loading order items...'**
  String get loadingOrderItems;

  /// No description provided for @errorLoadingOrderItems.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Order Items'**
  String get errorLoadingOrderItems;

  /// No description provided for @noOrderItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No Order Items Found'**
  String get noOrderItemsFound;

  /// No description provided for @orderDoesntHaveItemsYet.
  ///
  /// In en, this message translates to:
  /// **'This order doesn\'t have any items yet. Add your first order item to get started.'**
  String get orderDoesntHaveItemsYet;

  /// No description provided for @addFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Add First Item'**
  String get addFirstItem;

  /// No description provided for @activeSearch.
  ///
  /// In en, this message translates to:
  /// **'Active Search'**
  String get activeSearch;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearch;

  /// No description provided for @orderItemsRefreshedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order items refreshed successfully'**
  String get orderItemsRefreshedSuccessfully;

  /// No description provided for @advancePaymentCannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Advance payment cannot be negative'**
  String get advancePaymentCannotBeNegative;

  /// No description provided for @orderID.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderID;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @noPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone'**
  String get noPhone;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get item;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// No description provided for @addItemsToSeeTotal.
  ///
  /// In en, this message translates to:
  /// **'Add items to see total'**
  String get addItemsToSeeTotal;

  /// No description provided for @noDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get noDate;

  /// No description provided for @errorDisplayingOrder.
  ///
  /// In en, this message translates to:
  /// **'Error displaying order'**
  String get errorDisplayingOrder;

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @startProduction.
  ///
  /// In en, this message translates to:
  /// **'Start Production'**
  String get startProduction;

  /// No description provided for @markAsReady.
  ///
  /// In en, this message translates to:
  /// **'Mark as Ready'**
  String get markAsReady;

  /// No description provided for @markAsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark as Delivered'**
  String get markAsDelivered;

  /// No description provided for @changeOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Order Status'**
  String get changeOrderStatus;

  /// No description provided for @areYouSureChangeStatusTo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change the status of order'**
  String get areYouSureChangeStatusTo;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get changeStatus;

  /// No description provided for @failedToUpdateOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update order status'**
  String get failedToUpdateOrderStatus;

  /// No description provided for @orderStatusUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Order status updated to'**
  String get orderStatusUpdatedTo;

  /// No description provided for @successfully.
  ///
  /// In en, this message translates to:
  /// **'successfully'**
  String get successfully;

  /// No description provided for @deactivateOrder.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Order'**
  String get deactivateOrder;

  /// No description provided for @areYouSureDeactivateOrder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate order'**
  String get areYouSureDeactivateOrder;

  /// No description provided for @thisActionCanBeReversed.
  ///
  /// In en, this message translates to:
  /// **'This action can be reversed.'**
  String get thisActionCanBeReversed;

  /// No description provided for @failedToDeactivateOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to deactivate order'**
  String get failedToDeactivateOrder;

  /// No description provided for @orderDeactivatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order deactivated successfully'**
  String get orderDeactivatedSuccessfully;

  /// No description provided for @restoreOrder.
  ///
  /// In en, this message translates to:
  /// **'Restore Order'**
  String get restoreOrder;

  /// No description provided for @areYouSureRestoreOrder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to restore order'**
  String get areYouSureRestoreOrder;

  /// No description provided for @failedToRestoreOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore order'**
  String get failedToRestoreOrder;

  /// No description provided for @orderRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order restored successfully'**
  String get orderRestoredSuccessfully;

  /// No description provided for @failedToLoadOrders.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Orders'**
  String get failedToLoadOrders;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No Orders Found'**
  String get noOrdersFound;

  /// No description provided for @startManagingCustomerOrders.
  ///
  /// In en, this message translates to:
  /// **'Start managing your customer orders by creating your first order. Track deliveries, manage payments, and keep customers informed.'**
  String get startManagingCustomerOrders;

  /// No description provided for @createNewOrder.
  ///
  /// In en, this message translates to:
  /// **'Create New Order'**
  String get createNewOrder;

  /// No description provided for @noOrdersMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No orders match your search criteria'**
  String get noOrdersMatchSearch;

  /// No description provided for @tryAdjustingSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms or filters to find what you\'re looking for.'**
  String get tryAdjustingSearchTerms;

  /// No description provided for @selectProduct.
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get selectProduct;

  /// No description provided for @selectProductForOrder.
  ///
  /// In en, this message translates to:
  /// **'Select Product for Order'**
  String get selectProductForOrder;

  /// No description provided for @chooseProductToAddToOrder.
  ///
  /// In en, this message translates to:
  /// **'Choose a product to add to the order'**
  String get chooseProductToAddToOrder;

  /// No description provided for @pleaseSelectProduct.
  ///
  /// In en, this message translates to:
  /// **'Please select a product'**
  String get pleaseSelectProduct;

  /// No description provided for @searchProductsShort.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get searchProductsShort;

  /// No description provided for @searchProductsByNameFabricOrColor.
  ///
  /// In en, this message translates to:
  /// **'Search products by name, fabric, or color...'**
  String get searchProductsByNameFabricOrColor;

  /// No description provided for @availableProducts.
  ///
  /// In en, this message translates to:
  /// **'Available Products'**
  String get availableProducts;

  /// No description provided for @tryAdjustingYourSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms'**
  String get tryAdjustingYourSearchTerms;

  /// No description provided for @selectedProductDetails.
  ///
  /// In en, this message translates to:
  /// **'Selected Product Details'**
  String get selectedProductDetails;

  /// No description provided for @customizationNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Customization Notes (Optional)'**
  String get customizationNotesOptional;

  /// No description provided for @specialInstructionsOrCustomizationNotes.
  ///
  /// In en, this message translates to:
  /// **'Special instructions or customization notes'**
  String get specialInstructionsOrCustomizationNotes;

  /// No description provided for @notesMustBeLessThan500Characters.
  ///
  /// In en, this message translates to:
  /// **'Notes must be less than 500 characters'**
  String get notesMustBeLessThan500Characters;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @quantityMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than 0'**
  String get quantityMustBeGreaterThanZero;

  /// No description provided for @only.
  ///
  /// In en, this message translates to:
  /// **'Only'**
  String get only;

  /// No description provided for @unitsAvailable.
  ///
  /// In en, this message translates to:
  /// **'units available'**
  String get unitsAvailable;

  /// No description provided for @addToOrder.
  ///
  /// In en, this message translates to:
  /// **'Add to Order'**
  String get addToOrder;

  /// No description provided for @viewOrder.
  ///
  /// In en, this message translates to:
  /// **'View Order'**
  String get viewOrder;

  /// No description provided for @completeOrderInformation.
  ///
  /// In en, this message translates to:
  /// **'Complete order information'**
  String get completeOrderInformation;

  /// No description provided for @orderInformation.
  ///
  /// In en, this message translates to:
  /// **'Order Information'**
  String get orderInformation;

  /// No description provided for @paymentPercentage.
  ///
  /// In en, this message translates to:
  /// **'Payment Percentage'**
  String get paymentPercentage;

  /// No description provided for @orderItemsManagedSeparately.
  ///
  /// In en, this message translates to:
  /// **'Order items are managed separately. Use the Order Items module to view and manage products in this order.'**
  String get orderItemsManagedSeparately;

  /// No description provided for @daysSinceOrdered.
  ///
  /// In en, this message translates to:
  /// **'Days Since Ordered'**
  String get daysSinceOrdered;

  /// No description provided for @daysUntilDelivery.
  ///
  /// In en, this message translates to:
  /// **'Days Until Delivery'**
  String get daysUntilDelivery;

  /// No description provided for @isOverdue.
  ///
  /// In en, this message translates to:
  /// **'Is Overdue'**
  String get isOverdue;

  /// No description provided for @conversionStatus.
  ///
  /// In en, this message translates to:
  /// **'Conversion Status'**
  String get conversionStatus;

  /// No description provided for @convertedSalesAmount.
  ///
  /// In en, this message translates to:
  /// **'Converted Sales Amount'**
  String get convertedSalesAmount;

  /// No description provided for @conversionDate.
  ///
  /// In en, this message translates to:
  /// **'Conversion Date'**
  String get conversionDate;

  /// No description provided for @isActive.
  ///
  /// In en, this message translates to:
  /// **'Is Active'**
  String get isActive;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @editLabor.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get editLabor;

  /// No description provided for @editLaborDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee Details'**
  String get editLaborDetails;

  /// No description provided for @updateWorkerInformation.
  ///
  /// In en, this message translates to:
  /// **'Update worker information'**
  String get updateWorkerInformation;

  /// No description provided for @laborUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Employee updated successfully!'**
  String get laborUpdatedSuccessfully;

  /// No description provided for @failedToUpdateLabor.
  ///
  /// In en, this message translates to:
  /// **'Failed to update employee'**
  String get failedToUpdateLabor;

  /// No description provided for @errorUpdatingLabor.
  ///
  /// In en, this message translates to:
  /// **'Error updating employee'**
  String get errorUpdatingLabor;

  /// No description provided for @updateLabor.
  ///
  /// In en, this message translates to:
  /// **'Update Employee'**
  String get updateLabor;

  /// No description provided for @enterWorkerFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter worker\'s full name'**
  String get enterWorkerFullName;

  /// No description provided for @enterCNIC.
  ///
  /// In en, this message translates to:
  /// **'Enter CNIC'**
  String get enterCNIC;

  /// No description provided for @enterCNICFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter CNIC (e.g., 42101-1234567-1)'**
  String get enterCNICFormat;

  /// No description provided for @pleaseEnterCNIC.
  ///
  /// In en, this message translates to:
  /// **'Please enter a CNIC'**
  String get pleaseEnterCNIC;

  /// No description provided for @pleaseEnterValidCNIC.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid CNIC (XXXXX-XXXXXXX-X)'**
  String get pleaseEnterValidCNIC;

  /// No description provided for @enterMonthlySalaryInPKR.
  ///
  /// In en, this message translates to:
  /// **'Enter monthly salary in PKR'**
  String get enterMonthlySalaryInPKR;

  /// No description provided for @laborCanBeRestoredLater.
  ///
  /// In en, this message translates to:
  /// **'Employee can be restored later'**
  String get laborCanBeRestoredLater;

  /// No description provided for @laborID.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get laborID;

  /// No description provided for @iUnderstandActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'I understand this action cannot be undone and will affect related records'**
  String get iUnderstandActionCannotBeUndone;

  /// No description provided for @typeLaborNameToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type the employee name to confirm permanent deletion:'**
  String get typeLaborNameToConfirm;

  /// No description provided for @laborDeletedPermanently.
  ///
  /// In en, this message translates to:
  /// **'Employee deleted permanently!'**
  String get laborDeletedPermanently;

  /// No description provided for @failedToDeleteLabor.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete employee'**
  String get failedToDeleteLabor;

  /// No description provided for @pleaseConfirmYouUnderstandThisAction.
  ///
  /// In en, this message translates to:
  /// **'Please confirm that you understand this action'**
  String get pleaseConfirmYouUnderstandThisAction;

  /// No description provided for @pleaseConfirmYouUnderstandConsequences.
  ///
  /// In en, this message translates to:
  /// **'Please confirm that you understand the consequences of permanent deletion'**
  String get pleaseConfirmYouUnderstandConsequences;

  /// No description provided for @pleaseTypeLaborNameExactly.
  ///
  /// In en, this message translates to:
  /// **'Please type the employee name exactly to confirm permanent deletion'**
  String get pleaseTypeLaborNameExactly;

  /// No description provided for @pleaseCompleteAllConfirmationSteps.
  ///
  /// In en, this message translates to:
  /// **'Please complete all confirmation steps'**
  String get pleaseCompleteAllConfirmationSteps;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @pleaseTryAgainOrContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Please try again later or contact support.'**
  String get pleaseTryAgainOrContactSupport;

  /// No description provided for @failedToDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete category'**
  String get failedToDeleteCategory;

  /// No description provided for @categoryDeletedPermanently.
  ///
  /// In en, this message translates to:
  /// **'Category deleted permanently!'**
  String get categoryDeletedPermanently;

  /// No description provided for @categoryDeactivatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category deactivated successfully!'**
  String get categoryDeactivatedSuccessfully;

  /// No description provided for @deactivateCategory.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Category'**
  String get deactivateCategory;

  /// No description provided for @categoryCanBeRestoredLater.
  ///
  /// In en, this message translates to:
  /// **'Category can be restored later'**
  String get categoryCanBeRestoredLater;

  /// No description provided for @iUnderstandPermanentDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'I understand this will permanently delete the category and cannot be undone'**
  String get iUnderstandPermanentDeleteCategory;

  /// No description provided for @iUnderstandDeactivateCategory.
  ///
  /// In en, this message translates to:
  /// **'I understand this will deactivate the category'**
  String get iUnderstandDeactivateCategory;

  /// No description provided for @categoryUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category updated successfully!'**
  String get categoryUpdatedSuccessfully;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @updateCategoryInformation.
  ///
  /// In en, this message translates to:
  /// **'Update category information'**
  String get updateCategoryInformation;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @enterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Enter category name'**
  String get enterCategoryName;

  /// No description provided for @enterCategoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter category name (e.g., Bridal Dresses)'**
  String get enterCategoryNameHint;

  /// No description provided for @pleaseEnterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category name'**
  String get pleaseEnterCategoryName;

  /// No description provided for @categoryNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Category name must be at least 2 characters'**
  String get categoryNameMinLength;

  /// No description provided for @categoryNameMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Category name must be less than 50 characters'**
  String get categoryNameMaxLength;

  /// No description provided for @enterDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter description (optional)'**
  String get enterDescriptionOptional;

  /// No description provided for @enterCategoryDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter category description (optional)'**
  String get enterCategoryDescriptionOptional;

  /// No description provided for @descriptionMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Description must be less than 200 characters'**
  String get descriptionMaxLength;

  /// No description provided for @updateCategory.
  ///
  /// In en, this message translates to:
  /// **'Update Category'**
  String get updateCategory;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search products, orders, customers...'**
  String get searchPlaceholder;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @lastSixMonthsPerformance.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months performance'**
  String get lastSixMonthsPerformance;

  /// No description provided for @sixMonths.
  ///
  /// In en, this message translates to:
  /// **'6M'**
  String get sixMonths;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @activeProducts.
  ///
  /// In en, this message translates to:
  /// **'Active Products'**
  String get activeProducts;

  /// No description provided for @dailySales.
  ///
  /// In en, this message translates to:
  /// **'Daily Sales'**
  String get dailySales;

  /// No description provided for @monthlySales.
  ///
  /// In en, this message translates to:
  /// **'Monthly Sales'**
  String get monthlySales;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @addNewExpense.
  ///
  /// In en, this message translates to:
  /// **'Add New Expense'**
  String get addNewExpense;

  /// No description provided for @recordNewExpenseEntry.
  ///
  /// In en, this message translates to:
  /// **'Record a new expense entry'**
  String get recordNewExpenseEntry;

  /// No description provided for @enterExpense.
  ///
  /// In en, this message translates to:
  /// **'Enter expense'**
  String get enterExpense;

  /// No description provided for @enterExpenseTypeCategory.
  ///
  /// In en, this message translates to:
  /// **'Enter expense type/category'**
  String get enterExpenseTypeCategory;

  /// No description provided for @pleaseEnterExpenseType.
  ///
  /// In en, this message translates to:
  /// **'Please enter expense type'**
  String get pleaseEnterExpenseType;

  /// No description provided for @expenseMinLength.
  ///
  /// In en, this message translates to:
  /// **'Expense must be at least 2 characters'**
  String get expenseMinLength;

  /// No description provided for @enterExpenseDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter expense description/details'**
  String get enterExpenseDescription;

  /// No description provided for @descriptionMinLength.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 5 characters'**
  String get descriptionMinLength;

  /// No description provided for @enterAmountPKR.
  ///
  /// In en, this message translates to:
  /// **'Enter amount (PKR)'**
  String get enterAmountPKR;

  /// No description provided for @withdrawalBy.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal By'**
  String get withdrawalBy;

  /// No description provided for @selectWhoMadeWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Select who made the withdrawal'**
  String get selectWhoMadeWithdrawal;

  /// No description provided for @pleaseSelectWhoMadeWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Please select who made the withdrawal'**
  String get pleaseSelectWhoMadeWithdrawal;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateTime;

  /// No description provided for @selectExpenseDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Expense Date & Time'**
  String get selectExpenseDateTime;

  /// No description provided for @expenseAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Expense added successfully!'**
  String get expenseAddedSuccessfully;

  /// No description provided for @deleteExpense.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense'**
  String get deleteExpense;

  /// No description provided for @deleteExpenseRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Expense Record'**
  String get deleteExpenseRecord;

  /// No description provided for @confirmDeleteExpenseShort.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this expense record?'**
  String get confirmDeleteExpenseShort;

  /// No description provided for @confirmDeleteExpenseLong.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure you want to delete this expense record?'**
  String get confirmDeleteExpenseLong;

  /// No description provided for @deleteWarningShort.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the expense record.'**
  String get deleteWarningShort;

  /// No description provided for @deleteWarningLong.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the expense record and all associated data. This action cannot be undone.'**
  String get deleteWarningLong;

  /// No description provided for @expenseDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted successfully!'**
  String get expenseDeletedSuccessfully;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// No description provided for @editExpenseRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense Record'**
  String get editExpenseRecord;

  /// No description provided for @updateExpenseInformation.
  ///
  /// In en, this message translates to:
  /// **'Update expense information'**
  String get updateExpenseInformation;

  /// No description provided for @updateExpense.
  ///
  /// In en, this message translates to:
  /// **'Update Expense'**
  String get updateExpense;

  /// No description provided for @expenseUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Expense updated successfully!'**
  String get expenseUpdatedSuccessfully;

  /// No description provided for @pleaseAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'Please accept the terms and conditions'**
  String get pleaseAcceptTerms;

  /// No description provided for @accountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully! Welcome to Al Noor.'**
  String get accountCreatedSuccessfully;

  /// No description provided for @registrationFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please check the details below.'**
  String get registrationFailedMessage;

  /// No description provided for @joinOur.
  ///
  /// In en, this message translates to:
  /// **'Join Our'**
  String get joinOur;

  /// No description provided for @premiumFamily.
  ///
  /// In en, this message translates to:
  /// **'Premium Family'**
  String get premiumFamily;

  /// No description provided for @signupWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Begin your journey with us and discover the epitome of luxury fashion. \nCreate your account to access exclusive collections and personalized service.'**
  String get signupWelcomeMessage;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinExclusiveCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join our exclusive community'**
  String get joinExclusiveCommunity;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @pleaseEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get pleaseEnterFullName;

  /// No description provided for @nameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMinLength;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @createStrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password'**
  String get createStrongPassword;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @passwordMustContain.
  ///
  /// In en, this message translates to:
  /// **'Password must contain uppercase, lowercase, and number'**
  String get passwordMustContain;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @reenterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reenterPassword;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeToThe;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration Failed'**
  String get registrationFailed;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have account?'**
  String get alreadyHaveAccount;

  /// No description provided for @filterExpenseRecords.
  ///
  /// In en, this message translates to:
  /// **'Filter Expense Records'**
  String get filterExpenseRecords;

  /// No description provided for @refineExpenseList.
  ///
  /// In en, this message translates to:
  /// **'Refine your expense list with filters'**
  String get refineExpenseList;

  /// No description provided for @searchExpenseRecords.
  ///
  /// In en, this message translates to:
  /// **'Search Expense Records'**
  String get searchExpenseRecords;

  /// No description provided for @searchByExpenseHint.
  ///
  /// In en, this message translates to:
  /// **'Search by expense name, description, or amount'**
  String get searchByExpenseHint;

  /// No description provided for @expenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Expense Category'**
  String get expenseCategory;

  /// No description provided for @enterExpenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Enter expense category'**
  String get enterExpenseCategory;

  /// No description provided for @selectWithdrawalAuthority.
  ///
  /// In en, this message translates to:
  /// **'Select Withdrawal Authority'**
  String get selectWithdrawalAuthority;

  /// No description provided for @clearWithdrawalFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Withdrawal Filter'**
  String get clearWithdrawalFilter;

  /// No description provided for @expenseId.
  ///
  /// In en, this message translates to:
  /// **'Expense ID'**
  String get expenseId;

  /// No description provided for @noExpenseRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No Expense Records Found'**
  String get noExpenseRecordsFound;

  /// No description provided for @startAddingFirstExpense.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first expense record to track business spending'**
  String get startAddingFirstExpense;

  /// No description provided for @addFirstExpense.
  ///
  /// In en, this message translates to:
  /// **'Add First Expense'**
  String get addFirstExpense;

  /// No description provided for @errorLoadingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Error loading expenses'**
  String get errorLoadingExpenses;

  /// No description provided for @pleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later or check your internet connection.'**
  String get pleaseTryAgainLater;

  /// No description provided for @retryLoading.
  ///
  /// In en, this message translates to:
  /// **'Retry Loading'**
  String get retryLoading;

  /// No description provided for @expenseDetails.
  ///
  /// In en, this message translates to:
  /// **'Expense Details'**
  String get expenseDetails;

  /// No description provided for @viewCompleteExpenseInfo.
  ///
  /// In en, this message translates to:
  /// **'View complete expense information'**
  String get viewCompleteExpenseInfo;

  /// No description provided for @amountInformation.
  ///
  /// In en, this message translates to:
  /// **'Amount Information'**
  String get amountInformation;

  /// No description provided for @withdrawalInformation.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Information'**
  String get withdrawalInformation;

  /// No description provided for @expenseDescription.
  ///
  /// In en, this message translates to:
  /// **'Expense Description'**
  String get expenseDescription;

  /// No description provided for @recordCreated.
  ///
  /// In en, this message translates to:
  /// **'Record Created:'**
  String get recordCreated;

  /// No description provided for @expenseRecord.
  ///
  /// In en, this message translates to:
  /// **'Expense Record'**
  String get expenseRecord;

  /// No description provided for @hour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// No description provided for @minute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get minute;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @explorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get explorer;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @viewImage.
  ///
  /// In en, this message translates to:
  /// **'View Image'**
  String get viewImage;

  /// No description provided for @invalidImageFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid image file. Please select a valid image (max 10MB).'**
  String get invalidImageFile;

  /// No description provided for @receiptUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Receipt image uploaded successfully!'**
  String get receiptUploadedSuccessfully;

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get failedToUploadImage;

  /// No description provided for @receiptImageRemoved.
  ///
  /// In en, this message translates to:
  /// **'Receipt image removed'**
  String get receiptImageRemoved;

  /// No description provided for @failedToOpenImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to open image'**
  String get failedToOpenImage;

  /// No description provided for @failedToShowInExplorer.
  ///
  /// In en, this message translates to:
  /// **'Failed to show in explorer'**
  String get failedToShowInExplorer;

  /// No description provided for @imageCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Image copied to clipboard!'**
  String get imageCopiedToClipboard;

  /// No description provided for @failedToCopyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy to clipboard'**
  String get failedToCopyToClipboard;

  /// No description provided for @clickToSelectReceiptImage.
  ///
  /// In en, this message translates to:
  /// **'Click to select receipt image'**
  String get clickToSelectReceiptImage;

  /// No description provided for @supportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: JPG, PNG, BMP, GIF (max 10MB)'**
  String get supportedFormats;

  /// No description provided for @supportedFormatsShort.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG, BMP, GIF (max 10MB)'**
  String get supportedFormatsShort;

  /// No description provided for @browseFiles.
  ///
  /// In en, this message translates to:
  /// **'Browse Files'**
  String get browseFiles;

  /// No description provided for @processingImageFile.
  ///
  /// In en, this message translates to:
  /// **'Processing image file...'**
  String get processingImageFile;

  /// No description provided for @openingFileDialog.
  ///
  /// In en, this message translates to:
  /// **'Opening file dialog...'**
  String get openingFileDialog;

  /// No description provided for @validatingImageFile.
  ///
  /// In en, this message translates to:
  /// **'Validating image file...'**
  String get validatingImageFile;

  /// No description provided for @savingToAppDirectory.
  ///
  /// In en, this message translates to:
  /// **'Saving to application directory...'**
  String get savingToAppDirectory;

  /// No description provided for @finalizing.
  ///
  /// In en, this message translates to:
  /// **'Finalizing...'**
  String get finalizing;

  /// No description provided for @replaceImage.
  ///
  /// In en, this message translates to:
  /// **'Replace Image'**
  String get replaceImage;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @loadingFileInfo.
  ///
  /// In en, this message translates to:
  /// **'Loading file info...'**
  String get loadingFileInfo;

  /// No description provided for @receiptImageViewer.
  ///
  /// In en, this message translates to:
  /// **'Receipt Image Viewer'**
  String get receiptImageViewer;

  /// No description provided for @openInExternalViewer.
  ///
  /// In en, this message translates to:
  /// **'Open in External Viewer'**
  String get openInExternalViewer;

  /// No description provided for @showInExplorer.
  ///
  /// In en, this message translates to:
  /// **'Show in Explorer'**
  String get showInExplorer;

  /// No description provided for @copyToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to Clipboard'**
  String get copyToClipboard;

  /// No description provided for @failedToOpen.
  ///
  /// In en, this message translates to:
  /// **'Failed to open'**
  String get failedToOpen;

  /// No description provided for @failedToCopy.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy'**
  String get failedToCopy;

  /// No description provided for @loadingImage.
  ///
  /// In en, this message translates to:
  /// **'Loading image...'**
  String get loadingImage;

  /// No description provided for @failedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// No description provided for @openWithExternalViewer.
  ///
  /// In en, this message translates to:
  /// **'Open with External Viewer'**
  String get openWithExternalViewer;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get removeImage;

  /// No description provided for @viewFullScreen.
  ///
  /// In en, this message translates to:
  /// **'View Full Screen'**
  String get viewFullScreen;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @tapToChangeImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to change image'**
  String get tapToChangeImage;

  /// No description provided for @tapToAddImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to add image'**
  String get tapToAddImage;

  /// No description provided for @supports.
  ///
  /// In en, this message translates to:
  /// **'Supports'**
  String get supports;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @fileSizeMustBeLessThan.
  ///
  /// In en, this message translates to:
  /// **'File size must be less than'**
  String get fileSizeMustBeLessThan;

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image'**
  String get errorPickingImage;

  /// No description provided for @realTimeInventory.
  ///
  /// In en, this message translates to:
  /// **'Real-Time Inventory'**
  String get realTimeInventory;

  /// No description provided for @refreshInventory.
  ///
  /// In en, this message translates to:
  /// **'Refresh Inventory'**
  String get refreshInventory;

  /// No description provided for @noStockInformationAvailable.
  ///
  /// In en, this message translates to:
  /// **'No stock information available'**
  String get noStockInformationAvailable;

  /// No description provided for @stockInformation.
  ///
  /// In en, this message translates to:
  /// **'Stock Information'**
  String get stockInformation;

  /// No description provided for @unknownProduct.
  ///
  /// In en, this message translates to:
  /// **'Unknown Product'**
  String get unknownProduct;

  /// No description provided for @allProductsHaveSufficientStock.
  ///
  /// In en, this message translates to:
  /// **'All products have sufficient stock'**
  String get allProductsHaveSufficientStock;

  /// No description provided for @lowStockAlerts.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alerts'**
  String get lowStockAlerts;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL'**
  String get critical;

  /// No description provided for @currentStock.
  ///
  /// In en, this message translates to:
  /// **'Current Stock'**
  String get currentStock;

  /// No description provided for @refreshStock.
  ///
  /// In en, this message translates to:
  /// **'Refresh Stock'**
  String get refreshStock;

  /// No description provided for @viewAlerts.
  ///
  /// In en, this message translates to:
  /// **'View Alerts'**
  String get viewAlerts;

  /// No description provided for @noLowStockAlertsAtThisTime.
  ///
  /// In en, this message translates to:
  /// **'No low stock alerts at this time.'**
  String get noLowStockAlertsAtThisTime;

  /// No description provided for @addNewOrderItem.
  ///
  /// In en, this message translates to:
  /// **'Add New Order Item'**
  String get addNewOrderItem;

  /// No description provided for @productNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Product name is required'**
  String get productNameIsRequired;

  /// No description provided for @customizationNotes.
  ///
  /// In en, this message translates to:
  /// **'Customization Notes'**
  String get customizationNotes;

  /// No description provided for @quantityIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Quantity is required'**
  String get quantityIsRequired;

  /// No description provided for @unitPriceIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Unit price is required'**
  String get unitPriceIsRequired;

  /// No description provided for @addOrderItem.
  ///
  /// In en, this message translates to:
  /// **'Add Order Item'**
  String get addOrderItem;

  /// No description provided for @pleaseSelectAnOrder.
  ///
  /// In en, this message translates to:
  /// **'Please select an order'**
  String get pleaseSelectAnOrder;

  /// No description provided for @pleaseSelectAProduct.
  ///
  /// In en, this message translates to:
  /// **'Please select a product'**
  String get pleaseSelectAProduct;

  /// No description provided for @orderItemCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order item created successfully'**
  String get orderItemCreatedSuccessfully;

  /// No description provided for @failedToCreateOrderItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to create order item'**
  String get failedToCreateOrderItem;

  /// No description provided for @selectOrder.
  ///
  /// In en, this message translates to:
  /// **'Select Order'**
  String get selectOrder;

  /// No description provided for @typeCustomerNameToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type customer name to search...'**
  String get typeCustomerNameToSearch;

  /// No description provided for @searchByCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Search by customer name...'**
  String get searchByCustomerName;

  /// No description provided for @typeProductNameToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type product name to search...'**
  String get typeProductNameToSearch;

  /// No description provided for @searchByProductName.
  ///
  /// In en, this message translates to:
  /// **'Search by product name...'**
  String get searchByProductName;

  /// No description provided for @selectAnOrder.
  ///
  /// In en, this message translates to:
  /// **'Select an order...'**
  String get selectAnOrder;

  /// No description provided for @selectAProduct.
  ///
  /// In en, this message translates to:
  /// **'Select a product...'**
  String get selectAProduct;

  /// No description provided for @deleteOrderItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Order Item'**
  String get deleteOrderItem;

  /// No description provided for @removeThisOrderItemPermanently.
  ///
  /// In en, this message translates to:
  /// **'Remove this order item permanently'**
  String get removeThisOrderItemPermanently;

  /// No description provided for @orderItemDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order item deleted successfully!'**
  String get orderItemDeletedSuccessfully;

  /// No description provided for @failedToDeleteOrderItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete order item'**
  String get failedToDeleteOrderItem;

  /// No description provided for @irreversibleAction.
  ///
  /// In en, this message translates to:
  /// **'Irreversible Action'**
  String get irreversibleAction;

  /// No description provided for @deleteWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete the order item and cannot be undone. Please review the details below before proceeding.'**
  String get deleteWarningMessage;

  /// No description provided for @orderItemSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Item Summary'**
  String get orderItemSummary;

  /// No description provided for @productId.
  ///
  /// In en, this message translates to:
  /// **'Product ID'**
  String get productId;

  /// No description provided for @lineTotal.
  ///
  /// In en, this message translates to:
  /// **'Line Total'**
  String get lineTotal;

  /// No description provided for @impactAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Impact Analysis'**
  String get impactAnalysis;

  /// No description provided for @financialImpact.
  ///
  /// In en, this message translates to:
  /// **'Financial Impact'**
  String get financialImpact;

  /// No description provided for @willBeRemovedFromOrderTotal.
  ///
  /// In en, this message translates to:
  /// **'{amount} will be removed from order total'**
  String willBeRemovedFromOrderTotal(String amount);

  /// No description provided for @inventoryImpact.
  ///
  /// In en, this message translates to:
  /// **'Inventory Impact'**
  String get inventoryImpact;

  /// No description provided for @quantityWillBeAffected.
  ///
  /// In en, this message translates to:
  /// **'Quantity {quantity} will be affected'**
  String quantityWillBeAffected(int quantity);

  /// No description provided for @salesImpact.
  ///
  /// In en, this message translates to:
  /// **'Sales Impact'**
  String get salesImpact;

  /// No description provided for @itemHasBeenSoldWarning.
  ///
  /// In en, this message translates to:
  /// **'This item has been sold and deletion may affect sales records'**
  String get itemHasBeenSoldWarning;

  /// No description provided for @finalConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Final Confirmation'**
  String get finalConfirmation;

  /// No description provided for @areYouSureDeleteOrderItem.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure you want to delete this order item?'**
  String get areYouSureDeleteOrderItem;

  /// No description provided for @deleteOrderItemWarningPoints.
  ///
  /// In en, this message translates to:
  /// **'• This action cannot be undone\n• All associated data will be permanently removed\n• This may affect order totals and inventory\n• Consider archiving instead if you need to preserve records'**
  String get deleteOrderItemWarningPoints;

  /// No description provided for @editOrderItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Order Item'**
  String get editOrderItem;

  /// No description provided for @updateOrderItemInformation.
  ///
  /// In en, this message translates to:
  /// **'Update order item information'**
  String get updateOrderItemInformation;

  /// No description provided for @changingOrderNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Changing the order is not allowed. Please create a new order item instead.'**
  String get changingOrderNotAllowed;

  /// No description provided for @changingProductNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Changing the product is not allowed. Please create a new order item instead.'**
  String get changingProductNotAllowed;

  /// No description provided for @orderItemUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order item updated successfully!'**
  String get orderItemUpdatedSuccessfully;

  /// No description provided for @failedToUpdateOrderItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to update order item'**
  String get failedToUpdateOrderItem;

  /// No description provided for @productInformation.
  ///
  /// In en, this message translates to:
  /// **'Product Information'**
  String get productInformation;

  /// No description provided for @orderItemDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Item Details'**
  String get orderItemDetails;

  /// No description provided for @quantityMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be a positive number'**
  String get quantityMustBePositive;

  /// No description provided for @unitPricePKR.
  ///
  /// In en, this message translates to:
  /// **'Unit Price (PKR)'**
  String get unitPricePKR;

  /// No description provided for @enterUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter unit price'**
  String get enterUnitPrice;

  /// No description provided for @pleaseEnterUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter unit price'**
  String get pleaseEnterUnitPrice;

  /// No description provided for @unitPriceMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Unit price must be a positive number'**
  String get unitPriceMustBePositive;

  /// No description provided for @enterCustomizationNotes.
  ///
  /// In en, this message translates to:
  /// **'Enter any customization notes or special requirements'**
  String get enterCustomizationNotes;

  /// No description provided for @notesMustBeLessThan500.
  ///
  /// In en, this message translates to:
  /// **'Notes must be less than 500 characters'**
  String get notesMustBeLessThan500;

  /// No description provided for @updateOrderItem.
  ///
  /// In en, this message translates to:
  /// **'Update Order Item'**
  String get updateOrderItem;

  /// No description provided for @orderItemFilters.
  ///
  /// In en, this message translates to:
  /// **'Order Item Filters'**
  String get orderItemFilters;

  /// No description provided for @customizeOrderItemSearch.
  ///
  /// In en, this message translates to:
  /// **'Customize your order item search and filtering'**
  String get customizeOrderItemSearch;

  /// No description provided for @activeFilters.
  ///
  /// In en, this message translates to:
  /// **'Active Filters'**
  String get activeFilters;

  /// No description provided for @basicFilters.
  ///
  /// In en, this message translates to:
  /// **'Basic Filters'**
  String get basicFilters;

  /// No description provided for @allOrders.
  ///
  /// In en, this message translates to:
  /// **'All Orders'**
  String get allOrders;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get allProducts;

  /// No description provided for @searchAndTextFilters.
  ///
  /// In en, this message translates to:
  /// **'Search & Text Filters'**
  String get searchAndTextFilters;

  /// No description provided for @searchQuery.
  ///
  /// In en, this message translates to:
  /// **'Search Query'**
  String get searchQuery;

  /// No description provided for @searchInProductNames.
  ///
  /// In en, this message translates to:
  /// **'Search in product names, customization notes, or IDs'**
  String get searchInProductNames;

  /// No description provided for @numericRangeFilters.
  ///
  /// In en, this message translates to:
  /// **'Numeric Range Filters'**
  String get numericRangeFilters;

  /// No description provided for @minQuantity.
  ///
  /// In en, this message translates to:
  /// **'Min Quantity'**
  String get minQuantity;

  /// No description provided for @minimumQuantity.
  ///
  /// In en, this message translates to:
  /// **'Minimum quantity'**
  String get minimumQuantity;

  /// No description provided for @maxQuantity.
  ///
  /// In en, this message translates to:
  /// **'Max Quantity'**
  String maxQuantity(int max);

  /// No description provided for @maximumQuantity.
  ///
  /// In en, this message translates to:
  /// **'Maximum quantity'**
  String get maximumQuantity;

  /// No description provided for @minPricePKR.
  ///
  /// In en, this message translates to:
  /// **'Min Price (PKR)'**
  String get minPricePKR;

  /// No description provided for @minimumUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Minimum unit price'**
  String get minimumUnitPrice;

  /// No description provided for @maxPricePKR.
  ///
  /// In en, this message translates to:
  /// **'Max Price (PKR)'**
  String get maxPricePKR;

  /// No description provided for @maximumUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Maximum unit price'**
  String get maximumUnitPrice;

  /// No description provided for @dateAndStatusFilters.
  ///
  /// In en, this message translates to:
  /// **'Date & Status Filters'**
  String get dateAndStatusFilters;

  /// No description provided for @dateFrom.
  ///
  /// In en, this message translates to:
  /// **'Date From'**
  String get dateFrom;

  /// No description provided for @dateTo.
  ///
  /// In en, this message translates to:
  /// **'Date To'**
  String get dateTo;

  /// No description provided for @showInactiveItems.
  ///
  /// In en, this message translates to:
  /// **'Show Inactive Items'**
  String get showInactiveItems;

  /// No description provided for @hasCustomizationNotes.
  ///
  /// In en, this message translates to:
  /// **'Has Customization Notes'**
  String get hasCustomizationNotes;

  /// No description provided for @sortingOptions.
  ///
  /// In en, this message translates to:
  /// **'Sorting Options'**
  String get sortingOptions;

  /// No description provided for @updatedDate.
  ///
  /// In en, this message translates to:
  /// **'Updated Date'**
  String get updatedDate;

  /// No description provided for @areYouSureYouWantTo.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to'**
  String get areYouSureYouWantTo;

  /// No description provided for @areYouSureYouWantToCreateACopyOf.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to create a copy of'**
  String get areYouSureYouWantToCreateACopyOf;

  /// No description provided for @failedToUpdateItemStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update item status'**
  String get failedToUpdateItemStatus;

  /// No description provided for @activatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'activated successfully'**
  String get activatedSuccessfully;

  /// No description provided for @failedToDuplicateItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to duplicate item'**
  String get failedToDuplicateItem;

  /// No description provided for @orderItemDuplicatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order item duplicated successfully'**
  String get orderItemDuplicatedSuccessfully;

  /// No description provided for @orderItemDetailsExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order item details exported successfully'**
  String get orderItemDetailsExportedSuccessfully;

  /// No description provided for @failedToExport.
  ///
  /// In en, this message translates to:
  /// **'Failed to export'**
  String get failedToExport;

  /// No description provided for @failedToLoadOrderItems.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Order Items'**
  String get failedToLoadOrderItems;

  /// No description provided for @startManagingYourOrderItems.
  ///
  /// In en, this message translates to:
  /// **'Start managing your order items by adding products to track inventory, pricing, and customizations for customer orders.'**
  String get startManagingYourOrderItems;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @orderItem.
  ///
  /// In en, this message translates to:
  /// **'Order Item'**
  String get orderItem;

  /// No description provided for @viewOrderItem.
  ///
  /// In en, this message translates to:
  /// **'View Order Item'**
  String get viewOrderItem;

  /// No description provided for @completeOrderItemInformation.
  ///
  /// In en, this message translates to:
  /// **'Complete order item information'**
  String get completeOrderItemInformation;

  /// No description provided for @orderItemId.
  ///
  /// In en, this message translates to:
  /// **'Order Item ID'**
  String get orderItemId;

  /// No description provided for @productInfo.
  ///
  /// In en, this message translates to:
  /// **'Product Info'**
  String get productInfo;

  /// No description provided for @noAdditionalProductDetailsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No additional product details available'**
  String get noAdditionalProductDetailsAvailable;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active Status'**
  String get activeStatus;

  /// No description provided for @soldStatus.
  ///
  /// In en, this message translates to:
  /// **'Sold Status'**
  String get soldStatus;

  /// No description provided for @remainingToSell.
  ///
  /// In en, this message translates to:
  /// **'Remaining to Sell'**
  String get remainingToSell;

  /// No description provided for @timestamps.
  ///
  /// In en, this message translates to:
  /// **'Timestamps'**
  String get timestamps;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// No description provided for @noCustomizationNotesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No customization notes available'**
  String get noCustomizationNotesAvailable;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @material.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get material;

  /// No description provided for @style.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get style;

  /// No description provided for @noAdditionalDetails.
  ///
  /// In en, this message translates to:
  /// **'No additional details'**
  String get noAdditionalDetails;

  /// No description provided for @additionalProductInformationAvailable.
  ///
  /// In en, this message translates to:
  /// **'Additional product information available'**
  String get additionalProductInformationAvailable;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'added to cart'**
  String get addedToCart;

  /// No description provided for @stockAvailable.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String stockAvailable(int quantity);

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @customPrice.
  ///
  /// In en, this message translates to:
  /// **'Custom Price'**
  String get customPrice;

  /// No description provided for @customPricePkr.
  ///
  /// In en, this message translates to:
  /// **'Custom Price (PKR)'**
  String get customPricePkr;

  /// No description provided for @itemDiscountOptional.
  ///
  /// In en, this message translates to:
  /// **'Item Discount (Optional)'**
  String get itemDiscountOptional;

  /// No description provided for @clearDiscount.
  ///
  /// In en, this message translates to:
  /// **'Clear Discount'**
  String clearDiscount(String amount);

  /// No description provided for @specialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special Instructions'**
  String get specialInstructions;

  /// No description provided for @anySpecialRequirements.
  ///
  /// In en, this message translates to:
  /// **'Any special requirements, alterations, or notes...'**
  String get anySpecialRequirements;

  /// No description provided for @checkoutAndPayment.
  ///
  /// In en, this message translates to:
  /// **'Checkout & Payment'**
  String get checkoutAndPayment;

  /// No description provided for @completeTheSaleTransaction.
  ///
  /// In en, this message translates to:
  /// **'Complete the sale transaction'**
  String get completeTheSaleTransaction;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @credit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get credit;

  /// No description provided for @split.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// No description provided for @splitPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Split Payment Details'**
  String get splitPaymentDetails;

  /// No description provided for @cashAmount.
  ///
  /// In en, this message translates to:
  /// **'Cash Amount'**
  String get cashAmount;

  /// No description provided for @cardAmount.
  ///
  /// In en, this message translates to:
  /// **'Card Amount'**
  String get cardAmount;

  /// No description provided for @bankTransferAmount.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer Amount'**
  String get bankTransferAmount;

  /// No description provided for @pleaseEnterAmountPaid.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount paid'**
  String get pleaseEnterAmountPaid;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @hideAdvancedOptions.
  ///
  /// In en, this message translates to:
  /// **'Hide Advanced Options'**
  String get hideAdvancedOptions;

  /// No description provided for @showAdvancedOptions.
  ///
  /// In en, this message translates to:
  /// **'Show Advanced Options'**
  String get showAdvancedOptions;

  /// No description provided for @advancedOptions.
  ///
  /// In en, this message translates to:
  /// **'Advanced Options'**
  String get advancedOptions;

  /// No description provided for @overallDiscountPkr.
  ///
  /// In en, this message translates to:
  /// **'Overall Discount (PKR)'**
  String get overallDiscountPkr;

  /// No description provided for @gstPercentage.
  ///
  /// In en, this message translates to:
  /// **'GST Percentage (%)'**
  String get gstPercentage;

  /// No description provided for @additionalTax.
  ///
  /// In en, this message translates to:
  /// **'Additional Tax (%)'**
  String get additionalTax;

  /// No description provided for @anySpecialInstructionsOrRemarks.
  ///
  /// In en, this message translates to:
  /// **'Any special instructions or remarks...'**
  String get anySpecialInstructionsOrRemarks;

  /// No description provided for @completeSale.
  ///
  /// In en, this message translates to:
  /// **'Complete Sale'**
  String get completeSale;

  /// No description provided for @saleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sale Completed!'**
  String get saleCompleted;

  /// No description provided for @transactionProcessedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Transaction processed successfully'**
  String get transactionProcessedSuccessfully;

  /// No description provided for @invoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice Number'**
  String get invoiceNumber;

  /// No description provided for @printFunctionalityToBeImplemented.
  ///
  /// In en, this message translates to:
  /// **'Print functionality to be implemented'**
  String get printFunctionalityToBeImplemented;

  /// No description provided for @printReceipt.
  ///
  /// In en, this message translates to:
  /// **'Print Receipt'**
  String get printReceipt;

  /// No description provided for @newSale.
  ///
  /// In en, this message translates to:
  /// **'New Sale'**
  String get newSale;

  /// No description provided for @navigateToSalesManagementToContinue.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Sales Management to continue'**
  String get navigateToSalesManagementToContinue;

  /// No description provided for @createNewInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create New Invoice'**
  String get createNewInvoice;

  /// No description provided for @selectSaleRequired.
  ///
  /// In en, this message translates to:
  /// **'Select Sale *'**
  String get selectSaleRequired;

  /// No description provided for @chooseASaleToCreateInvoiceFor.
  ///
  /// In en, this message translates to:
  /// **'Choose a sale to create invoice for'**
  String get chooseASaleToCreateInvoiceFor;

  /// No description provided for @pleaseSelectASale.
  ///
  /// In en, this message translates to:
  /// **'Please select a sale'**
  String get pleaseSelectASale;

  /// No description provided for @dueDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Due Date *'**
  String get dueDateRequired;

  /// No description provided for @selectDueDate.
  ///
  /// In en, this message translates to:
  /// **'Select due date'**
  String get selectDueDate;

  /// No description provided for @additionalInvoiceNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional invoice notes (optional)'**
  String get additionalInvoiceNotesOptional;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @invoiceTermsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Invoice terms and conditions'**
  String get invoiceTermsAndConditions;

  /// No description provided for @standardTermsAndConditionsApply.
  ///
  /// In en, this message translates to:
  /// **'Standard terms and conditions apply'**
  String get standardTermsAndConditionsApply;

  /// No description provided for @createInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createInvoice;

  /// No description provided for @invoiceCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invoice created successfully'**
  String get invoiceCreatedSuccessfully;

  /// No description provided for @failedToCreateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Failed to create invoice'**
  String get failedToCreateInvoice;

  /// No description provided for @receiptManagement.
  ///
  /// In en, this message translates to:
  /// **'Receipt Management'**
  String get receiptManagement;

  /// No description provided for @pleaseSelectALabor.
  ///
  /// In en, this message translates to:
  /// **'Please select an employee'**
  String get pleaseSelectALabor;

  /// No description provided for @amountCannotExceedRemainingAdvanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot exceed remaining advance amount of'**
  String get amountCannotExceedRemainingAdvanceAmount;

  /// No description provided for @failedToAddAdvancePayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to add advance payment'**
  String get failedToAddAdvancePayment;

  /// No description provided for @advancePaymentAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Advance payment added successfully'**
  String get advancePaymentAddedSuccessfully;

  /// No description provided for @selectDateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateAndTime;

  /// No description provided for @uploadReceiptImageForBetterRecordKeeping.
  ///
  /// In en, this message translates to:
  /// **'Upload receipt image for better record keeping'**
  String get uploadReceiptImageForBetterRecordKeeping;

  /// No description provided for @selectALabor.
  ///
  /// In en, this message translates to:
  /// **'Select an employee'**
  String get selectALabor;

  /// No description provided for @advanceAmountPkr.
  ///
  /// In en, this message translates to:
  /// **'Advance Amount (PKR)'**
  String get advanceAmountPkr;

  /// No description provided for @enterAdvanceAmountPkr.
  ///
  /// In en, this message translates to:
  /// **'Enter advance amount (PKR)'**
  String get enterAdvanceAmountPkr;

  /// No description provided for @pleaseEnterAdvanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter advance amount'**
  String get pleaseEnterAdvanceAmount;

  /// No description provided for @amountExceedsRemainingSalary.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds remaining monthly salary'**
  String get amountExceedsRemainingSalary;

  /// No description provided for @enterReasonForAdvancePayment.
  ///
  /// In en, this message translates to:
  /// **'Enter reason for advance payment'**
  String get enterReasonForAdvancePayment;

  /// No description provided for @salaryCalculation.
  ///
  /// In en, this message translates to:
  /// **'Salary Calculation'**
  String get salaryCalculation;

  /// No description provided for @originalSalary.
  ///
  /// In en, this message translates to:
  /// **'Original Salary'**
  String get originalSalary;

  /// No description provided for @currentMonthAdvances.
  ///
  /// In en, this message translates to:
  /// **'Current Month Advances'**
  String get currentMonthAdvances;

  /// No description provided for @remainingForMonth.
  ///
  /// In en, this message translates to:
  /// **'Remaining for Month'**
  String get remainingForMonth;

  /// No description provided for @newAdvance.
  ///
  /// In en, this message translates to:
  /// **'New Advance'**
  String get newAdvance;

  /// No description provided for @afterAdvance.
  ///
  /// In en, this message translates to:
  /// **'After Advance'**
  String get afterAdvance;

  /// No description provided for @filterAdvancePayments.
  ///
  /// In en, this message translates to:
  /// **'Filter Advance Payments'**
  String get filterAdvancePayments;

  /// No description provided for @applyFiltersToFindSpecificAdvancePayments.
  ///
  /// In en, this message translates to:
  /// **'Apply filters to find specific advance payments'**
  String get applyFiltersToFindSpecificAdvancePayments;

  /// No description provided for @searchAdvancePayments.
  ///
  /// In en, this message translates to:
  /// **'Search advance payments...'**
  String get searchAdvancePayments;

  /// No description provided for @allLaborers.
  ///
  /// In en, this message translates to:
  /// **'All Employeeers'**
  String get allLaborers;

  /// No description provided for @receiptAndSorting.
  ///
  /// In en, this message translates to:
  /// **'Receipt & Sorting'**
  String get receiptAndSorting;

  /// No description provided for @showInactiveRecords.
  ///
  /// In en, this message translates to:
  /// **'Show Inactive Records'**
  String get showInactiveRecords;

  /// No description provided for @showingAdvancePayments.
  ///
  /// In en, this message translates to:
  /// **'Showing {start}-{end} of {total} advance payments'**
  String showingAdvancePayments(Object end, Object start, Object total);

  /// No description provided for @failedToLoadAdvancePayments.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Advance Payments'**
  String get failedToLoadAdvancePayments;

  /// No description provided for @noAdvancePaymentRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No Advance Payment Records Found'**
  String get noAdvancePaymentRecordsFound;

  /// No description provided for @startByAddingYourFirstAdvancePaymentRecord.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first advance payment record to track employee payments effectively'**
  String get startByAddingYourFirstAdvancePaymentRecord;

  /// No description provided for @addFirstAdvancePayment.
  ///
  /// In en, this message translates to:
  /// **'Add First Advance Payment'**
  String get addFirstAdvancePayment;

  /// No description provided for @highAmount.
  ///
  /// In en, this message translates to:
  /// **'High Amount'**
  String get highAmount;

  /// No description provided for @failedToDeleteAdvancePayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete advance payment'**
  String get failedToDeleteAdvancePayment;

  /// No description provided for @advancePaymentDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Advance payment deleted successfully!'**
  String get advancePaymentDeletedSuccessfully;

  /// No description provided for @deleteAdvancePayment.
  ///
  /// In en, this message translates to:
  /// **'Delete Advance Payment'**
  String get deleteAdvancePayment;

  /// No description provided for @areYouSureDeleteThisPayment.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this payment?'**
  String get areYouSureDeleteThisPayment;

  /// No description provided for @areYouAbsolutelySureDeleteAdvancePayment.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure you want to delete this advance payment record?'**
  String get areYouAbsolutelySureDeleteAdvancePayment;

  /// No description provided for @thisWillPermanentlyDeleteThePaymentRecord.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the payment record.'**
  String get thisWillPermanentlyDeleteThePaymentRecord;

  /// No description provided for @thisWillPermanentlyDeleteAdvancePaymentRecord.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the advance payment record and all associated data. This action cannot be undone.'**
  String get thisWillPermanentlyDeleteAdvancePaymentRecord;

  /// No description provided for @amountIncreaseCannotExceedRemainingAdvanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount increase cannot exceed remaining advance amount of'**
  String get amountIncreaseCannotExceedRemainingAdvanceAmount;

  /// No description provided for @advancePaymentUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Advance payment updated successfully!'**
  String get advancePaymentUpdatedSuccessfully;

  /// No description provided for @editAdvancePayment.
  ///
  /// In en, this message translates to:
  /// **'Edit Advance Payment'**
  String get editAdvancePayment;

  /// No description provided for @laborInformation.
  ///
  /// In en, this message translates to:
  /// **'Employee Information'**
  String get laborInformation;

  /// No description provided for @advancePaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Advance Payment Details'**
  String get advancePaymentDetails;

  /// No description provided for @viewCompletePaymentInformation.
  ///
  /// In en, this message translates to:
  /// **'View complete payment information'**
  String get viewCompletePaymentInformation;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @advanceAmount.
  ///
  /// In en, this message translates to:
  /// **'Advance Amount'**
  String get advanceAmount;

  /// No description provided for @paymentDescription.
  ///
  /// In en, this message translates to:
  /// **'Payment Description'**
  String get paymentDescription;

  /// No description provided for @receiptInformation.
  ///
  /// In en, this message translates to:
  /// **'Receipt Information'**
  String get receiptInformation;

  /// No description provided for @receiptImageAvailable.
  ///
  /// In en, this message translates to:
  /// **'Receipt image available'**
  String get receiptImageAvailable;

  /// No description provided for @salaryInformation.
  ///
  /// In en, this message translates to:
  /// **'Salary Information'**
  String get salaryInformation;

  /// No description provided for @totalSalary.
  ///
  /// In en, this message translates to:
  /// **'Total Salary'**
  String get totalSalary;

  /// No description provided for @viewReceiptDetailsAndImage.
  ///
  /// In en, this message translates to:
  /// **'View receipt details and image'**
  String get viewReceiptDetailsAndImage;

  /// No description provided for @recurringExpense.
  ///
  /// In en, this message translates to:
  /// **'Recurring Expense'**
  String get recurringExpense;

  /// No description provided for @deductFromSalary.
  ///
  /// In en, this message translates to:
  /// **'Deduct from Salary'**
  String get deductFromSalary;

  /// No description provided for @selectEmployeeForDeduction.
  ///
  /// In en, this message translates to:
  /// **'Select employee for deduction'**
  String get selectEmployeeForDeduction;

  /// No description provided for @ofSalary.
  ///
  /// In en, this message translates to:
  /// **'of salary'**
  String get ofSalary;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get used;

  /// No description provided for @receiptImagePreview.
  ///
  /// In en, this message translates to:
  /// **'Receipt Image Preview'**
  String get receiptImagePreview;

  /// No description provided for @receiptUploadFunctionalityToBeImplemented.
  ///
  /// In en, this message translates to:
  /// **'Receipt upload functionality to be implemented'**
  String get receiptUploadFunctionalityToBeImplemented;

  /// No description provided for @areYouSureLogoutFromYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from your account?'**
  String get areYouSureLogoutFromYourAccount;

  /// No description provided for @forgotPasswordComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Forgot password feature coming soon!'**
  String get forgotPasswordComingSoon;

  /// No description provided for @successfullyLoggedOutSeeSoon.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged out. See you soon!'**
  String get successfullyLoggedOutSeeSoon;

  /// No description provided for @loggedOutLocallyDueToError.
  ///
  /// In en, this message translates to:
  /// **'Logged out locally due to an error.'**
  String get loggedOutLocallyDueToError;

  /// No description provided for @createNewReceipt.
  ///
  /// In en, this message translates to:
  /// **'Create New Receipt'**
  String get createNewReceipt;

  /// No description provided for @chooseASaleToCreateReceiptFor.
  ///
  /// In en, this message translates to:
  /// **'Choose a sale to create receipt for'**
  String get chooseASaleToCreateReceiptFor;

  /// No description provided for @additionalReceiptNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional receipt notes (optional)'**
  String get additionalReceiptNotesOptional;

  /// No description provided for @failedToCreateReceipt.
  ///
  /// In en, this message translates to:
  /// **'Failed to create receipt'**
  String get failedToCreateReceipt;

  /// No description provided for @addPrincipalAccountEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Principal Account Entry'**
  String get addPrincipalAccountEntry;

  /// No description provided for @recordANewLedgerTransaction.
  ///
  /// In en, this message translates to:
  /// **'Record a new ledger transaction'**
  String get recordANewLedgerTransaction;

  /// No description provided for @sourceModule.
  ///
  /// In en, this message translates to:
  /// **'Source Module'**
  String get sourceModule;

  /// No description provided for @pleaseSelectSourceModule.
  ///
  /// In en, this message translates to:
  /// **'Please select source module'**
  String get pleaseSelectSourceModule;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get transactionType;

  /// No description provided for @pleaseSelectTransactionType.
  ///
  /// In en, this message translates to:
  /// **'Please select transaction type'**
  String get pleaseSelectTransactionType;

  /// No description provided for @creditMoneyIn.
  ///
  /// In en, this message translates to:
  /// **'Credit (Money In)'**
  String get creditMoneyIn;

  /// No description provided for @debitMoneyOut.
  ///
  /// In en, this message translates to:
  /// **'Debit (Money Out)'**
  String get debitMoneyOut;

  /// No description provided for @sourceID.
  ///
  /// In en, this message translates to:
  /// **'Source ID'**
  String get sourceID;

  /// No description provided for @referenceIDOptional.
  ///
  /// In en, this message translates to:
  /// **'Reference ID (optional)'**
  String get referenceIDOptional;

  /// No description provided for @referenceIDFromSourceModuleOptional.
  ///
  /// In en, this message translates to:
  /// **'Reference ID from source module (optional)'**
  String get referenceIDFromSourceModuleOptional;

  /// No description provided for @enterTransactionDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter transaction description'**
  String get enterTransactionDescription;

  /// No description provided for @enterTransactionAmountPKR.
  ///
  /// In en, this message translates to:
  /// **'Enter transaction amount (PKR)'**
  String get enterTransactionAmountPKR;

  /// No description provided for @handledByOptional.
  ///
  /// In en, this message translates to:
  /// **'Handled By (Optional)'**
  String get handledByOptional;

  /// No description provided for @selectTransactionDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Transaction Date & Time'**
  String get selectTransactionDateTime;

  /// No description provided for @additionalNotesOrDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional notes or details (optional)'**
  String get additionalNotesOrDetailsOptional;

  /// No description provided for @principalAccountEntryAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Principal account entry added successfully!'**
  String get principalAccountEntryAddedSuccessfully;

  /// No description provided for @principalAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Principal Account Details'**
  String get principalAccountDetails;

  /// No description provided for @viewCompleteTransactionInformation.
  ///
  /// In en, this message translates to:
  /// **'View complete transaction information'**
  String get viewCompleteTransactionInformation;

  /// No description provided for @sourceModuleInformation.
  ///
  /// In en, this message translates to:
  /// **'Source Module Information'**
  String get sourceModuleInformation;

  /// No description provided for @module.
  ///
  /// In en, this message translates to:
  /// **'Module'**
  String get module;

  /// No description provided for @balanceInformation.
  ///
  /// In en, this message translates to:
  /// **'Balance Information'**
  String get balanceInformation;

  /// No description provided for @balanceAfterTransaction.
  ///
  /// In en, this message translates to:
  /// **'Balance After Transaction'**
  String get balanceAfterTransaction;

  /// No description provided for @handlerInformation.
  ///
  /// In en, this message translates to:
  /// **'Handler Information'**
  String get handlerInformation;

  /// No description provided for @transactionDescription.
  ///
  /// In en, this message translates to:
  /// **'Transaction Description'**
  String get transactionDescription;

  /// No description provided for @ledgerEntry.
  ///
  /// In en, this message translates to:
  /// **'Ledger Entry'**
  String get ledgerEntry;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @entryID.
  ///
  /// In en, this message translates to:
  /// **'Entry ID'**
  String get entryID;

  /// No description provided for @balanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance After'**
  String get balanceAfter;

  /// No description provided for @handledBy.
  ///
  /// In en, this message translates to:
  /// **'Handled By'**
  String get handledBy;

  /// No description provided for @exportAccountEntry.
  ///
  /// In en, this message translates to:
  /// **'Export account entry'**
  String get exportAccountEntry;

  /// No description provided for @noPrincipalAccountRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No Principal Account Records Found'**
  String get noPrincipalAccountRecordsFound;

  /// No description provided for @startByAddingYourFirstPrincipalAccountEntry.
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first principal account entry to track all cash movements'**
  String get startByAddingYourFirstPrincipalAccountEntry;

  /// No description provided for @addFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Add First Entry'**
  String get addFirstEntry;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// No description provided for @editPrincipalAccountEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Principal Account Entry'**
  String get editPrincipalAccountEntry;

  /// No description provided for @updateTransactionInformation.
  ///
  /// In en, this message translates to:
  /// **'Update transaction information'**
  String get updateTransactionInformation;

  /// No description provided for @updateEntry.
  ///
  /// In en, this message translates to:
  /// **'Update Entry'**
  String get updateEntry;

  /// No description provided for @principalAccountEntryUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Principal account entry updated successfully!'**
  String get principalAccountEntryUpdatedSuccessfully;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get deleteEntry;

  /// No description provided for @deletePrincipalAccountEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete Principal Account Entry'**
  String get deletePrincipalAccountEntry;

  /// No description provided for @areYouSureYouWantToDeleteThisEntry.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this principal account entry?'**
  String get areYouSureYouWantToDeleteThisEntry;

  /// No description provided for @areYouAbsolutelySureYouWantToDeleteThisEntry.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure you want to delete this principal account entry?'**
  String get areYouAbsolutelySureYouWantToDeleteThisEntry;

  /// No description provided for @thisWillPermanentlyDeleteTheEntry.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the principal account entry and affect balance calculations.'**
  String get thisWillPermanentlyDeleteTheEntry;

  /// No description provided for @thisWillPermanentlyDeleteTheEntryFull.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the principal account entry and may affect balance calculations. This action cannot be undone.'**
  String get thisWillPermanentlyDeleteTheEntryFull;

  /// No description provided for @principalAccountEntryDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Principal account entry deleted successfully!'**
  String get principalAccountEntryDeletedSuccessfully;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @enableDarkThemeForApplication.
  ///
  /// In en, this message translates to:
  /// **'Enable dark theme for the application'**
  String get enableDarkThemeForApplication;

  /// No description provided for @alNoorFashionPOS.
  ///
  /// In en, this message translates to:
  /// **'Al Noor POS'**
  String get alNoorFashionPOS;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @aPremiumPointOfSaleSolution.
  ///
  /// In en, this message translates to:
  /// **'A premium point of sale solution designed for fashion retail businesses. Manage your inventory, customers, and sales with elegance.'**
  String get aPremiumPointOfSaleSolution;

  /// No description provided for @createNewReturn.
  ///
  /// In en, this message translates to:
  /// **'Create New Return'**
  String get createNewReturn;

  /// No description provided for @enterSaleId.
  ///
  /// In en, this message translates to:
  /// **'Enter sale ID'**
  String get enterSaleId;

  /// No description provided for @saleIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Sale ID is required'**
  String get saleIdRequired;

  /// No description provided for @customerId.
  ///
  /// In en, this message translates to:
  /// **'Customer ID'**
  String get customerId;

  /// No description provided for @enterCustomerId.
  ///
  /// In en, this message translates to:
  /// **'Enter customer ID'**
  String get enterCustomerId;

  /// No description provided for @customerIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer ID is required'**
  String get customerIdRequired;

  /// No description provided for @returnReason.
  ///
  /// In en, this message translates to:
  /// **'Return Reason'**
  String get returnReason;

  /// No description provided for @selectReason.
  ///
  /// In en, this message translates to:
  /// **'Select a reason'**
  String get selectReason;

  /// No description provided for @reasonDefective.
  ///
  /// In en, this message translates to:
  /// **'Defective Product'**
  String get reasonDefective;

  /// No description provided for @reasonWrongSize.
  ///
  /// In en, this message translates to:
  /// **'Wrong Size'**
  String get reasonWrongSize;

  /// No description provided for @reasonWrongColor.
  ///
  /// In en, this message translates to:
  /// **'Wrong Color'**
  String get reasonWrongColor;

  /// No description provided for @reasonQualityIssue.
  ///
  /// In en, this message translates to:
  /// **'Quality Issue'**
  String get reasonQualityIssue;

  /// No description provided for @reasonChangeMind.
  ///
  /// In en, this message translates to:
  /// **'Customer Changed Mind'**
  String get reasonChangeMind;

  /// No description provided for @reasonDamagedTransit.
  ///
  /// In en, this message translates to:
  /// **'Damaged in Transit'**
  String get reasonDamagedTransit;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @selectReturnReason.
  ///
  /// In en, this message translates to:
  /// **'Please select a return reason'**
  String get selectReturnReason;

  /// No description provided for @reasonDetails.
  ///
  /// In en, this message translates to:
  /// **'Reason Details'**
  String get reasonDetails;

  /// No description provided for @specifyReason.
  ///
  /// In en, this message translates to:
  /// **'Please specify the reason'**
  String get specifyReason;

  /// No description provided for @provideReasonDetails.
  ///
  /// In en, this message translates to:
  /// **'Please provide reason details'**
  String get provideReasonDetails;

  /// No description provided for @returnItems.
  ///
  /// In en, this message translates to:
  /// **'Return Items'**
  String get returnItems;

  /// No description provided for @noItemsAdded.
  ///
  /// In en, this message translates to:
  /// **'No return items added'**
  String get noItemsAdded;

  /// No description provided for @clickAddItem.
  ///
  /// In en, this message translates to:
  /// **'Click \"Add Item\" to add items to return'**
  String get clickAddItem;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove Item'**
  String get removeItem;

  /// No description provided for @saleItemId.
  ///
  /// In en, this message translates to:
  /// **'Sale Item ID'**
  String get saleItemId;

  /// No description provided for @enterSaleItemId.
  ///
  /// In en, this message translates to:
  /// **'Enter sale item ID'**
  String get enterSaleItemId;

  /// No description provided for @saleItemIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Sale item ID is required'**
  String get saleItemIdRequired;

  /// No description provided for @quantityRequired.
  ///
  /// In en, this message translates to:
  /// **'Quantity is required'**
  String get quantityRequired;

  /// No description provided for @quantityPositive.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be a positive number'**
  String get quantityPositive;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @selectCondition.
  ///
  /// In en, this message translates to:
  /// **'Select condition'**
  String get selectCondition;

  /// No description provided for @conditionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get conditionNew;

  /// No description provided for @conditionGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get conditionGood;

  /// No description provided for @conditionFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get conditionFair;

  /// No description provided for @conditionPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get conditionPoor;

  /// No description provided for @conditionDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get conditionDamaged;

  /// No description provided for @selectConditionError.
  ///
  /// In en, this message translates to:
  /// **'Please select condition'**
  String get selectConditionError;

  /// No description provided for @conditionNotes.
  ///
  /// In en, this message translates to:
  /// **'Condition Notes'**
  String get conditionNotes;

  /// No description provided for @conditionNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Additional notes about condition'**
  String get conditionNotesHint;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional notes about the return'**
  String get notesHint;

  /// No description provided for @createReturn.
  ///
  /// In en, this message translates to:
  /// **'Create Return'**
  String get createReturn;

  /// No description provided for @addOneItem.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one return item'**
  String get addOneItem;

  /// No description provided for @createdSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Return created successfully'**
  String get createdSuccessfully;

  /// No description provided for @failedToCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create return'**
  String get failedToCreate;

  /// No description provided for @errorCreating.
  ///
  /// In en, this message translates to:
  /// **'Error creating return: {error}'**
  String errorCreating(String error);

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get blue;

  /// No description provided for @green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get green;

  /// No description provided for @purple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get purple;

  /// No description provided for @pink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get pink;

  /// No description provided for @orange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get orange;

  /// No description provided for @customizeAndAdd.
  ///
  /// In en, this message translates to:
  /// **'Customize & Add'**
  String get customizeAndAdd;

  /// No description provided for @customizedAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'Customized {productName} added to cart'**
  String customizedAddedToCart(String productName);

  /// No description provided for @quantityAndPricing.
  ///
  /// In en, this message translates to:
  /// **'Quantity & Pricing'**
  String get quantityAndPricing;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get enterValidPrice;

  /// No description provided for @sizeAndFitting.
  ///
  /// In en, this message translates to:
  /// **'Size & Fitting'**
  String get sizeAndFitting;

  /// No description provided for @fitting.
  ///
  /// In en, this message translates to:
  /// **'Fitting'**
  String get fitting;

  /// No description provided for @fittingStyle.
  ///
  /// In en, this message translates to:
  /// **'Fitting Style'**
  String get fittingStyle;

  /// No description provided for @customizationOptions.
  ///
  /// In en, this message translates to:
  /// **'Customization Options'**
  String get customizationOptions;

  /// No description provided for @embroideryWork.
  ///
  /// In en, this message translates to:
  /// **'Embroidery Work'**
  String get embroideryWork;

  /// No description provided for @embroidery.
  ///
  /// In en, this message translates to:
  /// **'Embroidery'**
  String get embroidery;

  /// No description provided for @fabricQuality.
  ///
  /// In en, this message translates to:
  /// **'Fabric Quality'**
  String get fabricQuality;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @additionalServices.
  ///
  /// In en, this message translates to:
  /// **'Additional Services'**
  String get additionalServices;

  /// No description provided for @expressDelivery.
  ///
  /// In en, this message translates to:
  /// **'Express Delivery'**
  String get expressDelivery;

  /// No description provided for @expressDeliveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Get your order in 2-3 days (+PKR 1,000)'**
  String get expressDeliveryDesc;

  /// No description provided for @expressDeliveryRequired.
  ///
  /// In en, this message translates to:
  /// **'Express Delivery Required'**
  String get expressDeliveryRequired;

  /// No description provided for @giftWrapping.
  ///
  /// In en, this message translates to:
  /// **'Gift Wrapping'**
  String get giftWrapping;

  /// No description provided for @giftWrappingDesc.
  ///
  /// In en, this message translates to:
  /// **'Beautiful gift packaging (+PKR 500)'**
  String get giftWrappingDesc;

  /// No description provided for @giftWrappingRequired.
  ///
  /// In en, this message translates to:
  /// **'Gift Wrapping Required'**
  String get giftWrappingRequired;

  /// No description provided for @additionalRequirements.
  ///
  /// In en, this message translates to:
  /// **'Additional Requirements'**
  String get additionalRequirements;

  /// No description provided for @additionalRequirementsHint.
  ///
  /// In en, this message translates to:
  /// **'Any special requirements, measurements, design preferences, or delivery instructions...'**
  String get additionalRequirementsHint;

  /// No description provided for @basePriceQuantity.
  ///
  /// In en, this message translates to:
  /// **'Base Price × {quantity}:'**
  String basePriceQuantity(int quantity);

  /// No description provided for @customSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom Size'**
  String get customSizeLabel;

  /// No description provided for @customTailoring.
  ///
  /// In en, this message translates to:
  /// **'Custom Tailoring'**
  String get customTailoring;

  /// No description provided for @slimFit.
  ///
  /// In en, this message translates to:
  /// **'Slim Fit'**
  String get slimFit;

  /// No description provided for @subtotalWithCustomizations.
  ///
  /// In en, this message translates to:
  /// **'Subtotal with Customizations:'**
  String get subtotalWithCustomizations;

  /// No description provided for @itemDiscount.
  ///
  /// In en, this message translates to:
  /// **'Item Discount:'**
  String get itemDiscount;

  /// No description provided for @youSave.
  ///
  /// In en, this message translates to:
  /// **'You save PKR {amount}'**
  String youSave(String amount);

  /// No description provided for @deleteSale.
  ///
  /// In en, this message translates to:
  /// **'Delete Sale'**
  String get deleteSale;

  /// No description provided for @deleteSaleRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Sale Record'**
  String get deleteSaleRecord;

  /// No description provided for @areYouSureDeleteSale.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this sale?'**
  String get areYouSureDeleteSale;

  /// No description provided for @areYouAbsolutelySure.
  ///
  /// In en, this message translates to:
  /// **'Are you absolutely sure you want to delete this sale record?'**
  String get areYouAbsolutelySure;

  /// No description provided for @permanentDeleteWarningShort.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the sale record and all associated data.'**
  String get permanentDeleteWarningShort;

  /// No description provided for @permanentDeleteWarningLong.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete the sale record, payment information, and all associated data. This action cannot be undone.'**
  String get permanentDeleteWarningLong;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleting;

  /// No description provided for @deleteSaleButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Sale'**
  String get deleteSaleButton;

  /// No description provided for @saleDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Sale record deleted successfully!'**
  String get saleDeletedSuccessfully;

  /// No description provided for @editInvoice.
  ///
  /// In en, this message translates to:
  /// **'Edit Invoice'**
  String get editInvoice;

  /// No description provided for @editInvoiceWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Edit Invoice - {invoiceNumber}'**
  String editInvoiceWithNumber(String invoiceNumber);

  /// No description provided for @statusRequired.
  ///
  /// In en, this message translates to:
  /// **'Status *'**
  String get statusRequired;

  /// No description provided for @selectInvoiceStatus.
  ///
  /// In en, this message translates to:
  /// **'Select invoice status'**
  String get selectInvoiceStatus;

  /// No description provided for @pleaseSelectStatus.
  ///
  /// In en, this message translates to:
  /// **'Please select a status'**
  String get pleaseSelectStatus;

  /// No description provided for @clearDueDate.
  ///
  /// In en, this message translates to:
  /// **'Clear due date'**
  String get clearDueDate;

  /// No description provided for @additionalInvoiceNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional invoice notes (optional)'**
  String get additionalInvoiceNotes;

  /// No description provided for @invoiceTermsConditions.
  ///
  /// In en, this message translates to:
  /// **'Invoice terms and conditions'**
  String get invoiceTermsConditions;

  /// No description provided for @standardTermsConditions.
  ///
  /// In en, this message translates to:
  /// **'Standard terms and conditions apply'**
  String get standardTermsConditions;

  /// No description provided for @updateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Update Invoice'**
  String get updateInvoice;

  /// No description provided for @invoiceUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invoice updated successfully'**
  String get invoiceUpdatedSuccessfully;

  /// No description provided for @failedToUpdateInvoice.
  ///
  /// In en, this message translates to:
  /// **'Failed to update invoice'**
  String get failedToUpdateInvoice;

  /// No description provided for @editReceipt.
  ///
  /// In en, this message translates to:
  /// **'Edit Receipt'**
  String get editReceipt;

  /// No description provided for @editReceiptWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Edit Receipt - {receiptNumber}'**
  String editReceiptWithNumber(String receiptNumber);

  /// No description provided for @failedToUpdateReceipt.
  ///
  /// In en, this message translates to:
  /// **'Failed to update receipt'**
  String get failedToUpdateReceipt;

  /// No description provided for @editSale.
  ///
  /// In en, this message translates to:
  /// **'Edit Sale'**
  String get editSale;

  /// No description provided for @editSaleDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Sale Details'**
  String get editSaleDetails;

  /// No description provided for @saleSummaryReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Sale Summary (Read-Only)'**
  String get saleSummaryReadOnly;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @gst.
  ///
  /// In en, this message translates to:
  /// **'GST'**
  String get gst;

  /// No description provided for @editableFields.
  ///
  /// In en, this message translates to:
  /// **'Editable Fields'**
  String get editableFields;

  /// No description provided for @amountPaidPkr.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid (PKR)'**
  String get amountPaidPkr;

  /// No description provided for @enterAmountPaid.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount paid'**
  String get enterAmountPaid;

  /// No description provided for @partialStatus.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partialStatus;

  /// No description provided for @unpaidStatus.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaidStatus;

  /// No description provided for @specialInstructionsOrRemarks.
  ///
  /// In en, this message translates to:
  /// **'Any special instructions or remarks...'**
  String get specialInstructionsOrRemarks;

  /// No description provided for @amountPaying.
  ///
  /// In en, this message translates to:
  /// **'Amount Paying'**
  String get amountPaying;

  /// No description provided for @updateSale.
  ///
  /// In en, this message translates to:
  /// **'Update Sale'**
  String get updateSale;

  /// No description provided for @saleUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Sale updated successfully!'**
  String get saleUpdatedSuccessfully;

  /// No description provided for @existingOrders.
  ///
  /// In en, this message translates to:
  /// **'Existing Orders'**
  String get existingOrders;

  /// No description provided for @deliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery Date'**
  String get deliveryDate;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @inProgressStatus.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgressStatus;

  /// No description provided for @completedStatus.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedStatus;

  /// No description provided for @deliveredStatus.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveredStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledStatus;

  /// No description provided for @productAddedToOrder.
  ///
  /// In en, this message translates to:
  /// **'{productName} added to order {orderId}'**
  String productAddedToOrder(String productName, String orderId);

  /// No description provided for @searchByInvoiceNumberCustomerOrSale.
  ///
  /// In en, this message translates to:
  /// **'Search by invoice number, customer, or sale'**
  String get searchByInvoiceNumberCustomerOrSale;

  /// No description provided for @noInvoicesFound.
  ///
  /// In en, this message translates to:
  /// **'No invoices found'**
  String get noInvoicesFound;

  /// No description provided for @createNewInvoiceUsingButton.
  ///
  /// In en, this message translates to:
  /// **'Create a new invoice using the + button'**
  String get createNewInvoiceUsingButton;

  /// No description provided for @generatePdf.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get generatePdf;

  /// No description provided for @invoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details'**
  String get invoiceDetails;

  /// No description provided for @invoiceDetailsWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details - {invoiceNumber}'**
  String invoiceDetailsWithNumber(String invoiceNumber);

  /// No description provided for @saleInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Sale Invoice Number'**
  String get saleInvoiceNumber;

  /// No description provided for @issueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get issueDate;

  /// No description provided for @invoicePdfGeneratedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invoice PDF generated successfully'**
  String get invoicePdfGeneratedSuccessfully;

  /// No description provided for @deleteInvoiceWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Delete Invoice - {invoiceNumber}'**
  String deleteInvoiceWithNumber(String invoiceNumber);

  /// No description provided for @areYouSureDeleteInvoice.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this invoice?'**
  String get areYouSureDeleteInvoice;

  /// No description provided for @invoiceDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invoice deleted successfully'**
  String get invoiceDeletedSuccessfully;

  /// No description provided for @orderCreated.
  ///
  /// In en, this message translates to:
  /// **'Order Created!'**
  String get orderCreated;

  /// No description provided for @customOrderCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Custom order created successfully'**
  String get customOrderCreatedSuccessfully;

  /// No description provided for @advanceReceived.
  ///
  /// In en, this message translates to:
  /// **'Advance Received:'**
  String get advanceReceived;

  /// No description provided for @printOrder.
  ///
  /// In en, this message translates to:
  /// **'Print Order'**
  String get printOrder;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @printFunctionalityWillBeImplemented.
  ///
  /// In en, this message translates to:
  /// **'Print functionality will be implemented'**
  String get printFunctionalityWillBeImplemented;

  /// No description provided for @paymentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Payment Confirmation'**
  String get paymentConfirmation;

  /// No description provided for @paymentComplete.
  ///
  /// In en, this message translates to:
  /// **'Payment Complete'**
  String get paymentComplete;

  /// No description provided for @paymentInProgress.
  ///
  /// In en, this message translates to:
  /// **'Payment in Progress'**
  String get paymentInProgress;

  /// No description provided for @previouslyPaid.
  ///
  /// In en, this message translates to:
  /// **'Previously Paid:'**
  String get previouslyPaid;

  /// No description provided for @thisPayment.
  ///
  /// In en, this message translates to:
  /// **'This Payment:'**
  String get thisPayment;

  /// No description provided for @newBalance.
  ///
  /// In en, this message translates to:
  /// **'New Balance:'**
  String get newBalance;

  /// No description provided for @creditDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Credit/Debit Card'**
  String get creditDebitCard;

  /// No description provided for @mobilePayment.
  ///
  /// In en, this message translates to:
  /// **'Mobile Payment'**
  String get mobilePayment;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @amountExceedsBalance.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds remaining balance'**
  String get amountExceedsBalance;

  /// No description provided for @referenceOptional.
  ///
  /// In en, this message translates to:
  /// **'Reference (Optional)'**
  String get referenceOptional;

  /// No description provided for @transactionReferenceOrReceipt.
  ///
  /// In en, this message translates to:
  /// **'Transaction reference or receipt number'**
  String get transactionReferenceOrReceipt;

  /// No description provided for @additionalNotesAboutPayment.
  ///
  /// In en, this message translates to:
  /// **'Additional notes about this payment'**
  String get additionalNotesAboutPayment;

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// No description provided for @paymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment Confirmed'**
  String get paymentConfirmed;

  /// No description provided for @paymentProcessedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment has been processed successfully!'**
  String get paymentProcessedSuccessfully;

  /// No description provided for @continue_.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_;

  /// No description provided for @paymentError.
  ///
  /// In en, this message translates to:
  /// **'Payment Error'**
  String get paymentError;

  /// No description provided for @invalidPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid payment amount. Please check the amount and try again.'**
  String get invalidPaymentAmount;

  /// No description provided for @paymentProcessingFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment processing failed. Please try again.'**
  String get paymentProcessingFailed;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String errorOccurred(String error);

  /// No description provided for @paymentWorkflowDashboard.
  ///
  /// In en, this message translates to:
  /// **'Payment Workflow Dashboard'**
  String get paymentWorkflowDashboard;

  /// No description provided for @refreshDashboard.
  ///
  /// In en, this message translates to:
  /// **'Refresh Dashboard'**
  String get refreshDashboard;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @pendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Pending Payments'**
  String get pendingPayments;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @paymentProgressOverview.
  ///
  /// In en, this message translates to:
  /// **'Payment Progress Overview'**
  String get paymentProgressOverview;

  /// No description provided for @paymentCompletion.
  ///
  /// In en, this message translates to:
  /// **'Payment Completion'**
  String get paymentCompletion;

  /// No description provided for @recentWorkflowActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Workflow Activities'**
  String get recentWorkflowActivities;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @updateSaleStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Sale Status'**
  String get updateSaleStatus;

  /// No description provided for @selectActionToPerform.
  ///
  /// In en, this message translates to:
  /// **'Select an action to perform:'**
  String get selectActionToPerform;

  /// No description provided for @cancelSale.
  ///
  /// In en, this message translates to:
  /// **'Cancel Sale'**
  String get cancelSale;

  /// No description provided for @returnSale.
  ///
  /// In en, this message translates to:
  /// **'Return Sale'**
  String get returnSale;

  /// No description provided for @unknownAction.
  ///
  /// In en, this message translates to:
  /// **'Unknown Action'**
  String get unknownAction;

  /// No description provided for @processAdditionalPayment.
  ///
  /// In en, this message translates to:
  /// **'Process additional payment for this sale'**
  String get processAdditionalPayment;

  /// No description provided for @markSaleAsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark the sale as delivered to customer'**
  String get markSaleAsDelivered;

  /// No description provided for @cancelSaleAndRestoreInventory.
  ///
  /// In en, this message translates to:
  /// **'Cancel this sale and restore inventory'**
  String get cancelSaleAndRestoreInventory;

  /// No description provided for @processReturnForDeliveredSale.
  ///
  /// In en, this message translates to:
  /// **'Process return for delivered sale'**
  String get processReturnForDeliveredSale;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// No description provided for @markedAsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Marked as delivered'**
  String get markedAsDelivered;

  /// No description provided for @saleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sale cancelled'**
  String get saleCancelled;

  /// No description provided for @saleReturned.
  ///
  /// In en, this message translates to:
  /// **'Sale returned'**
  String get saleReturned;

  /// No description provided for @awaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Payment'**
  String get awaitingPayment;

  /// No description provided for @partialPayment.
  ///
  /// In en, this message translates to:
  /// **'Partial Payment'**
  String get partialPayment;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More Actions'**
  String get moreActions;

  /// No description provided for @applyDiscount.
  ///
  /// In en, this message translates to:
  /// **'Apply Discount'**
  String get applyDiscount;

  /// No description provided for @quickDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Quick Discounts'**
  String get quickDiscounts;

  /// No description provided for @originalPrice.
  ///
  /// In en, this message translates to:
  /// **'Original Price:'**
  String get originalPrice;

  /// No description provided for @finalPrice.
  ///
  /// In en, this message translates to:
  /// **'Final Price:'**
  String get finalPrice;

  /// No description provided for @addWithDiscount.
  ///
  /// In en, this message translates to:
  /// **'Add with Discount'**
  String get addWithDiscount;

  /// No description provided for @addedWithDiscount.
  ///
  /// In en, this message translates to:
  /// **'Added {productName} with {discount} discount'**
  String addedWithDiscount(String productName, String discount);

  /// No description provided for @quickAddWithDefaultOptions.
  ///
  /// In en, this message translates to:
  /// **'Quick add with default options'**
  String get quickAddWithDefaultOptions;

  /// No description provided for @setSizeQualityEmbroidery.
  ///
  /// In en, this message translates to:
  /// **'Set size, quality, embroidery, and options'**
  String get setSizeQualityEmbroidery;

  /// No description provided for @applyDiscountBeforeAdding.
  ///
  /// In en, this message translates to:
  /// **'Add discount before adding to cart'**
  String get applyDiscountBeforeAdding;

  /// No description provided for @createCustomOrder.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Order'**
  String get createCustomOrder;

  /// No description provided for @scheduleDeliveryAndAdvance.
  ///
  /// In en, this message translates to:
  /// **'Schedule delivery and take advance'**
  String get scheduleDeliveryAndAdvance;

  /// No description provided for @searchByReceiptCustomerPayment.
  ///
  /// In en, this message translates to:
  /// **'Search by receipt number, customer, or payment'**
  String get searchByReceiptCustomerPayment;

  /// No description provided for @createNewReceiptUsingButton.
  ///
  /// In en, this message translates to:
  /// **'Create a new receipt using the + button'**
  String get createNewReceiptUsingButton;

  /// No description provided for @receiptDetails.
  ///
  /// In en, this message translates to:
  /// **'Receipt Details - {receiptNumber}'**
  String receiptDetails(String receiptNumber);

  /// No description provided for @receiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt Number'**
  String get receiptNumber;

  /// No description provided for @generatedAt.
  ///
  /// In en, this message translates to:
  /// **'Generated At'**
  String get generatedAt;

  /// No description provided for @deleteReceipt.
  ///
  /// In en, this message translates to:
  /// **'Delete Receipt - {receiptNumber}'**
  String deleteReceipt(String receiptNumber);

  /// No description provided for @areYouSureDeleteReceipt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this receipt?'**
  String get areYouSureDeleteReceipt;

  /// No description provided for @refunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get refunds;

  /// No description provided for @searchByReturnCustomerInvoice.
  ///
  /// In en, this message translates to:
  /// **'Search by return number, customer, or invoice'**
  String get searchByReturnCustomerInvoice;

  /// No description provided for @allReasons.
  ///
  /// In en, this message translates to:
  /// **'All Reasons'**
  String get allReasons;

  /// No description provided for @defective.
  ///
  /// In en, this message translates to:
  /// **'Defective'**
  String get defective;

  /// No description provided for @wrongSize.
  ///
  /// In en, this message translates to:
  /// **'Wrong Size'**
  String get wrongSize;

  /// No description provided for @wrongColor.
  ///
  /// In en, this message translates to:
  /// **'Wrong Color'**
  String get wrongColor;

  /// No description provided for @qualityIssue.
  ///
  /// In en, this message translates to:
  /// **'Quality Issue'**
  String get qualityIssue;

  /// No description provided for @customerChangedMind.
  ///
  /// In en, this message translates to:
  /// **'Customer Changed Mind'**
  String get customerChangedMind;

  /// No description provided for @damagedInTransit.
  ///
  /// In en, this message translates to:
  /// **'Damaged in Transit'**
  String get damagedInTransit;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @processed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get processed;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @noReturnsFound.
  ///
  /// In en, this message translates to:
  /// **'No returns found'**
  String get noReturnsFound;

  /// No description provided for @createNewReturnUsingButton.
  ///
  /// In en, this message translates to:
  /// **'Create a new return using the + button'**
  String get createNewReturnUsingButton;

  /// No description provided for @noRefundsFound.
  ///
  /// In en, this message translates to:
  /// **'No refunds found'**
  String get noRefundsFound;

  /// No description provided for @refundsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Refunds will appear here when returns are processed'**
  String get refundsWillAppearHere;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @approvedAt.
  ///
  /// In en, this message translates to:
  /// **'Approved At'**
  String get approvedAt;

  /// No description provided for @processedAt.
  ///
  /// In en, this message translates to:
  /// **'Processed At'**
  String get processedAt;

  /// No description provided for @returnStatistics.
  ///
  /// In en, this message translates to:
  /// **'Return Statistics'**
  String get returnStatistics;

  /// No description provided for @totalReturns.
  ///
  /// In en, this message translates to:
  /// **'Total Returns'**
  String get totalReturns;

  /// No description provided for @approvedReturns.
  ///
  /// In en, this message translates to:
  /// **'Approved Returns'**
  String get approvedReturns;

  /// No description provided for @totalRefunds.
  ///
  /// In en, this message translates to:
  /// **'Total Refunds'**
  String get totalRefunds;

  /// No description provided for @statusBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Status Breakdown'**
  String get statusBreakdown;

  /// No description provided for @returnDetails.
  ///
  /// In en, this message translates to:
  /// **'Return Details - {returnNumber}'**
  String returnDetails(String returnNumber);

  /// No description provided for @saleInvoice.
  ///
  /// In en, this message translates to:
  /// **'Sale Invoice'**
  String get saleInvoice;

  /// No description provided for @refundDetails.
  ///
  /// In en, this message translates to:
  /// **'Refund Details - {refundNumber}'**
  String refundDetails(String refundNumber);

  /// No description provided for @returnId.
  ///
  /// In en, this message translates to:
  /// **'Return ID'**
  String get returnId;

  /// No description provided for @approveReturn.
  ///
  /// In en, this message translates to:
  /// **'Approve Return - {returnNumber}'**
  String approveReturn(String returnNumber);

  /// No description provided for @areYouSureApproveReturn.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to approve this return?'**
  String get areYouSureApproveReturn;

  /// No description provided for @approvalReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Approval Reason (Optional)'**
  String get approvalReasonOptional;

  /// No description provided for @returnApprovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Return approved successfully'**
  String get returnApprovedSuccessfully;

  /// No description provided for @processReturn.
  ///
  /// In en, this message translates to:
  /// **'Process Return - {returnNumber}'**
  String processReturn(String returnNumber);

  /// No description provided for @processReturnAndInitiateRefund.
  ///
  /// In en, this message translates to:
  /// **'Process this return and initiate refund?'**
  String get processReturnAndInitiateRefund;

  /// No description provided for @refundAmount.
  ///
  /// In en, this message translates to:
  /// **'Refund Amount'**
  String get refundAmount;

  /// No description provided for @refundMethod.
  ///
  /// In en, this message translates to:
  /// **'Refund Method'**
  String get refundMethod;

  /// No description provided for @refundMethodHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Cash, Bank Transfer, etc.'**
  String get refundMethodHint;

  /// No description provided for @returnProcessedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Return processed successfully'**
  String get returnProcessedSuccessfully;

  /// No description provided for @provideValidRefundAmountAndMethod.
  ///
  /// In en, this message translates to:
  /// **'Please provide valid refund amount and method'**
  String get provideValidRefundAmountAndMethod;

  /// No description provided for @cancelReturn.
  ///
  /// In en, this message translates to:
  /// **'Cancel Return - {returnNumber}'**
  String cancelReturn(String returnNumber);

  /// No description provided for @areYouSureCancelReturn.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this return?'**
  String get areYouSureCancelReturn;

  /// No description provided for @cancellationReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Reason (Required)'**
  String get cancellationReasonRequired;

  /// No description provided for @provideCancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a cancellation reason'**
  String get provideCancellationReason;

  /// No description provided for @returnCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Return cancelled successfully'**
  String get returnCancelledSuccessfully;

  /// No description provided for @editReturn.
  ///
  /// In en, this message translates to:
  /// **'Edit Return - {returnNumber}'**
  String editReturn(String returnNumber);

  /// No description provided for @returnUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Return updated successfully'**
  String get returnUpdatedSuccessfully;

  /// No description provided for @deleteReturn.
  ///
  /// In en, this message translates to:
  /// **'Delete Return - {returnNumber}'**
  String deleteReturn(String returnNumber);

  /// No description provided for @areYouSureDeleteReturn.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this return?'**
  String get areYouSureDeleteReturn;

  /// No description provided for @returnDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Return deleted successfully'**
  String get returnDeletedSuccessfully;

  /// No description provided for @processRefund.
  ///
  /// In en, this message translates to:
  /// **'Process Refund - {refundNumber}'**
  String processRefund(String refundNumber);

  /// No description provided for @referenceNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Reference Number (Optional)'**
  String get referenceNumberOptional;

  /// No description provided for @processingNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Processing Notes (Optional)'**
  String get processingNotesOptional;

  /// No description provided for @refundProcessedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Refund processed successfully'**
  String get refundProcessedSuccessfully;

  /// No description provided for @processRefundAction.
  ///
  /// In en, this message translates to:
  /// **'Process Refund'**
  String get processRefundAction;

  /// No description provided for @editRefund.
  ///
  /// In en, this message translates to:
  /// **'Edit Refund - {refundNumber}'**
  String editRefund(String refundNumber);

  /// No description provided for @amountCannotBeChanged.
  ///
  /// In en, this message translates to:
  /// **'Amount: PKR {amount} (Cannot be changed)'**
  String amountCannotBeChanged(String amount);

  /// No description provided for @refundUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Refund updated successfully'**
  String get refundUpdatedSuccessfully;

  /// No description provided for @deleteRefund.
  ///
  /// In en, this message translates to:
  /// **'Delete Refund - {refundNumber}'**
  String deleteRefund(String refundNumber);

  /// No description provided for @areYouSureDeleteRefund.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this refund?'**
  String get areYouSureDeleteRefund;

  /// No description provided for @refundDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Refund deleted successfully'**
  String get refundDeletedSuccessfully;

  /// No description provided for @createNewSale.
  ///
  /// In en, this message translates to:
  /// **'Create New Sale'**
  String get createNewSale;

  /// No description provided for @pleaseEnterInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter an invoice number'**
  String get pleaseEnterInvoiceNumber;

  /// No description provided for @pleaseEnterCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Please enter customer name'**
  String get pleaseEnterCustomerName;

  /// No description provided for @pleaseEnterCustomerPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter customer phone'**
  String get pleaseEnterCustomerPhone;

  /// No description provided for @overallDiscountRs.
  ///
  /// In en, this message translates to:
  /// **'Overall Discount (Rs.)'**
  String get overallDiscountRs;

  /// No description provided for @invoiced.
  ///
  /// In en, this message translates to:
  /// **'INVOICED'**
  String get invoiced;

  /// No description provided for @saleItems.
  ///
  /// In en, this message translates to:
  /// **'Sale Items'**
  String get saleItems;

  /// No description provided for @noSaleItemsAdded.
  ///
  /// In en, this message translates to:
  /// **'No Sale Items Added'**
  String get noSaleItemsAdded;

  /// No description provided for @addItemsToSale.
  ///
  /// In en, this message translates to:
  /// **'Add items to this sale'**
  String get addItemsToSale;

  /// No description provided for @taxConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Tax Configuration'**
  String get taxConfiguration;

  /// No description provided for @totalTax.
  ///
  /// In en, this message translates to:
  /// **'Total Tax'**
  String get totalTax;

  /// No description provided for @createSale.
  ///
  /// In en, this message translates to:
  /// **'Create Sale'**
  String get createSale;

  /// No description provided for @addSaleItemFunctionalityToBeImplemented.
  ///
  /// In en, this message translates to:
  /// **'Add Sale Item functionality to be implemented'**
  String get addSaleItemFunctionalityToBeImplemented;

  /// No description provided for @pleaseAddAtLeastOneSaleItem.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one sale item'**
  String get pleaseAddAtLeastOneSaleItem;

  /// No description provided for @errorSavingSale.
  ///
  /// In en, this message translates to:
  /// **'Error saving sale: {error}'**
  String errorSavingSale(String error);

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @process.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get process;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @refundNumber.
  ///
  /// In en, this message translates to:
  /// **'Refund Number'**
  String get refundNumber;

  /// No description provided for @saleDate.
  ///
  /// In en, this message translates to:
  /// **'Sale Date'**
  String get saleDate;

  /// No description provided for @customerPhone.
  ///
  /// In en, this message translates to:
  /// **'Customer Phone'**
  String get customerPhone;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @noSalesRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No Sales Records Found'**
  String get noSalesRecordsFound;

  /// No description provided for @completeFirstSaleMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete your first sale to see transaction records here'**
  String get completeFirstSaleMessage;

  /// No description provided for @printReceiptFor.
  ///
  /// In en, this message translates to:
  /// **'Print receipt for {invoice}'**
  String printReceiptFor(String invoice);

  /// No description provided for @addCustomTax.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Tax'**
  String get addCustomTax;

  /// No description provided for @refreshTaxRates.
  ///
  /// In en, this message translates to:
  /// **'Refresh Tax Rates'**
  String get refreshTaxRates;

  /// No description provided for @noTaxRatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Tax Rates Available'**
  String get noTaxRatesAvailable;

  /// No description provided for @contactAdministratorToSetupTaxRates.
  ///
  /// In en, this message translates to:
  /// **'Contact administrator to set up tax rates'**
  String get contactAdministratorToSetupTaxRates;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @totalTaxAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Tax Amount'**
  String get totalTaxAmount;

  /// No description provided for @totalTaxPercentage.
  ///
  /// In en, this message translates to:
  /// **'Total Tax Percentage'**
  String get totalTaxPercentage;

  /// No description provided for @addTax.
  ///
  /// In en, this message translates to:
  /// **'Add Tax'**
  String get addTax;

  /// No description provided for @saleDetails.
  ///
  /// In en, this message translates to:
  /// **'Sale Details'**
  String get saleDetails;

  /// No description provided for @saleInvoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Sale Invoice Details'**
  String get saleInvoiceDetails;

  /// No description provided for @dateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateTime;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noSplitPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'No split payment details'**
  String get noSplitPaymentDetails;

  /// No description provided for @overallDiscount.
  ///
  /// In en, this message translates to:
  /// **'Overall Discount'**
  String get overallDiscount;

  /// No description provided for @notesRemarks.
  ///
  /// In en, this message translates to:
  /// **'Notes & Remarks'**
  String get notesRemarks;

  /// No description provided for @noNotesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No notes available'**
  String get noNotesAvailable;

  /// No description provided for @printingReceiptFor.
  ///
  /// In en, this message translates to:
  /// **'Printing receipt for {invoice}'**
  String printingReceiptFor(String invoice);

  /// No description provided for @invoiceHash.
  ///
  /// In en, this message translates to:
  /// **'Invoice #'**
  String get invoiceHash;

  /// No description provided for @subTotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subTotal;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get action;

  /// No description provided for @deletePurchase.
  ///
  /// In en, this message translates to:
  /// **'Delete Purchase'**
  String get deletePurchase;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingData;

  /// No description provided for @pendingOrders.
  ///
  /// In en, this message translates to:
  /// **'Pending orders'**
  String get pendingOrders;

  /// No description provided for @returnNumber.
  ///
  /// In en, this message translates to:
  /// **'Return Number'**
  String get returnNumber;

  /// No description provided for @pleaseSelectVendor.
  ///
  /// In en, this message translates to:
  /// **'Please select a vendor'**
  String get pleaseSelectVendor;

  /// No description provided for @loadingLabors.
  ///
  /// In en, this message translates to:
  /// **'Loading employees...'**
  String get loadingLabors;

  /// No description provided for @loadingVendors.
  ///
  /// In en, this message translates to:
  /// **'Loading vendors...'**
  String get loadingVendors;

  /// No description provided for @loadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Loading orders...'**
  String get loadingOrders;

  /// No description provided for @loadingSales.
  ///
  /// In en, this message translates to:
  /// **'Loading sales...'**
  String get loadingSales;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this purchase?'**
  String get confirmDelete;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchase deleted successfully'**
  String get deleteSuccess;

  /// No description provided for @editPurchase.
  ///
  /// In en, this message translates to:
  /// **'Edit Purchase'**
  String get editPurchase;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @scannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Barcode Scanner'**
  String get scannerTitle;

  /// No description provided for @scannerReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to scan...'**
  String get scannerReady;

  /// No description provided for @scannerScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scannerScanning;

  /// No description provided for @scannerLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get scannerLabel;

  /// No description provided for @scannerHint.
  ///
  /// In en, this message translates to:
  /// **'Type or scan barcode'**
  String get scannerHint;

  /// No description provided for @scannerInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid barcode format'**
  String get scannerInvalidFormat;

  /// No description provided for @scannerDuplicateScan.
  ///
  /// In en, this message translates to:
  /// **'Duplicate barcode scan'**
  String get scannerDuplicateScan;

  /// No description provided for @scannerProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get scannerProductNotFound;

  /// No description provided for @scannerFound.
  ///
  /// In en, this message translates to:
  /// **'Found: {productName}'**
  String scannerFound(String productName);

  /// No description provided for @scannerFailed.
  ///
  /// In en, this message translates to:
  /// **'Scan failed: {error}'**
  String scannerFailed(String error);

  /// No description provided for @scannerAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added {productName} to cart'**
  String scannerAddedToCart(String productName);

  /// No description provided for @scannerAddToCartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add product to cart'**
  String get scannerAddToCartFailed;

  /// No description provided for @userLogin.
  ///
  /// In en, this message translates to:
  /// **'User Login'**
  String get userLogin;

  /// No description provided for @userRegistration.
  ///
  /// In en, this message translates to:
  /// **'User Registration'**
  String get userRegistration;

  /// No description provided for @registerHere.
  ///
  /// In en, this message translates to:
  /// **'Register here'**
  String get registerHere;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Full Name'**
  String get enterFullName;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @createNewUser.
  ///
  /// In en, this message translates to:
  /// **'Create New User'**
  String get createNewUser;

  /// No description provided for @rolePermissionMatrix.
  ///
  /// In en, this message translates to:
  /// **'Role & Permission Matrix'**
  String get rolePermissionMatrix;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get userName;

  /// No description provided for @orderRental.
  ///
  /// In en, this message translates to:
  /// **'Order & Rental'**
  String get orderRental;

  /// No description provided for @invoicePayments.
  ///
  /// In en, this message translates to:
  /// **'Invoice & Payments'**
  String get invoicePayments;

  /// No description provided for @approvalWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Approval Workflow for Sensitive actions'**
  String get approvalWorkflow;

  /// No description provided for @userRoles.
  ///
  /// In en, this message translates to:
  /// **'User Roles'**
  String get userRoles;

  /// No description provided for @reportsAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics'**
  String get reportsAnalytics;

  /// No description provided for @manageReportsSub.
  ///
  /// In en, this message translates to:
  /// **'Manage your Reports here\'s'**
  String get manageReportsSub;

  /// No description provided for @newCustomersStat.
  ///
  /// In en, this message translates to:
  /// **'New Customer\'s'**
  String get newCustomersStat;

  /// No description provided for @thisMonthStat.
  ///
  /// In en, this message translates to:
  /// **'this Month'**
  String get thisMonthStat;

  /// No description provided for @eventsStat.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsStat;

  /// No description provided for @itemsStat.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsStat;

  /// No description provided for @timeFilter.
  ///
  /// In en, this message translates to:
  /// **'Time Filter'**
  String get timeFilter;

  /// No description provided for @searchReport.
  ///
  /// In en, this message translates to:
  /// **'Search Report'**
  String get searchReport;

  /// No description provided for @downloadPdfReport.
  ///
  /// In en, this message translates to:
  /// **'Download PDF Report'**
  String get downloadPdfReport;

  /// No description provided for @exportToExcel.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get exportToExcel;

  /// No description provided for @monthlyRevenueAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue Analysis'**
  String get monthlyRevenueAnalysis;

  /// No description provided for @categoryWiseDemand.
  ///
  /// In en, this message translates to:
  /// **'Category-wise Demand'**
  String get categoryWiseDemand;

  /// No description provided for @mostRentedItemReports.
  ///
  /// In en, this message translates to:
  /// **'Most Rented Item Reports'**
  String get mostRentedItemReports;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @rentDays.
  ///
  /// In en, this message translates to:
  /// **'Rent Days'**
  String get rentDays;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get clientName;

  /// No description provided for @totalBill.
  ///
  /// In en, this message translates to:
  /// **'Total Bill'**
  String get totalBill;

  /// No description provided for @stageLight.
  ///
  /// In en, this message translates to:
  /// **'Stage Light'**
  String get stageLight;

  /// No description provided for @smdScreens.
  ///
  /// In en, this message translates to:
  /// **'SMD Screens'**
  String get smdScreens;

  /// No description provided for @totalEvents.
  ///
  /// In en, this message translates to:
  /// **'Total Events'**
  String get totalEvents;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @quotations.
  ///
  /// In en, this message translates to:
  /// **'Quotations'**
  String get quotations;

  /// No description provided for @failedToUpdatePayablePleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Failed to update payable. Please try again.'**
  String get failedToUpdatePayablePleaseTryAgain;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ur': return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
