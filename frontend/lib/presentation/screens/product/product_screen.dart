import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/product/product_model.dart';
import '../../../src/providers/product_provider.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../widgets/product/add_product_dialog.dart';
import '../../widgets/product/delete_product_dialog.dart';
import '../../widgets/product/edit_product_dialog.dart';
import '../../widgets/product/filter_product_dialog.dart';
import '../../widgets/product/product_table.dart';
import '../../widgets/product/view_product_dialog.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // Added focus node

  @override
  void initState() {
    super.initState();
    // Re-build when focus changes to update color
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    // Initialize the provider when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose(); // Dispose focus node
    super.dispose();
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddProductDialog(),
    );
  }

  void _showEditProductDialog(ProductModel product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditProductDialog(product: product),
    );
  }

  void _showDeleteProductDialog(ProductModel product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteProductDialog(product: product),
    );
  }

  void _showViewProductDialog(ProductModel product) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ViewProductDetailsDialog(product: product),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const FilterProductsDialog(),
    );
  }

  // Export functionality removed

  Future<void> _refreshProducts() async {
    await context.read<ProductProvider>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isMinimumSupported) {
      return _buildUnsupportedScreen();
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final bool canAdd = currentUser?.canPerform('Inventory', 'add') ?? true;
    final bool canEdit = currentUser?.canPerform('Inventory', 'edit') ?? true;
    final bool canDelete = currentUser?.canPerform('Inventory', 'delete') ?? true;

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit global background
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              ResponsiveBreakpoints.responsive(
                context,
                tablet: _buildTabletHeader(canAdd),
                small: _buildMobileHeader(canAdd),
                medium: _buildDesktopHeader(canAdd),
                large: _buildDesktopHeader(canAdd),
                ultrawide: _buildDesktopHeader(canAdd),
              ),

              const SizedBox(height: 18), // Precise spacing from screenshot

              // Search Bar Section
              _buildSearchSection(),

              const SizedBox(height: 24), // Spacing before table

              // Product Table Area
              EnhancedProductTable(
                onEdit: _showEditProductDialog,
                onDelete: _showDeleteProductDialog,
                onView: _showViewProductDialog,
                canEdit: canEdit,
                canDelete: canDelete,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshProducts,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.desktop_access_disabled, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Your screen size is not supported for this view.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Please use a tablet or desktop device."),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(bool canAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Inventory Management",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 2), // Tighter spacing
            Text(
              "Manage your rental equipment and items",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
        if (canAdd) _buildAddButton(),
      ],
    );
  }

  Widget _buildTabletHeader(bool canAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Inventory Management",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Manage your rental equipment and items",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 16),
        if (canAdd) _buildAddButton(),
      ],
    );
  }

  Widget _buildMobileHeader(bool canAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Inventory",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        if (canAdd) _buildAddButton(),
      ],
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton(
      onPressed: _showAddProductDialog,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF222222),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      child: const Text(
        "+Add Item",
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    );
  }

  Widget _buildDesktopStatsRow(ProductProvider provider) {
    final stats = {
      'total': provider.products.length,
      'inStock': provider.products.where((p) => p.quantity > 0).length,
      'totalValue': provider.products.fold<num>(0, (sum, p) => sum + (p.price * p.quantity)),
      'lowStock': provider.products.where((p) => p.quantity < 10).length,
    };
    return Row(
      children: [
        Expanded(
          child: _buildStatsCard(
            AppLocalizations.of(context)!.totalProducts,
            stats['total'].toString(),
            Icons.inventory_rounded,
            Colors.blue,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            AppLocalizations.of(context)!.inStock,
            stats['inStock'].toString(),
            Icons.check_circle_rounded,
            Colors.green,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            AppLocalizations.of(context)!.totalValue,
            'PKR ${stats['totalValue']}',
            Icons.attach_money_rounded,
            Colors.purple,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            AppLocalizations.of(context)!.lowStock,
            stats['lowStock'].toString(),
            Icons.warning_rounded,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatsGrid(ProductProvider provider) {
    final stats = {
      'total': provider.products.length,
      'inStock': provider.products.where((p) => p.quantity > 0).length,
      'totalValue': provider.products.fold<num>(0, (sum, p) => sum + (p.price * p.quantity)),
      'lowStock': provider.products.where((p) => p.quantity < 10).length,
    };
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                AppLocalizations.of(context)!.total,
                stats['total'].toString(),
                Icons.inventory_rounded,
                Colors.blue,
              ),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard(
                AppLocalizations.of(context)!.inStock,
                stats['inStock'].toString(),
                Icons.check_circle_rounded,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                AppLocalizations.of(context)!.value,
                'PKR ${stats['totalValue']}',
                Icons.attach_money_rounded,
                Colors.purple,
              ),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard(
                AppLocalizations.of(context)!.lowStock,
                stats['lowStock'].toString(),
                Icons.warning_rounded,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white, // Outer container is White as requested
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000), // #00000040 shadow
            offset: Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.transparent, // Background moving to TextField
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              focusNode: _searchFocusNode,
              controller: _searchController,
              onChanged: (value) => context.read<ProductProvider>().searchProducts(value),
              cursorColor: Colors.black,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 15, color: Colors.black),
              decoration: InputDecoration(
                filled: true, // Internal fill color enabled
                fillColor: _searchFocusNode.hasFocus 
                    ? const Color(0xFFD9D9D9).withOpacity(0.7) 
                    : const Color(0xFFE8E8E8), // Correct default color
                hintText: "Search Inventory...",
                hintStyle: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 15),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF8E8E8E),
                  size: 22,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Export button removed

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      height: context.statsCardHeight / 1.5,
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: Offset(0, context.smallPadding),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.smallPadding),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                context.borderRadius('small'),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: context.dashboardIconSize('medium'),
            ),
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
                      tablet: 10.8.sp, // Original size
                      small: 11.2.sp, // Original size
                      medium: 11.5.sp, // Original size
                      large: 11.8.sp, // Original size
                      ultrawide: 12.2.sp, // Original size
                    ),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoalGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveBreakpoints.getDashboardCaptionFontSize(
                      context,
                    ), // Use dashboard-specific size
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
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
