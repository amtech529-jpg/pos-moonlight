import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/invoice_service.dart';
import '../models/sales/sale_model.dart';
import '../utils/debug_helper.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceService _invoiceService = InvoiceService();

  // State variables
  List<InvoiceModel> _invoices = [];
  bool _isLoading = false;
  String? _error;
  String? _success;
  Map<String, dynamic>? _thermalPrintData;

  // Filter state
  String _searchQuery = '';
  Timer? _searchTimer;
  String? _selectedStatus;
  String? _selectedCustomerId;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _showInactive = false;

  // Getters
  List<InvoiceModel> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get success => _success;
  Map<String, dynamic>? get thermalPrintData => _thermalPrintData;

  // Client-Side Filtering
  List<InvoiceModel> get filteredInvoices => _invoices;

  /// Initialize the provider
  Future<void> initialize() async {
    await loadInvoices();
  }

  /// Load invoices from API
  Future<void> loadInvoices({bool refresh = false}) async {
    if (!refresh && _invoices.isNotEmpty) {
      debugPrint('🔍 [InvoiceProvider] Skipping load - already have ${_invoices.length} invoices');
      return;
    }

    debugPrint('🔍 [InvoiceProvider] Starting to load invoices (refresh: $refresh)');
    _setLoading(true);
    _clearMessages();

    try {
      final response = await _invoiceService.listInvoices(
        status: _selectedStatus,
        customerId: _selectedCustomerId,
        dateFrom: _dateFrom?.toIso8601String(),
        dateTo: _dateTo?.toIso8601String(),
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        showInactive: _showInactive,
      );

      debugPrint('🔍 [InvoiceProvider] API Response success: ${response.success}');
      debugPrint('🔍 [InvoiceProvider] API Response message: ${response.message}');

      if (response.success && response.data != null) {
        _invoices = response.data!;
        debugPrint('🔍 [InvoiceProvider] Loaded ${_invoices.length} invoices');
        notifyListeners();
      } else {
        debugPrint('❌ [InvoiceProvider] API Error: ${response.message}');
        _setError(response.message);
      }
    } catch (e) {
      DebugHelper.printError('Load invoices in provider', e);
      debugPrint('❌ [InvoiceProvider] Exception: $e');
      _setError('Failed to load invoices: $e');
    } finally {
      _setLoading(false);
      debugPrint('🔍 [InvoiceProvider] Load completed, loading: $_isLoading');
    }
  }

  Future<void> refresh() async {
    await loadInvoices(refresh: true);
  }

  void setFilters({String? search, String? status, String? customerId}) {
    bool changed = false;

    if (search != null) {
      _searchQuery = search;
      changed = true;
    }

    if (status != null) {
      _selectedStatus = status.isEmpty ? null : status;
      changed = true;
    }

    if (customerId != null) {
      _selectedCustomerId = customerId.isEmpty ? null : customerId;
      changed = true;
    }

    if (changed) {
      if (status != null || customerId != null) {
        loadInvoices(refresh: true);
      } else if (search != null) {
        // Debounce search
        _searchTimer?.cancel();
        _searchTimer = Timer(const Duration(milliseconds: 500), () {
          loadInvoices(refresh: true);
        });
      } else {
        notifyListeners();
      }
    }
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedStatus = null;
    _selectedCustomerId = null;
    _dateFrom = null;
    _dateTo = null;
    loadInvoices(refresh: true);
  }

  // --- CRUD Operations ---

  Future<bool> createInvoice({required String saleId, String? notes, DateTime? dueDate}) async {
    _setLoading(true);
    try {
      debugPrint('🔍 [InvoiceProvider] Creating invoice for sale: $saleId');
      debugPrint('🔍 [InvoiceProvider] Due date: $dueDate');
      debugPrint('🔍 [InvoiceProvider] Notes: $notes');
      
      final response = await _invoiceService.createInvoice(saleId: saleId, notes: notes, dueDate: dueDate);
      
      debugPrint('🔍 [InvoiceProvider] Create invoice response success: ${response.success}');
      debugPrint('🔍 [InvoiceProvider] Create invoice response message: ${response.message}');
      
      if (response.success && response.data != null) {
        final newInvoice = response.data!;
        _invoices.insert(0, newInvoice);
        _setSuccess('Invoice created successfully');
        notifyListeners();
        debugPrint('✅ [InvoiceProvider] Invoice created and added to list');
        return true;
      } else {
        debugPrint('❌ [InvoiceProvider] Create invoice failed: ${response.message}');
        _setError(response.message);
        return false;
      }
    } catch (e) {
      debugPrint('❌ [InvoiceProvider] Exception creating invoice: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ Added updateInvoice method here
  Future<bool> updateInvoice({required String id, String? notes, String? status, DateTime? dueDate, double? writeOffAmount}) async {
    _setLoading(true);
    try {
      debugPrint('🔍 [InvoiceProvider] Updating invoice: $id');
      debugPrint('🔍 [InvoiceProvider] Status: $status');
      debugPrint('🔍 [InvoiceProvider] Due date: $dueDate');
      debugPrint('🔍 [InvoiceProvider] Notes: $notes');
      
      final response = await _invoiceService.updateInvoice(
          id: id,
          notes: notes,
          status: status,
          dueDate: dueDate,
          writeOffAmount: writeOffAmount
      );

      debugPrint('🔍 [InvoiceProvider] Update invoice response success: ${response.success}');
      debugPrint('🔍 [InvoiceProvider] Update invoice response message: ${response.message}');

      if (response.success && response.data != null) {
        final index = _invoices.indexWhere((i) => i.id == id);
        if (index != -1) {
          var updatedInvoice = response.data!;
          
          // Allow backend-provided payment details to be used
          
          _invoices[index] = updatedInvoice;
          _setSuccess('Invoice updated successfully');
          notifyListeners();
          debugPrint('✅ [InvoiceProvider] Invoice updated in list');
        }
        return true;
      } else {
        debugPrint('❌ [InvoiceProvider] Update invoice failed: ${response.message}');
        _setError(response.message);
        return false;
      }
    } catch (e) {
      debugPrint('❌ [InvoiceProvider] Exception updating invoice: $e');
      _setError('Error updating invoice: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteInvoice(String id) async {
    _setLoading(true);
    try {
      debugPrint('🔍 [InvoiceProvider] Deleting invoice: $id');
      
      final response = await _invoiceService.deleteInvoice(id);
      
      debugPrint('🔍 [InvoiceProvider] Delete invoice response success: ${response.success}');
      debugPrint('🔍 [InvoiceProvider] Delete invoice response message: ${response.message}');
      
      if (response.success) {
        _invoices.removeWhere((i) => i.id == id);
        _setSuccess('Invoice deleted');
        notifyListeners();
        debugPrint('✅ [InvoiceProvider] Invoice deleted from list');
        return true;
      } else {
        debugPrint('❌ [InvoiceProvider] Delete invoice failed: ${response.message}');
        _setError(response.message);
        return false;
      }
    } catch (e) {
      debugPrint('❌ [InvoiceProvider] Exception deleting invoice: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> generateInvoicePdf(String id) async {
    _setLoading(true);
    try {
      debugPrint('🔍 [InvoiceProvider] Generating PDF for invoice: $id');
      final response = await _invoiceService.generateInvoicePdf(id);
      
      debugPrint('🔍 [InvoiceProvider] PDF Generation response success: ${response.success}');
      debugPrint('🔍 [InvoiceProvider] PDF Generation response message: ${response.message}');
      
      if (response.success && response.data != null) {
        debugPrint('✅ [InvoiceProvider] PDF generated successfully');
        debugPrint('🔍 [InvoiceProvider] PDF data: ${response.data}');
        
        // Check if response contains file URL or base64 data
        if (response.data!['file_url'] != null) {
          debugPrint('🔍 [InvoiceProvider] PDF file URL: ${response.data!['file_url']}');
          _setSuccess('Invoice PDF generated successfully. File available at: ${response.data!['file_url']}');
          return true;
        } else if (response.data!['file_data'] != null) {
          debugPrint('🔍 [InvoiceProvider] PDF contains base64 data');
          _setSuccess('Invoice PDF generated successfully (base64 data)');
          return true;
        } else if (response.data!['success'] == true) {
          debugPrint('🔍 [InvoiceProvider] PDF generation confirmed');
          _setSuccess('Invoice PDF generated successfully');
          return true;
        } else {
          debugPrint('❌ [InvoiceProvider] PDF response missing file data');
          _setError('PDF generated but no file data received');
          return false;
        }
      } else {
        debugPrint('❌ [InvoiceProvider] PDF generation failed: ${response.message}');
        _setError(response.message ?? 'Failed to generate PDF');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [InvoiceProvider] Exception generating PDF: $e');
      _setError('Error generating PDF: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Generate thermal print data for an invoice
  Future<bool> generateInvoiceThermalPrint(String invoiceId) async {
    debugPrint('🔍 [InvoiceProvider] Generating thermal print for invoice: $invoiceId');
    _clearMessages();
    _setLoading(true);

    try {
      final response = await _invoiceService.generateInvoiceThermalPrint(invoiceId);
      
      debugPrint('🔍 [InvoiceProvider] Thermal print generation response success: ${response.success}');
      debugPrint('🔍 [InvoiceProvider] Thermal print generation response message: ${response.message}');
      
      if (response.success) {
        debugPrint('✅ [InvoiceProvider] Thermal print data generated successfully');
        _setSuccess(response.message);
        
        // Store thermal print data for printing
        _thermalPrintData = response.data;
        notifyListeners();
        
        return true;
      } else {
        debugPrint('❌ [InvoiceProvider] Thermal print generation failed: ${response.message}');
        _setError(response.message);
        return false;
      }
    } catch (e) {
      debugPrint('❌ [InvoiceProvider] Exception generating thermal print: $e');
      _setError('Error generating thermal print: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- Ledger State ---
  Map<String, dynamic>? _ledgerData;
  Map<String, dynamic>? get ledgerData => _ledgerData;

  /// Generate an invoice from an order
  Future<bool> generateInvoiceFromOrder({required String orderId}) async {
    _setLoading(true);
    _clearMessages();
    try {
      debugPrint('🔍 [InvoiceProvider] Generating invoice from order: $orderId');
      final response = await _invoiceService.generateInvoiceFromOrder(orderId: orderId);

      if (response.success && response.data != null) {
        final newInvoice = response.data!;
        _invoices.insert(0, newInvoice);
        _setSuccess(response.message ?? 'Invoice generated successfully');
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to generate invoice');
        return false;
      }
    } catch (e) {
      _setError('Error generating invoice: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Apply a payment to an invoice
  Future<bool> applyInvoicePayment({
    required String invoiceId,
    required double amount,
    String paymentMethod = 'CASH',
    String? reference,
  }) async {
    _setLoading(true);
    _clearMessages();
    try {
      debugPrint('🔍 [InvoiceProvider] Applying payment $amount to $invoiceId');
      final response = await _invoiceService.applyInvoicePayment(
        invoiceId: invoiceId,
        amount: amount,
        paymentMethod: paymentMethod,
        reference: reference,
      );

      if (response.success) {
        _setSuccess(response.message ?? 'Payment applied successfully');
        // Refresh invoices to get updated amounts
        await loadInvoices(refresh: true);
        return true;
      } else {
        _setError(response.message ?? 'Failed to apply payment');
        return false;
      }
    } catch (e) {
      _setError('Error applying payment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Write off remaining balance on an invoice
  Future<bool> writeOffInvoice({
    required String invoiceId,
    double? amount,
    String? reason,
  }) async {
    _setLoading(true);
    _clearMessages();
    try {
      debugPrint('🔍 [InvoiceProvider] Writing off invoice: $invoiceId');
      final response = await _invoiceService.writeOffInvoice(
        invoiceId: invoiceId,
        amount: amount,
        reason: reason,
      );

      if (response.success && response.data != null) {
        // Update the invoice in our local list
        final index = _invoices.indexWhere((i) => i.id == invoiceId);
        if (index != -1) {
          _invoices[index] = response.data!;
        }
        _setSuccess(response.message ?? 'Write-off applied successfully');
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Failed to apply write-off');
        return false;
      }
    } catch (e) {
      _setError('Error applying write-off: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load invoice ledger summary
  Future<void> loadLedger({String? customerId}) async {
    try {
      final response = await _invoiceService.getInvoiceLedger(customerId: customerId);

      if (response.success && response.data != null) {
        _ledgerData = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading ledger: $e');
    }
  }

  // --- Helpers ---
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

  @override
  void dispose() {
    super.dispose();
  }
}