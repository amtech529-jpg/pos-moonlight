import 'dart:typed_data'; // ✅ REQUIRED
import 'dart:io'; // ✅ REQUIRED for File operations
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart'; // ✅ REQUIRED
import 'package:pdf/pdf.dart';           // ✅ REQUIRED
import 'package:path_provider/path_provider.dart'; // ✅ REQUIRED for file operations
import 'package:open_file/open_file.dart'; // ✅ REQUIRED for opening files
import '../models/sales/sale_model.dart';
import '../models/sales/request_models.dart';
import '../services/sales_service.dart';
import '../services/sale_item_service.dart';
import '../services/customer_service.dart';
import '../services/product_service.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../utils/debug_helper.dart';
import '../models/customer/customer_model.dart';
import '../models/product/product_model.dart';
import '../providers/dashboard_provider.dart';

// Cart item model for cart functionality
class CartItem {
  final String id;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double itemDiscount;
  final String? customizationNotes;
  final double lineTotal;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.itemDiscount = 0.0,
    this.customizationNotes,
  }) : lineTotal = (unitPrice * quantity) - itemDiscount;

  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    double? itemDiscount,
    String? customizationNotes,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      itemDiscount: itemDiscount ?? this.itemDiscount,
      customizationNotes: customizationNotes ?? this.customizationNotes,
    );
  }
}

class SalesProvider extends ChangeNotifier {
  final SalesService _salesService = SalesService();
  final SaleItemService _saleItemService = SaleItemService();
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();

  // State variables
  List<SaleModel> _sales = [];
  SaleModel? _selectedSale;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Pagination
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;
  int _totalPages = 1;
  bool _hasNext = false;
  bool _hasPrevious = false;

  // Filters
  String? _statusFilter;
  String? _customerFilter;
  String? _paymentMethodFilter;
  String? _searchQuery;
  String? _dateFromFilter;
  String? _dateToFilter;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  // Statistics
  Map<String, dynamic>? _statistics;

  // Cart functionality
  List<CartItem> _cartItems = [];
  CustomerModel? _selectedCustomer;
  double _overallDiscount = 0.0;
  TaxConfiguration _taxConfiguration = TaxConfiguration();

  // Customer and Product management
  List<CustomerModel> _customers = [];
  List<ProductModel> _products = [];

  // Getters
  List<SaleModel> get sales => _sales;
  SaleModel? get selectedSale => _selectedSale;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Pagination getters
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;
  bool get hasNext => _hasNext;
  bool get hasPrevious => _hasPrevious;

  // Filter getters
  String get statusFilter => _statusFilter ?? 'All Status';
  String? get customerFilter => _customerFilter;
  String? get paymentMethodFilter => _paymentMethodFilter;
  String? get searchQuery => _searchQuery;
  String? get dateFromFilter => _dateFromFilter;
  String? get dateToFilter => _dateToFilter;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;

  // Statistics getters
  Map<String, dynamic>? get statistics => _statistics;

  // Cart getters
  List<CartItem> get currentCart => _cartItems;
  int get cartTotalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get cartSubtotal => _cartItems.fold(0.0, (sum, item) => sum + item.lineTotal);
  double get overallDiscount => _overallDiscount;
  double get cartGstAmount => _taxConfiguration.totalTaxAmount;
  double get cartTaxAmount => _taxConfiguration.totalTaxAmount;
  double get gstPercentage => _taxConfiguration.totalTaxPercentage;
  double get taxPercentage => _taxConfiguration.totalTaxPercentage;
  double get cartGrandTotal => cartSubtotal + cartGstAmount - overallDiscount;

  // Customer and Product getters
  CustomerModel? get selectedCustomer => _selectedCustomer;
  List<CustomerModel> get customers => _customers;
  List<ProductModel> get products => _products;

  // Sales statistics getter
  Map<String, dynamic>? get salesStats => _statistics;

  // Computed getters
  bool get hasSales => _sales.isNotEmpty;
  int get salesCount => _sales.length;
  double get totalRevenue => _sales.fold(0.0, (sum, sale) => sum + sale.grandTotal);
  double get totalTaxCollected => _sales.fold(0.0, (sum, sale) => sum + sale.taxAmount);

