import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../services/inventory_service.dart';
import '../utils/debug_helper.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryService _inventoryService = InventoryService();

  // State variables
  bool _isLoading = false;
  List<Map<String, dynamic>> _stockInfo = [];
  List<Map<String, dynamic>> _lowStockAlerts = [];
  Map<String, dynamic>? _lastStockCheck;
  String? _lastError;

  // Getters
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get stockInfo => _stockInfo;
  List<Map<String, dynamic>> get lowStockAlerts => _lowStockAlerts;
  Map<String, dynamic>? get lastStockCheck => _lastStockCheck;
  String? get lastError => _lastError;

  // Check real-time stock availability
  Future<bool> checkStockAvailability(List<String> productIds) async {
    if (productIds.isEmpty) return false;

    _setLoading(true);
    _clearError();

    try {
      final response = await _inventoryService.checkStockAvailability(productIds: productIds);

      if (response.success && response.data != null) {
        _stockInfo = response.data!;
        _lastStockCheck = {'timestamp': DateTime.now().toIso8601String(), 'product_count': productIds.length, 'stock_info': _stockInfo};
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      DebugHelper.printError('Check stock availability in provider', e);
      _setError('Failed to check stock availability: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reserve stock for a pending sale
  Future<bool> reserveStockForSale({required String productId, required int quantity, required String saleId, int reservationDuration = 30}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _inventoryService.reserveStockForSale(
        productId: productId,
        quantity: quantity,
        saleId: saleId,
        reservationDuration: reservationDuration,
      );

      if (response.success && response.data != null) {
        // Update local stock info if available
        _updateLocalStockInfo(productId, response.data!);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      DebugHelper.printError('Reserve stock in provider', e);
      _setError('Failed to reserve stock: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Confirm stock deduction after sale confirmation
  Future<bool> confirmStockDeduction(String saleId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _inventoryService.confirmStockDeduction(saleId: saleId);

      if (response.success && response.data != null) {
        // Update local stock info based on deduction results
        final deductions = response.data!['deductions'] as List?;
        if (deductions != null) {
          for (final deduction in deductions) {
            if (deduction is Map<String, dynamic>) {
              final productId = deduction['product_id'] as String?;
              if (productId != null) {
                _updateLocalStockInfo(productId, {
                  'quantity': deduction['new_quantity'],
                  'stock_status': deduction['stock_status'],
                  'low_stock_warning': deduction['low_stock_warning'],
                });
              }
            }
          }
        }
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      DebugHelper.printError('Confirm stock deduction in provider', e);
      _setError('Failed to confirm stock deduction: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get low stock alerts
  Future<bool> getLowStockAlerts({int threshold = 5, bool includeOutOfStock = true}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _inventoryService.getLowStockAlerts(threshold: threshold, includeOutOfStock: includeOutOfStock);

      if (response.success && response.data != null) {
        final alerts = response.data!['alerts'] as List?;
        if (alerts != null) {
          _lowStockAlerts = List<Map<String, dynamic>>.from(alerts);
        } else {
          _lowStockAlerts = [];
        }
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      DebugHelper.printError('Get low stock alerts in provider', e);
      _setError('Failed to get low stock alerts: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Bulk update stock quantities
  Future<bool> bulkUpdateStock(List<Map<String, dynamic>> updates) async {
    if (updates.isEmpty) return false;

    _setLoading(true);
    _clearError();

    try {
      final response = await _inventoryService.bulkUpdateStock(updates: updates);

      if (response.success && response.data != null) {
        // Update local stock info based on successful updates
        final successfulUpdates = response.data!['successful_updates'] as List?;
        if (successfulUpdates != null) {
          for (final update in successfulUpdates) {
            if (update is Map<String, dynamic>) {
              final productId = update['product_id'] as String?;
              if (productId != null) {
                _updateLocalStockInfo(productId, {
                  'quantity': update['new_quantity'],
                  'stock_status': update['stock_status'],
                  'low_stock_warning': update['low_stock_warning'],
                });
              }
            }
          }
        }
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      DebugHelper.printError('Bulk update stock in provider', e);
      _setError('Failed to perform bulk stock update: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get stock info for a specific product
  Map<String, dynamic>? getProductStockInfo(String productId) {
    try {
      return _stockInfo.firstWhere((info) => info['product_id'] == productId, orElse: () => {});
    } catch (e) {
      return null;
    }
  }

  // Check if product can fulfill requested quantity
  bool canFulfillQuantity(String productId, int requestedQuantity) {
    final stockInfo = getProductStockInfo(productId);
    if (stockInfo == null) return false;

    final availableQuantity = stockInfo['available_quantity'] as int? ?? 0;
    return availableQuantity >= requestedQuantity;
  }

  // Get stock status for a product
  String getProductStockStatus(String productId) {
    final stockInfo = getProductStockInfo(productId);
    if (stockInfo == null) return 'UNKNOWN';

    return stockInfo['stock_status'] as String? ?? 'UNKNOWN';
  }

  // Get low stock alert count
  int getLowStockAlertCount() {
    return _lowStockAlerts.length;
  }

  // Get critical stock alert count
  int getCriticalStockAlertCount() {
    return _lowStockAlerts.where((alert) => alert['alert_level'] == 'CRITICAL').length;
  }

  // Get warning stock alert count
  int getWarningStockAlertCount() {
    return _lowStockAlerts.where((alert) => alert['alert_level'] == 'WARNING').length;
  }

  // Check if product has low stock warning
  bool hasLowStockWarning(String productId) {
    final stockInfo = getProductStockInfo(productId);
    if (stockInfo == null) return false;

    return stockInfo['low_stock_warning'] as bool? ?? false;
  }

  // Check if product is out of stock
  bool isOutOfStock(String productId) {
    final stockInfo = getProductStockInfo(productId);
    if (stockInfo == null) return false;

    return stockInfo['out_of_stock'] as bool? ?? false;
  }

  // Get available quantity for a product
  int getAvailableQuantity(String productId) {
    final stockInfo = getProductStockInfo(productId);
    if (stockInfo == null) return 0;

    return stockInfo['available_quantity'] as int? ?? 0;
  }

  // Update local stock info
  void _updateLocalStockInfo(String productId, Map<String, dynamic> newInfo) {
    final index = _stockInfo.indexWhere((info) => info['product_id'] == productId);

    if (index != -1) {
      _stockInfo[index].addAll(newInfo);
    } else {
      _stockInfo.add({'product_id': productId, ...newInfo});
    }
  }

  // Clear stock info
  void clearStockInfo() {
    _stockInfo.clear();
    _lastStockCheck = null;
    notifyListeners();
  }

  // Clear low stock alerts
  void clearLowStockAlerts() {
    _lowStockAlerts.clear();
    notifyListeners();
  }

  // Refresh all inventory data
  Future<void> refreshInventoryData() async {
    // Clear existing data
    clearStockInfo();
    clearLowStockAlerts();

    // Reload low stock alerts
    await getLowStockAlerts();
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }

  void _clearError() {
    _lastError = null;
  }

  // Dispose method
  @override
  void dispose() {
    clearStockInfo();
    clearLowStockAlerts();
    super.dispose();
  }
}
