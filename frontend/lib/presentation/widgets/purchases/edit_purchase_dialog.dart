import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/models/purchase_model.dart';
import '../../../src/providers/purchase_provider.dart';
import '../../../src/providers/vendor_provider.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/text_field.dart';
import '../globals/drop_down.dart';
import '../globals/custom_date_picker.dart';
import '../globals/text_button.dart';


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

    for (int i = 0; i < _items.length; i++) {
      _qtyControllers[i] = TextEditingController(text: _items[i].quantity.toString());
      _costControllers[i] = TextEditingController(text: _items[i].unitCost.toString());
    }

    Future.microtask(() {
      context.read<VendorProvider>().initialize();
      context.read<ProductProvider>().initialize();
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
        width: 75.w, // Desktop-optimized width
        constraints: BoxConstraints(maxHeight: 90.h),
        padding: EdgeInsets.all(context.mainPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(context.smallPadding),
                    decoration: BoxDecoration(
                        color: AppTheme.primaryMaroon.withOpacity(0.1),
                        shape: BoxShape.circle
                    ),
                    child: Icon(
                        Icons.edit_note_rounded,
                        color: AppTheme.primaryMaroon,
                        size: context.iconSize('medium')
                    ),
                  ),
                  SizedBox(width: context.smallPadding),
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
                      icon: const Icon(Icons.close_rounded)
                  ),
                ],
              ),
              const Divider(height: 32),

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
              _buildActions(context, l10n),
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
                  return PremiumDropdownField<String>(
                    label: l10n.vendor ?? "Vendor",
                    value: _selectedVendorId,
                    items: provider.vendors.map((v) => DropdownItem<String>(
                        value: v.id!,
                        label: v.name
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedVendorId = val),
                    hint: l10n.selectVendorError ?? "Select Vendor",
                  );
                },
              ),
            ),
            SizedBox(width: context.mainPadding),
            Expanded(
              child: PremiumTextField(
                controller: _invoiceController,
                label: l10n.invoiceNumber ?? "Invoice #",
                validator: (val) => val!.isEmpty ? (l10n.enterInvoiceNumberError ?? "Required") : null,
              ),
            ),
          ],
        ),
        SizedBox(height: context.mainPadding),
        Row(
          children: [
            Expanded(
              child: InkWell(
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
                    label: l10n.purchaseDate ?? "Purchase Date",
                    controller: TextEditingController(
                      text: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} ${_selectedTime.format(context)}",
                    ),
                    prefixIcon: Icons.calendar_today_rounded,
                  ),
                ),
              ),
            ),
            SizedBox(width: context.mainPadding),
            Expanded(
              child: PremiumDropdownField<String>(
                label: "Status",
                value: _status,
                items: [
                  DropdownItem(value: 'draft', label: "Draft"),
                  DropdownItem(value: 'posted', label: "Posted"),
                ],
                onChanged: (val) => setState(() => _status = val!),
              ),
            ),
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
                  flex: 4,
                  child: Consumer<ProductProvider>(
                        builder: (context, provider, child) {
                          final List<DropdownItem<String>> dropdownItems = provider.products.map((p) => DropdownItem<String>(
                              value: p.id!,
                              label: p.name
                          )).toList();

                          // Add the current product if it's not in the list (e.g. inactive or filtered)
                          if (item.product != null && !dropdownItems.any((di) => di.value == item.product)) {
                            dropdownItems.add(DropdownItem<String>(
                                value: item.product!,
                                label: item.productDetail?.name ?? item.productName ?? "Previous Product"
                            ));
                          }

                          return PremiumDropdownField<String>(
                            label: l10n.purchasedProducts ?? "Product",
                            value: item.product,
                            items: dropdownItems,
                            onChanged: (val) {
                              final prod = provider.products.firstWhere((p) => p.id == val);
                                setState(() {
                                  _items[index] = item.copyWith(
                                    product: val,
                                    productName: prod.name,
                                    categoryName: prod.categoryName,
                                  );
                                });
                            },
                            hint: "Product",
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
                    onChanged: (v) {
                      final q = double.tryParse(v) ?? 0;
                      setState(() {
                        _items[index] = item.copyWith(
                          quantity: q,
                          totalPrice: q * item.unitCost,
                        );
                      });
                    },
                  ),
                ),
                SizedBox(width: context.smallPadding),
                Expanded(
                  flex: 2,
                  child: PremiumTextField(
                    label: l10n.unitCost ?? "Cost",
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    controller: _costControllers[index],
                    onChanged: (v) {
                      final c = double.tryParse(v) ?? 0;
                      setState(() {
                        _items[index] = item.copyWith(
                          unitCost: c,
                          totalPrice: c * item.quantity,
                        );
                      });
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
                        _qtyControllers.remove(index);
                        _costControllers.remove(index);
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
                      label: "Tax",
                      onChanged: (_) => setState(() {})
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.read<PurchaseProvider>().error ?? "Failed to update"))
        );
      }
    }
  }
}