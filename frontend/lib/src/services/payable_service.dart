import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/payable/payable_api_responses.dart';
import '../models/payable/payable_model.dart';
import '../utils/debug_helper.dart';
import '../utils/storage_service.dart';
import 'api_client.dart';

class PayableService {
  static final PayableService _instance = PayableService._internal();

  factory PayableService() => _instance;

  PayableService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get list of payables with pagination and filtering
  Future<ApiResponse<PayablesListResponse>> getPayables({PayableListParams? params}) async {
    try {
      final queryParams = params?.toQueryParameters() ?? PayableListParams().toQueryParameters();

      final response = await _apiClient.get(ApiConfig.payables, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Payables', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final payableListData = responseData['data'] as Map<String, dynamic>;

          // Handle the API response structure from Django views
          final payablesListResponse = PayablesListResponse(
            payables: (payableListData['payables'] as List).map((payableJson) => Payable.fromJson(payableJson)).toList(),
            pagination: PaginationInfo.fromJson(payableListData['pagination']),
            filtersApplied: payableListData['filters_applied'] as Map<String, dynamic>?,
          );

          // Cache payables if successful
          await _cachePayables(payablesListResponse.payables);

          return ApiResponse<PayablesListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Payables retrieved successfully',
            data: payablesListResponse,
          );
        } else {
          return ApiResponse<PayablesListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get payables',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<PayablesListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get payables',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get payables DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedPayables = await _getCachedPayables();
        if (cachedPayables.isNotEmpty) {
          return ApiResponse<PayablesListResponse>(
            success: true,
            message: 'Showing cached data',
            data: PayablesListResponse(
              payables: cachedPayables,
              pagination: PaginationInfo(
                currentPage: 1,
                pageSize: cachedPayables.length,
                totalCount: cachedPayables.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
              ),
            ),
          );
        }
      }

      return ApiResponse<PayablesListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get payables', e);
      return ApiResponse<PayablesListResponse>(success: false, message: 'An unexpected error occurred while getting payables');
    }
  }

  /// Get a specific payable by ID
  Future<ApiResponse<Payable>> getPayableById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getPayableById(id));

      DebugHelper.printApiResponse('GET Payable by ID', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final payable = Payable.fromJson(responseData['data']);
          return ApiResponse<Payable>(success: true, message: responseData['message'] as String? ?? 'Payable retrieved successfully', data: payable);
        } else {
          return ApiResponse<Payable>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get payable',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Payable>(
          success: false,
          message: response.data['message'] ?? 'Failed to get payable',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get payable by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Payable>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get payable by ID', e);
      return ApiResponse<Payable>(success: false, message: 'An unexpected error occurred while getting payable');
    }
  }

  /// Create a new payable
  Future<ApiResponse<Payable>> createPayable(PayableCreateRequest request) async {
    try {
      // Debug: Print the request data
      debugPrint('🔍 DEBUG: Create Payable Request:');
      debugPrint('📄 Request Data: ${request.toJson()}');
      
      final response = await _apiClient.post(ApiConfig.createPayable, data: request.toJson());

      DebugHelper.printApiResponse('CREATE Payable', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final payable = Payable.fromJson(responseData['data']);

          // Clear cache to refresh data
          await _clearPayablesCache();

          return ApiResponse<Payable>(success: true, message: responseData['message'] as String? ?? 'Payable created successfully', data: payable);
        } else {
          return ApiResponse<Payable>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to create payable',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Payable>(
          success: false,
          message: response.data['message'] ?? 'Failed to create payable',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Create payable DioException: ${e.toString()}');
      if (e.response != null) {
        debugPrint('Create payable Error Response: ${e.response?.data}');
      }
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Payable>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Create payable', e);
      return ApiResponse<Payable>(success: false, message: 'An unexpected error occurred while creating payable');
    }
  }

  /// Update an existing payable
  Future<ApiResponse<Payable>> updatePayable(String id, PayableUpdateRequest request) async {
    try {
      final response = await _apiClient.put(ApiConfig.updatePayable(id), data: request.toJson());

      DebugHelper.printApiResponse('UPDATE Payable', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final payable = Payable.fromJson(responseData['data']);

          // Clear cache to refresh data
          await _clearPayablesCache();

          return ApiResponse<Payable>(success: true, message: responseData['message'] as String? ?? 'Payable updated successfully', data: payable);
        } else {
          return ApiResponse<Payable>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to update payable',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Payable>(
          success: false,
          message: response.data['message'] ?? 'Failed to update payable',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update payable DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Payable>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Update payable', e);
      return ApiResponse<Payable>(success: false, message: 'An unexpected error occurred while updating payable');
    }
  }

  /// Delete a payable
  Future<ApiResponse<bool>> deletePayable(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deletePayable(id));

      DebugHelper.printApiResponse('DELETE Payable', response.data);

      if (response.statusCode == 200 || response.statusCode == 204) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          // Clear cache to refresh data
          await _clearPayablesCache();

          return ApiResponse<bool>(success: true, message: responseData['message'] as String? ?? 'Payable deleted successfully', data: true);
        } else {
          return ApiResponse<bool>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to delete payable',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<bool>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete payable',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete payable DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<bool>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Delete payable', e);
      return ApiResponse<bool>(success: false, message: 'An unexpected error occurred while deleting payable');
    }
  }

  /// Soft delete a payable
  Future<ApiResponse<bool>> softDeletePayable(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.softDeletePayable(id));

      DebugHelper.printApiResponse('SOFT DELETE Payable', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          // Clear cache to refresh data
          await _clearPayablesCache();

          return ApiResponse<bool>(success: true, message: responseData['message'] as String? ?? 'Payable soft deleted successfully', data: true);
        } else {
          return ApiResponse<bool>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to soft delete payable',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<bool>(
          success: false,
          message: response.data['message'] ?? 'Failed to soft delete payable',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Soft delete payable DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<bool>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Soft delete payable', e);
      return ApiResponse<bool>(success: false, message: 'An unexpected error occurred while soft deleting payable');
    }
  }

  /// Restore a soft deleted payable
  Future<ApiResponse<bool>> restorePayable(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.restorePayable(id));

      DebugHelper.printApiResponse('RESTORE Payable', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          // Clear cache to refresh data
          await _clearPayablesCache();

          return ApiResponse<bool>(success: true, message: responseData['message'] as String? ?? 'Payable restored successfully', data: true);
        } else {
          return ApiResponse<bool>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to restore payable',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<bool>(
          success: false,
          message: response.data['message'] ?? 'Failed to restore payable',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Restore payable DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<bool>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Restore payable', e);
      return ApiResponse<bool>(success: false, message: 'An unexpected error occurred while restoring payable');
    }
  }

  /// Add payment to a payable
  Future<ApiResponse<bool>> addPayment(String payableId, PayablePaymentRequest request) async {
    try {
      final response = await _apiClient.post(ApiConfig.addPayablePayment(payableId), data: request.toJson());

      DebugHelper.printApiResponse('ADD Payment to Payable', response.data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          // Clear cache to refresh data
          await _clearPayablesCache();

          return ApiResponse<bool>(success: true, message: responseData['message'] as String? ?? 'Payment added successfully', data: true);
        } else {
          return ApiResponse<bool>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to add payment',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<bool>(
          success: false,
          message: response.data['message'] ?? 'Failed to add payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Add payment DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<bool>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Add payment', e);
      return ApiResponse<bool>(success: false, message: 'An unexpected error occurred while adding payment');
    }
  }

  /// Update payable contact information
  Future<ApiResponse<bool>> updateContact(String payableId, PayableContactUpdateRequest request) async {
    try {
      final response = await _apiClient.put(ApiConfig.updatePayableContact(payableId), data: request.toJson());

      DebugHelper.printApiResponse('UPDATE Payable Contact', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          // Clear cache to refresh data
          await _clearPayablesCache();

          return ApiResponse<bool>(success: true, message: responseData['message'] as String? ?? 'Contact updated successfully', data: true);
        } else {
          return ApiResponse<bool>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to update contact',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<bool>(
          success: false,
          message: response.data['message'] ?? 'Failed to update contact',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update payable contact DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<bool>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Update payable contact', e);
      return ApiResponse<bool>(success: false, message: 'An unexpected error occurred while updating contact');
    }
  }

  /// Get payable statistics
  Future<ApiResponse<PayableStatisticsResponse>> getStatistics() async {
    try {
      final response = await _apiClient.get(ApiConfig.payableStatistics);

      DebugHelper.printApiResponse('GET Payable Statistics', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          final statistics = PayableStatisticsResponse.fromJson(data);

          // Cache statistics
          await _cacheStatistics(statistics);

          return ApiResponse<PayableStatisticsResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Statistics retrieved successfully',
            data: statistics,
          );
        } else {
          return ApiResponse<PayableStatisticsResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get statistics',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<PayableStatisticsResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get statistics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get payable statistics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached statistics if network error
      if (apiError.type == 'network_error') {
        final cachedStats = await _getCachedStatistics();
        if (cachedStats != null) {
          return ApiResponse<PayableStatisticsResponse>(success: true, message: 'Showing cached statistics', data: cachedStats);
        }
      }

      return ApiResponse<PayableStatisticsResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get payable statistics', e);
      return ApiResponse<PayableStatisticsResponse>(success: false, message: 'An unexpected error occurred while getting statistics');
    }
  }

  /// Get overdue payables
  Future<ApiResponse<PayablesListResponse>> getOverduePayables() async {
    try {
      final response = await _apiClient.get(ApiConfig.overduePayables);

      DebugHelper.printApiResponse('GET Overdue Payables', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final payableListData = responseData['data'] as Map<String, dynamic>;

          final payablesListResponse = PayablesListResponse(
            payables: (payableListData['payables'] as List).map((payableJson) => Payable.fromJson(payableJson)).toList(),
            pagination: PaginationInfo.fromJson(payableListData['pagination']),
            filtersApplied: payableListData['filters_applied'] as Map<String, dynamic>?,
          );

          return ApiResponse<PayablesListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Overdue payables retrieved successfully',
            data: payablesListResponse,
          );
        } else {
          return ApiResponse<PayablesListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get overdue payables',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<PayablesListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get overdue payables',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get overdue payables DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PayablesListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get overdue payables', e);
      return ApiResponse<PayablesListResponse>(success: false, message: 'An unexpected error occurred while getting overdue payables');
    }
  }

  /// Get urgent payables
  Future<ApiResponse<PayablesListResponse>> getUrgentPayables() async {
    try {
      final response = await _apiClient.get(ApiConfig.urgentPayables);

      DebugHelper.printApiResponse('GET Urgent Payables', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final payableListData = responseData['data'] as Map<String, dynamic>;

          final payablesListResponse = PayablesListResponse(
            payables: (payableListData['payables'] as List).map((payableJson) => Payable.fromJson(payableJson)).toList(),
            pagination: PaginationInfo.fromJson(payableListData['pagination']),
            filtersApplied: payableListData['filters_applied'] as Map<String, dynamic>?,
          );

          return ApiResponse<PayablesListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Urgent payables retrieved successfully',
            data: payablesListResponse,
          );
        } else {
          return ApiResponse<PayablesListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get urgent payables',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<PayablesListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get urgent payables',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get urgent payables DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PayablesListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get urgent payables', e);
      return ApiResponse<PayablesListResponse>(success: false, message: 'An unexpected error occurred while getting urgent payables');
    }
  }

  /// Perform bulk actions on payables
  Future<ApiResponse<bool>> bulkActions(PayableBulkActionRequest request) async {
    try {
      final response = await _apiClient.post(ApiConfig.bulkPayableActions, data: request.toJson());

      DebugHelper.printApiResponse('BULK ACTIONS Payables', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          // Clear cache to refresh data
          await _clearPayablesCache();

          return ApiResponse<bool>(success: true, message: responseData['message'] as String? ?? 'Bulk actions completed successfully', data: true);
        } else {
          return ApiResponse<bool>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to perform bulk actions',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<bool>(
          success: false,
          message: response.data['message'] ?? 'Failed to perform bulk actions',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Bulk actions DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<bool>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Bulk actions', e);
      return ApiResponse<bool>(success: false, message: 'An unexpected error occurred while performing bulk actions');
    }
  }

  /// Generate partner payables for an order
  Future<ApiResponse<List<Payable>>> generatePartnerPayables({
    required String orderId,
    bool recalculate = false,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.generatePartnerPayables,
        data: {
          'order_id': orderId,
          'recalculate': recalculate,
        },
      );

      DebugHelper.printApiResponse('GENERATE Partner Payables', response.data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final payables = (responseData['data'] as List)
              .map((json) => Payable.fromJson(json))
              .toList();

          await _clearPayablesCache();

          return ApiResponse<List<Payable>>(
            success: true,
            message: responseData['message'] as String? ??
                'Partner payables generated successfully',
            data: payables,
          );
        } else {
          return ApiResponse<List<Payable>>(
            success: false,
            message: responseData['message'] as String? ??
                'Failed to generate partner payables',
          );
        }
      } else {
        return ApiResponse<List<Payable>>(
          success: false,
          message:
              response.data['message'] ?? 'Failed to generate partner payables',
        );
      }
    } on DioException catch (e) {
      debugPrint('Generate partner payables DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<List<Payable>>(
          success: false,
          message: apiError.displayMessage,
          errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Generate partner payables', e);
      return ApiResponse<List<Payable>>(
          success: false,
          message:
              'An unexpected error occurred while generating partner payables');
    }
  }

  // Cache management methods
  Future<void> _cachePayables(List<Payable> payables) async {
    try {
      await _storageService.saveData(ApiConfig.payablesCacheKey, payables.map((p) => p.toJson()).toList());
    } catch (e) {
      debugPrint('Error caching payables: $e');
    }
  }

  Future<List<Payable>> _getCachedPayables() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.payablesCacheKey);
      if (cachedData != null) {
        return (cachedData as List).map((json) => Payable.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error getting cached payables: $e');
    }
    return [];
  }

  Future<void> _clearPayablesCache() async {
    try {
      await _storageService.removeData(ApiConfig.payablesCacheKey);
    } catch (e) {
      debugPrint('Error clearing payables cache: $e');
    }
  }

  Future<void> _cacheStatistics(PayableStatisticsResponse statistics) async {
    try {
      await _storageService.saveData(ApiConfig.payableStatsCacheKey, statistics.toJson());
    } catch (e) {
      debugPrint('Error caching payable statistics: $e');
    }
  }

  Future<PayableStatisticsResponse?> _getCachedStatistics() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.payableStatsCacheKey);
      if (cachedData != null) {
        // Create a minimal statistics response from cached data
        return PayableStatisticsResponse.fromJson(cachedData);
      }
    } catch (e) {
      debugPrint('Error getting cached payable statistics: $e');
    }
    return null;
  }
}
