import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/order_item_provider.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/providers/order_provider.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/models/order/order_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../globals/text_button.dart';
import '../globals/text_field.dart';
import '../globals/custom_date_picker.dart';
import '../globals/drop_down.dart';

class PremiumDatePicker extends StatefulWidget {
  final String label;
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTime) onDateSelected;
  final Key? dateKey;

  const PremiumDatePicker({
    super.key,
    required this.label,
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
    this.dateKey,
  });

  @override
  State<PremiumDatePicker> createState() => _PremiumDatePickerState();
}

class _PremiumDatePickerState extends State<PremiumDatePicker> {
  late TextEditingController _controller;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _controller = TextEditingController(
      text: _selectedDate != null
          ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
          : '',
    );
  }

  @override
  void didUpdateWidget(PremiumDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDate != widget.initialDate) {
      _selectedDate = widget.initialDate;
      _controller.text = _selectedDate != null
          ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
          : '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () async {
        await context.showSyncfusionDateTimePicker(
          initialDate: _selectedDate ?? DateTime.now(),
          initialTime: const TimeOfDay(hour: 0, minute: 0),
          onDateTimeSelected: (date, time) {
            setState(() {
              _selectedDate = date;
              _controller.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
            });
            widget.onDateSelected(date);
          },
          title: '${l10n.select} ${widget.label}',
          minDate: widget.firstDate,
          maxDate: widget.lastDate,
          showTimeInline: false,
        );
      },
      child: PremiumTextField(
        label: widget.label,
        hint: l10n.selectDate,
        controller: _controller,
        prefixIcon: Icons.calendar_today_outlined,
        enabled: false,
      ),
    );
  }
}

class OrderItemFilterDialog extends StatefulWidget {
  const OrderItemFilterDialog({super.key});

  @override
  State<OrderItemFilterDialog> createState() => _OrderItemFilterDialogState();
}

