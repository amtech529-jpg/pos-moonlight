import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/order/order_model.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/providers/order_item_provider.dart';
import '../../../src/providers/order_provider.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../../src/utils/responsive_breakpoints.dart';
import '../globals/drop_down.dart';

class AddOrderItemDialog extends StatefulWidget {
  final String? initialOrderId;

  const AddOrderItemDialog({super.key, this.initialOrderId});

  @override
  State<AddOrderItemDialog> createState() => _AddOrderItemDialogState();
}

class _AddOrderItemDialogState extends State<AddOrderItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _customizationNotesController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();

  // Selected models for dropdowns
  OrderModel? _selectedOrder;
  ProductModel? _selectedProduct;

  @override
  void initState() {
    super.initState();
    // Load orders and products for dropdowns
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDropdownData();
      if (widget.initialOrderId != null) {
        _setInitialOrderSelection();
      }
    });
  }

  void _loadDropdownData() {
    // Load orders and products for dropdowns
    final orderProvider = context.read<OrderProvider>();
    final productProvider = context.read<ProductProvider>();

    if (orderProvider.orders.isEmpty) {
      //  orderProvider.getOrders();
    }

    if (productProvider.products.isEmpty) {
      //   productProvider.getProducts();
    }
  }

  void _setInitialOrderSelection() {
    final orderProvider = context.read<OrderProvider>();
    try {
      final initialOrder = orderProvider.orders.firstWhere(
        (order) => order.id == widget.initialOrderId,
      );
      setState(() {
        _selectedOrder = initialOrder;
      });
    } catch (e) {
      // Order not found, will be handled by the dropdown
      debugPrint('Initial order not found: ${widget.initialOrderId}');
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _customizationNotesController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
      ),
      child: Container(
        width: ResponsiveBreakpoints.responsive(
          context,
          tablet: 450,
          small: 500,
          medium: 550,
          large: 600,
          ultrawide: 650,
        ),
        padding: EdgeInsets.all(context.cardPadding * 1.5),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.addNewOrderItem,
                    style: TextStyle(
                      fontSize: context.headerFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoalGray,
                      letterSpacing: 0.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      size: ResponsiveBreakpoints.responsive(
                        context,
                        tablet: 20,
                        small: 22,
                        medium: 24,
                        large: 26,
                        ultrawide: 28,
                      ),
                    ),
                    padding: EdgeInsets.all(context.smallPadding / 2),
                  ),
                ],
              ),
              SizedBox(height: context.cardPadding),

              // Order Selection
              _buildOrderDropdown(l10n),
              SizedBox(height: context.cardPadding),

              // Product Selection
              _buildProductDropdown(l10n),
              SizedBox(height: context.cardPadding),

              // Product Name
              _buildFormField(
                context,
                controller: _productNameController,
                label: '${l10n.productName} *',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.productNameIsRequired;
                  }
                  return null;
                },
              ),
              SizedBox(height: context.cardPadding),

              // Customization Notes
              _buildFormField(
                context,
                controller: _customizationNotesController,
                label: l10n.customizationNotes,
                maxLines: 3,
              ),
              SizedBox(height: context.cardPadding),

              // Quantity and Unit Price Row
              Row(
                children: [
                  Expanded(
                    child: _buildFormField(
                      context,
                      controller: _quantityController,
                      label: '${l10n.quantity} *',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.quantityIsRequired;
                        }
                        if (int.tryParse(value) == null) {
                          return l10n.pleaseEnterValidNumber;
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: context.cardPadding),
                  Expanded(
                    child: _buildFormField(
                      context,
                      controller: _unitPriceController,
                      label: '${l10n.unitPrice} *',
                      keyboardType: TextInputType.number,
                      prefixText: 'PKR ',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.unitPriceIsRequired;
                        }
                        if (double.tryParse(value) == null) {
                          return l10n.pleaseEnterValidNumber;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.cardPadding * 1.5),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  SizedBox(width: context.cardPadding),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      foregroundColor: AppTheme.pureWhite,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.cardPadding,
                        vertical: context.smallPadding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          context.borderRadius('medium'),
                        ),
                      ),
                    ),
                    child: Text(
                      l10n.addOrderItem,
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? prefixText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
        ),
        labelStyle: TextStyle(
          fontSize: context.subtitleFontSize,
          fontWeight: FontWeight.w400,
          color: Colors.grey[600],
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.smallPadding,
          vertical: context.smallPadding,
        ),
      ),
      style: TextStyle(
        fontSize: context.bodyFontSize,
        fontWeight: FontWeight.w400,
        color: AppTheme.charcoalGray,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  void _submitForm() {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState!.validate()) {
      // Validate that order and product are selected
      if (_selectedOrder == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.pleaseSelectAnOrder,
              style: TextStyle(
                fontSize: context.captionFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.pleaseSelectAProduct,
              style: TextStyle(
                fontSize: context.captionFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final quantity = int.parse(_quantityController.text);
      final unitPrice = double.parse(_unitPriceController.text);

      context
          .read<OrderItemProvider>()
          .createOrderItem(
            orderId: _selectedOrder!.id,
            productId: _selectedProduct!.id,
            quantity: quantity,
            unitPrice: unitPrice,
            customizationNotes: _customizationNotesController.text,
          )
          .then((success) {
            if (success) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.orderItemCreatedSuccessfully,
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.failedToCreateOrderItem,
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          })
          .catchError((error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${l10n.error}: $error',
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: Colors.red,
              ),
            );
          });
    }
  }

  Widget _buildOrderDropdown(AppLocalizations l10n) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return _buildSearchableDropdown<OrderModel>(
          label: '${l10n.selectOrder} *',
          hint: l10n.typeCustomerNameToSearch,
          value: _selectedOrder,
          items: _getOrderDropdownItems(orderProvider, l10n),
          onChanged: (order) {
            setState(() {
              _selectedOrder = order;
            });
          },
          prefixIcon: Icons.receipt_long_outlined,
          searchHint: l10n.searchByCustomerName,
        );
      },
    );
  }

  Widget _buildProductDropdown(AppLocalizations l10n) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return _buildSearchableDropdown<ProductModel>(
          label: '${l10n.selectProduct} *',
          hint: l10n.typeProductNameToSearch,
          value: _selectedProduct,
          items: _getProductDropdownItems(productProvider, l10n),
          onChanged: (product) {
            setState(() {
              _selectedProduct = product;
            });
          },
          prefixIcon: Icons.inventory_2_outlined,
          searchHint: l10n.searchByProductName,
        );
      },
    );
  }

  Widget _buildSearchableDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownItem<T?>> items,
    required ValueChanged<T?> onChanged,
    IconData? prefixIcon,
    String? searchHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.subtitleFontSize,
            fontWeight: FontWeight.w500,
            color: AppTheme.charcoalGray,
          ),
        ),
        SizedBox(height: context.smallPadding / 2),
        InkWell(
          onTap: () => _showSearchableDropdown<T>(
            context,
            items,
            value,
            onChanged,
            searchHint,
          ),
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.smallPadding,
              vertical: context.smallPadding,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(
                context.borderRadius('small'),
              ),
              color: AppTheme.pureWhite,
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(
                    prefixIcon,
                    size: context.iconSize('small'),
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: context.smallPadding / 2),
                ],
                Expanded(
                  child: Text(
                    value != null
                        ? items
                              .firstWhere(
                                (item) => item.value == value,
                                orElse: () =>
                                    DropdownItem<T?>(value: null, label: ''),
                              )
                              .label
                        : hint,
                    style: TextStyle(
                      fontSize: context.bodyFontSize,
                      color: value != null
                          ? AppTheme.charcoalGray
                          : Colors.grey[500],
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down_rounded, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchableDropdown<T>(
    BuildContext context,
    List<DropdownItem<T?>> items,
    T? currentValue,
    ValueChanged<T?> onChanged,
    String? searchHint,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final searchController = TextEditingController();
    List<DropdownItem<T?>> filteredItems = List.from(items);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                context.borderRadius('large'),
              ),
            ),
            child: Container(
              width: 400,
              padding: EdgeInsets.all(context.cardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.select} ${T == OrderModel ? l10n.order : l10n.product}',
                    style: TextStyle(
                      fontSize: context.headerFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.charcoalGray,
                    ),
                  ),
                  SizedBox(height: context.cardPadding),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: searchHint ?? l10n.search,
                      hintStyle: TextStyle(
                        fontSize: context.subtitleFontSize,
                        color: Colors.grey[600],
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          context.borderRadius('small'),
                        ),
                      ),
                    ),
                    onChanged: (query) {
                      setState(() {
                        if (query.isEmpty) {
                          filteredItems = List.from(items);
                        } else {
                          filteredItems = items
                              .where(
                                (item) => item.label.toLowerCase().contains(
                                  query.toLowerCase(),
                                ),
                              )
                              .toList();
                        }
                      });
                    },
                  ),
                  SizedBox(height: context.cardPadding),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return ListTile(
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          onTap: () {
                            onChanged(item.value);
                            Navigator.of(context).pop();
                          },
                          tileColor: item.value == currentValue
                              ? AppTheme.primaryMaroon.withOpacity(0.1)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<DropdownItem<OrderModel?>> _getOrderDropdownItems(
    OrderProvider orderProvider,
    AppLocalizations l10n,
  ) {
    final orders = orderProvider.orders;
    return [
      DropdownItem<OrderModel?>(value: null, label: l10n.selectAnOrder),
      ...orders
          .map(
            (order) => DropdownItem<OrderModel?>(
              value: order,
              label: '${order.customerName} - ${order.id.substring(0, 8)}...',
            ),
          )
          .toList(),
    ];
  }

  List<DropdownItem<ProductModel?>> _getProductDropdownItems(
    ProductProvider productProvider,
    AppLocalizations l10n,
  ) {
    final products = productProvider.products;
    return [
      DropdownItem<ProductModel?>(value: null, label: l10n.selectAProduct),
      ...products
          .map(
            (product) => DropdownItem<ProductModel?>(
              value: product,
              label: '${product.name} - ${product.id.substring(0, 8)}...',
            ),
          )
          .toList(),
    ];
  }
}
