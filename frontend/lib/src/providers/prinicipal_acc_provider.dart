import 'package:flutter/material.dart';
import '../services/principal_account_service.dart';
import '../models/principal_account/principal_account_model.dart';
import '../models/common_models.dart';

class PrincipalAccountProvider extends ChangeNotifier {
  final PrincipalAccountService _service = PrincipalAccountService();

  // State variables
  List<PrincipalAccount> _accounts = [];
  PrincipalAccountBalance? _currentBalance;
  PrincipalAccountStatistics? _statistics;
  bool _isLoading = false;
  String? _errorMessage;
  PaginationInfo? _pagination;

  // Getters
  List<PrincipalAccount> get accounts => _accounts;
  PrincipalAccountBalance? get currentBalance => _currentBalance;
  PrincipalAccountStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PaginationInfo? get pagination => _pagination;

  // Add missing getter for accountStats
  PrincipalAccountStatistics? get accountStats => _statistics;

  // Add missing getter for searchableAccounts
  List<PrincipalAccount> get searchableAccounts => _accounts;

  // Available options for filters
  final List<String> _availableSourceModules = [
    'SALES',
    'ORDERS',
    'PAYMENTS',
    'RECEIVABLES',
    'PAYABLES',
    'ADVANCE_PAYMENT',
    'EXPENSES',
    'ZAKAT',
    'LABOR',
    'VENDOR',
    'ADJUSTMENT',
    'TRANSFER',
  ];

  final List<String> _availableTransactionTypes = ['CREDIT', 'DEBIT'];

  final List<String> _availableHandlers = ['Mr. Shahzain Baloch', 'Mr Huzaifa'];

  List<String> get availableSourceModules => _availableSourceModules;
  List<String> get availableTransactionTypes => _availableTransactionTypes;
  List<String> get availableHandlers => _availableHandlers;

