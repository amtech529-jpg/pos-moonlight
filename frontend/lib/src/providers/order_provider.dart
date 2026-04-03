import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order/order_model.dart';
import '../models/order/order_api_responses.dart';
import '../models/order/order_item_model.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  List<OrderModel> _filteredOrders = [];
  String _searchQuery = '';
  String? _currentStatusFilter;
  bool _isLoading = false;
  String? _errorMessage;
  OrderStatisticsResponse? _statistics;

  // Pagination support
  int _currentPage = 1;
  int _pageSize = 20;
  int _totalCount = 0;

  // Sorting support
  String _sortBy = 'created_at';
  bool _sortAscending = false;

  // Getters
  List<OrderModel> get orders => _filteredOrders;
  List<OrderModel> get allOrders => _orders;
  String get searchQuery => _searchQuery;
  String? get currentStatusFilter => _currentStatusFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  OrderStatisticsResponse? get statistics => _statistics;

  // Pagination getters
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => _pageSize > 0 ? (_totalCount / _pageSize).ceil() : 0;

  // Sorting getters
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Pagination info object for the table
  PaginationInfo? get paginationInfo {
    if (_totalCount == 0) return null;
    return PaginationInfo(
      currentPage: _currentPage,
      pageSize: _pageSize,
      totalCount: _totalCount,
      totalPages: totalPages,
      hasNext: _currentPage < totalPages,
      hasPrevious: _currentPage > 1,
    );
  }

  // Computed properties
  Map<String, int> get orderStats {
    final total = _orders.length;
    final pending = _orders.where((order) => order.status == OrderStatus.PENDING).length;
    final inProgress = _orders.where((order) => order.status == OrderStatus.CONFIRMED).length;
    final completed = _orders.where((order) => order.status == OrderStatus.DELIVERED || order.status == OrderStatus.READY || order.status == OrderStatus.RETURNED).length;
    final cancelled = _orders.where((order) => order.status == OrderStatus.CANCELLED).length;

    return {'total': total, 'pending': pending, 'inProgress': inProgress, 'completed': completed, 'cancelled': cancelled};
  }

  OrderProvider() {
    // Load cached data first, then refresh from API
    _initializeFromCache();
    _loadOrders();
    _loadStatistics();
  }

  /// Initialize from cached data if available
  Future<void> _initializeFromCache() async {
    try {
      final cachedOrders = await OrderService().getCachedOrders();
      if (cachedOrders.isNotEmpty) {
        _orders = cachedOrders;
        _totalCount = _orders.length;
        _applySearchAndFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load cached orders: $e');
    }
  }

  // ✅ ADDED: Public method to load orders (Fixed the error)
  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _orders.clear();
    }
    await _loadOrders();
  }

  /// Load orders from API
  Future<void> _loadOrders() async {
    _setLoading(true);
    _clearError();

    debugPrint('OrderProvider: Starting to load orders from API...');

    try {
      // Create parameters for API call
      final params = OrderListParams(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _currentStatusFilter,
        sortBy: _getApiSortKey(_sortBy),
        sortOrder: _sortAscending ? 'asc' : 'desc',
      );

      final response = await OrderService().getOrders(params: params);

      if (response.success && response.data != null) {
        final ordersResponse = response.data!;
        
        if (_currentPage == 1) {
          _orders = ordersResponse.orders;
        } else {
          _orders.addAll(ordersResponse.orders);
        }

        // Update pagination info from API response
        if (ordersResponse.pagination != null) {
          _currentPage = ordersResponse.pagination.currentPage;
          _pageSize = ordersResponse.pagination.pageSize;
          _totalCount = ordersResponse.pagination.totalCount;
        } else {
          // Fallback to local pagination if API doesn't provide pagination
          if (_currentPage == 1) _totalCount = _orders.length;
        }

        _filteredOrders = List.from(_orders);
        _setLoading(false);
        notifyListeners();
      } else {
        _setError(response.message ?? 'Failed to load orders');
        _setLoading(false);
        notifyListeners();
      }
    } catch (e) {
      _setError('Error loading orders: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load order statistics from API
  Future<void> _loadStatistics() async {
    try {
      final response = await OrderService().getOrderStatistics();

      if (response.success && response.data != null) {
        final statistics = response.data;
        if (statistics != null) {
          _statistics = statistics;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load order statistics: $e');
    }
  }

  /// Refresh orders from API
  Future<void> refreshOrders() async {
    await _loadOrders();
    await _loadStatistics();
  }

  /// Manually refresh data
  Future<void> refreshData() async {
    _setLoading(true);
    notifyListeners();

    try {
      await _loadOrders();
      await _loadStatistics();
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Export order data for external use
  Map<String, dynamic> exportOrderData() {
    return {
      'total_orders': _orders.length,
      'total_amount': _orders.fold(0.0, (sum, order) => sum + order.totalAmount),
      'pending_orders': _orders.where((order) => order.status == OrderStatus.PENDING).length,
      'in_progress_orders': _orders.where((order) => order.status == OrderStatus.CONFIRMED).length,
      'completed_orders': _orders.where((order) => order.status == OrderStatus.DELIVERED || order.status == OrderStatus.READY || order.status == OrderStatus.RETURNED).length,
      'orders': _orders.map((order) => order.toJson()).toList(),
    };
  }

  /// Create a new order
  Future<bool> createOrder({
    required String customer,
    required List<OrderItemModel> items,
    required double advancePayment,
    required DateTime dateOrdered,
    required DateTime expectedDeliveryDate,
    String? eventName,
    String? eventLocation,
    DateTime? eventDate,
    DateTime? returnDate,
    required String description,
    required String status,
  }) async {
    _setLoading(true);
    _clearError();
    notifyListeners();

    try {
      final response = await OrderService().createOrder(
        customer: customer,
        items: items,
        advancePayment: advancePayment,
        dateOrdered: dateOrdered,
        expectedDeliveryDate: expectedDeliveryDate,
        eventName: eventName,
        eventLocation: eventLocation,
        eventDate: eventDate,
        returnDate: returnDate,
        description: description,
        status: status,
      );

      if (response.success && response.data != null) {
        // Reload orders from server to get fresh data with correct pagination
        _setLoading(false);
        notifyListeners();
        
        // Refresh both statistics and orders list
        await _loadStatistics();
        await _loadOrders();
        return true;
      } else {
        _setError(response.message ?? 'Failed to create order');
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setError('Failed to create order: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Timer? _searchTimer;

  /// Search orders
  Future<void> searchOrders(String query) async {
    _searchQuery = query;
    _currentPage = 1; // Reset to first page when searching
    
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _loadOrders(); // Reload from API with search query
    });
  }

  /// Filter orders by status
  Future<void> filterOrdersByStatus(String? status) async {
    _currentStatusFilter = status;
    _currentPage = 1; // Reset to first page when filtering
    await _loadOrders(); // Reload from API with status filter
  }

  /// Update an existing order
  Future<bool> updateOrder({
    required String id,
    required double advancePayment,
    DateTime? expectedDeliveryDate,
    required String description,
    required String status,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderService().updateOrder(
        id: id,
        advancePayment: advancePayment,
        expectedDeliveryDate: expectedDeliveryDate,
        description: description,
        status: status,
      );

      if (response.success && response.data != null) {
        final index = _orders.indexWhere((order) => order.id == id);
        if (index != -1) {
          _orders[index] = response.data!;
          _applySearchAndFilters();
        }

        _setLoading(false);
        notifyListeners();

        // Refresh statistics
        await _loadStatistics();

        return true;
      } else {
        _setError(response.message ?? 'Failed to update order');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Delete an order
  Future<bool> deleteOrder(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderService().deleteOrder(id);

      if (response.success) {
        _orders.removeWhere((order) => order.id == id);
        _totalCount = _orders.length;
        _applySearchAndFilters();
        _setLoading(false);
        notifyListeners();

        // Refresh statistics
        await _loadStatistics();

        return true;
      } else {
        _setError(response.message ?? 'Failed to delete order');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Duplicate an existing order
  Future<bool> duplicateOrder(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderService().duplicateOrder(id);

      if (response.success && response.data != null) {
        // Refresh orders
        await _loadOrders();
        await _loadStatistics();
        
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to duplicate order');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Soft delete an order
  Future<bool> softDeleteOrder(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderService().softDeleteOrder(id);

      if (response.success) {
        final index = _orders.indexWhere((order) => order.id == id);
        if (index != -1) {
          _orders[index] = _orders[index].copyWith(isActive: false);
          _applySearchAndFilters();
        }

        _setLoading(false);
        notifyListeners();

        // Refresh statistics
        await _loadStatistics();

        return true;
      } else {
        _setError(response.message ?? 'Failed to soft delete order');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Restore a soft-deleted order
  Future<bool> restoreOrder(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderService().restoreOrder(id);

      if (response.success) {
        final index = _orders.indexWhere((order) => order.id == id);
        if (index != -1) {
          _orders[index] = _orders[index].copyWith(isActive: true);
          _applySearchAndFilters();
        }

        _setLoading(false);
        notifyListeners();

        // Refresh statistics
        await _loadStatistics();

        return true;
      } else {
        _setError(response.message ?? 'Failed to restore order');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String status, {String? notes}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderService().updateOrderStatus(orderId, status, notes: notes);

      if (response.success) {
        final index = _orders.indexWhere((order) => order.id == orderId);
        if (index != -1) {
          final currentOrder = _orders[index];
          OrderStatus newStatus;

          switch (status.toLowerCase()) {
            case 'pending':
              newStatus = OrderStatus.PENDING;
              break;
            case 'confirmed':
              newStatus = OrderStatus.CONFIRMED;
              break;
            case 'ready':
              newStatus = OrderStatus.READY;
              break;
            case 'delivered':
              newStatus = OrderStatus.DELIVERED;
              break;
            case 'cancelled':
              newStatus = OrderStatus.CANCELLED;
              break;
            case 'returned':
              newStatus = OrderStatus.RETURNED;
              break;
            default:
              newStatus = OrderStatus.PENDING;
          }

          _orders[index] = currentOrder.copyWith(status: newStatus);
          _applySearchAndFilters();
        }

        _setLoading(false);
        notifyListeners();

        // Refresh statistics
        await _loadStatistics();

        return true;
      } else {
        _setError(response.message ?? 'Failed to update order status');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Add payment to an order
  Future<bool> addOrderPayment(String orderId, double amount) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderService().addOrderPayment(orderId, amount);

      if (response.success) {
        // Refresh orders to get updated payment information
        await _loadOrders();
        await _loadStatistics();

        return true;
      } else {
        _setError(response.message ?? 'Failed to add payment');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Generate invoice for an order
  Future<Map<String, dynamic>?> generateInvoice(String orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderService().generateInvoice(orderId);

      if (response.success && response.data != null) {
        _setLoading(false);
        return response.data;
      } else {
        _setError(response.message ?? 'Failed to generate invoice');
        _setLoading(false);
        return null;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  /// Get valid next statuses for an order
  List<OrderStatus> getValidNextStatuses(OrderModel order) {
    switch (order.status) {
      case OrderStatus.PENDING:
        return [OrderStatus.CONFIRMED, OrderStatus.CANCELLED];
      case OrderStatus.CONFIRMED:
        return [OrderStatus.READY, OrderStatus.CANCELLED];
      case OrderStatus.READY:
        return [OrderStatus.DELIVERED, OrderStatus.CANCELLED];
      case OrderStatus.DELIVERED:
        return []; // OrderStatus.RETURNED removed as per user request. Use Return & Tally module.
      case OrderStatus.RETURNED:
        return [];
      case OrderStatus.CANCELLED:
        return [];
    }
  }

  /// Check if a status transition is valid
  bool isValidStatusTransition(OrderModel order, OrderStatus newStatus) {
    final validNextStatuses = getValidNextStatuses(order);
    return validNextStatuses.contains(newStatus) || newStatus == order.status;
  }

  // Pagination methods
  Future<void> loadNextPage() async {
    if (_currentPage < totalPages) {
      _currentPage++;
      await _loadOrders(); // Reload from API with new page
    }
  }

  Future<void> loadPreviousPage() async {
    if (_currentPage > 1) {
      _currentPage--;
      await _loadOrders(); // Reload from API with new page
    }
  }

  Future<void> goToPage(int page) async {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      await _loadOrders(); // Reload from API with new page
    }
  }

  // Sorting methods
  Future<void> setSortBy(String sortKey) async {
    if (_sortBy == sortKey) {
      // Toggle sort direction if same column
      _sortAscending = !_sortAscending;
    } else {
      // New column, default to ascending
      _sortBy = sortKey;
      _sortAscending = true;
    }

    _currentPage = 1; // Reset to first page when sorting
    await _loadOrders(); // Reload from API with new sorting
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Apply search and filters (for local operations only)
  void _applySearchAndFilters({String? status}) {
    _filteredOrders = List.from(_orders);
  }

  /// Get order by ID
  OrderModel? getOrderById(String id) {
    try {
      return _orders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get orders by customer ID
  List<OrderModel> getOrdersByCustomer(String customerId) {
    return _orders.where((order) => order.customerId == customerId).toList();
  }

  /// Get orders by status
  List<OrderModel> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  /// Get overdue orders
  List<OrderModel> getOverdueOrders() {
    return _orders.where((order) => order.isOverdue).toList();
  }

  /// Get pending orders
  List<OrderModel> getPendingOrders() {
    return _orders.where((order) => order.status == OrderStatus.PENDING).toList();
  }

  /// Get recent orders (last 7 days)
  List<OrderModel> getRecentOrders() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _orders.where((order) => order.dateOrdered.isAfter(weekAgo)).toList();
  }

  /// Clear search and filters
  Future<void> clearFilters() async {
    _searchQuery = '';
    _currentStatusFilter = null;
    _currentPage = 1;
    await _loadOrders(); // Reload from API with cleared filters
  }

  /// Convert internal sort key to API sort key
  String _getApiSortKey(String internalKey) {
    switch (internalKey) {
      case 'id':
        return 'id';
      case 'total_amount':
        return 'total_amount';
      case 'expected_delivery_date':
        return 'expected_delivery_date';
      case 'dateOrdered':
      default:
        return 'created_at';
    }
  }
}