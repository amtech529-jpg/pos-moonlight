import 'package:frontend/src/config/api_config.dart';
import 'package:frontend/src/models/dispatch/dispatch_form_model.dart';
import 'package:frontend/src/models/api_response.dart';
import 'package:frontend/src/services/api_client.dart';

class DispatchService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<DispatchFormModel>>> getDispatchForms({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _apiClient.get(
      ApiConfig.listDispatchForms,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      try {
        final data = response.data['data'];
        final List<dynamic> formsJson = data is Map ? (data['forms'] ?? []) : [];
        final forms = formsJson
            .where((json) => json != null && json is Map)
            .map((json) => DispatchFormModel.fromJson(json as Map<String, dynamic>))
            .toList();
        
        return ApiResponse<List<DispatchFormModel>>(
          success: true,
          data: forms,
          message: response.data['message']?.toString() ?? '',
        );
      } catch (e) {
        return ApiResponse<List<DispatchFormModel>>(
          success: false,
          message: 'Error parsing dispatch forms: $e',
        );
      }
    }

    return ApiResponse<List<DispatchFormModel>>(
      success: false,
      message: response.data?['message']?.toString() ?? 'Failed to load dispatch forms',
    );
  }

  /// Fetch dispatch forms linked to a specific order (used for return tally)
  Future<ApiResponse<List<DispatchFormModel>>> getDispatchFormsForOrder(String orderId) async {
    final response = await _apiClient.get(
      ApiConfig.listDispatchForms,
      queryParameters: {'order_id': orderId, 'page_size': '50'},
    );

    if (response.statusCode == 200 && response.data != null) {
      try {
        final data = response.data['data'];
        final List<dynamic> formsJson = data is Map ? (data['forms'] ?? []) : [];
        final forms = formsJson
            .where((json) => json != null && json is Map)
            .map((json) => DispatchFormModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<DispatchFormModel>>(success: true, data: forms, message: '');
      } catch (e) {
        return ApiResponse<List<DispatchFormModel>>(success: false, message: 'Parse error: $e');
      }
    }
    return ApiResponse<List<DispatchFormModel>>(success: false, message: 'Failed to load dispatch forms for order');
  }

  /// Fetch dispatch forms for a specific customer
  Future<ApiResponse<List<DispatchFormModel>>> getDispatchFormsForCustomer({
    required String customerId,
    bool? standaloneOnly,
  }) async {
    final queryParams = {
      'customer_id': customerId,
      'page_size': '50',
      if (standaloneOnly == true) 'standalone': 'true',
    };
    
    final response = await _apiClient.get(
      ApiConfig.listDispatchForms,
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      try {
        final data = response.data['data'];
        final List<dynamic> formsJson = data is Map ? (data['forms'] ?? []) : [];
        final forms = formsJson
            .where((json) => json != null && json is Map)
            .map((json) => DispatchFormModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return ApiResponse<List<DispatchFormModel>>(success: true, data: forms, message: '');
      } catch (e) {
        return ApiResponse<List<DispatchFormModel>>(success: false, message: 'Parse error: $e');
      }
    }
    return ApiResponse<List<DispatchFormModel>>(success: false, message: 'Failed to load dispatch forms for customer');
  }

  Future<ApiResponse<DispatchFormModel>> createDispatchForm(DispatchFormModel form) async {
    final response = await _apiClient.post(
      ApiConfig.createDispatchForm,
      data: form.toJson(),
    );

    if (response.statusCode == 201 && response.data != null) {
      return ApiResponse<DispatchFormModel>(
        success: true,
        data: DispatchFormModel.fromJson(response.data['data']),
        message: response.data['message']?.toString() ?? '',
      );
    }

    return ApiResponse<DispatchFormModel>(
      success: false,
      message: response.data?['message']?.toString() ?? 'Failed to create dispatch form',
    );
  }

  Future<ApiResponse<DispatchFormModel>> getDispatchForm(String id) async {
    final response = await _apiClient.get('${ApiConfig.ordersBase}dispatches/$id/');

    if (response.statusCode == 200 && response.data != null) {
      return ApiResponse<DispatchFormModel>(
        success: true,
        data: DispatchFormModel.fromJson(response.data['data']),
        message: response.data['message']?.toString() ?? '',
      );
    }

    return ApiResponse<DispatchFormModel>(
      success: false,
      message: response.data?['message']?.toString() ?? 'Failed to load dispatch form',
    );
  }

  Future<ApiResponse<DispatchFormModel>> updateDispatchForm(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.put(
      '${ApiConfig.ordersBase}dispatches/$id/update/',
      data: data,
    );

    if (response.statusCode == 200 && response.data != null) {
      return ApiResponse<DispatchFormModel>(
        success: true,
        data: DispatchFormModel.fromJson(response.data['data']),
        message: response.data['message']?.toString() ?? 'Dispatch form updated successfully',
      );
    }

    return ApiResponse<DispatchFormModel>(
      success: false,
      message: response.data?['message']?.toString() ?? 'Failed to update dispatch form',
    );
  }

  Future<ApiResponse<void>> deleteDispatchForm(String id) async {
    final response = await _apiClient.delete('${ApiConfig.ordersBase}dispatches/$id/delete/');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return ApiResponse<void>(
        success: true,
        message: 'Dispatch form deleted successfully',
      );
    }

    return ApiResponse<void>(
      success: false,
      message: response.data?['message']?.toString() ?? 'Failed to delete dispatch form',
    );
  }
}
