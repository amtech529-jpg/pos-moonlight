import 'package:flutter/material.dart';
import '../models/sales/return_model.dart';
import '../services/return_service.dart';

class ReturnProvider extends ChangeNotifier {
  final ReturnService _returnService = ReturnService();

  // State variables
  List<ReturnModel> _returns = [];
  List<RefundModel> _refunds = [];
  ReturnModel? _selectedReturn;
  RefundModel? _selectedRefund;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;

  // Getters
  List<ReturnModel> get returns => _returns;
  List<RefundModel> get refunds => _refunds;
  ReturnModel? get selectedReturn => _selectedReturn;
  RefundModel? get selectedRefund => _selectedRefund;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get statistics => _statistics;

  // Filter and search
  String _searchQuery = '';
  String _statusFilter = '';
  String _reasonFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;
  String get reasonFilter => _reasonFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // Computed properties
  List<ReturnModel> get filteredReturns {
    return _returns.where((returnItem) {
      bool matchesSearch =
          _searchQuery.isEmpty ||
              returnItem.returnNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              returnItem.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              returnItem.saleInvoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesStatus = _statusFilter.isEmpty || returnItem.status == _statusFilter;
      bool matchesReason = _reasonFilter.isEmpty || returnItem.reason == _reasonFilter;

      bool matchesDate = true;
      if (_startDate != null) {
        matchesDate = matchesDate && returnItem.returnDate.isAfter(_startDate!);
      }
      if (_endDate != null) {
        matchesDate = matchesDate && returnItem.returnDate.isBefore(_endDate!.add(Duration(days: 1)));
      }

      return matchesSearch && matchesStatus && matchesReason && matchesDate;
    }).toList();
  }

  List<ReturnModel> get pendingReturns => _returns.where((r) => r.status == 'PENDING').toList();
  List<ReturnModel> get approvedReturns => _returns.where((r) => r.status == 'APPROVED').toList();
  List<ReturnModel> get processedReturns => _returns.where((r) => r.status == 'PROCESSED').toList();

  List<RefundModel> get pendingRefunds => _refunds.where((r) => r.status == 'PENDING').toList();
  List<RefundModel> get processedRefunds => _refunds.where((r) => r.status == 'PROCESSED').toList();

  // Initialize provider
  Future<void> initialize() async {
    await Future.wait([loadReturns(), loadRefunds(), loadStatistics()]);
  }

  // Load returns
  Future<void> loadReturns({String? search, String? status, String? reason, DateTime? startDate, DateTime? endDate, int? page, int? pageSize}) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🔄 [ReturnProvider] Loading returns with filters: search="$search", status="$status", reason="$reason"');
      final response = await _returnService.getReturns(
        search: search,
        status: status,
        reason: reason,
        startDate: startDate,
        endDate: endDate,
        page: page,
        pageSize: pageSize,
      );

