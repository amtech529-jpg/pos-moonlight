import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/profit_loss/profit_loss_models.dart';
import '../utils/debug_helper.dart';
import '../utils/storage_service.dart';
import 'api_client.dart';

class ProfitLossService {
  static final ProfitLossService _instance = ProfitLossService._internal();

  factory ProfitLossService() => _instance;

  ProfitLossService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Calculate profit and loss for a specific period
  Future<ApiResponse<ProfitLossRecord>> calculateProfitLoss({
    required DateTime startDate,
    required DateTime endDate,
    required String periodType,
    bool includeCalculations = true,
    String? calculationNotes,
  }) async {
    try {
      final request = ProfitLossCalculationRequest(
        startDate: startDate,
        endDate: endDate,
        periodType: periodType,
        includeCalculations: includeCalculations,
        calculationNotes: calculationNotes,
      );

      DebugHelper.printJson('Calculate Profit Loss Request', request.toJson());

      final response = await _apiClient.post(ApiConfig.calculateProfitLoss, data: request.toJson());

      DebugHelper.printApiResponse('POST Calculate Profit Loss', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['record'] != null) {
          try {
            final profitLoss = ProfitLossRecord.fromJson(responseData['record']);

            // Cache the record
            await _cacheProfitLossRecord(profitLoss);

            return ApiResponse<ProfitLossRecord>(
              success: true,
              message: responseData['message'] as String? ?? 'Profit loss calculated successfully',
              data: profitLoss,
            );
          } catch (e) {
            DebugHelper.printError('Error parsing profit loss record', e);
            return ApiResponse<ProfitLossRecord>(
              success: false,
              message: 'Error parsing profit loss data: ${e.toString()}',
              errors: {'parsing_error': e.toString()},
            );
          }
        } else {
          return ApiResponse<ProfitLossRecord>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to calculate profit loss',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<ProfitLossRecord>(
          success: false,
          message: response.data['message'] ?? 'Failed to calculate profit loss',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Calculate profit loss DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ProfitLossRecord>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Calculate profit loss', e);
      return ApiResponse<ProfitLossRecord>(success: false, message: 'An unexpected error occurred while calculating profit loss: ${e.toString()}');
    }
  }

  /// Get list of profit and loss records with filtering
  Future<ApiResponse<ProfitLossListResponse>> getProfitLossRecords({ProfitLossListParams? params}) async {
    try {
      final queryParams = params?.toQueryParameters() ?? ProfitLossListParams().toQueryParameters();

      final response = await _apiClient.get(ApiConfig.profitLossRecords, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Profit Loss Records', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        // Handle paginated response structure
        List<dynamic> recordsData;
        int totalCount = 0;

        if (responseData.containsKey('results')) {
          // Paginated response
          recordsData = responseData['results'] as List<dynamic>;
          totalCount = responseData['count'] as int? ?? recordsData.length;
        } else if (responseData is List) {
          // Direct list response
          recordsData = responseData as List<dynamic>;
          totalCount = recordsData.length;
        } else {
          // Single record or other format
          recordsData = [responseData];
          totalCount = 1;
        }

        final records = recordsData
            .map((recordJson) {
              try {
                return ProfitLossRecord.fromJson(recordJson);
              } catch (parseError) {
                DebugHelper.printError('Error parsing profit loss record', parseError);
                // Return a default record or skip this one
                return null;
              }
            })
            .where((record) => record != null)
            .cast<ProfitLossRecord>()
            .toList();

        final profitLossListResponse = ProfitLossListResponse(records: records, totalCount: totalCount);

        // Cache records if successful
        await _cacheProfitLossRecords(records);

        return ApiResponse<ProfitLossListResponse>(
          success: true,
          message: 'Profit loss records retrieved successfully',
          data: profitLossListResponse,
        );
      } else {
        return ApiResponse<ProfitLossListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get profit loss records',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get profit loss records DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedRecords = await _getCachedProfitLossRecords();
        if (cachedRecords.isNotEmpty) {
          return ApiResponse<ProfitLossListResponse>(
            success: true,
            message: 'Showing cached data',
            data: ProfitLossListResponse(records: cachedRecords, totalCount: cachedRecords.length),
          );
        }
      }

      return ApiResponse<ProfitLossListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get profit loss records', e);
      return ApiResponse<ProfitLossListResponse>(success: false, message: 'An unexpected error occurred while getting profit loss records');
    }
  }

  /// Get a specific profit and loss record by ID
  Future<ApiResponse<ProfitLossRecord>> getProfitLossRecordById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getProfitLossRecordById(id));

      DebugHelper.printApiResponse('GET Profit Loss Record by ID', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final record = ProfitLossRecord.fromJson(responseData);

        return ApiResponse<ProfitLossRecord>(success: true, message: 'Profit loss record retrieved successfully', data: record);
      } else {
        return ApiResponse<ProfitLossRecord>(
          success: false,
          message: response.data['message'] ?? 'Failed to get profit loss record',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get profit loss record by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ProfitLossRecord>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get profit loss record by ID error: ${e.toString()}');
      return ApiResponse<ProfitLossRecord>(success: false, message: 'An unexpected error occurred while getting profit loss record');
    }
  }

