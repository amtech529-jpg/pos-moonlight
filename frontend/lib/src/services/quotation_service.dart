import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/quotation/quotation_model.dart';
import 'api_client.dart';
import '../config/api_config.dart';

class QuotationService {
  final ApiClient _apiClient = ApiClient();

  /// Get all quotations
  Future<ApiResponse<List<QuotationModel>>> getQuotations({int page = 1, int pageSize = 20, String? search}) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.quotations, 
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      if (response.statusCode == 200) {
        print('DEBUG: Quotations Response Data: ${response.data}');
        
        List<dynamic> dataList = [];
        if (response.data is List) {
          dataList = response.data;
        } else if (response.data is Map) {
          // Handle paginated response ("results") or wrapped response ("data")
          dataList = response.data['results'] ?? response.data['data'] ?? [];
        }
            
        final quotations = dataList.map((json) => QuotationModel.fromJson(json)).toList();
        print('DEBUG: Parsed ${quotations.length} quotations');
        return ApiResponse.success(data: quotations);
      }
      return ApiResponse.error(message: 'Failed to fetch quotations: ${response.statusMessage}');
    } catch (e, stack) {
      print('DEBUG: Error fetching quotations: $e');
      print('DEBUG: Stacktrace: $stack');
      return ApiResponse.error(message: 'Error fetching quotations: $e');
    }
  }

  /// Create a new quotation
  Future<ApiResponse<QuotationModel>> createQuotation(QuotationModel quotation) async {
    try {
      final response = await _apiClient.post(ApiConfig.createQuotation, data: quotation.toJson());
      if (response.statusCode == 201) {
        return ApiResponse.success(data: QuotationModel.fromJson(response.data));
      }
      return _handleError(response.data, 'Failed to create quotation');
    } catch (e) {
      return _handleException(e, 'Error creating quotation');
    }
  }

  /// Update an existing quotation
  Future<ApiResponse<QuotationModel>> updateQuotation(String id, QuotationModel quotation) async {
    try {
      final response = await _apiClient.put(ApiConfig.updateQuotation(id), data: quotation.toJson());
      if (response.statusCode == 200) {
        return ApiResponse.success(data: QuotationModel.fromJson(response.data));
      }
      return _handleError(response.data, 'Failed to update quotation');
    } catch (e) {
      return _handleException(e, 'Error updating quotation');
    }
  }

  /// Delete a quotation
  Future<ApiResponse<void>> deleteQuotation(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteQuotation(id));
      if (response.statusCode == 204) {
        return ApiResponse.success(data: null as dynamic);
      }
      return _handleError(response.data, 'Failed to delete quotation');
    } catch (e) {
      return _handleException(e, 'Error deleting quotation');
    }
  }
  
  /// Convert approved quotation to order
  Future<ApiResponse<Map<String, dynamic>>> convertToOrder(String id) async {
    try {
      final response = await _apiClient.post(ApiConfig.convertQuotationToOrder(id));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse.success(data: response.data);
      }
      
      return _handleError(response.data, 'Failed to convert quotation to order');
    } catch (e) {
      return _handleException(e, 'Error converting quotation to order');
    }
  }
  
  // Helper to handle API error responses consistently
  ApiResponse<T> _handleError<T>(dynamic data, String defaultMessage) {
    String errorMessage = defaultMessage;
    if (data is Map) {
      if (data['message'] != null) {
        errorMessage = data['message'];
      } else if (data['errors'] != null) {
        errorMessage = data['errors'].toString();
      } else if (data['detail'] != null) {
        errorMessage = data['detail'];
      }
    }
    return ApiResponse.error(message: errorMessage);
  }
  
  // Helper to handle exceptions
  ApiResponse<T> _handleException<T>(dynamic e, String contextMessage) {
    try {
      final dynamic errorData = (e as dynamic).response?.data;
      if (errorData != null) {
        if (errorData is Map) {
          if (errorData['message'] != null) return ApiResponse.error(message: errorData['message']);
          if (errorData['errors'] != null) return ApiResponse.error(message: errorData['errors'].toString());
          if (errorData['detail'] != null) return ApiResponse.error(message: errorData['detail']);
          return ApiResponse.error(message: errorData.toString());
        }
      }
    } catch (_) {}
    
    return ApiResponse.error(message: '$contextMessage: $e');
  }
}
