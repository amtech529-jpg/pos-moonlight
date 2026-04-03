import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/sales/sale_model.dart'; // Ensure ReceiptModel is defined here
import '../utils/storage_service.dart';

class ReceiptService {
  static final ReceiptService _instance = ReceiptService._internal();
  factory ReceiptService() => _instance;
  ReceiptService._internal();

  final Dio _dio = Dio();
  final StorageService _storageService = StorageService();

  // ✅ CRITICAL FIX: Get Token & Use Correct Header Format
  Future<Options> _getAuthOptions() async {
    final token = await _storageService.getToken() ?? '';
    if (token.isEmpty) {
      debugPrint('⚠️ [ReceiptService] Warning: No Auth Token found!');
    }
    return Options(
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token', // Fixed: "Token" instead of "Bearer"
      },
      validateStatus: (status) => status! < 500,
    );
  }

  String _getUrl(String endpoint) {
    return '${ApiConfig.baseUrl}$endpoint';
  }

  // Generate PDF receipt for a sale directly (same as after-sale receipt)
  Future<ApiResponse<Map<String, dynamic>>> generateSaleReceiptPdf(String saleId) async {
    try {
      debugPrint(' [ReceiptService] Generating PDF receipt for sale: $saleId');

      final options = await _getAuthOptions();
      final response = await _dio.post(
        _getUrl('/api/v1/sales/$saleId/print-receipt/'),
        options: options,
      );

      debugPrint(' [ReceiptService] Sale receipt PDF generated successfully');
      debugPrint(' [ReceiptService] Response data: ${response.data}');

      return ApiResponse<Map<String, dynamic>>.success(
        data: response.data,
        message: 'Sale receipt PDF generated successfully',
      );
    } on DioException catch (e) {
      debugPrint(' [ReceiptService] Dio error generating sale receipt PDF: $e');
      debugPrint(' [ReceiptService] Response data: ${e.response?.data}');
      debugPrint(' [ReceiptService] Status code: ${e.response?.statusCode}');

      String errorMessage = 'Failed to generate sale receipt PDF';
      
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        errorMessage = data['message'] ?? data['detail'] ?? errorMessage;
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No internet connection. Please check your network.';
      }

      return ApiResponse<Map<String, dynamic>>.error(
        message: errorMessage,
      );
    } catch (e) {
      debugPrint(' [ReceiptService] Unexpected error generating sale receipt PDF: $e');
      return ApiResponse<Map<String, dynamic>>.error(
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Generate PDF for a receipt
  Future<ApiResponse<Map<String, dynamic>>> generateReceiptPdf(String receiptId) async {
    final url = _getUrl('/sales/receipts/$receiptId/generate-pdf/');
    debugPrint(' [ReceiptService] POST $url (Generate PDF)');

    try {
      final response = await _dio.post(
        url,
        options: await _getAuthOptions(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('✅ [ReceiptService] PDF generated successfully');
        return ApiResponse.success(
          message: data['message'] ?? 'PDF generated successfully',
          data: data['data'] as Map<String, dynamic>,
        );
      } else {
        final errorData = response.data;
        debugPrint('❌ [ReceiptService] PDF generation failed: ${response.statusCode}');
        return ApiResponse.error(
          message: errorData['message'] ?? 'Failed to generate PDF',
          errors: errorData['errors'] ?? {},
        );
      }
    } catch (e) {
      debugPrint('❌ [ReceiptService] Exception during PDF generation: $e');
      return ApiResponse.error(
        message: 'Failed to generate receipt PDF: ${e.toString()}',
        errors: {'detail': e.toString()},
      );
    }
  }

  /// Create a simple receipt directly from sale (for sales with amount_paid > 0)
  Future<ApiResponse<ReceiptModel>> createSimpleReceipt({
    required String saleId,
    String? notes,
  }) async {
    final url = _getUrl('/sales/receipts/create-simple/');
    debugPrint('🚀 [ReceiptService] POST $url (Simple Receipt)');

    try {
      final response = await _dio.post(
        url,
        options: await _getAuthOptions(),
        data: {
          'sale': saleId,
          'notes': notes ?? 'Receipt generated for paid sale',
        },
      );

      debugPrint('✅ [ReceiptService] Simple Receipt Response: ${response.data}');

      if (response.statusCode == 201 && response.data['success'] == true) {
        final receiptData = response.data['data'];
        final receipt = ReceiptModel.fromJson(receiptData);
        
        return ApiResponse.success(
          data: receipt,
          message: response.data['message'] ?? 'Simple receipt created successfully',
        );
      } else {
        return ApiResponse.error(
          message: response.data['message'] ?? 'Failed to create simple receipt',
          errors: response.data['errors'],
        );
      }
    } catch (e) {
      debugPrint('❌ [ReceiptService] Simple Receipt Error: $e');
      return ApiResponse.error(
        message: 'Failed to create simple receipt: ${e.toString()}',
      );
    }
  }

  /// Create a new receipt for a payment
  Future<ApiResponse<ReceiptModel>> createReceipt({
    required String saleId,
    required String paymentId,
    String? notes,
  }) async {
    final url = _getUrl(ApiConfig.createReceipt);
    debugPrint('🚀 [ReceiptService] POST $url');

    try {
      final response = await _dio.post(
        url,
        options: await _getAuthOptions(),
        data: {
          'sale': saleId,
          'payment': paymentId,
          'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [ReceiptService] Receipt Created');
        return ApiResponse<ReceiptModel>.fromJson(
          response.data,
              (data) => ReceiptModel.fromJson(data),
        );
      } else {
        debugPrint('❌ [ReceiptService] Failed: ${response.data}');
        return ApiResponse<ReceiptModel>(
          success: false,
          message: response.data['message'] ?? response.data['detail'] ?? 'Failed to create receipt',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      debugPrint('🛑 [ReceiptService] Error: $e');
      return ApiResponse<ReceiptModel>(
        success: false,
        message: 'Error creating receipt: $e',
      );
    }
  }

  /// Get receipt details by ID
  Future<ApiResponse<ReceiptModel>> getReceipt(String id) async {
    final url = _getUrl(ApiConfig.getReceiptById(id));
    debugPrint('🚀 [ReceiptService] GET $url');

    try {
      final response = await _dio.get(url, options: await _getAuthOptions());

      if (response.statusCode == 200) {
        return ApiResponse<ReceiptModel>.fromJson(
          response.data,
              (data) => ReceiptModel.fromJson(data),
        );
      } else {
        return ApiResponse<ReceiptModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to get receipt',
        );
      }
    } catch (e) {
      return ApiResponse<ReceiptModel>(
        success: false,
        message: 'Error getting receipt: $e',
      );
    }
  }

  /// Update receipt details
  Future<ApiResponse<ReceiptModel>> updateReceipt({
    required String id,
    String? notes,
    String? status,
  }) async {
    final url = _getUrl(ApiConfig.updateReceipt(id));

    try {
      final response = await _dio.put(
        url,
        options: await _getAuthOptions(),
        data: {
          if (notes != null) 'notes': notes,
          if (status != null) 'status': status,
        },
      );

      if (response.statusCode == 200) {
        return ApiResponse<ReceiptModel>.fromJson(
          response.data,
              (data) => ReceiptModel.fromJson(data),
        );
      } else {
        return ApiResponse<ReceiptModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update receipt',
        );
      }
    } catch (e) {
      return ApiResponse<ReceiptModel>(
        success: false,
        message: 'Error updating receipt: $e',
      );
    }
  }

  /// List receipts with filtering and pagination
  /// ✅ FIXED: Returns List<ReceiptModel> instead of Map to prevent crash
  Future<ApiResponse<List<ReceiptModel>>> listReceipts({
    String? saleId,
    String? paymentId,
    String? status,
    String? dateFrom,
    String? dateTo,
    bool? showInactive,
    int? page,
    int? pageSize,
  }) async {
    final url = _getUrl(ApiConfig.receipts);
    debugPrint('🚀 [ReceiptService] GET List $url');
    debugPrint('🔍 [ReceiptService] Query params: saleId=$saleId, paymentId=$paymentId, status=$status');

    try {
      final response = await _dio.get(
        url,
        options: await _getAuthOptions(),
        queryParameters: {
          if (saleId != null) 'sale_id': saleId,
          if (paymentId != null) 'payment_id': paymentId,
          if (status != null) 'status': status,
          if (dateFrom != null) 'date_from': dateFrom,
          if (dateTo != null) 'date_to': dateTo,
          if (showInactive != null) 'show_inactive': showInactive.toString(),
          if (page != null) 'page': page,
          if (pageSize != null) 'page_size': pageSize,
        },
      );
      
      debugPrint('🔍 [ReceiptService] Response status: ${response.statusCode}');
      debugPrint('🔍 [ReceiptService] Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        // ✅ SAFE PARSING: Handles both {data: [...]} and {results: [...]}
        List<dynamic> listData;
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData.containsKey('data')) {
            listData = responseData['data'];
            debugPrint('🔍 [ReceiptService] Found data field with ${listData.length} results');
          } else if (responseData.containsKey('results')) {
            listData = responseData['results'];
            debugPrint('🔍 [ReceiptService] Found results field with ${listData.length} results');
          } else {
            debugPrint('🔍 [ReceiptService] No data or results field found in: ${responseData.keys}');
            listData = [];
          }
        } else if (response.data is List) {
          listData = response.data;
          debugPrint('🔍 [ReceiptService] Found direct list with ${listData.length} items');
        } else {
          debugPrint('🔍 [ReceiptService] Unexpected response format: ${response.data}');
          listData = [];
        }

        final receipts = listData.map((json) => ReceiptModel.fromJson(json)).toList();
        debugPrint('✅ [ReceiptService] Loaded ${receipts.length} receipts');

        return ApiResponse<List<ReceiptModel>>(
          success: true,
          data: receipts,
          message: 'Receipts list loaded',
        );
      } else {
        debugPrint('❌ [ReceiptService] Failed: ${response.data}');
        return ApiResponse<List<ReceiptModel>>(
          success: false,
          data: [],
          message: response.data['message'] ?? 'Failed to list receipts',
        );
      }
    } catch (e) {
      debugPrint('🛑 [ReceiptService] Exception: $e');
      return ApiResponse<List<ReceiptModel>>(
        success: false,
        data: [],
        message: 'Error listing receipts: $e',
      );
    }
  }

  /// Delete a receipt
  Future<ApiResponse<bool>> deleteReceipt(String id) async {
    final url = _getUrl(ApiConfig.deleteReceipt(id));

    try {
      final response = await _dio.delete(
        url,
        options: await _getAuthOptions(),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return ApiResponse<bool>(success: true, data: true, message: 'Deleted');
      } else {
        return ApiResponse<bool>(
          success: false,
          data: false,
          message: response.data['message'] ?? 'Failed to delete',
        );
      }
    } catch (e) {
      return ApiResponse<bool>(success: false, data: false, message: 'Error: $e');
    }
  }
}