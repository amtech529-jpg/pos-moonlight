import 'package:flutter/material.dart';
import '../models/purchase_model.dart';
import '../services/purchase_service.dart';
import '../utils/debug_helper.dart';

class PurchaseProvider with ChangeNotifier {
  final PurchaseService _purchaseService = PurchaseService();

  List<PurchaseModel> _purchases = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<PurchaseModel> get purchases => _purchases;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize the provider and fetch data
  Future<void> initialize() async {
    await fetchPurchases();
  }

  /// Fetch all purchases from the service
  Future<void> fetchPurchases() async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _purchaseService.getPurchases();

      if (response.success && response.data != null) {
        _purchases = response.data!;
      } else {
        _error = response.message;
        DebugHelper.printError('Failed to fetch purchases', _error);
      }
    } catch (e) {
      _error = e.toString();
      DebugHelper.printError('PurchaseProvider fetch error', e);
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new purchase
  Future<bool> addPurchase(PurchaseModel purchase) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _purchaseService.createPurchase(purchase);

      if (response.success && response.data != null) {
        // Add to the local list at the top and notify UI
        _purchases.insert(0, response.data!);
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing purchase
  Future<bool> updatePurchase(PurchaseModel purchase) async {
    _setLoading(true);
    _error = null;

    try {
      if (purchase.id == null) {
        _error = "Update failed: Missing purchase ID";
        notifyListeners();
        return false;
      }

      final response = await _purchaseService.updatePurchase(purchase.id!, purchase);

      if (response.success && response.data != null) {
        final index = _purchases.indexWhere((p) => p.id == purchase.id);
        if (index != -1) {
          _purchases[index] = response.data!;
        }
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      DebugHelper.printError('PurchaseProvider update error', e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a purchase record
  Future<bool> deletePurchase(String id) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _purchaseService.deletePurchase(id);

      if (response.success) {
        _purchases.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}