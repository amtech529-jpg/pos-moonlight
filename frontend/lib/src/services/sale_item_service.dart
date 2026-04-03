import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/sales/sale_model.dart';
import '../models/sales/request_models.dart';
import '../utils/storage_service.dart';
import '../utils/debug_helper.dart';
import 'api_client.dart';

class SaleItemService {
  static final SaleItemService _instance = SaleItemService._internal();
  factory SaleItemService() => _instance;
  SaleItemService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get list of sale items with filtering
  Future<ApiResponse<List<SaleItemModel>>> getSaleItems({String? saleId, String? productId, String? search, int? page, int? pageSize}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (saleId != null) queryParams['sale_id'] = saleId;
      if (productId != null) queryParams['product_id'] = productId;
      if (search != null) queryParams['search'] = search;
      if (page != null) queryParams['page'] = page.toString();
      if (pageSize != null) queryParams['page_size'] = pageSize.toString();

      debugPrint('🚀 Calling API: ${ApiConfig.saleItems}');
      debugPrint('🌐 Query params: $queryParams');

      final response = await _apiClient.get(ApiConfig.saleItems, queryParameters: queryParams);

      debugPrint('🌐 Response status: ${response.statusCode}');
      DebugHelper.printApiResponse('GET Sale Items', response.data);

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<List<SaleItemModel>>.fromJson(
          response.data,
          (data) => (data as List<dynamic>).map((item) => SaleItemModel.fromJson(item)).toList(),
        );

        // Cache sale items if successful
        if (apiResponse.success && apiResponse.data != null) {
          await _cacheSaleItems(apiResponse.data!);
        }

        return apiResponse;
      } else {
        return ApiResponse<List<SaleItemModel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get sale items',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get sale items DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedItems = await getCachedSaleItems();
        if (cachedItems.isNotEmpty) {
          return ApiResponse<List<SaleItemModel>>(success: true, message: 'Showing cached data', data: cachedItems);
        }
      }

