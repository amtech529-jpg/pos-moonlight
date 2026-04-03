import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/sales/sale_model.dart';
import '../utils/storage_service.dart';

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();
  factory InvoiceService() => _instance;
  InvoiceService._internal();

  final Dio _dio = Dio();
  final StorageService _storageService = StorageService();

  Future<Options> _getAuthOptions() async {
    final token = await _storageService.getToken() ?? '';
    return Options(
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      },
      // ✅ Allow 500 so we can parse the error message from backend
      validateStatus: (status) => status != null && status < 600,
    );
  }

  String _getUrl(String endpoint) {
    final fullUrl = '${ApiConfig.baseUrl}$endpoint';
    debugPrint('🔗 [InvoiceService] Constructed URL: $fullUrl');
    return fullUrl;
  }

  Future<ApiResponse<InvoiceModel>> createInvoice({
    required String saleId,
    DateTime? dueDate,
    String? notes,
    String? termsConditions,
  }) async {
    final url = _getUrl(ApiConfig.createInvoice);

    // ✅ Formatting Date strictly as YYYY-MM-DD
    final String? formattedDate = dueDate != null
        ? DateFormat('yyyy-MM-dd').format(dueDate)
        : null;

    final Map<String, dynamic> data = {
      'sale': saleId,
      'status': 'DRAFT',
      if (formattedDate != null) 'due_date': formattedDate,
      'notes': notes ?? '',
      'terms_conditions': termsConditions ?? 'Standard terms apply',
    };

    debugPrint('🚀 [InvoiceService] Payload: $data');

    try {
      final response = await _dio.post(
        url,
        options: await _getAuthOptions(),
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<InvoiceModel>.fromJson(
          response.data,
              (data) => InvoiceModel.fromJson(data),
        );
      } else if (response.statusCode == 500) {
        // ✅ Specific handling for the Backend Crash
        debugPrint('🔥 [InvoiceService] 500 Error: ${response.data}');
        return ApiResponse<InvoiceModel>(
          success: false,
          message: 'Server Error: The invoice might already exist, or the date format is rejected by the server.',
          errors: {'detail': 'Backend Logic Error (500)'},
        );
      } else {
        debugPrint('❌ [InvoiceService] Failed: ${response.data}');
        return ApiResponse<InvoiceModel>(
          success: false,
          message: response.data['message'] ?? response.data['detail'] ?? 'Failed to create invoice',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      return ApiResponse<InvoiceModel>(
        success: false,
        message: 'Connection Error: $e',
      );
    }
  }

  // --- Other Methods (List, Update, Delete, Generate PDF) ---

  Future<ApiResponse<List<InvoiceModel>>> listInvoices({
    String? status,
    String? customerId,
    String? dateFrom,
    String? dateTo,
    String? search,
    bool? showInactive,
    int? page,
    int? pageSize,
  }) async {
    final url = _getUrl(ApiConfig.invoices);
    debugPrint('🔍 [InvoiceService] Loading invoices from: $url');
    
    try {
      final response = await _dio.get(
        url,
        options: await _getAuthOptions(),
        queryParameters: {
          if (status != null) 'status': status,
          if (customerId != null) 'customer_id': customerId,
          if (dateFrom != null) 'date_from': dateFrom,
          if (dateTo != null) 'date_to': dateTo,
          if (search != null) 'search': search,
          if (showInactive != null) 'show_inactive': showInactive.toString(),
        },
      );

      debugPrint('🔍 [InvoiceService] Response status: ${response.statusCode}');
      debugPrint('🔍 [InvoiceService] Response data type: ${response.data.runtimeType}');
      debugPrint('🔍 [InvoiceService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        List<dynamic> listData = [];
        
        // Handle different response formats
        if (response.data == null) {
          debugPrint('🔍 [InvoiceService] Response data is null');
          return ApiResponse<List<InvoiceModel>>(
              success: true,
              data: [],
              message: 'No invoices found'
          );
        } else if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          if (dataMap.containsKey('results')) {
            listData = dataMap['results'];
            debugPrint('🔍 [InvoiceService] Found ${listData.length} invoices in results');
          } else if (dataMap.containsKey('data')) {
            listData = dataMap['data'];
            debugPrint('🔍 [InvoiceService] Found ${listData.length} invoices in data');
          } else {
            // If it's a map but no results/data, maybe it's empty
            debugPrint('🔍 [InvoiceService] Map response without results/data: ${dataMap.keys}');
            listData = [];
          }
        } else if (response.data is List) {
          listData = response.data;
          debugPrint('🔍 [InvoiceService] Found ${listData.length} invoices in list');
        } else {
          debugPrint('🔍 [InvoiceService] Unexpected response format: ${response.data.runtimeType}');
          listData = [];
        }

        debugPrint('🔍 [InvoiceService] Total items to parse: ${listData.length}');
        
        final invoices = <InvoiceModel>[];
        for (int i = 0; i < listData.length; i++) {
          try {
            final item = listData[i];
            debugPrint('🔍 [InvoiceService] Parsing item $i: $item');
            final invoice = InvoiceModel.fromJson(item as Map<String, dynamic>);
            invoices.add(invoice);
            debugPrint('✅ [InvoiceService] Successfully parsed item $i: ${invoice.invoiceNumber}');
          } catch (e) {
            debugPrint('❌ [InvoiceService] Error parsing item $i: $e');
            debugPrint('❌ [InvoiceService] Item data: ${listData[i]}');
            // Continue with other items even if one fails
          }
        }
        
        debugPrint('🔍 [InvoiceService] Successfully parsed ${invoices.length} out of ${listData.length} InvoiceModel objects');
        
        return ApiResponse<List<InvoiceModel>>(
            success: true,
            data: invoices,
            message: 'Invoices loaded successfully'
        );
      } else {
        debugPrint('❌ [InvoiceService] Failed with status: ${response.statusCode}');
        return ApiResponse<List<InvoiceModel>>(
            success: false,
            data: [],
            message: 'Failed to load invoices: Status ${response.statusCode}'
        );
      }
    } catch (e) {
      debugPrint('❌ [InvoiceService] Exception loading invoices: $e');
      return ApiResponse<List<InvoiceModel>>(
          success: false,
          data: [],
          message: 'Error: $e'
      );
    }
  }

  Future<ApiResponse<InvoiceModel>> updateInvoice({
    required String id,
    DateTime? dueDate,
    String? notes,
    String? termsConditions,
    String? status,
    double? writeOffAmount,
  }) async {
    final url = _getUrl(ApiConfig.updateInvoice(id));
    final String? formattedDate = dueDate != null
        ? DateFormat('yyyy-MM-dd').format(dueDate)
        : null;

    debugPrint('🔍 [InvoiceService] Updating invoice at: $url');
    debugPrint('🔍 [InvoiceService] Due date: $formattedDate');
    debugPrint('🔍 [InvoiceService] Status: $status');
    debugPrint('🔍 [InvoiceService] Notes: $notes');

    try {
      final response = await _dio.put(
        url,
        options: await _getAuthOptions(),
        data: {
          if (formattedDate != null) 'due_date': formattedDate,
          if (notes != null) 'notes': notes,
          if (termsConditions != null) 'terms_conditions': termsConditions,
          if (status != null) 'status': status,
          if (writeOffAmount != null) 'write_off_amount': writeOffAmount,
        },
      );

      debugPrint('🔍 [InvoiceService] Update response status: ${response.statusCode}');
      debugPrint('🔍 [InvoiceService] Update response data: ${response.data}');

      if (response.statusCode == 200) {
        return ApiResponse<InvoiceModel>.fromJson(
          response.data,
              (data) => InvoiceModel.fromJson(data),
        );
      } else {
        debugPrint('❌ [InvoiceService] Update failed with status: ${response.statusCode}');
        return ApiResponse<InvoiceModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to update invoice',
        );
      }
    } catch (e) {
      debugPrint('❌ [InvoiceService] Exception updating invoice: $e');
      return ApiResponse<InvoiceModel>(
        success: false,
        message: 'Error updating invoice: $e',
      );
    }
  }

  Future<ApiResponse<bool>> deleteInvoice(String id) async {
    final url = _getUrl(ApiConfig.deleteInvoice(id));
    
    debugPrint('🔍 [InvoiceService] Deleting invoice at: $url');
    
    try {
      final response = await _dio.delete(
        url, 
        options: await _getAuthOptions(),
      );
      
      debugPrint('🔍 [InvoiceService] Delete response status: ${response.statusCode}');
      debugPrint('🔍 [InvoiceService] Delete response data: ${response.data}');
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('✅ [InvoiceService] Invoice deleted successfully');
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'Invoice deleted successfully'
        );
      } else {
        debugPrint('❌ [InvoiceService] Delete failed with status: ${response.statusCode}');
        
        // Try to extract error message from response
        String errorMessage = 'Failed to delete invoice';
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = response.data['message'];
        } else if (response.data is String) {
          errorMessage = response.data;
        }
        
        return ApiResponse<bool>(success: false, message: errorMessage);
      }
    } catch (e) {
      debugPrint('❌ [InvoiceService] Exception deleting invoice: $e');
      
      // Extract more detailed error information
      String errorMessage = 'Error deleting invoice';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error: Could not connect to server';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout: Server took too long to respond';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Invoice not found or already deleted';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Permission denied: Cannot delete this invoice';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server error: Delete operation failed';
      } else {
        errorMessage = 'Error: $e';
      }
      
      return ApiResponse<bool>(success: false, message: errorMessage);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> generateInvoicePdf(String id) async {
    final url = _getUrl(ApiConfig.generateInvoicePdf(id));
    
    debugPrint('🔍 [InvoiceService] Generating PDF at: $url');
    
    try {
      final response = await _dio.post(
        url, 
        options: await _getAuthOptions(),
      );
      
      debugPrint('🔍 [InvoiceService] PDF response status: ${response.statusCode}');
      debugPrint('🔍 [InvoiceService] PDF response data: ${response.data}');
      
      if (response.statusCode == 200) {
        // Check if response contains PDF data or success message
        if (response.data != null) {
          debugPrint('✅ [InvoiceService] PDF generated successfully');
          
          // If response contains a file URL, we can download it
          if (response.data['file_url'] != null) {
            debugPrint('🔍 [InvoiceService] PDF file URL available: ${response.data['file_url']}');
            // You could add download logic here if needed
          }
          
          // If response contains base64 data, we could decode and save it
          if (response.data['file_data'] != null) {
            debugPrint('🔍 [InvoiceService] PDF contains base64 data');
            // You could add base64 decode and save logic here
          }
          
          return ApiResponse<Map<String, dynamic>>.fromJson(
              response.data, (d) => d as Map<String, dynamic>
          );
        } else {
          debugPrint('❌ [InvoiceService] PDF response data is null');
          return ApiResponse<Map<String, dynamic>>(
            success: false, 
            message: 'PDF generation returned empty response'
          );
        }
      } else {
        debugPrint('❌ [InvoiceService] PDF generation failed with status: ${response.statusCode}');
        debugPrint('❌ [InvoiceService] Response: ${response.data}');
        
        // Try to extract error message from response
        String errorMessage = 'Failed PDF gen';
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = response.data['message'];
        } else if (response.data is String) {
          errorMessage = response.data;
        }
        
        return ApiResponse<Map<String, dynamic>>(
          success: false, 
          message: errorMessage
        );
      }
    } catch (e) {
      debugPrint('❌ [InvoiceService] Exception generating PDF: $e');
      
      // Extract more detailed error information
      String errorMessage = 'Error generating PDF';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error: Could not connect to server';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout: Server took too long to respond';
      } else if (e.toString().contains('404')) {
        errorMessage = 'PDF generation endpoint not found';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server error: PDF generation failed on server';
      } else {
        errorMessage = 'Error: $e';
      }
      
      return ApiResponse<Map<String, dynamic>>(
        success: false, 
        message: errorMessage
      );
    }
  }

  /// Generate thermal print data for an invoice
  Future<ApiResponse<Map<String, dynamic>>> generateInvoiceThermalPrint(String invoiceId) async {
    debugPrint('🔍 [InvoiceService] Generating thermal print for invoice: $invoiceId');
    
    try {
      final url = '${ApiConfig.baseUrl}${ApiConfig.generateInvoiceThermalPrint(invoiceId)}';
      debugPrint('🔗 [InvoiceService] Constructed URL: $url');
      debugPrint('🔍 [InvoiceService] Generating thermal print at: $url');
      
      final response = await _dio.post(
        url,
        options: await _getAuthOptions(),
      );
      
      debugPrint('🔍 [InvoiceService] Thermal print response status: ${response.statusCode}');
      debugPrint('🔍 [InvoiceService] Thermal print response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map && response.data['success'] == true) {
          debugPrint('✅ [InvoiceService] Thermal print data generated successfully');
          return ApiResponse<Map<String, dynamic>>(
            success: true, 
            message: 'Thermal print data generated successfully',
            data: response.data['data'] ?? {}
          );
        } else {
          debugPrint('❌ [InvoiceService] Thermal print generation failed with response: ${response.data}');
          String errorMessage = 'Failed to generate thermal print data';
          if (response.data is Map && response.data['message'] != null) {
            errorMessage = response.data['message'];
          }
          return ApiResponse<Map<String, dynamic>>(
            success: false, 
            message: errorMessage
          );
        }
      } else {
        debugPrint('❌ [InvoiceService] Thermal print generation failed with status: ${response.statusCode}');
        debugPrint('❌ [InvoiceService] Response: ${response.data}');
        
        String errorMessage = 'Failed thermal print generation';
        if (response.data is Map && response.data['message'] != null) {
          errorMessage = response.data['message'];
        } else if (response.data is String) {
          errorMessage = response.data;
        }
        
        return ApiResponse<Map<String, dynamic>>(
          success: false, 
          message: errorMessage
        );
      }
    } catch (e) {
      debugPrint('❌ [InvoiceService] Exception generating thermal print: $e');
      
      String errorMessage = 'Error generating thermal print';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error: Could not connect to server';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout: Server took too long to respond';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Thermal print endpoint not found';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Server error: Thermal print generation failed on server';
      } else {
        errorMessage = 'Error: $e';
      }
      
      return ApiResponse<Map<String, dynamic>>(
        success: false, 
        message: errorMessage
      );
    }
  }

  /// Generate an invoice from an order
  Future<ApiResponse<InvoiceModel>> generateInvoiceFromOrder({
    required String orderId,
  }) async {
    final url = _getUrl(ApiConfig.generateInvoiceFromOrder);
    debugPrint('🚀 [InvoiceService] Generating invoice from order: $orderId');

    try {
      final response = await _dio.post(
        url,
        options: await _getAuthOptions(),
        data: {'order_id': orderId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          return ApiResponse<InvoiceModel>(
            success: true,
            message: responseData['message'] ?? 'Invoice generated successfully',
            data: InvoiceModel.fromJson(responseData['data']),
          );
        }
        return ApiResponse<InvoiceModel>(
          success: false,
          message: responseData['message'] ?? 'Failed to generate invoice',
        );
      } else {
        return ApiResponse<InvoiceModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to generate invoice',
        );
      }
    } catch (e) {
      debugPrint('❌ [InvoiceService] Exception generating invoice from order: $e');
      return ApiResponse<InvoiceModel>(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Apply a payment to an invoice
  Future<ApiResponse<Map<String, dynamic>>> applyInvoicePayment({
    required String invoiceId,
    required double amount,
    String paymentMethod = 'CASH',
    String? reference,
  }) async {
    final url = _getUrl(ApiConfig.applyInvoicePayment(invoiceId));
    debugPrint('🚀 [InvoiceService] Applying payment of $amount to invoice: $invoiceId');

    try {
      final response = await _dio.post(
        url,
        options: await _getAuthOptions(),
        data: {
          'amount': amount,
          'payment_method': paymentMethod,
          if (reference != null) 'reference': reference,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true) {
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            message: responseData['message'] ?? 'Payment applied successfully',
            data: responseData['data'],
          );
        }
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: responseData['message'] ?? 'Failed to apply payment',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: response.data['message'] ?? 'Failed to apply payment',
        );
      }
    } catch (e) {
      debugPrint('❌ [InvoiceService] Exception applying payment: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Write off remaining balance on an invoice
  Future<ApiResponse<InvoiceModel>> writeOffInvoice({
    required String invoiceId,
    double? amount,
    String? reason,
  }) async {
    final url = _getUrl(ApiConfig.writeOffInvoice(invoiceId));
    debugPrint('🚀 [InvoiceService] Writing off invoice: $invoiceId');

    try {
      final response = await _dio.post(
        url,
        options: await _getAuthOptions(),
        data: {
          if (amount != null) 'amount': amount,
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          return ApiResponse<InvoiceModel>(
            success: true,
            message: responseData['message'] ?? 'Write-off applied successfully',
            data: InvoiceModel.fromJson(responseData['data']),
          );
        }
        return ApiResponse<InvoiceModel>(
          success: false,
          message: responseData['message'] ?? 'Failed to apply write-off',
        );
      } else {
        return ApiResponse<InvoiceModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to apply write-off',
        );
      }
    } catch (e) {
      debugPrint('❌ [InvoiceService] Exception writing off invoice: $e');
      return ApiResponse<InvoiceModel>(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Get invoice ledger summary
  Future<ApiResponse<Map<String, dynamic>>> getInvoiceLedger({
    String? customerId,
  }) async {
    final url = _getUrl(ApiConfig.invoiceLedger);
    debugPrint('🚀 [InvoiceService] Loading invoice ledger');

    try {
      final response = await _dio.get(
        url,
        options: await _getAuthOptions(),
        queryParameters: {
          if (customerId != null) 'customer_id': customerId,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            message: 'Ledger loaded successfully',
            data: responseData['data'],
          );
        }
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: responseData['message'] ?? 'Failed to load ledger',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Failed to load ledger',
        );
      }
    } catch (e) {
      debugPrint('❌ [InvoiceService] Exception loading ledger: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error: $e',
      );
    }
  }
}