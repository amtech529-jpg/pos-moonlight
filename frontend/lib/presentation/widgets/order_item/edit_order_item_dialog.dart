import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/order/order_item_model.dart';
import '../../../src/models/order/order_model.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/providers/order_item_provider.dart';
import '../../../src/providers/order_provider.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../globals/drop_down.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';

class EditOrderItemDialog extends StatefulWidget {
  final OrderItemModel orderItem;

  const EditOrderItemDialog({super.key, required this.orderItem});

  @override
  State<EditOrderItemDialog> createState() => _EditOrderItemDialogState();
}

class _EditOrderItemDialogState extends State<EditOrderItemDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _customizationNotesController;

  // Selected models for dropdowns
  OrderModel? _selectedOrder;
  ProductModel? _selectedProduct;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing order item data
    _quantityController = TextEditingController(
      text: widget.orderItem.quantity.toString(),
    );
    _unitPriceController = TextEditingController(
      text: widget.orderItem.unitPrice.toString(),
    );
    _customizationNotesController = TextEditingController(
      text: widget.orderItem.customizationNotes,
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Load orders and products for dropdowns
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDropdownData();
      _setInitialSelections();
    });
  }

  void _loadDropdownData() {
    // Load orders and products for dropdowns
    final orderProvider = context.read<OrderProvider>();
    final productProvider = context.read<ProductProvider>();

    if (orderProvider.orders.isEmpty) {
      orderProvider.refreshOrders();
    }

    if (productProvider.products.isEmpty) {
      //   productProvider.getProducts();
    }
  }

  void _setInitialSelections() {
    // Set initial selections based on existing order item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = context.read<OrderProvider>();
      final productProvider = context.read<ProductProvider>();

      // Find and set the current order
      final currentOrder = orderProvider.orders.firstWhere(
        (order) => order.id == widget.orderItem.orderId,
        orElse: () => OrderModel(
          id: widget.orderItem.orderId,
          customerId: '',
          customerName: 'Unknown Customer',
          customerPhone: '',
          customerEmail: '',
          advancePayment: 0.0,
          totalAmount: 0.0,
          remainingAmount: 0.0,
          isFullyPaid: false,
          dateOrdered: DateTime.now(),
          expectedDeliveryDate: DateTime.now(),
          description: '',
          status: OrderStatus.PENDING,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: null,
          createdById: null,
          conversionStatus: '',
          convertedSalesAmount: 0.0,
          conversionDate: null,
          daysSinceOrdered: 0,
          daysUntilDelivery: null,
          isOverdue: false,
          paymentPercentage: 0.0,
          orderSummary: {},
          deliveryStatus: '',
        ),
      );

      // Find and set the current product
      final currentProduct = productProvider.products.firstWhere(
        (product) => product.id == widget.orderItem.productId,
        orElse: () => ProductModel(
          id: widget.orderItem.productId,
          name: widget.orderItem.productName,
          detail: '',
          price: widget.orderItem.unitPrice,
          costPrice: null,
          color: '',
          fabric: '',
          pieces: [],
          quantity: 0,
          categoryId: null,
          categoryName: null,
          stockStatus: '',
          stockStatusDisplay: '',
          totalValue: 0.0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: null,
          createdById: null,
          createdByEmail: null,
        ),
      );

      setState(() {
        _selectedOrder = currentOrder;
        _selectedProduct = currentProduct;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _customizationNotesController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      // Validate that order and product selections haven't changed
      if (_selectedOrder?.id != widget.orderItem.orderId) {
        _showErrorSnackbar(l10n.changingOrderNotAllowed);
        return;
      }

      if (_selectedProduct?.id != widget.orderItem.productId) {
        _showErrorSnackbar(l10n.changingProductNotAllowed);
        return;
      }

      final orderItemProvider = Provider.of<OrderItemProvider>(
        context,
        listen: false,
      );

      final success = await orderItemProvider.updateOrderItem(
        id: widget.orderItem.id,
        quantity:
            int.tryParse(_quantityController.text.trim()) ??
            widget.orderItem.quantity,
        unitPrice:
            double.tryParse(_unitPriceController.text.trim()) ??
            widget.orderItem.unitPrice,
        customizationNotes: _customizationNotesController.text.trim(),
      );

      if (mounted) {
        if (success) {
          _showSuccessSnackbar();
          Navigator.of(context).pop();
        } else {
          _showErrorSnackbar(
            orderItemProvider.errorMessage ?? l10n.failedToUpdateOrderItem,
          );
        }
      }
    }
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _showSuccessSnackbar() {
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppTheme.pureWhite,
              size: context.iconSize('medium'),
            ),
            SizedBox(width: context.smallPadding),
            Text(
              l10n.orderItemUpdatedSuccessfully,
              style: TextStyle(
                fontSize: context.bodyFontSize,
                fontWeight: FontWeight.w500,
                color: AppTheme.pureWhite,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.pureWhite,
              size: context.iconSize('medium'),
            ),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.pureWhite,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.borderRadius()),
        ),
      ),
    );
  }

  double get _lineTotal {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    return quantity * unitPrice;
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

  Widget _buildOrderDropdown() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return _buildSearchableDropdown<OrderModel>(
          label: l10n.selectOrder,
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

  Widget _buildProductDropdown() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return _buildSearchableDropdown<ProductModel>(
          label: l10n.selectProduct,
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

  List<DropdownItem<OrderModel?>> _getOrderDropdownItems(
    OrderProvider orderProvider,
    AppLocalizations l10n,
  ) {
    final orders = orderProvider.orders;
    return [
      DropdownItem<OrderModel?>(value: null, label: l10n.selectAnOrder),
      ...orders.map(
        (order) => DropdownItem<OrderModel?>(
          value: order,
          label: '${order.customerName} - ${order.id.substring(0, 8)}...',
        ),
      ),
    ];
  }

  List<DropdownItem<ProductModel?>> _getProductDropdownItems(
    ProductProvider productProvider,
    AppLocalizations l10n,
  ) {
    final products = productProvider.products;
    return [
      DropdownItem<ProductModel?>(value: null, label: l10n.selectAProduct),
      ...products.map(
        (product) => DropdownItem<ProductModel?>(
          value: product,
          label: '${product.name} - ${product.id.substring(0, 8)}...',
        ),
      ),
    ];
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
                width: ResponsiveBreakpoints.responsive(
                  context,
                  tablet: 85.w,
                  small: 80.w,
                  medium: 75.w,
                  large: 70.w,
                  ultrawide: 65.w,
                ),
                constraints: BoxConstraints(maxWidth: 600, maxHeight: 85.h),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(
                    context.borderRadius('large'),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: context.shadowBlur('heavy'),
                      offset: Offset(0, context.cardPadding),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Expanded(child: _buildFormContent()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite.withOpacity(0.2),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Icon(
              Icons.edit_outlined,
              color: AppTheme.pureWhite,
              size: context.iconSize('large'),
            ),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.editOrderItem,
                  style: TextStyle(
                    fontSize: context.headerFontSize,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                if (!context.isTablet) ...[
                  SizedBox(height: context.smallPadding / 2),
                  Text(
                    l10n.updateOrderItemInformation,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.pureWhite.withOpacity(0.9),
                    ),
                  ),
                  SizedBox(height: context.smallPadding / 2),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.orderItem.id,
                          style: TextStyle(
                            fontSize: context.captionFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                      ),
                      SizedBox(width: context.smallPadding / 2),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.pureWhite.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.orderItem.productName,
                          style: TextStyle(
                            fontSize: context.captionFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleCancel,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding),
                child: Icon(
                  Icons.close_rounded,
                  color: AppTheme.pureWhite,
                  size: context.iconSize('medium'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(context.cardPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Information Section
                _buildProductInfoSection(),
                SizedBox(height: context.cardPadding),

                // Order Item Details Section
                _buildOrderItemDetailsSection(),
                SizedBox(height: context.cardPadding),

                // Line Total Section
                _buildLineTotalSection(),
                SizedBox(height: context.mainPadding),

                // Action Buttons
                ResponsiveBreakpoints.responsive(
                  context,
                  tablet: _buildCompactButtons(),
                  small: _buildCompactButtons(),
                  medium: _buildDesktopButtons(),
                  large: _buildDesktopButtons(),
                  ultrawide: _buildDesktopButtons(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfoSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Colors.blue,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.productInformation,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.productName,
            hint: l10n.productName,
            controller: TextEditingController(
              text: widget.orderItem.productName,
            ),
            prefixIcon: Icons.shopping_bag_outlined,
            enabled: false,
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(child: _buildProductDropdown()),
              SizedBox(width: context.cardPadding),
              Expanded(child: _buildOrderDropdown()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemDetailsSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_outlined,
                color: Colors.green,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.orderItemDetails,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: PremiumTextField(
                  label: '${l10n.quantity} *',
                  hint: l10n.enterQuantity,
                  controller: _quantityController,
                  prefixIcon: Icons.numbers_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return l10n.pleaseEnterQuantity;
                    }
                    final quantity = int.tryParse(value!);
                    if (quantity == null || quantity <= 0) {
                      return l10n.quantityMustBePositive;
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: PremiumTextField(
                  label: '${l10n.unitPricePKR} *',
                  hint: l10n.enterUnitPrice,
                  controller: _unitPriceController,
                  prefixIcon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return l10n.pleaseEnterUnitPrice;
                    }
                    final price = double.tryParse(value!);
                    if (price == null || price < 0) {
                      return l10n.unitPriceMustBePositive;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.customizationNotes,
            hint: l10n.enterCustomizationNotes,
            controller: _customizationNotesController,
            prefixIcon: Icons.note_outlined,
            maxLines: 3,
            validator: (value) {
              if (value != null && value.length > 500) {
                return l10n.notesMustBeLessThan500;
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLineTotalSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.orange.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                color: Colors.orange,
                size: context.iconSize('medium'),
              ),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.lineTotal,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Container(
            padding: EdgeInsets.all(context.cardPadding),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.lineTotal}:',
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
                Text(
                  'PKR ${_lineTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<OrderItemProvider>(
          builder: (context, provider, child) {
            return PremiumButton(
              text: l10n.updateOrderItem,
              onPressed: provider.isLoading ? null : _handleUpdate,
              isLoading: provider.isLoading,
              height: context.buttonHeight,
              icon: Icons.save_rounded,
              backgroundColor: Colors.blue,
            );
          },
        ),
        SizedBox(height: context.cardPadding),
        PremiumButton(
          text: l10n.cancel,
          onPressed: _handleCancel,
          isOutlined: true,
          height: context.buttonHeight,
          backgroundColor: Colors.grey[600],
          textColor: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildDesktopButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PremiumButton(
            text: l10n.cancel,
            onPressed: _handleCancel,
            height: context.buttonHeight / 1.5,
            backgroundColor: Colors.grey[600],
            textColor: AppTheme.pureWhite,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          flex: 1,
          child: Consumer<OrderItemProvider>(
            builder: (context, provider, child) {
              return PremiumButton(
                text: l10n.update,
                onPressed: provider.isLoading ? null : _handleUpdate,
                isLoading: provider.isLoading,
                height: context.buttonHeight / 1.5,
                icon: Icons.save_rounded,
                backgroundColor: Colors.blue,
              );
            },
          ),
        ),
      ],
    );
  }
}
