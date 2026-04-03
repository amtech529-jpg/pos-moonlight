import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/auth_provider.dart';
import '../../../src/providers/customer_provider.dart';
import '../../../src/theme/app_theme.dart';
import '../../widgets/customer/add_customer_dialog.dart';
import '../../widgets/customer/custom_filter_dialog.dart';
import '../../widgets/customer/customer_table.dart';
import '../../widgets/customer/delete_customer_dialog.dart';
import '../../widgets/customer/edit_customer_dialog.dart';
import '../../widgets/customer/view_customer_dialog.dart';
import '../../../l10n/app_localizations.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().refreshCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddCustomerDialog(),
    );
  }

  void _showEditCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditCustomerDialog(customer: customer),
    );
  }

  void _showDeleteCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedDeleteCustomerDialog(customer: customer),
    );
  }

  void _showViewCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ViewCustomerDetailsDialog(customer: customer),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CustomerFilterDialog(),
    );
  }

  Future<void> _handleRefresh() async {
    final provider = context.read<CustomerProvider>();
    await provider.refreshCustomers();

    if (provider.hasError && mounted) {
      _showErrorSnackbar(
        provider.errorMessage ??
            AppLocalizations.of(context)!.failedToRefreshCustomers,
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final bool canAdd = currentUser?.canPerform('Customer Management', 'add') ?? true;
    final bool canEdit = currentUser?.canPerform('Customer Management', 'edit') ?? true;
    final bool canDelete = currentUser?.canPerform('Customer Management', 'delete') ?? true;

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          return _buildNormalContent(provider, canAdd, canEdit, canDelete);
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
              Icon(
                Icons.screen_rotation_outlined,
                size: 15.w,
                color: Colors.grey[400],
              ),
              SizedBox(height: 3.h),
              Text(
                l10n.screenTooSmall,
                style: TextStyle(
                  fontSize: 6.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Text(
                l10n.screenTooSmallMessage,
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

  Widget _buildNormalContent(CustomerProvider provider, bool canAdd, bool canEdit, bool canDelete) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppTheme.primaryMaroon,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(context.mainPadding / 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            ResponsiveBreakpoints.responsive(
              context,
              tablet: _buildTabletHeader(canAdd),
              small: _buildMobileHeader(canAdd),
              medium: _buildDesktopHeader(canAdd),
              large: _buildDesktopHeader(canAdd),
              ultrawide: _buildDesktopHeader(canAdd),
            ),

            SizedBox(height: context.mainPadding),

            context.statsCardColumns == 2
                ? _buildMobileStatsGrid(provider)
                : _buildDesktopStatsRow(provider),

            SizedBox(height: context.cardPadding * 0.5),

            _buildSearchSection(provider),

            SizedBox(height: context.cardPadding * 0.5),

            _buildActiveFilters(provider),

            // Full-page table (No Expanded needed since parent is scrolling)
            _buildMainContent(provider, canEdit, canDelete),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(CustomerProvider provider, bool canEdit, bool canDelete) {
    if (provider.isLoading && provider.customers.isEmpty) {
      return _buildLoadingWidget();
    }

    if (provider.customers.isEmpty) {
      // Logic: If error exists, show error, else show empty
      if (provider.hasError) {
        return _buildErrorStateWidget(
            provider.errorMessage ?? AppLocalizations.of(context)!.failedToRefreshCustomers
        );
      }
      return _buildEmptyStateWidget();
    }

    // ✅ If we are here, we have customers. Show the table.
    return EnhancedCustomerTable(
      onEdit: _showEditCustomerDialog,
      onDelete: _showDeleteCustomerDialog,
      onView: _showViewCustomerDialog,
      canEdit: canEdit,
      canDelete: canDelete,
    );
  }

  // --- Header Widgets ---

  Widget _buildDesktopHeader(bool canAdd) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.customerManagement,
                style: TextStyle(
                  fontSize: context.headingFontSize / 1.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoalGray,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: context.cardPadding / 4),
              Text(
                l10n.customerManagementDescription,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (canAdd) _buildAddButton(),
      ],
    );
  }

  Widget _buildTabletHeader(bool canAdd) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customerManagement,
          style: TextStyle(
            fontSize: context.headingFontSize / 1.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.customerManagementShortDescription,
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        if (canAdd) ...[
          SizedBox(height: context.cardPadding),
          SizedBox(width: double.infinity, child: _buildAddButton()),
        ],
      ],
    );
  }

  Widget _buildMobileHeader(bool canAdd) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customers,
          style: TextStyle(
            fontSize: context.headerFontSize,
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoalGray,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.customerManagementShortDescription,
          style: TextStyle(
            fontSize: context.bodyFontSize,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
        ),
        if (canAdd) ...[
          SizedBox(height: context.cardPadding),
          SizedBox(width: double.infinity, child: _buildAddButton()),
        ],
      ],
    );
  }

  Widget _buildAddButton() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon],
        ),
        borderRadius: BorderRadius.circular(context.borderRadius()),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showAddCustomerDialog,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.cardPadding * 0.5,
              vertical: context.cardPadding / 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  color: AppTheme.pureWhite,
                  size: context.iconSize('medium'),
                ),
                SizedBox(width: context.smallPadding),
                Text(
                  context.isTablet ? l10n.add : l10n.addCustomer,
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

  Widget _buildDesktopStatsRow(CustomerProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final stats = provider.customerStats;
    return Row(
      children: [
        Expanded(
          child: _buildStatsCard(
            l10n.totalCustomers,
            stats['total'].toString(),
            Icons.people_rounded,
            Colors.blue,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            l10n.newThisMonth,
            stats['newThisMonth'].toString(),
            Icons.person_add_rounded,
            Colors.green,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            l10n.totalSales,
            _getTotalSalesCount(provider),
            Icons.shopping_cart_rounded,
            AppTheme.primaryMaroon,
          ),
        ),
        SizedBox(width: context.cardPadding),
        Expanded(
          child: _buildStatsCard(
            l10n.recentBuyers,
            stats['recentBuyers'].toString(),
            Icons.shopping_bag_rounded,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatsGrid(CustomerProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final stats = provider.customerStats;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                l10n.total,
                stats['total'].toString(),
                Icons.people_rounded,
                Colors.blue,
              ),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard(
                l10n.newCustomer,
                stats['newThisMonth'].toString(),
                Icons.person_add_rounded,
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
                l10n.totalSales,
                _getTotalSalesCount(provider),
                Icons.shopping_cart_rounded,
                AppTheme.primaryMaroon,
              ),
            ),
            SizedBox(width: context.cardPadding),
            Expanded(
              child: _buildStatsCard(
                l10n.recent,
                stats['recentBuyers'].toString(),
                Icons.shopping_bag_rounded,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchSection(CustomerProvider provider) {
    return Container(
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: context.shadowBlur(),
            offset: Offset(0, context.smallPadding),
          ),
        ],
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

  Widget _buildDesktopSearchLayout(CustomerProvider provider) {
    return Row(
      children: [
        Expanded(flex: 1, child: _buildSearchBar(provider)),
        SizedBox(width: context.cardPadding),
        Expanded(flex: 1, child: _buildShowInactiveToggle(provider)),
        SizedBox(width: context.smallPadding),
        Expanded(flex: 1, child: _buildFilterButton(provider)),
        SizedBox(width: context.smallPadding),
      ],
    );
  }

  Widget _buildTabletSearchLayout(CustomerProvider provider) {
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

  Widget _buildMobileSearchLayout(CustomerProvider provider) {
    return Column(
      children: [
        _buildSearchBar(provider),
        SizedBox(height: context.smallPadding),
        Row(
          children: [
            Expanded(child: _buildShowInactiveToggle(provider)),
            SizedBox(width: context.smallPadding),
            Expanded(child: _buildFilterButton(provider)),
            SizedBox(width: context.smallPadding),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(CustomerProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: context.buttonHeight / 1.5,
      child: TextField(
        controller: _searchController,
        onChanged: provider.searchCustomers,
        style: TextStyle(
          fontSize: context.bodyFontSize,
          color: AppTheme.charcoalGray,
        ),
        decoration: InputDecoration(
          hintText: context.isTablet
              ? l10n.searchCustomersShortHint
              : l10n.searchCustomersHint,
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
              provider.clearSearch();
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
    );
  }

  Widget _buildShowInactiveToggle(CustomerProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: context.buttonHeight / 1.5,
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
      decoration: BoxDecoration(
        color: provider.showInactive
            ? AppTheme.primaryMaroon.withOpacity(0.1)
            : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
          color: provider.showInactive
              ? AppTheme.primaryMaroon.withOpacity(0.3)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: provider.toggleShowInactive,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              provider.showInactive ? Icons.visibility : Icons.visibility_off,
              color: provider.showInactive
                  ? AppTheme.primaryMaroon
                  : Colors.grey[600],
              size: context.iconSize('medium'),
            ),
            if (!context.isTablet) ...[
              SizedBox(width: context.smallPadding),
              Text(
                provider.showInactive
                    ? l10n.hideInactive
                    : l10n.showInactive,
                style: TextStyle(
                  fontSize: ResponsiveBreakpoints.getDashboardBodyFontSize(context),
                  fontWeight: FontWeight.w500,
                  color: provider.showInactive
                      ? AppTheme.primaryMaroon
                      : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(CustomerProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final hasActiveFilters =
        provider.selectedStatus != null ||
            provider.selectedType != null ||
            provider.selectedCity != null ||
            provider.selectedCountry != null ||
            provider.verificationFilter != null;

    return Container(
      height: context.buttonHeight / 1.5,
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
      decoration: BoxDecoration(
        color: hasActiveFilters
            ? AppTheme.accentGold.withOpacity(0.1)
            : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(
          color: hasActiveFilters
              ? AppTheme.accentGold.withOpacity(0.3)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: _showFilterDialog,
        borderRadius: BorderRadius.circular(context.borderRadius()),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasActiveFilters ? Icons.filter_alt : Icons.filter_list_rounded,
              color: hasActiveFilters
                  ? AppTheme.accentGold
                  : AppTheme.primaryMaroon,
              size: context.iconSize('medium'),
            ),
            if (!context.isTablet) ...[
              SizedBox(width: context.smallPadding),
              Text(
                hasActiveFilters
                    ? '${l10n.filter} (${_getActiveFilterCount(provider)})'
                    : l10n.filter,
                style: TextStyle(
                  fontSize: context.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: hasActiveFilters
                      ? AppTheme.accentGold
                      : AppTheme.primaryMaroon,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Export button method removed

  Widget _buildActiveFilters(CustomerProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final activeFilters = <String>[];

    if (provider.selectedStatus != null) {
      activeFilters.add('${l10n.status}: ${provider.selectedStatus}');
    }
    if (provider.selectedType != null) {
      activeFilters.add('${l10n.type}: ${provider.selectedType}');
    }
    if (provider.selectedCity != null) {
      activeFilters.add('${l10n.city}: ${provider.selectedCity}');
    }
    if (provider.selectedCountry != null) {
      activeFilters.add('${l10n.country}: ${provider.selectedCountry}');
    }
    if (provider.verificationFilter != null) {
      activeFilters.add('${l10n.verified}: ${provider.verificationFilter}');
    }

    if (activeFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: context.cardPadding * 0.5),
      child: Wrap(
        spacing: context.smallPadding,
        runSpacing: context.smallPadding / 2,
        children: [
          ...activeFilters.map(
                (filter) => Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.smallPadding,
                vertical: context.smallPadding / 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  context.borderRadius('small'),
                ),
                border: Border.all(
                  color: AppTheme.primaryMaroon.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter,
                    style: TextStyle(
                      fontSize: context.captionFontSize,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryMaroon,
                    ),
                  ),
                  SizedBox(width: context.smallPadding / 2),
                  InkWell(
                    onTap: () => _clearSpecificFilter(filter, provider),
                    child: Icon(
                      Icons.close,
                      size: context.iconSize('small'),
                      color: AppTheme.primaryMaroon,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.smallPadding,
              vertical: context.smallPadding / 2,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                context.borderRadius('small'),
              ),
              border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
            ),
            child: InkWell(
              onTap: provider.clearAllFilters,
              child: Text(
                l10n.clearAll,
                style: TextStyle(
                  fontSize: context.captionFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.red[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearSpecificFilter(String filterText, CustomerProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    if (filterText.startsWith('${l10n.status}:')) {
      provider.setStatusFilter(null);
    } else if (filterText.startsWith('${l10n.type}:')) {
      provider.setTypeFilter(null);
    } else if (filterText.startsWith('${l10n.city}:')) {
      provider.setCityFilter(null);
    } else if (filterText.startsWith('${l10n.country}:')) {
      provider.setCountryFilter(null);
    } else if (filterText.startsWith('${l10n.verified}:')) {
      provider.setVerificationFilter(null);
    }
  }

  int _getActiveFilterCount(CustomerProvider provider) {
    int count = 0;
    if (provider.selectedStatus != null) count++;
    if (provider.selectedType != null) count++;
    if (provider.selectedCity != null) count++;
    if (provider.selectedCountry != null) count++;
    if (provider.verificationFilter != null) count++;
    return count;
  }

  Widget _buildStatsCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: context.statsCardHeight * 0.85, // Balanced responsive height
      padding: EdgeInsets.all(context.cardPadding * 0.6),
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
            padding: EdgeInsets.all(context.smallPadding * 0.8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.borderRadius('small')),
            ),
            child: Icon(icon, color: color, size: context.dashboardIconSize('medium')),
          ),
          SizedBox(width: context.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17, // Further reduced from 22
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                      color: AppTheme.charcoalGray,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 2), // Slightly smaller gap
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12, // Reduced from 14
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTotalSalesCount(CustomerProvider provider) {
    final totalSales = provider.customerStats['totalSales'] as int?;
    return totalSales != null ? totalSales.toString() : '0';
  }

  // ✅ WIDGET: Local Error State (not Scaffold)
  Widget _buildErrorStateWidget(String message) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 5.h),
          Icon(Icons.error_outline, size: 10.w, color: Colors.red[400]),
          SizedBox(height: 2.h),
          Text(
            '${l10n.error}: $message',
            style: TextStyle(fontSize: 4.sp, fontWeight: FontWeight.w500, color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            l10n.pleaseTryAgainOrContactSupport,
            style: TextStyle(fontSize: 3.sp, fontWeight: FontWeight.w400, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET: Local Empty State (not Scaffold)
  Widget _buildEmptyStateWidget() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 5.h),
          Icon(Icons.search_off_rounded, size: 10.w, color: Colors.grey[400]),
          SizedBox(height: 2.h),
          Text(
            l10n.noCustomersFound,
            style: TextStyle(
              fontSize: 4.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            l10n.adjustFilters,
            style: TextStyle(
              fontSize: 3.sp,
              fontWeight: FontWeight.w400,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET: Local Loading State (not Scaffold)
  Widget _buildLoadingWidget() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 5.h),
          CircularProgressIndicator(
            color: AppTheme.primaryMaroon,
            strokeWidth: 2.w,
          ),
          SizedBox(height: 2.h),
          Text(
            l10n.loadingCustomers,
            style: TextStyle(
              fontSize: 4.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.charcoalGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}