  /// Load sales with current filters and pagination
  Future<void> loadSales({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _sales.clear();
    }

    if (_isLoading) return;

    _setLoading(true);
    _clearMessages();

    try {
      final params = SalesListParams(
        page: _currentPage,
        pageSize: _pageSize,
        status: _statusFilter,
        customerId: _customerFilter,
        paymentMethod: _paymentMethodFilter,
        search: _searchQuery,
        dateFrom: _dateFromFilter,
        dateTo: _dateToFilter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      final response = await _salesService.getSales(params: params);

      if (response.success && response.data != null) {
        if (refresh) {
          _sales = response.data!.sales;
          debugPrint('🔍 [SalesProvider] Refresh: Set sales to ${_sales.length} items');
        } else {
          _sales.addAll(response.data!.sales);
          debugPrint('🔍 [SalesProvider] Append: Added ${response.data!.sales.length} items, total now ${_sales.length}');
        }

        _totalCount = response.data!.pagination.totalCount;
        _totalPages = response.data!.pagination.totalPages;
        _hasNext = response.data!.pagination.hasNext;
        _hasPrevious = response.data!.pagination.hasPrevious;
        debugPrint('🔍 [SalesProvider] Pagination updated: page=$_currentPage, totalPages=$_totalPages, hasNext=$_hasNext');
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading sales: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load all sales pages
  Future<void> loadAllSales() async {
    debugPrint('🔍 [SalesProvider] Starting loadAllSales...');
    _sales.clear();
    _currentPage = 1;
    
    // Load first page to get pagination info
    debugPrint('🔍 [SalesProvider] Loading first page...');
    await loadSales(refresh: true);
    debugPrint('🔍 [SalesProvider] After first load: hasNext=$_hasNext, totalPages=$_totalPages, salesCount=${_sales.length}');
    
    // Load remaining pages
    while (_hasNext && _currentPage < _totalPages) {
      _currentPage++;
      debugPrint('🔍 [SalesProvider] Loading page $_currentPage...');
      await loadSales(refresh: false);
      debugPrint('🔍 [SalesProvider] After page $_currentPage: hasNext=$_hasNext, salesCount=${_sales.length}');
    }
    debugPrint('🔍 [SalesProvider] Finished loading all ${_sales.length} sales');
  }

  /// Load sales statistics
  Future<void> loadSalesStatistics() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _salesService.getSalesStatistics();

      if (response.success && response.data != null) {
        _statistics = response.data!.toJson();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Error loading sales statistics: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load customers
  Future<void> loadCustomers() async {
    try {
      final response = await _customerService.getCustomers();
      if (response.success && response.data != null) {
        _customers = response.data!.customers;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading customers: $e');
    }
  }

  /// Load products
  Future<void> loadProducts() async {
    try {
      final response = await _productService.getProducts();
      if (response.success && response.data != null) {
        _products = response.data!.products;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  /// Cart management methods
  void addToCartWithCustomization({
    required String productId,
    required String productName,
    required double unitPrice,
    required int quantity,
    double itemDiscount = 0.0,
    String? customizationNotes,
  }) {
    final existingItemIndex = _cartItems.indexWhere(
          (item) => item.productId == productId,
    );

    if (existingItemIndex != -1) {
      // Update existing item
      final existingItem = _cartItems[existingItemIndex];
      _cartItems[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
    } else {
      // Add new item
      final cartItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: productId,
        productName: productName,
        unitPrice: unitPrice,
        quantity: quantity,
        itemDiscount: itemDiscount,
        customizationNotes: customizationNotes,
      );

      _cartItems.add(cartItem);
    }

    _clearMessages();
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    _cartItems.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void updateCartItemQuantity(String itemId, int newQuantity) {
    final itemIndex = _cartItems.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      if (newQuantity <= 0) {
        _cartItems.removeAt(itemIndex);
      } else {
        final item = _cartItems[itemIndex];
        _cartItems[itemIndex] = item.copyWith(quantity: newQuantity);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _overallDiscount = 0.0;
    _taxConfiguration = TaxConfiguration();
    notifyListeners();
  }

  /// Customer management methods
  void setSelectedCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void addCustomer(CustomerModel customer) {
    _customers.add(customer);
    notifyListeners();
  }

  void updateCustomer(CustomerModel customer) {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      notifyListeners();
    }
  }

  void removeCustomer(String customerId) {
    _customers.removeWhere((c) => c.id == customerId);
    notifyListeners();
  }

  /// Product management methods
  void addProduct(ProductModel product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(ProductModel product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      notifyListeners();
    }
  }

  void removeProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  /// Tax configuration methods
  void updateTaxConfiguration(TaxConfiguration configuration) {
    _taxConfiguration = configuration;
    notifyListeners();
  }

  void setOverallDiscount(double discount) {
    print('🔍 setOverallDiscount called');
    print('🔍 Input discount: $discount');
    print('🔍 Cart subtotal: $cartSubtotal');
    
    // Validate discount
    if (discount < 0) {
      print('❌ Discount is negative');
      _setError('Discount cannot be negative');
      return;
    }
    
    if (discount > cartSubtotal) {
      print('❌ Discount $discount exceeds subtotal $cartSubtotal');
      _setError('Discount cannot exceed subtotal');
      return;
    }
    
    _overallDiscount = discount;
    print('✅ Overall discount set to: $_overallDiscount');
    notifyListeners();
  }

  /// Calculate cart totals
  double get cartTotal => cartSubtotal + cartGstAmount - overallDiscount;

  /// Create sale from cart and return the sale ID
  Future<String?> createSaleFromCartWithId({
    required String paymentMethod,
    required double amountPaid,
    String? notes,
  }) async {
    if (_cartItems.isEmpty) {
      _setError('Cart is empty');
      return null;
    }

    try {
      final saleItems = _cartItems
          .map(
            (item) => CreateSaleItemRequest(
          productId: item.productId,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          itemDiscount: item.itemDiscount,
          customizationNotes: item.customizationNotes,
        ),
      )
          .toList();

      final request = CreateSaleRequest(
        customerId: _selectedCustomer?.id,
        overallDiscount: _overallDiscount,
        taxConfiguration: _taxConfiguration,
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        notes: notes,
        saleItems: saleItems,
      );

      debugPrint('🚀 Creating sale with payload: ${request.toJson()}');

      final response = await _salesService.createSale(request);

      if (response.success && response.data != null) {
        final saleId = response.data!.id;
        _sales.insert(0, response.data!);
        _setSuccess('Sale created successfully');
        
        // Clear cart after successful sale
        clearCart();
        setSelectedCustomer(null);
        
        // Refresh products to update stock quantities
        await loadProducts();
        
        // Refresh dashboard to update real-time counts
        DashboardProvider.refreshDashboard();
        
        return saleId;
      } else {
        _setError(response.message);
        return null;
      }
    } catch (e) {
      debugPrint('💥 Exception in createSaleFromCartWithId: $e');
      _setError('Error creating sale from cart: $e');
      return null;
    }
  }
  Future<bool> createSaleFromCart({
    required String paymentMethod,
    required double amountPaid,
    String? notes,
  }) async {
    if (_cartItems.isEmpty) {
      _setError('Cart is empty');
      return false;
    }

    try {
      final saleItems = _cartItems
          .map(
            (item) => CreateSaleItemRequest(
          productId: item.productId,
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          itemDiscount: item.itemDiscount,
          customizationNotes: item.customizationNotes,
        ),
      )
          .toList();

      final request = CreateSaleRequest(
        customerId: _selectedCustomer?.id,
        overallDiscount: _overallDiscount,
        taxConfiguration: _taxConfiguration,
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        notes: notes,
        saleItems: saleItems,
      );

      debugPrint('🚀 Creating sale with payload: ${request.toJson()}');

      final success = await createSale(request);

      debugPrint('✅ Sale creation result: $success');
      if (!success) debugPrint('❌ Error: $_errorMessage');

      if (success) {
        clearCart();
        setSelectedCustomer(null);
        
        // Refresh products to update stock quantities
        await loadProducts();
        
        // Refresh dashboard to update real-time counts
        DashboardProvider.refreshDashboard();
      }
      return success;
    } catch (e) {
      debugPrint('💥 Exception in createSaleFromCart: $e');
      _setError('Error creating sale from cart: $e');
      return false;
    }
  }

  /// Get sale by ID
  Future<SaleModel?> getSaleById(String id) async {
    try {
      final response = await _salesService.getSaleById(id);
      if (response.success && response.data != null) {
        return response.data!;
      }
      return null;
    } catch (e) {
      _setError('Error getting sale: $e');
      return null;
    }
  }

  /// Create new sale
  Future<bool> createSale(CreateSaleRequest request) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _salesService.createSale(request);

      if (response.success && response.data != null) {
        _sales.insert(0, response.data!);
        _setSuccess('Sale created successfully');
        
        // Refresh products to update stock quantities
        await loadProducts();
        
        // Refresh dashboard to update real-time counts
        DashboardProvider.refreshDashboard();
        
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error creating sale: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing sale
  Future<bool> updateSale(String id, UpdateSaleRequest request) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _salesService.updateSale(id, request);

      if (response.success && response.data != null) {
        final index = _sales.indexWhere((sale) => sale.id == id);
        if (index != -1) {
          _sales[index] = response.data!;
        }
        _setSuccess('Sale updated successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error updating sale: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete sale
  Future<bool> deleteSale(String id) async {
    if (_isLoading) return false;

    _setLoading(true);
    _clearMessages();

    try {
      final response = await _salesService.deleteSale(id);

      if (response.success) {
        _sales.removeWhere((sale) => sale.id == id);
        _setSuccess('Sale deleted successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error deleting sale: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Search sales
  Future<void> searchSales(String query) async {
    _searchQuery = query;
    await loadSales(refresh: true);
  }

  /// Filter sales by status
  Future<void> filterByStatus(String? status) async {
    _statusFilter = (status == 'All Status') ? null : status;
    await loadSales(refresh: true);
  }

  /// Filter sales by customer
  Future<void> filterByCustomer(String? customerId) async {
    _customerFilter = customerId;
    await loadSales(refresh: true);
  }

  /// Filter sales by payment method
  Future<void> filterByPaymentMethod(String? paymentMethod) async {
    _paymentMethodFilter = paymentMethod;
    await loadSales(refresh: true);
  }

  /// Filter sales by date range
  Future<void> filterByDateRange(String? dateFrom, String? dateTo) async {
    _dateFromFilter = dateFrom;
    _dateToFilter = dateTo;
    await loadSales(refresh: true);
  }

  /// Sort sales
  Future<void> sortSales(String sortBy, String sortOrder) async {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    await loadSales(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    _statusFilter = null;
    _customerFilter = null;
    _paymentMethodFilter = null;
    _searchQuery = null;
    _dateFromFilter = null;
    _dateToFilter = null;
    _sortBy = 'created_at';
    _sortOrder = 'desc';
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (_hasNext && !_isLoading) {
      _currentPage++;
      await loadSales();
    }
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (_hasPrevious && !_isLoading) {
      _currentPage--;
      await loadSales();
    }
  }

  /// Go to specific page
  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= _totalPages && page != _currentPage) {
      _currentPage = page;
      await loadSales();
    }
  }

  /// Select sale
  void selectSale(SaleModel? sale) {
    _selectedSale = sale;
    notifyListeners();
  }

  /// Update sale status
  Future<bool> updateSaleStatus(String id, String status) async {
    try {
      final request = UpdateSaleRequest(status: status);
      return await updateSale(id, request);
    } catch (e) {
      _setError('Error updating sale status: $e');
      return false;
    }
  }

  /// Recalculate sale totals
  Future<bool> recalculateSaleTotals(String id) async {
    try {
      final saleIndex = _sales.indexWhere((sale) => sale.id == id);
      if (saleIndex == -1) {
        _setError('Sale not found');
        return false;
      }

      final sale = _sales[saleIndex];

      // 1. Calculate Subtotal
      final double subtotal = sale.saleItems.fold(
        0.0,
            (sum, item) => sum + item.lineTotal,
      );

      // 2. Recalculate Taxes
      final Map<String, TaxConfigItem> newTaxes = {};
      sale.taxConfiguration.taxes.forEach((key, item) {
        final double newAmount = (subtotal * item.percentage) / 100;
        newTaxes[key] = item.copyWith(amount: newAmount);
      });

      final newTaxConfiguration = sale.taxConfiguration.copyWith(
        taxes: newTaxes,
      );
      final double taxAmount = newTaxConfiguration.totalTaxAmount;

      // 3. Calculate Grand Total
      final double grandTotal = subtotal + taxAmount - sale.overallDiscount;

      // 4. Update Remaining Amount
      final double remainingAmount = grandTotal - sale.amountPaid;

      // 5. Check if fully paid
      final bool isFullyPaid = remainingAmount <= 0;

      // 6. Update Sale Model
      final updatedSale = sale.copyWith(
        subtotal: subtotal,
        taxConfiguration: newTaxConfiguration,
        taxAmount: taxAmount,
        grandTotal: grandTotal,
        remainingAmount: remainingAmount,
        isFullyPaid: isFullyPaid,
      );

      // 7. Update State
      _sales[saleIndex] = updatedSale;
      if (_selectedSale?.id == id) {
        _selectedSale = updatedSale;
      }
      notifyListeners();

      _setSuccess('Sale totals recalculated');
      return true;
    } catch (e) {
      _setError('Error recalculating sale totals: $e');
      return false;
    }
  }

  /// Create sale from order
  Future<bool> createSaleFromOrder(
      String orderId, {
        required String paymentMethod,
        required double amountPaid,
        double overallDiscount = 0.0,
        TaxConfiguration? taxConfiguration,
        String? notes,
      }) async {
    try {
      final request = CreateSaleFromOrderRequest(
        orderId: orderId,
        paymentMethod: paymentMethod,
        amountPaid: amountPaid,
        overallDiscount: overallDiscount,
        taxConfiguration: taxConfiguration,
        notes: notes,
      );

      final response = await _salesService.createSaleFromOrder(request);

      if (response.success && response.data != null) {
        _sales.insert(0, response.data!);
        _setSuccess('Sale created from order successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error creating sale from order: $e');
      return false;
    }
  }

  /// Initialize provider
  Future<void> initialize() async {
    await Future.wait([
      loadSales(refresh: true),
      loadSalesStatistics(),
      loadCustomers(),
      loadProducts(),
    ]);
  }

  // ===== BULK OPERATIONS =====

  /// Bulk recalculate all sales totals
  Future<bool> bulkRecalculateTotals() async {
    _setLoading(true);
    _clearMessages();

    try {
      // Get all sales IDs
      final allSalesIds = _sales.map((sale) => sale.id).toList();
      
      if (allSalesIds.isEmpty) {
        _setError('No sales found to recalculate');
        return false;
      }

      _setLoading(false); // Stop loading for info message
      
      final response = await _salesService.bulkActionSales(allSalesIds, 'recalculate');

      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('Totals recalculated successfully for ${allSalesIds.length} sales');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error recalculating sales totals: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Bulk activate sales
  Future<bool> bulkActivateSales(List<String> saleIds) async {
    try {
      final response = await _salesService.bulkActionSales(saleIds, 'activate');
      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('${saleIds.length} sales activated successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error activating sales: $e');
      return false;
    }
  }

  /// Bulk deactivate sales
  Future<bool> bulkDeactivateSales(List<String> saleIds) async {
    try {
      final response = await _salesService.bulkActionSales(
        saleIds,
        'deactivate',
      );
      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('${saleIds.length} sales deactivated successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error deactivating sales: $e');
      return false;
    }
  }

  /// Bulk confirm sales
  Future<bool> bulkConfirmSales(List<String> saleIds) async {
    try {
      final response = await _salesService.bulkActionSales(saleIds, 'confirm');
      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('${saleIds.length} sales confirmed successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error confirming sales: $e');
      return false;
    }
  }

  /// Bulk invoice sales
  Future<bool> bulkInvoiceSales(List<String> saleIds) async {
    try {
      final response = await _salesService.bulkActionSales(saleIds, 'invoice');
      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('${saleIds.length} sales invoiced successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error invoicing sales: $e');
      return false;
    }
  }

  /// Bulk mark sales as paid
  Future<bool> bulkMarkPaidSales(List<String> saleIds) async {
    try {
      final response = await _salesService.bulkActionSales(
        saleIds,
        'mark_paid',
      );
      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('${saleIds.length} sales marked as paid successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error marking sales as paid: $e');
      return false;
    }
  }

  /// Bulk deliver sales
  Future<bool> bulkDeliverSales(List<String> saleIds) async {
    try {
      final response = await _salesService.bulkActionSales(saleIds, 'deliver');
      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('${saleIds.length} sales delivered successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error delivering sales: $e');
      return false;
    }
  }

  /// Bulk cancel sales
  Future<bool> bulkCancelSales(List<String> saleIds) async {
    try {
      final response = await _salesService.bulkActionSales(saleIds, 'cancel');
      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('${saleIds.length} sales cancelled successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error cancelling sales: $e');
      return false;
    }
  }

  /// Bulk return sales
  Future<bool> bulkReturnSales(List<String> saleIds) async {
    try {
      final response = await _salesService.bulkActionSales(saleIds, 'return');
      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('${saleIds.length} sales returned successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error returning sales: $e');
      return false;
    }
  }

  // ===== ADVANCED SALES FEATURES =====

  /// Add payment to sale
  Future<bool> addPayment(
      String saleId,
      double amount,
      String method, {
        Map<String, dynamic>? splitDetails,
      }) async {
    try {
      final response = await _salesService.addSalePayment(
        saleId,
        amount,
        method,
      );
      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('Payment added successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error adding payment: $e');
      return false;
    }
  }

  /// Add payment with enhanced workflow
  Future<bool> addPaymentWithWorkflow({
    required String saleId,
    required double amount,
    required String method,
    String? reference,
    String? notes,
    Map<String, dynamic>? splitDetails,
    bool isPartialPayment = false,
  }) async {
    try {
      final response = await _salesService.addPaymentWithWorkflow(
        id: saleId,
        amount: amount,
        method: method,
        reference: reference,
        notes: notes,
        splitDetails: splitDetails,
        isPartialPayment: isPartialPayment,
      );

      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('Payment processed with workflow successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error processing payment workflow: $e');
      return false;
    }
  }

  /// Get payment status for a sale
  Future<Map<String, dynamic>?> getSalePaymentStatus(String saleId) async {
    try {
      final response = await _salesService.getSalePaymentStatus(saleId);
      if (response.success && response.data != null) {
        return response.data;
      } else {
        _setError(response.message);
        return null;
      }
    } catch (e) {
      _setError('Error getting payment status: $e');
      return null;
    }
  }

  /// Process payment confirmation workflow
  Future<bool> confirmPaymentWorkflow({
    required String saleId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
    Map<String, dynamic>? splitDetails,
    bool isPartialPayment = false,
  }) async {
    try {
      final response = await _salesService.confirmPaymentWorkflow(
        saleId: saleId,
        amount: amount,
        paymentMethod: paymentMethod,
        reference: reference,
        notes: notes,
        splitDetails: splitDetails,
        isPartialPayment: isPartialPayment,
      );

      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('Payment workflow completed successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error confirming payment workflow: $e');
      return false;
    }
  }

  /// Get payment workflow summary
  Future<Map<String, dynamic>?> getPaymentWorkflowSummary(String saleId) async {
    try {
      final response = await _salesService.getPaymentWorkflowSummary(saleId);
      if (response.success && response.data != null) {
        return response.data;
      } else {
        _setError(response.message);
        return null;
      }
    } catch (e) {
      _setError('Error getting payment workflow summary: $e');
      return null;
    }
  }

  /// Update sale status with payment tracking
  Future<bool> updateSaleStatusWithPayment(
      String saleId,
      String newStatus, {
        String? notes,
      }) async {
    try {
      final response = await _salesService.updateSaleStatus(saleId, newStatus);
      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('Sale status updated successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error updating sale status: $e');
      return false;
    }
  }

  /// Handle split payments
  Future<bool> handleSplitPayments(
      String saleId,
      Map<String, dynamic> splitDetails,
      ) async {
    try {
      final response = await _salesService.addPayment(saleId, 0.0, 'SPLIT');
      if (response.success) {
        await loadSales(refresh: true);
        _setSuccess('Split payment processed successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error processing split payment: $e');
      return false;
    }
  }

  /// Process payment and update sale workflow
  Future<bool> processPaymentAndUpdateSale({
    required String saleId,
    required double amount,
    required String paymentMethod,
    String? newStatus,
    String? notes,
  }) async {
    try {
      // Step 1: Process payment
      final paymentSuccess = await addPaymentWithWorkflow(
        saleId: saleId,
        amount: amount,
        method: paymentMethod,
        notes: notes,
      );

      if (!paymentSuccess) {
        return false;
      }

      // Step 2: Update sale status if provided
      if (newStatus != null) {
        final statusSuccess = await updateSaleStatusWithPayment(
          saleId,
          newStatus,
          notes: notes,
        );
        if (!statusSuccess) {
          _setError('Payment processed but status update failed');
          return false;
        }
      }

      _setSuccess('Payment and sale update completed successfully');
      return true;
    } catch (e) {
      _setError('Error processing payment and updating sale: $e');
      return false;
    }
  }

  /// Get payment workflow actions for a sale
  List<String> getAvailablePaymentActions(
      Map<String, dynamic> workflowSummary,
      ) {
    final actions = <String>[];

    if (workflowSummary['workflow_actions'] != null) {
      final workflowActions =
      workflowSummary['workflow_actions'] as Map<String, dynamic>;

      if (workflowActions['can_add_payment'] == true) {
        actions.add('add_payment');
      }
      if (workflowActions['can_mark_delivered'] == true) {
        actions.add('mark_delivered');
      }
      if (workflowActions['can_cancel_sale'] == true) {
        actions.add('cancel_sale');
      }
      if (workflowActions['can_return_sale'] == true) {
        actions.add('return_sale');
      }
    }

    return actions;
  }

  /// Validate payment workflow data
  bool validatePaymentWorkflowData({
    required double amount,
    required String paymentMethod,
    required double saleTotal,
    double? previousAmountPaid = 0.0,
  }) {
    if (amount <= 0) return false;
    if (amount > saleTotal) return false;
    if (paymentMethod.isEmpty) return false;

    // Check if payment would exceed sale total
    final totalAfterPayment = (previousAmountPaid ?? 0.0) + amount;
    if (totalAfterPayment > saleTotal) return false;

    return true;
  }

  /// Get payment workflow progress
  double getPaymentWorkflowProgress(Map<String, dynamic> workflowSummary) {
    if (workflowSummary['payment_summary'] != null) {
      final paymentSummary =
      workflowSummary['payment_summary'] as Map<String, dynamic>;
      return paymentSummary['payment_percentage'] as double? ?? 0.0;
    }
    return 0.0;
  }

  /// Check if payment workflow is complete
  bool isPaymentWorkflowComplete(Map<String, dynamic> workflowSummary) {
    if (workflowSummary['payment_summary'] != null) {
      final paymentSummary =
      workflowSummary['payment_summary'] as Map<String, dynamic>;
      return paymentSummary['is_fully_paid'] as bool? ?? false;
    }
    return false;
  }

  /// Validate payment workflow data
  bool validatePaymentWorkflow({
    required double amount,
    required String paymentMethod,
    required double saleTotal,
    double? previousAmountPaid = 0.0,
  }) {
    if (amount <= 0) return false;
    if (amount > saleTotal) return false;
    if (paymentMethod.isEmpty) return false;

    // Check if payment would exceed sale total
    final totalAfterPayment = (previousAmountPaid ?? 0.0) + amount;
    if (totalAfterPayment > saleTotal) return false;

    return true;
  }

  // ===== ENHANCED ANALYTICS =====

  /// Get top products
  Future<Map<String, dynamic>> getTopProducts({int limit = 10}) async {
    try {
      final stats = await _salesService.getSalesStatistics();
      if (stats.success && stats.data != null) {
        return {
          'total_revenue': stats.data!.totalRevenue,
          'total_sales': stats.data!.totalSales,
        };
      }
      return {};
    } catch (e) {
      debugPrint('Error getting top products: $e');
      return {};
    }
  }

  /// Get top customers
  Future<Map<String, dynamic>> getTopCustomers({int limit = 10}) async {
    try {
      final stats = await _salesService.getSalesStatistics();
      if (stats.success && stats.data != null) {
        return {
          'total_sales': stats.data!.totalSales,
          'total_revenue': stats.data!.totalRevenue,
        };
      }
      return {};
    } catch (e) {
      debugPrint('Error getting top customers: $e');
      return {};
    }
  }

  /// Get daily trends
  Future<List<dynamic>> getDailyTrends({int days = 30}) async {
    try {
      final stats = await _salesService.getSalesStatistics();
      if (stats.success && stats.data != null) {
        return stats.data!.dailyTrends;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting daily trends: $e');
      return [];
    }
  }

  /// Get monthly trends
  Future<List<dynamic>> getMonthlyTrends({int months = 12}) async {
    try {
      final stats = await _salesService.getSalesStatistics();
      if (stats.success && stats.data != null) {
        return stats.data!.monthlyTrends;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting monthly trends: $e');
      return [];
    }
  }

  /// Get payment method distribution
  Future<Map<String, dynamic>> getPaymentMethodDistribution() async {
    try {
      final stats = await _salesService.getSalesStatistics();
      if (stats.success && stats.data != null) {
        return stats.data!.paymentMethodDistribution;
      }
      return {};
    } catch (e) {
      debugPrint('Error getting payment method distribution: $e');
      return {};
    }
  }

  /// Get status distribution
  Future<Map<String, dynamic>> getStatusDistribution() async {
    try {
      final stats = await _salesService.getSalesStatistics();
      if (stats.success && stats.data != null) {
        return stats.data!.statusDistribution;
      }
      return {};
    } catch (e) {
      debugPrint('Error getting status distribution: $e');
      return {};
    }
  }

  // ===== SALE ITEMS MANAGEMENT =====

  /// Load sale items for a specific sale
  Future<void> loadSaleItems(String saleId) async {
    try {
      final response = await _saleItemService.getSaleItemsBySale(saleId);
      if (response.success && response.data != null) {
        // Update the sale with its items
        final saleIndex = _sales.indexWhere((sale) => sale.id == saleId);
        if (saleIndex != -1) {
          _sales[saleIndex] = _sales[saleIndex].copyWith(
            saleItems: response.data!,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading sale items: $e');
    }
  }

  /// Create sale item (Note: Sale items are typically created as part of sale creation)
  Future<bool> createSaleItem(
      CreateSaleItemRequest request,
      String saleId,
      ) async {
    try {
      final response = await _saleItemService.createSaleItem(request);
      if (response.success && response.data != null) {
        // Add the new item to the sale
        final saleIndex = _sales.indexWhere((sale) => sale.id == saleId);
        if (saleIndex != -1) {
          _sales[saleIndex] = _sales[saleIndex].copyWith(
            saleItems: [..._sales[saleIndex].saleItems, response.data!],
          );
          notifyListeners();
        }
        _setSuccess('Sale item created successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error creating sale item: $e');
      return false;
    }
  }


  Future<bool> updateSaleItem(
      String itemId,
      UpdateSaleItemRequest request,
      ) async {
    try {
      final response = await _saleItemService.updateSaleItem(itemId, request);
      if (response.success && response.data != null) {
        for (int i = 0; i < _sales.length; i++) {
          final itemIndex = _sales[i].saleItems.indexWhere(
                (item) => item.id == itemId,
          );
          if (itemIndex != -1) {
            final updatedItems = List<SaleItemModel>.from(_sales[i].saleItems);
            updatedItems[itemIndex] = response.data!;
            _sales[i] = _sales[i].copyWith(saleItems: updatedItems);
            notifyListeners();
            break;
          }
        }
        _setSuccess('Sale item updated successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error updating sale item: $e');
      return false;
    }
  }

  /// Delete sale item
  Future<bool> deleteSaleItem(String itemId) async {
    try {
      final response = await _saleItemService.deleteSaleItem(itemId);
      if (response.success) {
        // Remove the item from the sale
        for (int i = 0; i < _sales.length; i++) {
          final itemIndex = _sales[i].saleItems.indexWhere(
                (item) => item.id == itemId,
          );
          if (itemIndex != -1) {
            final updatedItems = List<SaleItemModel>.from(_sales[i].saleItems);
            updatedItems.removeAt(itemIndex);
            _sales[i] = _sales[i].copyWith(saleItems: updatedItems);
            notifyListeners();
            break;
          }
        }
        _setSuccess('Sale item deleted successfully');
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error deleting sale item: $e');
      return false;
    }
  }

  /// Search sale items
  Future<List<SaleItemModel>> searchSaleItems(String query) async {
    try {
      final response = await _saleItemService.searchSaleItems(query);
      if (response.success && response.data != null) {
        return response.data!;
      }
      return [];
    } catch (e) {
      debugPrint('Error searching sale items: $e');
      return [];
    }
  }

  // ✅ UPDATED: Open PDF in System Viewer
  Future<bool> generateReceiptPdf(String saleId) async {
    _setLoading(true);
    debugPrint("🖨️ [SalesProvider] Starting PDF Generation...");

    try {
      final response = await _salesService.generateSaleReceipt(saleId);

      if (response.success && response.data != null) {
        debugPrint("✅ PDF Bytes received. Opening in system viewer...");

        try {
          // ✅ Save PDF to temporary file
          final directory = await getTemporaryDirectory();
          final fileName = 'Receipt_$saleId.pdf';
          final filePath = '${directory.path}/$fileName';
          
          final file = File(filePath);
          await file.writeAsBytes(response.data!);
          
          debugPrint("✅ PDF saved to: $filePath");
          
          // ✅ Use printing package to show PDF (Works on Windows/macOS/Web/Mobile)
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => response.data!,
            name: 'Receipt_$saleId',
          );
          
          _setSuccess('Receipt opened for printing');
          return true;
        } catch (openError) {
          debugPrint("❌ Failed to show PDF: $openError");
          _setError('Failed to show receipt: $openError');
          return false;
        }
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      debugPrint("💥 Print Error: $e");
      _setError('Error generating receipt: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ NEW: Generate Invoice PDF (similar to receipt but for invoices)
  Future<bool> generateInvoicePdf(String invoiceId) async {
    _setLoading(true);
    debugPrint("🖨️ [SalesProvider] Starting Invoice PDF Generation...");

    try {
      final response = await _salesService.generateInvoicePdf(invoiceId);

      if (response.success && response.data != null) {
        debugPrint("✅ Invoice PDF Bytes received. Opening in system viewer...");

        try {
          // ✅ Save PDF to temporary file
          final directory = await getTemporaryDirectory();
          final fileName = 'Invoice_$invoiceId.pdf';
          final filePath = '${directory.path}/$fileName';
          
          final file = File(filePath);
          await file.writeAsBytes(response.data!);
          
          debugPrint("✅ Invoice PDF saved to: $filePath");
          
          // ✅ Use printing package to show PDF
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => response.data!,
            name: 'Invoice_$invoiceId',
          );
          
          _setSuccess('Invoice opened for printing');
          return true;
        } catch (openError) {
          debugPrint("❌ Failed to show Invoice PDF: $openError");
          _setError('Failed to show invoice: $openError');
          return false;
        }
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      debugPrint("💥 Invoice Print Error: $e");
      _setError('Error generating invoice: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

// ✅ NEW: Generate Thermal Print for Sale
  Future<bool> generateSaleThermalPrint(String saleId) async {
    _setLoading(true);
    debugPrint("🖨️ [SalesProvider] Starting Thermal Print Generation...");

    try {
      final response = await _salesService.generateSaleThermalPrint(saleId);

      if (response.success && response.data != null) {
        debugPrint("✅ Thermal print data received");
        
        // Backend returns thermal data as JSON, not PDF bytes
        // For now, show the thermal data in a dialog or save as text file
        final thermalData = response.data as Map<String, dynamic>;
        
        try {
          // Create a simple text receipt from thermal data
          final receiptText = _generateThermalTextReceipt(thermalData);
          
          // Save as text file
          final directory = await getTemporaryDirectory();
          final fileName = 'Thermal_Receipt_$saleId.txt';
          final filePath = '${directory.path}/$fileName';
          
          final file = File(filePath);
          await file.writeAsString(receiptText);
          
          debugPrint("✅ Thermal receipt saved to: $filePath");
          
          // ✅ Open text file using open_file package
          await OpenFile.open(filePath);
          
          _setSuccess('Thermal receipt opened for printing');
          return true;
        } catch (openError) {
          debugPrint("❌ Failed to open thermal receipt: $openError");
          _setError('Failed to open thermal receipt: $openError');
          return false;
        }
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      debugPrint("💥 Thermal Print Error: $e");
      _setError('Error generating thermal print: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Generate thermal-style text receipt
  String _generateThermalTextReceipt(Map<String, dynamic> thermalData) {
    final receipt = thermalData['sale'];
    final items = thermalData['items'] as List;
    final company = thermalData['company'];
    
    final buffer = StringBuffer();
    
    // Company header
    buffer.writeln(company['name'] ?? 'Moon Light Events');
    buffer.writeln(company['address'] ?? '');
    buffer.writeln(company['phone'] ?? '');
    buffer.writeln('' + '=' * 40);
    
    // Receipt details
    buffer.writeln('Invoice: ${receipt['invoice_number']}');
    buffer.writeln('Date: ${receipt['date_of_sale']}');
    buffer.writeln('Customer: ${receipt['customer_name']}');
    if (receipt['customer_phone'] != null && receipt['customer_phone'].isNotEmpty) {
      buffer.writeln('Phone: ${receipt['customer_phone']}');
    }
    buffer.writeln('' + '-' * 40);
    
    // Table header
    buffer.writeln('Item        Qty  Price   Total');
    buffer.writeln('' + '-' * 40);
    
    // Items
    for (var item in items) {
      final itemName = item['name'] as String;
      final quantity = item['quantity'] as int;
      final unitPrice = item['unit_price'] as double;
      final total = item['total'] as double;
      
      // Item name (truncate if too long)
      String displayName = itemName.length > 10 ? itemName.substring(0, 10) : itemName;
      buffer.writeln('$displayName${' ' * (10 - displayName.length)}${quantity.toString().padLeft(3)}  ${unitPrice.toStringAsFixed(0).padLeft(5)}  ${total.toStringAsFixed(0).padLeft(5)}');
      
      // If item name was truncated, show the rest on next line
      if (itemName.length > 10) {
        String remainingName = itemName.substring(10);
        if (remainingName.length > 40) {
          remainingName = remainingName.substring(0, 40);
        }
        buffer.writeln(remainingName);
      }
    }
    
    buffer.writeln('' + '-' * 40);
    
    // Totals
    buffer.writeln('Subtotal:'.padRight(17) + receipt['subtotal'].toStringAsFixed(0).padLeft(6));
    
    if (receipt['overall_discount'] > 0) {
      buffer.writeln('Discount:'.padRight(17) + '-${receipt['overall_discount'].toStringAsFixed(0)}'.padLeft(6));
    }
    
    if (receipt['tax_amount'] > 0) {
      buffer.writeln('Tax:'.padRight(17) + receipt['tax_amount'].toStringAsFixed(0).padLeft(6));
    }
    
    // Double line for total
    buffer.writeln('' + '=' * 40);
    
    // Grand Total (larger font simulation)
    buffer.writeln('TOTAL:'.padRight(17) + receipt['grand_total'].toStringAsFixed(0).padLeft(6));
    
    // Double line for total
    buffer.writeln('' + '=' * 40);
    
    // Payment info
    buffer.writeln('Payment: ${receipt['payment_method']}');
    buffer.writeln('Paid:'.padRight(17) + receipt['amount_paid'].toStringAsFixed(0).padLeft(6));
    
    if (receipt['remaining_amount'] > 0) {
      buffer.writeln('Due:'.padRight(17) + receipt['remaining_amount'].toStringAsFixed(0).padLeft(6));
    }
    
    buffer.writeln('' + '-' * 40);
    
    // Footer
    buffer.writeln('Thank you for shopping!');
    buffer.writeln('No Return / Exchange without receipt');
    buffer.writeln('Visit us again!');
    
    return buffer.toString();
  }

  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _successMessage = null;
    notifyListeners();
  }
}