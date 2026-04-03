import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../src/providers/order_item_provider.dart';
import '../../../src/models/order/order_item_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../widgets/order_item/add_order_item_dialog.dart';
import '../../widgets/order_item/delete_order_item_dialog.dart';
import '../../widgets/order_item/edit_order_item_dialog.dart';
import '../../widgets/order_item/order_item_table.dart';
import '../../widgets/order_item/view_order_item_dialog.dart';
import '../../widgets/order_item/order_item_filter_dialog.dart';

class OrderItemScreen extends StatefulWidget {
  const OrderItemScreen({super.key});

  @override
  State<OrderItemScreen> createState() => _OrderItemScreenState();
}

class _OrderItemScreenState extends State<OrderItemScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<OrderItemProvider>();
      provider.loadOrderItems(); // Use the provider's load method

      // Sync search controller with provider state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchController.text = provider.searchQuery;
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddOrderItemDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const AddOrderItemDialog());
  }

  void _showEditOrderItemDialog(OrderItemModel orderItem) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditOrderItemDialog(orderItem: orderItem),
    );
  }

  void _showDeleteOrderItemDialog(OrderItemModel orderItem) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteOrderItemDialog(orderItem: orderItem),
    );
  }

  void _showViewOrderItemDialog(OrderItemModel orderItem) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ViewOrderItemDialog(orderItem: orderItem),
    );
  }

  void _showFilterDialog() {
    showDialog(context: context, barrierDismissible: true, builder: (context) => const OrderItemFilterDialog());
  }

  Future<void> _handleRefresh() async {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<OrderItemProvider>();
    await provider.loadOrderItems();

    if (provider.errorMessage != null) {
      _showErrorSnackbar(provider.errorMessage ?? l10n.failedToRefreshCustomers);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
              SizedBox(width: context.smallPadding),
              Text(
                '${l10n.orderItems} ${l10n.success.toLowerCase()}',
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

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.pureWhite, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.pureWhite),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.borderRadius())),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isMinimumSupported) {
      return _buildUnsupportedScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Consumer<OrderItemProvider>(
        builder: (context, provider, child) {
          // Sync search controller with provider state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _searchController.text != provider.searchQuery) {
              _searchController.text = provider.searchQuery;
            }
          });

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppTheme.primaryMaroon,
            child: Padding(
              padding: EdgeInsets.all(context.mainPadding / 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Responsive Header Section
                  ResponsiveBreakpoints.responsive(
                    context,
                    tablet: _buildTabletHeader(),
                    small: _buildMobileHeader(),
                    medium: _buildDesktopHeader(),
                    large: _buildDesktopHeader(),
                    ultrawide: _buildDesktopHeader(),
                  ),

                  SizedBox(height: context.cardPadding),

                  // Responsive Stats Cards
                  context.statsCardColumns == 2 ? _buildMobileStatsGrid(provider) : _buildDesktopStatsRow(provider),

                  SizedBox(height: context.cardPadding * 0.5),

                  // Responsive Search Section
                  _buildSearchSection(provider),

                  SizedBox(height: context.cardPadding * 0.5),

                  // Active Filters Display
                  _buildActiveFilters(provider),

                  // Enhanced Order Item Table with View functionality
                  Expanded(
                    child: EnhancedOrderItemTable(
                      orderItems: provider.orderItems,
                      onRefresh: () => provider.loadOrderItems(),
                      onEdit: _showEditOrderItemDialog,
                      onDelete: _showDeleteOrderItemDialog,
                      onView: _showViewOrderItemDialog,
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

  Widget _buildUnsupportedScreen() {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.screen_rotation_outlined, size: 15.w, color: Colors.grey[400]),
              SizedBox(height: 3.h),
              Text(
                l10n.screenTooSmall,
                style: TextStyle(fontSize: 6.sp, fontWeight: FontWeight.w700, color: AppTheme.charcoalGray),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                l10n.screenTooSmallMessage,
                style: TextStyle(fontSize: 3.sp, fontWeight: FontWeight.w400, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        // Page Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.orderItems} ${l10n.manageInventory}',
                style: TextStyle(
                  fontSize: context.headingFontSize / 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: context.cardPadding / 4),
              Text(
                l10n.productManagementDescription,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Add Order Item Button
        _buildAddButton(),
      ],
    );
  }

  Widget _buildTabletHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page Title
        Text(
          '${l10n.orderItems} ${l10n.manageInventory}',
          style: TextStyle(
            fontSize: context.headingFontSize / 1.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.manageInventory,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
        ),
        SizedBox(height: context.cardPadding),

        // Add Order Item Button (full width on tablet)
        SizedBox(width: double.infinity, child: _buildAddButton()),
      ],
    );
  }

  Widget _buildMobileHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Page Title
        Text(
          l10n.orderItems,
          style: TextStyle(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.manageInventory,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
        ),
        SizedBox(height: context.cardPadding),

        // Add Order Item Button (full width)
        SizedBox(width: double.infinity, child: _buildAddButton()),
      ],
    );
  }

  Widget _buildAddButton() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
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
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding * 0.5, vertical: context.cardPadding / 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
                SizedBox(width: context.smallPadding),
                Text(
                  context.isTablet ? l10n.add : '${l10n.add} ${l10n.orderItems}',
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
    );
  }

  Widget _buildDesktopStatsRow(OrderItemProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final totalItems = provider.orderItems.length;
    final totalQuantity = provider.orderItems.fold<int>(0, (sum, item) => sum + (item.quantity ?? 0));
    final totalValue = provider.orderItems.fold<double>(0.0, (sum, item) => sum + ((item.unitPrice ?? 0) * (item.quantity ?? 0)));
    final activeCount = provider.orderItems.where((item) => item.isActive).length;

    return Row(
      children: [
        Expanded(child: _buildStatsCard('${l10n.total} ${l10n.items}', totalItems.toString(), Icons.inventory_2_rounded, Colors.blue)),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildStatsCard('${l10n.activeCustomers} ${l10n.items}', activeCount.toString(), Icons.check_circle_rounded, Colors.green)),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildStatsCard('${l10n.total} ${l10n.quantity}', totalQuantity.toString(), Icons.shopping_cart_rounded, Colors.purple)),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildStatsCard('${l10n.total} ${l10n.value}', 'PKR ${totalValue.toStringAsFixed(0)}', Icons.attach_money_rounded, Colors.orange)),
      ],
    );
  }

  Widget _buildMobileStatsGrid(OrderItemProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final totalItems = provider.orderItems.length;
    final totalQuantity = provider.orderItems.fold<int>(0, (sum, item) => sum + (item.quantity ?? 0));
    final totalValue = provider.orderItems.fold<double>(0.0, (sum, item) => sum + ((item.unitPrice ?? 0) * (item.quantity ?? 0)));
    final activeCount = provider.orderItems.where((item) => item.isActive).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatsCard(l10n.total, totalItems.toString(), Icons.inventory_2_rounded, Colors.blue)),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildStatsCard(l10n.activeCustomers, activeCount.toString(), Icons.check_circle_rounded, Colors.green)),
          ],
        ),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(child: _buildStatsCard(l10n.quantity, totalQuantity.toString(), Icons.shopping_cart_rounded, Colors.purple)),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildStatsCard(l10n.value, 'PKR ${_formatValue(totalValue)}', Icons.attach_money_rounded, Colors.orange)),
          ],
        ),
      ],
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }

  Widget _buildSearchSection(OrderItemProvider provider) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: ResponsiveBreakpoints.responsive(
        context,
        tablet: _buildTabletSearchLayout(provider),
        small: _buildMobileSearchLayout(provider),
        medium: _buildDesktopSearchLayout(provider),
        large: _buildDesktopSearchLayout(provider),
        ultrawide: _buildDesktopSearchLayout(provider),
      ),
    );
  }

  Widget _buildDesktopSearchLayout(OrderItemProvider provider) {
    return Row(
      children: [
        // Search Bar
        Expanded(flex: 3, child: _buildSearchBar(provider)),

        SizedBox(width: context.cardPadding),

        // Show Inactive Toggle
        Expanded(flex: 1, child: _buildShowInactiveToggle(provider)),

        SizedBox(width: context.smallPadding),

        // Filter Button
        Expanded(flex: 1, child: _buildFilterButton(provider)),
      ],
    );
  }

  Widget _buildTabletSearchLayout(OrderItemProvider provider) {
    return Column(
      children: [
        _buildSearchBar(provider),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(child: _buildShowInactiveToggle(provider)),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildFilterButton(provider)),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileSearchLayout(OrderItemProvider provider) {
    return Column(
      children: [
        _buildSearchBar(provider),
        SizedBox(height: context.smallPadding),
        Row(
          children: [
            Expanded(child: _buildShowInactiveToggle(provider)),
            SizedBox(width: context.smallPadding),
            Expanded(child: _buildFilterButton(provider)),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(OrderItemProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: context.buttonHeight / 1.5,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          // Use debounced search to avoid too many API calls
          provider.searchOrderItemsDebounced(value);
        },
        style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
        decoration: InputDecoration(
          hintText: context.isTablet ? '${l10n.search} ${l10n.items}...' : '${l10n.searchProductsHint}',
          hintStyle: TextStyle(fontSize: context.bodyFontSize * 0.9, color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500], size: context.iconSize('medium')),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (provider.isLoading && provider.searchQuery.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(right: context.smallPadding / 2),
                  child: SizedBox(
                    width: context.iconSize('small'),
                    height: context.iconSize('small'),
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon)),
                  ),
                ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                    provider.clearSearch();
                  },
                  icon: Icon(Icons.clear_rounded, color: Colors.grey[500], size: context.iconSize('small')),
                ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2, vertical: context.cardPadding / 2),
        ),
      ),
    );
  }

  Widget _buildShowInactiveToggle(OrderItemProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: context.buttonHeight / 1.5,
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
      decoration: BoxDecoration(
        color: provider.showInactive ? AppTheme.primaryMaroon.withOpacity(0.1) : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: provider.showInactive ? AppTheme.primaryMaroon.withOpacity(0.3) : Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        onTap: () {
          provider.toggleShowInactive();
        },
        borderRadius: BorderRadius.circular(context.borderRadius()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.showInactive ? Icons.visibility : Icons.visibility_off,
              color: provider.showInactive ? AppTheme.primaryMaroon : Colors.grey[600],
              size: context.iconSize('medium'),
            ),
            if (!context.isTablet) ...[
              SizedBox(width: context.smallPadding),
              Text(
                provider.showInactive ? l10n.hideInactive : l10n.showInactive,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: provider.showInactive ? AppTheme.primaryMaroon : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(OrderItemProvider provider) {
    final l10n = AppLocalizations.of(context)!;

    // Check for active filters based on provider state
    final hasActiveFilters = provider.searchQuery.isNotEmpty || provider.currentOrderId != null || provider.currentProductId != null;

    // Count active filters
    int filterCount = 0;
    if (provider.searchQuery.isNotEmpty) filterCount++;
    if (provider.currentOrderId != null) filterCount++;
    if (provider.currentProductId != null) filterCount++;

    return Container(
      height: context.buttonHeight / 1.5,
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
      decoration: BoxDecoration(
        color: hasActiveFilters ? AppTheme.accentGold.withOpacity(0.1) : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: hasActiveFilters ? AppTheme.accentGold.withOpacity(0.3) : Colors.grey.shade300, width: 1),
      ),
      child: InkWell(
        onTap: _showFilterDialog,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasActiveFilters ? Icons.filter_alt : Icons.filter_list_rounded,
              color: hasActiveFilters ? AppTheme.accentGold : AppTheme.primaryMaroon,
              size: context.iconSize('medium'),
            ),
            if (!context.isTablet) ...[
              SizedBox(width: context.smallPadding),
              Text(
                hasActiveFilters ? '${l10n.filter} ($filterCount)' : l10n.filter,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: hasActiveFilters ? AppTheme.accentGold : AppTheme.primaryMaroon,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters(OrderItemProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final activeFilters = <MapEntry<String, String>>[];

    if (provider.searchQuery.isNotEmpty) {
      activeFilters.add(MapEntry('search', '${l10n.search}: ${provider.searchQuery}'));
    }

    if (provider.currentOrderId != null) {
      activeFilters.add(MapEntry('order', '${l10n.orders} ID: ${provider.currentOrderId}'));
    }

    if (provider.currentProductId != null) {
      activeFilters.add(MapEntry('product', '${l10n.products} ID: ${provider.currentProductId}'));
    }

    // Add more filter indicators as they are implemented in provider
    // These would be populated from the filter dialog state

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: context.cardPadding),
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, color: AppTheme.accentGold, size: context.iconSize('small')),
              SizedBox(width: context.smallPadding),
              Text(
                '${l10n.filter}:',
                style: TextStyle(fontSize: context.subtitleFontSize, fontWeight: FontWeight.w600, color: AppTheme.accentGold),
              ),
            ],
          ),
          SizedBox(height: context.smallPadding),
          Wrap(
            spacing: context.smallPadding,
            runSpacing: context.smallPadding / 2,
            children: activeFilters.map((filter) {
              return InkWell(
                onTap: () => _clearSpecificFilter(filter.key, provider),
                borderRadius: BorderRadius.circular(context.borderRadius('small')),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: context.smallPadding, vertical: context.smallPadding / 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(context.borderRadius('small')),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filter.value,
                        style: TextStyle(fontSize: context.captionFontSize, fontWeight: FontWeight.w500, color: AppTheme.accentGold),
                      ),
                      SizedBox(width: context.smallPadding / 2),
                      Icon(Icons.close, size: context.iconSize('small'), color: AppTheme.accentGold),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _clearSpecificFilter(String filterKey, OrderItemProvider provider) {
    switch (filterKey) {
      case 'search':
        _searchController.clear();
        provider.clearSearch();
        break;
      case 'order':
        provider.clearFilters();
        break;
      case 'product':
        provider.clearFilters();
        break;
      default:
      // Handle other filter types as they are implemented
        break;
    }
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: context.statsCardHeight / 1.5,
      padding: EdgeInsets.all(context.cardPadding / 2),
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

          SizedBox(width: context.cardPadding),

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
                      medium: 11.5.sp,
                      large: 11.8.sp,
                      ultrawide: 12.2.sp,
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
}
