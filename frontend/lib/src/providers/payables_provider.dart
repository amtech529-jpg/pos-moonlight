import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/payable/payable_model.dart';
import '../models/payable/payable_api_responses.dart';
import '../services/payable_service.dart';

class PayablesProvider extends ChangeNotifier {
  final PayableService _payableService = PayableService();

  List<Payable> _payables = [];
  List<Payable> _filteredPayables = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String _searchQuery = '';
  PaginationInfo? _paginationInfo;
  PayableStatisticsResponse? _statistics;

  // Sorting and filtering
  String _sortBy = 'created_at';
  bool _sortAscending = false;
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedVendor;
  DateTime? _dueAfter;
  DateTime? _dueBefore;
  DateTime? _borrowedAfter;
  DateTime? _borrowedBefore;
  bool _showInactive = false;
  bool _overdueOnly = false;
  bool _urgentOnly = false;

  // Getters
  List<Payable> get payables => _filteredPayables;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  PaginationInfo? get paginationInfo => _paginationInfo;
  PayableStatisticsResponse? get statistics => _statistics;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  String? get selectedStatus => _selectedStatus;
  String? get selectedPriority => _selectedPriority;
  String? get selectedVendor => _selectedVendor;
  DateTime? get dueAfter => _dueAfter;
  DateTime? get dueBefore => _dueBefore;
  DateTime? get borrowedAfter => _borrowedAfter;
  DateTime? get borrowedBefore => _borrowedBefore;
  bool get showInactive => _showInactive;
  bool get overdueOnly => _overdueOnly;
  bool get urgentOnly => _urgentOnly;

  PayablesProvider() {
    loadPayables();
    loadStatistics();
  }

