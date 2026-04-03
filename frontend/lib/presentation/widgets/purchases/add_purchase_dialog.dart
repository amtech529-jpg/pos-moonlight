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
import '../product/add_product_dialog.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/models/category/category_model.dart'; // ✅ Added import
import '../../../src/services/category_service.dart'; // ✅ Added import

class AddPurchaseDialog extends StatefulWidget {
  const AddPurchaseDialog({super.key});

  @override
  State<AddPurchaseDialog> createState() => _AddPurchaseDialogState();
}

class _AddPurchaseDialogState extends State<AddPurchaseDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _invoiceController = TextEditingController();
  final TextEditingController _taxController = TextEditingController(text: '0');

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedVendorId;
  String _status = 'draft';

  List<PurchaseItemModel> _items = [];
  bool _isLocalLoading = false;

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
          maxWidth: 1000, // Reasonable max width for desktop
        ),
        padding: EdgeInsets.all(context.mainPadding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Header ---
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.smallPadding),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMaroon.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_shopping_cart_rounded,
                      color: AppTheme.primaryMaroon,
                      size: 24, // Fixed size for header icon
                    ),
                  ),
                  SizedBox(width: context.smallPadding),
                  Expanded(
                    child: Text(
                      l10n.add ?? "New Purchase",
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
              const Divider(height: 32),

              // --- Scrollable Body ---
              Expanded(
                child: SingleChildScrollView(
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

              const Divider(height: 32),

              // --- Footer Actions ---
              _buildActions(context, l10n),
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
              child: PremiumDropdownField<String>(
                label: l10n.vendor ?? "Vendor",
                value: _selectedVendorId,
                items: provider.vendors.map((v) => DropdownItem<String>(
                  value: v.id!,
                  label: v.name,
                )).toList(),
                onChanged: (val) => setState(() => _selectedVendorId = val),
                hint: "Select Vendor",
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
      child: IgnorePointer(
        child: PremiumTextField(
          label: l10n.date ?? "Purchase Date",
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
      _showError("Please select a Vendor.");
      return;
    }

    // 2. Validate Items
    if (_items.isEmpty) {
      _showError("Please add at least one product to the purchase.");
      return;
    }

    for (int i = 0; i < _items.length; i++) {
      if ((_items[i].productName ?? '').isEmpty) {
        _showError("Item #${i + 1}: Please enter an item name.");
        return;
      }
      if ((_items[i].categoryName ?? '').isEmpty) {
        _showError("Item #${i + 1}: Please enter a category.");
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
      final categoryService = CategoryService();

      // 3. Process Items (Create Products if needed)
      List<PurchaseItemModel> processedItems = [];

      for (var item in _items) {
        String? productId = item.product;

        // If product doesn't exist (no ID), create it
        if (productId == null || productId.isEmpty) {
          
          // A. Handle Category
          String categoryId = '';
          
          // Check if category exists
          final existingCategory = productProvider.categories.firstWhere(
            (c) => c.name.toLowerCase() == (item.categoryName ?? '').toLowerCase(),
            orElse: () => CategoryModel(id: '', name: '', description: '', isActive: false, createdAt: DateTime.now(), updatedAt: DateTime.now())
          );

          if (existingCategory.id.isNotEmpty) {
            categoryId = existingCategory.id;
          } else {
            // Create Category
            final catResult = await categoryService.createCategory(
              name: item.categoryName!, 
              description: "Auto-created from Purchase"
            );
            if (catResult.success && catResult.data != null) {
              categoryId = catResult.data!.id;
               productProvider.loadCategories(); 
            } else {
               throw Exception("Failed to create category: ${item.categoryName}");
            }
          }

          // B. Create Product
          final newProduct = await productProvider.addProduct(
            name: item.productName!,
            detail: item.description ?? "Purchased Item",
            // ✅ Round to 2 decimal places to avoid precision errors
            price: double.parse(item.unitCost.toStringAsFixed(2)), 
            costPrice: double.parse(item.unitCost.toStringAsFixed(2)),
            quantity: 0, 
            categoryId: categoryId,
            color: '',
            fabric: '',
            pieces: [],
            isRental: true, 
            isConsumable: false,
          );

          if (newProduct != null) {
            productId = newProduct.id;
          } else {
            final error = productProvider.errorMessage ?? "Failed to create product: ${item.productName}";
            throw Exception(error);
          }
        }

        processedItems.add(item.copyWith(product: productId));
      }

      // 4. Create Purchase
      final purchase = PurchaseModel(
        vendor: _selectedVendorId,
        invoiceNumber: "Auto-Generated", // Backend can handle or we just send placeholder if not visible
        purchaseDate: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        subtotal: _subtotal,
        tax: 0,
        total: _subtotal, // No tax
        status: 'posted', // Always posted
        items: processedItems,
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
  late FocusNode _nameFocusNode;
  late FocusNode _categoryFocusNode;
  late FocusNode _qtyFocusNode;
  late FocusNode _costFocusNode;
  late FocusNode _descFocusNode;
  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: _formatNumber(widget.item.quantity));
    _costController = TextEditingController(text: _formatNumber(widget.item.unitCost));
    _descController = TextEditingController(text: widget.item.description ?? '');
    _nameController = TextEditingController(text: widget.item.productName ?? '');
    _categoryController = TextEditingController(text: widget.item.categoryName ?? '');
    _nameFocusNode = FocusNode();
    _categoryFocusNode = FocusNode();
    _qtyFocusNode = FocusNode();
    _costFocusNode = FocusNode();
    _descFocusNode = FocusNode();

    // Add listeners for backspace navigation
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
    // Sync Name controller if item changed
    if (widget.item.productName != oldWidget.item.productName) {
      if (_nameController.text != widget.item.productName) {
         _nameController.text = widget.item.productName ?? '';
      }
    }
    // Sync Category controller if item changed
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
    _descFocusNode.dispose();
    // _internalCatController is managed by Autocomplete, don't dispose it here
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
          // Row 1: Item Name & Category
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name (Autocomplete)
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
                            if (textEditingValue.text.isEmpty) {
                              return const Iterable<ProductModel>.empty();
                            }
                            return provider.allProducts.where((ProductModel option) {
                              return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          displayStringForOption: (ProductModel option) => option.name,
                          onSelected: (ProductModel selection) {
                             _nameController.text = selection.name;
                             widget.onChanged(widget.item.copyWith(
                               product: selection.id,
                               productName: selection.name,
                               categoryName: selection.categoryName,
                               unitCost: selection.costPrice ?? selection.price,
                               description: selection.detail,
                               totalPrice: (selection.costPrice ?? selection.price) * widget.item.quantity
                             ));
                             _costController.text = _formatNumber(selection.costPrice ?? selection.price);
                             _descController.text = selection.detail;
                             _categoryController.text = selection.categoryName ?? '';
                             _qtyFocusNode.requestFocus();
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return PremiumTextField(
                              controller: controller,
                              focusNode: focusNode, 
                              label: "Item Name",
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
                                  product: null,
                                  productName: val,
                                ));
                              },
                              onSubmitted: (val) {
                                if (val.isNotEmpty) {
                                  onFieldSubmitted(); // Select top option
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
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
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

              // Category (Autocomplete)
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
                             if (textEditingValue.text.isEmpty) {
                               return const Iterable<CategoryModel>.empty();
                             }
                             return provider.categories.where((CategoryModel option) {
                               return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                             });
                           },
                           displayStringForOption: (CategoryModel option) => option.name,
                           onSelected: (CategoryModel selection) {
                               _categoryController.text = selection.name;
                               widget.onChanged(widget.item.copyWith(
                                 categoryName: selection.name
                               ));
                           },
                           fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              return PremiumTextField(
                                controller: controller,
                                focusNode: focusNode,
                                label: "Category",
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
                                   widget.onChanged(widget.item.copyWith(categoryName: val));
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
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
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
          
          // Row 2: Description (Full Width)
          PremiumTextField(
            label: "Description",
            controller: _descController,
            focusNode: _descFocusNode,
            hint: "Item description",
            onChanged: (val) {
              widget.onChanged(widget.item.copyWith(description: val));
            },
            onSubmitted: (_) => _qtyFocusNode.requestFocus(),
          ),
          const SizedBox(height: 8),

          // Row 3: Qty, Cost, Total, Delete
          Row(
            children: [
              Expanded(
                flex: 2,
                child: PremiumTextField(
                  label: "Qty",
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
                flex: 2,
                child: PremiumTextField(
                  label: "Purchase Price",
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
                  onSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Container(
                  height: 48, // Match input height
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
                      Text("Total", style: TextStyle(fontSize: 8.sp, color: Colors.grey[700])),
                      Text(
                        widget.item.totalPrice.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryMaroon,
                          fontSize: 10.sp,
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