class _OrderItemFilterDialogState extends State<OrderItemFilterDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  OrderModel? _selectedOrder;
  ProductModel? _selectedProduct;
  String _searchQuery = '';
  bool _showInactiveOnly = false;

  int? _minQuantity;
  int? _maxQuantity;

  double? _minPrice;
  double? _maxPrice;

  bool _hasCustomization = false;

  DateTime? _dateFrom;
  DateTime? _dateTo;

  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minQuantityController = TextEditingController();
  final TextEditingController _maxQuantityController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  final List<String> _sortByOptions = ['created_at', 'quantity', 'unit_price', 'line_total', 'product_name', 'updated_at'];

  final List<String> _sortOrderOptions = ['asc', 'desc'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderItemProvider>();
      _selectedOrder = null;
      _selectedProduct = null;
      _searchQuery = provider.searchQuery;

      _searchController.text = _searchQuery;

      _loadDropdownData();
    });

    _animationController.forward();
  }

  void _loadDropdownData() {
    final orderProvider = context.read<OrderProvider>();
    final productProvider = context.read<ProductProvider>();

    if (orderProvider.orders.isEmpty) {
      orderProvider.refreshOrders();
    }

    if (productProvider.products.isEmpty) {
      productProvider.loadProducts();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _minQuantityController.dispose();
    _maxQuantityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _handleApplyFilters() async {
    final provider = context.read<OrderItemProvider>();

    final search = _searchController.text.trim();

    final minQuantity = _minQuantityController.text.trim().isEmpty ? null : int.tryParse(_minQuantityController.text.trim());
    final maxQuantity = _maxQuantityController.text.trim().isEmpty ? null : int.tryParse(_maxQuantityController.text.trim());
    final minPrice = _minPriceController.text.trim().isEmpty ? null : double.tryParse(_minPriceController.text.trim());
    final maxPrice = _maxPriceController.text.trim().isEmpty ? null : double.tryParse(_maxPriceController.text.trim());

    _searchQuery = search;
    _minQuantity = minQuantity;
    _maxQuantity = maxQuantity;
    _minPrice = minPrice;
    _maxPrice = maxPrice;

    await provider.loadOrderItemsWithFilters(
      orderId: _selectedOrder?.id,
      productId: _selectedProduct?.id,
      refresh: true,
      minQuantity: minQuantity,
      maxQuantity: maxQuantity,
      minPrice: minPrice,
      maxPrice: maxPrice,
      hasCustomization: _hasCustomization,
      showInactive: _showInactiveOnly,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );

    _handleClose();
  }

  void _handleClearFilters() async {
    final provider = context.read<OrderItemProvider>();

    provider.clearFilters();

    _selectedOrder = null;
    _selectedProduct = null;
    _searchQuery = '';
    _showInactiveOnly = false;
    _minQuantity = null;
    _maxQuantity = null;
    _minPrice = null;
    _maxPrice = null;
    _hasCustomization = false;
    _dateFrom = null;
    _dateTo = null;
    _sortBy = 'created_at';
    _sortOrder = 'desc';

    _searchController.clear();
    _minQuantityController.clear();
    _maxQuantityController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();

    await provider.loadOrderItemsWithFilters(refresh: true);

    _handleClose();
  }

  void _handleClose() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedOrder != null) count++;
    if (_selectedProduct != null) count++;
    if (_searchQuery.isNotEmpty) count++;
    if (_minQuantity != null) count++;
    if (_maxQuantity != null) count++;
    if (_minPrice != null) count++;
    if (_maxPrice != null) count++;
    if (_hasCustomization) count++;
    if (_showInactiveOnly) count++;
    if (_dateFrom != null) count++;
    if (_dateTo != null) count++;
    if (_sortBy != 'created_at') count++;
    if (_sortOrder != 'desc') count++;
    return count;
  }

  String _getActiveFiltersText(AppLocalizations l10n) {
    final filters = <String>[];
    if (_selectedOrder != null) filters.add('${l10n.order}: ${_selectedOrder!.customerName}');
    if (_selectedProduct != null) filters.add('${l10n.product}: ${_selectedProduct!.name}');
    if (_searchQuery.isNotEmpty) filters.add('${l10n.search}: $_searchQuery');
    if (_minQuantity != null) filters.add('${l10n.minQuantity}: $_minQuantity');
    if (_maxQuantity != null) filters.add('${l10n.maxQuantity}: $_maxQuantity');
    if (_minPrice != null) filters.add('${l10n.minPricePKR}: PKR ${_minPrice!.toStringAsFixed(0)}');
    if (_maxPrice != null) filters.add('${l10n.maxPricePKR}: PKR ${_maxPrice!.toStringAsFixed(0)}');
    if (_hasCustomization) filters.add(l10n.hasCustomizationNotes);
    if (_dateFrom != null) filters.add('${l10n.dateFrom}: ${_dateFrom!.day}/${_dateFrom!.month}/${_dateFrom!.year}');
    if (_dateTo != null) filters.add('${l10n.dateTo}: ${_dateTo!.day}/${_dateTo!.month}/${_dateTo!.year}');
    if (_showInactiveOnly) filters.add(l10n.showInactiveItems);
    if (_sortBy != 'created_at') filters.add('${l10n.sortBy}: $_sortBy');
    if (_sortOrder != 'desc') filters.add('${l10n.sortOrder}: ${_sortOrder.toUpperCase()}');

    return filters.join(', ');
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
                width: ResponsiveBreakpoints.responsive(context, tablet: 98.w, small: 95.w, medium: 90.w, large: 85.w, ultrawide: 80.w),
                constraints: BoxConstraints(maxWidth: 800, maxHeight: 90.h),
                margin: EdgeInsets.all(context.mainPadding),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius('large')),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: context.shadowBlur('heavy'), offset: Offset(0, context.cardPadding)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    _buildActiveFiltersDisplay(),
                    Expanded(child: _buildFilterContent()),
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
        gradient: const LinearGradient(colors: [Colors.indigo, Colors.indigoAccent]),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Icon(Icons.filter_list_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
          ),
          SizedBox(width: context.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.orderItemFilters,
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
                    l10n.customizeOrderItemSearch,
                    style: TextStyle(
                      fontSize: context.subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.pureWhite.withOpacity(0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleClose,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Container(
                padding: EdgeInsets.all(context.smallPadding),
                child: Icon(Icons.close_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersDisplay() {
    final l10n = AppLocalizations.of(context)!;

    if (_activeFiltersCount == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.smallPadding),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: AppTheme.primaryMaroon.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined, color: AppTheme.primaryMaroon, size: context.iconSize('small')),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Text(
              '${l10n.activeFilters}: ${_getActiveFiltersText(l10n)}',
              style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.primaryMaroon),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.primaryMaroon, borderRadius: BorderRadius.circular(context.borderRadius())),
            child: Text(
              '$_activeFiltersCount',
              style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterContent() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(context.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBasicFiltersSection(),
              SizedBox(height: context.cardPadding),

              _buildSearchSection(),
              SizedBox(height: context.cardPadding),

              _buildNumericFiltersSection(),
              SizedBox(height: context.cardPadding),

              _buildDateStatusFiltersSection(),
              SizedBox(height: context.cardPadding),

              _buildSortingSection(),
              SizedBox(height: context.mainPadding),

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
    );
  }

  Widget _buildBasicFiltersSection() {
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
              Icon(Icons.filter_alt_outlined, color: Colors.blue, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.basicFilters,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(child: _buildOrderDropdown()),
              SizedBox(width: context.cardPadding),
              Expanded(child: _buildProductDropdown()),
            ],
          ),
        ],
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
          style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
        ),
        SizedBox(height: context.smallPadding / 2),
        InkWell(
          onTap: () => _showSearchableDropdown<T>(context, items, value, onChanged, searchHint),
          borderRadius: BorderRadius.circular(context.borderRadius('small')),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
              color: AppTheme.pureWhite,
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(prefixIcon, size: context.iconSize('small'), color: Colors.grey[600]),
                  SizedBox(width: context.smallPadding / 2),
                ],
                Expanded(
                  child: Text(
                    value != null
                        ? items.firstWhere((item) => item.value == value, orElse: () => DropdownItem<T?>(value: null, label: '')).label
                        : hint,
                    style: TextStyle(fontSize: context.bodyFontSize, color: value != null ? AppTheme.charcoalGray : Colors.grey[500]),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius('large'))),
            child: Container(
              width: 400,
              padding: EdgeInsets.all(context.cardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.select} ${T == OrderModel ? l10n.order : l10n.product}',
                    style: TextStyle(fontSize: context.headerFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
                  ),
                  SizedBox(height: context.cardPadding),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: searchHint ?? l10n.search,
                      hintStyle: TextStyle(fontSize: context.subtitleFontSize, color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(context.borderRadius('small'))),
                    ),
                    onChanged: (query) {
                      setState(() {
                        if (query.isEmpty) {
                          filteredItems = List.from(items);
                        } else {
                          filteredItems = items.where((item) => item.label.toLowerCase().contains(query.toLowerCase())).toList();
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
                            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400),
                          ),
                          onTap: () {
                            onChanged(item.value);
                            Navigator.of(context).pop();
                          },
                          tileColor: item.value == currentValue ? AppTheme.primaryMaroon.withOpacity(0.1) : null,
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

  List<DropdownItem<OrderModel?>> _getOrderDropdownItems(OrderProvider orderProvider, AppLocalizations l10n) {
    final orders = orderProvider.orders;
    return [
      DropdownItem<OrderModel?>(value: null, label: l10n.allOrders),
      ...orders.map((order) => DropdownItem<OrderModel?>(value: order, label: '${order.customerName} - ${order.id.substring(0, 8)}...')).toList(),
    ];
  }

  List<DropdownItem<ProductModel?>> _getProductDropdownItems(ProductProvider productProvider, AppLocalizations l10n) {
    final products = productProvider.products;
    return [
      DropdownItem<ProductModel?>(value: null, label: l10n.allProducts),
      ...products.map((product) => DropdownItem<ProductModel?>(value: product, label: '${product.name} - ${product.id.substring(0, 8)}...')).toList(),
    ];
  }

  Widget _buildSearchSection() {
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
              Icon(Icons.search_outlined, color: Colors.green, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.searchAndTextFilters,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          PremiumTextField(
            label: l10n.searchQuery,
            hint: l10n.searchInProductNames,
            controller: _searchController,
            prefixIcon: Icons.search_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildNumericFiltersSection() {
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
              Icon(Icons.tune_outlined, color: Colors.orange, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.numericRangeFilters,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: PremiumTextField(
                  label: l10n.minQuantity,
                  hint: l10n.minimumQuantity,
                  controller: _minQuantityController,
                  prefixIcon: Icons.numbers_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: PremiumTextField(
                  label: l10n.maximumQuantity,
                  hint: l10n.maximumQuantity,
                  controller: _maxQuantityController,
                  prefixIcon: Icons.numbers_outlined,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: PremiumTextField(
                  label: l10n.minPricePKR,
                  hint: l10n.minimumUnitPrice,
                  controller: _minPriceController,
                  prefixIcon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: PremiumTextField(
                  label: l10n.maxPricePKR,
                  hint: l10n.maximumUnitPrice,
                  controller: _maxPriceController,
                  prefixIcon: Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateStatusFiltersSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.purple.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range_outlined, color: Colors.purple, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.dateAndStatusFilters,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: PremiumDatePicker(
                  key: ValueKey('dateFrom_${_dateFrom?.millisecondsSinceEpoch ?? 'null'}'),
                  label: l10n.dateFrom,
                  initialDate: _dateFrom,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  onDateSelected: (date) => setState(() => _dateFrom = date),
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: PremiumDatePicker(
                  key: ValueKey('dateTo_${_dateTo?.millisecondsSinceEpoch ?? 'null'}'),
                  label: l10n.dateTo,
                  initialDate: _dateTo,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  onDateSelected: (date) => setState(() => _dateTo = date),
                ),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: Text(
                    l10n.showInactiveItems,
                    style: TextStyle(fontSize: ResponsiveBreakpoints.getDashboardSubtitleFontSize(context), fontWeight: FontWeight.w500),
                  ),
                  value: _showInactiveOnly,
                  onChanged: (value) => setState(() => _showInactiveOnly = value ?? false),
                  activeColor: Colors.purple,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: Text(
                    l10n.hasCustomizationNotes,
                    style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w500),
                  ),
                  value: _hasCustomization,
                  onChanged: (value) => setState(() => _hasCustomization = value ?? false),
                  activeColor: Colors.purple,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortingSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: Colors.teal.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sort_outlined, color: Colors.teal, size: context.iconSize('medium')),
              SizedBox(width: context.cardPadding),
              Text(
                l10n.sortingOptions,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
              ),
            ],
          ),
          SizedBox(height: context.cardPadding),
          Row(
            children: [
              Expanded(
                child: PremiumDropdownField<String>(
                  label: l10n.sortBy,
                  hint: l10n.selectSortField,
                  value: _sortBy,
                  items: _sortByOptions.map((option) {
                    return DropdownItem<String>(value: option, label: _getSortByDisplayName(option, l10n));
                  }).toList(),
                  onChanged: (value) => setState(() => _sortBy = value ?? 'created_at'),
                  prefixIcon: Icons.sort_by_alpha_outlined,
                ),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: PremiumDropdownField<String>(
                  label: l10n.sortOrder,
                  hint: l10n.selectSortOrder,
                  value: _sortOrder,
                  items: _sortOrderOptions.map((option) {
                    return DropdownItem<String>(value: option, label: option.toUpperCase());
                  }).toList(),
                  onChanged: (value) => setState(() => _sortOrder = value ?? 'desc'),
                  prefixIcon: Icons.arrow_upward_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSortByDisplayName(String sortBy, AppLocalizations l10n) {
    switch (sortBy) {
      case 'created_at':
        return l10n.createdDate;
      case 'quantity':
        return l10n.quantity;
      case 'unit_price':
        return l10n.unitPrice;
      case 'line_total':
        return l10n.lineTotal;
      case 'product_name':
        return l10n.productName;
      case 'updated_at':
        return l10n.updatedDate;
      default:
        return sortBy;
    }
  }

  Widget _buildCompactButtons() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumButton(
          text: l10n.applyFilters,
          onPressed: _handleApplyFilters,
          height: context.buttonHeight,
          icon: Icons.check_rounded,
          backgroundColor: Colors.indigo,
        ),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(
              child: PremiumButton(
                text: l10n.clearAll,
                onPressed: _handleClearFilters,
                isOutlined: true,
                height: context.buttonHeight,
                backgroundColor: Colors.red[600],
                textColor: Colors.red[600],
              ),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: PremiumButton(
                text: l10n.cancel,
                onPressed: _handleClose,
                isOutlined: true,
                height: context.buttonHeight,
                backgroundColor: Colors.grey[600],
                textColor: Colors.grey[600],
              ),
            ),
          ],
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
            text: l10n.clearAllFilters,
            onPressed: _handleClearFilters,
            isOutlined: true,
            height: context.buttonHeight / 1.5,
            backgroundColor: Colors.red[600],
            textColor: Colors.red[600],
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          flex: 1,
          child: PremiumButton(
            text: l10n.cancel,
            onPressed: _handleClose,
            isOutlined: true,
            height: context.buttonHeight / 1.5,
            backgroundColor: Colors.grey[600],
            textColor: Colors.grey[600],
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          flex: 2,
          child: PremiumButton(
            text: l10n.applyFilters,
            onPressed: _handleApplyFilters,
            height: context.buttonHeight / 1.5,
            icon: Icons.check_rounded,
            backgroundColor: Colors.indigo,
          ),
        ),
      ],
    );
  }
}
