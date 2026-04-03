import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../models/api_response.dart';
import '../../models/expenses/expenses_api_responses.dart';
import '../../models/expenses/expenses_model.dart';
import '../../utils/debug_helper.dart';
import '../../utils/storage_service.dart';
import '../api_client.dart';

class ExpenseService {
  static final ExpenseService _instance = ExpenseService._internal();

  factory ExpenseService() => _instance;

  ExpenseService._internal();

  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Get list of expenses with pagination and filtering
  Future<ApiResponse<ExpensesListResponse>> getExpenses({ExpenseListParams? params}) async {
    try {
      final queryParams = params?.toQueryParameters() ?? ExpenseListParams().toQueryParameters();

      final response = await _apiClient.get(ApiConfig.expenses, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Expenses', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final expenseListData = responseData['data'] as Map<String, dynamic>;

          // Handle the API response structure from Django views
          final expensesListResponse = ExpensesListResponse(
            expenses: (expenseListData['expenses'] as List).map((expenseJson) => Expense.fromJson(expenseJson)).toList(),
            pagination: PaginationInfo.fromJson(expenseListData['pagination']),
            filtersApplied: expenseListData['filters_applied'] as Map<String, dynamic>?,
          );

          // Cache expenses if successful
          await _cacheExpenses(expensesListResponse.expenses);

          return ApiResponse<ExpensesListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Expenses retrieved successfully',
            data: expensesListResponse,
          );
        } else {
          return ApiResponse<ExpensesListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get expenses',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<ExpensesListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get expenses',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get expenses DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached data if network error
      if (apiError.type == 'network_error') {
        final cachedExpenses = await _getCachedExpenses();
        if (cachedExpenses.isNotEmpty) {
          return ApiResponse<ExpensesListResponse>(
            success: true,
            message: 'Showing cached data',
            data: ExpensesListResponse(
              expenses: cachedExpenses,
              pagination: PaginationInfo(
                currentPage: 1,
                pageSize: cachedExpenses.length,
                totalCount: cachedExpenses.length,
                totalPages: 1,
                hasNext: false,
                hasPrevious: false,
              ),
            ),
          );
        }
      }

      return ApiResponse<ExpensesListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get expenses', e);
      return ApiResponse<ExpensesListResponse>(success: false, message: 'An unexpected error occurred while getting expenses');
    }
  }

