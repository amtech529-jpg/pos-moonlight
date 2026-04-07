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
      validateStatus: (status) => status != null && status < 600,
    );
  }

  String _getUrl(String endpoint) {
    return '${ApiConfig.baseUrl}$endpoint';
  }

  Future<ApiResponse<InvoiceModel>> createInvoice({
    required String saleId,
    DateTime? dueDate,
    String? notes,
    String? termsConditions,
  }) async {
    final url = _getUrl(ApiConfig.createInvoice);
    final String? formattedDate = dueDate != null ? DateFormat('yyyy-MM-dd').format(dueDate) : null;

    try {
      final response = await _dio.post(
        url,
        options: await _getAuthOptions(),
        data: {
          'sale': saleId,
          'status': 'DRAFT',
          if (formattedDate != null) 'due_date': formattedDate,
          if (notes != null) 'notes': notes,
          if (termsConditions != null) 'terms_conditions': termsConditions,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<InvoiceModel>.fromJson(
          response.data,
          (data) => InvoiceModel.fromJson(data),
        );
      } else {
        return ApiResponse<InvoiceModel>(
          success: false,
          message: response.data['message'] ?? 'Failed to create invoice',
        );
      }
    } catch (e) {
      return ApiResponse<InvoiceModel>(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  Future<ApiResponse<List<InvoiceModel>>> listInvoices({
    String? status,
    String? customerId,
    String? dateFrom,
    String? dateTo,
    String? search,
    bool? showInactive,
  }) async {
    final url = _getUrl(ApiConfig.invoices);
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

      if (response.statusCode == 200) {
        List<dynamic> listData = [];
        if (response.data is Map<String, dynamic>) {
          listData = response.data['results'] ?? response.data['data'] ?? [];
        } else if (response.data is List) {
          listData = response.data;
        }

        final invoices = listData.map((item) => InvoiceModel.fromJson(item as Map<String, dynamic>)).toList();
        return ApiResponse<List<InvoiceModel>>(
          success: true,
          data: invoices,
          message: 'Invoices loaded successfully',
        );
      } else {
        return ApiResponse<List<InvoiceModel>>(success: false, data: [], message: 'Failed to load');
      }
    } catch (e) {
      return ApiResponse<List<InvoiceModel>>(success: false, data: [], message: 'Error: $e');
    }
  }

  Future<ApiResponse<InvoiceModel>> getInvoiceById(String id) async {
    final url = _getUrl(ApiConfig.getInvoiceById(id));
    try {
      final response = await _dio.get(url, options: await _getAuthOptions());
      if (response.statusCode == 200) {
        return ApiResponse<InvoiceModel>.fromJson(
          response.data,
          (data) => InvoiceModel.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<InvoiceModel>(success: false, message: 'Not found');
      }
    } catch (e) {
      return ApiResponse<InvoiceModel>(success: false, message: 'Error: $e');
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
    final String? formattedDate = dueDate != null ? DateFormat('yyyy-MM-dd').format(dueDate) : null;
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
      if (response.statusCode == 200) {
        return ApiResponse<InvoiceModel>.fromJson(response.data, (data) => InvoiceModel.fromJson(data));
      }
      return ApiResponse<InvoiceModel>(success: false, message: 'Failed update');
    } catch (e) {
      return ApiResponse<InvoiceModel>(success: false, message: 'Error: $e');
    }
  }

  Future<ApiResponse<bool>> deleteInvoice(String id) async {
    final url = _getUrl(ApiConfig.deleteInvoice(id));
    try {
      final response = await _dio.delete(url, options: await _getAuthOptions());
      return ApiResponse<bool>(
        success: response.statusCode == 204 || response.statusCode == 200, 
        data: true,
        message: 'Deleted'
      );
    } catch (e) {
      return ApiResponse<bool>(success: false, message: 'Error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> generateInvoicePdf(String id) async {
    final url = _getUrl(ApiConfig.generateInvoicePdf(id));
    try {
      final response = await _dio.post(url, options: await _getAuthOptions());
      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.fromJson(response.data, (d) => d as Map<String, dynamic>);
      }
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'Failed PDF');
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'Error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> generateInvoiceThermalPrint(String invoiceId) async {
    final url = _getUrl(ApiConfig.generateInvoiceThermalPrint(invoiceId));
    try {
      final response = await _dio.post(url, options: await _getAuthOptions());
      if (response.statusCode == 200 && response.data != null) {
        return ApiResponse<Map<String, dynamic>>(
          success: true, 
          message: 'Success',
          data: response.data['data'] ?? {}
        );
      }
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'Failed Print');
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'Error: $e');
    }
  }

  Future<ApiResponse<InvoiceModel>> generateInvoiceFromOrder({required String orderId}) async {
    final url = _getUrl(ApiConfig.generateInvoiceFromOrder);
    try {
      final response = await _dio.post(url, options: await _getAuthOptions(), data: {'order_id': orderId});
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<InvoiceModel>.fromJson(response.data, (d) => InvoiceModel.fromJson(d));
      }
      return ApiResponse<InvoiceModel>(success: false, message: 'Failed Gen');
    } catch (e) {
      return ApiResponse<InvoiceModel>(success: false, message: 'Error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> applyInvoicePayment({
    required String invoiceId,
    required double amount,
    String paymentMethod = 'CASH',
    String? reference,
  }) async {
    final url = _getUrl(ApiConfig.applyInvoicePayment(invoiceId));
    try {
      final response = await _dio.post(url, options: await _getAuthOptions(), data: {
        'amount': amount,
        'payment_method': paymentMethod,
        if (reference != null) 'reference': reference,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<Map<String, dynamic>>(
          success: true, 
          message: 'Success',
          data: response.data['data']
        );
      }
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'Failed Payment');
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'Error: $e');
    }
  }

  Future<ApiResponse<InvoiceModel>> writeOffInvoice({
    required String invoiceId,
    double? amount,
    String? reason,
  }) async {
    final url = _getUrl(ApiConfig.writeOffInvoice(invoiceId));
    try {
      final response = await _dio.post(url, options: await _getAuthOptions(), data: {
        if (amount != null) 'amount': amount,
        if (reason != null) 'reason': reason,
      });
      if (response.statusCode == 200) {
        return ApiResponse<InvoiceModel>.fromJson(response.data, (d) => InvoiceModel.fromJson(d));
      }
      return ApiResponse<InvoiceModel>(success: false, message: 'Failed Writeoff');
    } catch (e) {
      return ApiResponse<InvoiceModel>(success: false, message: 'Error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getInvoiceLedger({String? customerId}) async {
    final url = _getUrl(ApiConfig.invoiceLedger);
    try {
      final response = await _dio.get(url, options: await _getAuthOptions(), queryParameters: {
        if (customerId != null) 'customer_id': customerId,
      });
      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true, 
          message: 'Success',
          data: response.data['data']
        );
      }
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'Failed Ledger');
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'Error: $e');
    }
  }
}