import 'package:flutter/foundation.dart';

import '../models/vendor_ledger/vendor_ledger_model.dart';
import '../services/vendor_ledger_service.dart.dart';


class VendorLedgerProvider with ChangeNotifier {
  final VendorLedgerService _service = VendorLedgerService();

  bool _isLoading = false;
  String? _errorMessage;
  List<VendorLedgerEntry> _ledgerEntries = [];
  VendorLedgerSummary? _summary;

  int _currentPage = 1;
  int _pageSize = 20;
  int _totalCount = 0;
  int _totalPages = 0;

  String? _currentVendorId;
  String? _currentVendorName;

  // Getters
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  List<VendorLedgerEntry> get ledgerEntries => _ledgerEntries;
  VendorLedgerSummary? get summary => _summary;
  bool get hasLedgerEntries => _ledgerEntries.isNotEmpty;

  int get currentPage => _currentPage;
  int get totalCount => _totalCount;
  int get totalPages => _totalPages;
  bool get hasNext => _currentPage < _totalPages;
  bool get hasPrevious => _currentPage > 1;

  Future<void> loadVendorLedger({
    required String vendorId,
    required String vendorName,
    int page = 1,
    String? startDate,
    String? endDate,
  }) async {
    _currentVendorId = vendorId;
    _currentVendorName = vendorName;
    _currentPage = page;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getVendorLedger(
        vendorId: vendorId,
        page: page,
        pageSize: _pageSize,
        startDate: startDate,
        endDate: endDate,
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
      debugPrint('Error loading vendor ledger: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (hasNext && _currentVendorId != null) {
      await loadVendorLedger(
        vendorId: _currentVendorId!,
        vendorName: _currentVendorName ?? '',
        page: _currentPage + 1,
      );
    }
  }

  Future<void> loadPreviousPage() async {
    if (hasPrevious && _currentVendorId != null) {
      await loadVendorLedger(
        vendorId: _currentVendorId!,
        vendorName: _currentVendorName ?? '',
        page: _currentPage - 1,
      );
    }
  }

  Future<Map<String, dynamic>?> exportVendorLedger({
    required String vendorId,
    required String format,
  }) async {
    try {
      return await _service.exportVendorLedger(
        vendorId: vendorId,
        format: format,
      );
    } catch (e) {
      _errorMessage = 'Error exporting ledger: $e';
      notifyListeners();
      debugPrint('Error exporting vendor ledger: $e');
      return null;
    }
  }

  void clearLedger() {
    _ledgerEntries = [];
    _summary = null;
    _currentVendorId = null;
    _currentVendorName = null;
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
