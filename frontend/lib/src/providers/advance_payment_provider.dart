import 'package:flutter/material.dart';
import '../models/advance_payment/advance_payment_api_responses.dart';
import '../models/advance_payment/advance_payment_model.dart';
import '../models/advance_payment/advance_payment_requests.dart';
import '../models/labor/labor_model.dart';
import '../services/advance_payment_service.dart';
import '../services/labor/labor_service.dart';
import 'dart:io';

class AdvancePaymentProvider extends ChangeNotifier {
  final AdvancePaymentService _advancePaymentService = AdvancePaymentService();
  final LaborService _laborService = LaborService();

  List<AdvancePayment> _advancePayments = [];
  List<AdvancePayment> _filteredAdvancePayments = [];
  List<LaborModel> _laborers = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _searchQuery = '';
  PaginationInfo? _paginationInfo;
  AdvancePaymentStatisticsResponse? _statistics;

  // Sorting and filtering
  String _sortBy = 'date';
  bool _sortAscending = false;
  String? _selectedLaborId;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  double? _minAmount;
  double? _maxAmount;
  String? _hasReceipt;
  bool _showInactive = false;

  // Getters
  List<AdvancePayment> get advancePayments => _filteredAdvancePayments;
  List<LaborModel> get laborers => _laborers;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  PaginationInfo? get paginationInfo => _paginationInfo;
  AdvancePaymentStatisticsResponse? get statistics => _statistics;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  String? get selectedLaborId => _selectedLaborId;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  double? get minAmount => _minAmount;
  double? get maxAmount => _maxAmount;
  String? get hasReceipt => _hasReceipt;
  bool get showInactive => _showInactive;

  AdvancePaymentProvider() {
    loadAdvancePayments();
    loadLaborers();
  }

