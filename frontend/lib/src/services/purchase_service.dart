import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/purchase_model.dart';
import '../utils/debug_helper.dart';
import '../utils/storage_service.dart';
import 'api_client.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  Future<ApiResponse<List<PurchaseModel>>> getPurchases() async {
    try {
      debugPrint('🚀 [PurchaseService] GET ${ApiConfig.purchases}');
      final response = await _apiClient.get(ApiConfig.purchases);

      DebugHelper.printApiResponse('GET Purchases', response.data);

      if (response.statusCode == 200) {
        final responseBody = response.data;
        List<dynamic> listData = [];

        // 1. Unwrap the "data" field if present
        dynamic targetData = responseBody;
        if (responseBody is Map<String, dynamic> && responseBody.containsKey('data')) {
          targetData = responseBody['data'];
        }

        // 2. Determine if it's a List or a Map (Pagination)
        if (targetData is List) {
          listData = targetData;
        } else if (targetData is Map<String, dynamic>) {
          // Check for common list keys inside the data object
          if (targetData.containsKey('purchases')) {
            listData = targetData['purchases'];
          } else if (targetData.containsKey('results')) {
            listData = targetData['results'];
          } else {
            debugPrint('⚠️ [PurchaseService] Could not find list in data map keys: ${targetData.keys}');
          }
        }

        // 3. Parse List
        final purchases = listData.map((json) {
          try {
            return PurchaseModel.fromJson(json);
          } catch (e) {
            DebugHelper.printError('Error parsing purchase record', e);
            return null;
          }
        }).whereType<PurchaseModel>().toList();

        debugPrint('✅ [PurchaseService] Parsed ${purchases.length} purchases');
        await _cachePurchases(purchases);

        return ApiResponse<List<PurchaseModel>>(
          success: true,
          message: 'Purchases retrieved successfully',
          data: purchases,
        );
      } else {
        return ApiResponse<List<PurchaseModel>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get purchases',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Get Purchases DioException', e);
      final apiError = ApiError.fromDioError(e);

      if (apiError.type == 'network_error') {
        final cached = await _getCachedPurchases();
        if (cached.isNotEmpty) {
          return ApiResponse<List<PurchaseModel>>(
            success: true,
            message: 'Showing cached data',
            data: cached,
          );
        }
      }

      return ApiResponse<List<PurchaseModel>>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      DebugHelper.printError('Get Purchases error', e);
      return ApiResponse<List<PurchaseModel>>(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Create a new purchase
  Future<ApiResponse<PurchaseModel>> createPurchase(PurchaseModel purchase) async {
    try {
      DebugHelper.printJson('Create Purchase Request', purchase.toJson());

      final response = await _apiClient.post(ApiConfig.purchases, data: purchase.toJson());

      DebugHelper.printApiResponse('POST Create Purchase', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Unwrap data if wrapped
        dynamic responseData = response.data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          responseData = responseData['data'];
        }

        final newPurchase = PurchaseModel.fromJson(responseData as Map<String, dynamic>);

        return ApiResponse<PurchaseModel>(
          success: true,
          message: 'Purchase created successfully',
          data: newPurchase,
        );
      } else {
        return ApiResponse<PurchaseModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to create purchase',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Create Purchase DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PurchaseModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      DebugHelper.printError('Create Purchase error', e);
      return ApiResponse<PurchaseModel>(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Update an existing purchase record (PUT request)
  Future<ApiResponse<PurchaseModel>> updatePurchase(String id, PurchaseModel purchase) async {
    try {
      DebugHelper.printJson('Update Purchase Request', purchase.toJson());

      final response = await _apiClient.put(ApiConfig.getPurchaseById(id), data: purchase.toJson());

      DebugHelper.printApiResponse('PUT Update Purchase', response.data);

      if (response.statusCode == 200) {
        // Unwrap data if wrapped
        dynamic responseData = response.data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          responseData = responseData['data'];
        }

        final updatedPurchase = PurchaseModel.fromJson(responseData as Map<String, dynamic>);

        return ApiResponse<PurchaseModel>(
          success: true,
          message: 'Purchase updated successfully',
          data: updatedPurchase,
        );
      } else {
        return ApiResponse<PurchaseModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update purchase',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Update Purchase DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PurchaseModel>(
        success: false,
        message: apiError.displayMessage,
        errors: apiError.errors,
      );
    } catch (e) {
      DebugHelper.printError('Update Purchase error', e);
      return ApiResponse<PurchaseModel>(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Delete a purchase
  Future<ApiResponse<void>> deletePurchase(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.getPurchaseById(id));

      if (response.statusCode == 204 || response.statusCode == 200) {
        return ApiResponse<void>(
          success: true,
          message: 'Purchase deleted successfully',
          data: null,
        );
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete purchase',
        );
      }
    } on DioException catch (e) {
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(
        success: false,
        message: apiError.displayMessage,
      );
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: e.toString(),
      );
    }
  }

  // Cache management methods
  Future<void> _cachePurchases(List<PurchaseModel> records) async {
    try {
      final recordsJson = records.map((r) => r.toJson()).toList();
      await _storageService.saveData(ApiConfig.purchasesCacheKey, recordsJson);
    } catch (e) {
      debugPrint('Error caching purchases: $e');
    }
  }

  Future<List<PurchaseModel>> _getCachedPurchases() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.purchasesCacheKey);
      if (cachedData != null && cachedData is List) {
        return cachedData
            .map((json) => PurchaseModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error getting cached purchases: $e');
    }
    return [];
  }
}