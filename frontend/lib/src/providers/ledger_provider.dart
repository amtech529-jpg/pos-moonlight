import 'package:flutter/material.dart';
import 'package:frontend/src/services/ledger_service.dart';

class LedgerProvider extends ChangeNotifier {
  final LedgerService _ledgerService = LedgerService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic> _totals = {};
  double _totalOverdue = 0.0;
  List<dynamic> _allLedgerEntries = [];
  List<dynamic> _filteredLedgerEntries = [];
  String _searchQuery = "";

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get totals => _totals;
  double get totalOverdue => _totalOverdue;
  List<dynamic> get ledgerEntries => _filteredLedgerEntries;

  Future<void> loadLedger({String? customerId, String? startDate, String? endDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _ledgerService.getGeneralLedger(
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
      );
      _totals = data['totals'] ?? {};
      _totalOverdue = (data['total_overdue'] ?? 0.0).toDouble();
      _allLedgerEntries = data['ledger_entries'] ?? [];
      _applyFilter();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredLedgerEntries = List.from(_allLedgerEntries);
    } else {
      _filteredLedgerEntries = _allLedgerEntries.where((entry) {
        final invoiceNum = (entry['invoice_number'] ?? "").toString().toLowerCase();
        final customerName = (entry['customer_name'] ?? "").toString().toLowerCase();
        return invoiceNum.contains(_searchQuery) || customerName.contains(_searchQuery);
      }).toList();
    }
  }
}
