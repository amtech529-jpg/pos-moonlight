import 'package:dio/dio.dart';
import 'package:frontend/src/config/api_config.dart';
import 'package:frontend/src/services/api_client.dart';

class ReportService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> getTopCustomers() async {
    try {
      final response = await _apiClient.get(ApiConfig.topCustomersReport);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getTopProducts() async {
    try {
      final response = await _apiClient.get(ApiConfig.topProductsReport);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getRevenueReport() async {
    try {
      final response = await _apiClient.get(ApiConfig.revenueReport);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getMonthlyRevenueReport() async {
    try {
      final response = await _apiClient.get(ApiConfig.monthlyRevenueReport);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getBusinessPerformance() async {
    try {
      final response = await _apiClient.get(ApiConfig.businessPerformance);
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getToolUsageReport({int months = 6}) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.toolUsageReport,
        queryParameters: {'months': months.toString()},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