  /// Get profit and loss summary for different periods
  Future<ApiResponse<ProfitLossSummary>> getProfitLossSummary({
    required String periodType, // CURRENT_MONTH, CURRENT_YEAR, LAST_30_DAYS, LAST_90_DAYS
  }) async {
    try {
      final queryParams = {'period_type': periodType};

      final response = await _apiClient.get(ApiConfig.profitLossSummary, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Profit Loss Summary', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        final summary = ProfitLossSummary.fromJson(responseData);

        return ApiResponse<ProfitLossSummary>(success: true, message: 'Summary retrieved successfully', data: summary);
      } else {
        return ApiResponse<ProfitLossSummary>(
          success: false,
          message: response.data['message'] ?? 'Failed to get summary',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get profit loss summary DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ProfitLossSummary>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get profit loss summary error: ${e.toString()}');
      return ApiResponse<ProfitLossSummary>(success: false, message: 'An unexpected error occurred while getting summary');
    }
  }

  /// Get product profitability analysis
  Future<ApiResponse<List<ProductProfitability>>> getProductProfitability({DateTime? startDate, DateTime? endDate}) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(ApiConfig.productProfitability, queryParameters: queryParams.isNotEmpty ? queryParams : null);

      DebugHelper.printApiResponse('GET Product Profitability', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> productsData;

        if (responseData is List) {
          productsData = responseData;
        } else if (responseData is Map && responseData.containsKey('results')) {
          productsData = responseData['results'] as List<dynamic>;
        } else {
          productsData = [responseData];
        }

        try {
          final products = productsData
              .map((productJson) {
                try {
                  return ProductProfitability.fromJson(productJson);
                } catch (parseError) {
                  DebugHelper.printError('Error parsing individual product', parseError);
                  return null;
                }
              })
              .where((product) => product != null)
              .cast<ProductProfitability>()
              .toList();

          return ApiResponse<List<ProductProfitability>>(success: true, message: 'Product profitability retrieved successfully', data: products);
        } catch (parseError) {
          DebugHelper.printError('Error parsing product profitability data', parseError);
          return ApiResponse<List<ProductProfitability>>(
            success: false,
            message: 'Error parsing product profitability data: ${parseError.toString()}',
            errors: {'parsing_error': parseError.toString()},
          );
        }
      } else {
        return ApiResponse<List<ProductProfitability>>(
          success: false,
          message: response.data['message'] ?? 'Failed to get product profitability',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get product profitability DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<List<ProductProfitability>>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get product profitability error: ${e.toString()}');
      return ApiResponse<List<ProductProfitability>>(success: false, message: 'An unexpected error occurred while getting product profitability');
    }
  }

  /// Get dashboard data with comparisons
  Future<ApiResponse<ProfitLossDashboard>> getDashboardData() async {
    try {
      final response = await _apiClient.get(ApiConfig.profitLossDashboard);

      DebugHelper.printApiResponse('GET Profit Loss Dashboard', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        try {
          final dashboard = ProfitLossDashboard.fromJson(responseData);
          return ApiResponse<ProfitLossDashboard>(success: true, message: 'Dashboard data retrieved successfully', data: dashboard);
        } catch (parseError) {
          DebugHelper.printError('Error parsing dashboard data', parseError);
          return ApiResponse<ProfitLossDashboard>(
            success: false,
            message: 'Error parsing dashboard data: ${parseError.toString()}',
            errors: {'parsing_error': parseError.toString()},
          );
        }
      } else {
        return ApiResponse<ProfitLossDashboard>(
          success: false,
          message: response.data['message'] ?? 'Failed to get dashboard data',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get dashboard data DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Handle specific backend errors
      if (e.response?.statusCode == 500) {
        final errorData = e.response?.data as Map<String, dynamic>?;
        final errorMessage = errorData?['error'] ?? 'Server error occurred';
        return ApiResponse<ProfitLossDashboard>(success: false, message: 'Backend error: $errorMessage', errors: {'backend_error': errorMessage});
      }

      return ApiResponse<ProfitLossDashboard>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get dashboard data error: ${e.toString()}');
      return ApiResponse<ProfitLossDashboard>(success: false, message: 'An unexpected error occurred while getting dashboard data');
    }
  }

  // Cache management methods
  Future<void> _cacheProfitLossRecord(ProfitLossRecord record) async {
    try {
      final records = await _getCachedProfitLossRecords();

      // Remove existing record with same ID
      records.removeWhere((r) => r.id == record.id);

      // Add new record
      records.insert(0, record);

      // Keep only last 20 records
      if (records.length > 20) {
        records.removeRange(20, records.length);
      }

      await _cacheProfitLossRecords(records);
    } catch (e) {
      debugPrint('Error caching profit loss record: $e');
    }
  }

  Future<void> _cacheProfitLossRecords(List<ProfitLossRecord> records) async {
    try {
      final recordsJson = records.map((record) => record.toJson()).toList();
      await _storageService.saveData(ApiConfig.profitLossCacheKey, recordsJson);
    } catch (e) {
      debugPrint('Error caching profit loss records: $e');
    }
  }

  Future<List<ProfitLossRecord>> _getCachedProfitLossRecords() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.profitLossCacheKey);
      if (cachedData != null && cachedData is List) {
        return cachedData.map((json) => ProfitLossRecord.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error getting cached profit loss records: $e');
    }
    return [];
  }

  /// Refresh profit loss records (for pull-to-refresh functionality)
  Future<ApiResponse<ProfitLossListResponse>> refreshProfitLossRecords() async {
    return getProfitLossRecords();
  }
}
