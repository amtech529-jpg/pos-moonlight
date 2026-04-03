import 'package:flutter/foundation.dart';
import '../models/sales/sale_model.dart';
import '../services/receipt_service.dart';
import '../utils/debug_helper.dart';

class ReceiptProvider extends ChangeNotifier {
  final ReceiptService _receiptService = ReceiptService();

  // State variables
  List<ReceiptModel> _receipts = [];
  bool _isLoading = false;
  String? _error;
  String? _success;
  Map<String, dynamic>? _pagination;

  // Filter state
  String? _selectedSaleId;
  String? _selectedPaymentId;
  String? _selectedStatus;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _showInactive = false;

  // Getters
  List<ReceiptModel> get receipts => _receipts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get success => _success;
  Map<String, dynamic>? get pagination => _pagination;

  // Filter getters
  String? get selectedSaleId => _selectedSaleId;
  String? get selectedPaymentId => _selectedPaymentId;
  String? get selectedStatus => _selectedStatus;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  bool get showInactive => _showInactive;

  // Computed properties
  List<ReceiptModel> get generatedReceipts => _receipts.where((receipt) => receipt.status == 'GENERATED').toList();
  List<ReceiptModel> get sentReceipts => _receipts.where((receipt) => receipt.status == 'SENT').toList();
  List<ReceiptModel> get viewedReceipts => _receipts.where((receipt) => receipt.status == 'VIEWED').toList();
  int get totalReceipts => _receipts.length;
  int get unviewedCount => _receipts.where((receipt) => receipt.status != 'VIEWED').length;

