import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/models/sales/request_models.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/services/product_service.dart';
import '../../../src/services/sale_item_service.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class LocalSaleItem {
  final String? saleItemId;
  final String productId;
  final String productName;
  final String? categoryName;
  double unitPrice;
  int quantity;
  double itemDiscount;
  bool isDeleted;
  bool isNew;

  LocalSaleItem({
    this.saleItemId,
    required this.productId,
    required this.productName,
    this.categoryName,
    required this.unitPrice,
    required this.quantity,
    this.itemDiscount = 0.0,
    this.isDeleted = false,
    this.isNew = false,
  });

  double get total => (unitPrice * quantity) - itemDiscount;
}

class EditSaleDialog extends StatefulWidget {
  final SaleModel sale;

  const EditSaleDialog({super.key, required this.sale});

  @override
  State<EditSaleDialog> createState() => _EditSaleDialogState();
}

class _EditSaleDialogState extends State<EditSaleDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountPaidController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  final List<LocalSaleItem> _localItems = [];
  List<ProductModel> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  String _selectedPaymentMethod = 'Cash';
  String _selectedStatus = 'Paid';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();

    for (var item in widget.sale.saleItems) {
      _localItems.add(LocalSaleItem(
        saleItemId: item.id,
        productId: item.productId,
        productName: item.productName,
        categoryName: item.categoryName, // Assuming this is available
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        itemDiscount: item.itemDiscount,
      ));
    }

    _amountPaidController.text = widget.sale.amountPaid.toStringAsFixed(0);
    _notesController.text = widget.sale.notes ?? '';
    _selectedPaymentMethod = widget.sale.paymentMethod ?? 'CASH';
    _selectedStatus = widget.sale.status ?? 'DRAFT';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  double get _calculatedSubtotal => _localItems.where((i) => !i.isDeleted).fold(0.0, (sum, item) => sum + item.total);
  int get _totalActiveQuantity => _localItems.where((i) => !i.isDeleted).fold(0, (sum, item) => sum + item.quantity);
  int get _totalActiveItems => _localItems.where((i) => !i.isDeleted).length;

  double get _calculatedGrandTotal => _calculatedSubtotal - widget.sale.overallDiscount + widget.sale.taxAmount;
  double get _remainingAmount {
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    return _calculatedGrandTotal - amountPaid;
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() { _searchResults = []; _isSearching = false; });
        return;
      }
      setState(() => _isSearching = true);
      try {
        final response = await ProductService().searchProducts(query: query);
        if (response.success && response.data != null) {
          setState(() { _searchResults = response.data!.products; });
        }
      } finally {
        setState(() => _isSearching = false);
      }
    });
  }

  void _addProduct(ProductModel product) {
    setState(() {
      final existingIndex = _localItems.indexWhere((i) => i.productId == product.id && !i.isDeleted);
      if (existingIndex != -1) {
        _localItems[existingIndex].quantity += 1;
      } else {
        _localItems.add(LocalSaleItem(
          productId: product.id,
          productName: product.name,
          categoryName: product.categoryName,
          unitPrice: product.price,
          quantity: 1,
          isNew: true,
        ));
      }
      _searchController.clear();
      _searchResults = [];
    });
  }

  void _handleUpdate() async {
    if (_formKey.currentState?.validate() ?? false) {
      final provider = Provider.of<SalesProvider>(context, listen: false);
      final saleItemService = SaleItemService();

      try {
        for (var item in _localItems.where((i) => i.isDeleted && i.saleItemId != null)) {
          await saleItemService.deleteSaleItem(item.saleItemId!);
        }
        for (var item in _localItems.where((i) => !i.isDeleted && !i.isNew && i.saleItemId != null)) {
          await saleItemService.updateSaleItem(item.saleItemId!, UpdateSaleItemRequest(
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            itemDiscount: item.itemDiscount,
          ));
        }
        for (var item in _localItems.where((i) => !i.isDeleted && i.isNew)) {
          await saleItemService.createSaleItem(CreateSaleItemRequest(
            saleId: widget.sale.id,
            productId: item.productId,
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            itemDiscount: item.itemDiscount,
          ));
        }
        await provider.updateSale(widget.sale.id, UpdateSaleRequest(
          paymentMethod: _selectedPaymentMethod,
          status: _selectedStatus,
          notes: _notesController.text,
        ));
        if (mounted) {
          // Get the updated sale from the provider
          final updatedSale = provider.sales.firstWhere((s) => s.id == widget.sale.id);
          
          Navigator.of(context).pop(); // Close edit dialog
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => OrderSuccessDialog(
              sale: updatedSale,
            ),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          body: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 90.w,
                height: 92.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF7FF), // Subtle lavender tint background
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    _buildTopHeader(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Table Area
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  _buildProductSearchInput(),
                                  const SizedBox(height: 16),
                                  _buildItemsTableContainer(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right Side Summary & Payment
                            Expanded(
                              flex: 1,
                              child: _buildRightSummaryPanel(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomActions(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart_outlined, color: Color(0xFF8B2252), size: 32),
          const SizedBox(width: 12),
          const Text(
            'Order Items',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_totalActiveItems items · Qty: $_totalActiveQuantity',
              style: const TextStyle(color: Color(0xFF8B2252), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSearchInput() {
    return Column(
      children: [
        PremiumTextField(
          controller: _searchController,
          hint: 'Search products to add...',
          prefixIcon: Icons.search,
          onChanged: _onSearchChanged,
        ),
        if (_isSearching) const LinearProgressIndicator(),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            maxHeight: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final p = _searchResults[index];
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text('PKR ${p.price}'),
                  trailing: const Icon(Icons.add_circle, color: Color(0xFF8B2252)),
                  onTap: () => _addProduct(p),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildItemsTableContainer() {
    final activeItems = _localItems.where((i) => !i.isDeleted).toList();

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3E5F5)),
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F0FA),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                  Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('Rent Price', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.end)),
                  SizedBox(width: 40),
                ],
              ),
            ),
            // Table Body with Always Visible Scrollbar
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                thickness: 8,
                radius: const Radius.circular(4),
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  itemCount: activeItems.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final item = activeItems[index];
                    return _buildTableItemRow(item);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableItemRow(LocalSaleItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Product Name & Category Badge
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (item.categoryName != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.categoryName!,
                      style: const TextStyle(fontSize: 10, color: Color(0xFFD32F2F), fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          // Editable Qty
          Expanded(
            flex: 1,
            child: _buildTransparentInput(
              value: item.quantity.toString(),
              color: const Color(0xFF2196F3),
              onChanged: (v) => setState(() => item.quantity = int.tryParse(v) ?? 0),
            ),
          ),
          // Editable Rent Price
          Expanded(
            flex: 2,
            child: _buildTransparentInput(
              value: item.unitPrice.toStringAsFixed(0),
              color: const Color(0xFF2196F3),
              onChanged: (v) => setState(() => item.unitPrice = double.tryParse(v) ?? 0.0),
              showCurrency: true,
            ),
          ),
          // Total (Red)
          Expanded(
            flex: 2,
            child: Text(
              'PKR ${item.total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD32F2F), fontSize: 16),
              textAlign: TextAlign.end,
            ),
          ),
          // Remove Action
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => setState(() => item.isDeleted = true),
          ),
        ],
      ),
    );
  }

  Widget _buildTransparentInput({required String value, required Color color, required Function(String) onChanged, bool showCurrency = false}) {
    return TextFormField(
      initialValue: value,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
      decoration: InputDecoration(
        border: InputBorder.none,
        prefixText: showCurrency ? ' ' : null,
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildRightSummaryPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3E5F5)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            _buildDropdownField('Payment Method', _selectedPaymentMethod, ['Cash', 'Card', 'Bank Transfer', 'Credit'], (v) => setState(() => _selectedPaymentMethod = v!)),
            const SizedBox(height: 16),
            PremiumTextField(
              label: 'Amount Paid',
              controller: _amountPaidController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            PremiumTextField(
              label: 'Order Notes',
              controller: _notesController,
              maxLines: 3,
            ),
            const Spacer(),
            const Divider(),
            const SizedBox(height: 16),
            _buildSummaryRow('Subtotal', 'PKR ${_calculatedSubtotal.toStringAsFixed(0)}'),
            _buildSummaryRow('Discount', '- PKR ${widget.sale.overallDiscount.toStringAsFixed(0)}'),
            _buildSummaryRow('Tax', '+ PKR ${widget.sale.taxAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            _buildSummaryRow('Grand Total', 'PKR ${_calculatedGrandTotal.toStringAsFixed(0)}', isBold: true, color: const Color(0xFF8B2252)),
            const SizedBox(height: 8),
            _buildSummaryRow(_remainingAmount > 0 ? 'Remaining' : 'Change', 'PKR ${_remainingAmount.abs().toStringAsFixed(0)}', color: _remainingAmount > 0 ? Colors.red : Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? Colors.black : Colors.grey, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: color ?? Colors.black, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Discard Changes', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 200,
            child: PremiumButton(
              text: 'Update Sale Order',
              onPressed: _handleUpdate,
              icon: Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }
}
