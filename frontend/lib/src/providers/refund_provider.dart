import 'package:flutter/material.dart';
import '../models/sales/return_model.dart';
import '../services/return_service.dart';

class RefundProvider extends ChangeNotifier {
  final ReturnService _returnService = ReturnService();

  // State variables
  List<RefundModel> _refunds = [];
  RefundModel? _selectedRefund;
  bool _isLoading = false;
  String? _error;
  String? _success;

  // Filter and search
  String _searchQuery = '';
  String _statusFilter = '';
  String _methodFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  List<RefundModel> get refunds => _refunds;
  RefundModel? get selectedRefund => _selectedRefund;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get success => _success;
  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get methodFilter => _methodFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Computed properties
  List<RefundModel> get filteredRefunds {
    return _refunds.where((refund) {
      bool matchesSearch = _searchQuery.isEmpty ||
          refund.refundNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          refund.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          refund.returnNumber.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesStatus = _statusFilter.isEmpty || refund.status == _statusFilter;
      bool matchesMethod = _methodFilter.isEmpty || refund.method == _methodFilter;

      bool matchesDate = true;
      if (_startDate != null) {
        matchesDate = matchesDate && refund.refundDate.isAfter(_startDate!);
      }
      if (_endDate != null) {
        matchesDate = matchesDate && refund.refundDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesStatus && matchesMethod && matchesDate;
    }).toList();
  }

  List<RefundModel> get pendingRefunds => _refunds.where((r) => r.status == 'PENDING').toList();
  List<RefundModel> get processedRefunds => _refunds.where((r) => r.status == 'PROCESSED').toList();
  List<RefundModel> get failedRefunds => _refunds.where((r) => r.status == 'FAILED').toList();
  List<RefundModel> get cancelledRefunds => _refunds.where((r) => r.status == 'CANCELLED').toList();

  // Initialize provider
  Future<void> initialize() async {
    await loadRefunds();
  }

  // Load refunds
  Future<void> loadRefunds({
    String? search,
    String? status,
    String? method,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? pageSize,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _returnService.getRefunds(
        search: search,
        status: status,
        method: method,
        startDate: startDate,
        endDate: endDate,
        page: page,
        pageSize: pageSize,
      );

      if (response.success && response.data != null) {
        _refunds = response.data!;
        notifyListeners();
      } else {
        _setError(response.message ?? 'Failed to load refunds');
      }
    } catch (e) {
      _setError('Error loading refunds: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get refund by ID
  Future<RefundModel?> getRefund(String id) async {
    try {
      final response = await _returnService.getRefund(id);
      if (response.success && response.data != null) {
        return response.data!;
      } else {
        _setError(response.message ?? 'Failed to get refund');
        return null;
      }
    } catch (e) {
      _setError('Error getting refund: $e');
      return null;
    }
  }

  // Create refund
  Future<bool> createRefund({
    required String returnRequestId,
    required double amount,
    required String method,
    String? notes,
    String? referenceNumber,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _returnService.createRefund(
        returnRequestId: returnRequestId,
        amount: amount,
        method: method,
        notes: notes,
        referenceNumber: referenceNumber,
      );

      if (response.success && response.data != null) {
        _refunds.insert(0, response.data!);
        _setSuccess('Refund created successfully');
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to create refund');
        return false;
      }
    } catch (e) {
      _setError('Error creating refund: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update refund
  Future<bool> updateRefund({
    required String id,
    String? method,
    String? notes,
    String? referenceNumber,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _returnService.updateRefund(
        id: id,
        method: method,
        notes: notes,
        referenceNumber: referenceNumber,
      );

      if (response.success && response.data != null) {
        final index = _refunds.indexWhere((r) => r.id == id);
        if (index != -1) {
          _refunds[index] = response.data!;
          notifyListeners();
        }
        _setSuccess('Refund updated successfully');
        return true;
      } else {
        _setError(response.message ?? 'Failed to update refund');
        return false;
      }
    } catch (e) {
      _setError('Error updating refund: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete refund
  Future<bool> deleteRefund(String id) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _returnService.deleteRefund(id);

      if (response.success) {
        _refunds.removeWhere((refund) => refund.id == id);
        _setSuccess('Refund deleted successfully');
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete refund: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Process refund
  Future<bool> processRefund({
    required String id,
    String? referenceNumber,
    String? notes,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _returnService.processRefund(
        id: id,
        referenceNumber: referenceNumber,
        notes: notes,
      );

      if (response.success && response.data != null) {
        final index = _refunds.indexWhere((r) => r.id == id);
        if (index != -1) {
          _refunds[index] = response.data!;
          notifyListeners();
        }
        _setSuccess('Refund processed successfully');
        return true;
      } else {
        _setError(response.message ?? 'Failed to process refund');
        return false;
      }
    } catch (e) {
      _setError('Error processing refund: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Fail refund
  Future<bool> failRefund({
    required String id,
    String? notes,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _returnService.failRefund(
        id: id,
        notes: notes,
      );

      if (response.success && response.data != null) {
        final index = _refunds.indexWhere((r) => r.id == id);
        if (index != -1) {
          _refunds[index] = response.data!;
          notifyListeners();
        }
        _setSuccess('Refund marked as failed');
        return true;
      } else {
        _setError(response.message ?? 'Failed to mark refund as failed');
        return false;
      }
    } catch (e) {
      _setError('Error marking refund as failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel refund
  Future<bool> cancelRefund({
    required String id,
    String? notes,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _returnService.cancelRefund(
        id: id,
        notes: notes,
      );

      if (response.success && response.data != null) {
        final index = _refunds.indexWhere((r) => r.id == id);
        if (index != -1) {
          _refunds[index] = response.data!;
          notifyListeners();
        }
        _setSuccess('Refund cancelled successfully');
        return true;
      } else {
        _setError(response.message ?? 'Failed to cancel refund');
        return false;
      }
    } catch (e) {
      _setError('Error cancelling refund: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set filters
  void setFilters({
    String? search,
    String? status,
    String? method,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (search != null) _searchQuery = search;
    if (status != null) _statusFilter = status;
    if (method != null) _methodFilter = method;
    if (startDate != null) _startDate = startDate;
    if (endDate != null) _endDate = endDate;
    
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _statusFilter = '';
    _methodFilter = '';
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  // Select refund
  void selectRefund(RefundModel? refund) {
    _selectedRefund = refund;
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _success = null;
    notifyListeners();
  }

  void _setSuccess(String success) {
    _success = success;
    _error = null;
    notifyListeners();
  }

  void _clearMessages() {
    _error = null;
    _success = null;
    notifyListeners();
  }
}