  /// Load payables from API
  Future<void> loadPayables({int page = 1, int pageSize = 20, bool showLoading = true}) async {
    if (showLoading) {
      _setLoading(true);
    }

    try {
      final params = PayableListParams(
        page: page,
        pageSize: pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: _selectedStatus,
        priority: _selectedPriority,
        vendorId: _selectedVendor,
        dueAfter: _dueAfter,
        dueBefore: _dueBefore,
        borrowedAfter: _borrowedAfter,
        borrowedBefore: _borrowedBefore,
        overdueOnly: _overdueOnly,
        urgentOnly: _urgentOnly,
        sortBy: _sortBy,
        sortOrder: _sortAscending ? 'asc' : 'desc',
        showInactive: _showInactive,
      );

      final response = await _payableService.getPayables(params: params);

      if (response.success && response.data != null) {
        _payables = response.data!.payables;
        _filteredPayables = List.from(_payables);
        _paginationInfo = response.data!.pagination;
        _clearError();
        notifyListeners(); // Notify listeners after updating data
      } else {
        _setError(response.message ?? 'Failed to load payables');
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
      final response = await _payableService.getStatistics();

      if (response.success && response.data != null) {
        _statistics = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  /// Add new payable
  Future<bool> addPayable({
    required String creditorName,
    String? creditorPhone,
    String? creditorEmail,
    String? vendorId,
    required double amountBorrowed,
    double amountPaid = 0.0,
    String reasonOrItem = '',
    required DateTime dateBorrowed,
    required DateTime expectedRepaymentDate,
    String priority = 'MEDIUM',
    String? notes,
  }) async {
    try {
      final request = PayableCreateRequest(
        creditorName: creditorName,
        creditorPhone: creditorPhone,
        creditorEmail: creditorEmail,
        vendorId: vendorId,
        amountBorrowed: amountBorrowed,
        amountPaid: amountPaid,
        reasonOrItem: reasonOrItem,
        dateBorrowed: dateBorrowed,
        expectedRepaymentDate: expectedRepaymentDate,
        priority: priority,
        notes: notes,
      );

      final response = await _payableService.createPayable(request);

      if (response.success) {
        await loadPayables(showLoading: false);
        await loadStatistics();
        return true;
      } else {
        _setError(response.message ?? 'Failed to create payable');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    }
  }

  /// Update existing payable
  Future<bool> updatePayable({
    required String id,
    String? creditorName,
    String? creditorPhone,
    String? creditorEmail,
    String? vendorId,
    double? amountBorrowed,
    double? amountPaid,
    String? reasonOrItem,
    DateTime? dateBorrowed,
    DateTime? expectedRepaymentDate,
    String? priority,
    String? status,
    String? notes,
  }) async {
    try {
      final request = PayableUpdateRequest(
        creditorName: creditorName,
        creditorPhone: creditorPhone,
        creditorEmail: creditorEmail,
        vendorId: vendorId,
        amountBorrowed: amountBorrowed,
        amountPaid: amountPaid,
        reasonOrItem: reasonOrItem,
        dateBorrowed: dateBorrowed,
        expectedRepaymentDate: expectedRepaymentDate,
        priority: priority,
        status: status,
        notes: notes,
      );

      final response = await _payableService.updatePayable(id, request);

      if (response.success) {
        await loadPayables(showLoading: false);
        await loadStatistics();
        return true;
      } else {
        _setError(response.message ?? 'Failed to update payable');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    }
  }

  /// Delete payable
  Future<bool> deletePayable(String id) async {
    try {
      final response = await _payableService.deletePayable(id);

      if (response.success) {
        await loadPayables(showLoading: false);
        await loadStatistics();
        return true;
      } else {
        _setError(response.message ?? 'Failed to delete payable');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    }
  }

  /// Soft delete payable
  Future<bool> softDeletePayable(String id) async {
    try {
      final response = await _payableService.softDeletePayable(id);

      if (response.success) {
        await loadPayables(showLoading: false);
        await loadStatistics();
        return true;
      } else {
        _setError(response.message ?? 'Failed to soft delete payable');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    }
  }

  /// Restore soft deleted payable
  Future<bool> restorePayable(String id) async {
    try {
      final response = await _payableService.restorePayable(id);

      if (response.success) {
        await loadPayables(showLoading: false);
        await loadStatistics();
        return true;
      } else {
        _setError(response.message ?? 'Failed to restore payable');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    }
  }

  /// Add payment to payable
  Future<bool> addPayment({required String payableId, required double amount, required DateTime paymentDate, String? notes}) async {
    try {
      final request = PayablePaymentRequest(amount: amount, paymentDate: paymentDate, notes: notes);

      final response = await _payableService.addPayment(payableId, request);

      if (response.success) {
        await loadPayables(showLoading: false);
        await loadStatistics();
        return true;
      } else {
        _setError(response.message ?? 'Failed to add payment');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    }
  }

  /// Update payable contact
  Future<bool> updateContact({required String payableId, String? creditorPhone, String? creditorEmail}) async {
    try {
      final request = PayableContactUpdateRequest(creditorPhone: creditorPhone, creditorEmail: creditorEmail);

      final response = await _payableService.updateContact(payableId, request);

      if (response.success) {
        await loadPayables(showLoading: false);
        return true;
      } else {
        _setError(response.message ?? 'Failed to update contact');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    }
  }

  /// Get overdue payables
  Future<void> loadOverduePayables() async {
    try {
      final response = await _payableService.getOverduePayables();

      if (response.success && response.data != null) {
        _payables = response.data!.payables;
        _filteredPayables = List.from(_payables);
        _paginationInfo = response.data!.pagination;
        _clearError();
      } else {
        _setError(response.message ?? 'Failed to load overdue payables');
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Get urgent payables
  Future<void> loadUrgentPayables() async {
    try {
      final response = await _payableService.getUrgentPayables();

      if (response.success && response.data != null) {
        _payables = response.data!.payables;
        _filteredPayables = List.from(_payables);
        _paginationInfo = response.data!.pagination;
        _clearError();
      } else {
        _setError(response.message ?? 'Failed to load urgent payables');
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Perform bulk actions
  Future<bool> performBulkActions({required List<String> payableIds, required String action, Map<String, dynamic>? actionData}) async {
    try {
      final request = PayableBulkActionRequest(payableIds: payableIds, action: action, actionData: actionData);

      final response = await _payableService.bulkActions(request);

      if (response.success) {
        await loadPayables(showLoading: false);
        await loadStatistics();
        return true;
      } else {
        _setError(response.message ?? 'Failed to perform bulk actions');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    }
  }

  /// Refresh payables data
  Future<void> refreshPayables() async {
    await loadPayables(showLoading: false);
    await loadStatistics();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Set status filter
  void setStatusFilter(String? status) {
    _selectedStatus = status;
    _applyFilters();
  }

  /// Set priority filter
  void setPriorityFilter(String? priority) {
    _selectedPriority = priority;
    _applyFilters();
  }

  /// Set vendor filter
  void setVendorFilter(String? vendor) {
    _selectedVendor = vendor;
    _applyFilters();
  }

  /// Set due date range
  void setDueDateRange(DateTime? after, DateTime? before) {
    _dueAfter = after;
    _dueBefore = before;
    _applyFilters();
  }

  /// Set borrowed date range
  void setBorrowedDateRange(DateTime? after, DateTime? before) {
    _borrowedAfter = after;
    _borrowedBefore = before;
    _applyFilters();
  }

  /// Set overdue only filter
  void setOverdueOnly(bool value) {
    _overdueOnly = value;
    _applyFilters();
  }

  /// Set urgent only filter
  void setUrgentOnly(bool value) {
    _urgentOnly = value;
    _applyFilters();
  }

  /// Set show inactive filter
  void setShowInactive(bool value) {
    _showInactive = value;
    _applyFilters();
  }

  /// Set sorting
  void setSorting(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFilters();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedStatus = null;
    _selectedPriority = null;
    _selectedVendor = null;
    _dueAfter = null;
    _dueBefore = null;
    _borrowedAfter = null;
    _borrowedBefore = null;
    _overdueOnly = false;
    _urgentOnly = false;
    _showInactive = false;
    _sortBy = 'expected_repayment_date';
    _sortAscending = true;
    _applyFilters();
  }

  /// Apply filters and sorting
  void _applyFilters() {
    // Use API-based filtering instead of client-side filtering
    loadPayables(showLoading: false);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error state
  void _clearError() {
    _hasError = false;
    _errorMessage = null;
  }

  /// Public method to clear error
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Get payable by ID
  Payable? getPayableById(String id) {
    try {
      return _payables.firstWhere((payable) => payable.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get payables by status
  List<Payable> getPayablesByStatus(String status) {
    return _payables.where((payable) => payable.status == status).toList();
  }

  /// Get payables by priority
  List<Payable> getPayablesByPriority(String priority) {
    return _payables.where((payable) => payable.priority == priority).toList();
  }

  /// Get overdue payables
  List<Payable> getOverduePayables() {
    return _payables.where((payable) => payable.isOverdueComputed).toList();
  }

  /// Get urgent payables
  List<Payable> getUrgentPayables() {
    return _payables.where((payable) => payable.priority == 'URGENT').toList();
  }

  /// Get total amount borrowed
  double get totalAmountBorrowed {
    try {
      if (_statistics != null) {
        return _statistics!.totalBorrowedAmount;
      }
      return _payables.fold(0.0, (sum, payable) => sum + payable.amountBorrowed);
    } catch (e) {
      return _payables.fold(0.0, (sum, payable) => sum + payable.amountBorrowed);
    }
  }

  /// Get total amount paid
  double get totalAmountPaid {
    try {
      if (_statistics != null) {
        return _statistics!.totalPaidAmount;
      }
      return _payables.fold(0.0, (sum, payable) => sum + payable.amountPaid);
    } catch (e) {
      return _payables.fold(0.0, (sum, payable) => sum + payable.amountPaid);
    }
  }

  /// Get total balance remaining
  double get totalBalanceRemaining {
    try {
      if (_statistics != null) {
        return _statistics!.totalOutstandingAmount;
      }
      return _payables.fold(0.0, (sum, payable) => sum + payable.balanceRemaining);
    } catch (e) {
      return _payables.fold(0.0, (sum, payable) => sum + payable.balanceRemaining);
    }
  }

  /// Get average payment percentage
  double get averagePaymentPercentage {
    try {
      if (_statistics != null && _statistics!.totalBorrowedAmount > 0) {
        return (_statistics!.totalPaidAmount / _statistics!.totalBorrowedAmount) * 100;
      }
      if (_payables.isEmpty) return 0.0;
      final totalPercentage = _payables.fold(0.0, (sum, payable) => sum + payable.paymentPercentage);
      return totalPercentage / _payables.length;
    } catch (e) {
      if (_payables.isEmpty) return 0.0;
      final totalPercentage = _payables.fold(0.0, (sum, payable) => sum + payable.paymentPercentage);
      return totalPercentage / _payables.length;
    }
  }

  /// Set sorting field
  void setSortBy(String sortBy) {
    if (_sortBy == sortBy) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = sortBy;
      _sortAscending = true;
    }
    _applyFilters();
    notifyListeners();
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (_paginationInfo != null && _paginationInfo!.hasNext) {
      await loadPayables(page: _paginationInfo!.currentPage + 1, showLoading: false);
    }
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (_paginationInfo != null && _paginationInfo!.hasPrevious) {
      await loadPayables(page: _paginationInfo!.currentPage - 1, showLoading: false);
    }
  }

  /// Generate partner payables for an order
  Future<bool> generatePartnerPayables({
    required String orderId,
    bool recalculate = false,
  }) async {
    try {
      _setLoading(true);
      final response = await _payableService.generatePartnerPayables(
        orderId: orderId,
        recalculate: recalculate,
      );

      if (response.success) {
        await loadPayables(showLoading: false);
        await loadStatistics();
        return true;
      } else {
        _setError(response.message ?? 'Failed to generate partner payables');
        return false;
      }
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