  /// Get a specific expense by ID
  Future<ApiResponse<Expense>> getExpenseById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.getExpenseById(id));

      DebugHelper.printApiResponse('GET Expense by ID', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final expenseData = responseData['data'] as Map<String, dynamic>;
          final expense = Expense.fromJson(expenseData);

          return ApiResponse<Expense>(success: true, message: responseData['message'] as String? ?? 'Expense retrieved successfully', data: expense);
        } else {
          return ApiResponse<Expense>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get expense',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Expense>(
          success: false,
          message: response.data['message'] ?? 'Failed to get expense',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get expense by ID DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Expense>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get expense by ID error: ${e.toString()}');
      return ApiResponse<Expense>(success: false, message: 'An unexpected error occurred while getting expense');
    }
  }

  /// Create a new expense
  Future<ApiResponse<Expense>> createExpense({
    required String expense,
    required String description,
    required DateTime date,
    required String time, // HH:MM format
    required double amount,
    required String withdrawalBy,
    String? category,
    String? notes,
    bool isRecurring = false,
    bool isSalaryDeductible = false,
    String? deductibleLaborId,
  }) async {
    try {
      final request = ExpenseCreateRequest(
        expense: expense,
        description: description,
        date: date,
        time: time,
        amount: amount,
        withdrawalBy: withdrawalBy,
        category: category,
        notes: notes,
        isRecurring: isRecurring,
        isSalaryDeductible: isSalaryDeductible,
        deductibleLaborId: deductibleLaborId,
      );


      DebugHelper.printJson('Create Expense Request', request.toJson());

      final response = await _apiClient.post(ApiConfig.createExpense, data: request.toJson());

      DebugHelper.printApiResponse('POST Create Expense', response.data);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final expenseData = responseData['data'] as Map<String, dynamic>;
          final expense = Expense.fromJson(expenseData);

          // Update cache with new expense
          await _addExpenseToCache(expense);

          return ApiResponse<Expense>(success: true, message: responseData['message'] as String? ?? 'Expense created successfully', data: expense);
        } else {
          return ApiResponse<Expense>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to create expense',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Expense>(
          success: false,
          message: response.data['message'] ?? 'Failed to create expense',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      DebugHelper.printError('Create expense DioException', e);
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Expense>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Create expense', e);
      return ApiResponse<Expense>(success: false, message: 'An unexpected error occurred while creating expense: ${e.toString()}');
    }
  }

  /// Update an existing expense
  Future<ApiResponse<Expense>> updateExpense({
    required String id,
    required String expense,
    required String description,
    required DateTime date,
    required String time, // HH:MM format
    required double amount,
    required String withdrawalBy,
    String? category,
    String? notes,
    bool isRecurring = false,
    bool isSalaryDeductible = false,
    String? deductibleLaborId,
  }) async {
    try {
      final request = ExpenseUpdateRequest(
        expense: expense,
        description: description,
        date: date,
        time: time,
        amount: amount,
        withdrawalBy: withdrawalBy,
        category: category,
        notes: notes,
        isRecurring: isRecurring,
        isSalaryDeductible: isSalaryDeductible,
        deductibleLaborId: deductibleLaborId,
      );


      DebugHelper.printJson('Update Expense Request', request.toJson());

      final response = await _apiClient.put(ApiConfig.updateExpense(id), data: request.toJson());

      DebugHelper.printApiResponse('PUT Update Expense', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final expenseData = responseData['data'] as Map<String, dynamic>;
          final expense = Expense.fromJson(expenseData);

          // Update cache with updated expense
          await _updateExpenseInCache(expense);

          return ApiResponse<Expense>(success: true, message: responseData['message'] as String? ?? 'Expense updated successfully', data: expense);
        } else {
          return ApiResponse<Expense>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to update expense',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<Expense>(
          success: false,
          message: response.data['message'] ?? 'Failed to update expense',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Update expense DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<Expense>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Update expense error: ${e.toString()}');
      return ApiResponse<Expense>(success: false, message: 'An unexpected error occurred while updating expense');
    }
  }

  /// Delete an expense (soft delete)
  Future<ApiResponse<void>> deleteExpense(String id) async {
    try {
      final response = await _apiClient.delete(ApiConfig.deleteExpense(id));

      DebugHelper.printApiResponse('DELETE Expense', response.data);

      if (response.statusCode == 200) {
        // Remove from cache
        await _removeExpenseFromCache(id);

        return ApiResponse<void>(success: true, message: response.data['message'] ?? 'Expense deleted successfully');
      } else {
        return ApiResponse<void>(
          success: false,
          message: response.data['message'] ?? 'Failed to delete expense',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Delete expense DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<void>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Delete expense error: ${e.toString()}');
      return ApiResponse<void>(success: false, message: 'An unexpected error occurred while deleting expense');
    }
  }

  /// Get expense statistics
  Future<ApiResponse<ExpenseStatisticsResponse>> getExpenseStatistics() async {
    try {
      final response = await _apiClient.get(ApiConfig.expenseStatistics);

      DebugHelper.printApiResponse('GET Expense Statistics', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final statisticsData = responseData['data'] as Map<String, dynamic>;

          final statisticsResponse = ExpenseStatisticsResponse.fromJson(statisticsData);

          // Cache statistics if successful
          await _cacheExpenseStatistics(statisticsResponse);

          return ApiResponse<ExpenseStatisticsResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Expense statistics retrieved successfully',
            data: statisticsResponse,
          );
        } else {
          return ApiResponse<ExpenseStatisticsResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get expense statistics',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<ExpenseStatisticsResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get expense statistics',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get expense statistics DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);

      // Try to return cached statistics if network error
      if (apiError.type == 'network_error') {
        final cachedStatistics = await _getCachedExpenseStatistics();
        if (cachedStatistics != null) {
          return ApiResponse<ExpenseStatisticsResponse>(success: true, message: 'Showing cached statistics', data: cachedStatistics);
        }
      }

      return ApiResponse<ExpenseStatisticsResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      DebugHelper.printError('Get expense statistics', e);
      return ApiResponse<ExpenseStatisticsResponse>(success: false, message: 'An unexpected error occurred while getting expense statistics');
    }
  }

  /// Get expenses by authority
  Future<ApiResponse<ExpensesListResponse>> getExpensesByAuthority({required String authority, DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      final queryParams = <String, String>{};

      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(ApiConfig.expensesByAuthority(authority), queryParameters: queryParams.isNotEmpty ? queryParams : null);

      DebugHelper.printApiResponse('GET Expenses by Authority', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final expenseListData = responseData['data'] as Map<String, dynamic>;

          final expensesListResponse = ExpensesListResponse(
            expenses: (expenseListData['expenses'] as List).map((expenseJson) => Expense.fromJson(expenseJson)).toList(),
            pagination: PaginationInfo(
              currentPage: 1,
              pageSize: expenseListData['count'] as int,
              totalCount: expenseListData['count'] as int,
              totalPages: 1,
              hasNext: false,
              hasPrevious: false,
            ),
          );

          return ApiResponse<ExpensesListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Expenses by authority retrieved successfully',
            data: expensesListResponse,
          );
        } else {
          return ApiResponse<ExpensesListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get expenses by authority',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<ExpensesListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get expenses by authority',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get expenses by authority DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ExpensesListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get expenses by authority error: ${e.toString()}');
      return ApiResponse<ExpensesListResponse>(success: false, message: 'An unexpected error occurred while getting expenses by authority');
    }
  }

  /// Get expenses by category
  Future<ApiResponse<ExpensesListResponse>> getExpensesByCategory({required String category, DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      final queryParams = <String, String>{};

      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      final response = await _apiClient.get(ApiConfig.expensesByCategory(category), queryParameters: queryParams.isNotEmpty ? queryParams : null);

      DebugHelper.printApiResponse('GET Expenses by Category', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final expenseListData = responseData['data'] as Map<String, dynamic>;

          final expensesListResponse = ExpensesListResponse(
            expenses: (expenseListData['expenses'] as List).map((expenseJson) => Expense.fromJson(expenseJson)).toList(),
            pagination: PaginationInfo(
              currentPage: 1,
              pageSize: expenseListData['count'] as int,
              totalCount: expenseListData['count'] as int,
              totalPages: 1,
              hasNext: false,
              hasPrevious: false,
            ),
          );

          return ApiResponse<ExpensesListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Expenses by category retrieved successfully',
            data: expensesListResponse,
          );
        } else {
          return ApiResponse<ExpensesListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get expenses by category',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<ExpensesListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get expenses by category',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get expenses by category DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ExpensesListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get expenses by category error: ${e.toString()}');
      return ApiResponse<ExpensesListResponse>(success: false, message: 'An unexpected error occurred while getting expenses by category');
    }
  }

  /// Get expenses by date range
  Future<ApiResponse<ExpensesListResponse>> getExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final response = await _apiClient.get(ApiConfig.expensesByDateRange, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Expenses by Date Range', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final expenseListData = responseData['data'] as Map<String, dynamic>;

          final expensesListResponse = ExpensesListResponse(
            expenses: (expenseListData['expenses'] as List).map((expenseJson) => Expense.fromJson(expenseJson)).toList(),
            pagination: PaginationInfo(
              currentPage: page,
              pageSize: pageSize,
              totalCount: expenseListData['count'] as int,
              totalPages: ((expenseListData['count'] as int) / pageSize).ceil(),
              hasNext: false,
              hasPrevious: false,
            ),
          );

          return ApiResponse<ExpensesListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Date range search completed successfully',
            data: expensesListResponse,
          );
        } else {
          return ApiResponse<ExpensesListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get expenses by date range',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<ExpensesListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get expenses by date range',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get expenses by date range DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ExpensesListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get expenses by date range error: ${e.toString()}');
      return ApiResponse<ExpensesListResponse>(success: false, message: 'An unexpected error occurred while getting expenses by date range');
    }
  }

  /// Get recent expenses
  Future<ApiResponse<ExpensesListResponse>> getRecentExpenses({int limit = 10}) async {
    try {
      final queryParams = {'limit': limit.toString()};

      final response = await _apiClient.get(ApiConfig.recentExpenses, queryParameters: queryParams);

      DebugHelper.printApiResponse('GET Recent Expenses', response.data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] != null) {
          final expenseListData = responseData['data'] as Map<String, dynamic>;

          final expensesListResponse = ExpensesListResponse(
            expenses: (expenseListData['expenses'] as List).map((expenseJson) => Expense.fromJson(expenseJson)).toList(),
            pagination: PaginationInfo(
              currentPage: 1,
              pageSize: limit,
              totalCount: expenseListData['count'] as int,
              totalPages: 1,
              hasNext: false,
              hasPrevious: false,
            ),
          );

          return ApiResponse<ExpensesListResponse>(
            success: true,
            message: responseData['message'] as String? ?? 'Recent expenses retrieved successfully',
            data: expensesListResponse,
          );
        } else {
          return ApiResponse<ExpensesListResponse>(
            success: false,
            message: responseData['message'] as String? ?? 'Failed to get recent expenses',
            errors: responseData['errors'] as Map<String, dynamic>?,
          );
        }
      } else {
        return ApiResponse<ExpensesListResponse>(
          success: false,
          message: response.data['message'] ?? 'Failed to get recent expenses',
          errors: response.data['errors'] as Map<String, dynamic>?,
        );
      }
    } on DioException catch (e) {
      debugPrint('Get recent expenses DioException: ${e.toString()}');
      final apiError = ApiError.fromDioError(e);
      return ApiResponse<ExpensesListResponse>(success: false, message: apiError.displayMessage, errors: apiError.errors);
    } catch (e) {
      debugPrint('Get recent expenses error: ${e.toString()}');
      return ApiResponse<ExpensesListResponse>(success: false, message: 'An unexpected error occurred while getting recent expenses');
    }
  }

  // Cache management methods
  Future<void> _cacheExpenses(List<Expense> expenses) async {
    try {
      final expensesJson = expenses.map((expense) => expense.toJson()).toList();
      await _storageService.saveData(ApiConfig.expensesCacheKey, expensesJson);
    } catch (e) {
      debugPrint('Error caching expenses: $e');
    }
  }

  Future<List<Expense>> _getCachedExpenses() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.expensesCacheKey);
      if (cachedData != null && cachedData is List) {
        return cachedData.map((json) => Expense.fromJson(json as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error getting cached expenses: $e');
    }
    return [];
  }

  Future<void> _addExpenseToCache(Expense expense) async {
    try {
      final cachedExpenses = await _getCachedExpenses();
      cachedExpenses.add(expense);
      await _cacheExpenses(cachedExpenses);
    } catch (e) {
      debugPrint('Error adding expense to cache: $e');
    }
  }

  Future<void> _updateExpenseInCache(Expense updatedExpense) async {
    try {
      final cachedExpenses = await _getCachedExpenses();
      final index = cachedExpenses.indexWhere((expense) => expense.id == updatedExpense.id);
      if (index != -1) {
        cachedExpenses[index] = updatedExpense;
        await _cacheExpenses(cachedExpenses);
      }
    } catch (e) {
      debugPrint('Error updating expense in cache: $e');
    }
  }

  Future<void> _removeExpenseFromCache(String expenseId) async {
    try {
      final cachedExpenses = await _getCachedExpenses();
      cachedExpenses.removeWhere((expense) => expense.id == expenseId);
      await _cacheExpenses(cachedExpenses);
    } catch (e) {
      debugPrint('Error removing expense from cache: $e');
    }
  }

  /// Cache expense statistics
  Future<void> _cacheExpenseStatistics(ExpenseStatisticsResponse statistics) async {
    try {
      await _storageService.saveData(ApiConfig.expenseStatsCacheKey, statistics.toJson());
    } catch (e) {
      debugPrint('Failed to cache expense statistics: $e');
    }
  }

  /// Get cached expense statistics
  Future<ExpenseStatisticsResponse?> _getCachedExpenseStatistics() async {
    try {
      final cachedData = await _storageService.getData(ApiConfig.expenseStatsCacheKey);
      if (cachedData != null) {
        return ExpenseStatisticsResponse.fromJson(cachedData);
      }
    } catch (e) {
      debugPrint('Failed to get cached expense statistics: $e');
    }
    return null;
  }

  /// Refresh expense records (for pull-to-refresh functionality)
  Future<ApiResponse<ExpensesListResponse>> refreshExpenseRecords() async {
    return getExpenses();
  }
}
