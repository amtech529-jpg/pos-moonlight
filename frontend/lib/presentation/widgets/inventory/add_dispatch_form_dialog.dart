import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/src/models/dispatch/dispatch_form_model.dart';
import 'package:frontend/src/models/order/order_model.dart';
import 'package:frontend/src/models/product/product_model.dart';
import 'package:frontend/src/providers/customer_provider.dart' show Customer, CustomerProvider;
import 'package:frontend/src/providers/dispatch_provider.dart';
import 'package:frontend/src/providers/order_provider.dart';
import 'package:frontend/src/providers/product_provider.dart';
import 'package:frontend/src/providers/quotation_provider.dart';
import 'package:frontend/src/theme/app_theme.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:frontend/presentation/widgets/globals/text_field.dart';
import 'package:frontend/presentation/widgets/globals/keyboard_scrollable.dart';
import 'package:frontend/src/services/pdf_gate_pass_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

class AddDispatchFormDialog extends StatefulWidget {
  final DispatchFormModel? existingForm;
  const AddDispatchFormDialog({super.key, this.existingForm});

  @override
  State<AddDispatchFormDialog> createState() => _AddDispatchFormDialogState();
}

class _AddDispatchFormDialogState extends State<AddDispatchFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _orderSearchController = TextEditingController();
  final _customerSearchController = TextEditingController();
  final _productSearchController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _staffNameController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _locationController = TextEditingController();
  
  final _orderSearchFocus = FocusNode();
  final _customerSearchFocus = FocusNode();
  final _productSearchFocus = FocusNode();
  late List<FocusNode> _orderResultFocusNodes;
  late List<FocusNode> _customerResultFocusNodes;
  late List<FocusNode> _productResultFocusNodes;
  
  final _driverNameFocus = FocusNode();
  final _vehicleNumberFocus = FocusNode();
  final _vehicleTypeFocus = FocusNode();
  final _staffNameFocus = FocusNode();
  
  OrderModel? _selectedOrder;
  Customer? _selectedCustomer;
  List<DispatchItemModel> _items = [];
  
  bool _isSearchingOrders = false;
  List<OrderModel> _orderSearchResults = [];
  
  bool _isSearchingCustomers = false;
  List<Customer> _customerSearchResults = [];
  
  bool _isSearchingProducts = false;
  List<ProductModel> _productSearchResults = [];
  bool _isSaving = false;
  Map<String, int> _availabilityMap = {};
  final Map<String, TextEditingController> _quantityControllers = {};
  
  List<String> _eventNameSuggestions = [];
  List<String> _locationSuggestions = [];
  List<String> _filteredEventSuggestions = [];
  List<String> _filteredLocationSuggestions = [];

  // Editable Dates
  DateTime? _eventDate;
  DateTime? _dispatchDate;
  DateTime? _returnDate;
  
  final FocusNode _eventNameFocus = FocusNode();
  final FocusNode _eventLocationFocus = FocusNode();
  final FocusNode _eventDateFocus = FocusNode();
  final FocusNode _dispatchDateFocus = FocusNode();
  final FocusNode _returnDateFocus = FocusNode();
  
  List<FocusNode>? _suggestionFocusNodesList;
  List<FocusNode> get _suggestionFocusNodes {
    _suggestionFocusNodesList ??= List.generate(20, (index) => FocusNode());
    return _suggestionFocusNodesList!;
  }

  final List<String> _vehicleTypes = ['Bike', 'Auto Rickshaw', 'Loader Rickshaw', 'Car', 'Pickup', 'Truck', 'Shahzor Gari'];
  String _selectedVehicleType = 'Truck';

  @override
  void initState() {
    super.initState();
    _orderResultFocusNodes = [];
    _customerResultFocusNodes = [];
    _productResultFocusNodes = [];
    _filteredEventSuggestions = [];
    _filteredLocationSuggestions = [];

    // Add listeners to date focus nodes for visual feedback
    _eventDateFocus.addListener(() => setState(() {}));
    _dispatchDateFocus.addListener(() => setState(() {}));
    _returnDateFocus.addListener(() => setState(() {}));
    if (widget.existingForm != null) {
      _selectedOrder = widget.existingForm!.orderDetails;
      if (_selectedOrder != null) {
        _orderSearchController.text = _selectedOrder!.orderNumber;
      }
      
      if (widget.existingForm!.customerId != null) {
        _selectedCustomer = Customer(
          id: widget.existingForm!.customerId!,
          name: widget.existingForm!.customerDetails?['name'] ?? '',
          phone: widget.existingForm!.customerDetails?['phone'] ?? '',
          email: '',
          createdAt: DateTime.now(),
          country: 'Pakistan',
          customerType: 'INDIVIDUAL',
          status: 'ACTIVE',
          phoneVerified: false,
          emailVerified: false,
          isActive: true,
          displayName: widget.existingForm!.customerDetails?['name'] ?? '',
          initials: 'CU',
          isNewCustomer: false,
          isRecentCustomer: false,
          totalSalesCount: 0,
          totalSalesAmount: 0,
          hasRecentSales: false,
          customerTypeDisplay: 'Individual',
          statusDisplay: 'Active',
        );
        _customerSearchController.text = _selectedCustomer!.name;
      }

      _driverNameController.text = widget.existingForm!.driverName;
      _vehicleNumberController.text = widget.existingForm!.vehicleNumber;
      _staffNameController.text = widget.existingForm!.staffName;
      _vehicleTypeController.text = widget.existingForm!.vehicleType ?? '';
      if (_vehicleTypes.contains(widget.existingForm!.vehicleType)) {
        _selectedVehicleType = widget.existingForm!.vehicleType!;
      } else if (widget.existingForm!.vehicleType != null && widget.existingForm!.vehicleType!.isNotEmpty) {
        _selectedVehicleType = 'Other';
      }
      
      _eventDate = widget.existingForm!.eventDate;
      _dispatchDate = widget.existingForm!.dispatchDate;
      _returnDate = widget.existingForm!.returnDate;

      _items = List.from(widget.existingForm!.items);
      for (var item in _items) {
        _quantityControllers[item.id] = TextEditingController(text: item.quantity.toString());
      }
      _eventNameController.text = widget.existingForm!.eventName ?? '';
      _locationController.text = widget.existingForm!.eventLocation ?? '';
      
      if (_selectedOrder != null) {
        _eventDate = _selectedOrder!.eventDate;
        _dispatchDate = _selectedOrder!.dispatchDate;
        _returnDate = _selectedOrder!.returnDate;
        if (_eventNameController.text.isEmpty) _eventNameController.text = _selectedOrder!.eventName ?? _selectedOrder!.description;
        if (_locationController.text.isEmpty) _locationController.text = _selectedOrder!.eventLocation ?? '';
      }
    } else {
      // For new standalone forms, keep dates null as requested
      _eventDate = null;
      _dispatchDate = null;
      _returnDate = null;
    }
    _loadSuggestions();
  }

  void _loadSuggestions() async {
    final dispatchProvider = context.read<DispatchProvider>();
    final orderProvider = context.read<OrderProvider>();
    final quotationProvider = context.read<QuotationProvider>();
    
    // Collect from Dispatches
    final dispatchForms = dispatchProvider.forms;
    final Set<String> events = dispatchForms.map((f) => f.eventName ?? '').where((s) => s.isNotEmpty).toSet();
    final Set<String> locations = dispatchForms.map((f) => f.eventLocation ?? '').where((s) => s.isNotEmpty).toSet();
    
    // Collect from Orders
    final orders = orderProvider.allOrders;
    events.addAll(orders.map((o) => o.eventName ?? '').where((s) => s.isNotEmpty));
    locations.addAll(orders.map((o) => o.eventLocation ?? '').where((s) => s.isNotEmpty));
    
    // Collect from Quotations
    final quotations = quotationProvider.quotations;
    events.addAll(quotations.map((q) => q.eventName).where((s) => s.isNotEmpty));
    locations.addAll(quotations.map((q) => q.eventLocation ?? '').where((s) => s.isNotEmpty));

    setState(() {
      _eventNameSuggestions = events.toList();
      _locationSuggestions = locations.toList();
    });
  }

  @override
  void dispose() {
    _orderSearchController.dispose();
    _customerSearchController.dispose();
    _productSearchController.dispose();
    _driverNameController.dispose();
    _vehicleNumberController.dispose();
    _vehicleTypeController.dispose();
    _locationController.dispose();
    _eventNameFocus.dispose();
    _eventLocationFocus.dispose();
    _eventDateFocus.dispose();
    _dispatchDateFocus.dispose();
    _returnDateFocus.dispose();
    _orderSearchFocus.dispose();
    _customerSearchFocus.dispose();
    _productSearchFocus.dispose();
    _driverNameFocus.dispose();
    _vehicleNumberFocus.dispose();
    _vehicleTypeFocus.dispose();
    _staffNameFocus.dispose();
    for (var node in _orderResultFocusNodes) {
      node.dispose();
    }
    for (var node in _customerResultFocusNodes) {
      node.dispose();
    }
    for (var node in _productResultFocusNodes) {
      node.dispose();
    }
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _searchOrders(String query) async {
    if (query.isEmpty) {
      setState(() {
        _orderSearchResults = [];
        _isSearchingOrders = false;
      });
      return;
    }

    setState(() => _isSearchingOrders = true);
    try {
      final results = await context.read<OrderProvider>().searchOrdersUtility(query, excludeDispatched: true);
      setState(() {
        _orderSearchResults = results;
        _isSearchingOrders = false;
        
        // Update focus nodes if results changed
        for (var node in _orderResultFocusNodes) {
          node.dispose();
        }
        _orderResultFocusNodes = List.generate(_orderSearchResults.length, (index) => FocusNode());
      });
    } catch (e) {
      setState(() => _isSearchingOrders = false);
    }
  }

  Future<void> _searchCustomers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _customerSearchResults = [];
        _isSearchingCustomers = false;
      });
      return;
    }

    setState(() => _isSearchingCustomers = true);
    final customerProvider = context.read<CustomerProvider>();
    await customerProvider.searchCustomers(query);
    setState(() {
      _customerSearchResults = customerProvider.customers;
      _isSearchingCustomers = false;
      
      // Update focus nodes
      for (var node in _customerResultFocusNodes) {
        node.dispose();
      }
      _customerResultFocusNodes.clear();
      _customerResultFocusNodes.addAll(List.generate(_customerSearchResults.length, (index) => FocusNode()));
    });
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _productSearchResults = [];
        _isSearchingProducts = false;
      });
      return;
    }

    setState(() => _isSearchingProducts = true);
    final productProvider = context.read<ProductProvider>();
    productProvider.searchProducts(query);
    
    // Give it a moment to update results (search is debounced in provider)
    await Future.delayed(const Duration(milliseconds: 600));
    
    final results = productProvider.products;
    setState(() {
      _productSearchResults = results;
      
      // Update focus nodes
      for (var node in _productResultFocusNodes) {
        node.dispose();
      }
      _productResultFocusNodes.clear();
      _productResultFocusNodes.addAll(List.generate(_productSearchResults.length, (index) => FocusNode()));
    });

    if (results.isNotEmpty) {
      final ids = results.map((p) => p.id).toList();
      final date = _dispatchDate ?? DateTime.now();
      
      final avail = await productProvider.checkAvailability(
        productIds: ids, 
        startDate: date, 
        endDate: date.add(const Duration(days: 1))
      );

      if (avail != null) {
        setState(() {
          for (var id in ids) {
            if (avail.containsKey(id)) {
              _availabilityMap[id] = avail[id]['available_quantity'] ?? 0;
            }
          }
        });
      }
    }
    
    setState(() => _isSearchingProducts = false);
  }

  void _selectOrder(OrderModel order) {
    setState(() {
      _selectedOrder = order;
      _selectedCustomer = null;
      _orderSearchResults = [];
      _orderSearchController.text = order.orderNumber;
      
      _eventDate = order.eventDate;
      _dispatchDate = order.dispatchDate;
      _returnDate = order.returnDate;

      // Auto-fill items from order
      _items = order.items.map((item) => DispatchItemModel(
        id: const Uuid().v4(),
        productId: item.productId,
        productName: item.productName,
        quantity: item.quantity,
        isExtra: false,
      )).toList();
      
      _eventNameController.text = order.eventName ?? order.description;
      _locationController.text = order.eventLocation ?? '';
    });
    
    // Advance focus
    _driverNameFocus.requestFocus();
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      _selectedOrder = null;
      _customerSearchResults = [];
      _customerSearchController.text = customer.name;
      _orderSearchController.clear();
      // Keep existing items or clear if switching from order
      if (_items.any((i) => !i.isExtra)) {
         _items = _items.where((i) => i.isExtra).toList();
      }
    });
    
    // Move focus to first date as requested
    _eventDateFocus.requestFocus();
  }

  Future<void> _pickEventDate() async {
    final picked = await showDatePicker(
      context: context,
      helpText: 'SELECT EVENT DATE',
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFBD0D1D)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
      _dispatchDateFocus.requestFocus();
    }
  }

  Future<void> _pickDispatchDate() async {
    final picked = await showDatePicker(
      context: context,
      helpText: 'SELECT DISPATCH DATE',
      initialDate: _dispatchDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFBD0D1D)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dispatchDate = picked);
      _returnDateFocus.requestFocus();
    }
  }

  Future<void> _pickReturnDate() async {
    final picked = await showDatePicker(
      context: context,
      helpText: 'SELECT RETURN DATE',
      initialDate: _returnDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFBD0D1D)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _returnDate = picked);
      _eventNameFocus.requestFocus();
    }
  }

  void _addProduct(ProductModel product) {
    final existingIndex = _items.indexWhere((item) => item.productId == product.id);
    
    setState(() {
      if (existingIndex != -1) {
        final existingItem = _items[existingIndex];
        final newQty = existingItem.quantity + 1;
        _items[existingIndex] = existingItem.copyWith(quantity: newQty);
        _quantityControllers[existingItem.id]?.text = newQty.toString();
      } else {
        final newItem = DispatchItemModel(
          id: 'temp_${const Uuid().v4()}',
          productId: product.id,
          productName: product.name,
          quantity: 1,
          isExtra: _selectedOrder != null,
        );
        _items.add(newItem);
        _quantityControllers[newItem.id] = TextEditingController(text: '1');
      }
      _productSearchResults = [];
      _productSearchController.clear();
    });
  }

  void _removeItem(int index) {
    final item = _items[index];
    setState(() {
      _items.removeAt(index);
      _quantityControllers[item.id]?.dispose();
      _quantityControllers.remove(item.id);
    });
  }

  Future<void> _saveAndPrint() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedOrder == null && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an Order or a Customer')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {

    // --- STOCK VALIDATION ---
    // First, ensure we have current availability for ALL items
    final productProvider = context.read<ProductProvider>();
    final allProductIds = _items.map((i) => i.productId).toList();
    final date = _dispatchDate ?? DateTime.now();
    
    final avail = await productProvider.checkAvailability(
      productIds: allProductIds, 
      startDate: date, 
      endDate: date.add(const Duration(days: 1)),
      excludeOrderId: _selectedOrder?.id,
    );

    if (avail != null) {
      setState(() {
        for (var id in allProductIds) {
          if (avail.containsKey(id)) {
            _availabilityMap[id] = avail[id]['available_quantity'] ?? 0;
          }
        }
      });
    }

    List<String> outOfStockItems = [];
    for (var item in _items) {
      int physicalAvailable = _availabilityMap[item.productId] ?? 0;
      
      // If editing, add back the original quantity of this item 
      if (widget.existingForm != null) {
        final originalItem = widget.existingForm!.items.where((oi) => oi.productId == item.productId);
        if (originalItem.isNotEmpty) {
          physicalAvailable += originalItem.first.quantity;
        }
      }

      // Final allowed quantity: Either what's in stock, or what was already ordered
      // (This handles partner stock cases where the order was for more than we have)
      int maxAllowed = physicalAvailable;
      
      if (_selectedOrder != null) {
        final orderItem = _selectedOrder!.items.where((oi) => oi.productId == item.productId);
        if (orderItem.isNotEmpty) {
          // If the order has more than our stock, allow up to the order amount
          if (orderItem.first.quantity > maxAllowed) {
            maxAllowed = orderItem.first.quantity;
          }
        }
      }

      if (item.quantity > maxAllowed) {
        outOfStockItems.add("${item.productName}\n(Requested: ${item.quantity}, Max Allowed: $maxAllowed)");
      }
    }

    if (outOfStockItems.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
              SizedBox(width: 12),
              Text('Stock Warning', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'The following items exceed available stock:', 
                  style: TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w500)
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: outOfStockItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                              Expanded(
                                child: Text(
                                  item, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBD0D1D), fontSize: 14)
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please adjust quantities before proceeding.', 
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: Colors.black54)
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBD0D1D),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      );
      return; // Stop saving
    }
    // --- END STOCK VALIDATION ---

    final vehicleType = _vehicleTypeController.text;

    // --- AUTO-SPLIT ITEMS FOR PARTNER STOCK REPORTING ---
    List<DispatchItemModel> processedItems = [];
    for (var item in _items) {
      // Get physical stock (ignoring the order reservation for a moment to see true own stock)
      int physicalStock = _availabilityMap[item.productId] ?? 0;
      
      // If we are editing, we need to consider the stock we ALREADY consumed as 'ours'
      if (widget.existingForm != null) {
        final originalItem = widget.existingForm!.items.where((oi) => oi.productId == item.productId && !oi.isExtra);
        if (originalItem.isNotEmpty) {
          physicalStock += originalItem.first.quantity;
        }
      }

      if (!item.isExtra && item.quantity > physicalStock) {
        if (physicalStock > 0) {
          // Split into Own Stock row and Partner Stock row
          processedItems.add(item.copyWith(
            id: item.id, // Keep ID for first part
            quantity: physicalStock, 
            isExtra: false
          ));
          processedItems.add(item.copyWith(
            id: "extra_${item.id}", 
            quantity: item.quantity - physicalStock, 
            isExtra: true
          ));
        } else {
          // All is partner stock
          processedItems.add(item.copyWith(isExtra: true));
        }
      } else {
        processedItems.add(item);
      }
    }

    final dispatchForm = DispatchFormModel(
      id: widget.existingForm?.id ?? '',
      orderId: _selectedOrder?.id,
      customerId: _selectedCustomer?.id,
      driverName: _driverNameController.text,
      vehicleNumber: _vehicleNumberController.text,
      vehicleType: vehicleType,
      staffName: _staffNameController.text,
      eventDate: _eventDate,
      dispatchDate: _dispatchDate,
      returnDate: _returnDate,
      eventName: _eventNameController.text,
      eventLocation: _locationController.text,
      createdAt: DateTime.now(),
      items: processedItems,
      orderDetails: _selectedOrder,
    );

    final provider = context.read<DispatchProvider>();
    DispatchFormModel? result;
    
    if (widget.existingForm == null) {
      result = await provider.createDispatchForm(dispatchForm);
    } else {
      final success = await provider.updateDispatchForm(widget.existingForm!.id, dispatchForm.toJson());
      if (success) result = dispatchForm;
    }

    if (result != null) {
      // Re-fetch details to get populated order/items if needed
      final fullResult = await provider.getDispatchFormDetails(result.id.isEmpty ? widget.existingForm!.id : result.id);
      if (fullResult != null) {
        await PdfGatePassService.printGatePass(fullResult);
      }
      
      if (mounted) {
        // Refresh providers to update inventory and order status
        // Await these so the screen is ready when dialog closes
        await context.read<ProductProvider>().initialize();
        await context.read<OrderProvider>().refreshOrders();
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gate Pass saved and printed successfully')),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to save Gate Pass')),
        );
      }
    }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: const Color(0xFFBD0D1D),
        scaffoldBackgroundColor: Colors.white,
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.black),
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: isMobile ? double.infinity : 950,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.existingForm == null ? 'Create Gate Pass (Dispatch)' : 'Edit Gate Pass',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.black12),
                
                Expanded(
                  child: KeyboardScrollable(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSelectionSection(),
                          const SizedBox(height: 24),
                          _buildDateDetailsSection(),
                          const SizedBox(height: 24),
                          _buildItemsSection(),
                          const SizedBox(height: 24),
                          _buildLogisticsSection(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const Divider(height: 1, color: Colors.black12),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Target Selection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Option 1: Link to Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                  const SizedBox(height: 8),
                  PremiumTextField(
                    controller: _orderSearchController,
                    focusNode: _orderSearchFocus,
                    label: 'Search Order',
                    hint: 'Enter Order # or Customer...',
                    prefixIcon: Icons.receipt_long,
                    onChanged: _searchOrders,
                    enabled: _selectedCustomer == null,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown || 
                            event.logicalKey == LogicalKeyboardKey.tab) {
                          if (_orderResultFocusNodes.isNotEmpty) {
                            _orderResultFocusNodes[0].requestFocus();
                            return KeyEventResult.handled;
                          }
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            const Text('OR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Option 2: Standalone Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
                  const SizedBox(height: 8),
                  PremiumTextField(
                    controller: _customerSearchController,
                    focusNode: _customerSearchFocus,
                    label: 'Search Customer',
                    hint: 'Enter Customer Name...',
                    prefixIcon: Icons.person_search,
                    onChanged: _searchCustomers,
                    enabled: _selectedOrder == null,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowDown || 
                            event.logicalKey == LogicalKeyboardKey.tab) {
                          if (_customerResultFocusNodes.isNotEmpty) {
                            _customerResultFocusNodes[0].requestFocus();
                            return KeyEventResult.handled;
                          }
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        
        if (_orderSearchResults.isNotEmpty) _buildOrderResults(),
        if (_customerSearchResults.isNotEmpty) _buildCustomerResults(),

        if (_selectedOrder != null) _buildOrderSummary(),
        if (_selectedCustomer != null) _buildCustomerSummary(),
      ],
    );
  }

  Widget _buildOrderResults() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black26), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Column(
          children: _orderSearchResults.asMap().entries.map((entry) {
            final index = entry.key;
            final order = entry.value;
            final focusNode = _orderResultFocusNodes[index];
            
            return Focus(
              focusNode: focusNode,
              onFocusChange: (focused) => setState(() {}),
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (index < _orderResultFocusNodes.length - 1) {
                      _orderResultFocusNodes[index + 1].requestFocus();
                      return KeyEventResult.handled;
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (index > 0) {
                      _orderResultFocusNodes[index - 1].requestFocus();
                    } else {
                      _orderSearchFocus.requestFocus();
                    }
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    _selectOrder(order);
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: InkWell(
                onTap: () => _selectOrder(order),
                canRequestFocus: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: focusNode.hasFocus ? const Color(0xFFBD0D1D).withOpacity(0.1) : Colors.transparent,
                    border: const Border(bottom: BorderSide(color: Colors.black12))
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
                                const SizedBox(width: 8),
                                if (order.businessName != null && order.businessName!.isNotEmpty)
                                  Expanded(child: Text(order.businessName!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBD0D1D), fontSize: 16, overflow: TextOverflow.ellipsis))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 14, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text(order.clientName ?? "No Name", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 14)),
                                const SizedBox(width: 8),
                                const Icon(Icons.phone, size: 14, color: Colors.black54),
                                const SizedBox(width: 4),
                                Text(order.customerPhone, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCustomerResults() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black26), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Column(
          children: _customerSearchResults.asMap().entries.map((entry) {
            final index = entry.key;
            final customer = entry.value;
            final focusNode = _customerResultFocusNodes[index];
            
            return Focus(
              focusNode: focusNode,
              onFocusChange: (focused) => setState(() {}),
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (index < _customerResultFocusNodes.length - 1) {
                      _customerResultFocusNodes[index + 1].requestFocus();
                      return KeyEventResult.handled;
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (index > 0) {
                      _customerResultFocusNodes[index - 1].requestFocus();
                    } else {
                      _customerSearchFocus.requestFocus();
                    }
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    _selectCustomer(customer);
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: InkWell(
                onTap: () => _selectCustomer(customer),
                canRequestFocus: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: focusNode.hasFocus ? Colors.blue.withOpacity(0.1) : Colors.transparent,
                    border: const Border(bottom: BorderSide(color: Colors.black12))
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (customer.customerType == 'BUSINESS' && (customer.businessName ?? '').isNotEmpty) ...[
                              Text(customer.businessName!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(customer.name, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w400)),
                            ] else ...[
                              Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
                            ],
                            const SizedBox(height: 4),
                            Text(customer.phone, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFBD0D1D).withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBD0D1D).withOpacity(0.2))),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Linked to Order: ${_selectedOrder!.orderNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              if (_selectedOrder!.businessName != null)
                Text('Business: ${_selectedOrder!.businessName}', style: const TextStyle(fontSize: 13, color: Color(0xFFBD0D1D), fontWeight: FontWeight.bold)),
              Text('Client Contact: ${_selectedOrder!.clientName ?? _selectedOrder!.customerName}', style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w600)),
            ],
          )),
          TextButton(onPressed: () => setState(() { _selectedOrder = null; _orderSearchController.clear(); _items.clear(); }), child: const Text('Clear', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildCustomerSummary() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withOpacity(0.2))),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedCustomer!.customerType == 'BUSINESS' && (_selectedCustomer!.businessName ?? '').isNotEmpty) ...[
                  Text('Standalone Business: ${_selectedCustomer!.businessName}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  Text('Contact Person: ${_selectedCustomer!.name}', style: TextStyle(color: Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
                ] else ...[
                  Text('Standalone Customer: ${_selectedCustomer!.name}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ],
            ),
          ),
          TextButton(onPressed: () => setState(() { _selectedCustomer = null; _customerSearchController.clear(); }), child: const Text('Clear', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Dispatch Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            if (_items.isNotEmpty) Text('${_items.length} Items Selected', style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
          PremiumTextField(
            controller: _productSearchController,
            focusNode: _productSearchFocus,
            label: 'Add Product',
            hint: 'Search by name or barcode...',
            prefixIcon: Icons.add_shopping_cart,
            onChanged: _searchProducts,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowDown || 
                    event.logicalKey == LogicalKeyboardKey.tab) {
                  if (_productResultFocusNodes.isNotEmpty) {
                    _productResultFocusNodes[0].requestFocus();
                    return KeyEventResult.handled;
                  }
                }
              }
              return KeyEventResult.ignored;
            },
          ),
        if (_productSearchResults.isNotEmpty) _buildProductResults(),
        const SizedBox(height: 16),
        _buildItemsTable(),
      ],
    );
  }

  Widget _buildProductResults() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black26), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Column(
          children: _productSearchResults.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            final focusNode = _productResultFocusNodes[index];
            
            return Focus(
              focusNode: focusNode,
              onFocusChange: (focused) => setState(() {}),
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (index < _productResultFocusNodes.length - 1) {
                      _productResultFocusNodes[index + 1].requestFocus();
                      return KeyEventResult.handled;
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    if (index > 0) {
                      _productResultFocusNodes[index - 1].requestFocus();
                    } else {
                      _productSearchFocus.requestFocus();
                    }
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                    _addProduct(product);
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: InkWell(
                onTap: () => _addProduct(product),
                canRequestFocus: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: focusNode.hasFocus ? Colors.green.withOpacity(0.1) : Colors.transparent,
                    border: const Border(bottom: BorderSide(color: Colors.black12))
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
                      ),
                      Text(
                        'Available: ${_availabilityMap[product.id] ?? product.quantity}', 
                        style: TextStyle(
                          color: (_availabilityMap[product.id] ?? product.quantity) <= 0 ? Colors.red : Colors.green.shade700, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildItemsTable() {
    if (_items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: const Center(child: Text('No items added yet. Search products to add them.', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(
              children: const [
                Expanded(flex: 4, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                Expanded(flex: 2, child: Center(child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
                Expanded(flex: 2, child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),),
                SizedBox(width: 60, child: Center(child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
              ],
            ),
          ),
          // Table Body
          ...List.generate(_items.length, (index) {
            final item = _items[index];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16))),
                  Expanded(flex: 2, child: Center(
                    child: SizedBox(
                      width: 90,
                      child: TextField(
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
                        decoration: InputDecoration(
                          isDense: true, 
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFBD0D1D), width: 2)),
                        ),
                        onChanged: (val) {
                          if (val.isEmpty) return;
                          final newQty = int.tryParse(val) ?? item.quantity;
                          _items[index] = _items[index].copyWith(quantity: newQty);
                        },
                        controller: _quantityControllers[item.id] ?? (
                          _quantityControllers[item.id] = TextEditingController(text: item.quantity.toString())
                        ),
                      ),
                    ),
                  )),
                  Expanded(flex: 2, child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: item.isExtra ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(item.isExtra ? 'Partner' : 'Order Item', textAlign: TextAlign.center, style: TextStyle(color: item.isExtra ? Colors.orange.shade900 : Colors.green.shade900, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  )),
                  SizedBox(width: 60, child: Center(child: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 28), onPressed: () => _removeItem(index)))),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLogisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Logistics & Staff', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        const SizedBox(height: 16),
        PremiumTextField(
          controller: _driverNameController,
          focusNode: _driverNameFocus,
          label: 'Driver Name',
          prefixIcon: Icons.person_outline,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _vehicleNumberFocus.requestFocus(),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        PremiumTextField(
          controller: _vehicleNumberController,
          focusNode: _vehicleNumberFocus,
          label: 'Vehicle Number',
          prefixIcon: Icons.directions_car_outlined,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _staffNameFocus.requestFocus(),
          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _vehicleTypes.contains(_selectedVehicleType) ? _selectedVehicleType : _vehicleTypes.first,
                decoration: InputDecoration(
                  labelText: 'Vehicle Type',
                  prefixIcon: const Icon(Icons.local_shipping, color: Color(0xFFBD0D1D)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black26)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black26)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFBD0D1D), width: 2)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                items: _vehicleTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type, style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedVehicleType = newValue;
                      _vehicleTypeController.text = newValue;
                    });
                  }
                },
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: PremiumTextField(
                controller: _staffNameController,
                label: 'Staff Accompanying',
                prefixIcon: Icons.badge,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20), 
              side: const BorderSide(color: Colors.black87),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: const Text('Cancel', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAndPrint,
            icon: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.print, color: Colors.white),
            label: Text(
              _isSaving 
                ? 'Saving...' 
                : (widget.existingForm == null ? 'Save & Print Gate Pass' : 'Update & Print'), 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBD0D1D), 
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDatePickerField('Event Date', _eventDate, (d) => setState(() => _eventDate = d), onTap: _pickEventDate, focusNode: _eventDateFocus)),
            const SizedBox(width: 12),
            Expanded(child: _buildDatePickerField('Dispatch Date', _dispatchDate, (d) => setState(() => _dispatchDate = d), onTap: _pickDispatchDate, focusNode: _dispatchDateFocus)),
            const SizedBox(width: 12),
            Expanded(child: _buildDatePickerField('Return Date', _returnDate, (d) => setState(() => _returnDate = d), onTap: _pickReturnDate, focusNode: _returnDateFocus)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  PremiumTextField(
                    controller: _eventNameController,
                    focusNode: _eventNameFocus,
                    label: 'Event Name / Description',
                    prefixIcon: Icons.event,
                    hint: 'e.g. Wedding of Ali...',
                    onSubmitted: (_) => _eventLocationFocus.requestFocus(),
                    onChanged: (val) {
                      setState(() {
                        if (val.isEmpty) {
                          _filteredEventSuggestions = [];
                        } else {
                          _filteredEventSuggestions = _eventNameSuggestions
                              .where((s) => s.toLowerCase().contains(val.toLowerCase()))
                              .toList();
                        }
                      });
                    },
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.tab)) {
                        if (_filteredEventSuggestions.isNotEmpty) {
                          _suggestionFocusNodes[0].requestFocus();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                  ),
                  if (_filteredEventSuggestions.isNotEmpty)
                    _buildSuggestionResults(_filteredEventSuggestions, (val) {
                      setState(() {
                        _eventNameController.text = val;
                        _filteredEventSuggestions = [];
                        _eventLocationFocus.requestFocus();
                      });
                    }, _eventNameFocus, _eventLocationFocus),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  PremiumTextField(
                    controller: _locationController,
                    focusNode: _eventLocationFocus,
                    label: 'Event Location / Address',
                    prefixIcon: Icons.location_on,
                    hint: 'e.g. PC Hotel, Lahore...',
                    onSubmitted: (_) => _productSearchFocus.requestFocus(),
                    onChanged: (val) {
                      setState(() {
                        if (val.isEmpty) {
                          _filteredLocationSuggestions = [];
                        } else {
                          _filteredLocationSuggestions = _locationSuggestions
                              .where((s) => s.toLowerCase().contains(val.toLowerCase()))
                              .toList();
                        }
                      });
                    },
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.tab)) {
                        if (_filteredLocationSuggestions.isNotEmpty) {
                          _suggestionFocusNodes[0].requestFocus();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                  ),
                  if (_filteredLocationSuggestions.isNotEmpty)
                    _buildSuggestionResults(_filteredLocationSuggestions, (val) {
                      setState(() {
                        _locationController.text = val;
                        _filteredLocationSuggestions = [];
                        _productSearchFocus.requestFocus();
                      });
                    }, _eventLocationFocus, _productSearchFocus),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionResults(List<String> suggestions, Function(String) onSelected, FocusNode parentFocus, FocusNode nextFieldFocus) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          final fNode = _suggestionFocusNodes[index % 20];
          return Focus(
            focusNode: fNode,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.enter) {
                  onSelected(suggestion);
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.tab) {
                  if (index < suggestions.length - 1) {
                    _suggestionFocusNodes[(index + 1) % 20].requestFocus();
                  } else {
                    nextFieldFocus.requestFocus();
                  }
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  if (index > 0) {
                    _suggestionFocusNodes[(index - 1) % 20].requestFocus();
                  } else {
                    parentFocus.requestFocus();
                  }
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: InkWell(
              onTap: () => onSelected(suggestion),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                color: fNode.hasFocus ? const Color(0xFFBD0D1D).withOpacity(0.05) : Colors.transparent,
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 18, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(child: Text(suggestion, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black))),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime? value, Function(DateTime) onSelected, {VoidCallback? onTap, FocusNode? focusNode}) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
          // If the field is focused and Tab is pressed, open the calendar
          if (onTap != null) {
            onTap();
            return KeyEventResult.handled; // Consume Tab so it doesn't move focus yet
          }
        }
        // Handle Enter/Space as well for standard accessibility
        if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space)) {
          if (onTap != null) {
            onTap();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          return InkWell(
            onFocusChange: (focused) {
              setState(() {});
            },
            onTap: onTap ?? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2101),
                builder: (context, child) => Theme(
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(primary: Color(0xFFBD0D1D)),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) onSelected(picked);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFocused ? const Color(0xFFBD0D1D) : Colors.grey.shade400,
                  width: isFocused ? 2 : 1,
                ),
                boxShadow: isFocused ? [BoxShadow(color: const Color(0xFFBD0D1D).withOpacity(0.1), blurRadius: 4)] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: isFocused ? const Color(0xFFBD0D1D) : Colors.black54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: isFocused ? const Color(0xFFBD0D1D) : const Color(0xFFBD0D1D).withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Text(
                        value == null ? 'Select' : '${value.day}/${value.month}/${value.year}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: isFocused ? Colors.black : Colors.black87),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
