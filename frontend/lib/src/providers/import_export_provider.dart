import 'package:flutter/material.dart';
import '../services/import_export_service.dart';
import './product_provider.dart'; // Keep for signature compatibility if needed, but not used now
import './customer_provider.dart';

class ImportExportProvider extends ChangeNotifier {
  final ImportExportService _importExportService = ImportExportService();

  bool _isImportingInventory = false;
  bool _isImportingCustomers = false;
  bool _isExportingInventory = false;
  bool _isExportingCustomers = false;
  String? _message;
  
  final List<Map<String, String>> _importHistory = [];

  bool get isImportingInventory => _isImportingInventory;
  bool get isImportingCustomers => _isImportingCustomers;
  bool get isExportingInventory => _isExportingInventory;
  bool get isExportingCustomers => _isExportingCustomers;
  String? get message => _message;
  List<Map<String, String>> get importHistory => _importHistory;

  void clearMessage() {
    if (_message != null) {
      _message = null;
      notifyListeners();
    }
  }

  // Template Downloads
  Future<void> downloadInventoryTemplate() async {
    try {
      await _importExportService.downloadTemplate('products');
      _message = "Template downloaded successfully";
    } catch (e) {
      _message = "Failed to download template: $e";
    } finally {
      notifyListeners();
    }
  }

  Future<void> downloadCustomerTemplate() async {
     try {
      await _importExportService.downloadTemplate('customers');
      _message = "Template downloaded successfully";
    } catch (e) {
      _message = "Failed to download template: $e";
    } finally {
      notifyListeners();
    }
  }

  // Export
  Future<void> exportAllInventory() async {
    _isExportingInventory = true;
    notifyListeners();
    try {
      await _importExportService.exportData('products');
      _message = "Inventory exported successfully";
    } catch (e) {
      _message = "Export error: $e";
    } finally {
      _isExportingInventory = false;
      notifyListeners();
    }
  }

  Future<void> exportAllCustomers() async {
    _isExportingCustomers = true;
    notifyListeners();
    try {
      await _importExportService.exportData('customers');
      _message = "Customers exported successfully";
    } catch (e) {
      _message = "Export error: $e";
    } finally {
      _isExportingCustomers = false;
      notifyListeners();
    }
  }

  // Import
  Future<void> importInventory(ProductProvider productProvider) async {
    _isImportingInventory = true;
    notifyListeners();
    try {
      final result = await _importExportService.importData('products');
      if (result['cancelled'] == true) {
        _message = "Import cancelled";
      } else {
        int imported = result['imported_count'] ?? 0;
        List errors = result['errors'] ?? [];
        if (errors.isNotEmpty) {
           _message = "Imported $imported items with ${errors.length} errors";
        } else {
           _message = "Successfully imported $imported items";
        }
        
        // Add to history
        _addHistoryRecord(result['file_name'] ?? 'Inventory Upload', imported);
        
        // Refresh products
        await productProvider.loadProducts(page: 1); // Refresh list
      }
    } catch (e) {
      _message = "Import error: $e";
    } finally {
      _isImportingInventory = false;
      notifyListeners();
    }
  }

  Future<void> importCustomers(CustomerProvider customerProvider) async {
    _isImportingCustomers = true;
    notifyListeners();
    try {
      final result = await _importExportService.importData('customers');
      if (result['cancelled'] == true) {
        _message = "Import cancelled";
      } else {
        int imported = result['imported_count'] ?? 0;
        List errors = result['errors'] ?? [];
        if (errors.isNotEmpty) {
           _message = "Imported $imported items with ${errors.length} errors";
        } else {
           _message = "Successfully imported $imported items";
        }
        
        // Add to history
        _addHistoryRecord(result['file_name'] ?? 'Customer Upload', imported);
        
        // Refresh customers
        await customerProvider.loadCustomers(); // Refresh list
      }
    } catch (e) {
      _message = "Import error: $e";
    } finally {
      _isImportingCustomers = false;
      notifyListeners();
    }
  }

  void _addHistoryRecord(String fileName, int count) {
    if (count > 0) {
      _importHistory.insert(0, {
        'fileName': fileName,
        'count': '$count Item${count > 1 ? 's' : ''}'
      });
      if (_importHistory.length > 5) {
        _importHistory.removeLast();
      }
    }
  }
}