      return ApiResponse<List<SaleItemModel>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get sale items', e);
      return ApiResponse<List<SaleItemModel>>(success: false, message: 'An unexpected error occurred while getting sale items');
    }
  }

  /// Get sale items by sale ID
  Future<ApiResponse<List<SaleItemModel>>> getSaleItemsBySale(String saleId) async {
    try {
      final response = await _apiClient.get(ApiConfig.saleItemsBySale(saleId));

      DebugHelper.printApiResponse('GET Sale Items by Sale', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<List<SaleItemModel>>.fromJson(
          response.data,
          (data) => (data['sale_items'] as List<dynamic>).map((item) => SaleItemModel.fromJson(item)).toList(),
        );
      } else {
        return ApiResponse<List<SaleItemModel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get sale items by sale',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get sale items by sale DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<List<SaleItemModel>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get sale items by sale', e);
      return ApiResponse<List<SaleItemModel>>(success: false, message: 'An unexpected error occurred while getting sale items by sale');
    }
  }

  /// Get sale items by product ID
  Future<ApiResponse<List<SaleItemModel>>> getSaleItemsByProduct(String productId) async {
    try {
      final response = await _apiClient.get(ApiConfig.saleItemsByProduct(productId));

      DebugHelper.printApiResponse('GET Sale Items by Product', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<List<SaleItemModel>>.fromJson(
          response.data,
          (data) => (data['sale_items'] as List<dynamic>).map((item) => SaleItemModel.fromJson(item)).toList(),
        );
      } else {
        return ApiResponse<List<SaleItemModel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get sale items by product',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get sale items by product DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<List<SaleItemModel>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get sale items by product', e);
      return ApiResponse<List<SaleItemModel>>(success: false, message: 'An unexpected error occurred while getting sale items by product');
    }
  }

  /// Get a specific sale item by ID
  Future<ApiResponse<SaleItemModel>> getSaleItemById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getSaleItemById(id));

      DebugHelper.printApiResponse('GET Sale Item by ID', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<SaleItemModel>.fromJson(response.data, (data) => SaleItemModel.fromJson(data));
      } else {
        return ApiResponse<SaleItemModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to get sale item',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get sale item by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SaleItemModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get sale item by ID', e);
      return ApiResponse<SaleItemModel>(success: false, message: 'An unexpected error occurred while getting sale item');
    }
  }

  /// Create a new sale item
  Future<ApiResponse<SaleItemModel>> createSaleItem(CreateSaleItemRequest request) async {
    try {
      final response = await _apiClient.post(ApiConfig.createSaleItem, data: request.toJson());

      DebugHelper.printApiResponse('POST Create Sale Item', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<SaleItemModel>.fromJson(response.data, (data) => SaleItemModel.fromJson(data));
      } else {
        return ApiResponse<SaleItemModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to create sale item',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Create sale item DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SaleItemModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Create sale item', e);
      return ApiResponse<SaleItemModel>(success: false, message: 'An unexpected error occurred while creating sale item');
    }
  }

  /// Update an existing sale item
  Future<ApiResponse<SaleItemModel>> updateSaleItem(String id, UpdateSaleItemRequest request) async {
    try {
      final response = await _apiClient.put(ApiConfig.updateSaleItem(id), data: request.toJson());

      DebugHelper.printApiResponse('PUT Update Sale Item', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<SaleItemModel>.fromJson(response.data, (data) => SaleItemModel.fromJson(data));
      } else {
        return ApiResponse<SaleItemModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update sale item',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update sale item DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SaleItemModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Update sale item', e);
      return ApiResponse<SaleItemModel>(success: false, message: 'An unexpected error occurred while updating sale item');
    }
  }

  /// Delete a sale item
  Future<ApiResponse<void>> deleteSaleItem(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteSaleItem(id));

      DebugHelper.printApiResponse('DELETE Sale Item', response.data);

      if (response.statusCode == 204 || response.statusCode == 200) {
        return ApiResponse<void>(success: true, message: 'Sale item deleted successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete sale item',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete sale item DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Delete sale item', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while deleting sale item');
    }
  }

  /// Search sale items
  Future<ApiResponse<List<SaleItemModel>>> searchSaleItems(String query) async {
    try {
      final response = await _apiClient.get(ApiConfig.searchSaleItems, queryParameters: {'search': query});

      DebugHelper.printApiResponse('GET Search Sale Items', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<List<SaleItemModel>>.fromJson(
          response.data,
          (data) => (data['sale_items'] as List<dynamic>).map((item) => SaleItemModel.fromJson(item)).toList(),
        );
      } else {
        return ApiResponse<List<SaleItemModel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to search sale items',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Search sale items DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<List<SaleItemModel>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Search sale items', e);
      return ApiResponse<List<SaleItemModel>>(success: false, message: 'An unexpected error occurred while searching sale items');
    }
  }

  // Private helper methods for caching
  Future<void> _cacheSaleItems(List<SaleItemModel> items) async {
    try {
      final itemsJson = items.map((item) => item.toJson()).toList();
      await _storageService.setString(ApiConfig.saleItemsCacheKey, jsonEncode(itemsJson));
    } catch (e) {
      debugPrint('Failed to cache sale items: $e');
    }
  }

  Future<List<SaleItemModel>> getCachedSaleItems() async {
    try {
      final cachedData = await _storageService.getString(ApiConfig.saleItemsCacheKey);
      if (cachedData != null) {
        final List<dynamic> itemsJson = jsonDecode(cachedData);
        return itemsJson.map((json) => SaleItemModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Failed to get cached sale items: $e');
    }
    return [];
  }
}

// ApiError class for error handling
class ApiError {
  final String type;
  final String displayMessage;
  final Map<String, dynamic>? errors;

  ApiError({required this.type, required this.displayMessage, this.errors});

  factory ApiError.fromDioError(DioException e) {
    String type = 'unknown_error';
    String message = 'An unknown error occurred';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        type = 'timeout_error';
        message = 'Request timed out. Please try again.';
        break;
      case DioExceptionType.connectionError:
        type = 'network_error';
        message = 'No internet connection. Please check your network.';
        break;
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 401) {
          type = 'unauthorized';
          message = 'You are not authorized to perform this action.';
        } else if (e.response?.statusCode == 403) {
          type = 'forbidden';
          message = 'Access forbidden.';
        } else if (e.response?.statusCode == 404) {
          type = 'not_found';
          message = 'Resource not found.';
        } else if (e.response?.statusCode == 422) {
          type = 'validation_error';
          message = 'Please check your input and try again.';
        } else if ((e.response?.statusCode ?? 0) >= 500) {
          type = 'server_error';
          message = 'Server error. Please try again later.';
        } else {
          type = 'http_error';
          message = 'HTTP error ${e.response?.statusCode}.';
        }
        break;
      case DioExceptionType.cancel:
        type = 'cancelled';
        message = 'Request was cancelled.';
        break;
      default:
        type = 'unknown_error';
        message = 'An unexpected error occurred.';
    }

    return ApiError(type: type, displayMessage: message, errors: e.response?.data is Map<String, dynamic> ? e.response?.data['errors'] : null);
  }
}
