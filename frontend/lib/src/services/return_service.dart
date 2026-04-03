import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/sales/return_model.dart';
import '../models/api_response.dart';
import '../utils/storage_service.dart';

class ReturnService {
  static final ReturnService _instance = ReturnService._internal();
  factory ReturnService() => _instance;
  ReturnService._internal();

  final Dio _dio = Dio();
  final StorageService _storageService = StorageService();

  Future<Options> _getAuthOptions() async {
    final token = await _storageService.getToken() ?? '';

    if (token.isEmpty) {
      debugPrint('⚠️ [ReturnService] Warning: No Auth Token found in StorageService!');
    }

    return Options(
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $token',
      },
      validateStatus: (status) {
        return status! < 500;
      },
    );
  }

  String _getUrl(String endpoint) {
    return '${ApiConfig.baseUrl}$endpoint';
  }

  // ---------------------------------------------------------------------------
  // Return Management
  // ---------------------------------------------------------------------------

  Future<ApiResponse<List<ReturnModel>>> getReturns({
    String? search,
    String? status,
    String? reason,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? pageSize,
  }) async {
    final url = _getUrl(ApiConfig.returnsEndpoint);
    debugPrint('🚀 [ReturnService] GET $url');

    try {
      final response = await _dio.get(
        url,
        options: await _getAuthOptions(),
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
          if (page != null) 'page': page,
          if (pageSize != null) 'page_size': pageSize,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = (response.data is Map && response.data.containsKey('results'))
            ? response.data['results']
            : (response.data is List ? response.data : []);

        final returns = data.map((json) => ReturnModel.fromJson(json)).toList();
        debugPrint('✅ [ReturnService] Loaded ${returns.length} returns');
        return ApiResponse<List<ReturnModel>>(success: true, data: returns, message: 'Returns loaded successfully');
      } else {
        debugPrint('❌ [ReturnService] Failed: ${response.data}');
        return ApiResponse<List<ReturnModel>>(success: false, data: null, message: response.data['detail'] ?? 'Failed to load returns');
      }
    } catch (e) {
      debugPrint('🛑 [ReturnService] Exception: $e');
      return ApiResponse<List<ReturnModel>>(success: false, data: null, message: 'Error loading returns: $e');
    }
  }

  Future<ApiResponse<ReturnModel>> getReturn(String id) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}$id/');
    try {
      debugPrint('🔄 [ReturnService] Getting return $id');
      final response = await _dio.get(url, options: await _getAuthOptions());
      debugPrint('📋 [ReturnService] Response data: ${response.data}');
      if (response.statusCode == 200) {
        debugPrint('✅ [ReturnService] Parsing return data...');
        final returnModel = ReturnModel.fromJson(response.data);
        debugPrint('✅ [ReturnService] Return parsed successfully: ${returnModel.returnNumber}');
        return ApiResponse<ReturnModel>(success: true, data: returnModel, message: 'Return loaded');
      } else {
        debugPrint('❌ [ReturnService] Failed to load return: ${response.data}');
        return ApiResponse<ReturnModel>(success: false, data: null, message: response.data['detail'] ?? 'Failed to load');
      }
    } catch (e) {
      debugPrint('❌ [ReturnService] Error getting return: $e');
      return ApiResponse<ReturnModel>(success: false, data: null, message: 'Error: $e');
    }
  }

  Future<ApiResponse<ReturnModel>> createReturn({
    required String saleId,
    String? customerId, // ✅ Changed to nullable
    required String reason,
    String? reasonDetails,
    String? notes,
    required List<Map<String, dynamic>> returnItems,
  }) async {
    final url = _getUrl(ApiConfig.returnsEndpoint);
    debugPrint('🚀 [ReturnService] POST $url');

    try {
      final response = await _dio.post(
        url,
        options: await _getAuthOptions(),
        data: {
          'sale': saleId,
          'customer': customerId, // Can be null now
          'reason': reason,
          if (reasonDetails != null) 'reason_details': reasonDetails,
          if (notes != null) 'notes': notes,
          'return_items': returnItems,
        },
      );

      if (response.statusCode == 201) {
        debugPrint('✅ [ReturnService] Created Successfully');
        return ApiResponse<ReturnModel>(success: true, data: ReturnModel.fromJson(response.data), message: 'Return created');
      } else {
        debugPrint('❌ [ReturnService] Failed: ${response.data}');
        return ApiResponse<ReturnModel>(success: false, data: null, message: response.data['detail'] ?? 'Failed to create');
      }
    } catch (e) {
      debugPrint('🛑 [ReturnService] Exception: $e');
      return ApiResponse<ReturnModel>(success: false, data: null, message: 'Error: $e');
    }
  }

  Future<ApiResponse<ReturnModel>> updateReturn({required String id, String? reason, String? reasonDetails, String? notes}) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}$id/');
    try {
      final response = await _dio.patch(
        url,
        options: await _getAuthOptions(),
        data: {if (reason != null) 'reason': reason, if (reasonDetails != null) 'reason_details': reasonDetails, if (notes != null) 'notes': notes},
      );
      if (response.statusCode == 200) {
        return ApiResponse<ReturnModel>(success: true, data: ReturnModel.fromJson(response.data), message: 'Updated successfully');
      } else {
        return ApiResponse<ReturnModel>(success: false, data: null, message: response.data['detail'] ?? 'Failed to update');
      }
    } catch (e) {
      return ApiResponse<ReturnModel>(success: false, data: null, message: 'Error: $e');
    }
  }

  Future<ApiResponse<bool>> deleteReturn(String id) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}$id/');
    try {
      final response = await _dio.delete(url, options: await _getAuthOptions());
      if (response.statusCode == 204) {
        return ApiResponse<bool>(success: true, data: true, message: 'Deleted successfully');
      } else {
        return ApiResponse<bool>(success: false, data: false, message: response.data['detail'] ?? 'Failed to delete');
      }
    } catch (e) {
      return ApiResponse<bool>(success: false, data: false, message: 'Error: $e');
    }
  }

  // --- Workflow Actions ---

  Future<ApiResponse<ReturnModel>> approveReturn({required String id, String? reason}) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}$id/approve/');
    debugPrint('🚀 [ReturnService] POST $url');
    try {
      final response = await _dio.patch(
        url,
        options: await _getAuthOptions(),
        data: {'action': 'approve', if (reason != null) 'reason': reason},
      );
      if (response.statusCode == 200) {
        // After approval, fetch the updated return data
        final updatedReturn = await getReturn(id);
        if (updatedReturn.success) {
          return ApiResponse<ReturnModel>(success: true, data: updatedReturn.data!, message: 'Approved successfully');
        } else {
          return ApiResponse<ReturnModel>(success: false, data: null, message: 'Failed to fetch updated return');
        }
      } else {
        debugPrint('❌ [ReturnService] Approve Failed: ${response.data}');
        return ApiResponse<ReturnModel>(success: false, data: null, message: response.data['detail'] ?? 'Failed to approve');
      }
    } catch (e) {
      return ApiResponse<ReturnModel>(success: false, data: null, message: 'Error: $e');
    }
  }

  Future<ApiResponse<ReturnModel>> rejectReturn({required String id, required String reason}) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}$id/approve/');
    try {
      final response = await _dio.patch(
          url,
          options: await _getAuthOptions(),
          data: {'action': 'reject', 'reason': reason}
      );
      if (response.statusCode == 200) {
        // After rejection, fetch the updated return data
        final updatedReturn = await getReturn(id);
        if (updatedReturn.success) {
          return ApiResponse<ReturnModel>(success: true, data: updatedReturn.data!, message: 'Rejected successfully');
        } else {
          return ApiResponse<ReturnModel>(success: false, data: null, message: 'Failed to fetch updated return');
        }
      } else {
        return ApiResponse<ReturnModel>(success: false, data: null, message: response.data['detail'] ?? 'Failed to reject');
      }
    } catch (e) {
      return ApiResponse<ReturnModel>(success: false, data: null, message: 'Error: $e');
    }
  }

  Future<ApiResponse<ReturnModel>> processReturn({required String id, double? refundAmount, String? refundMethod}) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}$id/process/');
    try {
      final response = await _dio.patch(
        url,
        options: await _getAuthOptions(),
        data: {if (refundAmount != null) 'refund_amount': refundAmount, if (refundMethod != null) 'refund_method': refundMethod},
      );
      if (response.statusCode == 200) {
        // After processing, fetch the updated return data
        final updatedReturn = await getReturn(id);
        if (updatedReturn.success) {
          return ApiResponse<ReturnModel>(success: true, data: updatedReturn.data!, message: 'Processed successfully');
        } else {
          return ApiResponse<ReturnModel>(success: false, data: null, message: 'Failed to fetch updated return');
        }
      } else {
        return ApiResponse<ReturnModel>(success: false, data: null, message: response.data['detail'] ?? 'Failed to process');
      }
    } catch (e) {
      return ApiResponse<ReturnModel>(success: false, data: null, message: 'Error: $e');
    }
  }

  // --- Refund Management ---

  Future<ApiResponse<List<RefundModel>>> getRefunds({
    String? search,
    String? status,
    String? method,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? pageSize,
  }) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}refunds/');
    debugPrint('🚀 [ReturnService] GET $url');
    try {
      final response = await _dio.get(
        url,
        options: await _getAuthOptions(),
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          if (method != null && method.isNotEmpty) 'method': method,
          if (startDate != null) 'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
          if (page != null) 'page': page,
          if (pageSize != null) 'page_size': pageSize,
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = (response.data is Map && response.data.containsKey('results'))
            ? response.data['results']
            : (response.data is List ? response.data : []);

        debugPrint('🔍 [ReturnService] Refunds response data: $data');
        debugPrint('🔍 [ReturnService] Number of refunds: ${data.length}');

        final refunds = data.map((json) => RefundModel.fromJson(json)).toList();
        debugPrint('✅ [ReturnService] Loaded ${refunds.length} refunds');
        return ApiResponse<List<RefundModel>>(success: true, data: refunds, message: 'Refunds loaded');
      } else {
        return ApiResponse<List<RefundModel>>(success: false, data: null, message: response.data['detail'] ?? 'Failed to load');
      }
    } catch (e) {
      return ApiResponse<List<RefundModel>>(success: false, data: null, message: 'Error: $e');
    }
  }

  Future<ApiResponse<RefundModel>> getRefund(String id) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}refunds/$id/');
    try {
      final response = await _dio.get(url, options: await _getAuthOptions());
      if (response.statusCode == 200) {
        return ApiResponse<RefundModel>(success: true, data: RefundModel.fromJson(response.data), message: 'Loaded');
      } else {
        return ApiResponse<RefundModel>(success: false, data: null, message: response.data['detail'] ?? 'Failed');
      }
    } catch (e) {
      return ApiResponse<RefundModel>(success: false, data: null, message: 'Error: $e');
    }
  }

  Future<ApiResponse<RefundModel>> createRefund({
    required String returnRequestId,
    required double amount,
    required String method,
    String? notes,
    String? referenceNumber,
  }) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}refunds/');
    try {
      final response = await _dio.post(
        url,
        options: await _getAuthOptions(),
        data: {
          'return_request': returnRequestId,
          'amount': amount,
          'method': method,
          if (notes != null) 'notes': notes,
          if (referenceNumber != null) 'reference_number': referenceNumber,
        },
      );
      if (response.statusCode == 201) {
        return ApiResponse<RefundModel>(success: true, data: RefundModel.fromJson(response.data), message: 'Created');
      } else {
        return ApiResponse<RefundModel>(success: false, data: null, message: response.data['detail'] ?? 'Failed');
      }
    } catch (e) {
      return ApiResponse<RefundModel>(success: false, data: null, message: 'Error: $e');
    }
  }

  Future<ApiResponse<RefundModel>> updateRefund({required String id, String? method, String? notes, String? referenceNumber}) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}refunds/$id/');
    try {
      final response = await _dio.patch(
        url,
        options: await _getAuthOptions(),
        data: {if (method != null) 'method': method, if (notes != null) 'notes': notes, if (referenceNumber != null) 'reference_number': referenceNumber},
      );
      if (response.statusCode == 200) {
        return ApiResponse<RefundModel>(success: true, data: RefundModel.fromJson(response.data), message: 'Updated');
      } else {
        return ApiResponse<RefundModel>(success: false, data: null, message: response.data['detail'] ?? 'Failed');
      }
    } catch (e) {
      return ApiResponse<RefundModel>(success: false, data: null, message: 'Error: $e');
    }
  }

  Future<ApiResponse<bool>> deleteRefund(String id) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}refunds/$id/');
    try {
      final response = await _dio.delete(url, options: await _getAuthOptions());
      if (response.statusCode == 204) {
        return ApiResponse<bool>(success: true, data: true, message: 'Deleted');
      } else {
        return ApiResponse<bool>(success: false, data: false, message: response.data['detail'] ?? 'Failed');
      }
    } catch (e) {
      return ApiResponse<bool>(success: false, data: false, message: 'Error: $e');
    }
  }

  Future<ApiResponse<RefundModel>> processRefund({required String id, String? referenceNumber, String? notes}) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}refunds/$id/process/');
    try {
      final response = await _dio.patch(
        url,
        options: await _getAuthOptions(),
        data: {if (referenceNumber != null) 'reference_number': referenceNumber, if (notes != null) 'notes': notes},
      );
      if (response.statusCode == 200) {
        return ApiResponse<RefundModel>(success: true, data: RefundModel.fromJson(response.data), message: 'Processed');
      } else {
        return ApiResponse<RefundModel>(success: false, data: null, message: response.data['detail'] ?? 'Failed');
      }
    } catch (e) {
      return ApiResponse<RefundModel>(success: false, data: null, message: 'Error: $e');
    }
  }

  Future<ApiResponse<RefundModel>> failRefund({required String id, String? notes}) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}refunds/$id/fail/');
    try {
      final response = await _dio.patch(url, options: await _getAuthOptions(), data: {if (notes != null) 'notes': notes});
      if (response.statusCode == 200) {
        return ApiResponse<RefundModel>(success: true, data: RefundModel.fromJson(response.data), message: 'Marked failed');
      } else {
        return ApiResponse<RefundModel>(success: false, data: null, message: response.data['detail'] ?? 'Failed');
      }
    } catch (e) {
      return ApiResponse<RefundModel>(success: false, data: null, message: 'Error: $e');
    }
  }

  Future<ApiResponse<RefundModel>> cancelRefund({required String id, String? notes}) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}refunds/$id/cancel/');
    try {
      final response = await _dio.patch(url, options: await _getAuthOptions(), data: {if (notes != null) 'notes': notes});
      if (response.statusCode == 200) {
        return ApiResponse<RefundModel>(success: true, data: RefundModel.fromJson(response.data), message: 'Cancelled');
      } else {
        return ApiResponse<RefundModel>(success: false, data: null, message: response.data['detail'] ?? 'Failed');
      }
    } catch (e) {
      return ApiResponse<RefundModel>(success: false, data: null, message: 'Error: $e');
    }
  }

  // --- Statistics and History ---

  Future<ApiResponse<Map<String, dynamic>>> getReturnStatistics() async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}statistics/');
    debugPrint('🚀 [ReturnService] GET Stats $url');
    try {
      final response = await _dio.get(url, options: await _getAuthOptions());
      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(success: true, data: response.data, message: 'Stats loaded');
      } else {
        return ApiResponse<Map<String, dynamic>>(success: false, data: null, message: response.data['detail'] ?? 'Failed');
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(success: false, data: null, message: 'Error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getCustomerReturnHistory(String customerId) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}customer/$customerId/history/');
    try {
      final response = await _dio.get(url, options: await _getAuthOptions());
      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(success: true, data: response.data, message: 'History loaded');
      } else {
        return ApiResponse<Map<String, dynamic>>(success: false, data: null, message: response.data['detail'] ?? 'Failed');
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(success: false, data: null, message: 'Error: $e');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getSaleReturnDetails(String saleId) async {
    final url = _getUrl('${ApiConfig.returnsEndpoint}sale/$saleId/returns/');
    try {
      final response = await _dio.get(url, options: await _getAuthOptions());
      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(success: true, data: response.data, message: 'Details loaded');
      } else {
        return ApiResponse<Map<String, dynamic>>(success: false, data: null, message: response.data['detail'] ?? 'Failed');
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(success: false, data: null, message: 'Error: $e');
    }
  }
}