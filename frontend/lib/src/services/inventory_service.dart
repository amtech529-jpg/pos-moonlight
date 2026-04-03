import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../utils/debug_helper.dart';
import 'api_client.dart';

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  final ApiClient _apiClient = ApiClient();

  /// Check real-time stock availability for products
  Future<ApiResponse<List<Map<String, dynamic>>>> checkStockAvailability({required List<String> productIds}) async {
    try {
      final queryParams = {'product_ids[]': productIds};

      DebugHelper.printApiResponse('GET Check Stock Availability', {'product_ids': productIds});

      final response = await _apiClient.get(ApiConfig.checkStockAvailability, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Check Stock Availability Response', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: List<Map<String, dynamic>>.from(response.data['data'] ?? []),
          message: response.data['message'] ?? 'Stock availability checked successfully',
        );
      } else {
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          message: response.data['message'] ?? 'Failed to check stock availability',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Check stock availability DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<List<Map<String, dynamic>>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Check stock availability', e);
      return ApiResponse<List<Map<String, dynamic>>>(success: false, message: 'An unexpected error occurred while checking stock availability');
    }
  }

  /// Reserve stock for a pending sale
  Future<ApiResponse<Map<String, dynamic>>> reserveStockForSale({
    required String productId,
    required int quantity,
    required String saleId,
    int reservationDuration = 30, // minutes
  }) async {
    try {
      final request = {'product_id': productId, 'quantity': quantity, 'sale_id': saleId, 'reservation_duration': reservationDuration};

      DebugHelper.printJson('Reserve Stock Request', request);

      final response = await _apiClient.post(ApiConfig.reserveStockForSale, data: request);

      DebugHelper.printApiResponse('POST Reserve Stock Response', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'] as Map<String, dynamic>? ?? {},
          message: response.data['message'] ?? 'Stock reserved successfully',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to reserve stock',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Reserve stock DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Reserve stock', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while reserving stock');
    }
  }

  /// Confirm stock deduction after sale confirmation
  Future<ApiResponse<Map<String, dynamic>>> confirmStockDeduction({required String saleId}) async {
    try {
      final request = {'sale_id': saleId};

      DebugHelper.printJson('Confirm Stock Deduction Request', request);

      final response = await _apiClient.post(ApiConfig.confirmStockDeduction, data: request);

      DebugHelper.printApiResponse('POST Confirm Stock Deduction Response', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'] as Map<String, dynamic>? ?? {},
          message: response.data['message'] ?? 'Stock deduction confirmed successfully',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to confirm stock deduction',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Confirm stock deduction DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Confirm stock deduction', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while confirming stock deduction');
    }
  }

  /// Get low stock alerts
  Future<ApiResponse<Map<String, dynamic>>> getLowStockAlerts({int threshold = 5, bool includeOutOfStock = true}) async {
    try {
      final queryParams = {'threshold': threshold.toString(), 'include_out_of_stock': includeOutOfStock.toString()};

      DebugHelper.printApiResponse('GET Low Stock Alerts', queryParams);

      final response = await _apiClient.get(ApiConfig.getLowStockAlerts, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Low Stock Alerts Response', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'] as Map<String, dynamic>? ?? {},
          message: response.data['message'] ?? 'Low stock alerts retrieved successfully',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get low stock alerts',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Get low stock alerts DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get low stock alerts', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting low stock alerts');
    }
  }

  /// Bulk update stock quantities
  Future<ApiResponse<Map<String, dynamic>>> bulkUpdateStock({required List<Map<String, dynamic>> updates}) async {
    try {
      final request = {'updates': updates};

      DebugHelper.printJson('Bulk Update Stock Request', request);

      final response = await _apiClient.post(ApiConfig.bulkUpdateStock, data: request);

      DebugHelper.printApiResponse('POST Bulk Update Stock Response', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'] as Map<String, dynamic>? ?? {},
          message: response.data['message'] ?? 'Bulk stock update completed successfully',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to perform bulk stock update',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Bulk update stock DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Bulk update stock', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while performing bulk stock update');
    }
  }

  /// Check if product can fulfill requested quantity
  bool canFulfillQuantity({required int availableQuantity, required int requestedQuantity, int reservedQuantity = 0}) {
    final actualAvailable = availableQuantity - reservedQuantity;
    return actualAvailable >= requestedQuantity;
  }

  /// Get stock status based on quantity
  String getStockStatus({required int quantity, int minThreshold = 5, int reorderPoint = 10}) {
    if (quantity == 0) return 'OUT_OF_STOCK';
    if (quantity <= minThreshold) return 'LOW_STOCK';
    if (quantity <= reorderPoint) return 'REORDER_POINT';
    return 'IN_STOCK';
  }

  /// Get stock status color
  String getStockStatusColor(String status) {
    switch (status) {
      case 'OUT_OF_STOCK':
        return '#FF0000'; // Red
      case 'LOW_STOCK':
        return '#FFA500'; // Orange
      case 'REORDER_POINT':
        return '#FFFF00'; // Yellow
      case 'IN_STOCK':
        return '#00FF00'; // Green
      default:
        return '#808080'; // Gray
    }
  }

  /// Get stock status display text
  String getStockStatusDisplay(String status) {
    switch (status) {
      case 'OUT_OF_STOCK':
        return 'Out of Stock';
      case 'LOW_STOCK':
        return 'Low Stock';
      case 'REORDER_POINT':
        return 'Reorder Point';
      case 'IN_STOCK':
        return 'In Stock';
      default:
        return 'Unknown';
    }
  }

  /// Format quantity with appropriate units
  String formatQuantity(int quantity, {String unit = 'pcs'}) {
    if (quantity == 1) {
      return '1 $unit';
    }
    return '$quantity ${unit}s';
  }

  /// Get stock alert level
  String getStockAlertLevel({required int quantity, int minThreshold = 5}) {
    if (quantity == 0) return 'CRITICAL';
    if (quantity <= minThreshold) return 'WARNING';
    return 'NORMAL';
  }

  /// Get stock alert message
  String getStockAlertMessage({required int quantity, required String productName, int minThreshold = 5}) {
    if (quantity == 0) {
      return '$productName is out of stock';
    }
    if (quantity <= minThreshold) {
      return '$productName has low stock: $quantity remaining';
    }
    return '$productName has sufficient stock: $quantity available';
  }
}

// Helper class for API errors
class ApiError {
  final String type;
  final String displayMessage;
  final Map<String, dynamic>? errors;

  ApiError({required this.type, required this.displayMessage, this.errors});

  factory ApiError.fromDioError(DioException e) {
    String type = 'unknown_error';
    String message = 'An unknown error occurred';

    String? serverMessage;
    final data = e.response?.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data as Map);
      final dynamic raw = map['message'] ?? map['detail'] ?? map['error'];
      if (raw is String && raw.trim().isNotEmpty) {
        serverMessage = raw.trim();
      }
    }

    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.sendTimeout) {
      type = 'timeout_error';
      message = 'Request timed out. Please try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      type = 'network_error';
      message = 'Network connection error. Please check your internet connection.';
    } else if (e.response != null) {
      final statusCode = e.response!.statusCode;
      if (statusCode == 400) {
        type = 'bad_request';
        message = serverMessage ?? 'Invalid request. Please check your input.';
      } else if (statusCode == 401) {
        type = 'unauthorized';
        message = 'Unauthorized access. Please log in again.';
      } else if (statusCode == 403) {
        type = 'forbidden';
        message = 'Access forbidden. You don\'t have permission for this action.';
      } else if (statusCode == 404) {
        type = 'not_found';
        message = serverMessage ?? 'Resource not found.';
      } else if (statusCode == 500) {
        type = 'server_error';
        message = serverMessage ?? 'Server error. Please try again later.';
      } else {
        type = 'http_error';
        message = serverMessage ?? 'HTTP error $statusCode. Please try again.';
      }
    }

    return ApiError(type: type, displayMessage: message, errors: e.response?.data as Map<String, dynamic>?);
  }
}
