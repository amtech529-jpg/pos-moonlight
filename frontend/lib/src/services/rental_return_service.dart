import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/rental_return_model.dart';
import '../models/api_response.dart';
import '../utils/storage_service.dart';

class RentalReturnService {
  static final RentalReturnService _instance = RentalReturnService._internal();
  factory RentalReturnService() => _instance;
  RentalReturnService._internal();

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
      validateStatus: (status) => status! < 500,
    );
  }

  String _getUrl(String endpoint) {
    return '${ApiConfig.baseUrl}$endpoint';
  }

  Future<ApiResponse<List<RentalReturnModel>>> getReturns({
    String? search,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? pageSize,
  }) async {
    final url = _getUrl(ApiConfig.rentalReturnsEndpoint);
    debugPrint('🚀 [RentalReturnService] GET $url');

    try {
      final response = await _dio.get(
        url,
        options: await _getAuthOptions(),
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
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

        final returns = data.map((json) => RentalReturnModel.fromJson(json)).toList();
        return ApiResponse<List<RentalReturnModel>>(success: true, data: returns, message: 'Returns loaded successfully');
      } else {
        return ApiResponse<List<RentalReturnModel>>(success: false, data: null, message: _parseError(response.data));
      }
    } catch (e) {
      debugPrint('🛑 [RentalReturnService] Exception: $e');
      return ApiResponse<List<RentalReturnModel>>(success: false, data: null, message: 'Error loading returns: $e');
    }
  }

  Future<ApiResponse<RentalReturnModel>> createReturn({
    required String orderId,
    required String responsibility,
    required double damageCharges,
    String? notes,
    required List<Map<String, dynamic>> items,
    bool restoreStock = true,
  }) async {
    final url = _getUrl(ApiConfig.rentalReturnCreate);
    
    try {
      final response = await _dio.post(
        url,
        options: await _getAuthOptions(),
        data: {
          'order': orderId,
          'responsibility': responsibility,
          'damage_charges': damageCharges,
          'notes': notes,
          'items': items,
          'restore_stock': restoreStock,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data;
        final data = responseData is Map && responseData.containsKey('data')
            ? responseData['data']
            : responseData;
        return ApiResponse<RentalReturnModel>(
          success: true,
          data: RentalReturnModel.fromJson(data),
          message: responseData is Map && responseData.containsKey('message') 
              ? responseData['message'] 
              : 'Return created successfully'
        );
      } else {
         return ApiResponse<RentalReturnModel>(
          success: false, 
          message: _parseError(response.data)
        );
      }
    } catch (e) {
      return ApiResponse<RentalReturnModel>(success: false, message: 'Error: $e');
    }
  }

  String _parseError(dynamic responseData) {
    if (responseData == null) return 'Unknown error';
    if (responseData is Map) {
      if (responseData.containsKey('detail')) return responseData['detail'].toString();
      if (responseData.containsKey('message')) return responseData['message'].toString();
      
      // Handle field errors: {"field": ["error"]}
      final List<String> errorMessages = [];
      responseData.forEach((key, value) {
        if (value is List) {
          errorMessages.add('$key: ${value.join(", ")}');
        } else if (value is String) {
          errorMessages.add('$key: $value');
        }
      });
      if (errorMessages.isNotEmpty) return errorMessages.join("\n");
    }
    return responseData.toString();
  }

  /// Submit tally for a rental return (update item counts)
  Future<ApiResponse<RentalReturnModel>> tallyReturn({
    required String returnId,
    required List<Map<String, dynamic>> items,
    double? damageCharges,
    String? responsibility,
    String? notes,
  }) async {
    final url = _getUrl(ApiConfig.rentalReturnTally(returnId));
    debugPrint('🚀 [RentalReturnService] Tallying return: $returnId');

    try {
      final response = await _dio.patch(
        url,
        options: await _getAuthOptions(),
        data: {
          'items': items,
          if (damageCharges != null) 'damage_charges': damageCharges,
          if (responsibility != null) 'responsibility': responsibility,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final data = responseData is Map && responseData.containsKey('data')
            ? responseData['data']
            : responseData;
        return ApiResponse<RentalReturnModel>(
          success: true,
          data: RentalReturnModel.fromJson(data),
          message: responseData['message'] ?? 'Tally updated successfully',
        );
      } else {
        return ApiResponse<RentalReturnModel>(
          success: false,
          message: _parseError(response.data),
        );
      }
    } catch (e) {
      debugPrint('🛑 [RentalReturnService] Tally exception: $e');
      return ApiResponse<RentalReturnModel>(success: false, message: 'Error: $e');
    }
  }

  /// Restore stock from returned items
  Future<ApiResponse<bool>> restoreStock({required String returnId}) async {
    final url = _getUrl(ApiConfig.rentalReturnRestoreStock(returnId));
    debugPrint('🚀 [RentalReturnService] Restoring stock for return: $returnId');

    try {
      final response = await _dio.post(url, options: await _getAuthOptions());

      if (response.statusCode == 200) {
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: response.data['message'] ?? 'Stock restored successfully',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          message: _parseError(response.data),
        );
      }
    } catch (e) {
      debugPrint('🛑 [RentalReturnService] Restore stock exception: $e');
      return ApiResponse<bool>(success: false, message: 'Error: $e');
    }
  }

  /// Add damage recovery payment
  Future<ApiResponse<bool>> addDamageRecovery({
    required String returnId,
    required double amount,
    required String recoveryType,
    String? notes,
  }) async {
    final url = _getUrl(ApiConfig.rentalReturnDamageRecovery(returnId));
    debugPrint('🚀 [RentalReturnService] Adding damage recovery: $amount');

    try {
      final response = await _dio.post(
        url,
        options: await _getAuthOptions(),
        data: {
          'amount': amount,
          'recovery_type': recoveryType,
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: response.data['message'] ?? 'Damage recovery added successfully',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          message: _parseError(response.data),
        );
      }
    } catch (e) {
      debugPrint('🛑 [RentalReturnService] Damage recovery exception: $e');
      return ApiResponse<bool>(success: false, message: 'Error: $e');
    }
  }

  /// Get rental return statistics
  Future<ApiResponse<Map<String, dynamic>>> getStatistics() async {
    final url = _getUrl(ApiConfig.rentalReturnStatistics);
    debugPrint('🚀 [RentalReturnService] Loading statistics');

    try {
      final response = await _dio.get(url, options: await _getAuthOptions());

      if (response.statusCode == 200) {
        final responseData = response.data;
        final data = responseData is Map && responseData.containsKey('data')
            ? responseData['data'] as Map<String, dynamic>
            : responseData as Map<String, dynamic>;
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: data,
          message: 'Statistics loaded successfully',
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: _parseError(response.data),
        );
      }
    } catch (e) {
      debugPrint('🛑 [RentalReturnService] Statistics exception: $e');
      return ApiResponse<Map<String, dynamic>>(success: false, message: 'Error: $e');
    }
  }

  /// Delete a rental return
  Future<ApiResponse<bool>> deleteReturn({required String returnId}) async {
    final url = _getUrl(ApiConfig.deleteRentalReturn(returnId));
    debugPrint('🚀 [RentalReturnService] Deleting return: $returnId');

    try {
      final response = await _dio.delete(url, options: await _getAuthOptions());

      if (response.statusCode == 200 || response.statusCode == 204) {
        return ApiResponse<bool>(
          success: true,
          data: true,
          message: 'Return deleted successfully',
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          message: _parseError(response.data),
        );
      }
    } catch (e) {
      debugPrint('🛑 [RentalReturnService] Delete exception: $e');
      return ApiResponse<bool>(success: false, message: 'Error: $e');
    }
  }
}
