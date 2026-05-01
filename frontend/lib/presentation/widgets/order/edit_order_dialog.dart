import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../widgets/globals/confirmation_dialog.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/order/order_model.dart';
import '../../../src/models/order/order_item_model.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/models/vendor/vendor_model.dart';
import '../../../src/providers/order_provider.dart';
import '../../../src/providers/customer_provider.dart' as cp;
import '../../../src/services/product_service.dart';
import '../../../src/services/order_item_service.dart';
import '../../../src/services/vendor/vendor_service.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../globals/custom_date_picker.dart';
import '../product/add_product_dialog.dart';

class LocalOrderItem {
  final String? id;
  final String productId;
  final String productName;
  final String? categoryName;
  double rate;
  int quantity;
  int days;
  bool isDeleted;
  bool isNew;
  bool rentedFromPartner;
  int? currentStock;
  String? partnerId;
  double? partnerRate;
  int partnerQuantity; // only the excess from partner

  LocalOrderItem({
    this.id,
    required this.productId,
    required this.productName,
    this.categoryName,
    required this.rate,
    required this.quantity,
    this.days = 1,
    this.isDeleted = false,
    this.isNew = false,
    this.rentedFromPartner = false,
    this.currentStock,
    this.partnerId,
    this.partnerRate,
    this.partnerQuantity = 0,
  });

  double get total => rate * quantity * days;
  bool get isOutOfStock => !rentedFromPartner && currentStock != null && currentStock! < quantity;
}

class EditOrderDialog extends StatefulWidget {
  final OrderModel order;

  const EditOrderDialog({super.key, required this.order});

  @override
  State<EditOrderDialog> createState() => _EditOrderDialogState();
}