  /// Load receipts with current filters
  Future<void> loadReceipts({bool refresh = false, int? page, int? pageSize}) async {
    debugPrint('🔍 [ReceiptProvider] loadReceipts called: refresh=$refresh, current receipts count=${_receipts.length}');
    debugPrint('🔍 [ReceiptProvider] Filters: saleId=$_selectedSaleId, paymentId=$_selectedPaymentId, status=$_selectedStatus');
    
    if (!refresh && _receipts.isNotEmpty) {
      debugPrint('🔍 [ReceiptProvider] Skipping load - not refresh and receipts not empty');
      return;
    }

    _setLoading(true);
    _clearMessages();

    try {
      debugPrint('🔍 [ReceiptProvider] Calling receipt service...');
      final response = await _receiptService.listReceipts(
        saleId: _selectedSaleId,
        paymentId: _selectedPaymentId,
        status: _selectedStatus,
        dateFrom: _dateFrom?.toIso8601String(),
        dateTo: _dateTo?.toIso8601String(),
        showInactive: _showInactive,
        page: page,
        pageSize: pageSize,
      );
      
      debugPrint('🔍 [ReceiptProvider] Service response: success=${response.success}, data=${response.data != null ? "present" : "null"}');

      if (response.success && response.data != null) {
        // ✅ FIXED: The Service already returns List<ReceiptModel>, so we just assign it.
        _receipts = response.data!;
        debugPrint('🔍 [ReceiptProvider] Loaded ${_receipts.length} receipts');

        // Note: Since we are getting a direct List, we assume standard pagination handling is done
        // or we nullify pagination map for now to prevent the crash.
        _pagination = null;

        _setSuccess('Receipts loaded successfully');
      } else {
        _setError(response.message);
      }
    } catch (e) {
      DebugHelper.printError('Load receipts in provider', e);
      _setError('Failed to load receipts: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a simple receipt directly from sale (for sales with amount_paid > 0)
  Future<bool> createSimpleReceipt({
    required String saleId,
    String? notes,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _receiptService.createSimpleReceipt(
        saleId: saleId,
        notes: notes,
      );

      if (response.success && response.data != null) {
        _receipts.insert(0, response.data!);
        _success = response.message;
        notifyListeners();
        
        // Auto-generate PDF after successful receipt creation
        await generateReceiptPdf(response.data!.id);
        
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to create simple receipt: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Generate PDF for a receipt
  Future<bool> generateReceiptPdf(String receiptId) async {
    try {
      final response = await _receiptService.generateReceiptPdf(receiptId);
      
      if (response.success) {
        debugPrint('✅ Receipt PDF generated successfully');
        return true;
      } else {
        debugPrint('❌ Failed to generate receipt PDF: ${response.message}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error generating receipt PDF: ${e.toString()}');
      return false;
    }
  }

  /// Create a new receipt
  Future<bool> createReceipt({
    required String saleId,
    required String paymentId,
    String? notes,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _receiptService.createReceipt(
        saleId: saleId,
        paymentId: paymentId,
        notes: notes,
      );

      if (response.success && response.data != null) {
        _receipts.insert(0, response.data!);
        _success = response.message;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to create receipt: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update receipt
  Future<bool> updateReceipt({required String id, String? notes, String? status}) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _receiptService.updateReceipt(id: id, notes: notes, status: status);

      if (response.success && response.data != null) {
        final index = _receipts.indexWhere((receipt) => receipt.id == id);
        if (index != -1) {
          _receipts[index] = response.data!;
          _setSuccess('Receipt updated successfully');
          notifyListeners();
          return true;
        }
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      DebugHelper.printError('Update receipt in provider', e);
      _setError('Failed to update receipt: $e');
      return false;
    } finally {
      _setLoading(false);
    }
    return false;
  }

  /// Get receipt by ID
  ReceiptModel? getReceiptById(String id) {
    try {
      return _receipts.firstWhere((receipt) => receipt.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get receipts by sale ID
  List<ReceiptModel> getReceiptsBySale(String saleId) {
    return _receipts.where((receipt) => receipt.saleId == saleId).toList();
  }

  /// Get receipts by payment ID
  List<ReceiptModel> getReceiptsByPayment(String paymentId) {
    return _receipts.where((receipt) => receipt.paymentId == paymentId).toList();
  }

  /// Delete a receipt
  Future<bool> deleteReceipt(String id) async {
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _receiptService.deleteReceipt(id);

      if (response.success) {
        _receipts.removeWhere((receipt) => receipt.id == id);
        _setSuccess('Receipt deleted successfully');
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      DebugHelper.printError('Delete receipt in provider', e);
      _setError('Failed to delete receipt: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Filter receipts by sale
  void filterBySale(String? saleId) {
    _selectedSaleId = saleId;
    loadReceipts(refresh: true);
  }

  /// Filter receipts by payment
  void filterByPayment(String? paymentId) {
    _selectedPaymentId = paymentId;
    loadReceipts(refresh: true);
  }

  /// Filter receipts by status
  void filterByStatus(String? status) {
    _selectedStatus = status;
    loadReceipts(refresh: true);
  }

  /// Filter receipts by date range
  void filterByDateRange(DateTime? from, DateTime? to) {
    _dateFrom = from;
    _dateTo = to;
    loadReceipts(refresh: true);
  }

  /// Toggle inactive receipts
  void toggleInactive(bool showInactive) {
    _showInactive = showInactive;
    loadReceipts(refresh: true);
  }

  /// Clear all filters
  void clearFilters() {
    debugPrint('🔍 [ReceiptProvider] Clearing filters...');
    _selectedSaleId = null;
    _selectedPaymentId = null;
    _selectedStatus = null;
    _dateFrom = null;
    _dateTo = null;
    _showInactive = false;
    debugPrint('🔍 [ReceiptProvider] Filters cleared, reloading receipts...');
    loadReceipts(refresh: true);
  }

  /// Set filters for search and status
  void setFilters({String? search, String? status}) {
    if (search != null) {
      // Implement search logic if needed
      // For now, just reload receipts
    }
    if (status != null) {
      _selectedStatus = status;
    }
    loadReceipts(refresh: true);
  }

  /// Initialize the provider
  Future<void> initialize() async {
    await loadReceipts();
  }

  /// Get filtered receipts based on current filters
  List<ReceiptModel> get filteredReceipts {
    List<ReceiptModel> filtered = _receipts;

    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      filtered = filtered.where((receipt) => receipt.status == _selectedStatus).toList();
    }

    return filtered;
  }

  /// Refresh receipts
  Future<void> refresh() async {
    await loadReceipts(refresh: true);
  }

  // Private helper methods
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