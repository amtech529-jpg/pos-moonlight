import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/payment/payment_model.dart';
import '../models/payment/payment_request_models.dart';
import '../models/payment/payment_response_models.dart';
import '../utils/debug_helper.dart';
import '../utils/storage_service.dart';
import 'api_client.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  // ===== PAYMENT PROCESSING =====

  /// Process payment for a sale
  Future<ApiResponse<Map<String, dynamic>>> processPayment({
    required String saleId,
    required double amount,
    required String paymentMethod,
    required String currency,
    String? reference,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.processPayment,
        data: {
          'sale_id': saleId,
          'amount': amount.toString(),
          'payment_method': paymentMethod,
          'currency': currency,
          'reference': reference,
          'notes': notes,
          'metadata': metadata,
        },
      );

      DebugHelper.printApiResponse('POST Process Payment', response.data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to process payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Process payment DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Process payment', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while processing payment');
    }
  }

  /// Process split payment for a sale
  Future<ApiResponse<Map<String, dynamic>>> processSplitPayment({
    required String saleId,
    required List<Map<String, dynamic>> splitDetails,
    required String currency,
    String? reference,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.processSplitPayment,
        data: {'sale_id': saleId, 'split_details': splitDetails, 'currency': currency, 'reference': reference, 'notes': notes},
      );

      DebugHelper.printApiResponse('POST Process Split Payment', response.data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to process split payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Process split payment DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Process split payment', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while processing split payment');
    }
  }

  // ===== COMPREHENSIVE PAYMENT MANAGEMENT =====

  /// Get list of payments with filtering and pagination
  Future<ApiResponse<PaymentListResponse>> getPayments({PaymentFilterRequest? filter}) async {
    try {
      final queryParams = filter?.toQueryParameters() ?? {};

      final response = await _apiClient.get(ApiConfig.payments, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Payments', response.data);

      if (response.statusCode == 200) {
        debugPrint('🌐 API Response [GET Payments]: ${response.data}');
        final PaymentListResponse paymentsResponse = PaymentListResponse.fromJson(response.data['data']);
        debugPrint('📊 Parsed ${paymentsResponse.payments.length} payments');

        final apiResponse = ApiResponse<PaymentListResponse>(success: true, message: 'Payments loaded successfully', data: paymentsResponse);

        if (apiResponse.data != null) {
          await _cachePayments(apiResponse.data!.payments);
        }

        return apiResponse;
      } else {
        return ApiResponse<PaymentListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get payments',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get payments DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      if (apiError.type == 'network_error') {
        final cachedPayments = await getCachedPayments();
        if (cachedPayments.isNotEmpty) {
          return ApiResponse<PaymentListResponse>(
            success: true,
            message: 'Showing cached data',
            data: PaymentListResponse(
              payments: cachedPayments,
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

      return ApiResponse<PaymentListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get payments', e);
      return ApiResponse<PaymentListResponse>(success: false, message: 'An unexpected error occurred while getting payments');
    }
  }

  /// Get a specific payment by ID
  Future<ApiResponse<PaymentModel>> getPaymentById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getPaymentById(id));

      DebugHelper.printApiResponse('GET Payment by ID', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<PaymentModel>.fromJson(response.data, (data) => PaymentModel.fromJson(data));
      } else {
        return ApiResponse<PaymentModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to get payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get payment by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PaymentModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get payment by ID', e);
      return ApiResponse<PaymentModel>(success: false, message: 'An unexpected error occurred while getting payment');
    }
  }

  /// Create a new payment (FIXED: Uses standard JSON)
  Future<ApiResponse<PaymentModel>> createPayment(CreatePaymentRequest request) async {
    try {
      // NOTE: We are using JSON because the backend is currently configured for JSON.
      // This means file uploads (receipts) will be ignored for now.
      // The Date/Time format issue is handled by the updated `request.toJson()` method.

      final response = await _apiClient.post(
          ApiConfig.createPayment,
          data: request.toJson()
      );

      DebugHelper.printApiResponse('POST Create Payment', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<PaymentModel>.fromJson(response.data, (data) => PaymentModel.fromJson(data));
      } else {
        return ApiResponse<PaymentModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to create payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Create payment DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PaymentModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Create payment', e);
      return ApiResponse<PaymentModel>(success: false, message: 'An unexpected error occurred while creating payment');
    }
  }

  /// Update an existing payment
  Future<ApiResponse<PaymentModel>> updatePayment(String id, UpdatePaymentRequest request) async {
    try {
      final response = await _apiClient.put(ApiConfig.updatePayment(id), data: request.toJson());

      DebugHelper.printApiResponse('PUT Update Payment', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<PaymentModel>.fromJson(response.data, (data) => PaymentModel.fromJson(data));
      } else {
        return ApiResponse<PaymentModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update payment DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PaymentModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Update payment', e);
      return ApiResponse<PaymentModel>(success: false, message: 'An unexpected error occurred while updating payment');
    }
  }

  /// Delete a payment
  Future<ApiResponse<void>> deletePayment(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deletePayment(id));

      DebugHelper.printApiResponse('DELETE Payment', response.data);

      if (response.statusCode == 204 || response.statusCode == 200) {
        return ApiResponse<void>(success: true, message: 'Payment deleted successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete payment DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Delete payment', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while deleting payment');
    }
  }

  /// Soft delete a payment
  Future<ApiResponse<void>> softDeletePayment(String id) async {
    try {
      final response = await _apiClient.patch(ApiConfig.softDeletePayment(id));

      DebugHelper.printApiResponse('PATCH Soft Delete Payment', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true, message: 'Payment soft deleted successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to soft delete payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Soft delete payment DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Soft delete payment', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while soft deleting payment');
    }
  }

  /// Restore a soft deleted payment
  Future<ApiResponse<void>> restorePayment(String id) async {
    try {
      final response = await _apiClient.patch(ApiConfig.restorePayment(id));

      DebugHelper.printApiResponse('PATCH Restore Payment', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true, message: 'Payment restored successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to restore payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Restore payment DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Restore payment', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while restoring payment');
    }
  }

  /// Search payments
  Future<ApiResponse<PaymentListResponse>> searchPayments(String query) async {
    try {
      final response = await _apiClient.get(ApiConfig.searchPayments, queryParameters: {'search': query});

      DebugHelper.printApiResponse('GET Search Payments', response.data);

      if (response.statusCode == 200) {
        final PaymentListResponse paymentsResponse = PaymentListResponse.fromJson(response.data['data']);
        return ApiResponse<PaymentListResponse>(success: true, message: 'Payments search completed successfully', data: paymentsResponse);
      } else {
        return ApiResponse<PaymentListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to search payments',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Search payments DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PaymentListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Search payments', e);
      return ApiResponse<PaymentListResponse>(success: false, message: 'An unexpected error occurred while searching payments');
    }
  }

  /// Get payments by labor ID
  Future<ApiResponse<PaymentListResponse>> getPaymentsByLabor(String laborId) async {
    try {
      final response = await _apiClient.get(ApiConfig.paymentsByLaborId(laborId));

      DebugHelper.printApiResponse('GET Payments by Labor', response.data);

      if (response.statusCode == 200) {
        final PaymentListResponse paymentsResponse = PaymentListResponse.fromJson(response.data['data']);
        return ApiResponse<PaymentListResponse>(success: true, message: 'Labor payments loaded successfully', data: paymentsResponse);
      } else {
        return ApiResponse<PaymentListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get payments by labor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get payments by labor DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PaymentListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get payments by labor', e);
      return ApiResponse<PaymentListResponse>(success: false, message: 'An unexpected error occurred while getting payments by labor');
    }
  }

  /// Get payments by vendor ID
  Future<ApiResponse<PaymentListResponse>> getPaymentsByVendor(String vendorId) async {
    try {
      final response = await _apiClient.get(ApiConfig.paymentsByVendorId(vendorId));

      DebugHelper.printApiResponse('GET Payments by Vendor', response.data);

      if (response.statusCode == 200) {
        final PaymentListResponse paymentsResponse = PaymentListResponse.fromJson(response.data['data']);
        return ApiResponse<PaymentListResponse>(success: true, message: 'Vendor payments loaded successfully', data: paymentsResponse);
      } else {
        return ApiResponse<PaymentListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get payments by vendor',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get payments by vendor DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PaymentListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get payments by vendor', e);
      return ApiResponse<PaymentListResponse>(success: false, message: 'An unexpected error occurred while getting payments by vendor');
    }
  }

  /// Get payments by order ID
  Future<ApiResponse<PaymentListResponse>> getPaymentsByOrder(String orderId) async {
    try {
      final response = await _apiClient.get(ApiConfig.paymentsByOrderId(orderId));

      DebugHelper.printApiResponse('GET Payments by Order', response.data);

      if (response.statusCode == 200) {
        final PaymentListResponse paymentsResponse = PaymentListResponse.fromJson(response.data['data']);
        return ApiResponse<PaymentListResponse>(success: true, message: 'Order payments loaded successfully', data: paymentsResponse);
      } else {
        return ApiResponse<PaymentListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get payments by order',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get payments by order DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PaymentListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get payments by order', e);
      return ApiResponse<PaymentListResponse>(success: false, message: 'An unexpected error occurred while getting payments by order');
    }
  }

  /// Get payments by sale ID
  Future<ApiResponse<PaymentListResponse>> getPaymentsBySale(String saleId) async {
    try {
      final response = await _apiClient.get(ApiConfig.paymentsBySaleId(saleId));

      DebugHelper.printApiResponse('GET Payments by Sale', response.data);

      if (response.statusCode == 200) {
        final PaymentListResponse paymentsResponse = PaymentListResponse.fromJson(response.data['data']);
        return ApiResponse<PaymentListResponse>(success: true, message: 'Sale payments loaded successfully', data: paymentsResponse);
      } else {
        return ApiResponse<PaymentListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get payments by sale',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get payments by sale DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PaymentListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get payments by sale', e);
      return ApiResponse<PaymentListResponse>(success: false, message: 'An unexpected error occurred while getting payments by sale');
    }
  }

  /// Get payments by date range
  Future<ApiResponse<PaymentListResponse>> getPaymentsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.paymentDateRange,
        queryParameters: {'start_date': startDate.toIso8601String(), 'end_date': endDate.toIso8601String()},
      );

      DebugHelper.printApiResponse('GET Payments by Date Range', response.data);

      if (response.statusCode == 200) {
        final PaymentListResponse paymentsResponse = PaymentListResponse.fromJson(response.data['data']);
        return ApiResponse<PaymentListResponse>(success: true, message: 'Date range payments loaded successfully', data: paymentsResponse);
      } else {
        return ApiResponse<PaymentListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get payments by date range',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get payments by date range DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PaymentListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get payments by date range', e);
      return ApiResponse<PaymentListResponse>(success: false, message: 'An unexpected error occurred while getting payments by date range');
    }
  }

  /// Get payments by payment method
  Future<ApiResponse<PaymentListResponse>> getPaymentsByMethod(String method) async {
    try {
      final response = await _apiClient.get(ApiConfig.paymentsByMethod(method));

      DebugHelper.printApiResponse('GET Payments by Method', response.data);

      if (response.statusCode == 200) {
        final PaymentListResponse paymentsResponse = PaymentListResponse.fromJson(response.data['data']);
        return ApiResponse<PaymentListResponse>(success: true, message: 'Method payments loaded successfully', data: paymentsResponse);
      } else {
        return ApiResponse<PaymentListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get payments by method',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get payments by method DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PaymentListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get payments by method', e);
      return ApiResponse<PaymentListResponse>(success: false, message: 'An unexpected error occurred while getting payments by method');
    }
  }

  /// Mark payment as final
  Future<ApiResponse<void>> markAsFinalPayment(String id) async {
    try {
      final response = await _apiClient.patch(ApiConfig.markAsFinalPayment(id));

      DebugHelper.printApiResponse('PATCH Mark as Final Payment', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true, message: 'Payment marked as final successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to mark payment as final',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Mark as final payment DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Mark as final payment', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while marking payment as final');
    }
  }

  /// Get payment statistics
  Future<ApiResponse<PaymentStatisticsResponse>> getPaymentStatistics() async {
    try {
      final response = await _apiClient.get(ApiConfig.paymentStatistics);

      DebugHelper.printApiResponse('GET Payment Statistics', response.data);

      if (response.statusCode == 200) {
        final PaymentStatisticsResponse statisticsResponse = PaymentStatisticsResponse.fromJson(response.data['data']);
        return ApiResponse<PaymentStatisticsResponse>(success: true, message: 'Payment statistics loaded successfully', data: statisticsResponse);
      } else {
        return ApiResponse<PaymentStatisticsResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get payment statistics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get payment statistics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PaymentStatisticsResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get payment statistics', e);
      return ApiResponse<PaymentStatisticsResponse>(success: false, message: 'An unexpected error occurred while getting payment statistics');
    }
  }

  /// Get payment summary
  Future<ApiResponse<PaymentSummaryResponse>> getPaymentSummary() async {
    try {
      final response = await _apiClient.get(ApiConfig.paymentSummary);

      DebugHelper.printApiResponse('GET Payment Summary', response.data);

      if (response.statusCode == 200) {
        final PaymentSummaryResponse summaryResponse = PaymentSummaryResponse.fromJson(response.data['data']);
        return ApiResponse<PaymentSummaryResponse>(success: true, message: 'Payment summary loaded successfully', data: summaryResponse);
      } else {
        return ApiResponse<PaymentSummaryResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get payment summary',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get payment summary DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<PaymentSummaryResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get payment summary', e);
      return ApiResponse<PaymentSummaryResponse>(success: false, message: 'An unexpected error occurred while getting payment summary');
    }
  }

  // ===== SALES PAYMENT INTEGRATION =====

  /// Process payment for a sale with comprehensive workflow
  Future<ApiResponse<Map<String, dynamic>>> processSalePayment({
    required String saleId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
    Map<String, dynamic>? splitDetails,
    bool isPartialPayment = false,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.addSalePayment(saleId),
        data: {
          'amount': amount.toString(),
          'payment_method': paymentMethod,
          'reference': reference,
          'notes': notes,
          'split_payment_details': splitDetails,
          'is_partial_payment': isPartialPayment,
        },
      );

      DebugHelper.printApiResponse('POST Process Sale Payment', response.data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to process sale payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Process sale payment DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Process sale payment', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while processing sale payment');
    }
  }

  /// Get payment status for a sale
  Future<ApiResponse<Map<String, dynamic>>> getSalePaymentStatus(String saleId) async {
    try {
      final response = await _apiClient.get(ApiConfig.getSaleById(saleId));

      DebugHelper.printApiResponse('GET Sale Payment Status', response.data);

      if (response.statusCode == 200) {
        final saleData = response.data['data'] as Map<String, dynamic>;
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: 'Sale payment status retrieved successfully',
          data: {
            'sale_id': saleId,
            'amount_paid': saleData['amount_paid'] ?? 0.0,
            'grand_total': saleData['grand_total'] ?? 0.0,
            'remaining_amount': saleData['remaining_amount'] ?? 0.0,
            'is_fully_paid': saleData['is_fully_paid'] ?? false,
            'payment_method': saleData['payment_method'] ?? '',
            'payment_status': saleData['status'] ?? '',
            'payment_percentage': saleData['payment_percentage'] ?? 0.0,
          },
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get sale payment status',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get sale payment status DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get sale payment status', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting sale payment status');
    }
  }

  /// Update payment status for a sale
  Future<ApiResponse<Map<String, dynamic>>> updateSalePaymentStatus({
    required String saleId,
    required String newStatus,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiClient.patch(ApiConfig.updateSaleStatus(saleId), data: {'status': newStatus, 'notes': notes, 'metadata': metadata});

      DebugHelper.printApiResponse('PATCH Update Sale Payment Status', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (data) => data as Map<String, dynamic>);
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to update sale payment status',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update sale payment status DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Update sale payment status', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while updating sale payment status');
    }
  }

  /// Process payment confirmation workflow
  Future<ApiResponse<Map<String, dynamic>>> confirmPaymentWorkflow({
    required String saleId,
    required String paymentMethod,
    required double amount,
    String? receiptPath,
    String? notes,
    Map<String, dynamic>? workflowData,
  }) async {
    try {
      // Step 1: Process the payment
      final paymentResponse = await processSalePayment(saleId: saleId, amount: amount, paymentMethod: paymentMethod, notes: notes);

      if (!paymentResponse.success) {
        return paymentResponse;
      }

      // Step 2: Update sale status based on payment
      final saleData = paymentResponse.data!;
      final isFullyPaid = saleData['is_fully_paid'] ?? false;
      final newStatus = isFullyPaid ? 'PAID' : 'PARTIAL';

      final statusResponse = await updateSalePaymentStatus(
        saleId: saleId,
        newStatus: newStatus,
        notes: 'Payment confirmed: ${paymentMethod} - ${amount.toStringAsFixed(2)}',
        metadata: {'receipt_path': receiptPath, 'workflow_data': workflowData, 'confirmation_timestamp': DateTime.now().toIso8601String()},
      );

      if (!statusResponse.success) {
        return statusResponse;
      }

      // Step 3: Return comprehensive workflow result
      return ApiResponse<Map<String, dynamic>>(
        success: true,
        message: 'Payment workflow completed successfully',
        data: {
          'payment_result': paymentResponse.data,
          'status_update': statusResponse.data,
          'workflow_completed': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      DebugHelper.printError('Confirm payment workflow', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred during payment workflow confirmation');
    }
  }

  /// Get payment workflow history for a sale
  Future<ApiResponse<List<Map<String, dynamic>>>> getPaymentWorkflowHistory(String saleId) async {
    try {
      // Get payment records for the sale
      final paymentsResponse = await getPayments(filter: PaymentFilterRequest(saleId: saleId));

      if (!paymentsResponse.success) {
        return ApiResponse<List<Map<String, dynamic>>>(success: false, message: paymentsResponse.message, errors: paymentsResponse.errors);
      }

      // Get sale status history
      final saleResponse = await _apiClient.get(ApiConfig.getSaleById(saleId));

      List<Map<String, dynamic>> workflowHistory = [];

      // Add payment records to workflow history
      if (paymentsResponse.data != null) {
        for (final payment in paymentsResponse.data!.payments) {
          workflowHistory.add({
            'type': 'payment',
            'timestamp': payment.createdAt.toIso8601String(),
            'amount': payment.amountPaid,
            'method': payment.paymentMethod,
            'description': payment.description ?? 'Payment processed',
            'status': 'completed',
          });
        }
      }

      // Add sale status changes to workflow history
      if (saleResponse.statusCode == 200) {
        final saleData = saleResponse.data['data'] as Map<String, dynamic>;
        workflowHistory.add({
          'type': 'status_change',
          'timestamp': saleData['updated_at'] ?? DateTime.now().toIso8601String(),
          'status': saleData['status'] ?? 'unknown',
          'description': 'Sale status updated',
          'amount_paid': saleData['amount_paid'] ?? 0.0,
          'remaining_amount': saleData['remaining_amount'] ?? 0.0,
        });
      }

      // Sort by timestamp
      workflowHistory.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));

      return ApiResponse<List<Map<String, dynamic>>>(
        success: true,
        message: 'Payment workflow history retrieved successfully',
        data: workflowHistory,
      );
    } catch (e) {
      DebugHelper.printError('Get payment workflow history', e);
      return ApiResponse<List<Map<String, dynamic>>>(success: false, message: 'An unexpected error occurred while getting payment workflow history');
    }
  }

  /// Validate payment workflow data
  bool validatePaymentWorkflow({required double amount, required String paymentMethod, required double saleTotal, double? previousAmountPaid = 0.0}) {
    // Basic validation
    if (amount <= 0) return false;
    if (amount > saleTotal) return false;
    if (paymentMethod.isEmpty) return false;

    // Check if payment would exceed sale total
    final totalAfterPayment = (previousAmountPaid ?? 0.0) + amount;
    if (totalAfterPayment > saleTotal) return false;

    return true;
  }

  /// Get payment workflow status summary
  Map<String, dynamic> getPaymentWorkflowSummary({
    required double amountPaid,
    required double grandTotal,
    required String currentStatus,
    required List<Map<String, dynamic>> workflowHistory,
  }) {
    final remainingAmount = grandTotal - amountPaid;
    final paymentPercentage = grandTotal > 0 ? (amountPaid / grandTotal) * 100 : 0;
    final isFullyPaid = amountPaid >= grandTotal;
    final isPartial = amountPaid > 0 && !isFullyPaid;
    final isUnpaid = amountPaid == 0;

    String nextWorkflowStep = 'pending';
    if (isUnpaid) {
      nextWorkflowStep = 'awaiting_payment';
    } else if (isPartial) {
      nextWorkflowStep = 'awaiting_remaining_payment';
    } else if (isFullyPaid) {
      nextWorkflowStep = 'ready_for_delivery';
    }

    return {
      'amount_paid': amountPaid,
      'grand_total': grandTotal,
      'remaining_amount': remainingAmount,
      'payment_percentage': paymentPercentage,
      'is_fully_paid': isFullyPaid,
      'is_partial': isPartial,
      'is_unpaid': isUnpaid,
      'current_status': currentStatus,
      'next_workflow_step': nextWorkflowStep,
      'workflow_steps_completed': workflowHistory.length,
      'last_workflow_update': workflowHistory.isNotEmpty ? workflowHistory.last['timestamp'] : null,
    };
  }

  // Private helper methods for caching
  Future<void> _cachePayments(List<PaymentModel> payments) async {
    try {
      final paymentsJson = payments.map((payment) => payment.toJson()).toList();
      await _storageService.setString('cached_payments', paymentsJson.toString());
    } catch (e) {
      debugPrint('Failed to cache payments: $e');
    }
  }

  Future<List<PaymentModel>> getCachedPayments() async {
    try {
      final cachedData = await _storageService.getString('cached_payments');
      if (cachedData != null) {
        // Parse cached data (simplified for now)
        return [];
      }
    } catch (e) {
      debugPrint('Failed to get cached payments: $e');
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