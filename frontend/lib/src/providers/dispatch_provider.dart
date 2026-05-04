import 'package:flutter/material.dart';
import 'package:frontend/src/models/dispatch/dispatch_form_model.dart';
import 'package:frontend/src/services/dispatch_service.dart';

class DispatchProvider with ChangeNotifier {
  final DispatchService _dispatchService = DispatchService();

  List<DispatchFormModel> _forms = [];
  bool _isLoading = false;
  String? _error;

  List<DispatchFormModel> get forms => _forms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDispatchForms({String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dispatchService.getDispatchForms(search: search);

      if (response.success && response.data != null) {
        _forms = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<DispatchFormModel?> createDispatchForm(DispatchFormModel form) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _dispatchService.createDispatchForm(form);

    _isLoading = false;
    if (response.success && response.data != null) {
      _forms.insert(0, response.data!);
      notifyListeners();
      return response.data;
    } else {
      _error = response.message;
      notifyListeners();
      return null;
    }
  }

  Future<DispatchFormModel?> getDispatchFormDetails(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _dispatchService.getDispatchForm(id);

    _isLoading = false;
    notifyListeners();

    if (response.success && response.data != null) {
      return response.data;
    } else {
      _error = response.message;
      return null;
    }
  }

  Future<bool> updateDispatchForm(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _dispatchService.updateDispatchForm(id, data);

    _isLoading = false;
    if (response.success && response.data != null) {
      final index = _forms.indexWhere((f) => f.id == id);
      if (index != -1) {
        _forms[index] = response.data!;
      }
      notifyListeners();
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDispatchForm(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await _dispatchService.deleteDispatchForm(id);

    _isLoading = false;
    if (response.success) {
      _forms.removeWhere((f) => f.id == id);
      notifyListeners();
      return true;
    } else {
      _error = response.message;
      notifyListeners();
      return false;
    }
  }
}