  // Initialize with real API data
  PrincipalAccountProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([loadTransactions(), loadBalance(), loadStatistics()]);
  }

  /// Load principal account transactions
  Future<void> loadTransactions({PrincipalAccountListParams? params}) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _service.getTransactions(params: params);

      if (response.success && response.data != null) {
        _accounts = response.data!.transactions;
        _pagination = response.data!.pagination;
        _notifyListeners();
      } else {
        _setError(response.message);
      }
    } catch (e) {
      _setError('Failed to load transactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load current balance
  Future<void> loadBalance() async {
    try {
      final response = await _service.getBalance();

      if (response.success && response.data != null) {
        _currentBalance = response.data;
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load balance: $e');
    }
  }

  /// Load statistics
  Future<void> loadStatistics({int days = 30}) async {
    try {
      final response = await _service.getStatistics(days: days);

      if (response.success && response.data != null) {
        _statistics = response.data;
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load statistics: $e');
    }
  }

  /// Create new transaction
  Future<bool> createTransaction(PrincipalAccountCreateRequest request) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _service.createTransaction(request);

      if (response.success && response.data != null) {
        // Add new transaction to the list
        _accounts.insert(0, response.data!);

        // Reload balance and statistics
        await Future.wait([loadBalance(), loadStatistics()]);

        _notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to create transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update transaction
  Future<bool> updateTransaction(String id, PrincipalAccountUpdateRequest request) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _service.updateTransaction(id, request);

      if (response.success && response.data != null) {
        // Update transaction in the list
        final index = _accounts.indexWhere((account) => account.id == id);
        if (index != -1) {
          _accounts[index] = response.data!;
          _notifyListeners();
        }

        // Reload balance and statistics
        await Future.wait([loadBalance(), loadStatistics()]);

        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to update transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete transaction
  Future<bool> deleteTransaction(String id) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _service.deleteTransaction(id);

      if (response.success) {
        // Remove transaction from the list
        _accounts.removeWhere((account) => account.id == id);

        // Reload balance and statistics
        await Future.wait([loadBalance(), loadStatistics()]);

        _notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete transaction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Create transaction from other modules
  Future<bool> createTransactionFromModule(PrincipalAccountCreateRequest request) async {
    try {
      final response = await _service.createTransactionFromModule(request);

      if (response.success && response.data != null) {
        // Reload data to reflect the new transaction
        await Future.wait([loadTransactions(), loadBalance(), loadStatistics()]);

        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to create transaction from module: $e');
      return false;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await _initializeData();
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _service.clearCache();
  }

  /// Search transactions
  Future<void> searchTransactions(String query) async {
    if (query.isEmpty) {
      await loadTransactions();
    } else {
      final params = PrincipalAccountListParams(search: query);
      await loadTransactions(params: params);
    }
  }

  /// Filter transactions by source module
  Future<void> filterBySourceModule(String? sourceModule) async {
    final params = PrincipalAccountListParams(sourceModule: sourceModule, page: 1);
    await loadTransactions(params: params);
  }

  /// Filter transactions by type
  Future<void> filterByTransactionType(String? transactionType) async {
    final params = PrincipalAccountListParams(transactionType: transactionType, page: 1);
    await loadTransactions(params: params);
  }

  /// Filter transactions by date range
  Future<void> filterByDateRange(DateTime? dateFrom, DateTime? dateTo) async {
    final params = PrincipalAccountListParams(dateFrom: dateFrom, dateTo: dateTo, page: 1);
    await loadTransactions(params: params);
  }

  /// Filter transactions by amount range
  Future<void> filterByAmountRange(double? minAmount, double? maxAmount) async {
    final params = PrincipalAccountListParams(minAmount: minAmount, maxAmount: maxAmount, page: 1);
    await loadTransactions(params: params);
  }

  /// Filter transactions by handler
  Future<void> filterByHandler(String? handledBy) async {
    final params = PrincipalAccountListParams(handledBy: handledBy, page: 1);
    await loadTransactions(params: params);
  }

  /// Get transactions for specific page
  Future<void> loadPage(int page) async {
    final params = PrincipalAccountListParams(page: page);
    await loadTransactions(params: params);
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    _notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _notifyListeners() {
    notifyListeners();
  }

  // Computed properties
  double get totalCredits {
    return _accounts.where((account) => account.type == 'CREDIT').fold(0.0, (sum, account) => sum + account.amount);
  }

  double get totalDebits {
    return _accounts.where((account) => account.type == 'DEBIT').fold(0.0, (sum, account) => sum + account.amount);
  }

  double get netBalance {
    return totalCredits - totalDebits;
  }

  String get formattedTotalCredits => 'PKR ${totalCredits.toStringAsFixed(2)}';
  String get formattedTotalDebits => 'PKR ${totalDebits.toStringAsFixed(2)}';
  String get formattedNetBalance => 'PKR ${netBalance.toStringAsFixed(2)}';

  // Get transactions by source module
  List<PrincipalAccount> getTransactionsByModule(String sourceModule) {
    return _accounts.where((account) => account.sourceModule == sourceModule).toList();
  }

  // Get transactions by type
  List<PrincipalAccount> getTransactionsByType(String type) {
    return _accounts.where((account) => account.type == type).toList();
  }

  // Get recent transactions
  List<PrincipalAccount> getRecentTransactions({int limit = 10}) {
    final sortedAccounts = List<PrincipalAccount>.from(_accounts);
    sortedAccounts.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return sortedAccounts.take(limit).toList();
  }

  // Get transactions by date range
  List<PrincipalAccount> getTransactionsByDateRange(DateTime startDate, DateTime endDate) {
    return _accounts.where((account) {
      return account.date.isAfter(startDate.subtract(const Duration(days: 1))) && account.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get monthly summary
  Map<String, double> getMonthlySummary(int year) {
    final monthlyData = <String, double>{};
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (int i = 1; i <= 12; i++) {
      final monthTransactions = _accounts.where((account) {
        return account.date.year == year && account.date.month == i;
      });

      final monthCredits = monthTransactions.where((account) => account.type == 'CREDIT').fold(0.0, (sum, account) => sum + account.amount);

      final monthDebits = monthTransactions.where((account) => account.type == 'DEBIT').fold(0.0, (sum, account) => sum + account.amount);

      monthlyData[months[i - 1]] = monthCredits - monthDebits;
    }

    return monthlyData;
  }

  // Get source module breakdown
  Map<String, Map<String, double>> getSourceModuleBreakdown() {
    final breakdown = <String, Map<String, double>>{};

    for (final account in _accounts) {
      if (!breakdown.containsKey(account.sourceModule)) {
        breakdown[account.sourceModule] = {'credits': 0.0, 'debits': 0.0};
      }

      if (account.type == 'CREDIT') {
        breakdown[account.sourceModule]!['credits'] = (breakdown[account.sourceModule]!['credits'] ?? 0.0) + account.amount;
      } else {
        breakdown[account.sourceModule]!['debits'] = (breakdown[account.sourceModule]!['debits'] ?? 0.0) + account.amount;
      }
    }

    return breakdown;
  }

  // Add missing method for addPrincipalAccount (alias for createTransaction)
  Future<bool> addPrincipalAccount(PrincipalAccountCreateRequest request) async {
    return await createTransaction(request);
  }

  // Add missing method for updatePrincipalAccount (alias for alias for updateTransaction)
  Future<bool> updatePrincipalAccount(String id, PrincipalAccountUpdateRequest request) async {
    return await updateTransaction(id, request);
  }

  // Add missing method for deletePrincipalAccount (alias for deleteTransaction)
  Future<bool> deletePrincipalAccount(String id) async {
    return await deleteTransaction(id);
  }

  // Add missing method for searchAccounts (alias for searchTransactions)
  Future<void> searchAccounts(String query) async {
    return await searchTransactions(query);
  }
}