      if (response.success) {
        _returns = response.data!;
        debugPrint('✅ [ReturnProvider] Loaded ${_returns.length} returns');
        notifyListeners();
      } else {
        debugPrint('❌ [ReturnProvider] Failed to load returns: ${response.message}');
        _setError(response.message ?? 'Failed to load returns');
      }
    } catch (e) {
      debugPrint('❌ [ReturnProvider] Error loading returns: $e');
      _setError('Error loading returns: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load refunds
  Future<void> loadRefunds({String? search, String? status, String? method, DateTime? startDate, DateTime? endDate, int? page, int? pageSize}) async {
    _setLoading(true);
    _clearError();

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

      if (response.success) {
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

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      final response = await _returnService.getReturnStatistics();
      if (response.success) {
        _statistics = response.data;
        notifyListeners();
      }
    } catch (e) {
      // Don't set error for statistics, just log
      debugPrint('Error loading return statistics: $e');
    }
  }

  // Get return by ID
  Future<ReturnModel?> getReturn(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _returnService.getReturn(id);
      if (response.success) {
        _selectedReturn = response.data;
        notifyListeners();
        return response.data;
      } else {
        _setError(response.message ?? 'Failed to get return');
        return null;
      }
    } catch (e) {
      _setError('Error getting return: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get refund by ID
  Future<RefundModel?> getRefund(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _returnService.getRefund(id);
      if (response.success) {
        _selectedRefund = response.data;
        notifyListeners();
        return response.data;
      } else {
        _setError(response.message ?? 'Failed to get refund');
        return null;
      }
    } catch (e) {
      _setError('Error getting refund: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Create return
  Future<bool> createReturn({
    required String saleId,
    String? customerId, // ✅ FIXED: Changed from required String to String?
    required String reason,
    String? reasonDetails,
    String? notes,
    required List<Map<String, dynamic>> returnItems,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _returnService.createReturn(
        saleId: saleId,
        customerId: customerId, // Service will handle null
        reason: reason,
        reasonDetails: reasonDetails,
        notes: notes,
        returnItems: returnItems,
      );

      if (response.success) {
        _returns.insert(0, response.data!);
        await loadStatistics(); // Refresh statistics
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to create return');
        return false;
      }
    } catch (e) {
      _setError('Error creating return: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update return
  Future<bool> updateReturn({required String id, String? reason, String? reasonDetails, String? notes}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _returnService.updateReturn(id: id, reason: reason, reasonDetails: reasonDetails, notes: notes);

      if (response.success) {
        final index = _returns.indexWhere((r) => r.id == id);
        if (index != -1) {
          _returns[index] = response.data!;
          if (_selectedReturn?.id == id) {
            _selectedReturn = response.data;
          }
          notifyListeners();
        }
        return true;
      } else {
        _setError(response.message ?? 'Failed to update return');
        return false;
      }
    } catch (e) {
      _setError('Error updating return: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete return
  Future<bool> deleteReturn(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _returnService.deleteReturn(id);
      if (response.success) {
        _returns.removeWhere((r) => r.id == id);
        if (_selectedReturn?.id == id) {
          _selectedReturn = null;
        }
        await loadStatistics(); // Refresh statistics
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to delete return');
        return false;
      }
    } catch (e) {
      _setError('Error deleting return: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Approve return
  Future<bool> approveReturn({required String id, String? reason}) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('🔄 [ReturnProvider] Approving return $id with reason: $reason');
      final response = await _returnService.approveReturn(id: id, reason: reason);

      if (response.success) {
        debugPrint('✅ [ReturnProvider] Approve successful, reloading returns and refunds...');
        debugPrint('🔍 [ReturnProvider] Current filters: search="$_searchQuery", status="$_statusFilter", reason="$_reasonFilter"');
        // Reload returns to get updated data and ensure proper filtering
        await Future.wait([
          loadReturns(
            search: _searchQuery,
            status: _statusFilter,
            reason: _reasonFilter,
            startDate: _startDate,
            endDate: _endDate,
          ),
          loadRefunds() // Also reload refunds to show newly created refunds
        ]);
        debugPrint('✅ [ReturnProvider] Returns and refunds reloaded, returns count: ${_returns.length}, refunds count: ${_refunds.length}');
        return true;
      } else {
        debugPrint('❌ [ReturnProvider] Approve failed: ${response.message}');
        _setError(response.message ?? 'Failed to approve return');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [ReturnProvider] Approve error: $e');
      _setError('Error approving return: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reject return
  Future<bool> rejectReturn({required String id, required String reason}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _returnService.rejectReturn(id: id, reason: reason);

      if (response.success) {
        // Reload returns to get updated data and ensure proper filtering
        await loadReturns(
          search: _searchQuery,
          status: _statusFilter,
          reason: _reasonFilter,
          startDate: _startDate,
          endDate: _endDate,
        );
        return true;
      } else {
        _setError(response.message ?? 'Failed to reject return');
        return false;
      }
    } catch (e) {
      _setError('Error rejecting return: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Process return
  Future<bool> processReturn({required String id, double? refundAmount, String? refundMethod}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _returnService.processReturn(id: id, refundAmount: refundAmount, refundMethod: refundMethod);

      if (response.success) {
        // Reload returns and refunds to get updated data
        await Future.wait([
          loadReturns(
            search: _searchQuery,
            status: _statusFilter,
            reason: _reasonFilter,
            startDate: _startDate,
            endDate: _endDate,
          ),
          loadRefunds() // Also reload refunds to show updated status
        ]);
        return true;
      } else {
        _setError(response.message ?? 'Failed to process return');
        return false;
      }
    } catch (e) {
      _setError('Error processing return: $e');
      return false;
    } finally {
      _setLoading(false);
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
    _clearError();

    try {
      final response = await _returnService.createRefund(
        returnRequestId: returnRequestId,
        amount: amount,
        method: method,
        notes: notes,
        referenceNumber: referenceNumber,
      );

      if (response.success) {
        _refunds.insert(0, response.data!);
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
  Future<bool> updateRefund({required String id, String? method, String? notes, String? referenceNumber}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _returnService.updateRefund(id: id, method: method, notes: notes, referenceNumber: referenceNumber);

      if (response.success) {
        final index = _refunds.indexWhere((r) => r.id == id);
        if (index != -1) {
          _refunds[index] = response.data!;
          if (_selectedRefund?.id == id) {
            _selectedRefund = response.data;
          }
          notifyListeners();
        }
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
    _clearError();

    try {
      final response = await _returnService.deleteRefund(id);
      if (response.success) {
        _refunds.removeWhere((r) => r.id == id);
        if (_selectedRefund?.id == id) {
          _selectedRefund = null;
        }
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to delete refund');
        return false;
      }
    } catch (e) {
      _setError('Error deleting refund: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Process refund
  Future<bool> processRefund({required String id, String? referenceNumber, String? notes}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _returnService.processRefund(id: id, referenceNumber: referenceNumber, notes: notes);

      if (response.success) {
        final index = _refunds.indexWhere((r) => r.id == id);
        if (index != -1) {
          _refunds[index] = response.data!;
          if (_selectedRefund?.id == id) {
            _selectedRefund = response.data;
          }
          notifyListeners();
        }
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
  Future<bool> failRefund({required String id, String? notes}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _returnService.failRefund(id: id, notes: notes);

      if (response.success) {
        final index = _refunds.indexWhere((r) => r.id == id);
        if (index != -1) {
          _refunds[index] = response.data!;
          if (_selectedRefund?.id == id) {
            _selectedRefund = response.data;
          }
          notifyListeners();
        }
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
  Future<bool> cancelRefund({required String id, String? notes}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _returnService.cancelRefund(id: id, notes: notes);

      if (response.success) {
        final index = _refunds.indexWhere((r) => r.id == id);
        if (index != -1) {
          _refunds[index] = response.data!;
          if (_selectedRefund?.id == id) {
            _selectedRefund = response.data;
          }
          notifyListeners();
        }
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

  // Get customer return history
  Future<Map<String, dynamic>?> getCustomerReturnHistory(String customerId) async {
    try {
      final response = await _returnService.getCustomerReturnHistory(customerId);
      if (response.success) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting customer return history: $e');
      return null;
    }
  }

  // Get sale return details
  Future<Map<String, dynamic>?> getSaleReturnDetails(String saleId) async {
    try {
      final response = await _returnService.getSaleReturnDetails(saleId);
      if (response.success) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting sale return details: $e');
      return null;
    }
  }

  // Set filters
  void setFilters({String? search, String? status, String? reason, DateTime? startDate, DateTime? endDate}) {
    _searchQuery = search ?? _searchQuery;
    _statusFilter = status ?? _statusFilter;
    _reasonFilter = reason ?? _reasonFilter;
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _statusFilter = '';
    _reasonFilter = '';
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  // Select return
  void selectReturn(ReturnModel? returnItem) {
    _selectedReturn = returnItem;
    notifyListeners();
  }

  // Select refund
  void selectRefund(RefundModel? refund) {
    _selectedRefund = refund;
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedReturn = null;
    _selectedRefund = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    await Future.wait([loadReturns(), loadRefunds(), loadStatistics()]);
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Dispose
  @override
  void dispose() {
    super.dispose();
  }
}