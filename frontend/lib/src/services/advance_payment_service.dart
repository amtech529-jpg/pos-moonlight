import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/advance_payment/advance_payment_api_responses.dart';
import '../models/advance_payment/advance_payment_requests.dart';
import '../models/advance_payment/advance_payment_model.dart';
import '../utils/debug_helper.dart';
import '../utils/storage_service.dart';
import 'api_client.dart';

class AdvancePaymentService {
  static final AdvancePaymentService _instance = AdvancePaymentService._internal();
  factory AdvancePaymentService() => _instance;
  AdvancePaymentService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get list of advance payments with pagination and filtering
  Future<ApiResponse<AdvancePaymentsListResponse>> getAdvancePayments({AdvancePaymentListParams? params}) async {
    try {
      final queryParams = params?.toQueryParameters() ?? AdvancePaymentListParams().toQueryParameters();
      final response = await _apiClient.get(ApiConfig.advancePayments, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Advance Payments', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final listData = responseData['data'] as Map<String, dynamic>;

          final listResponse = AdvancePaymentsListResponse(
            advancePayments: (listData['advance_payments'] as List).map((paymentJson) => AdvancePayment.fromJson(paymentJson)).toList(),
            pagination: PaginationInfo.fromJson(listData['pagination']),
            filtersApplied: listData['filters_applied'] as Map<String, dynamic>?,
          );

          // Cache payments if successful
          await _cacheAdvancePayments(listResponse.advancePayments);

          return ApiResponse<AdvancePaymentsListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Advance payments retrieved successfully',
            data: listResponse,
          );
        } else {
          return ApiResponse<AdvancePaymentsListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get advance payments',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<AdvancePaymentsListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get advance payments',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get advance payments DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedPayments = await _getCachedAdvancePayments();
        if (cachedPayments.isNotEmpty) {
          return ApiResponse<AdvancePaymentsListResponse>(
            success: true,
            message: 'Showing cached data',
            data: AdvancePaymentsListResponse(
              advancePayments: cachedPayments,
              pagination: PaginationInfo(
                currentPage: 1,
                pageSize: cachedPayments.length,
                totalCount: cachedPayments.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
              ),
            ),
          );
        }
      }

      return ApiResponse<AdvancePaymentsListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get advance payments', e);
      return ApiResponse<AdvancePaymentsListResponse>(success: false, message: 'An unexpected error occurred while getting advance payments');
    }
  }

  /// Create a new advance payment
  Future<ApiResponse<AdvancePayment>> createAdvancePayment({
    required String laborId,
    required double amount,
    required String description,
    required DateTime date,
    required String time,
    File? receiptImageFile,
  }) async {
    try {
      final request = AdvancePaymentCreateRequest(
        laborId: laborId,
        amount: amount,
        description: description,
        date: date,
        time: time,
        receiptImagePath: receiptImageFile,
      );

      DebugHelper.printJson('Create Advance Payment Request', request.toFormData());

      // Create FormData for file upload
      final formData = FormData.fromMap(request.toFormData());

      // Add receipt image if provided
      if (receiptImageFile != null) {
        try {
          final file = await MultipartFile.fromFile(receiptImageFile.path);
          formData.files.add(MapEntry('receipt_image_path', file));
        } catch (e) {
          DebugHelper.printError('Error creating file from path', e);
          // Continue without receipt if file creation fails
        }
      }

      final response = await _apiClient.post<Map<String, dynamic>>(ApiConfig.createAdvancePayment, data: formData);

      DebugHelper.printApiResponse('POST Create Advance Payment', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final paymentData = responseData['data'] as Map<String, dynamic>;
          final payment = AdvancePayment.fromJson(paymentData);

          // Update cache with new payment
          await _addAdvancePaymentToCache(payment);

          return ApiResponse<AdvancePayment>(
            success: true,
            message: responseData['message'] as String? ?? 'Advance payment created successfully',
            data: payment,
          );
        } else {
          return ApiResponse<AdvancePayment>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to create advance payment',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<AdvancePayment>(
          success: false,
          message: response.data?['message'] ?? 'Failed to create advance payment',
          errors: response.data?['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Create advance payment DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<AdvancePayment>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Create advance payment', e);
      return ApiResponse<AdvancePayment>(success: false, message: 'An unexpected error occurred while creating advance payment: ${e.toString()}');
    }
  }

  /// Update an existing advance payment
  Future<ApiResponse<AdvancePayment>> updateAdvancePayment({
    required String id,
    required String laborId,
    required double amount,
    required String description,
    required DateTime date,
    required String time,
    File? receiptImageFile,
  }) async {
    try {
      final request = AdvancePaymentUpdateRequest(
        laborId: laborId,
        amount: amount,
        description: description,
        date: date,
        time: time,
        receiptImagePath: receiptImageFile,
      );

      DebugHelper.printJson('Update Advance Payment Request', request.toFormData());

      // Create FormData for file upload
      final formData = FormData.fromMap(request.toFormData());

      // Add receipt image if provided
      if (receiptImageFile != null) {
        try {
          final file = await MultipartFile.fromFile(receiptImageFile.path);
          formData.files.add(MapEntry('receipt_image_path', file));
        } catch (e) {
          DebugHelper.printError('Error creating file from path', e);
          // Continue without receipt if file creation fails
        }
      }

      final response = await _apiClient.put<Map<String, dynamic>>('${ApiConfig.updateAdvancePayment}$id/', data: formData);

      DebugHelper.printApiResponse('PUT Update Advance Payment', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final paymentData = responseData['data'] as Map<String, dynamic>;
          final payment = AdvancePayment.fromJson(paymentData);

          // Update cache with updated payment
          await _updateAdvancePaymentInCache(payment);

          return ApiResponse<AdvancePayment>(
            success: true,
            message: responseData['message'] as String? ?? 'Advance payment updated successfully',
            data: payment,
          );
        } else {
          return ApiResponse<AdvancePayment>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to update advance payment',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<AdvancePayment>(
          success: false,
          message: response.data?['message'] ?? 'Failed to update advance payment',
          errors: response.data?['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Update advance payment DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<AdvancePayment>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Update advance payment', e);
      return ApiResponse<AdvancePayment>(success: false, message: 'An unexpected error occurred while updating advance payment');
    }
  }

  /// Delete an advance payment (hard delete)
  Future<ApiResponse<void>> deleteAdvancePayment(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteAdvancePayment(id));

      DebugHelper.printApiResponse('DELETE Advance Payment', response.data);

      if (response.statusCode == 200) {
        // Remove from cache
        await _removeAdvancePaymentFromCache(id);

        return ApiResponse<void>(success: true, message: response.data['message'] ?? 'Advance payment deleted successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete advance payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete advance payment DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Delete advance payment error: ${e.toString()}');
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while deleting advance payment');
    }
  }

  /// Get advance payment statistics
  Future<ApiResponse<AdvancePaymentStatisticsResponse>> getAdvancePaymentStatistics() async {
    try {
      final response = await _apiClient.get(ApiConfig.advancePaymentStatistics);

      DebugHelper.printApiResponse('GET Advance Payment Statistics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<AdvancePaymentStatisticsResponse>.fromJson(
          response.data,
          (data) => AdvancePaymentStatisticsResponse.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<AdvancePaymentStatisticsResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get advance payment statistics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get advance payment statistics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<AdvancePaymentStatisticsResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get advance payment statistics error: ${e.toString()}');
      return ApiResponse<AdvancePaymentStatisticsResponse>(
        success: false,
        message: 'An unexpected error occurred while getting advance payment statistics',
      );
    }
  }

  // Cache management methods
  Future<void> _cacheAdvancePayments(List<AdvancePayment> payments) async {
    try {
      final paymentsJson = payments.map((payment) => payment.toJson()).toList();
      await _storageService.saveData(ApiConfig.advancePaymentsCacheKey, paymentsJson);
    } catch (e) {
      debugPrint('Error caching advance payments: $e');
    }
  }

  Future<List<AdvancePayment>> _getCachedAdvancePayments() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.advancePaymentsCacheKey);
      if (cachedData != null && cachedData is List) {
        return cachedData.map((json) => AdvancePayment.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error getting cached advance payments: $e');
    }
    return [];
  }

  Future<void> _addAdvancePaymentToCache(AdvancePayment payment) async {
    try {
      final cachedPayments = await _getCachedAdvancePayments();
      cachedPayments.add(payment);
      await _cacheAdvancePayments(cachedPayments);
    } catch (e) {
      debugPrint('Error adding advance payment to cache: $e');
    }
  }

  Future<void> _updateAdvancePaymentInCache(AdvancePayment updatedPayment) async {
    try {
      final cachedPayments = await _getCachedAdvancePayments();
      final index = cachedPayments.indexWhere((payment) => payment.id == updatedPayment.id);
      if (index != -1) {
        cachedPayments[index] = updatedPayment;
        await _cacheAdvancePayments(cachedPayments);
      }
    } catch (e) {
      debugPrint('Error updating advance payment in cache: $e');
    }
  }

  Future<void> _removeAdvancePaymentFromCache(String paymentId) async {
    try {
      final cachedPayments = await _getCachedAdvancePayments();
      cachedPayments.removeWhere((payment) => payment.id == paymentId);
      await _cacheAdvancePayments(cachedPayments);
    } catch (e) {
      debugPrint('Error removing advance payment from cache: $e');
    }
  }

  /// Refresh advance payment records (for pull-to-refresh functionality)
  Future<ApiResponse<AdvancePaymentsListResponse>> refreshAdvancePaymentRecords() async {
    return getAdvancePayments();
  }
}
