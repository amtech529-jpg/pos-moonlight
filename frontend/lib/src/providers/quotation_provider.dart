import 'dart:async';
import 'package:flutter/material.dart';
import '../models/quotation/quotation_model.dart';
import '../services/quotation_service.dart';

class QuotationProvider extends ChangeNotifier {
  final QuotationService _service = QuotationService();
  
  List<QuotationModel> _quotations = [];
  bool _isLoading = false;
  bool _hasMore = false;
  int _currentPage = 1;
  String _searchQuery = '';
  String? _error;
  Timer? _searchTimer;

  List<QuotationModel> get quotations => _quotations;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String get searchQuery => _searchQuery;
  String? get error => _error;

  Future<void> initialize() async {
    _currentPage = 1;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _service.getQuotations(page: 1, pageSize: 100, search: _searchQuery);
    if (response.success) {
      _quotations = response.data ?? [];
      _hasMore = _quotations.length >= 100; 
    } else {
      _error = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    
    _isLoading = true;
    notifyListeners();
    
    _currentPage++;
    final response = await _service.getQuotations(page: _currentPage, pageSize: 100, search: _searchQuery); 
    
    if (response.success && response.data != null) {
      if (response.data!.isEmpty) {
        _hasMore = false;
      } else {
        _quotations.addAll(response.data!);
        _hasMore = response.data!.length >= 100;
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addQuotation(QuotationModel quotation) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _service.createQuotation(quotation);
    if (response.success) {
      _quotations.insert(0, response.data!);
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateQuotation(String id, QuotationModel quotation) async {
    _isLoading = true;
    notifyListeners();

    final response = await _service.updateQuotation(id, quotation);
    if (response.success) {
      final index = _quotations.indexWhere((q) => q.id == id);
      if (index != -1) {
        _quotations[index] = response.data!;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteQuotation(String id) async {
    final response = await _service.deleteQuotation(id);
    if (response.success) {
      _quotations.removeWhere((q) => q.id == id);
      notifyListeners();
      return true;
    } else {
      _error = response.message;
      return false;
    }
  }

  Future<Map<String, dynamic>?> convertToOrder(String id) async {
    _isLoading = true;
    notifyListeners();

    final response = await _service.convertToOrder(id);
    _isLoading = false;
    
    if (response.success) {
      // Refresh list to show updated status
      initialize();
      return response.data;
    } else {
      _error = response.message;
      notifyListeners();
      return null;
    }
  }

  void searchQuotations(String query) {
    _searchQuery = query;
    _currentPage = 1;

    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      initialize();
    });
  }
}
