import 'package:flutter/material.dart';
import 'dart:async';
import '../models/order/order_item_model.dart';
import '../models/order/order_api_responses.dart';
import '../services/order_item_service.dart';

class OrderItemProvider extends ChangeNotifier {
  List<OrderItemModel> _orderItems = [];
  List<OrderItemModel> _filteredOrderItems = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _searchDebounceTimer;

  // Filtering and pagination
  String? _currentOrderId;
  String? _currentProductId;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = false;
  bool _showInactive = false; // Add show inactive filter

  // Sorting support
  String _sortBy = 'created_at';
  bool _sortAscending = false;

  // Getters
  List<OrderItemModel> get orderItems => _filteredOrderItems;
  List<OrderItemModel> get allOrderItems => _orderItems;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentOrderId => _currentOrderId;
  String? get currentProductId => _currentProductId;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _hasMore;
  bool get showInactive => _showInactive; // Add getter for showInactive

  // Sorting getters
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  // Pagination info object for the table
  PaginationInfo? get paginationInfo {
    if (_orderItems.isEmpty) return null;
    return PaginationInfo(
      currentPage: _currentPage,
      pageSize: 20, // Default page size
      totalCount: _orderItems.length,
      totalPages: _totalPages,
      hasNext: _currentPage < _totalPages,
      hasPrevious: _currentPage > 1,
    );
  }

  // Computed properties
  double get totalValue => _orderItems.fold(0.0, (sum, item) => sum + item.lineTotal);
  int get totalQuantity => _orderItems.fold(0, (sum, item) => sum + item.quantity);

  Map<String, int> get orderItemStats {
    final total = _orderItems.length;
    final active = _orderItems.where((item) => item.isActive).length;
    final inactive = _orderItems.where((item) => !item.isActive).length;
    final withCustomization = _orderItems.where((item) => item.customizationNotes.isNotEmpty).length;

    return {'total': total, 'active': active, 'inactive': inactive, 'withCustomization': withCustomization};
  }

  OrderItemProvider() {
    _initializeFromCache();
  }

