import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/models/purchase_model.dart';
import '../../../src/providers/purchase_provider.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/providers/category_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/text_field.dart';
import '../globals/drop_down.dart';
import '../globals/custom_date_picker.dart';
import '../globals/text_button.dart';
import '../../../src/models/vendor/vendor_model.dart';
import '../../../src/models/product/product_model.dart';


class EditPurchaseDialog extends StatefulWidget {
  final PurchaseModel purchase;

  const EditPurchaseDialog({super.key, required this.purchase});

  @override
  State<EditPurchaseDialog> createState() => _EditPurchaseDialogState();
}

class _EditPurchaseDialogState extends State<EditPurchaseDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _invoiceController;
  late TextEditingController _taxController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _selectedVendorId;
  late String _status;
  List<PurchaseItemModel> _items = [];
   final Map<int, TextEditingController> _qtyControllers = {};
  final Map<int, TextEditingController> _costControllers = {};
  final Map<int, TextEditingController> _retailControllers = {};

  final FocusNode _vendorFocusNode = FocusNode();
  final TextEditingController _vendorController = TextEditingController();
  final FocusNode _dateFocusNode = FocusNode();
  final FocusNode _invoiceFocusNode = FocusNode();
  final FocusNode _taxFocusNode = FocusNode();
  final FocusNode _saveFocusNode = FocusNode();
  final FocusNode _addRowFocusNode = FocusNode(skipTraversal: true);

  final Map<int, FocusNode> _productFocusNodes = {};
  final Map<int, TextEditingController> _productControllers = {};
  final Map<int, FocusNode> _qtyFocusNodes = {};
  final Map<int, FocusNode> _costFocusNodes = {};
  final Map<int, FocusNode> _retailFocusNodes = {};

  @override
  void initState() {
    super.initState();
    // Initialize with existing purchase data
    _invoiceController = TextEditingController(text: widget.purchase.invoiceNumber);
    _taxController = TextEditingController(text: widget.purchase.tax.toString());
    _selectedDate = widget.purchase.purchaseDate;
    // Assuming purchaseDate contains time, otherwise default to now
    _selectedTime = TimeOfDay.fromDateTime(widget.purchase.purchaseDate);
    _selectedVendorId = widget.purchase.vendor;
    _status = widget.purchase.status;
    _items = List.from(widget.purchase.items);

    _saveFocusNode.addListener(() {
      if (_saveFocusNode.hasFocus && _saveFocusNode.context != null) {
        Future.microtask(() {
          Scrollable.ensureVisible(
            _saveFocusNode.context!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      }
    });

    for (int i = 0; i < _items.length; i++) {
      _qtyControllers[i] = TextEditingController(text: _items[i].quantity.toString());
      _costControllers[i] = TextEditingController(text: _items[i].unitCost.toString());
      _retailControllers[i] = TextEditingController(text: _items[i].retailPrice.toString());
      
      _productFocusNodes[i] = FocusNode();
      _productControllers[i] = TextEditingController();
      _qtyFocusNodes[i] = FocusNode();
      _costFocusNodes[i] = FocusNode();
      _retailFocusNodes[i] = FocusNode();
    }

    Future.microtask(() {
      context.read<VendorProvider>().initialize();
      context.read<ProductProvider>().initialize();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);
  double get _taxAmount => double.tryParse(_taxController.text) ?? 0.0;
  double get _total => _subtotal + _taxAmount;

  void _addItem() {
    setState(() {
      int newIndex = _items.length;
      _items.add(PurchaseItemModel(
          quantity: 1,
          unitCost: 0,
          totalPrice: 0
      ));
      _qtyControllers[newIndex] = TextEditingController(text: "1");
      _costControllers[newIndex] = TextEditingController(text: "0");
      _retailControllers[newIndex] = TextEditingController(text: "0");
      
      _productFocusNodes[newIndex] = FocusNode();
      _productControllers[newIndex] = TextEditingController();
      _qtyFocusNodes[newIndex] = FocusNode();
      _costFocusNodes[newIndex] = FocusNode();
      _retailFocusNodes[newIndex] = FocusNode();
    });
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _taxController.dispose();
    for (var controller in _qtyControllers.values) {
      controller.dispose();
    }
    for (var controller in _costControllers.values) {
      controller.dispose();
    }
    _vendorFocusNode.dispose();
    _vendorController.dispose();
    _dateFocusNode.dispose();
    _invoiceFocusNode.dispose();
    _taxFocusNode.dispose();
    _saveFocusNode.dispose();
    _addRowFocusNode.dispose();
    for (var node in _productFocusNodes.values) { node.dispose(); }
    for (var node in _productControllers.values) { node.dispose(); }
    for (var node in _qtyFocusNodes.values) { node.dispose(); }
    for (var node in _costFocusNodes.values) { node.dispose(); }
    for (var node in _retailFocusNodes.values) { node.dispose(); }
    for (var controller in _retailControllers.values) { controller.dispose(); }
    
    super.dispose();
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
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 4.0),
                child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                        color: AppTheme.primaryMaroon.withOpacity(0.1),
                        shape: BoxShape.circle
                    ),
                    child: const Icon(
                        Icons.edit_note_rounded,
                        color: AppTheme.primaryMaroon,
                        size: 20
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n.editPurchase ?? "Edit Purchase",
                    style: TextStyle(
                        fontSize: context.headerFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.charcoalGray
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20,)
                  ),
                ],
              ),
              ),
              const Divider(height: 32),

              Expanded(
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(top: 12, bottom: 12, left: context.mainPadding, right: context.mainPadding),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Consumer<VendorProvider>(
                builder: (context, provider, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Autocomplete<VendorModel>(
                        focusNode: _vendorFocusNode,
                        textEditingController: _vendorController,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          final vendors = provider.vendors;
                          final query = textEditingValue.text.toLowerCase();
                          
                          if (query.isEmpty) {
                            return vendors;
                          }

                          // Find currently selected vendor name
                          String? selectedName;
                          if (_selectedVendorId != null) {
                            final match = vendors.where((v) => v.id == _selectedVendorId);
                            if (match.isNotEmpty) {
                              final v = match.first;
                              selectedName = (v.businessName.isNotEmpty ? v.businessName : v.name).toLowerCase();
                            }
                          }

                          // If text exactly matches the selected vendor, show all with selected at top
                          if (selectedName != null && query == selectedName) {
                            final selected = vendors.where((v) => v.id == _selectedVendorId).toList();
                            final rest = vendors.where((v) => v.id != _selectedVendorId).toList();
                            return [...selected, ...rest];
                          }

                          // Otherwise put matches at top, and the rest beneath
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
                          return PremiumTextField(
                            controller: controller,
                            focusNode: focusNode,
                            label: l10n.vendor ?? "Vendor",
                            hint: "Select Vendor...",
                            suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey, size: 24),
                            onChanged: (val) {
                              if (_selectedVendorId != null) setState(() => _selectedVendorId = null);
                            },
                            onSubmitted: (_) {
                              onFieldSubmitted();
                              _invoiceFocusNode.requestFocus();
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
                  );
                },
              ),
            ),
            SizedBox(width: context.mainPadding),
            Expanded(
              child: PremiumTextField(
                controller: _invoiceController,
                focusNode: _invoiceFocusNode,
                label: l10n.invoiceNumber ?? "Invoice #",
                validator: (val) => val!.isEmpty ? (l10n.enterInvoiceNumberError ?? "Required") : null,
                onSubmitted: (_) => _dateFocusNode.requestFocus(),
              ),
            ),
          ],
        ),
        SizedBox(height: context.mainPadding),
        Row(
          children: [
            Expanded(
              child: Focus(
                focusNode: _dateFocusNode,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space)) {
                    context.showSyncfusionDateTimePicker(
                      initialDate: _selectedDate,
                      initialTime: _selectedTime,
                      onDateTimeSelected: (date, time) {
                        setState(() {
                          _selectedDate = date;
                          _selectedTime = time;
                        });
                        Future.microtask(() {
                          if (_items.isNotEmpty && _productFocusNodes.containsKey(0)) {
                            _productFocusNodes[0]!.requestFocus();
                          } else {
                            _saveFocusNode.requestFocus();
                          }
                        });
                      },
                    );
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Builder(
                  builder: (context) {
                    final isFocused = Focus.of(context).hasFocus;
                    return InkWell(
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
                      child: Container(
                        decoration: isFocused ? BoxDecoration(
                          borderRadius: BorderRadius.circular(context.borderRadius()),
                          border: Border.all(color: AppTheme.accentGold, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentGold.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ) : null,
                        child: IgnorePointer(
                          child: PremiumTextField(
                            label: l10n.purchaseDate ?? "Purchase Date",
                            controller: TextEditingController(
                              text: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} ${_selectedTime.format(context)}",
                            ),
                            prefixIcon: Icons.calendar_today_rounded,
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ),
            ),
            SizedBox(width: context.mainPadding),
            const Expanded(child: SizedBox()), // Empty space to keep width at 50%
          ],
        ),
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
            Text(l10n.purchasedProducts ?? "Purchased Products",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.bodyFontSize)),
            PremiumButton(
              text: l10n.addProductRow ?? "Add Product Row",
              onPressed: _addItem,
              icon: Icons.add_rounded,
              focusNode: _addRowFocusNode,
              width: 200,
              height: 40,
            ),
          ],
        ),
        SizedBox(height: context.smallPadding),
        ..._items.asMap().entries.map((entry) {
          int index = entry.key;
          PurchaseItemModel item = entry.value;
          return Container(
            margin: EdgeInsets.only(bottom: context.smallPadding),
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Consumer<ProductProvider>(
                        builder: (context, provider, child) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return Autocomplete<ProductModel>(
                                focusNode: _productFocusNodes[index],
                                textEditingController: _productControllers[index],
                                optionsBuilder: (TextEditingValue textEditingValue) {
                                  final products = provider.products;
                                  final query = textEditingValue.text.toLowerCase();
                                  
                                  if (query.isEmpty) {
                                    return products;
                                  }

                                  String? selectedName = item.productName?.toLowerCase();

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
                                displayStringForOption: (option) => option.name.toString(),
                                onSelected: (selection) {
                                    setState(() {
                                      _items[index] = item.copyWith(
                                        product: selection.id,
                                        productName: selection.name,
                                        categoryName: selection.categoryName,
                                      );
                                    });
                                },
                                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                  if (item.productName != null && controller.text.isEmpty) {
                                    controller.text = item.productName!;
                                  }
                                  return PremiumTextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    label: l10n.purchasedProducts ?? "Product",
                                    hint: "Select Product...",
                                    suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey, size: 24),
                                    onChanged: (val) {
                                      setState(() {
                                        _items[index] = item.copyWith(
                                          product: "", // Use empty string so copyWith overwrites it
                                          productName: val,
                                        );
                                      });
                                    },
                                    onSubmitted: (_) {
                                      onFieldSubmitted();
                                      if (_qtyFocusNodes.containsKey(index)) {
                                          _qtyFocusNodes[index]!.requestFocus();
                                      }
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
                                                child: Text(option.name.toString(), style: const TextStyle(fontSize: 14)),
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
                SizedBox(width: context.smallPadding),
                Expanded(
                  flex: 2,
                  child: PremiumTextField(
                    label: "Qty",
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    controller: _qtyControllers[index],
                    focusNode: _qtyFocusNodes[index],
                    selectAllOnFocus: true,
                    onChanged: (v) {
                      final q = double.tryParse(v) ?? 0;
                      setState(() {
                        _items[index] = item.copyWith(
                          quantity: q,
                          totalPrice: q * item.unitCost,
                        );
                      });
                    },
                    onSubmitted: (_) {
                      if (_costFocusNodes.containsKey(index)) {
                        _costFocusNodes[index]!.requestFocus();
                      }
                    },
                  ),
                ),
                SizedBox(width: context.smallPadding),
                Expanded(
                  flex: 3,
                  child: PremiumTextField(
                    label: l10n.unitCost ?? "Cost",
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    controller: _costControllers[index],
                    focusNode: _costFocusNodes[index],
                    selectAllOnFocus: true,
                    onChanged: (v) {
                      final c = double.tryParse(v) ?? 0;
                      setState(() {
                        _items[index] = item.copyWith(
                          unitCost: c,
                          totalPrice: c * item.quantity,
                        );
                      });
                    },
                    onSubmitted: (_) {
                      if (_retailFocusNodes.containsKey(index)) {
                        _retailFocusNodes[index]!.requestFocus();
                      }
                    },
                  ),
                ),
                SizedBox(width: context.smallPadding),
                Expanded(
                  flex: 3,
                  child: PremiumTextField(
                    label: "Rent Price",
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    controller: _retailControllers[index],
                    focusNode: _retailFocusNodes[index],
                    selectAllOnFocus: true,
                    onChanged: (v) {
                      final r = double.tryParse(v) ?? 0;
                      setState(() {
                         _items[index] = item.copyWith(retailPrice: r);
                      });
                    },
                    onSubmitted: (_) {
                      if (_items.length - 1 == index) {
                        _taxFocusNode.requestFocus();
                      } else {
                        if (_productFocusNodes.containsKey(index + 1)) {
                          _productFocusNodes[index + 1]!.requestFocus();
                        }
                      }
                    },
                  ),
                ),
                SizedBox(width: context.smallPadding),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Line Total", style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      Text(item.totalPrice.toStringAsFixed(2),
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryMaroon)),
                    ],
                  ),
                ),
                IconButton(
                    onPressed: () {
                      setState(() {
                         _items.removeAt(index);
                         _qtyControllers.remove(index)?.dispose();
                         _costControllers.remove(index)?.dispose();
                         _productControllers.remove(index)?.dispose();
                         _productFocusNodes.remove(index)?.dispose();
                         _qtyFocusNodes.remove(index)?.dispose();
                         _costFocusNodes.remove(index)?.dispose();
                      });
                    },
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red)
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(context.mainPadding),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _summaryRow("Items Subtotal", _subtotal),
          SizedBox(height: context.smallPadding),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.taxAdjustment ?? "Total Tax", style: TextStyle(color: Colors.grey[600])),
              SizedBox(
                  width: 150,
                      child: PremiumTextField(
                      controller: _taxController,
                      focusNode: _taxFocusNode,
                      label: "Tax",
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      selectAllOnFocus: true,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _saveFocusNode.requestFocus(),
                  )
              ),
            ],
          ),
          const Divider(height: 32),
          _summaryRow(l10n.grandTotal ?? "Grand Total", _total, isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          fontSize: isTotal ? 18 : 14,
        )),
        Text(value.toStringAsFixed(2), style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryMaroon,
          fontSize: isTotal ? 18 : 14,
        )),
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
          backgroundColor: Colors.grey,
        ),
        SizedBox(width: context.mainPadding),
        Consumer<PurchaseProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: l10n.savePurchase ?? "Update Purchase",
              isLoading: provider.isLoading,
              focusNode: _saveFocusNode,
              onPressed: _handleUpdate,
              width: 200,
            );
          },
        ),
      ],
    );
  }

  void _handleUpdate() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedVendorId == null || _selectedVendorId!.isEmpty) {
        _showError("Please select a valid Vendor strictly from the dropdown list.");
        return;
      }

      if (_items.isEmpty) {
        _showError("Please add at least one product.");
        return;
      }

      final productProvider = context.read<ProductProvider>();
      final categoryProvider = context.read<CategoryProvider>();
      String defaultCategoryId = "";
      if (categoryProvider.categories.isNotEmpty) {
        defaultCategoryId = categoryProvider.categories.first.id;
      }

      for (int i = 0; i < _items.length; i++) {
        // 1. If product is new, create it with the retailPrice
        if (_items[i].product == null || _items[i].product!.isEmpty) {
          if (defaultCategoryId.isEmpty) {
             _showError("Row ${i+1}: Cannot auto-create product because no categories exist. Create a category first.");
             return;
          }
          final newProduct = await productProvider.addProduct(
            name: _items[i].productName!,
            detail: _items[i].description ?? 'Auto-created during purchase edit',
            price: _items[i].retailPrice > 0 ? _items[i].retailPrice : _items[i].unitCost, // Use retailPrice if set
            costPrice: _items[i].unitCost,
            quantity: 0,
            categoryId: defaultCategoryId,
          );

          if (newProduct != null && newProduct.id.isNotEmpty) {
            _items[i] = _items[i].copyWith(product: newProduct.id);
          } else {
            final err = productProvider.errorMessage ?? "Product creation failed";
            _showError("Row ${i+1}: Failed to auto-create product. $err");
            return;
          }
        } 
        // 2. If product exists, update its retail price if user changed it in the purchase row
        else if (_items[i].retailPrice > 0) {
          await productProvider.updateProduct(
            id: _items[i].product!,
            price: _items[i].retailPrice,
            costPrice: _items[i].unitCost,
          );
        }
      }

      final updated = widget.purchase.copyWith(
        vendor: _selectedVendorId,
        invoiceNumber: _invoiceController.text,
        purchaseDate: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        ),
        subtotal: _subtotal,
        tax: _taxAmount,
        total: _total,
        status: _status,
        items: _items,
      );

      final success = await context.read<PurchaseProvider>().updatePurchase(updated);
      if (success && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        _showError(context.read<PurchaseProvider>().error ?? "Failed to update");
      }
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