import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../src/models/sales/sale_model.dart';
import '../../../src/providers/sales_provider.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../widgets/sales/cart_sidebar.dart';
import '../../widgets/sales/checkout_dialog.dart';
import '../../widgets/sales/create_return_dialog.dart';
import '../../widgets/sales/delete_sales_dialog.dart';
import '../../widgets/sales/edit_sale_dialog.dart';
import '../../widgets/sales/product_grid.dart';
import '../../widgets/sales/sales_table.dart';
import '../../widgets/sales/view_sales_dialog.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerSearchController =
      TextEditingController();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Initialize SalesProvider to load products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalesProvider>(context, listen: false).initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  void _showCheckoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CheckoutDialog(),
    );
  }

  void _showSalesHistoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _buildSalesHistoryDialog(),
    );
  }

  // 2. NEW METHOD: Show Return Dialog manually
  void _showCreateReturnDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateReturnDialog(),
    );
  }

  void _showRecalculateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.refresh_rounded, color: AppTheme.primaryMaroon),
            SizedBox(width: 8),
            Text('Recalculate Sales Totals'),
          ],
        ),
        content: Text(
          'This will recalculate totals for all sales records. This may take a few moments if you have many sales.\n\nContinue?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<SalesProvider>();
              await provider.bulkRecalculateTotals();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: Colors.white,
            ),
            child: Text('Recalculate'),
          ),
        ],
      ),
    );
  }

  void _showPrintOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.print_rounded, color: AppTheme.primaryMaroon),
            SizedBox(width: 8),
            Text('Print Options'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose print option:'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
              title: Text('PDF Receipt'),
              subtitle: Text('Generate PDF receipt for printing'),
              onTap: () {
                Navigator.pop(context);
                _showSalesSelectionDialog('pdf');
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.receipt_rounded, color: Colors.blue),
              title: Text('Thermal Receipt'),
              subtitle: Text('Generate thermal-style receipt for printing'),
              onTap: () {
                Navigator.pop(context);
                _showSalesSelectionDialog('thermal');
              },
            ),
            Divider(),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Note: Thermal receipt will be generated as a PDF with thermal printer formatting.',
                style: TextStyle(color: Colors.blue, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSalesSelectionDialog(String printType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Sale'),
        content: Container(
          width: 400,
          height: 300,
          child: Consumer<SalesProvider>(
            builder: (context, provider, child) {
              if (provider.sales.isEmpty) {
                return Center(child: Text('No sales available'));
              }

              return ListView.builder(
                itemCount: provider.sales.length,
                itemBuilder: (context, index) {
                  final sale = provider.sales[index];
                  return ListTile(
                    title: Text('Invoice #${sale.invoiceNumber}'),
                    subtitle: Text(
                      '${sale.customerName} - PKR ${sale.grandTotal.toStringAsFixed(0)}',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (printType == 'pdf') {
                        provider.generateReceiptPdf(sale.id);
                      } else {
                        provider.generateSaleThermalPrint(sale.id);
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _handleViewSale(SaleModel sale) {
    // Navigator.of(context).pop(); // Optional: Close history dialog first if you want
    showDialog(
      context: context,
      builder: (context) => ViewSaleDialog(sale: sale),
    );
  }

  void _handleEditSale(SaleModel sale) {
    // Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => EditSaleDialog(sale: sale),
    );
  }

  void _handleDeleteSale(SaleModel sale) {
    // Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => DeleteSaleDialog(sale: sale),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isMinimumSupported) {
      return _buildUnsupportedScreen();
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final bool canAddSale = currentUser?.canPerform('Invoice & Payment', 'add') ?? true;
    final bool canAddReturn = currentUser?.canPerform('Return & Tally', 'add') ?? true;
    final bool canViewHistory = currentUser?.canPerform('Invoice & Payment', 'view') ?? true;
    final bool canEditSale = currentUser?.canPerform('Invoice & Payment', 'edit') ?? true;
    final bool canDeleteSale = currentUser?.canPerform('Invoice & Payment', 'delete') ?? true;

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Row(
        children: [
          // Main POS Area
          Expanded(
            flex: context.shouldShowCompactLayout ? 1 : 2,
            child: Column(
              children: [
                _buildPOSHeader(canAddReturn, canViewHistory, canEditSale, canDeleteSale),
                _buildSearchAndFilters(),
                Expanded(
                  child: ProductGrid(
                    searchQuery: _searchController.text,
                    selectedCategory: _selectedCategory,
                  ),
                ),
              ],
            ),
          ),

          // Cart Sidebar
          Container(
            width: ResponsiveBreakpoints.responsive(
              context,
              tablet: 25.w,
              small: 40.w,
              medium: 25.w,
              large: 30.w,
              ultrawide: 25.w,
            ),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: context.shadowBlur(),
                  offset: Offset(-2, 0),
                ),
              ],
            ),
            child: CartSidebar(
              onCheckout: _showCheckoutDialog,
              customerSearchController: _customerSearchController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedScreen() {
    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.screen_rotation_outlined,
                size: 15.w,
                color: Colors.grey[400],
              ),
              SizedBox(height: 3.h),
              Text(
                AppLocalizations.of(context)!.screenTooSmall,
                style: TextStyle(
                  fontSize: 6.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                AppLocalizations.of(context)!.screenTooSmallMessage,
                style: TextStyle(
                  fontSize: 3.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPOSHeader(bool canAddReturn, bool canViewHistory, bool canEditSale, bool canDeleteSale) {
    return Container(
      padding: EdgeInsets.all(context.mainPadding),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.posSystem,
                  style: TextStyle(
                    fontSize: context.headerFontSize,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoalGray,
                    letterSpacing: -0.5,
                  ),
                ),
                if (!context.isTablet) ...[
                  SizedBox(height: context.cardPadding / 4),
                ],
              ],
            ),
          ),

          // Quick Stats
          if (context.shouldShowFullLayout) ...[
            _buildQuickStat(
              AppLocalizations.of(context)!.todaySales,
              '12',
              Icons.shopping_cart_rounded,
              Colors.blue,
            ),
            SizedBox(width: context.cardPadding),
            _buildQuickStat(
              AppLocalizations.of(context)!.revenue,
              'PKR 125K',
              Icons.attach_money_rounded,
              Colors.green,
            ),
            SizedBox(width: context.cardPadding),
          ],

          // 3. NEW RETURN BUTTON ADDED HERE
          if (canAddReturn)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showCreateReturnDialog,
                borderRadius: BorderRadius.circular(context.borderRadius()),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.cardPadding,
                    vertical: context.cardPadding / 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius()),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.assignment_return_outlined,
                        color: Colors.purple,
                        size: context.iconSize('medium'),
                      ),
                      if (!context.isTablet) ...[
                        SizedBox(width: context.smallPadding),
                        Text(
                          'Return', // Label for the button
                          style: TextStyle(
                            fontSize: context.bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          if (canAddReturn) SizedBox(width: context.cardPadding),

          // View History Button
          if (canViewHistory)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showSalesHistoryDialog(canEditSale, canDeleteSale),
                borderRadius: BorderRadius.circular(context.borderRadius()),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.cardPadding,
                    vertical: context.cardPadding / 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMaroon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(context.borderRadius()),
                    border: Border.all(
                      color: AppTheme.primaryMaroon.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: AppTheme.primaryMaroon,
                        size: context.iconSize('medium'),
                      ),
                      if (!context.isTablet) ...[
                        SizedBox(width: context.smallPadding),
                        Text(
                          AppLocalizations.of(context)!.viewHistory,
                          style: TextStyle(
                            fontSize: context.bodyFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryMaroon,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          SizedBox(width: context.cardPadding),

          // Current Time
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.cardPadding,
              vertical: context.cardPadding / 2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.lightGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(context.borderRadius()),
            ),
            child: Column(
              children: [
                Text(
                  TimeOfDay.now().format(context),
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.charcoalGray,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.currentTime,
                  style: TextStyle(
                    fontSize: context.captionFontSize,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(context.smallPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: context.iconSize('medium')),
          SizedBox(width: context.smallPadding),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.charcoalGray,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesHistoryDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: ResponsiveBreakpoints.responsive(
          context,
          tablet: 95.w,
          small: 90.w,
          medium: 85.w,
          large: 80.w,
          ultrawide: 75.w,
        ),
        height: ResponsiveBreakpoints.responsive(
          context,
          tablet: 90.h,
          small: 85.h,
          medium: 80.h,
          large: 75.h,
          ultrawide: 70.h,
        ),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(context.borderRadius('large')),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: context.shadowBlur('heavy'),
              offset: Offset(0, context.cardPadding),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(context.cardPadding),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
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
                      borderRadius: BorderRadius.circular(
                        context.borderRadius(),
                      ),
                    ),
                    child: Icon(
                      Icons.history_rounded,
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
                          context.shouldShowCompactLayout
                              ? AppLocalizations.of(context)!.salesHistory
                              : AppLocalizations.of(context)!.salesHistory,
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
                            AppLocalizations.of(context)!.viewManageSales,
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

                  // Quick Stats in Header
                  if (context.shouldShowFullLayout)
                    Consumer<SalesProvider>(
                      builder: (context, provider, child) {
                        final stats = provider.salesStats;
                        return Container(
                          padding: EdgeInsets.all(context.smallPadding),
                          decoration: BoxDecoration(
                            color: AppTheme.pureWhite.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(
                              context.borderRadius(),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${stats?['total_sales'] ?? 0} ${AppLocalizations.of(context)!.sales}',
                                style: TextStyle(
                                  fontSize: context.captionFontSize,
                                  color: AppTheme.pureWhite.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                'PKR ${(stats?['total_revenue'] ?? 0).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: context.bodyFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.pureWhite,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  SizedBox(width: context.smallPadding),

                  // Recalculate Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showRecalculateDialog,
                      borderRadius: BorderRadius.circular(
                        context.borderRadius(),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(context.smallPadding),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: AppTheme.pureWhite,
                          size: context.iconSize('medium'),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: context.smallPadding),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(
                        context.borderRadius(),
                      ),
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
            ),

            // Search and Filter Bar
            Container(
              padding: EdgeInsets.all(context.cardPadding),
              color: AppTheme.lightGray.withOpacity(0.3),
              child: _buildHistoryFilters(),
            ),

            // Sales Table
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(context.cardPadding),
                child: SalesTable(
                  onView: _handleViewSale,
                  onEdit: _handleEditSale,
                  onDelete: _handleDeleteSale,
                  canEdit: canEditSale,
                  canDelete: canDeleteSale,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryFilters() {
    return Consumer<SalesProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            // Search Field
            Expanded(
              flex: 2,
              child: Container(
                height: context.buttonHeight / 1.5,
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: context.shadowBlur('light'),
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) => provider.searchSales(value),
                  style: TextStyle(
                    fontSize: context.bodyFontSize,
                    color: AppTheme.charcoalGray,
                  ),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchSales,
                    hintStyle: TextStyle(
                      fontSize: context.bodyFontSize * 0.9,
                      color: Colors.grey[500],
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Colors.grey[500],
                      size: context.iconSize('medium'),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.cardPadding / 2,
                      vertical: context.cardPadding / 2,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(width: context.cardPadding),

            // Status Filter
            if (!context.isTablet)
              Container(
                height: context.buttonHeight / 1.5,
                padding: EdgeInsets.symmetric(
                  horizontal: context.cardPadding / 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.pureWhite,
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: provider.statusFilter,
                    hint: Text(AppLocalizations.of(context)!.status),
                    onChanged: (value) {
                      if (value != null) {
                        provider.filterByStatus(value);
                      }
                    },
                    items: ['All Status', 'Paid', 'Partial', 'Unpaid'].map((
                      status,
                    ) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: context.bodyFontSize,
                            color: AppTheme.charcoalGray,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            if (!context.isTablet) SizedBox(width: context.cardPadding),

            // Export Button
            Container(
              height: context.buttonHeight / 1.5,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showPrintOptionsDialog,
                  borderRadius: BorderRadius.circular(context.borderRadius()),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.cardPadding,
                      vertical: context.cardPadding / 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        context.borderRadius(),
                      ),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.file_download_rounded,
                          color: Colors.green,
                          size: context.iconSize('medium'),
                        ),
                        if (!context.isTablet) ...[
                          SizedBox(width: context.smallPadding),
                          Text(
                            AppLocalizations.of(context)!.export,
                            style: TextStyle(
                              fontSize: context.bodyFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding),
      color: AppTheme.lightGray.withOpacity(0.3),
      child: ResponsiveBreakpoints.responsive(
        context,
        tablet: _buildCompactSearchAndFilters(),
        small: _buildCompactSearchAndFilters(),
        medium: _buildExpandedSearchAndFilters(),
        large: _buildExpandedSearchAndFilters(),
        ultrawide: _buildExpandedSearchAndFilters(),
      ),
    );
  }

  Widget _buildCompactSearchAndFilters() {
    return Column(
      children: [
        // Search bar
        Container(
          height: context.buttonHeight / 1.5,
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(context.borderRadius()),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: context.shadowBlur('light'),
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {}),
            style: TextStyle(
              fontSize: context.bodyFontSize,
              color: AppTheme.charcoalGray,
            ),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchProducts,
              hintStyle: TextStyle(
                fontSize: context.bodyFontSize * 0.9,
                color: Colors.grey[500],
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.grey[500],
                size: context.iconSize('medium'),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Colors.grey[500],
                        size: context.iconSize('small'),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: context.cardPadding / 2,
                vertical: context.cardPadding / 2,
              ),
            ),
          ),
        ),

        SizedBox(height: context.smallPadding),

        // Category filters
        SizedBox(
          height: context.buttonHeight / 1.8,
          child: Consumer<SalesProvider>(
            builder: (context, provider, child) {
              final categories = [
                'All',
                ...provider.products.map((p) => p.fabric).toSet().toList(),
              ];
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category;

                  return Container(
                    margin: EdgeInsets.only(right: context.smallPadding),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                        borderRadius: BorderRadius.circular(
                          context.borderRadius(),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.cardPadding,
                            vertical: context.smallPadding,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryMaroon
                                : AppTheme.pureWhite,
                            borderRadius: BorderRadius.circular(
                              context.borderRadius(),
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryMaroon
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            category!,
                            style: TextStyle(
                              fontSize: context.captionFontSize,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.pureWhite
                                  : AppTheme.charcoalGray,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedSearchAndFilters() {
    return Row(
      children: [
        // Search bar
        Expanded(
          flex: 2,
          child: Container(
            height: context.buttonHeight / 1.5,
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: context.shadowBlur('light'),
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              style: TextStyle(
                fontSize: context.bodyFontSize,
                color: AppTheme.charcoalGray,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchProductsExpanded,
                hintStyle: TextStyle(
                  fontSize: context.bodyFontSize * 0.9,
                  color: Colors.grey[500],
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey[500],
                  size: context.iconSize('medium'),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey[500],
                          size: context.iconSize('small'),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.cardPadding / 2,
                  vertical: context.cardPadding / 2,
                ),
              ),
            ),
          ),
        ),

        SizedBox(width: context.cardPadding),

        // Category dropdown
        Expanded(
          flex: 1,
          child: Container(
            height: context.buttonHeight / 1.5,
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
            decoration: BoxDecoration(
              color: AppTheme.pureWhite,
              borderRadius: BorderRadius.circular(context.borderRadius()),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Consumer<SalesProvider>(
              builder: (context, provider, child) {
                final categories = [
                  'All',
                  ...provider.products.map((p) => p.fabric).toSet().toList(),
                ];
                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value ?? 'All'),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(
                              category!,
                              style: TextStyle(
                                fontSize: context.bodyFontSize,
                                color: AppTheme.charcoalGray,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ),

        SizedBox(width: context.cardPadding),

        // Removed filter button as requested
      ],
    );
  }
}