  /// Load advance payments from API
  Future<void> loadAdvancePayments({int page = 1, int pageSize = 20, bool showLoading = true}) async {
    if (showLoading) {
      _setLoading(true);
    }

    try {
      final params = AdvancePaymentListParams(
        page: page,
        pageSize: pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        laborName: _selectedLaborId != null ? getLaborById(_selectedLaborId!)?.name : null,
        laborRole: null,
        laborPhone: null,
        minAmount: _minAmount,
        maxAmount: _maxAmount,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        hasReceipt: _hasReceipt,
        sortBy: _sortBy,
        sortOrder: _sortAscending ? 'asc' : 'desc',
        showInactive: _showInactive,
      );

      final response = await _advancePaymentService.getAdvancePayments(params: params);

      if (response.success && response.data != null) {
        _advancePayments = response.data!.advancePayments;
        _filteredAdvancePayments = List.from(_advancePayments);
        _paginationInfo = response.data!.pagination;
        _clearError();
      } else {
        _setError(response.message.isNotEmpty ? response.message : 'Failed to load advance payments');
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load statistics
  Future<void> loadStatistics() async {
    try {
      final response = await _advancePaymentService.getAdvancePaymentStatistics();

      if (response.success && response.data != null) {
        _statistics = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  /// Add new advance payment
  Future<bool> addAdvancePayment({
    required String laborId,
    required double amount,
    required String description,
    required DateTime date,
    required TimeOfDay time,
    File? receiptImageFile,
  }) async {
    _setLoading(true);

    try {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

      final response = await _advancePaymentService.createAdvancePayment(
        laborId: laborId,
        amount: amount,
        description: description,
        date: date,
        time: timeString,
        receiptImageFile: receiptImageFile,
      );

      if (response.success && response.data != null) {
        // Refresh the list to include the new record
        await loadAdvancePayments(showLoading: false);
        await loadStatistics(); // Refresh statistics
        _clearError();
        return true;
      } else {
        _setError(response.message.isNotEmpty ? response.message : 'Failed to add advance payment');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update existing advance payment
  Future<bool> updateAdvancePayment({
    required String id,
    required String laborId,
    required double amount,
    required String description,
    required DateTime date,
    required TimeOfDay time,
    File? receiptImageFile,
  }) async {
    _setLoading(true);

    try {
      final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

      final response = await _advancePaymentService.updateAdvancePayment(
        id: id,
        laborId: laborId,
        amount: amount,
        description: description,
        date: date,
        time: timeString,
        receiptImageFile: receiptImageFile,
      );

      if (response.success && response.data != null) {
        // Refresh the list to include the updated record
        await loadAdvancePayments(showLoading: false);
        await loadStatistics(); // Refresh statistics
        _clearError();
        return true;
      } else {
        _setError(response.message.isNotEmpty ? response.message : 'Failed to update advance payment');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete advance payment
  Future<bool> deleteAdvancePayment(String id) async {
    _setLoading(true);

    try {
      final response = await _advancePaymentService.deleteAdvancePayment(id);

      if (response.success) {
        // Refresh the list to remove the deleted record
        await loadAdvancePayments(showLoading: false);
        await loadStatistics(); // Refresh statistics
        _clearError();
        return true;
      } else {
        _setError(response.message.isNotEmpty ? response.message : 'Failed to delete advance payment');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Search advance payments
  Future<void> searchAdvancePayments(String query) async {
    _searchQuery = query;
    // Reload records with search query
    await loadAdvancePayments();
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
    await loadAdvancePayments();
  }

  /// Set labor filter
  Future<void> setLaborFilter(String? laborId) async {
    _selectedLaborId = laborId;
    await loadAdvancePayments();
  }

  /// Set date range filter
  Future<void> setDateRangeFilter(DateTime? from, DateTime? to) async {
    _dateFrom = from;
    _dateTo = to;
    await loadAdvancePayments();
  }

  /// Set amount range filter
  Future<void> setAmountRangeFilter(double? min, double? max) async {
    _minAmount = min;
    _maxAmount = max;
    await loadAdvancePayments();
  }

  /// Set receipt filter
  Future<void> setReceiptFilter(String? hasReceipt) async {
    _hasReceipt = hasReceipt;
    await loadAdvancePayments();
  }

  /// Set inactive records filter
  Future<void> setShowInactiveFilter(bool showInactive) async {
    _showInactive = showInactive;
    await loadAdvancePayments();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _selectedLaborId = null;
    _dateFrom = null;
    _dateTo = null;
    _minAmount = null;
    _maxAmount = null;
    _hasReceipt = null;
    _searchQuery = '';
    _showInactive = false;
    await loadAdvancePayments();
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (_paginationInfo?.hasNext == true) {
      await loadAdvancePayments(page: _paginationInfo!.currentPage + 1);
    }
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (_paginationInfo?.hasPrevious == true) {
      await loadAdvancePayments(page: _paginationInfo!.currentPage - 1);
    }
  }

  /// Get advance payment by ID
  AdvancePayment? getAdvancePaymentById(String id) {
    try {
      return _advancePayments.firstWhere((payment) => payment.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get advance payments by labor ID
  List<AdvancePayment> getAdvancePaymentsByLaborId(String laborId) {
    return _advancePayments.where((payment) => payment.laborId == laborId).toList();
  }

  /// Get labor by ID
  LaborModel? getLaborById(String laborId) {
    try {
      return _laborers.firstWhere((labor) => labor.id == laborId);
    } catch (e) {
      return null;
    }
  }

  /// Get statistics
  Map<String, dynamic> get advancePaymentStats {
    if (_statistics == null) {
      // Return default stats if statistics not loaded
      return {
        'total': _advancePayments.length,
        'totalAmount': _advancePayments.fold<double>(0.0, (sum, payment) => sum + payment.amount).toStringAsFixed(0),
        'withReceipts': _advancePayments.where((payment) => payment.hasReceipt).length,
        'thisMonth': _getThisMonthCount(),
      };
    }

    return {
      'total': _statistics!.totalPayments,
      'totalAmount': _statistics!.totalAmount.toStringAsFixed(0),
      'withReceipts': _statistics!.paymentsWithReceipts,
      'thisMonth': _statistics!.thisMonthPayments,
    };
  }

  /// Get recent advance payments
  List<AdvancePayment> get recentAdvancePayments {
    final recent = List<AdvancePayment>.from(_advancePayments);
    recent.sort((a, b) => b.date.compareTo(a.date));
    return recent.take(10).toList();
  }

  /// Get high advance payments
  List<AdvancePayment> get highAdvancePayments {
    return _advancePayments.where((payment) => payment.advancePercentage >= 50).toList();
  }

  /// Get payments without receipts
  List<AdvancePayment> get paymentsWithoutReceipts {
    return _advancePayments.where((payment) => !payment.hasReceipt).toList();
  }

  /// Get payments that need attention
  List<AdvancePayment> get paymentsNeedingAttention {
    return _advancePayments.where((payment) {
      return !payment.hasReceipt || payment.advancePercentage >= 80;
    }).toList();
  }

  /// Filter advance payments
  List<AdvancePayment> filterAdvancePayments({
    String? laborId,
    DateTime? fromDate,
    DateTime? toDate,
    double? minAmount,
    double? maxAmount,
    bool? hasReceipt,
  }) {
    return _advancePayments.where((payment) {
      if (laborId != null && payment.laborId != laborId) return false;
      if (fromDate != null && payment.date.isBefore(fromDate)) return false;
      if (toDate != null && payment.date.isAfter(toDate)) return false;
      if (minAmount != null && payment.amount < minAmount) return false;
      if (maxAmount != null && payment.amount > maxAmount) return false;
      if (hasReceipt != null && payment.hasReceipt != hasReceipt) return false;
      return true;
    }).toList();
  }

  /// Export advance payment data
  List<Map<String, dynamic>> exportAdvancePaymentData() {
    return _advancePayments
        .map(
          (payment) => {
            'Advance ID': payment.id,
            'Labor Name': payment.laborName,
            'Labor Phone': payment.laborPhone,
            'Labor Role': payment.laborRole,
            'Amount': payment.amount.toStringAsFixed(2),
            'Description': payment.description,
            'Date': payment.date.toString().split(' ')[0],
            'Time': payment.timeText,
            'Has Receipt': payment.hasReceipt ? 'Yes' : 'No',
            'Remaining Salary': payment.remainingSalary.toStringAsFixed(2),
            'Total Salary': payment.totalSalary.toStringAsFixed(2),
            'Advance Percentage': '${payment.advancePercentage.toStringAsFixed(1)}%',
            'Status': payment.statusText,
          },
        )
        .toList();
  }

  /// Get labor advance summary
  List<Map<String, dynamic>> getLaborAdvanceSummary() {
    return _laborers.map((labor) {
      final laborPayments = getAdvancePaymentsByLaborId(labor.id);
      final totalAdvancesTaken = laborPayments.fold<double>(0, (sum, payment) => sum + payment.amount);
      final paymentsCount = laborPayments.length;
      final lastAdvanceDate = laborPayments.isNotEmpty ? laborPayments.map((p) => p.date).reduce((a, b) => a.isAfter(b) ? a : b) : null;

      return {
        'labor': labor,
        'totalAdvancesTaken': totalAdvancesTaken,
        'paymentsCount': paymentsCount,
        'remainingSalary': labor.salary - totalAdvancesTaken,
        'lastAdvanceDate': lastAdvanceDate,
        'advancePercentage': labor.salary > 0 ? (totalAdvancesTaken / labor.salary * 100) : 0,
      };
    }).toList();
  }

  /// Refresh data (for pull-to-refresh functionality)
  Future<void> refreshAdvancePayments() async {
    await loadAdvancePayments();
    await loadStatistics();
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

  int _getThisMonthCount() {
    final now = DateTime.now();
    return _advancePayments.where((payment) => payment.date.year == now.year && payment.date.month == now.month).length;
  }

  /// Load laborers from API
  Future<void> loadLaborers() async {
    try {
      final response = await _laborService.getLabors();
      if (response.success && response.data != null) {
        _laborers = response.data!.labors;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading laborers: $e');
    }
  }

  /// Clear all records (for testing purposes)
  void clearAllRecords() {
    _advancePayments.clear();
    _filteredAdvancePayments.clear();
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
