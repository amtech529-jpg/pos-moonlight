import 'package:flutter/foundation.dart';

import '../models/customer_ledger/customer_ledger_model.dart';
import '../services/customer_ledger_service.dart';


class CustomerLedgerProvider with ChangeNotifier {
  final CustomerLedgerService _service = CustomerLedgerService();

  bool _isLoading = false;
  String? _errorMessage;
  List<CustomerLedgerEntry> _ledgerEntries = [];
  CustomerLedgerSummary? _summary;

  int _currentPage = 1;
  int _pageSize = 20;
  int _totalCount = 0;
  int _totalPages = 0;

  String? _currentCustomerId;
  String? _currentCustomerName;

  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  List<CustomerLedgerEntry> get ledgerEntries => _ledgerEntries;
  CustomerLedgerSummary? get summary => _summary;
  bool get hasLedgerEntries => _ledgerEntries.isNotEmpty;

  int get currentPage => _currentPage;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;
  bool get hasNext => _currentPage < _totalPages;
  bool get hasPrevious => _currentPage > 1;

  Future<void> loadCustomerLedger({
    required String customerId,
    required String customerName,
    int page = 1,
    String? startDate,
    String? endDate,
    String? transactionType,
  }) async {
    _currentCustomerId = customerId;
    _currentCustomerName = customerName;
    _currentPage = page;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getCustomerLedger(
        customerId: customerId,
        page: page,
        pageSize: _pageSize,
        startDate: startDate,
        endDate: endDate,
        transactionType: transactionType,
      );

      if (response.success) {
        _ledgerEntries = response.ledgerEntries;
        _summary = response.summary;
        _totalCount = response.pagination.totalCount;
        _totalPages = response.pagination.totalPages;
        _errorMessage = null;
      } else {
        _errorMessage = response.message ?? 'Failed to load ledger';
      }
    } catch (e) {
      _errorMessage = 'Error loading ledger: $e';
      debugPrint('Error loading customer ledger: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (hasNext && _currentCustomerId != null) {
      await loadCustomerLedger(
        customerId: _currentCustomerId!,
        customerName: _currentCustomerName ?? '',
        page: _currentPage + 1,
      );
    }
  }

  Future<void> loadPreviousPage() async {
    if (hasPrevious && _currentCustomerId != null) {
      await loadCustomerLedger(
        customerId: _currentCustomerId!,
        customerName: _currentCustomerName ?? '',
        page: _currentPage - 1,
      );
    }
  }

  Future<void> refreshLedger() async {
    if (_currentCustomerId != null) {
      await loadCustomerLedger(
        customerId: _currentCustomerId!,
        customerName: _currentCustomerName ?? '',
        page: 1,
      );
    }
  }

  Future<void> filterLedger({
    String? startDate,
    String? endDate,
    String? transactionType,
  }) async {
    if (_currentCustomerId != null) {
      await loadCustomerLedger(
        customerId: _currentCustomerId!,
        customerName: _currentCustomerName ?? '',
        page: 1,
        startDate: startDate,
        endDate: endDate,
        transactionType: transactionType,
      );
    }
  }

  Future<Map<String, dynamic>?> exportCustomerLedger({
    required String customerId,
    required String format,
    String? startDate,
    String? endDate,
    String? transactionType,
  }) async {
    try {
      return await _service.exportCustomerLedger(
        customerId: customerId,
        format: format,
        startDate: startDate,
        endDate: endDate,
        transactionType: transactionType,
      );
    } catch (e) {
      _errorMessage = 'Error exporting ledger: $e';
      notifyListeners();
      debugPrint('Error exporting customer ledger: $e');
      return null;
    }
  }

  void clearLedger() {
    _ledgerEntries = [];
    _summary = null;
    _currentCustomerId = null;
    _currentCustomerName = null;
    _errorMessage = null;
    _currentPage = 1;
    _totalCount = 0;
    _totalPages = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    clearLedger();
    super.dispose();
  }
}
