import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order/order_item_model.dart';
import '../models/api_response.dart';
import '../models/order/order_api_responses.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class OrderItemService {
  static const String _baseUrl = '/order-items/';
  static const String _cacheKey = 'cached_order_items';
  static const Duration _cacheExpiry = Duration(hours: 1);

  final ApiClient _apiClient = ApiClient();

  /// Get order items from API
  Future<ApiResponse<OrderItemsListResponse>> getOrderItems({
    String? orderId,
    String? productId,
    int page = 1,
    String? search,
    int pageSize = 20,
  }) async {
    try {
      final Map<String, String> queryParams = {'page': page.toString(), 'page_size': pageSize.toString()};

      if (orderId != null) {
        queryParams['order_id'] = orderId;
      }

      if (productId != null) {
        queryParams['product_id'] = productId;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _apiClient.get(_baseUrl, queryParameters: queryParams);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final orderItemsData = responseData['data'] as Map<String, dynamic>;
          final orderItemsResponse = OrderItemsListResponse.fromJson(orderItemsData);

          // Cache the response
          await _cacheOrderItems(orderItemsResponse.orderItems);

          return ApiResponse<OrderItemsListResponse>(success: true, data: orderItemsResponse, message: 'Order items loaded successfully');
        } else {
          return ApiResponse<OrderItemsListResponse>(success: false, message: responseData['message'] ?? 'Failed to load order items');
        }
      } else {
        return ApiResponse<OrderItemsListResponse>(success: false, message: 'Failed to load order items: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<OrderItemsListResponse>(success: false, message: 'Error loading order items: ${e.toString()}');
    }
  }

  /// Get order items with advanced filtering
  Future<ApiResponse<OrderItemsListResponse>> getOrderItemsWithFilters({
    String? orderId,
    String? productId,
    int page = 1,
    String? search,
    int pageSize = 20,
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
    try {
      final Map<String, String> queryParams = {'page': page.toString(), 'page_size': pageSize.toString()};

      if (orderId != null) {
        queryParams['order_id'] = orderId;
      }

      if (productId != null) {
        queryParams['product_id'] = productId;
      }

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (minQuantity != null) {
        queryParams['min_quantity'] = minQuantity.toString();
      }

      if (maxQuantity != null) {
        queryParams['max_quantity'] = maxQuantity.toString();
      }

      if (minPrice != null) {
        queryParams['min_price'] = minPrice.toString();
      }

      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice.toString();
      }

      if (hasCustomization != null) {
        queryParams['has_customization'] = hasCustomization.toString();
      }

      if (showInactive != null) {
        queryParams['show_inactive'] = showInactive.toString();
      }

      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String();
      }

      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String();
      }

      if (sortBy != null) {
        queryParams['sort_by'] = sortBy;
      }

      if (sortOrder != null) {
        queryParams['sort_order'] = sortOrder;
      }

      final response = await _apiClient.get(_baseUrl, queryParameters: queryParams);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final orderItemsData = responseData['data'] as Map<String, dynamic>;
          final orderItemsResponse = OrderItemsListResponse.fromJson(orderItemsData);

          // Cache the response
          await _cacheOrderItems(orderItemsResponse.orderItems);

          return ApiResponse<OrderItemsListResponse>(success: true, data: orderItemsResponse, message: 'Order items loaded successfully');
        } else {
          return ApiResponse<OrderItemsListResponse>(success: false, message: responseData['message'] ?? 'Failed to load order items');
        }
      } else {
        return ApiResponse<OrderItemsListResponse>(success: false, message: 'Failed to load order items: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<OrderItemsListResponse>(success: false, message: 'Error loading order items: ${e.toString()}');
    }
  }

  /// Get a single order item by ID
  Future<ApiResponse<OrderItemModel>> getOrderItem(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getOrderItemById(id));

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final orderItem = OrderItemModel.fromJson(responseData['data'] as Map<String, dynamic>);
          return ApiResponse<OrderItemModel>(success: true, data: orderItem, message: 'Order item loaded successfully');
        } else {
          return ApiResponse<OrderItemModel>(success: false, message: responseData['message'] ?? 'Failed to load order item');
        }
      } else {
        return ApiResponse<OrderItemModel>(success: false, message: 'Failed to load order item: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<OrderItemModel>(success: false, message: 'Error loading order item: ${e.toString()}');
    }
  }

  /// Create a new order item
  Future<ApiResponse<OrderItemModel>> createOrderItem({
    required String orderId,
    required String productId,
    required int quantity,
    required double unitPrice,
    String? customizationNotes,
  }) async {
    try {
      final Map<String, dynamic> requestData = {'order': orderId, 'product': productId, 'quantity': quantity, 'unit_price': unitPrice.toString()};

      // Always send customization notes, even if empty
      requestData['customization_notes'] = customizationNotes ?? '';
      // Also try alternative field names for compatibility
      requestData['notes'] = customizationNotes ?? '';
      requestData['description'] = customizationNotes ?? '';
      requestData['comment'] = customizationNotes ?? '';
      requestData['remarks'] = customizationNotes ?? '';

      final response = await _apiClient.post(ApiConfig.createOrderItem, data: requestData);

      if (response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final orderItem = OrderItemModel.fromJson(responseData['data'] as Map<String, dynamic>);

          // Update cache
          await _addToCache(orderItem);

          return ApiResponse<OrderItemModel>(success: true, data: orderItem, message: 'Order item created successfully');
        } else {
          return ApiResponse<OrderItemModel>(success: false, message: responseData['message'] ?? 'Failed to create order item');
        }
      } else {
        final errorData = response.data;
        return ApiResponse<OrderItemModel>(success: false, message: errorData['message'] ?? 'Failed to create order item');
      }
    } catch (e) {
      return ApiResponse<OrderItemModel>(success: false, message: 'Error creating order item: ${e.toString()}');
    }
  }

  /// Update an existing order item
  Future<ApiResponse<OrderItemModel>> updateOrderItem({required String id, int? quantity, double? unitPrice, String? customizationNotes}) async {
    try {
      final Map<String, dynamic> requestData = {};

      if (quantity != null) {
        requestData['quantity'] = quantity;
      }

      if (unitPrice != null) {
        requestData['unit_price'] = unitPrice.toString();
      }

      // Always send customization notes, even if empty
      requestData['customization_notes'] = customizationNotes ?? '';
      // Also try alternative field names for compatibility
      requestData['notes'] = customizationNotes ?? '';
      requestData['description'] = customizationNotes ?? '';
      requestData['comment'] = customizationNotes ?? '';
      requestData['remarks'] = customizationNotes ?? '';

      final response = await _apiClient.patch(ApiConfig.updateOrderItem(id), data: requestData);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final orderItem = OrderItemModel.fromJson(responseData['data'] as Map<String, dynamic>);

          // Update cache
          await _updateCache(orderItem);

          return ApiResponse<OrderItemModel>(success: true, data: orderItem, message: 'Order item updated successfully');
        } else {
          return ApiResponse<OrderItemModel>(success: false, message: responseData['message'] ?? 'Failed to update order item');
        }
      } else {
        final errorData = response.data;
        return ApiResponse<OrderItemModel>(success: false, message: errorData['message'] ?? 'Failed to update order item');
      }
    } catch (e) {
      return ApiResponse<OrderItemModel>(success: false, message: 'Error updating order item: ${e.toString()}');
    }
  }

  /// Delete an order item
  Future<ApiResponse<void>> deleteOrderItem(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteOrderItem(id));

      if (response.statusCode == 204) {
        // Remove from cache
        await _removeFromCache(id);

        return ApiResponse<void>(success: true, message: 'Order item deleted successfully');
      } else {
        return ApiResponse<void>(success: false, message: 'Failed to delete order item: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<void>(success: false, message: 'Error deleting order item: ${e.toString()}');
    }
  }

  /// Soft delete an order item
  Future<ApiResponse<void>> softDeleteOrderItem(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.softDeleteOrderItem(id));

      if (response.statusCode == 200) {
        // Update cache
        await _updateCacheStatus(id, false);

        return ApiResponse<void>(success: true, message: 'Order item soft deleted successfully');
      } else {
        return ApiResponse<void>(success: false, message: 'Failed to soft delete order item: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<void>(success: false, message: 'Error soft deleting order item: ${e.toString()}');
    }
  }

  /// Restore a soft-deleted order item
  Future<ApiResponse<void>> restoreOrderItem(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.restoreOrderItem(id));

      if (response.statusCode == 200) {
        // Update cache
        await _updateCacheStatus(id, true);

        return ApiResponse<void>(success: true, message: 'Order item restored successfully');
      } else {
        return ApiResponse<void>(success: false, message: 'Failed to restore order item: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<void>(success: false, message: 'Error restoring order item: ${e.toString()}');
    }
  }

  /// Update order item status (active/inactive)
  Future<ApiResponse<void>> updateOrderItemStatus(String id, bool isActive) async {
    try {
      String endpoint;
      if (isActive) {
        // Activate: use restore endpoint
        endpoint = ApiConfig.restoreOrderItem(id);
      } else {
        // Deactivate: use soft-delete endpoint
        endpoint = ApiConfig.softDeleteOrderItem(id);
      }

      final response = await _apiClient.post(endpoint);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          // Update cache with the updated order item data from backend
          final updatedOrderItem = OrderItemModel.fromJson(responseData['data'] as Map<String, dynamic>);
          await _updateCache(updatedOrderItem);
        } else {
          // Fallback: update cache status manually
          await _updateCacheStatus(id, isActive);
        }

        return ApiResponse<void>(success: true, message: 'Order item status updated successfully');
      } else {
        return ApiResponse<void>(success: false, message: 'Failed to update order item status: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<void>(success: false, message: 'Error updating order item status: ${e.toString()}');
    }
  }

  /// Duplicate an order item
  Future<ApiResponse<OrderItemModel>> duplicateOrderItem(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.duplicateOrderItem(id));

      if (response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final orderItem = OrderItemModel.fromJson(responseData['data'] as Map<String, dynamic>);

          // Add to cache
          await _addToCache(orderItem);

          return ApiResponse<OrderItemModel>(success: true, message: 'Order item duplicated successfully', data: orderItem);
        } else {
          return ApiResponse<OrderItemModel>(success: false, message: responseData['message'] ?? 'Failed to duplicate order item');
        }
      } else {
        return ApiResponse<OrderItemModel>(success: false, message: 'Failed to duplicate order item: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse<OrderItemModel>(success: false, message: 'Error duplicating order item: ${e.toString()}');
    }
  }

  /// Get order items for a specific order
  Future<ApiResponse<OrderItemsListResponse>> getOrderItemsByOrder(String orderId) async {
    return getOrderItems(orderId: orderId);
  }

  /// Get order items for a specific product
  Future<ApiResponse<OrderItemsListResponse>> getOrderItemsByProduct(String productId) async {
    return getOrderItems(productId: productId);
  }

  /// Search order items
  Future<ApiResponse<OrderItemsListResponse>> searchOrderItems(String query) async {
    return getOrderItems(search: query);
  }

  // Caching methods
  Future<void> _cacheOrderItems(List<OrderItemModel> orderItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': orderItems.map((item) => item.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0', // Cache version for future migrations
        'count': orderItems.length,
      };
      await prefs.setString(_cacheKey, json.encode(cacheData));
    } catch (e) {
      // Cache failure shouldn't break the app
      print('Failed to cache order items: $e');
    }
  }

  Future<List<OrderItemModel>> getCachedOrderItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_cacheKey);

      if (cachedString != null) {
        final cacheData = json.decode(cachedString);

        // Validate cache structure
        if (cacheData['data'] == null || cacheData['timestamp'] == null) {
          await clearCache(); // Clear invalid cache
          return [];
        }

        final timestamp = cacheData['timestamp'] as int;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

        // Check if cache is still valid
        if (DateTime.now().difference(cacheTime) < _cacheExpiry) {
          final itemsData = cacheData['data'] as List;

          // Validate data integrity
          try {
            final orderItems = itemsData.map((item) => OrderItemModel.fromJson(item)).toList();

            // Verify cache count matches actual data
            if (cacheData['count'] != null && orderItems.length != cacheData['count']) {
              print('Cache count mismatch, clearing cache');
              await clearCache();
              return [];
            }

            return orderItems;
          } catch (parseError) {
            print('Failed to parse cached data: $parseError');
            await clearCache(); // Clear corrupted cache
            return [];
          }
        } else {
          print('Cache expired, clearing old data');
          await clearCache(); // Clear expired cache
        }
      }
    } catch (e) {
      print('Failed to load cached order items: $e');
      await clearCache(); // Clear corrupted cache
    }

    return [];
  }

  Future<void> _addToCache(OrderItemModel orderItem) async {
    try {
      final cachedItems = await getCachedOrderItems();
      cachedItems.insert(0, orderItem);
      await _cacheOrderItems(cachedItems);
    } catch (e) {
      print('Failed to add order item to cache: $e');
    }
  }

  Future<void> _updateCache(OrderItemModel orderItem) async {
    try {
      final cachedItems = await getCachedOrderItems();
      final index = cachedItems.indexWhere((item) => item.id == orderItem.id);
      if (index != -1) {
        cachedItems[index] = orderItem;
        await _cacheOrderItems(cachedItems);
      }
    } catch (e) {
      print('Failed to update order item in cache: $e');
    }
  }

  Future<void> _removeFromCache(String id) async {
    try {
      final cachedItems = await getCachedOrderItems();
      cachedItems.removeWhere((item) => item.id == id);
      await _cacheOrderItems(cachedItems);
    } catch (e) {
      print('Failed to remove order item from cache: $e');
    }
  }

  Future<void> _updateCacheStatus(String id, bool isActive) async {
    try {
      final cachedItems = await getCachedOrderItems();
      final index = cachedItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        cachedItems[index] = cachedItems[index].copyWith(isActive: isActive);
        await _cacheOrderItems(cachedItems);
      }
    } catch (e) {
      print('Failed to update order item status in cache: $e');
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      print('Failed to clear cache: $e');
    }
  }

  /// Get cache information
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_cacheKey);

      if (cachedString != null) {
        final cacheData = json.decode(cachedString);
        final timestamp = cacheData['timestamp'] as int;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final isExpired = DateTime.now().difference(cacheTime) >= _cacheExpiry;
        final timeUntilExpiry = _cacheExpiry - DateTime.now().difference(cacheTime);

        return {
          'exists': true,
          'timestamp': cacheTime.toIso8601String(),
          'age': DateTime.now().difference(cacheTime).inMinutes,
          'is_expired': isExpired,
          'time_until_expiry': isExpired ? 0 : timeUntilExpiry.inMinutes,
          'count': cacheData['count'] ?? 0,
          'version': cacheData['version'] ?? 'unknown',
          'size_bytes': cachedString.length,
        };
      } else {
        return {
          'exists': false,
          'timestamp': null,
          'age': null,
          'is_expired': null,
          'time_until_expiry': null,
          'count': 0,
          'version': null,
          'size_bytes': 0,
        };
      }
    } catch (e) {
      return {
        'exists': false,
        'error': e.toString(),
        'timestamp': null,
        'age': null,
        'is_expired': null,
        'time_until_expiry': null,
        'count': 0,
        'version': null,
        'size_bytes': 0,
      };
    }
  }
}
