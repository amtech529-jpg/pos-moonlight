import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../src/models/quotation/quotation_model.dart';
import '../../../src/models/customer/customer_model.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/providers/customer_provider.dart' show CustomerProvider, Customer;
import '../../../src/providers/product_provider.dart';
import '../../../src/providers/quotation_provider.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/drop_down.dart';
import '../customer/add_customer_dialog.dart';

class AddQuotationDialog extends StatefulWidget {
  const AddQuotationDialog({super.key});

  @override
  State<AddQuotationDialog> createState() => _AddQuotationDialogState();
}

class _AddQuotationDialogState extends State<AddQuotationDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _notesController = TextEditingController();
  final _discountController = TextEditingController(text: "0");
  
  // Focus Nodes
  final _eventNameFocusNode = FocusNode();
  final _locationFocusNode = FocusNode();
  final _notesFocusNode = FocusNode();

  DateTime _eventDate = DateTime.now();
  DateTime _returnDate = DateTime.now().add(const Duration(days: 2));
  DateTime _validUntil = DateTime.now().add(const Duration(days: 15));
  
  Customer? _selectedCustomer;
  List<QuotationItemModel> _items = [];

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _total => _subtotal - _discount;

  @override
  void initState() {
    super.initState();
    // Load products and customers
    Future.microtask(() {
      final productProvider = context.read<ProductProvider>();
      productProvider.initialize().then((_) {
        _reloadProducts();
      });
      context.read<CustomerProvider>().initialize();
      context.read<VendorProvider>().initialize();
    });
  }

  void _reloadProducts() {
    final productProvider = context.read<ProductProvider>();
    productProvider.applyFilters(
      productProvider.currentFilters.copyWith(
        startDate: _eventDate,
        endDate: _returnDate,
      ),
    );
  }

  Widget _buildDatePickerTheme(Widget child) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: AppTheme.primaryMaroon,
          onPrimary: Colors.white,
          surface: const Color(0xFF2C2C2C),
          onSurface: Colors.white,
        ),
        dialogBackgroundColor: const Color(0xFF2C2C2C),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _companyNameController.dispose();
    _eventNameController.dispose();
    _eventLocationController.dispose();
    _notesController.dispose();
    _discountController.dispose();
    _eventNameFocusNode.dispose();
    _locationFocusNode.dispose();
    _notesFocusNode.dispose();
    
    // Clear filters and search from provider when closing the dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final provider = Provider.of<ProductProvider>(context, listen: false);
        provider.clearFilters(); // This resets both search and date filters
      }
    });

    super.dispose();
  }

  void _addItem() async {
    final results = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => _ManualItemEntryDialog(
        eventDate: _eventDate,
        returnDate: _returnDate,
        currentItems: _items,
      ),
    );

    if (results != null && results.isNotEmpty) {
      setState(() {
        for (var result in results) {
          _items.add(QuotationItemModel(
            product: result['product_id'],
            productName: result['name'],
            quantity: result['quantity'],
            rate: result['rate'],
            days: result['days'],
            pricingType: result['pricing_type'],
            rentedFromPartner: result['rented_from_partner'] ?? false,
            partner: result['partner'],
            partnerRate: result['partner_rate'],
            availableStock: result['available_stock'],
            total: result['quantity'] * result['rate'] * result['days'],
          ));
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add at least one item")));
        return;
      }

      final quotation = QuotationModel(
        id: "", // Server generated
        quotationNumber: "", // Server generated
        customer: _selectedCustomer?.id,
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        companyName: _companyNameController.text,
        eventName: _eventNameController.text,
        eventLocation: _eventLocationController.text,
        eventDate: _eventDate,
        returnDate: _returnDate,
        validUntil: _validUntil,
        status: "PENDING",
        totalAmount: _subtotal,
        discountAmount: _discount,
        finalAmount: _total,
        specialNotes: _notesController.text,
        items: _items,
        createdAt: DateTime.now(),
      );

      final success = await context.read<QuotationProvider>().addQuotation(quotation);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Quotation created successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        final error = context.read<QuotationProvider>().error;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Text("Error", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              (error == null || error.trim().isEmpty) ? "Failed to create quotation" : error,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.primaryMaroon,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF5F5F7), // Light gray background for contrast
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 90.w,
        height: 96.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _buildHeader(),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 16, thickness: 1.5),
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Side: Details
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle("Customer Information"),
                                const SizedBox(height: 12),
                                _buildCustomerSelection(),
                                const SizedBox(height: 16),
                                _buildSectionTitle("Event Details"),
                                const SizedBox(height: 12),
                                _buildEventFields(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Right Side: Items
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle("Quotation Items"),
                              const SizedBox(height: 8),
                              _buildItemsTable(),
                              const SizedBox(height: 8),
                              _buildSummary(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
               ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: _buildFooter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Create New Quotation", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text("Draft a premium quote for your client", style: TextStyle(color: Colors.grey)),
          ],
        ),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primaryMaroon));
  }

  Widget _buildCustomerSelection() {
    return Consumer<CustomerProvider>(
      builder: (context, provider, _) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PremiumDropdownField<Customer>(
                label: 'Select Customer *',
                hint: 'Choose an existing customer',
                items: provider.customers
                    .map((customer) => DropdownItem<Customer>(
                        value: customer,
                        label: '${customer.orderDisplayName} (${customer.phone})'
                    ))
                    .toList(),
                value: _selectedCustomer,
                onChanged: (customer) {
                  setState(() {
                    _selectedCustomer = customer;
                    if (customer != null) {
                      _customerNameController.text = customer.name;
                      _customerPhoneController.text = customer.phone;
                    }
                  });
                },
                prefixIcon: Icons.person_search_rounded,
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (_) => const AddCustomerDialog(),
                );
                if (mounted) {
                  final currProvider = context.read<CustomerProvider>();
                  if (currProvider.customers.isNotEmpty) {
                    setState(() {
                       _selectedCustomer = currProvider.customers.first;
                       _customerNameController.text = _selectedCustomer!.name;
                       _customerPhoneController.text = _selectedCustomer!.phone;
                    });
                  }
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 52, // Setting back to 52px which is the standard height of a PremiumField border box
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.35), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    Icon(Icons.person_add_alt_1_rounded, size: 20, color: AppTheme.primaryMaroon),
                    const SizedBox(width: 8),
                    const Text(
                      "Add New", 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon)
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildEventFields() {
    return Column(
      children: [
        _buildTextField("Event Name (e.g. Ali's Wedding)", _eventNameController, required: true, focusNode: _eventNameFocusNode, textInputAction: TextInputAction.next),
        const SizedBox(height: 16),
        _buildTextField("Location", _eventLocationController, focusNode: _locationFocusNode, textInputAction: TextInputAction.next),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _eventDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => _buildDatePickerTheme(child!),
                  );
                  if (date != null) {
                    setState(() {
                      _eventDate = date;
                      // Ensure Return Date is not before Event Date
                      if (_returnDate.isBefore(_eventDate)) {
                        _returnDate = _eventDate.add(const Duration(days: 1));
                      }
                    });
                    _reloadProducts();
                  }
                },
                child: _buildTextField("Event Date", TextEditingController(text: DateFormat('dd/MM/yyyy').format(_eventDate)), enabled: false),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _returnDate,
                    firstDate: _eventDate,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => _buildDatePickerTheme(child!),
                  );
                  if (date != null) {
                    setState(() => _returnDate = date);
                    _reloadProducts();
                  }
                },
                child: _buildTextField("Return Date", TextEditingController(text: DateFormat('dd/MM/yyyy').format(_returnDate)), enabled: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _validUntil,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (context, child) => _buildDatePickerTheme(child!),
                  );
                  if (date != null) setState(() => _validUntil = date);
                },
                child: _buildTextField("Valid Until", TextEditingController(text: DateFormat('dd/MM/yyyy').format(_validUntil)), enabled: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField("Internal / Special Notes", _notesController, maxLines: 3, focusNode: _notesFocusNode),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, bool enabled = true, int maxLines = 1, FocusNode? focusNode, TextInputAction? textInputAction}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? " *" : ""),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: "Enter $label...",
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.w400),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCCCCCC), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryMaroon, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: required ? (v) => v!.isEmpty ? "This field is required" : null : null,
          textInputAction: textInputAction,
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryMaroon,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text("Product / Service", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13))),
                Expanded(child: Text("Qty", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13))),
                Expanded(child: Text("Rate", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13))),
                Expanded(child: Text("Days", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13))),
                Expanded(child: Text("Event", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13))),
                Expanded(child: Text("Total", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13))),
                SizedBox(width: 30),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.productName ?? "Product",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            if (item.rentedFromPartner)
                              Consumer<VendorProvider>(
                                builder: (context, provider, _) {
                                  final vendor = provider.vendors.where((v) => v.id == item.partner).firstOrNull;
                                  return Text("Partner: ${vendor?.name ?? 'Unknown'}",
                                      style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold));
                                },
                              )
                            else
                              const Text("Internal Stock", style: TextStyle(fontSize: 9, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildInlineField(
                          item.quantity.toString(),
                          (v) => _updateItem(index, quantity: int.tryParse(v)),
                          validator: (v) {
                            if (v == null || v.isEmpty) return "";
                            final qty = int.tryParse(v);
                            if (qty == null || qty <= 0) return "";
                            if (!item.rentedFromPartner && item.availableStock != null && qty > item.availableStock!) return "Error";
                            return null;
                          },
                        ),
                      ),
                      Expanded(child: _buildInlineField(item.rate.toString(), (v) => _updateItem(index, rate: double.tryParse(v)))),
                      Expanded(
                        child: item.pricingType == 'PER_DAY'
                            ? _buildInlineField(item.days.toString(), (v) => _updateItem(index, days: int.tryParse(v)))
                            : const Center(child: Text("-", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                      ),
                      Expanded(
                        child: item.pricingType == 'PER_EVENT'
                            ? _buildInlineField(item.days.toString(), (v) => _updateItem(index, days: int.tryParse(v)))
                            : const Center(child: Text("-", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                      ),
                      Expanded(
                        child: Text(
                          "Rs. ${item.total.toStringAsFixed(0)}",
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primaryMaroon),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _items.removeAt(index)),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.remove_circle_outline, color: Colors.red.shade400, size: 18),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: _addItem, 
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryMaroon), 
              label: const Text("Add Product / Service", style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryMaroon)),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon.withOpacity(0.05),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineField(String value, Function(String) onChanged, {String? Function(String?)? validator}) {
    return _InlineTextField(
      initialValue: value,
      onChanged: onChanged,
      validator: validator,
    );
  }

  void _updateItem(int index, {int? quantity, double? rate, int? days}) {
    setState(() {
      final item = _items[index];
      final newQty = quantity ?? item.quantity;
      final newRate = rate ?? item.rate;
      final newDays = days ?? item.days;
      final pricingType = item.pricingType ?? 'PER_DAY';
      
      _items[index] = QuotationItemModel(
        product: item.product,
        productName: item.productName,
        quantity: newQty,
        rate: newRate,
        days: newDays,
        pricingType: pricingType,
        rentedFromPartner: item.rentedFromPartner,
        partner: item.partner,
        partnerRate: item.partnerRate,
        availableStock: item.availableStock,
        total: newQty * newRate * newDays,
      );
    });
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.primaryMaroon.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildSummaryRow("Subtotal", "Rs. ${_subtotal.toStringAsFixed(0)}"),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Discount", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              SizedBox(
                width: 130,
                height: 32,
                child: TextFormField(
                  controller: _discountController,
                  onChanged: (v) => setState(() {}),
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  decoration: InputDecoration(
                    prefixText: "Rs. ",
                    prefixStyle: const TextStyle(color: AppTheme.primaryMaroon, fontWeight: FontWeight.bold),
                    hintText: "0",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryMaroon, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _buildSummaryRow("Grand Total", "Rs. ${_total.toStringAsFixed(0)}", isBold: true, fontSize: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, double fontSize = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: fontSize)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: fontSize, color: isBold ? AppTheme.primaryMaroon : null)),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Cancel Button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "CANCEL",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        // Save Button
        Consumer<QuotationProvider>(
          builder: (context, provider, _) {
            return ElevatedButton.icon(
              onPressed: provider.isLoading ? null : _submit,
              icon: provider.isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                provider.isLoading ? "SAVING..." : "GENERATE QUOTE",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ManualItemEntryDialog extends StatefulWidget {
  final DateTime eventDate;
  final DateTime returnDate;
  final List<QuotationItemModel> currentItems;

  const _ManualItemEntryDialog({
    required this.eventDate,
    required this.returnDate,
    required this.currentItems,
  });

  @override
  State<_ManualItemEntryDialog> createState() => _ManualItemEntryDialogState();
}

class _ManualItemEntryDialogState extends State<_ManualItemEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode(); // Required when textEditingController is provided
  late TextEditingController _quantityController;
  final _rateController = TextEditingController();
  late TextEditingController _daysController;
  String _pricingType = 'PER_DAY';
  String? _selectedProductId;
  int? _maxAvailableQuantity;
  String? _selectedProductName;
  String? _stockWarning;
  bool _rentedFromPartner = false;
  String? _selectedPartnerId;
  final _partnerRateController = TextEditingController();
  String? _submitError;
  
  // Focus Nodes
  final _quantityFocusNode = FocusNode();
  final _rateFocusNode = FocusNode();
  final _daysFocusNode = FocusNode();
  final _partnerRateFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: "1");
    // Calculate initial days from the selected dates
    final duration = widget.returnDate.difference(widget.eventDate).inDays;
    _daysController = TextEditingController(text: (duration > 0 ? duration : 1).toString());

    _quantityController.addListener(_validateStock);
  }

  int _calculateAlreadyAllocated(String? productId) {
    if (productId == null) return 0;
    return widget.currentItems
        .where((item) => item.product == productId)
        .fold(0, (sum, item) => sum + item.quantity);
  }

  void _validateStock() {
    if (_rentedFromPartner) {
      setState(() => _stockWarning = null);
      return;
    }
    final qtyStr = _quantityController.text;
    if (qtyStr.isEmpty) {
      setState(() => _stockWarning = null);
      return;
    }
    
    final qty = int.tryParse(qtyStr);
    if (qty != null && _maxAvailableQuantity != null && qty > _maxAvailableQuantity!) {
      setState(() => _stockWarning = "Inventory contains only $_maxAvailableQuantity. You will need to purchase more.");
    } else {
      setState(() => _stockWarning = null);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _daysController.dispose();
    _partnerRateController.dispose();
    _quantityFocusNode.dispose();
    _rateFocusNode.dispose();
    _daysFocusNode.dispose();
    _partnerRateFocusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedProductId == null) {
        setState(() {
          _submitError = "Error: Item not found. Please select an existing item from the dropdown list.";
        });
        return;
      }
      setState(() => _submitError = null);

      final quantity = int.parse(_quantityController.text);
      final rate = double.parse(_rateController.text);
      final days = _pricingType == 'PER_DAY' ? int.parse(_daysController.text) : 1;
      final availableQty = _maxAvailableQuantity ?? 0;
      
      List<Map<String, dynamic>> items = [];

      // Logic: If partner rental is ON, and we have SOME stock but not enough, split it.
      // Like in Order module: utilize internal stock first if available.
      if (_rentedFromPartner && availableQty > 0 && quantity > availableQty) {
        // Part 1: From Internal Stock
        items.add({
          'product_id': _selectedProductId,
          'name': _nameController.text,
          'quantity': availableQty,
          'rate': rate,
          'days': days,
          'pricing_type': _pricingType,
          'rented_from_partner': false,
          'partner': null,
          'partner_rate': 0.0,
          'available_stock': _maxAvailableQuantity,
        });

        // Part 2: From Partner
        items.add({
          'product_id': _selectedProductId,
          'name': _nameController.text,
          'quantity': quantity - availableQty,
          'rate': rate,
          'days': days,
          'pricing_type': _pricingType,
          'rented_from_partner': true,
          'partner': _selectedPartnerId,
          'partner_rate': double.tryParse(_partnerRateController.text) ?? 0.0,
          'available_stock': _maxAvailableQuantity,
        });
      } else {
        // Single item (either all internal, or all partner if rentedFromPartner is on but stock is 0 or sufficient)
        items.add({
          'product_id': _selectedProductId,
          'name': _nameController.text,
          'quantity': quantity,
          'rate': rate,
          'days': days,
          'pricing_type': _pricingType,
          'rented_from_partner': _rentedFromPartner,
          'partner': _selectedPartnerId,
          'partner_rate': double.tryParse(_partnerRateController.text) ?? 0.0,
          'available_stock': _maxAvailableQuantity,
        });
      }

      Navigator.pop(context, items);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(maxHeight: 80.h),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Add Item / Service", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
              const SizedBox(height: 24),

              // ── Item Name with Autocomplete ──
              const Text("Item Name *", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 8),
              Autocomplete<ProductModel>(
                textEditingController: _nameController,
                focusNode: _nameFocusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<ProductModel>.empty();
                  }
                  
                  final productProvider = context.read<ProductProvider>();
                  productProvider.searchProducts(textEditingValue.text);
                  return productProvider.products.where((product) =>
                      product.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                    displayStringForOption: (ProductModel option) => option.name,
                    onSelected: (ProductModel selection) {
                      setState(() {
                        _selectedProductId = selection.id;
                        _submitError = null; // Automatically hide the error!
                        // Subtract already added items from the available stock
                        final rawStock = selection.dateAvailableQuantity ?? selection.quantityAvailable;
                        final alreadyAllocated = _calculateAlreadyAllocated(selection.id);
                        _maxAvailableQuantity = (rawStock - alreadyAllocated).clamp(0, 999999);
                        
                        _selectedProductName = selection.name;
                        _nameController.text = selection.name;
                        // Auto-fill rate from product price
                        _rateController.text = selection.price.toStringAsFixed(0);
                        _pricingType = selection.pricingType ?? 'PER_DAY';
                        _validateStock();
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (val) {
                          if (_selectedProductName != null && val != _selectedProductName) {
                            setState(() {
                              _selectedProductId = null;
                              _maxAvailableQuantity = null;
                              _selectedProductName = null;
                              _stockWarning = null;
                            });
                          }
                        },
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                        decoration: InputDecoration(
                          hintText: "e.g., LED Screen 10x10",
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                          suffixIcon: const Tooltip(
                            message: "Type to search existing products",
                            child: Icon(Icons.search, color: Colors.grey, size: 18),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.primaryMaroon, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Item name is required";
                          return null;
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Theme(
                          data: ThemeData(
                            brightness: Brightness.light,
                            textTheme: const TextTheme(
                              bodyLarge: TextStyle(color: Colors.black87),
                              bodyMedium: TextStyle(color: Colors.black87),
                              titleMedium: TextStyle(color: Colors.black87),
                            ),
                          ),
                          child: Material(
                            elevation: 8.0,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 436,
                                maxHeight: 220,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return InkWell(
                                    borderRadius: index == 0
                                        ? const BorderRadius.vertical(top: Radius.circular(10))
                                        : index == options.length - 1
                                            ? const BorderRadius.vertical(bottom: Radius.circular(10))
                                            : BorderRadius.zero,
                                    onTap: () => onSelected(option),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: index != options.length - 1
                                            ? Border(bottom: BorderSide(color: Colors.grey.shade100))
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryMaroon.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.inventory_2_outlined,
                                                size: 16, color: AppTheme.primaryMaroon),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  option.name,
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (option.categoryName != null && option.categoryName!.isNotEmpty)
                                                  Text(
                                                    option.categoryName!,
                                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "Rs ${option.price.toStringAsFixed(0)}",
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },

                  ),

              if (_submitError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_submitError!, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
                ),

              if (_selectedProductId != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (_maxAvailableQuantity ?? 0) > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: (_maxAvailableQuantity ?? 0) > 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (_maxAvailableQuantity ?? 0) > 0 ? Icons.check_circle_outline : Icons.error_outline,
                        size: 16,
                        color: (_maxAvailableQuantity ?? 0) > 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Available in Stock: ${_maxAvailableQuantity ?? 0}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: (_maxAvailableQuantity ?? 0) > 0 ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Pricing Basis (FIRST — defines how rate is calculated) ──
              const SizedBox(height: 16),
              const Text("Pricing Basis", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
              const SizedBox(height: 4),
              Text(
                _pricingType == 'PER_DAY'
                  ? "Per Day: Total = Qty × Rate × Days"
                  : "Per Event: Total = Qty × Rate (flat, one-time)",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _pricingType = 'PER_DAY'),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _pricingType == 'PER_DAY' ? AppTheme.primaryMaroon.withOpacity(0.1) : Colors.grey.shade50,
                          border: Border.all(
                            color: _pricingType == 'PER_DAY' ? AppTheme.primaryMaroon : Colors.grey.shade300,
                            width: _pricingType == 'PER_DAY' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 15,
                                    color: _pricingType == 'PER_DAY' ? AppTheme.primaryMaroon : Colors.grey),
                                const SizedBox(width: 6),
                                Text("Per Day",
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700,
                                      color: _pricingType == 'PER_DAY' ? AppTheme.primaryMaroon : Colors.grey.shade700,
                                    )),
                                if (_pricingType == 'PER_DAY') ...[
                                  const Spacer(),
                                  Icon(Icons.check_circle_rounded, size: 15, color: AppTheme.primaryMaroon),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text("Charged daily × days",
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _pricingType = 'PER_EVENT'),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _pricingType == 'PER_EVENT' ? AppTheme.primaryMaroon.withOpacity(0.1) : Colors.grey.shade50,
                          border: Border.all(
                            color: _pricingType == 'PER_EVENT' ? AppTheme.primaryMaroon : Colors.grey.shade300,
                            width: _pricingType == 'PER_EVENT' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.event_rounded, size: 15,
                                    color: _pricingType == 'PER_EVENT' ? AppTheme.primaryMaroon : Colors.grey),
                                const SizedBox(width: 6),
                                Text("Per Event",
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700,
                                      color: _pricingType == 'PER_EVENT' ? AppTheme.primaryMaroon : Colors.grey.shade700,
                                    )),
                                if (_pricingType == 'PER_EVENT') ...[
                                  const Spacer(),
                                  Icon(Icons.check_circle_rounded, size: 15, color: AppTheme.primaryMaroon),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text("Flat rate, whole event",
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Quantity + Rate ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          "Quantity *",
                          _quantityController,
                          "1",
                          isNumber: true,
                          required: true,
                          focusNode: _quantityFocusNode,
                          textInputAction: TextInputAction.next,
                          customValidator: (v) {
                            if (v == null || v.isEmpty) return "Required";
                            final qty = int.tryParse(v);
                            if (qty == null) return "Invalid";
                            if (qty <= 0) return "Must be > 0";
                            if (!_rentedFromPartner && _maxAvailableQuantity != null && qty > _maxAvailableQuantity!) {
                              return "Only $_maxAvailableQuantity available";
                            }
                            return null;
                          },
                        ),
                        if (_stockWarning != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_stockWarning!,
                                style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildField(
                      _pricingType == 'PER_DAY' ? "Rate / Day *" : "Rate / Event *",
                      _rateController,
                      "5000",
                      isNumber: true,
                      required: true,
                      focusNode: _rateFocusNode,
                      textInputAction: _pricingType == 'PER_DAY' ? TextInputAction.next : (_rentedFromPartner ? TextInputAction.next : TextInputAction.done),
                      onSubmitted: () {
                        if (_pricingType == 'PER_DAY') {
                          FocusScope.of(context).requestFocus(_daysFocusNode);
                        } else if (_rentedFromPartner) {
                          // If partner switch is on but dropdown is used, we might need more logic, 
                          // but usually next is fine
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_pricingType == 'PER_DAY') ...[
                const SizedBox(height: 16),
                _buildField("Number of Days *", _daysController, "1", 
                  isNumber: true, 
                  required: true,
                  focusNode: _daysFocusNode,
                  textInputAction: _rentedFromPartner ? TextInputAction.next : TextInputAction.done,
                ),
              ],
              
              // ── Partner Selection ──
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Rented from Partner?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text("Mark this if item is a sub-rental", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  Switch(
                    value: _rentedFromPartner,
                    activeColor: AppTheme.primaryMaroon,
                    onChanged: (v) {
                      setState(() {
                        _rentedFromPartner = v;
                        _validateStock();
                      });
                    },
                  ),
                ],
              ),
              
              if (_rentedFromPartner) ...[
                const SizedBox(height: 16),
                Consumer<VendorProvider>(
                  builder: (context, vendorProvider, _) {
                    return PremiumDropdownField<String>(
                      label: 'Select Partner Vendor *',
                      hint: 'Choose a vendor',
                      items: vendorProvider.vendors
                          .map((v) => DropdownItem<String>(
                              value: v.id,
                              label: v.name
                          ))
                          .toList(),
                      value: _selectedPartnerId,
                      onChanged: (id) => setState(() => _selectedPartnerId = id),
                      prefixIcon: Icons.handshake_outlined,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildField("Partner Rate (Cost) *", _partnerRateController, "4000", 
                  isNumber: true, 
                  required: true,
                  focusNode: _partnerRateFocusNode,
                  textInputAction: TextInputAction.done,
                ),
              ],
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCEL", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text("ADD ITEM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B61FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildField(String label, TextEditingController controller, String hint, {bool isNumber = false, bool required = false, String? Function(String?)? customValidator, FocusNode? focusNode, TextInputAction? textInputAction, VoidCallback? onSubmitted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryMaroon, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          focusNode: focusNode,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
          validator: customValidator ?? (v) {
            if (required && (v == null || v.isEmpty)) return "This field is required";
            if (isNumber && v != null && v.isNotEmpty) {
              if (double.tryParse(v) == null) return "Enter a valid number";
              if (double.parse(v) <= 0) return "Must be greater than 0";
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _InlineTextField extends StatefulWidget {
  final String initialValue;
  final Function(String) onChanged;
  final String? Function(String?)? validator;

  const _InlineTextField({
    required this.initialValue,
    required this.onChanged,
    this.validator,
  });

  @override
  State<_InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<_InlineTextField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _InlineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != _controller.text) {
      // Preserve selection position if we sync external text change
      final oldSelection = _controller.selection;
      _controller.text = widget.initialValue;
      if (oldSelection.isValid && oldSelection.end <= _controller.text.length) {
        _controller.selection = oldSelection;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: 32,
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          keyboardType: TextInputType.number,
          validator: widget.validator,
          autovalidateMode: AutovalidateMode.always,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppTheme.primaryMaroon)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.red, width: 2)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.red, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          ),
        ),
      ),
    );
  }
}