  /// Initialize from cached data if available
  Future<void> _initializeFromCache() async {
    try {
      final cachedItems = await OrderItemService().getCachedOrderItems();
      if (cachedItems.isNotEmpty) {
        _orderItems = cachedItems;
        _filteredOrderItems = List.from(_orderItems);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load cached order items: $e');
    }
  }

  /// Load order items from API
  Future<void> loadOrderItems({String? orderId, String? productId, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = false;
    }

    if (_isLoading && !refresh) return;

    _setLoading(true);
    _clearError();

    try {
      final response = await OrderItemService().getOrderItems(orderId: orderId, productId: productId, page: _currentPage, search: _searchQuery);

      if (response.success && response.data != null) {
        final data = response.data;
        if (data != null) {
          _totalPages = data.pagination.totalPages;
          _hasMore = _currentPage < _totalPages;
        }

        if (refresh || _currentPage == 1) {
          if (data?.orderItems != null) {
            _orderItems = data!.orderItems!;
          }
        } else {
          if (data?.orderItems != null) {
            _orderItems.addAll(data!.orderItems!);
          }
        }

        _filteredOrderItems = List.from(_orderItems);
        _currentOrderId = orderId;
        _currentProductId = productId;
        _hasMore = _currentPage < _totalPages;

        _setLoading(false);
        notifyListeners();
      } else {
        _setError(response.message ?? 'Failed to load order items');
        _setLoading(false);
        notifyListeners();
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load order items with advanced filters from API
  Future<void> loadOrderItemsWithFilters({
    String? orderId,
    String? productId,
    bool refresh = false,
    String? search,
    int? minQuantity,
    int? maxQuantity,
    double? minPrice,
    double? maxPrice,
    bool? hasCustomization,
    bool? showInactive,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sortBy,
    String? sortOrder,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = false;
    }

    if (_isLoading && !refresh) return;

    _setLoading(true);
    _clearError();

    try {
      final response = await OrderItemService().getOrderItemsWithFilters(
        orderId: orderId,
        productId: productId,
        page: _currentPage,
        search: search ?? _searchQuery,
        minQuantity: minQuantity,
        maxQuantity: maxQuantity,
        minPrice: minPrice,
        maxPrice: maxPrice,
        hasCustomization: hasCustomization,
        showInactive: showInactive,
        dateFrom: dateFrom,
        dateTo: dateTo,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      if (response.success && response.data != null) {
        final data = response.data;
        if (data != null) {
          _totalPages = data.pagination.totalPages;
          _hasMore = _currentPage < _totalPages;
        }

        if (refresh || _currentPage == 1) {
          if (data?.orderItems != null) {
            _orderItems = data!.orderItems!;
          }
        } else {
          if (data?.orderItems != null) {
            _orderItems.addAll(data!.orderItems!);
          }
        }

        _filteredOrderItems = List.from(_orderItems);
        _currentOrderId = orderId;
        _currentProductId = productId;
        if (search != null) _searchQuery = search;
        _hasMore = _currentPage < _totalPages;

        _setLoading(false);
        notifyListeners();
      } else {
        _setError(response.message ?? 'Failed to load order items');
        _setLoading(false);
        notifyListeners();
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Load more order items (pagination)
  Future<void> loadMoreOrderItems() async {
    if (_isLoading || !_hasMore) return;

    _currentPage++;
    await loadOrderItems(orderId: _currentOrderId, productId: _currentProductId, refresh: false);
  }

  /// Create a new order item
  Future<bool> createOrderItem({
    required String orderId,
    required String productId,
    required int quantity,
    required double unitPrice,
    String? customizationNotes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderItemService().createOrderItem(
        orderId: orderId,
        productId: productId,
        quantity: quantity,
        unitPrice: unitPrice,
        customizationNotes: customizationNotes,
      );

      if (response.success && response.data != null) {
        final orderItem = response.data;
        if (orderItem != null) {
          _orderItems.insert(0, orderItem);
          _filteredOrderItems = List.from(_orderItems);
        }
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to create order item');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Update an existing order item
  Future<bool> updateOrderItem({required String id, int? quantity, double? unitPrice, String? customizationNotes}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderItemService().updateOrderItem(
        id: id,
        quantity: quantity,
        unitPrice: unitPrice,
        customizationNotes: customizationNotes,
      );

      if (response.success && response.data != null) {
        final index = _orderItems.indexWhere((item) => item.id == id);
        if (index != -1) {
          final orderItem = response.data;
          if (orderItem != null) {
            _orderItems[index] = orderItem;
            _filteredOrderItems = List.from(_orderItems);
          }
        }

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to update order item');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Delete an order item
  Future<bool> deleteOrderItem(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderItemService().deleteOrderItem(id);

      if (response.success) {
        _orderItems.removeWhere((item) => item.id == id);
        _filteredOrderItems = List.from(_orderItems);
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to delete order item');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Soft delete an order item
  Future<bool> softDeleteOrderItem(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderItemService().softDeleteOrderItem(id);

      if (response.success) {
        final index = _orderItems.indexWhere((item) => item.id == id);
        if (index != -1) {
          _orderItems[index] = _orderItems[index].copyWith(isActive: false);
          _filteredOrderItems = List.from(_orderItems);
        }

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to soft delete order item');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Restore a soft-deleted order item
  Future<bool> restoreOrderItem(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderItemService().restoreOrderItem(id);

      if (response.success) {
        final index = _orderItems.indexWhere((item) => item.id == id);
        if (index != -1) {
          _orderItems[index] = _orderItems[index].copyWith(isActive: true);
          _filteredOrderItems = List.from(_orderItems);
        }

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to restore order item');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  /// Search order items with debouncing
  void searchOrderItemsDebounced(String query) {
    _searchQuery = query.trim();

    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Set new timer for 500ms delay
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  /// Perform the actual search
  Future<void> _performSearch() async {
    _currentPage = 1; // Reset to first page when searching

    if (_searchQuery.isEmpty) {
      // If search is empty, load all items
      await loadOrderItemsWithFilters(
        orderId: _currentOrderId,
        productId: _currentProductId,
        refresh: true,
        search: null,
        showInactive: _showInactive,
      );
    } else {
      // Perform backend search
      await loadOrderItemsWithFilters(
        orderId: _currentOrderId,
        productId: _currentProductId,
        refresh: true,
        search: _searchQuery,
        showInactive: _showInactive,
      );
    }
  }

  /// Search order items immediately (without debouncing)
  Future<void> searchOrderItems(String query) async {
    _searchQuery = query.trim();
    await _performSearch();
  }

  /// Filter order items by order
  void filterByOrder(String orderId) {
    _currentOrderId = orderId;
    _filteredOrderItems = _orderItems.where((item) => item.orderId == orderId).toList();
    notifyListeners();
  }

  /// Filter order items by product
  void filterByProduct(String productId) {
    _currentProductId = productId;
    _filteredOrderItems = _orderItems.where((item) => item.productId == productId).toList();
    notifyListeners();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _currentOrderId = null;
    _currentProductId = null;
    _searchQuery = '';
    await loadOrderItemsWithFilters(refresh: true);
  }

  /// Clear only search filter
  Future<void> clearSearch() async {
    _searchQuery = '';
    await loadOrderItemsWithFilters(orderId: _currentOrderId, productId: _currentProductId, refresh: true, showInactive: _showInactive);
  }

  /// Update filtered items (used by filter dialog)
  void updateFilteredItems(List<OrderItemModel> filteredItems) {
    _filteredOrderItems = filteredItems;
    notifyListeners();
  }

  /// Refresh order items
  Future<void> refreshOrderItems() async {
    await loadOrderItems(orderId: _currentOrderId, productId: _currentProductId, refresh: true);
  }

  /// Load next page of order items
  Future<void> loadNextPage() async {
    if (_currentPage < _totalPages) {
      _currentPage++;
      await loadOrderItems(orderId: _currentOrderId, productId: _currentProductId, refresh: false);
    }
  }

  /// Load previous page of order items
  Future<void> loadPreviousPage() async {
    if (_currentPage > 1) {
      _currentPage--;
      await loadOrderItems(orderId: _currentOrderId, productId: _currentProductId, refresh: false);
    }
  }

  /// Set sorting parameters
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
    await loadOrderItems(orderId: _currentOrderId, productId: _currentProductId, refresh: true);
  }

  /// Toggle show inactive filter
  Future<void> toggleShowInactive() async {
    _showInactive = !_showInactive;
    _currentPage = 1; // Reset to first page when toggling filter
    await loadOrderItemsWithFilters(orderId: _currentOrderId, productId: _currentProductId, refresh: true, showInactive: _showInactive);
  }

  /// Update order item status (active/inactive)
  Future<bool> updateOrderItemStatus(String orderItemId, bool isActive) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderItemService().updateOrderItemStatus(orderItemId, isActive);

      if (response.success) {
        // Update local state immediately for better UX
        final index = _orderItems.indexWhere((item) => item.id == orderItemId);
        if (index != -1) {
          _orderItems[index] = _orderItems[index].copyWith(isActive: isActive);
          _filteredOrderItems = List.from(_orderItems);
        }

        _setLoading(false);
        notifyListeners();

        // Refresh data to ensure table shows updated state
        await loadOrderItemsWithFilters(orderId: _currentOrderId, productId: _currentProductId, refresh: true, showInactive: _showInactive);

        return true;
      } else {
        _setError(response.message ?? 'Failed to update order item status');
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Duplicate an order item
  Future<bool> duplicateOrderItem(String orderItemId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await OrderItemService().duplicateOrderItem(orderItemId);

      if (response.success && response.data != null) {
        // Add duplicated item to local state
        _orderItems.insert(0, response.data!);
        _filteredOrderItems = List.from(_orderItems);

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to duplicate order item');
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Get order items for a specific order
  List<OrderItemModel> getOrderItemsByOrder(String orderId) {
    return _orderItems.where((item) => item.orderId == orderId).toList();
  }

  /// Get order items for a specific product
  List<OrderItemModel> getOrderItemsByProduct(String productId) {
    return _orderItems.where((item) => item.productId == productId).toList();
  }

  /// Calculate total for a specific order
  double getOrderTotal(String orderId) {
    return _orderItems.where((item) => item.orderId == orderId).fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  /// Export order item data
  Map<String, dynamic> exportOrderItemData() {
    return {
      'total_items': _orderItems.length,
      'total_value': totalValue,
      'total_quantity': totalQuantity,
      'order_items': _orderItems.map((item) => item.toJson()).toList(),
    };
  }

  /// Add new order item to cache and local state
  void addOrderItemToCache(OrderItemModel orderItem) {
    _orderItems.insert(0, orderItem);
    _filteredOrderItems = List.from(_orderItems);
    notifyListeners();
  }

  /// Update existing order item in cache and local state
  void updateOrderItemInCache(OrderItemModel orderItem) {
    final index = _orderItems.indexWhere((item) => item.id == orderItem.id);
    if (index != -1) {
      _orderItems[index] = orderItem;
      _filteredOrderItems = List.from(_orderItems);
      notifyListeners();
    }
  }

  /// Remove order item from cache and local state
  void removeOrderItemFromCache(String orderItemId) {
    _orderItems.removeWhere((item) => item.id == orderItemId);
    _filteredOrderItems = List.from(_orderItems);
    notifyListeners();
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      await OrderItemService().clearCache();
      _orderItems.clear();
      _filteredOrderItems.clear();
      _currentPage = 1;
      _totalPages = 1;
      _hasMore = false;
      _currentOrderId = null;
      _currentProductId = null;
      _searchQuery = '';
      _sortBy = 'created_at';
      _sortAscending = false;
      _showInactive = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  /// Refresh cache from API
  Future<void> refreshCache() async {
    await loadOrderItemsWithFilters(orderId: _currentOrderId, productId: _currentProductId, refresh: true, showInactive: _showInactive);
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'total_cached': _orderItems.length,
      'filtered_count': _filteredOrderItems.length,
      'current_page': _currentPage,
      'total_pages': _totalPages,
      'has_more': _hasMore,
      'show_inactive': _showInactive,
      'sort_by': _sortBy,
      'sort_ascending': _sortAscending,
    };
  }

  /// Get detailed cache information from service
  Future<Map<String, dynamic>> getDetailedCacheInfo() async {
    try {
      final cacheInfo = await OrderItemService().getCacheInfo();
      final localStats = getCacheStats();

      return {
        ...cacheInfo,
        'local_stats': localStats,
        'provider_state': {'is_loading': _isLoading, 'has_error': _errorMessage != null, 'error_message': _errorMessage},
      };
    } catch (e) {
      return {'error': 'Failed to get cache info: ${e.toString()}', 'local_stats': getCacheStats()};
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String? error) {
    _errorMessage = error;
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
