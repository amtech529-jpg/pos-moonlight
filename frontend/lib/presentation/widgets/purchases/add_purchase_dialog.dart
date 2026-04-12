import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/models/purchase_model.dart';
import '../../../src/providers/purchase_provider.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/text_field.dart'; // PremiumTextField
import '../globals/drop_down.dart';  // PremiumDropdownField
import '../globals/custom_date_picker.dart'; // SyncfusionDateTimePicker
import '../globals/text_button.dart'; // PremiumButton
import '../vendor/add_vendor_dialog.dart';
import '../product/add_product_dialog.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/models/vendor/vendor_model.dart';
import '../../../src/models/category/category_model.dart'; // ✅ Added import
import '../../../src/services/category_service.dart'; // ✅ Added import
import '../../../src/providers/category_provider.dart'; // ✅ Added import

class AddPurchaseDialog extends StatefulWidget {
  const AddPurchaseDialog({super.key});

  @override
  State<AddPurchaseDialog> createState() => _AddPurchaseDialogState();
}

class _AddPurchaseDialogState extends State<AddPurchaseDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _invoiceController = TextEditingController();
  final TextEditingController _taxController = TextEditingController(text: '0');
  final TextEditingController _vendorController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedVendorId;
  String _status = 'draft';

  List<PurchaseItemModel> _items = [];
  bool _isLocalLoading = false;

  // Focus nodes for keyboard navigation
  final FocusNode _vendorFocusNode = FocusNode();
  final FocusNode _dateFocusNode = FocusNode();
  final FocusNode _invoiceFocusNode = FocusNode();
  final FocusNode _saveFocusNode = FocusNode();
  final FocusNode _addRowFocusNode = FocusNode(skipTraversal: true);

  @override
  void initState() {
    super.initState();
    // Initialize data providers when dialog opens
    Future.microtask(() {
      context.read<VendorProvider>().initialize();
      final products = context.read<ProductProvider>();
      products.loadCategories();
      products.clearFilters();
    });
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _taxController.dispose();
    _vendorFocusNode.dispose();
    _dateFocusNode.dispose();
    _invoiceFocusNode.dispose();
    _saveFocusNode.dispose();
    _vendorController.dispose();
    _addRowFocusNode.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get _taxAmount => double.tryParse(_taxController.text) ?? 0.0;
  double get _total => _subtotal + _taxAmount;

  void _addItem() {
    setState(() {
      _items.add(PurchaseItemModel(
        quantity: 1,
        unitCost: 0,
        totalPrice: 0,
        // Product is initially null
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  /// Helper to format doubles nicely (e.g. 1.0 -> "1", 1.5 -> "1.5")
  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
      ),
      backgroundColor: AppTheme.creamWhite,
      child: Container(
        width: context.dialogWidth, // Use responsive width helper
        constraints: BoxConstraints(
          maxHeight: 90.h,
          maxWidth: 1000,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Header ---
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 4.0),
                child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMaroon.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: AppTheme.primaryMaroon,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add Purchase',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.headerFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoalGray,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              ),
              const Divider(height: 32),

              // --- Scrollable Body ---
              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(top: 10, left: context.mainPadding, right: context.mainPadding, bottom: 10),
                      child: Column(
                        children: [
                          _buildGeneralInfo(context, l10n),
                          SizedBox(height: context.mainPadding),
                          _buildItemsSection(context, l10n),
                          SizedBox(height: context.mainPadding),
                          _buildSummarySection(context, l10n),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(height: 32),

              // --- Footer Actions ---
              Padding(
                padding: EdgeInsets.only(bottom: context.mainPadding, left: context.mainPadding, right: context.mainPadding),
                child: _buildActions(context, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralInfo(BuildContext context, AppLocalizations l10n) {
    bool isWide = MediaQuery.of(context).size.width > 600;
    
    final vendorRow = Consumer<VendorProvider>(
      builder: (context, provider, child) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Autocomplete<VendorModel>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final vendors = provider.vendors;
                      final query = textEditingValue.text.toLowerCase();
                      
                      if (query.isEmpty) {
                        return vendors;
                      }

                      String? selectedName;
                      if (_selectedVendorId != null) {
                        final match = vendors.where((v) => v.id == _selectedVendorId);
                        if (match.isNotEmpty) {
                          final v = match.first;
                          selectedName = (v.businessName.isNotEmpty ? v.businessName : v.name).toLowerCase();
                        }
                      }

                      if (selectedName != null && query == selectedName) {
                        final selected = vendors.where((v) => v.id == _selectedVendorId).toList();
                        final rest = vendors.where((v) => v.id != _selectedVendorId).toList();
                        return [...selected, ...rest];
                      }

                      final matches = vendors.where((v) => 
                        v.name.toString().toLowerCase().contains(query) ||
                        v.businessName.toString().toLowerCase().contains(query)
                      ).toList();
                      
                      final nonMatches = vendors.where((v) => 
                        !v.name.toString().toLowerCase().contains(query) &&
                        !v.businessName.toString().toLowerCase().contains(query)
                      ).toList();
                      
                      return [...matches, ...nonMatches];
                    },
                    displayStringForOption: (option) => option.businessName.isNotEmpty ? option.businessName : option.name,
                    onSelected: (selection) {
                      setState(() => _selectedVendorId = selection.id);
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      if (_selectedVendorId != null && controller.text.isEmpty) {
                        final existing = provider.vendors.where((v) => v.id == _selectedVendorId).toList();
                        if (existing.isNotEmpty) {
                          final v = existing.first;
                          controller.text = v.businessName.isNotEmpty ? v.businessName : v.name;
                        }
                      }
                      
                      // Auto-open logic on focus
                      focusNode.addListener(() {
                        if (focusNode.hasFocus && controller.text.isEmpty) {
                          // This triggers optionsBuilder
                          // ignore: invalid_use_of_protected_member
                          controller.notifyListeners();
                        }
                      });

                      return PremiumTextField(
                        controller: controller,
                        focusNode: focusNode,
                        label: l10n.vendor ?? "Company Name",
                        hint: "Select Company...",
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          _dateFocusNode.requestFocus();
                        },
                        suffixIcon: InkWell(
                          onTap: () => focusNode.requestFocus(),
                          child: const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey, size: 24)
                        ),
                        onChanged: (val) {
                          if (_selectedVendorId != null) setState(() => _selectedVendorId = null);
                        },
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 8.0,
                          borderRadius: BorderRadius.circular(8),
                          color: AppTheme.pureWhite,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: 250, maxWidth: constraints.maxWidth),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.businessName.isNotEmpty ? option.businessName : option.name,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                                        ),
                                        if (option.businessName.isNotEmpty)
                                          Text(
                                            option.name,
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600])
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: IconButton.filled(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) => EnhancedAddVendorDialog(),
                  );
                  if (mounted) {
                    context.read<VendorProvider>().initialize();
                  }
                },
                icon: const Icon(Icons.add_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryMaroon,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        );
      },
    );

    final dateField = InkWell(
      focusNode: _dateFocusNode,
      onTap: () {
        context.showSyncfusionDateTimePicker(
          initialDate: _selectedDate,
          initialTime: _selectedTime,
          onDateTimeSelected: (date, time) {
            setState(() {
              _selectedDate = date;
              _selectedTime = time;
            });
          },
        );
      },
      borderRadius: BorderRadius.circular(context.borderRadius('small')),
      child: IgnorePointer(
        child: PremiumTextField(
          label: l10n.date ?? "Date",
          enabled: false,
          controller: TextEditingController(
            text: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} ${_selectedTime.format(context)}",
          ),
          prefixIcon: Icons.calendar_today_rounded,
        ),
      ),
    );

    return isWide 
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: vendorRow),
              SizedBox(width: context.mainPadding),
              Expanded(child: dateField),
            ],
          )
        : Column(
            children: [
              vendorRow,
              const SizedBox(height: 16),
              dateField,
            ],
          );
  }

  Widget _buildItemsSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Purchased Products",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodyFontSize),
            ),
            PremiumButton(
              text: "Add Product Row",
              onPressed: _addItem,
              icon: Icons.add_rounded,
              focusNode: _addRowFocusNode,
              width: 180,
              height: 40,
              backgroundColor: AppTheme.secondaryMaroon,
            ),
          ],
        ),
        SizedBox(height: context.smallPadding),

        if (_items.isEmpty)
          Container(
            padding: EdgeInsets.all(context.mainPadding),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              color: Colors.grey.shade50,
            ),
            child: Column(
              children: [
                Icon(Icons.list_alt_rounded, size: 40, color: Colors.grey[400]),
                SizedBox(height: 8),
                Text(
                    "No items added yet.",
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _items.length,
            itemBuilder: (context, index) => _PurchaseItemRow(
              index: index,
              item: _items[index],
              onChanged: (newItem) {
                setState(() {
                  _items[index] = newItem;
                });
              },
              onRemove: () => _removeItem(index),
            ),
          ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.mainPadding),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.03),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _summaryRow("Grand Total", _subtotal, isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          fontSize: isTotal ? 12.sp : 10.sp,
          color: isTotal ? AppTheme.charcoalGray : Colors.grey[700],
        )),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryMaroon,
            fontSize: isTotal ? 14.sp : 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        PremiumButton(
          text: l10n.cancel ?? "Cancel",
          onPressed: () => Navigator.pop(context),
          isOutlined: true,
          width: 120,
          height: 48,
          backgroundColor: Colors.grey,
        ),
        SizedBox(width: context.mainPadding),
        Consumer<PurchaseProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: "Save Purchase",
              focusNode: _saveFocusNode,
              isLoading: provider.isLoading || _isLocalLoading,
              onPressed: _handleSave,
              width: 200,
              height: 48,
              icon: Icons.check_circle_outline_rounded,
            );
          },
        ),
      ],
    );
  }

  void _handleSave() async {
    // 1. Validate General Fields
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    if (_selectedVendorId == null) {
      _showError("Please select a Vendor strictly from the dropdown list.");
      return;
    }

    // 2. Smart Sync Categories: If ID is missing but name exists, try to find a match
    final categories = context.read<CategoryProvider>().categories;
    for (int i = 0; i < _items.length; i++) {
      if ((_items[i].categoryId == null || _items[i].categoryId!.isEmpty) && 
          (_items[i].categoryName ?? '').isNotEmpty) {
        for (var cat in categories) {
          if (cat.name.toLowerCase().trim() == _items[i].categoryName!.toLowerCase().trim()) {
            _items[i] = _items[i].copyWith(categoryId: cat.id, categoryName: cat.name);
            break;
          }
        }
      }
    }

    // 3. Validate Items
    if (_items.isEmpty) {
      _showError("Please add at least one product to the purchase.");
      return;
    }

    for (int i = 0; i < _items.length; i++) {
      if ((_items[i].productName ?? '').isEmpty) {
        _showError("Item #${i + 1}: Please enter an item name.");
        return;
      }
      
      if (_items[i].categoryId == null || _items[i].categoryId!.isEmpty) {
        _showError("Item #${i + 1}: Please select a Category strictly from the dropdown list. Current: ${_items[i].categoryName}");
        return;
      }
      if (_items[i].quantity <= 0) {
        _showError("Item #${i + 1}: Quantity must be greater than 0.");
        return;
      }
    }

    setState(() => _isLocalLoading = true);

    try {
      final productProvider = context.read<ProductProvider>();
      
      // Auto-create products that were manually typed
      for (int i = 0; i < _items.length; i++) {
        if (_items[i].product == null || _items[i].product!.isEmpty) {
          final newProduct = await productProvider.addProduct(
            name: _items[i].productName!,
            detail: _items[i].description ?? 'Auto-created during purchase',
            price: _items[i].retailPrice > 0 ? _items[i].retailPrice : _items[i].unitCost,
            costPrice: _items[i].unitCost,
            quantity: 0, // Backend purchase view will increase the stock
            categoryId: _items[i].categoryId!,
          );

          if (newProduct != null && newProduct.id.isNotEmpty) {
            _items[i] = _items[i].copyWith(product: newProduct.id);
          } else {
            final err = productProvider.errorMessage ?? "Product creation failed";
            if (mounted) setState(() => _isLocalLoading = false);
            _showError("Item #${i + 1}: Failed to create product. $err");
            return;
          }
        } else if (_items[i].retailPrice > 0) {
           await productProvider.updateProduct(
            id: _items[i].product!,
            price: _items[i].retailPrice,
            costPrice: _items[i].unitCost,
          );
        }
      }

      // 3. Create Purchase
      final purchase = PurchaseModel(
        vendor: _selectedVendorId,
        invoiceNumber: "Auto-Generated", 
        purchaseDate: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        subtotal: _subtotal,
        tax: 0,
        total: _subtotal, 
        status: 'posted', 
        items: _items,
      );

      final success = await context.read<PurchaseProvider>().addPurchase(purchase);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
      } else {
        final error = context.read<PurchaseProvider>().error ?? "Failed to save purchase";
        _showError(error);
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isLocalLoading = false);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text(
              "Error",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppTheme.charcoalGray,
            fontSize: 14,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text(
              "OK",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseItemRow extends StatefulWidget {
  final int index;
  final PurchaseItemModel item;
  final Function(PurchaseItemModel) onChanged;
  final VoidCallback onRemove;

  const _PurchaseItemRow({
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_PurchaseItemRow> createState() => _PurchaseItemRowState();
}

class _PurchaseItemRowState extends State<_PurchaseItemRow> {
  late TextEditingController _qtyController;
  late TextEditingController _costController;
  late TextEditingController _descController; 
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _retailController;
  late FocusNode _nameFocusNode;
  late FocusNode _categoryFocusNode;
  late FocusNode _qtyFocusNode;
  late FocusNode _costFocusNode;
  late FocusNode _retailFocusNode;
  late FocusNode _descFocusNode;
  bool _isInternalChange = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: _formatNumber(widget.item.quantity));
    _costController = TextEditingController(text: _formatNumber(widget.item.unitCost));
    _descController = TextEditingController(text: widget.item.description ?? '');
    _nameController = TextEditingController(text: widget.item.productName ?? '');
    _categoryController = TextEditingController(text: widget.item.categoryName ?? '');
    _retailController = TextEditingController(text: _formatNumber(widget.item.retailPrice));
    _nameFocusNode = FocusNode();
    _categoryFocusNode = FocusNode();
    _qtyFocusNode = FocusNode();
    _costFocusNode = FocusNode();
    _retailFocusNode = FocusNode();
    _descFocusNode = FocusNode();
    _isInternalChange = false;
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _categoryFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
        if ((widget.item.categoryName ?? '').isEmpty) {
          _nameFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    _qtyFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_qtyController.text.isEmpty || _qtyController.text == '0') {
          _categoryFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    _costFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_costController.text.isEmpty || _costController.text == '0') {
          _qtyFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };

    _descFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_descController.text.isEmpty) {
          _costFocusNode.requestFocus();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void didUpdateWidget(_PurchaseItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.productName != oldWidget.item.productName) {
      if (_nameController.text != widget.item.productName) {
         _nameController.text = widget.item.productName ?? '';
      }
    }
    if (widget.item.categoryName != oldWidget.item.categoryName) {
      if (_categoryController.text != widget.item.categoryName) {
         _categoryController.text = widget.item.categoryName ?? '';
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _nameFocusNode.dispose();
    _categoryFocusNode.dispose();
    _qtyFocusNode.dispose();
    _costFocusNode.dispose();
    _retailFocusNode.dispose();
    _retailController.dispose();
    _descFocusNode.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Consumer<ProductProvider>(
                  builder: (context, provider, child) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Autocomplete<ProductModel>(
                          focusNode: _nameFocusNode,
                          textEditingController: _nameController,
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            final products = provider.allProducts;
                            final query = textEditingValue.text.toLowerCase();
                            
                            if (query.isEmpty) {
                              return products;
                            }

                            String? selectedName = widget.item.productName?.toLowerCase();

                            if (selectedName != null && query == selectedName) {
                              final selected = products.where((p) => p.name.toString().toLowerCase() == selectedName).toList();
                              final rest = products.where((p) => p.name.toString().toLowerCase() != selectedName).toList();
                              return [...selected, ...rest];
                            }

                            final matches = products.where((p) => 
                              p.name.toString().toLowerCase().contains(query)
                            ).toList();
                            
                            final nonMatches = products.where((p) => 
                              !p.name.toString().toLowerCase().contains(query)
                            ).toList();
                            
                            return [...matches, ...nonMatches];
                          },
                          displayStringForOption: (ProductModel option) => option.name,
                          onSelected: (ProductModel selection) {
                             _isInternalChange = true;
                             _nameController.text = selection.name;
                             widget.onChanged(widget.item.copyWith(
                               product: selection.id,
                               productName: selection.name,
                               categoryName: selection.categoryName,
                               categoryId: selection.categoryId,
                               unitCost: selection.costPrice ?? selection.price,
                               retailPrice: selection.price, // ✅ Auto-fill rent rate from product.price
                               description: selection.detail,
                               totalPrice: (selection.costPrice ?? selection.price) * widget.item.quantity
                             ));
                             _costController.text = _formatNumber(selection.costPrice ?? selection.price);
                             _retailController.text = _formatNumber(selection.price); // ✅ Show rent rate
                             _descController.text = selection.detail;
                             _categoryController.text = selection.categoryName ?? '';
                             _qtyFocusNode.requestFocus();
                             Future.microtask(() => _isInternalChange = false);
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return PremiumTextField(
                              controller: controller,
                              focusNode: focusNode, 
                              label: "Item Name",
                              fontSize: 13.sp,
                              labelFontSize: 13.sp,
                              hint: "Enter item name",
                              prefixIcon: Icons.shopping_bag_outlined,
                              suffixIcon: controller.text.isNotEmpty 
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      controller.clear();
                                      widget.onChanged(widget.item.copyWith(product: null, productName: ''));
                                    },
                                  )
                                : null,
                              onChanged: (val) {
                                widget.onChanged(widget.item.copyWith(
                                  product: '',
                                  productName: val,
                                ));
                              },
                              onSubmitted: (val) {
                                if (val.isNotEmpty) {
                                  onFieldSubmitted();
                                }
                                _categoryFocusNode.requestFocus();
                              },
                            );
                          },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 8.0,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: constraints.maxWidth,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    constraints: const BoxConstraints(maxHeight: 250),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (BuildContext context, int index) {
                                        final ProductModel option = options.elementAt(index);
                                        return InkWell(
                                          onTap: () => onSelected(option),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                            decoration: BoxDecoration(
                                              border: index != options.length - 1 
                                                ? Border(bottom: BorderSide(color: Colors.grey.shade100))
                                                : null,
                                            ),
                                            child: Text(
                                              option.name,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                          },
                        );
                      }
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                flex: 3,
                child: Consumer<ProductProvider>(
                  builder: (context, provider, child) {
                     return LayoutBuilder(
                       builder: (context, constraints) {
                         return Autocomplete<CategoryModel>(
                           focusNode: _categoryFocusNode,
                           textEditingController: _categoryController,
                           optionsBuilder: (TextEditingValue textEditingValue) {
                              final categories = provider.categories;
                              final query = textEditingValue.text.toLowerCase();
                              
                              if (query.isEmpty) {
                                return categories;
                              }

                              String? selectedName = widget.item.categoryName?.toLowerCase();

                              if (selectedName != null && query == selectedName) {
                                final selected = categories.where((c) => c.name.toString().toLowerCase() == selectedName).toList();
                                final rest = categories.where((c) => c.name.toString().toLowerCase() != selectedName).toList();
                                return [...selected, ...rest];
                              }

                              final matches = categories.where((c) => 
                                c.name.toString().toLowerCase().contains(query)
                              ).toList();
                              
                              final nonMatches = categories.where((c) => 
                                !c.name.toString().toLowerCase().contains(query)
                              ).toList();
                              
                              return [...matches, ...nonMatches];
                            },
                           displayStringForOption: (CategoryModel option) => option.name,
                           onSelected: (CategoryModel selection) {
                               _isInternalChange = true;
                               _categoryController.text = selection.name;
                               widget.onChanged(widget.item.copyWith(
                                 categoryId: selection.id,
                                 categoryName: selection.name
                               ));
                               Future.microtask(() => _isInternalChange = false);
                           },
                           fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              return PremiumTextField(
                                controller: controller,
                                focusNode: focusNode,
                                label: "Category",
                                fontSize: 13.sp,
                                labelFontSize: 13.sp,
                                hint: "Category",
                                suffixIcon: controller.text.isNotEmpty 
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        controller.clear();
                                        widget.onChanged(widget.item.copyWith(categoryName: ''));
                                      },
                                    )
                                  : null,
                                onChanged: (val) {
                                  if (!_isInternalChange && focusNode.hasFocus) {
                                    widget.onChanged(widget.item.copyWith(
                                       categoryName: val,
                                       categoryId: '',
                                    ));
                                  }
                                },
                                onSubmitted: (val) {
                                  if (val.isNotEmpty) {
                                    onFieldSubmitted();
                                  }
                                  _descFocusNode.requestFocus();
                                },
                              );
                           },
                           optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 8.0,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: constraints.maxWidth,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    constraints: const BoxConstraints(maxHeight: 250),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (BuildContext context, int index) {
                                        final CategoryModel option = options.elementAt(index);
                                        return InkWell(
                                          onTap: () => onSelected(option),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                            decoration: BoxDecoration(
                                              border: index != options.length - 1 
                                                ? Border(bottom: BorderSide(color: Colors.grey.shade100))
                                                : null,
                                            ),
                                            child: Text(
                                              option.name,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                           }
                         );
                       }
                     );
                  }
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          PremiumTextField(
            label: "Description",
            fontSize: 13.sp,
            labelFontSize: 13.sp,
            controller: _descController,
            focusNode: _descFocusNode,
            hint: "Item description",
            onChanged: (val) {
              widget.onChanged(widget.item.copyWith(description: val));
            },
            onSubmitted: (_) => _qtyFocusNode.requestFocus(),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: PremiumTextField(
                  label: "Qty",
                  fontSize: 13.sp,
                  labelFontSize: 13.sp,
                  controller: _qtyController,
                  focusNode: _qtyFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    final qty = double.tryParse(val) ?? 0;
                    widget.onChanged(widget.item.copyWith(
                      quantity: qty,
                      totalPrice: double.parse((qty * widget.item.unitCost).toStringAsFixed(2)),
                    ));
                  },
                  onSubmitted: (_) => _costFocusNode.requestFocus(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: PremiumTextField(
                  label: "Purchase Price",
                  fontSize: 13.sp,
                  labelFontSize: 13.sp,
                  controller: _costController,
                  focusNode: _costFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    final cost = double.tryParse(val) ?? 0;
                    widget.onChanged(widget.item.copyWith(
                      unitCost: cost,
                      totalPrice: double.parse((cost * widget.item.quantity).toStringAsFixed(2)),
                    ));
                  },
                  onSubmitted: (_) => _retailFocusNode.requestFocus(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: PremiumTextField(
                  label: "Rent Price",
                  fontSize: 13.sp,
                  labelFontSize: 13.sp,
                  controller: _retailController,
                  focusNode: _retailFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    final r = double.tryParse(val) ?? 0;
                    widget.onChanged(widget.item.copyWith(retailPrice: r));
                  },
                  onSubmitted: (_) {
                    final state = context.findAncestorStateOfType<_AddPurchaseDialogState>();
                    if (state != null) {
                      state._saveFocusNode.requestFocus();
                    } else {
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total", style: TextStyle(fontSize: 10.sp, color: Colors.grey[700])),
                      Text(
                        widget.item.totalPrice.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryMaroon,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}