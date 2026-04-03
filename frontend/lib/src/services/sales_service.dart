import 'dart:convert';
import 'dart:typed_data'; // ✅ REQUIRED for PDF Printing
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/sales/sale_model.dart';
import '../models/sales/request_models.dart';
import '../utils/storage_service.dart';
import '../utils/debug_helper.dart';
import 'api_client.dart';

class SalesService {
  static final SalesService _instance = SalesService._internal();
  factory SalesService() => _instance;
  SalesService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get list of sales with pagination and filtering
  Future<ApiResponse<SalesListResponse>> getSales({SalesListParams? params}) async {
    try {
      final queryParams = params?.toQueryParameters() ?? SalesListParams().toQueryParameters();

      // Debug: Log the API call
      debugPrint('🚀 Calling API: ${ApiConfig.sales}');
      debugPrint('🌐 Query params: $queryParams');

      final response = await _apiClient.get(ApiConfig.sales, queryParameters: queryParams);

      // Debug: Log the response
      DebugHelper.printApiResponse('GET Sales', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data;

        // 1. Extract List<SaleModel>
        final List<dynamic> salesListJson = responseData['data'] ?? [];
        final List<SaleModel> sales = salesListJson
            .map((json) => SaleModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // 2. Extract Pagination
        final paginationJson = responseData['pagination'] as Map<String, dynamic>?;
        final pagination = paginationJson != null
            ? PaginationInfo.fromJson(paginationJson)
            : PaginationInfo(
            currentPage: 1,
            pageSize: sales.length,
            totalCount: sales.length,
            totalPages: 1,
            hasNext: false,
            hasPrevious: false
        );

        // 3. Create the Response Object
        final salesListResponse = SalesListResponse(sales: sales, pagination: pagination);

        // 4. Wrap in ApiResponse
        final apiResponse = ApiResponse<SalesListResponse>(
          success: responseData['success'] ?? true,
          message: responseData['message'] ?? 'Sales retrieved successfully',
          data: salesListResponse,
        );

        // Cache sales if successful
        if (apiResponse.success && apiResponse.data != null) {
          await _cacheSales(apiResponse.data!.sales);
        }

        return apiResponse;
      } else {
        return ApiResponse<SalesListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get sales',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get sales DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedSales = await getCachedSales();
        if (cachedSales.isNotEmpty) {
          return ApiResponse<SalesListResponse>(
            success: true,
            message: 'Showing cached data',
            data: SalesListResponse(
              sales: cachedSales,
              pagination: PaginationInfo(
                currentPage: 1,
                pageSize: cachedSales.length,
                totalCount: cachedSales.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
              ),
            ),
          );
        }
      }

      return ApiResponse<SalesListResponse>(
          success: false,
          message: apiError.displayMessage,
          errors: apiError.errors
      );
    } catch (e) {
      DebugHelper.printError('Get sales', e);
      return ApiResponse<SalesListResponse>(
          success: false,
          message: 'An unexpected error occurred while getting sales: $e'
      );
    }
  }

  /// Get a specific sale by ID
  Future<ApiResponse<SaleModel>> getSaleById(String id) async {
    if (id.isEmpty) {
      return ApiResponse<SaleModel>(
        success: false,
        message: 'Sale ID is missing',
      );
    }
    try {
      final response = await _apiClient.get(ApiConfig.getSaleById(id));

      DebugHelper.printApiResponse('GET Sale by ID', response.data);

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic> && response.data['success'] == true) {
          return ApiResponse<SaleModel>.fromJson(response.data, (data) => SaleModel.fromJson(data));
        } else {
          return ApiResponse<SaleModel>(
            success: false,
            message: response.data['message'] ?? 'Failed to parse sale data',
          );
        }
      } else {
        return ApiResponse<SaleModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to get sale',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get sale by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SaleModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get sale by ID', e);
      return ApiResponse<SaleModel>(success: false, message: 'An unexpected error occurred while getting sale');
    }
  }

  /// Create a new sale
  Future<ApiResponse<SaleModel>> createSale(CreateSaleRequest request) async {
    try {
      final response = await _apiClient.post(ApiConfig.createSale, data: request.toJson());

      DebugHelper.printApiResponse('POST Create Sale', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<SaleModel>.fromJson(response.data, (data) => SaleModel.fromJson(data));
      } else {
        return ApiResponse<SaleModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to create sale',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Create sale DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SaleModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Create sale', e);
      return ApiResponse<SaleModel>(success: false, message: 'An unexpected error occurred while creating sale');
    }
  }

  /// Update an existing sale
  Future<ApiResponse<SaleModel>> updateSale(String id, UpdateSaleRequest request) async {
    try {
      final response = await _apiClient.put(ApiConfig.updateSale(id), data: request.toJson());

      DebugHelper.printApiResponse('PUT Update Sale', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<SaleModel>.fromJson(response.data, (data) => SaleModel.fromJson(data));
      } else {
        return ApiResponse<SaleModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update sale',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update sale DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SaleModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Update sale', e);
      return ApiResponse<SaleModel>(success: false, message: 'An unexpected error occurred while updating sale');
    }
  }

  /// Delete a sale
  Future<ApiResponse<void>> deleteSale(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteSale(id));

      DebugHelper.printApiResponse('DELETE Sale', response.data);

      if (response.statusCode == 204 || response.statusCode == 200) {
        return ApiResponse<void>(success: true, message: 'Sale deleted successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete sale',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete sale DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Delete sale', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while deleting sale');
    }
  }

  /// Get sales statistics
  Future<ApiResponse<SalesStatisticsResponse>> getSalesStatistics() async {
    try {
      final response = await _apiClient.get(ApiConfig.salesStatistics);

      DebugHelper.printApiResponse('GET Sales Statistics', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<SalesStatisticsResponse>.fromJson(response.data, (data) => SalesStatisticsResponse.fromJson(data));
      } else {
        return ApiResponse<SalesStatisticsResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get sales statistics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get sales statistics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SalesStatisticsResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get sales statistics', e);
      return ApiResponse<SalesStatisticsResponse>(success: false, message: 'An unexpected error occurred while getting sales statistics');
    }
  }

  // Custom method used by CheckoutDialog
  Future<bool> createSaleFromCart({
    String? orderId,
    String? customer,  // Nullable for walk-in sales
    required double overallDiscount,
    Map<String, dynamic> taxConfiguration = const {},
    required String paymentMethod,
    required double amountPaid,
    Map<String, dynamic>? splitPaymentDetails,
    String? notes,
    required List<Map<String, dynamic>> saleItems,
  }) async {
    try {
      final payload = {
        'order_id': orderId,
        'customer': customer,
        'overall_discount': overallDiscount,
        'tax_configuration': taxConfiguration,
        'payment_method': paymentMethod,
        'amount_paid': amountPaid,
        'split_payment_details': splitPaymentDetails,
        'notes': notes,
        'sale_items': saleItems,
      };

      print('🚀 Creating sale with payload: ${jsonEncode(payload)}');

      final response = await _apiClient.post(
        '/sales/create/',
        data: payload,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        print('✅ Sale created successfully');
        return true;
      }

      throw Exception(response.data['message'] ?? 'Sale creation failed');

    } on DioException catch (e) {
      print('DioException: $e');

      String errorMessage = 'Server error. Please try again.';

      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;

        if (statusCode == 400 && responseData is Map) {
          if (responseData.containsKey('errors')) {
            final errors = responseData['errors'];
            errorMessage = errors is Map
                ? errors.values.join(', ')
                : errors.toString();
          } else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'];
          }
        } else if (statusCode == 500) {
          errorMessage = 'Server error. Please contact support.';
        }
      }

      throw Exception(errorMessage);
    }
  }

  // ✅ ADDED: Generate Sale Receipt (PDF Bytes)
  Future<ApiResponse<Uint8List>> generateSaleReceipt(String saleId) async {
    final url = '/sales/$saleId/print-receipt/';
    debugPrint('🚀 [SalesService] Printing Receipt: $url');

    try {
      final response = await _apiClient.post(
        url,
        // ✅ CRITICAL: Expect BYTES (Binary) from backend
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        return ApiResponse<Uint8List>(
          success: true,
          message: 'Receipt generated',
          // ✅ Convert dynamic response data to Uint8List
          data: Uint8List.fromList(response.data),
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to generate receipt',
        );
      }
    } catch (e) {
      debugPrint('🛑 [SalesService] Print Error: $e');
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  // ✅ ADDED: Generate Invoice PDF (Bytes)
  Future<ApiResponse<Uint8List>> generateInvoicePdf(String invoiceId) async {
    final url = '/sales/invoices/$invoiceId/generate-pdf/';
    debugPrint('🚀 [SalesService] Printing Invoice: $url');

    try {
      final response = await _apiClient.post(
        url,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        return ApiResponse<Uint8List>(
          success: true,
          message: 'Invoice PDF generated',
          data: Uint8List.fromList(response.data),
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to generate invoice PDF',
        );
      }
    } catch (e) {
      debugPrint('🛑 [SalesService] Invoice Print Error: $e');
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  // ✅ ADDED: Generate Thermal Print Data for Sale
  Future<ApiResponse<Map<String, dynamic>>> generateSaleThermalPrint(String saleId) async {
    final url = '/sales/$saleId/thermal-print/';
    debugPrint('🚀 [SalesService] Generating Thermal Print: $url');

    try {
      final response = await _apiClient.post(url);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: 'Thermal print data generated',
          data: response.data as Map<String, dynamic>,
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Failed to generate thermal print data',
        );
      }
    } catch (e) {
      debugPrint('🛑 [SalesService] Thermal Print Error: $e');
      return ApiResponse(success: false, message: 'Error: $e');
    }
  }

  /// Create sale from order
  Future<ApiResponse<SaleModel>> createSaleFromOrder(CreateSaleFromOrderRequest request) async {
    try {
      final response = await _apiClient.post(ApiConfig.createFromOrder, data: request.toJson());

      DebugHelper.printApiResponse('POST Create Sale from Order', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<SaleModel>.fromJson(response.data, (data) => SaleModel.fromJson(data));
      } else {
        return ApiResponse<SaleModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to create sale from order',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Create sale from order DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SaleModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Create sale from order', e);
      return ApiResponse<SaleModel>(success: false, message: 'An unexpected error occurred while creating sale from order');
    }
  }

  /// Update sale status
  Future<ApiResponse<SaleModel>> updateSaleStatus(String id, String status) async {
    try {
      final response = await _apiClient.patch(ApiConfig.updateSaleStatus(id), data: {'status': status});

      DebugHelper.printApiResponse('PATCH Update Sale Status', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<SaleModel>.fromJson(response.data, (data) => SaleModel.fromJson(data));
      } else {
        return ApiResponse<SaleModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update sale status',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update sale status DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SaleModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Update sale status', e);
      return ApiResponse<SaleModel>(success: false, message: 'An unexpected error occurred while updating sale status');
    }
  }

  /// Add payment to sale
  Future<ApiResponse<SaleModel>> addPayment(String id, double amount, String method) async {
    try {
      final response = await _apiClient.post(ApiConfig.addSalePayment(id), data: {'amount': amount, 'payment_method': method});

      DebugHelper.printApiResponse('POST Add Sale Payment', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<SaleModel>.fromJson(response.data, (data) => SaleModel.fromJson(data));
      } else {
        return ApiResponse<SaleModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to add payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Add payment DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SaleModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Add payment', e);
      return ApiResponse<SaleModel>(success: false, message: 'An unexpected error occurred while adding payment');
    }
  }

  /// Get customer sales history
  Future<ApiResponse<SalesListResponse>> getCustomerSalesHistory(String customerId) async {
    try {
      final response = await _apiClient.get(ApiConfig.customerSalesHistory(customerId));

      DebugHelper.printApiResponse('GET Customer Sales History', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['data'] is List) {
          final List<dynamic> salesListJson = responseData['data'] ?? [];
          final List<SaleModel> sales = salesListJson
              .map((json) => SaleModel.fromJson(json as Map<String, dynamic>))
              .toList();

          final paginationJson = responseData['pagination'] as Map<String, dynamic>?;
          final pagination = paginationJson != null
              ? PaginationInfo.fromJson(paginationJson)
              : PaginationInfo(currentPage: 1, pageSize: sales.length, totalCount: sales.length, totalPages: 1, hasNext: false, hasPrevious: false);

          return ApiResponse<SalesListResponse>(
            success: true,
            message: 'History retrieved',
            data: SalesListResponse(sales: sales, pagination: pagination),
          );
        }

        return ApiResponse<SalesListResponse>.fromJson(response.data, (data) => SalesListResponse.fromJson(data));
      } else {
        return ApiResponse<SalesListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get customer sales history',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get customer sales history DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SalesListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get customer sales history', e);
      return ApiResponse<SalesListResponse>(success: false, message: 'An unexpected error occurred while getting customer sales history');
    }
  }

  // Private helper methods for caching
  Future<void> _cacheSales(List<SaleModel> sales) async {
    try {
      final salesJson = sales.map((sale) => sale.toJson()).toList();
      await _storageService.setString(ApiConfig.salesCacheKey, jsonEncode(salesJson));
    } catch (e) {
      debugPrint('Failed to cache sales: $e');
    }
  }

  Future<List<SaleModel>> getCachedSales() async {
    try {
      final cachedData = await _storageService.getString(ApiConfig.salesCacheKey);
      if (cachedData != null) {
        final List<dynamic> salesJson = jsonDecode(cachedData);
        return salesJson.map((json) => SaleModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Failed to get cached sales: $e');
    }
    return [];
  }

  // ===== BULK OPERATIONS =====

  /// Bulk action on sales
  Future<ApiResponse<void>> bulkActionSales(List<String> saleIds, String action) async {
    try {
      final response = await _apiClient.post(ApiConfig.bulkSaleActions, data: {'sale_ids': saleIds, 'action': action});

      DebugHelper.printApiResponse('POST Bulk Action Sales', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true, message: 'Bulk action completed successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to perform bulk action',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Bulk action sales DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Bulk action sales', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while performing bulk action');
    }
  }

  // ===== ADVANCED SALES FEATURES =====

  /// Add payment to sale (Duplicate method alias, keeping for compatibility)
  Future<ApiResponse<void>> addSalePayment(String saleId, double amount, String method) async {
    try {
      final response = await _apiClient.post(ApiConfig.addSalePayment(saleId), data: {'amount': amount, 'method': method});

      DebugHelper.printApiResponse('POST Add Payment', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<void>(success: true, message: 'Payment added successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to add payment',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Add payment DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Add payment', e);
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while adding payment');
    }
  }

  bool _validatePaymentAmount(double amount, double currentAmountPaid, double grandTotal) {
    if (amount <= 0) return false;
    if (currentAmountPaid + amount > grandTotal) return false;
    return true;
  }

  // ===== SALES PAYMENT INTEGRATION =====

  /// Add payment to sale with enhanced workflow
  Future<ApiResponse<SaleModel>> addPaymentWithWorkflow({
    required String id,
    required double amount,
    required String method,
    String? reference,
    String? notes,
    Map<String, dynamic>? splitDetails,
    bool isPartialPayment = false,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.addSalePayment(id),
        data: {
          'amount': amount,
          'payment_method': method,
          'reference': reference,
          'notes': notes,
          'split_payment_details': splitDetails,
          'is_partial_payment': isPartialPayment,
        },
      );

      DebugHelper.printApiResponse('POST Add Sale Payment with Workflow', response.data);

      if (response.statusCode == 200) {
        return ApiResponse<SaleModel>.fromJson(response.data, (data) => SaleModel.fromJson(data));
      } else {
        return ApiResponse<SaleModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to add payment with workflow',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Add payment with workflow DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<SaleModel>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Add payment with workflow', e);
      return ApiResponse<SaleModel>(success: false, message: 'An unexpected error occurred while adding payment with workflow');
    }
  }

  /// Get comprehensive payment status for a sale
  Future<ApiResponse<Map<String, dynamic>>> getSalePaymentStatus(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getSaleById(id));

      DebugHelper.printApiResponse('GET Sale Payment Status', response.data);

      if (response.statusCode == 200) {
        final saleData = response.data['data'] as Map<String, dynamic>;

        // Calculate payment metrics
        final amountPaid = (saleData['amount_paid'] as num?)?.toDouble() ?? 0.0;
        final grandTotal = (saleData['grand_total'] as num?)?.toDouble() ?? 0.0;
        final remainingAmount = (saleData['remaining_amount'] as num?)?.toDouble() ?? 0.0;
        final isFullyPaid = saleData['is_fully_paid'] as bool? ?? false;
        final paymentPercentage = grandTotal > 0 ? (amountPaid / grandTotal) * 100 : 0;

        return ApiResponse<Map<String, dynamic>>(
          success: true,
          message: 'Sale payment status retrieved successfully',
          data: {
            'sale_id': id,
            'invoice_number': saleData['invoice_number'] ?? '',
            'customer_name': saleData['customer_name'] ?? '',
            'amount_paid': amountPaid,
            'grand_total': grandTotal,
            'remaining_amount': remainingAmount,
            'is_fully_paid': isFullyPaid,
            'payment_method': saleData['payment_method'] ?? '',
            'payment_status': saleData['status'] ?? '',
            'payment_percentage': paymentPercentage,
            'payment_workflow_step': _getPaymentWorkflowStep(amountPaid, grandTotal, saleData['status'] ?? ''),
            'can_process_payment': !isFullyPaid,
            'next_workflow_action': _getNextWorkflowAction(amountPaid, grandTotal, saleData['status'] ?? ''),
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

  /// Process payment confirmation workflow
  Future<ApiResponse<Map<String, dynamic>>> confirmPaymentWorkflow({
    required String saleId,
    required double amount,
    required String paymentMethod,
    String? reference,
    String? notes,
    Map<String, dynamic>? splitDetails,
    bool isPartialPayment = false,
  }) async {
    try {
      // Step 1: Get current sale status
      final currentStatusResponse = await getSalePaymentStatus(saleId);
      if (!currentStatusResponse.success) {
        return ApiResponse<Map<String, dynamic>>(success: false, message: 'Failed to get current sale status', errors: currentStatusResponse.errors);
      }

      final currentStatus = currentStatusResponse.data!;
      final currentAmountPaid = currentStatus['amount_paid'] as double;
      final grandTotal = currentStatus['grand_total'] as double;

      // Step 2: Validate payment
      if (!_validatePaymentAmount(amount, currentAmountPaid, grandTotal)) {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Invalid payment amount',
          errors: {'amount': 'Payment amount exceeds remaining balance'},
        );
      }

      // Step 3: Process payment
      final paymentResponse = await addPaymentWithWorkflow(
        id: saleId,
        amount: amount,
        method: paymentMethod,
        reference: reference,
        notes: notes,
        splitDetails: splitDetails,
        isPartialPayment: isPartialPayment,
      );

      if (!paymentResponse.success) {
        return ApiResponse<Map<String, dynamic>>(success: false, message: paymentResponse.message, errors: paymentResponse.errors);
      }

      // Step 4: Update sale status if needed
      final newAmountPaid = currentAmountPaid + amount;
      final isFullyPaid = newAmountPaid >= grandTotal;

      String newStatus = currentStatus['payment_status'];
      if (isFullyPaid) {
        newStatus = 'PAID';
      } else if (newAmountPaid > 0) {
        newStatus = 'PARTIAL';
      }

      if (newStatus != currentStatus['payment_status']) {
        final statusResponse = await updateSaleStatus(saleId, newStatus);
        if (!statusResponse.success) {
          // Payment was successful but status update failed
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            message: 'Payment processed but status update failed',
            data: {'payment_result': paymentResponse.data?.toJson(), 'status_update_failed': true, 'workflow_completed': false},
          );
        }
      }

      // Step 5: Return workflow result
      return ApiResponse<Map<String, dynamic>>(
        success: true,
        message: 'Payment workflow completed successfully',
        data: {
          'payment_result': paymentResponse.data?.toJson(),
          'workflow_completed': true,
          'new_status': newStatus,
          'amount_paid': newAmountPaid,
          'remaining_amount': grandTotal - newAmountPaid,
          'is_fully_paid': isFullyPaid,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      DebugHelper.printError('Confirm payment workflow', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred during payment workflow confirmation');
    }
  }

  /// Get payment workflow summary for a sale
  Future<ApiResponse<Map<String, dynamic>>> getPaymentWorkflowSummary(String saleId) async {
    try {
      final statusResponse = await getSalePaymentStatus(saleId);
      if (!statusResponse.success) {
        return ApiResponse<Map<String, dynamic>>(success: false, message: statusResponse.message, errors: statusResponse.errors);
      }

      final statusData = statusResponse.data!;
      final amountPaid = statusData['amount_paid'] as double;
      final grandTotal = statusData['grand_total'] as double;
      final currentStatus = statusData['payment_status'] as String;

      // Calculate workflow metrics
      final remainingAmount = grandTotal - amountPaid;
      final paymentPercentage = grandTotal > 0 ? (amountPaid / grandTotal) * 100 : 0;
      final isFullyPaid = amountPaid >= grandTotal;
      final isPartial = amountPaid > 0 && !isFullyPaid;
      final isUnpaid = amountPaid == 0;

      // Determine workflow step
      String currentWorkflowStep = 'pending';
      String nextWorkflowStep = 'pending';
      String nextAction = 'pending';

      if (isUnpaid) {
        currentWorkflowStep = 'awaiting_payment';
        nextWorkflowStep = 'process_payment';
        nextAction = 'Collect payment from customer';
      } else if (isPartial) {
        currentWorkflowStep = 'partial_payment';
        nextWorkflowStep = 'collect_remaining_payment';
        nextAction = 'Collect remaining payment: PKR ${remainingAmount.toStringAsFixed(2)}';
      } else if (isFullyPaid) {
        currentWorkflowStep = 'payment_complete';
        nextWorkflowStep = 'ready_for_delivery';
        nextAction = 'Mark as delivered or prepare for pickup';
      }

      return ApiResponse<Map<String, dynamic>>(
        success: true,
        message: 'Payment workflow summary retrieved successfully',
        data: {
          'sale_id': saleId,
          'current_workflow_step': currentWorkflowStep,
          'next_workflow_step': nextWorkflowStep,
          'next_action': nextAction,
          'payment_summary': {
            'amount_paid': amountPaid,
            'grand_total': grandTotal,
            'remaining_amount': remainingAmount,
            'payment_percentage': paymentPercentage,
            'is_fully_paid': isFullyPaid,
            'is_partial': isPartial,
            'is_unpaid': isUnpaid,
          },
          'status_information': {
            'current_status': currentStatus,
            'can_process_payment': !isFullyPaid,
            'can_update_status': true,
            'workflow_progress': paymentPercentage,
          },
          'workflow_actions': {
            'can_add_payment': !isFullyPaid,
            'can_mark_delivered': isFullyPaid && currentStatus == 'PAID',
            'can_cancel_sale': ['DRAFT', 'CONFIRMED'].contains(currentStatus),
            'can_return_sale': currentStatus == 'DELIVERED',
          },
        },
      );
    } catch (e) {
      DebugHelper.printError('Get payment workflow summary', e);
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'An unexpected error occurred while getting payment workflow summary');
    }
  }

  // Private helper methods for payment workflow
  String _getPaymentWorkflowStep(double amountPaid, double grandTotal, String currentStatus) {
    if (amountPaid >= grandTotal) {
      return 'payment_complete';
    } else if (amountPaid > 0) {
      return 'partial_payment';
    } else {
      return 'awaiting_payment';
    }
  }

  String _getNextWorkflowAction(double amountPaid, double grandTotal, String currentStatus) {
    if (amountPaid >= grandTotal) {
      return 'ready_for_delivery';
    } else if (amountPaid > 0) {
      return 'collect_remaining_payment';
    } else {
      return 'collect_payment';
    }
  }
}

// Response Models
class SalesListResponse {
  final List<SaleModel> sales;
  final PaginationInfo pagination;

  SalesListResponse({required this.sales, required this.pagination});

  factory SalesListResponse.fromJson(Map<String, dynamic> json) {
    return SalesListResponse(
      sales: (json['sales'] as List<dynamic>?)?.map((sale) => SaleModel.fromJson(sale as Map<String, dynamic>)).toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

class SalesStatisticsResponse {
  final int totalSales;
  final double totalRevenue;
  final int totalItemsSold;
  final double averageOrderValue;
  final double totalTaxCollected;
  final Map<String, dynamic> taxBreakdown;
  final Map<String, dynamic> paymentMethodDistribution;
  final Map<String, dynamic> statusDistribution;
  final List<dynamic> dailyTrends;
  final List<dynamic> monthlyTrends;

  SalesStatisticsResponse({
    required this.totalSales,
    required this.totalRevenue,
    required this.totalItemsSold,
    required this.averageOrderValue,
    required this.totalTaxCollected,
    required this.taxBreakdown,
    required this.paymentMethodDistribution,
    required this.statusDistribution,
    required this.dailyTrends,
    required this.monthlyTrends,
  });

  factory SalesStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return SalesStatisticsResponse(
      totalSales: json['total_sales'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalItemsSold: json['total_items_sold'] as int? ?? 0,
      averageOrderValue: (json['average_order_value'] as num?)?.toDouble() ?? 0.0,
      totalTaxCollected: (json['total_tax_collected'] as num?)?.toDouble() ?? 0.0,
      taxBreakdown: json['tax_breakdown'] as Map<String, dynamic>? ?? {},
      paymentMethodDistribution: json['payment_method_distribution'] as Map<String, dynamic>? ?? {},
      statusDistribution: json['status_distribution'] as Map<String, dynamic>? ?? {},
      dailyTrends: json['daily_trends'] as List<dynamic>? ?? [],
      monthlyTrends: json['monthly_trends'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_sales': totalSales,
      'total_revenue': totalRevenue,
      'total_items_sold': totalItemsSold,
      'average_order_value': averageOrderValue,
      'total_tax_collected': totalTaxCollected,
      'tax_breakdown': taxBreakdown,
      'payment_method_distribution': paymentMethodDistribution,
      'status_distribution': statusDistribution,
      'daily_trends': dailyTrends,
      'monthly_trends': monthlyTrends,
    };
  }
}

// Parameters Models
class SalesListParams {
  final int? page;
  final int? pageSize;
  final String? status;
  final String? customerId;
  final String? paymentMethod;
  final String? search;
  final String? dateFrom;
  final String? dateTo;
  final String? sortBy;
  final String? sortOrder;

  SalesListParams({
    this.page,
    this.pageSize,
    this.status,
    this.customerId,
    this.paymentMethod,
    this.search,
    this.dateFrom,
    this.dateTo,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toQueryParameters() {
    final Map<String, dynamic> params = {};
    if (page != null) params['page'] = page.toString();
    if (pageSize != null) params['page_size'] = pageSize.toString();
    if (status != null) params['status'] = status;
    if (customerId != null) params['customer_id'] = customerId;
    if (paymentMethod != null) params['payment_method'] = paymentMethod;
    if (search != null) params['search'] = search;
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (sortBy != null) params['sort_by'] = sortBy;
    if (sortOrder != null) params['sort_order'] = sortOrder;
    return params;
  }
}

// Pagination and Error Models
class PaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalCount;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  PaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    final currentPage = json['page'] as int? ?? json['current_page'] as int? ?? 1;
    final totalPages = json['total_pages'] as int? ?? 1;
    return PaginationInfo(
      currentPage: currentPage,
      pageSize: json['page_size'] as int? ?? 10,
      totalCount: json['total_count'] as int? ?? 0,
      totalPages: totalPages,
      hasNext: json['has_next'] as bool? ?? (currentPage < totalPages),
      hasPrevious: json['has_previous'] as bool? ?? (currentPage > 1),
    );
  }
}

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