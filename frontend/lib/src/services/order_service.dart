import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/order/order_api_responses.dart';
import '../models/order/order_model.dart';
import '../models/order/order_item_model.dart';
import '../utils/storage_service.dart';
import '../utils/debug_helper.dart';
import 'api_client.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get list of orders with pagination and filtering
  Future<ApiResponse<OrdersListResponse>> getOrders({OrderListParams? params}) async {
    try {
      debugPrint('OrderService: Starting getOrders API call...');
      final queryParams = params?.toQueryParameters() ?? OrderListParams().toQueryParameters();

      debugPrint('OrderService: Query parameters: $queryParams');
      debugPrint('OrderService: API endpoint: ${ApiConfig.orders}');

      final response = await _apiClient.get(ApiConfig.orders, queryParameters: queryParams);

      debugPrint('OrderService: API response received - status: ${response.statusCode}');
      DebugHelper.printApiResponse('GET Orders', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        debugPrint('OrderService: Response data keys: ${responseData.keys.toList()}');
        debugPrint('OrderService: Success flag: ${responseData['success']}');
        debugPrint('OrderService: Data field: ${responseData['data']}');

        if (responseData['success'] == true && responseData['data'] != null) {
          final ordersListData = responseData['data'] as Map<String, dynamic>;
          debugPrint('OrderService: Orders list data keys: ${ordersListData.keys.toList()}');

          final ordersListResponse = OrdersListResponse.fromJson(ordersListData);
          debugPrint('OrderService: Parsed orders count: ${ordersListResponse.orders.length}');

          // Cache orders if successful
          await _cacheOrders(ordersListResponse.orders);

          return ApiResponse<OrdersListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Orders retrieved successfully',
            data: ordersListResponse,
          );
        } else {
          debugPrint('OrderService: API call failed - success: false, message: ${responseData['message']}');
          return ApiResponse<OrdersListResponse>(
            success: false,
            message: responseData['message'] ?? 'Failed to get orders',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        debugPrint('OrderService: Non-200 status code: ${response.statusCode}');
        return ApiResponse<OrdersListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get orders',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('OrderService: DioException occurred: ${e.toString()}');
      debugPrint('OrderService: DioException type: ${e.type}');
      debugPrint('OrderService: DioException message: ${e.message}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        debugPrint('OrderService: Network error detected, trying cached data...');
        final cachedOrders = await getCachedOrders();
        debugPrint('OrderService: Cached orders count: ${cachedOrders.length}');

        if (cachedOrders.isNotEmpty) {
          return ApiResponse<OrdersListResponse>(
            success: true,
            message: 'Showing cached data',
            data: OrdersListResponse(
              orders: cachedOrders,
              pagination: PaginationInfo(
                currentPage: 1,
                pageSize: cachedOrders.length,
                totalCount: cachedOrders.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
              ),
            ),
          );
        }
      }

      return ApiResponse<OrdersListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('OrderService: Unexpected error: $e');
      DebugHelper.printError('Get orders', e);
      return ApiResponse<OrdersListResponse>(success: false, message: 'An unexpected error occurred while getting orders');
    }
  }

  /// Get a specific order by ID
  Future<ApiResponse<OrderModel>> getOrderById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getOrderById(id));

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final order = OrderModel.fromJson(responseData['data'] as Map<String, dynamic>);
          return ApiResponse<OrderModel>(success: true, message: 'Order loaded successfully', data: order);
        } else {
          return ApiResponse<OrderModel>(
            success: false,
            message: responseData['message'] ?? 'Failed to get order',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<OrderModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to get order',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get order by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<OrderModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get order by ID error: ${e.toString()}');
      return ApiResponse<OrderModel>(success: false, message: 'An unexpected error occurred while getting order');
    }
  }

  /// Create a new order
  Future<ApiResponse<OrderModel>> createOrder({
    required String customer,
    required List<OrderItemModel> items,
    required double advancePayment,
    DateTime? dateOrdered,
    DateTime? expectedDeliveryDate,
    String? eventName,
    String? eventLocation,
    DateTime? eventDate,
    DateTime? returnDate,
    required String description,
    required String status,
  }) async {
    try {
      final request = OrderCreateRequest(
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

      DebugHelper.printJson('Create Order Request', request.toJson());

      final response = await _apiClient.post(ApiConfig.createOrder, data: request.toJson());

      DebugHelper.printApiResponse('POST Create Order', response.data);

      if (response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final order = OrderModel.fromJson(responseData['data'] as Map<String, dynamic>);

          final apiResponse = ApiResponse<OrderModel>(success: true, message: responseData['message'] ?? 'Order created successfully', data: order);

          // Update cache with new order
          if (apiResponse.data != null) {
            await _addOrderToCache(apiResponse.data!);
          }

          return apiResponse;
        } else {
          return ApiResponse<OrderModel>(
            success: false,
            message: responseData['message'] ?? 'Failed to create order',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<OrderModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to create order',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Create order DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<OrderModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Create order', e);
      return ApiResponse<OrderModel>(success: false, message: 'An unexpected error occurred while creating order: ${e.toString()}');
    }
  }

  /// Update an existing order
  Future<ApiResponse<OrderModel>> updateOrder({
    required String id,
    required double advancePayment,
    DateTime? expectedDeliveryDate,
    required String description,
    required String status,
  }) async {
    try {
      final request = OrderUpdateRequest(
        advancePayment: advancePayment,
        expectedDeliveryDate: expectedDeliveryDate,
        description: description,
        status: status,
      );

      DebugHelper.printJson('Update Order Request', request.toJson());

      final response = await _apiClient.put(ApiConfig.updateOrder(id), data: request.toJson());

      DebugHelper.printApiResponse('PUT Update Order', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final order = OrderModel.fromJson(responseData['data'] as Map<String, dynamic>);

          final apiResponse = ApiResponse<OrderModel>(success: true, message: responseData['message'] ?? 'Order updated successfully', data: order);

          // Update cache with updated order
          if (apiResponse.data != null) {
            await _updateOrderInCache(apiResponse.data!);
          }

          return apiResponse;
        } else {
          return ApiResponse<OrderModel>(
            success: false,
            message: responseData['message'] ?? 'Failed to update order',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<OrderModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update order',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Update order DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<OrderModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Update order', e);
      return ApiResponse<OrderModel>(success: false, message: 'An unexpected error occurred while updating order: ${e.toString()}');
    }
  }

  /// Delete an order
  Future<ApiResponse<void>> deleteOrder(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteOrder(id));

      if (response.statusCode == 204) {
        // Remove from cache
        await _removeOrderFromCache(id);
        return ApiResponse<void>(success: true, message: 'Order deleted successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete order',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Delete order DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Delete order', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while deleting order: ${e.toString()}');
    }
  }

  /// Soft delete an order
  Future<ApiResponse<void>> softDeleteOrder(String id) async {
    try {
      final response = await _apiClient.patch(ApiConfig.softDeleteOrder(id));

      if (response.statusCode == 200) {
        // Update cache to mark as inactive
        await _updateOrderStatusInCache(id, isActive: false);
        return ApiResponse<void>(success: true, message: 'Order soft deleted successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to soft delete order',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Soft delete order DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Soft delete order', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while soft deleting order: ${e.toString()}');
    }
  }

  /// Restore a soft-deleted order
  Future<ApiResponse<void>> restoreOrder(String id) async {
    try {
      final response = await _apiClient.patch(ApiConfig.restoreOrder(id));

      if (response.statusCode == 200) {
        // Update cache to mark as active
        await _updateOrderStatusInCache(id, isActive: true);
        return ApiResponse<void>(success: true, message: 'Order restored successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to restore order',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Restore order DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Restore order', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while restoring order: ${e.toString()}');
    }
  }

  /// Search orders
  Future<ApiResponse<OrdersListResponse>> searchOrders(String query, {OrderListParams? params}) async {
    try {
      final searchParams = params?.toQueryParameters() ?? OrderListParams().toQueryParameters();
      searchParams['search'] = query;

      final response = await _apiClient.get(ApiConfig.searchOrders, queryParameters: searchParams);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final ordersListData = responseData['data'] as Map<String, dynamic>;
          final ordersListResponse = OrdersListResponse.fromJson(ordersListData);

          return ApiResponse<OrdersListResponse>(
            success: true,
            message: responseData['message'] ?? 'Orders search completed',
            data: ordersListResponse,
          );
        } else {
          return ApiResponse<OrdersListResponse>(
            success: false,
            message: responseData['message'] ?? 'Failed to search orders',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<OrdersListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to search orders',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Search orders DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<OrdersListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Search orders error: ${e.toString()}');
      return ApiResponse<OrdersListResponse>(success: false, message: 'An unexpected error occurred while searching orders');
    }
  }

  /// Get order statistics
  Future<ApiResponse<OrderStatisticsResponse>> getOrderStatistics() async {
    try {
      final response = await _apiClient.get(ApiConfig.orderStatistics);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final statistics = OrderStatisticsResponse.fromJson(responseData['data'] as Map<String, dynamic>);
          return ApiResponse<OrderStatisticsResponse>(success: true, message: 'Statistics loaded successfully', data: statistics);
        } else {
          return ApiResponse<OrderStatisticsResponse>(
            success: false,
            message: responseData['message'] ?? 'Failed to get order statistics',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<OrderStatisticsResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get order statistics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get order statistics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<OrderStatisticsResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get order statistics error: ${e.toString()}');
      return ApiResponse<OrderStatisticsResponse>(success: false, message: 'An unexpected error occurred while getting order statistics');
    }
  }

  /// Add payment to an order
  Future<ApiResponse<Map<String, dynamic>>> addOrderPayment(String orderId, double amount) async {
    try {
      final request = OrderPaymentRequest(amount: amount);

      final response = await _apiClient.post(ApiConfig.addOrderPayment(orderId), data: request.toJson());

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            message: responseData['message'] ?? 'Payment added successfully',
            data: responseData['data'] as Map<String, dynamic>? ?? {},
          );
        } else {
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: responseData['message'] ?? 'Failed to add payment',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to add payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Add order payment DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Add order payment', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while adding payment: ${e.toString()}');
    }
  }

  /// Update order status
  Future<ApiResponse<void>> updateOrderStatus(String orderId, String status, {String? notes}) async {
    try {
      final request = OrderStatusUpdateRequest(status: status, notes: notes);

      final response = await _apiClient.patch(ApiConfig.updateOrderStatus(orderId), data: request.toJson());

      if (response.statusCode == 200) {
        // Update cache with new status
        await _updateOrderStatusInCache(orderId, status: status);
        return ApiResponse<void>(success: true, message: 'Order status updated successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to update order status',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Update order status DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Update order status', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while updating order status: ${e.toString()}');
    }
  }

  /// Generate invoice data for an order
  Future<ApiResponse<Map<String, dynamic>>> generateInvoice(String orderId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.orders}$orderId/invoice/');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          return ApiResponse<Map<String, dynamic>>(
            success: true, 
            message: responseData['message'] ?? 'Invoice generated successfully',
            data: responseData['data'] as Map<String, dynamic>,
          );
        } else {
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: responseData['message'] ?? 'Failed to generate invoice',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to generate invoice',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Generate invoice DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Generate invoice', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while generating invoice: ${e.toString()}');
    }
  }

  /// Duplicate an existing order
  Future<ApiResponse<OrderModel>> duplicateOrder(String orderId) async {
    try {
      final response = await _apiClient.post(ApiConfig.duplicateOrder(orderId));

      if (response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final order = OrderModel.fromJson(responseData['data'] as Map<String, dynamic>);
          
          // Add to cache
          await _addOrderToCache(order);

          return ApiResponse<OrderModel>(
            success: true, 
            message: responseData['message'] ?? 'Order duplicated successfully', 
            data: order
          );
        } else {
          return ApiResponse<OrderModel>(
            success: false,
            message: responseData['message'] ?? 'Failed to duplicate order',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<OrderModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to duplicate order',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Duplicate order DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<OrderModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Duplicate order', e);
      return ApiResponse<OrderModel>(success: false, message: 'An unexpected error occurred while duplicating order: ${e.toString()}');
    }
  }

  // Cache management methods
  Future<void> _cacheOrders(List<OrderModel> orders) async {
    try {
      await _storageService.saveData(ApiConfig.ordersCacheKey, orders.map((order) => order.toJson()).toList());
    } catch (e) {
      debugPrint('Failed to cache orders: $e');
    }
  }

  /// Get cached orders from local storage
  Future<List<OrderModel>> getCachedOrders() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.ordersCacheKey);
      if (cachedData != null) {
        return (cachedData as List<dynamic>).map((orderJson) => OrderModel.fromJson(orderJson as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Failed to get cached orders: $e');
    }
    return [];
  }

  /// Check if there are cached orders available
  Future<bool> hasCachedOrders() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.ordersCacheKey);
      return cachedData != null && (cachedData as List).isNotEmpty;
    } catch (e) {
      debugPrint('Failed to check cached orders: $e');
      return false;
    }
  }

  /// Clear all cached orders
  Future<void> clearCache() async {
    try {
      await _storageService.removeData(ApiConfig.ordersCacheKey);
    } catch (e) {
      debugPrint('Failed to clear orders cache: $e');
    }
  }

  Future<void> _addOrderToCache(OrderModel order) async {
    try {
      final cachedOrders = await getCachedOrders();
      // Insert at the beginning so it shows at the top
      cachedOrders.insert(0, order);
      await _cacheOrders(cachedOrders);
    } catch (e) {
      debugPrint('Failed to add order to cache: $e');
    }
  }

  Future<void> _updateOrderInCache(OrderModel updatedOrder) async {
    try {
      final cachedOrders = await getCachedOrders();
      final index = cachedOrders.indexWhere((order) => order.id == updatedOrder.id);
      if (index != -1) {
        cachedOrders[index] = updatedOrder;
        await _cacheOrders(cachedOrders);
      }
    } catch (e) {
      debugPrint('Failed to update order in cache: $e');
    }
  }

  Future<void> _removeOrderFromCache(String orderId) async {
    try {
      final cachedOrders = await getCachedOrders();
      cachedOrders.removeWhere((order) => order.id == orderId);
      await _cacheOrders(cachedOrders);
    } catch (e) {
      debugPrint('Failed to remove order from cache: $e');
    }
  }

  Future<void> _updateOrderStatusInCache(String orderId, {String? status, bool? isActive}) async {
    try {
      final cachedOrders = await getCachedOrders();
      final index = cachedOrders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final order = cachedOrders[index];
        if (status != null) {
          // Update status logic here
        }
        if (isActive != null) {
          cachedOrders[index] = order.copyWith(isActive: isActive);
        }
        await _cacheOrders(cachedOrders);
      }
    } catch (e) {
      debugPrint('Failed to update order status in cache: $e');
    }
  }
}
