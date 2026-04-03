import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/expenses/expenses_api_responses.dart';
import '../models/expenses/expenses_model.dart';
import '../services/expenses/expenses_service.dart';

class ExpensesProvider extends ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<Expense> _expenseRecords = [];
  List<Expense> _filteredRecords = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _searchQuery = '';
  PaginationInfo? _paginationInfo;
  ExpenseStatisticsResponse? _statistics;

  // Sorting and filtering
  String _sortBy = 'date';
  bool _sortAscending = false;

  String? _selectedCategory;
  DateTime? _dateFrom;
  DateTime? _dateTo;



  // Centralized categories as per user requirements
  static const List<String> expenseCategories = [
    'Transport',
    'Food',
    'Miscellaneous',
    'Electricity',
    'Rent',
    'Internet',
    'Mobile Bills',
    'Packages',
    'Other'
  ];

  // Getters
  List<Expense> get expenses => _filteredRecords;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  PaginationInfo? get paginationInfo => _paginationInfo;
  ExpenseStatisticsResponse? get statistics => _statistics;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;

  String? get selectedCategory => _selectedCategory;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;


  ExpensesProvider() {
    // Initialize with sample data for now, will be replaced by API calls
    _initializeSampleData();
  }

  // Initialize method to be called from main.dart
  Future<void> initialize() async {
    try {
      await loadExpenseRecords();
      await loadStatistics();
    } catch (e) {
      debugPrint('Failed to initialize ExpensesProvider: $e');
      // Keep sample data as fallback
      _initializeSampleData();
    }
  }

  /// Load expense records from API
  Future<void> loadExpenseRecords({int page = 1, int pageSize = 20, bool showLoading = true}) async {
    if (showLoading) {
      _setLoading(true);
    }

    try {
      final params = ExpenseListParams(
        page: page,
        pageSize: pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        withdrawalBy: null,
        category: _selectedCategory,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        sortBy: _sortBy,
        sortOrder: _sortAscending ? 'asc' : 'desc',
      );

      final response = await _expenseService.getExpenses(params: params);

      if (response.success && response.data != null) {
        _expenseRecords = response.data!.expenses;
        _filteredRecords = List.from(_expenseRecords);
        _paginationInfo = response.data!.pagination;
        _clearError();
      } else {
        _setError(response.message ?? 'Failed to load expense records');
        // Keep existing data on error
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      // Keep existing data on error
    } finally {
      _setLoading(false);
    }
  }

  /// Load statistics
  Future<void> loadStatistics() async {
    try {
      final response = await _expenseService.getExpenseStatistics();

      if (response.success && response.data != null) {
        _statistics = response.data!;
        _clearError();
        notifyListeners();
      } else {
        debugPrint('Failed to load statistics: ${response.message}');
        // Don't set error for statistics, just log it
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      // Don't set error for statistics, just log it
    }
  }

  /// Add new expense record
  Future<bool> addExpense({
    required String expense,
    required String description,
    required DateTime date,
    required TimeOfDay time,
    required double amount,
    required String withdrawalBy,
    String? category,
    String? notes,
    bool isRecurring = false,
    bool isSalaryDeductible = false,
    String? deductibleLaborId,
  }) async {
    _setLoading(true);

    try {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

      final response = await _expenseService.createExpense(
        expense: expense,
        description: description,
        date: date,
        time: timeString,
        amount: amount,
        withdrawalBy: withdrawalBy,
        category: category,
        notes: notes,
        isRecurring: isRecurring,
        isSalaryDeductible: isSalaryDeductible,
        deductibleLaborId: deductibleLaborId,
      );


      if (response.success && response.data != null) {
        // Refresh the list to include the new record
        await loadExpenseRecords(showLoading: false);
        await loadStatistics(); // Refresh statistics
        _clearError();
        return true;
      } else {
        _setError(response.message ?? 'Failed to add expense record');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing expense record
  Future<bool> updateExpense({
    required String id,
    required String expense,
    required String description,
    required DateTime date,
    required TimeOfDay time,
    required double amount,
    required String withdrawalBy,
    String? category,
    String? notes,
    bool isRecurring = false,
    bool isSalaryDeductible = false,
    String? deductibleLaborId,
  }) async {
    _setLoading(true);

    try {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

      final response = await _expenseService.updateExpense(
        id: id,
        expense: expense,
        description: description,
        date: date,
        time: timeString,
        amount: amount,
        withdrawalBy: withdrawalBy,
        category: category,
        notes: notes,
        isRecurring: isRecurring,
        isSalaryDeductible: isSalaryDeductible,
        deductibleLaborId: deductibleLaborId,
      );


      if (response.success && response.data != null) {
        // Refresh the list to include the updated record
        await loadExpenseRecords(showLoading: false);
        await loadStatistics(); // Refresh statistics
        _clearError();
        return true;
      } else {
        _setError(response.message ?? 'Failed to update expense record');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete expense record
  Future<bool> deleteExpense(String id) async {
    _setLoading(true);

    try {
      final response = await _expenseService.deleteExpense(id);

      if (response.success) {
        // Refresh the list to remove the deleted record
        await loadExpenseRecords(showLoading: false);
        await loadStatistics(); // Refresh statistics
        _clearError();
        return true;
      } else {
        _setError(response.message ?? 'Failed to delete expense record');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Search expense records
  Future<void> searchExpenses(String query) async {
    _searchQuery = query;
    // Reload records with search query
    await loadExpenseRecords();
  }

  /// Set sorting
  Future<void> setSortBy(String sortBy) async {
    if (_sortBy == sortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = sortBy;
      _sortAscending = false;
    }
    // Reload records with new sorting
    await loadExpenseRecords();
  }



  /// Set category filter
  Future<void> setCategoryFilter(String? category) async {
    _selectedCategory = category;
    await loadExpenseRecords();
  }

  /// Set date range filter
  Future<void> setDateRangeFilter(DateTime? from, DateTime? to) async {
    _dateFrom = from;
    _dateTo = to;
    await loadExpenseRecords();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _selectedCategory = null;
    _dateFrom = null;
    _dateTo = null;
    _searchQuery = '';
    await loadExpenseRecords();
  }

  /// Refresh data (for pull-to-refresh functionality)
  Future<void> refreshData() async {
    await loadExpenseRecords();
    await loadStatistics();
  }

  /// Get statistics
  Map<String, dynamic> get expenseStats {
    if (_statistics == null) {
      // Return default stats if statistics not loaded
      return {
        'total': _expenseRecords.length,
        'totalAmount': _expenseRecords.fold<double>(0.0, (sum, expense) => sum + expense.amount).toStringAsFixed(0),
        'thisYear': _getThisYearCount(),
        'thisMonth': _getThisMonthCount(),
        'thisWeek': _getThisWeekCount(),
      };
    }

    return {
      'total': _statistics!.totalExpenses,
      'totalAmount': _statistics!.totalAmount.toStringAsFixed(0),
      'thisYear': _getThisYearCount(),
      'thisMonth': _getThisMonthCount(),
      'thisWeek': _getThisWeekCount(),
    };
  }

  /// Sample data initialization (fallback)
  void _initializeSampleData() {
    _expenseRecords = [
      Expense(
        id: 'EXP001',
        expense: 'Office Supplies',
        description: 'Purchased stationery and printing materials for office use',
        amount: 8500.0,
        withdrawalBy: 'Mr. Huzaifa',
        date: DateTime.now().subtract(const Duration(days: 2)),
        time: const TimeOfDay(hour: 10, minute: 30),
        category: 'Office',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Expense(
        id: 'EXP002',
        expense: 'Internet Bill',
        description: 'Monthly internet service payment for office connectivity',
        amount: 12000.0,
        withdrawalBy: 'Mr. Huzaifa',
        date: DateTime.now().subtract(const Duration(days: 5)),
        time: const TimeOfDay(hour: 14, minute: 15),
        category: 'Utilities',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Expense(
        id: 'EXP003',
        expense: 'Transportation',
        description: 'Fuel and maintenance costs for delivery vehicle',
        amount: 15000.0,
        withdrawalBy: 'Mr. Huzaifa',
        date: DateTime.now().subtract(const Duration(days: 7)),
        time: const TimeOfDay(hour: 9, minute: 45),
        category: 'Transport',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      Expense(
        id: 'EXP004',
        expense: 'Marketing',
        description: 'Social media advertising and promotional materials',
        amount: 25000.0,
        withdrawalBy: 'Mr Huzaifa',
        date: DateTime.now().subtract(const Duration(days: 10)),
        time: const TimeOfDay(hour: 16, minute: 20),
        category: 'Marketing',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
    _filteredRecords = List.from(_expenseRecords);
    notifyListeners();
  }



  /// Get expense categories with counts
  Map<String, int> getExpenseCategories() {
    final categories = <String, int>{};
    for (final expense in _expenseRecords) {
      if (expense.category != null && expense.category!.isNotEmpty) {
        categories[expense.category!] = (categories[expense.category!] ?? 0) + 1;
      }
    }
    return categories;
  }

  /// Get monthly expense trend
  Map<String, double> getMonthlyExpenseTrend(int year) {
    final monthlyTotals = <String, double>{};
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (int i = 1; i <= 12; i++) {
      final monthExpenses = _expenseRecords.where((expense) {
        return expense.date.year == year && expense.date.month == i;
      });
      final total = monthExpenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
      monthlyTotals[months[i - 1]] = total;
    }

    return monthlyTotals;
  }



  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _hasError = true;
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  int _getThisYearCount() {
    final currentYear = DateTime.now().year;
    return _expenseRecords.where((expense) => expense.date.year == currentYear).length;
  }

  int _getThisMonthCount() {
    final now = DateTime.now();
    return _expenseRecords.where((expense) => expense.date.year == now.year && expense.date.month == now.month).length;
  }

  int _getThisWeekCount() {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    return _expenseRecords.where((expense) {
      return expense.date.isAfter(currentWeekStart.subtract(const Duration(days: 1)));
    }).length;
  }

  /// Clear error state
  void clearError() {
    _clearError();
  }

  /// Clear all records (for testing purposes)
  void clearAllRecords() {
    _expenseRecords.clear();
    _filteredRecords.clear();
    notifyListeners();
  }
}