class _EditOrderDialogState extends State<EditOrderDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _advanceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _rightPanelScrollController = ScrollController();
  
  final List<LocalOrderItem> _localItems = [];
  List<ProductModel> _searchResults = [];
  bool _isLoadingItems = false;
  bool _isSearching = false;
  bool _isSaving = false;
  Timer? _searchDebounce;

  OrderStatus _selectedStatus = OrderStatus.PENDING;
  DateTime? _selectedDeliveryDate;
  DateTime? _eventDate;
  DateTime? _dispatchDate;
  DateTime? _returnDate;
  cp.Customer? _customer;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    debugPrint('EditOrderDialog: Initializing for Order ${widget.order.id}');
    debugPrint('EditOrderDialog: Order Event Date: ${widget.order.eventDate}');
    debugPrint('EditOrderDialog: Order Return Date: ${widget.order.returnDate}');

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();

    _advanceController.text = widget.order.advancePayment.toStringAsFixed(0);
    _descriptionController.text = widget.order.description;
    _selectedStatus = widget.order.status;
    _selectedDeliveryDate = widget.order.expectedDeliveryDate;
    _eventDate = widget.order.eventDate;
    _dispatchDate = widget.order.dispatchDate;
    _returnDate = widget.order.returnDate;

    _loadExistingItems();
    _loadCustomerDetails();
  }

  Future<void> _loadCustomerDetails() async {
    final provider = Provider.of<cp.CustomerProvider>(context, listen: false);
    try {
      final success = await provider.fetchCustomerById(widget.order.customerId);
      if (success && mounted) {
        setState(() => _customer = provider.selectedCustomer);
      }
    } catch (e) {
      debugPrint('Error loading customer: $e');
    }
  }

  Future<void> _loadExistingItems() async {
    if (!mounted) return;
    setState(() => _isLoadingItems = true);
    try {
      final itemService = OrderItemService();
      await itemService.clearCache();
      final response = await itemService.getOrderItems(orderId: widget.order.id, pageSize: 100);
      if (response.success && response.data != null) {
        if (!mounted) return;
        setState(() {
          _localItems.clear();
          for (var item in response.data!.orderItems) {
            _localItems.add(LocalOrderItem(
              id: item.id,
              productId: item.productId,
              productName: item.productName,
              categoryName: item.productCategory,
              rate: item.rate,
              quantity: item.quantity,
              days: item.days,
              rentedFromPartner: item.rentedFromPartner,
              currentStock: item.currentStock,
              partnerId: item.partnerId,
              partnerRate: item.partnerRate,
              partnerQuantity: item.partnerQuantity ?? 0,
            ));
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _advanceController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _rightPanelScrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  double get _calculatedSubtotal => _localItems.where((i) => !i.isDeleted).fold(0.0, (sum, item) => sum + item.total);
  int get _totalActiveQuantity => _localItems.where((i) => !i.isDeleted).fold(0, (sum, item) => sum + item.quantity);
  int get _totalActiveItems => _localItems.where((i) => !i.isDeleted).length;

  double get _remainingAmount {
    final advance = double.tryParse(_advanceController.text) ?? 0.0;
    return _calculatedSubtotal - advance;
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
        _localItems.add(LocalOrderItem(
          productId: product.id,
          productName: product.name,
          categoryName: product.categoryName,
          rate: product.price,
          quantity: 1,
          isNew: true,
        ));
      }
      _searchController.clear();
      _searchResults = [];
    });
  }

  /// Check stock for each item. If quantity exceeds stock, ask user whether
  /// to rent the excess from a partner. Returns false if user cancels.
  Future<bool> _checkStockAndConfirm() async {
    for (final item in _localItems.where((i) => !i.isDeleted)) {
      if (item.currentStock == null) continue;
      if (item.rentedFromPartner) continue;

      final stock = item.currentStock!;
      if (item.quantity > stock) {
        final extra = item.quantity - stock;

        // Step 1: Stock warning
        final wantsPartner = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Stock Khatam!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                    children: [
                      TextSpan(text: item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const TextSpan(text: ' ki apni inventory mein sirf '),
                      TextSpan(text: '$stock', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B2252))),
                      const TextSpan(text: ' baqi hai.\n\nAap ny '),
                      TextSpan(text: '${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const TextSpan(text: ' manga hai — baqi '),
                      TextSpan(text: '$extra', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const TextSpan(text: ' partner se leni paregi.'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B2252),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.handshake_outlined, size: 18),
                    label: const Text('Haan, Partner Se Lo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Nahi, Cancel Karo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        );

        if (wantsPartner != true) return false;

        // Step 2: Partner selection dialog
        final partnerResult = await _showPartnerSelectionDialog(item.productName, extra);
        if (partnerResult == null) return false;

        setState(() {
          item.rentedFromPartner = true;
          item.partnerId = partnerResult['vendorId'] as String;
          item.partnerRate = partnerResult['rate'] as double;
          item.partnerQuantity = extra; // only the excess, not full quantity
        });
      }
    }
    return true;
  }

  /// Shows a dialog to select which vendor/partner and at what rate.
  Future<Map<String, dynamic>?> _showPartnerSelectionDialog(String productName, int quantity) async {
    List<VendorModel> vendors = [];
    VendorModel? selectedVendor;
    final rateController = TextEditingController();
    bool isLoading = true;

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            // Load vendors once
            if (isLoading) {
              VendorService().getVendors().then((res) {
                if (res.success && res.data != null) {
                  setDlgState(() {
                    vendors = res.data!.vendors;
                    isLoading = false;
                  });
                } else {
                  setDlgState(() => isLoading = false);
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF8B2252).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.handshake_outlined, color: Color(0xFF8B2252), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Partner Select Karein', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: Colors.blue, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$productName — $quantity partner se lena hai',
                              style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Partner / Vendor:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : vendors.isEmpty
                            ? const Text('Koi vendor nahi mila', style: TextStyle(color: Colors.red))
                            : DropdownButtonFormField<VendorModel>(
                                value: selectedVendor,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  hintText: 'Partner chuniye...',
                                ),
                                items: vendors.map((v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v.displayName, overflow: TextOverflow.ellipsis),
                                )).toList(),
                                onChanged: (v) => setDlgState(() => selectedVendor = v),
                              ),
                    const SizedBox(height: 14),
                    const Text('Partner Ka Rate (PKR):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Partner Ka Rate',
                        hintText: '500',
                        prefixIcon: Center(
                          widthFactor: 1.0,
                          child: Text(
                            'PKR',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              fontFamily: null, // system default font
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF8B2252), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (selectedVendor == null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Partner select karein'), backgroundColor: Colors.orange),
                            );
                            return;
                          }
                          final rate = double.tryParse(rateController.text);
                          if (rate == null || rate <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Rate sahi likhein'), backgroundColor: Colors.orange),
                            );
                            return;
                          }
                          Navigator.of(ctx).pop({'vendorId': selectedVendor!.id, 'rate': rate});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B2252),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Confirm & Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(null),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleUpdate() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Stock check first — show warning dialog if needed
      final canProceed = await _checkStockAndConfirm();
      if (!canProceed) return;

      setState(() => _isSaving = true);
      final provider = Provider.of<OrderProvider>(context, listen: false);
      final itemService = OrderItemService();

      try {
        // Track successes/failures
        int successCount = 0;
        int failCount = 0;
        String errorMessage = '';

        // 1. Sync Items
        for (var item in _localItems.where((i) => i.isDeleted && i.id != null)) {
          final res = await itemService.deleteOrderItem(item.id!);
          if (res.success) successCount++; else { failCount++; errorMessage = res.message; }
        }
        for (var item in _localItems.where((i) => !i.isDeleted && !i.isNew && i.id != null)) {
          final res = await itemService.updateOrderItem(
            id: item.id!,
            orderId: widget.order.id,
            quantity: item.quantity,
            unitPrice: item.rate,
            rentedFromPartner: item.rentedFromPartner,
            partnerId: item.partnerId,
            partnerRate: item.partnerRate,
            partnerQuantity: item.partnerQuantity > 0 ? item.partnerQuantity : null,
          );
          if (res.success) successCount++; else { failCount++; errorMessage = res.message; }
        }
        for (var item in _localItems.where((i) => !i.isDeleted && i.isNew)) {
          final res = await itemService.createOrderItem(
            orderId: widget.order.id,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.rate,
            rentedFromPartner: item.rentedFromPartner,
            partnerId: item.partnerId,
            partnerRate: item.partnerRate,
            partnerQuantity: item.partnerQuantity > 0 ? item.partnerQuantity : null,
          );
          if (res.success) successCount++; else { failCount++; errorMessage = res.message; }
        }

        // 2. Update Order Metadata
        final success = await provider.updateOrder(
          id: widget.order.id,
          advancePayment: double.tryParse(_advanceController.text) ?? 0.0,
          description: _descriptionController.text,
          status: _selectedStatus.name.toUpperCase(),
          expectedDeliveryDate: _selectedDeliveryDate,
          eventDate: _eventDate,
          dispatchDate: _dispatchDate ?? _eventDate,
          returnDate: _returnDate,
        );

        if (success && failCount == 0 && mounted) {
          // Success!
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order & Items Updated Successfully'), 
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            )
          );
          Navigator.of(context).pop(true); // Return true to trigger refresh
        } else if (mounted) {
          // Some items failed or metadata failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failCount > 0 
                ? 'Item Sync Issues: $errorMessage ($failCount failed)' 
                : 'Metadata Update Failed'), 
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            )
          );
          // Still might want to refresh if some things succeeded
          if (successCount > 0) {
             provider.refreshOrders(); // Correct method name
          }
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update Error: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isSaving = false);
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
                width: 95.w,
                height: 90.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF7FF),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 30, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    _buildTopHeader(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Items Table
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  _buildSearchInput(),
                                  const SizedBox(height: 12),
                                  _buildItemsTableHeader(),
                                  Expanded(child: _buildItemsTableBody()),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Right Summary Panel
                            Expanded(
                              flex: 3,
                              child: _buildRightPanel(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildFooterActions(),
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
    final String displayName = (_customer?.businessName != null && _customer!.businessName!.isNotEmpty)
        ? _customer!.businessName!
        : widget.order.customerName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF8B2252).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.edit_note_rounded, color: Color(0xFF8B2252), size: 28),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Order #${widget.order.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF2D2D2D)),
              ),
              Text(
                displayName,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B2252).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8B2252).withOpacity(0.2)),
            ),
            child: Text(
              '$_totalActiveItems Items · PKR ${_calculatedSubtotal.toStringAsFixed(0)}',
              style: const TextStyle(color: Color(0xFF8B2252), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.grey),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Column(
      children: [
        PremiumTextField(
          label: '',
          controller: _searchController,
          hint: 'Search products to add...',
          prefixIcon: Icons.search_rounded,
          onChanged: _onSearchChanged,
        ),
        if (_isSearching) const LinearProgressIndicator(minHeight: 2),
        if (_searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final p = _searchResults[index];
                return ListTile(
                  dense: true,
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Price: PKR ${p.price}'),
                  trailing: const Icon(Icons.add_circle_outline, color: Color(0xFF8B2252), size: 20),
                  onTap: () => _addProduct(p),
                );
              },
            ),
          )
        else if (_searchController.text.isNotEmpty && !_isSearching)
          Container(
            margin: const EdgeInsets.only(top: 8),
            child: PremiumButton(
              text: 'Add Products',
              icon: Icons.add_rounded,
              width: 180,
              height: 40,
              onPressed: () async {
                final result = await showDialog<ProductModel>(
                  context: context,
                  builder: (context) => const AddProductDialog(),
                );
                if (result != null) {
                  _addProduct(result);
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildItemsTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F0FA),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('PRODUCT NAME', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey.shade700, fontSize: 11))),
          Expanded(flex: 2, child: Text('QTY', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey.shade700, fontSize: 11), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('RENT PRICE', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey.shade700, fontSize: 11), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey.shade700, fontSize: 11), textAlign: TextAlign.end)),
          const SizedBox(width: 45),
        ],
      ),
    );
  }

  Widget _buildItemsTableBody() {
    final activeItems = _localItems.where((i) => !i.isDeleted).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
        border: Border.all(color: const Color(0xFFF3E5F5)),
      ),
      child: _isLoadingItems
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 10,
              radius: const Radius.circular(5),
              child: ListView.separated(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: activeItems.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  return _buildItemRow(activeItems[index]);
                },
              ),
            ),
    );
  }

  Widget _buildItemRow(LocalOrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D2D2D))),
                if (item.categoryName != null)
                  Text(item.categoryName!, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                if (item.isOutOfStock)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.red.shade200)),
                    child: const Text('LOW STOCK - USE PARTNER?', style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                if (item.rentedFromPartner && item.partnerQuantity > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.amber.shade200)),
                    child: Text('From Partner: ${item.partnerQuantity}', style: const TextStyle(fontSize: 9, color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          // Partner Toggle
          SizedBox(
            width: 45,
            child: Column(
              children: [
                Transform.scale(
                  scale: 0.8,
                  child: Checkbox(
                    value: item.rentedFromPartner,
                    activeColor: const Color(0xFF8B2252),
                    onChanged: (v) async {
                      if (v == true) {
                        // Show partner selection dialog immediately
                        final stock = item.currentStock ?? item.quantity;
                        final extra = item.quantity > stock ? item.quantity - stock : item.quantity;
                        final result = await _showPartnerSelectionDialog(item.productName, extra);
                        if (result == null) return; // user cancelled, don't check
                        setState(() {
                          item.rentedFromPartner = true;
                          item.partnerId = result['vendorId'] as String;
                          item.partnerRate = result['rate'] as double;
                          item.partnerQuantity = extra;
                        });
                      } else {
                        setState(() {
                          item.rentedFromPartner = false;
                          item.partnerId = null;
                          item.partnerRate = null;
                          item.partnerQuantity = 0;
                        });
                      }
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const Text('Partner', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: TextFormField(
                initialValue: item.quantity.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF2196F3)),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2196F3))),
                ),
                onChanged: (v) {
                  setState(() {
                    int newQty = int.tryParse(v) ?? 0;
                    item.quantity = newQty;
                    
                    if (item.rentedFromPartner) {
                      final maxInternalStock = (item.currentStock != null && item.currentStock! > 0) ? item.currentStock! : 0;
                      if (newQty > maxInternalStock) {
                        item.partnerQuantity = newQty - maxInternalStock;
                      } else {
                        item.partnerQuantity = 0;
                      }
                    }
                  });
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: TextFormField(
                initialValue: item.rate.toStringAsFixed(0),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF2196F3)),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2196F3))),
                ),
                onChanged: (v) => setState(() => item.rate = double.tryParse(v) ?? 0.0),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'PKR ${item.total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFD32F2F), fontSize: 14),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
            onPressed: () => setState(() => item.isDeleted = true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3E5F5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Form(
          key: _formKey,
          child: Scrollbar(
            controller: _rightPanelScrollController,
            thumbVisibility: true,
            thickness: 6,
            radius: const Radius.circular(3),
            child: SingleChildScrollView(
              controller: _rightPanelScrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('ORDER DETAILS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF8B2252))),
              const SizedBox(height: 16),
              _buildSmartStatusDropdown(),
              const SizedBox(height: 12),
/*
              const Text('Expected Delivery', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  await context.showSyncfusionDateTimePicker(
                    initialDate: _selectedDeliveryDate ?? DateTime.now(),
                    initialTime: TimeOfDay.now(),
                    title: 'Select Expected Delivery',
                    onDateTimeSelected: (date, time) {
                      setState(() => _selectedDeliveryDate = date);
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF8B2252)),
                      const SizedBox(width: 10),
                      Text(
                        _selectedDeliveryDate == null ? 'Select Date' : '${_selectedDeliveryDate!.day}/${_selectedDeliveryDate!.month}/${_selectedDeliveryDate!.year}',
                        style: TextStyle(color: _selectedDeliveryDate == null ? Colors.grey : Colors.black, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
*/
              const SizedBox(height: 12),
              const Text('Event Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  await context.showSyncfusionDateTimePicker(
                    initialDate: _eventDate ?? DateTime.now(),
                    initialTime: TimeOfDay.now(),
                    title: 'Select Event Date',
                    onDateTimeSelected: (date, time) {
                      setState(() => _eventDate = date);
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available, size: 18, color: Color(0xFF8B2252)),
                      const SizedBox(width: 10),
                      Text(
                        _eventDate == null ? 'Select Date' : '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}',
                        style: TextStyle(color: _eventDate == null ? Colors.grey : Colors.black, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Dispatch Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  await context.showSyncfusionDateTimePicker(
                    initialDate: _dispatchDate ?? _eventDate ?? DateTime.now(),
                    initialTime: TimeOfDay.now(),
                    title: 'Select Dispatch Date',
                    onDateTimeSelected: (date, time) {
                      setState(() => _dispatchDate = date);
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping, size: 18, color: Color(0xFF8B2252)),
                      const SizedBox(width: 10),
                      Text(
                        _dispatchDate == null ? 'Select Date' : '${_dispatchDate!.day}/${_dispatchDate!.month}/${_dispatchDate!.year}',
                        style: TextStyle(color: _dispatchDate == null ? Colors.grey : Colors.black, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Return Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  await context.showSyncfusionDateTimePicker(
                    initialDate: _returnDate ?? (_eventDate ?? DateTime.now()),
                    initialTime: TimeOfDay.now(),
                    title: 'Select Return Date',
                    onDateTimeSelected: (date, time) {
                      setState(() => _returnDate = date);
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_return, size: 18, color: Color(0xFF8B2252)),
                      const SizedBox(width: 10),
                      Text(
                        _returnDate == null ? 'Select Date' : '${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}',
                        style: TextStyle(color: _returnDate == null ? Colors.grey : Colors.black, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PremiumTextField(
                label: 'Advance Payment (PKR)',
                controller: _advanceController,
                keyboardType: TextInputType.number,
                fontSize: 13,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              PremiumTextField(
                label: 'Description / Notes',
                controller: _descriptionController,
                maxLines: 2,
                fontSize: 13,
              ),
              const SizedBox(height: 20),
              const Divider(height: 32),
              _buildSummaryRow('Subtotal', 'PKR ${_calculatedSubtotal.toStringAsFixed(0)}'),
              _buildSummaryRow('Advance Paid', '- PKR ${(double.tryParse(_advanceController.text) ?? 0).toStringAsFixed(0)}'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF8B2252).withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                child: _buildSummaryRow('Balance Due', 'PKR ${_remainingAmount.toStringAsFixed(0)}', isBold: true, color: const Color(0xFF8B2252)),
              ),
            ],
          ),
        ),
        ),
      ),
      ),
    );
  }

  Future<void> _handleDeleteOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ConfirmationDialog(
        title: 'Delete Order',
        message: 'Are you sure you want to delete this order? This action cannot be undone.',
        actionText: 'Delete',
        actionColor: Colors.red,
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isSaving = true);
      try {
        final provider = Provider.of<OrderProvider>(context, listen: false);
        final success = await provider.deleteOrder(widget.order.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order deleted successfully'), backgroundColor: Colors.green));
          Navigator.of(context).pop('deleted');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Failed to delete order'), backgroundColor: Colors.red));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  /// Returns the list of statuses the user is allowed to set,
  /// based on the current order status. RETURNED is never shown.
  List<OrderStatus> _getAllowedStatuses() {
    switch (widget.order.status) {
      case OrderStatus.PENDING:
        return [OrderStatus.PENDING, OrderStatus.CONFIRMED, OrderStatus.CANCELLED];
      case OrderStatus.CONFIRMED:
        // CONFIRMED → can go to READY, or skip straight to DELIVERED, or CANCEL
        return [OrderStatus.CONFIRMED, OrderStatus.READY, OrderStatus.DELIVERED, OrderStatus.CANCELLED];
      case OrderStatus.READY:
        return [OrderStatus.READY, OrderStatus.DELIVERED, OrderStatus.CANCELLED];
      case OrderStatus.DELIVERED:
        return [OrderStatus.DELIVERED]; // final state
      case OrderStatus.CANCELLED:
        return [OrderStatus.CANCELLED]; // final state
      case OrderStatus.RETURNED:
        return [OrderStatus.RETURNED]; // legacy, just show it, do not allow changing
    }
  }

  /// Friendly display labels for each status
  String _statusLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.PENDING:     return 'Pending';
      case OrderStatus.CONFIRMED:   return 'Confirmed';
      case OrderStatus.READY:       return 'Ready';
      case OrderStatus.DELIVERED:   return 'Delivered';
      case OrderStatus.CANCELLED:   return 'Cancelled';
      case OrderStatus.RETURNED:    return 'Returned';
    }
  }

  /// Status color indicator
  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.PENDING:     return Colors.orange;
      case OrderStatus.CONFIRMED:   return Colors.blue;
      case OrderStatus.READY:       return Colors.purple;
      case OrderStatus.DELIVERED:   return Colors.green;
      case OrderStatus.CANCELLED:   return Colors.red;
      case OrderStatus.RETURNED:    return Colors.grey;
    }
  }

  Widget _buildSmartStatusDropdown() {
    final allowed = _getAllowedStatuses();
    // Ensure current selection is valid
    if (!allowed.contains(_selectedStatus)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedStatus = allowed.first);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade50,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<OrderStatus>(
              value: allowed.contains(_selectedStatus) ? _selectedStatus : allowed.first,
              isExpanded: true,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 13),
              items: allowed.map((s) => DropdownMenuItem(
                value: s,
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _statusColor(s),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_statusLabel(s), style: TextStyle(color: _statusColor(s), fontWeight: FontWeight.w700)),
                  ],
                ),
              )).toList(),
              onChanged: allowed.length == 1
                  ? null // disable if only one option (final state)
                  : (s) {
                      if (s != null) setState(() => _selectedStatus = s);
                    },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 13),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? Colors.black : Colors.grey.shade600, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600, fontSize: isBold ? 14 : 13)),
        Text(value, style: TextStyle(color: color ?? Colors.black, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, fontSize: isBold ? 16 : 13)),
      ],
    );
  }

  Widget _buildFooterActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _isSaving ? null : _handleDeleteOrder,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('DELETE ORDER', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
          Row(
            children: [
              TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            child: Text('DISCARD CHANGES', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 220,
            child: PremiumButton(
              text: 'SAVE ORDER CHANGES',
              onPressed: _isSaving ? null : _handleUpdate,
              isLoading: _isSaving,
              icon: Icons.check_circle_rounded,
              backgroundColor: const Color(0xFF8B2252),
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }
}
