import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/models/order/order_model.dart';
import '../../../src/models/order/order_item_model.dart';
import '../../../src/providers/order_item_provider.dart';
import '../../../src/providers/order_provider.dart';
import '../../../src/services/order_item_service.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../order_item/add_order_item_dialog.dart';
import '../order_item/delete_order_item_dialog.dart';
import '../order_item/edit_order_item_dialog.dart';
import '../order_item/view_order_item_dialog.dart';
import '../order_item/order_item_table.dart';

class OrderItemsManagementDialog extends StatefulWidget {
  final OrderModel order;

  const OrderItemsManagementDialog({super.key, required this.order});

  @override
  State<OrderItemsManagementDialog> createState() => _OrderItemsManagementDialogState();
}

class _OrderItemsManagementDialogState extends State<OrderItemsManagementDialog> {
  final TextEditingController _searchController = TextEditingController();
  late OrderItemProvider _orderItemProvider;
  late OrderItemService _orderItemService;
  List<OrderItemModel> _orderItems = [];
  List<OrderItemModel> _originalOrderItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _orderItemProvider = Provider.of<OrderItemProvider>(context, listen: false);
    _orderItemService = OrderItemService();
    _loadOrderItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orderItems.isEmpty && !_isLoading) {
      _loadOrderItems();
    }
  }

  @override
  void didUpdateWidget(OrderItemsManagementDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      _loadOrderItems();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔍 Loading order items for order ID: ${widget.order.id}');

      final response = await _orderItemService.getOrderItems(
        orderId: widget.order.id,
        page: 1,
        pageSize: 100,
      );

      debugPrint('📡 API Response: success=${response.success}, message=${response.message}');

      if (response.success && response.data != null) {
        debugPrint('✅ Order items loaded: ${response.data!.orderItems.length} items found');
        setState(() {
          _orderItems = response.data!.orderItems;
          _originalOrderItems = List.from(response.data!.orderItems);
          _isLoading = false;
        });

        _orderItemProvider.refreshCache();
      } else {
        debugPrint('❌ Failed to load order items: ${response.message}');
        setState(() {
          _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to load order items';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('💥 Exception while loading order items: $e');
      setState(() {
        _errorMessage = 'Failed to load order items: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showAddOrderItemDialog() {
    debugPrint('➕ Opening Add Order Item Dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddOrderItemDialog(initialOrderId: widget.order.id),
    ).then((_) {
      debugPrint('➕ Add Order Item Dialog closed, syncing data');
      _syncOrderData();
    });
  }

  void _showEditOrderItemDialog(OrderItemModel orderItem) {
    debugPrint('✏️ Opening Edit Order Item Dialog for item: ${orderItem.id}');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditOrderItemDialog(orderItem: orderItem),
    ).then((_) {
      debugPrint('✏️ Edit Order Item Dialog closed, syncing data');
      _syncOrderData();
    });
  }

  void _showDeleteOrderItemDialog(OrderItemModel orderItem) {
    debugPrint('🗑️ Opening Delete Order Item Dialog for item: ${orderItem.id}');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteOrderItemDialog(orderItem: orderItem),
    ).then((_) {
      debugPrint('🗑️ Delete Order Item Dialog closed, syncing data');
      _syncOrderData();
    });
  }

  void _showViewOrderItemDialog(OrderItemModel orderItem) {
    debugPrint('👁️ Opening View Order Item Dialog for item: ${orderItem.id}');
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ViewOrderItemDialog(orderItem: orderItem),
    );
  }

  Future<void> _searchOrderItems(String query) async {
    if (query.isEmpty) {
      await _loadOrderItems();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _orderItemService.getOrderItems(orderId: widget.order.id, page: 1, pageSize: 100, search: query);

      if (response.success && response.data != null) {
        setState(() {
          _orderItems = response.data!.orderItems;
          _originalOrderItems = List.from(response.data!.orderItems);
          _isLoading = false;
        });
        debugPrint('🔍 Search completed: ${_orderItems.length} items found');
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty ? response.message : 'Search failed';
          _isLoading = false;
        });
        debugPrint('❌ Search failed: ${response.message}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Search error: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('💥 Search exception: $e');
    }
  }

  Future<void> _handleTableRefresh() async {
    debugPrint('🔄 Table refresh requested');
    await _syncOrderData();
  }

  Future<void> _syncOrderData() async {
    try {
      await _loadOrderItems();

      if (mounted) {
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        await orderProvider.refreshOrders();

        debugPrint('🔄 Parent order data refreshed successfully');
      }
    } catch (e) {
      debugPrint('Error syncing order data: $e');
    }
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query;
    });

    debugPrint('🔍 Search query: "$_searchQuery" (length: ${_searchQuery.length})');

    if (_searchQuery.isEmpty) {
      setState(() {
        _orderItems = List.from(_originalOrderItems);
      });
    } else if (_searchQuery.length >= 3) {
      _searchOrderItems(_searchQuery);
    } else {
      final filteredItems = _originalOrderItems.where((item) {
        return item.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.customizationNotes.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item.productColor?.toLowerCase().contains(_searchQuery.toLowerCase()) == true ||
            item.productFabric?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;
      }).toList();

      setState(() {
        _orderItems = filteredItems;
      });
    }
  }

  Future<void> _handleRefresh() async {
    final l10n = AppLocalizations.of(context)!;

    if (_searchQuery.isNotEmpty) {
      _searchController.clear();
      _searchQuery = '';
    }

    await _syncOrderData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                l10n.orderItemsRefreshedSuccessfully,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.pureWhite),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
        ),
      );
    }
  }

  String _getOrderDisplayName() {
    final l10n = AppLocalizations.of(context)!;
    final orderNumber = widget.order.id.substring(0, 8);
    final customerName = widget.order.customerName;
    final orderDate =
        '${widget.order.dateOrdered.day.toString().padLeft(2, '0')}/${widget.order.dateOrdered.month.toString().padLeft(2, '0')}/${widget.order.dateOrdered.year}';

    return '${l10n.order} #$orderNumber - $customerName ($orderDate)';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: ResponsiveBreakpoints.responsive(context, tablet: 95.w, small: 90.w, medium: 85.w, large: 80.w, ultrawide: 75.w),
        height: ResponsiveBreakpoints.responsive(context, tablet: 90.h, small: 85.h, medium: 80.h, large: 75.h, ultrawide: 70.h),
        decoration: BoxDecoration(
          color: AppTheme.creamWhite,
          borderRadius: BorderRadius.circular(context.borderRadius('large')),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchSection(),
            if (_searchQuery.isNotEmpty) _buildActiveSearchSection(),
            _buildStatsSection(),
            Expanded(child: _buildOrderItemsTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding / 1.5),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.borderRadius('large')),
          topRight: Radius.circular(context.borderRadius('large')),
        ),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.orderItemsManagement,
                  style: TextStyle(
                    fontSize: context.headingFontSize / 2,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoalGray,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: context.smallPadding / 2),
                Text(
                  _getOrderDisplayName(),
                  style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.primaryMaroon),
                ),
                SizedBox(height: context.smallPadding / 4),
                Text(
                  '${l10n.status}: ${_getStatusText(widget.order.status)} • ${l10n.total}: PKR ${widget.order.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                ),
                if (kDebugMode) ...[
                  SizedBox(height: context.smallPadding / 4),
                  Text(
                    'Debug: Order ID ${widget.order.id}',
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.blue),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close_rounded, color: Colors.grey[600], size: context.iconSize('large')),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding / 3),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: context.buttonHeight / 1.5,
              child: TextField(
                controller: _searchController,
                onChanged: _handleSearch,
                style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
                decoration: InputDecoration(
                  hintText: l10n.searchOrderItemsByProductDescriptionOrNotes,
                  hintStyle: TextStyle(fontSize: context.bodyFontSize, color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500], size: context.iconSize('medium')),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _handleSearch('');
                    },
                    icon: Icon(Icons.clear_rounded, color: Colors.grey[500], size: context.iconSize('medium')),
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.borderRadius()),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2, vertical: context.cardPadding / 2),
                ),
              ),
            ),
          ),

          SizedBox(width: context.cardPadding),

          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showAddOrderItemDialog,
                borderRadius: BorderRadius.circular(context.borderRadius()),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
                      SizedBox(width: context.smallPadding),
                      Text(
                        l10n.addItem,
                        style: TextStyle(
                          fontSize: context.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.pureWhite,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(width: context.smallPadding),

          Container(
            height: context.buttonHeight / 1.5,
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: InkWell(
              onTap: _handleRefresh,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.grey[600], size: context.iconSize('medium')),
                  SizedBox(width: context.smallPadding),
                  Text(
                    l10n.refresh,
                    style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final l10n = AppLocalizations.of(context)!;
    final totalItems = _orderItems.length;
    final totalQuantity = _orderItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalValue = _orderItems.fold<double>(0.0, (sum, item) => sum + item.lineTotal);
    final activeCount = _orderItems.where((item) => item.isActive).length;

    return Container(
      padding: EdgeInsets.all(context.cardPadding / 3),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatsCard(l10n.totalItems, totalItems.toString(), Icons.inventory_2_rounded, Colors.blue)),
          SizedBox(width: context.cardPadding / 2),
          Expanded(child: _buildStatsCard(l10n.activeItems, activeCount.toString(), Icons.check_circle_rounded, Colors.green)),
          SizedBox(width: context.cardPadding / 2),
          Expanded(child: _buildStatsCard(l10n.totalQuantity, totalQuantity.toString(), Icons.shopping_cart_rounded, Colors.purple)),
          SizedBox(width: context.cardPadding / 2),
          Expanded(child: _buildStatsCard(l10n.totalValue, 'PKR ${totalValue.toStringAsFixed(0)}', Icons.attach_money_rounded, Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: context.statsCardHeight / 2,
      padding: EdgeInsets.all(context.cardPadding / 3),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(context.borderRadius('small'))),
            child: Icon(icon, color: color, size: context.iconSize('medium')),
          ),

          SizedBox(width: context.cardPadding / 2),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: ResponsiveBreakpoints.responsive(
                      context,
                      tablet: 10.8.sp,
                      small: 11.2.sp,
                      medium: 11.6.sp,
                      large: 12.0.sp,
                      ultrawide: 12.4.sp,
                    ),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoalGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsTable() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: ResponsiveBreakpoints.responsive(context, tablet: 3.w, small: 6.w, medium: 3.w, large: 4.w, ultrawide: 3.w),
              height: ResponsiveBreakpoints.responsive(context, tablet: 3.w, small: 6.w, medium: 3.w, large: 4.w, ultrawide: 3.w),
              child: const CircularProgressIndicator(color: AppTheme.primaryMaroon, strokeWidth: 3),
            ),
            SizedBox(height: context.mainPadding),
            Text(
              l10n.loadingOrderItems,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.charcoalGray),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: context.iconSize('xl'), color: Colors.red[400]),
            SizedBox(height: context.mainPadding),
            Text(
              l10n.errorLoadingOrderItems,
              style: TextStyle(fontSize: context.headerFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
            ),
            SizedBox(height: context.smallPadding),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.mainPadding),
            ElevatedButton.icon(
              onPressed: _loadOrderItems,
              icon: Icon(Icons.refresh_rounded, color: AppTheme.pureWhite),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
              ),
            ),
          ],
        ),
      );
    }

    if (_orderItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: context.iconSize('xl'), color: Colors.grey[400]),
            SizedBox(height: context.mainPadding),
            Text(
              l10n.noOrderItemsFound,
              style: TextStyle(fontSize: context.headerFontSize, fontWeight: FontWeight.w600, color: AppTheme.charcoalGray),
            ),
            SizedBox(height: context.smallPadding),
            Text(
              l10n.orderDoesntHaveItemsYet,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.mainPadding),
            ElevatedButton.icon(
              onPressed: _showAddOrderItemDialog,
              icon: Icon(Icons.add_rounded, color: AppTheme.pureWhite),
              label: Text(l10n.addFirstItem),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryMaroon,
                padding: EdgeInsets.symmetric(horizontal: context.cardPadding, vertical: context.cardPadding / 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(context.cardPadding / 2),
      child: EnhancedOrderItemTable(
        orderItems: _orderItems,
        onRefresh: _handleTableRefresh,
        onEdit: _showEditOrderItemDialog,
        onDelete: _showDeleteOrderItemDialog,
        onView: _showViewOrderItemDialog,
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    final l10n = AppLocalizations.of(context)!;

    switch (status) {
      case OrderStatus.PENDING:
        return l10n.pending;
      case OrderStatus.CONFIRMED:
        return l10n.confirmed;
      case OrderStatus.READY:
        return l10n.ready;
      case OrderStatus.DELIVERED:
        return l10n.delivered;
      case OrderStatus.RETURNED:
        return 'Returned';
      case OrderStatus.CANCELLED:
        return l10n.cancelled;
    }
  }

  Widget _buildActiveSearchSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(context.cardPadding / 3),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.green, size: context.iconSize('small')),
          SizedBox(width: context.smallPadding),
          Text(
            '${l10n.activeSearch}: "$_searchQuery"',
            style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: Colors.green[700]),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              _searchController.clear();
              _handleSearch('');
            },
            borderRadius: BorderRadius.circular(context.borderRadius('small')),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.clear_rounded, color: Colors.red[700], size: context.iconSize('small')),
                  SizedBox(width: context.smallPadding / 2),
                  Text(
                    l10n.clearSearch,
                    style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: Colors.red[700]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
