import 'package:flutter/material.dart';
import '../models/rental_return_model.dart';
import '../models/api_response.dart';
import '../services/rental_return_service.dart';

class RentalReturnProvider extends ChangeNotifier {
  final RentalReturnService _service = RentalReturnService();
  
  List<RentalReturnModel> _returns = [];
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  Map<String, dynamic>? _apiStats;
  
  List<RentalReturnModel> get returns => _returns;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  
  Map<String, String> get stats {
    // Determine source data
    int partnerReturnsCount = _returns.where((r) => r.items.any((i) => i.isPartnerItem)).length;
    int damagedItems = _returns.fold(0, (sum, r) => sum + r.totalDamaged);
    double damageCost = _returns.fold(0, (sum, r) => sum + r.damageCharges);
    double totalRecovered = _returns.fold(0, (sum, r) => sum + r.damageRecovered);
    int pendingClaimsCount = _returns.where((r) => r.status == 'PENDING').length;

    // Override with API stats if available
    if (_apiStats != null) {
      partnerReturnsCount = _apiStats!['partner_returns_count'] ?? partnerReturnsCount;
      damagedItems = _apiStats!['total_items_damaged'] ?? damagedItems;
      damageCost = (_apiStats!['total_damage_charges'] as num?)?.toDouble() ?? damageCost;
      totalRecovered = (_apiStats!['total_recovered'] as num?)?.toDouble() ?? totalRecovered;
      pendingClaimsCount = _apiStats!['pending'] ?? pendingClaimsCount;
    }

    return {
      'partner_returns': partnerReturnsCount.toString(),
      'damage_items': damagedItems.toString(),
      'damage_cost': 'Rs. ${damageCost.toStringAsFixed(0)}',
      'pending_claims': pendingClaimsCount.toString(),
      'successful_recoveries': 'Rs. ${totalRecovered.toStringAsFixed(0)}',
    };
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadReturns({
    String? search, 
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    final response = await _service.getReturns(
      search: search, 
      status: status,
      startDate: startDate,
      endDate: endDate,
    );
    
    if (response.success) {
      _returns = response.data ?? [];
    } else {
      _error = response.message;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// Load statistics from the API
  Future<void> loadStatistics() async {
    final response = await _service.getStatistics();
    if (response.success && response.data != null) {
      _apiStats = response.data!;
      notifyListeners();
    }
  }

  /// Create a new return
  Future<bool> createReturn({
    required String orderId,
    required String responsibility,
    required double damageCharges,
    String? notes,
    required List<Map<String, dynamic>> items,
    bool restoreStock = true,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _service.createReturn(
      orderId: orderId,
      responsibility: responsibility,
      damageCharges: damageCharges,
      notes: notes,
      items: items,
      restoreStock: restoreStock,
    );

    _isLoading = false;
    if (response.success) {
      _successMessage = 'Return created successfully';
      await loadReturns(); // refresh list
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }

  /// Submit tally for a rental return
  Future<bool> tallyReturn({
    required String returnId,
    required List<Map<String, dynamic>> items,
    double? damageCharges,
    String? responsibility,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _service.tallyReturn(
      returnId: returnId,
      items: items,
      damageCharges: damageCharges,
      responsibility: responsibility,
      notes: notes,
    );

    _isLoading = false;
    if (response.success) {
      _successMessage = response.message ?? 'Tally updated successfully';
      await loadReturns(); // refresh list
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }

  /// Restore stock from returned items
  Future<bool> restoreStock({required String returnId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _service.restoreStock(returnId: returnId);

    _isLoading = false;
    if (response.success) {
      _successMessage = response.message ?? 'Stock restored successfully';
      await loadReturns(); // refresh list
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }

  /// Add damage recovery payment
  Future<bool> addDamageRecovery({
    required String returnId,
    required double amount,
    required String recoveryType,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _service.addDamageRecovery(
      returnId: returnId,
      amount: amount,
      recoveryType: recoveryType,
      notes: notes,
    );

    _isLoading = false;
    if (response.success) {
      _successMessage = response.message ?? 'Damage recovery added';
      await loadReturns(); // refresh
      await loadStatistics();
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }

  /// Delete a rental return
  Future<bool> deleteReturn({required String returnId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _service.deleteReturn(returnId: returnId);

    _isLoading = false;
    if (response.success) {
      _returns.removeWhere((r) => r.id == returnId);
      _successMessage = 'Return deleted successfully';
      notifyListeners();
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }
}
