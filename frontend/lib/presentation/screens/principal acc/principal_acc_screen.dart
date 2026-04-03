import 'package:flutter/material.dart';
import 'package:frontend/src/utils/responsive_breakpoints.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../../src/providers/prinicipal_acc_provider.dart';
import '../../../src/models/principal_account/principal_account_model.dart';
import '../../../src/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/prinicipal acc/add_principal_acc_dialog.dart';
import '../../widgets/prinicipal acc/delete_principal_acc_dialog.dart';
import '../../widgets/prinicipal acc/edit_principal_acc_dialog.dart';
import '../../widgets/prinicipal acc/principal_acc_table.dart';
import '../../widgets/prinicipal acc/view_principal_acc_dialog.dart';
import '../../widgets/principal_acc/principal_account_filter_dialog.dart';

class PrincipalAccountPage extends StatefulWidget {
  const PrincipalAccountPage({super.key});

  @override
  State<PrincipalAccountPage> createState() => _PrincipalAccountPageState();
}

class _PrincipalAccountPageState extends State<PrincipalAccountPage> {
  final TextEditingController _searchController = TextEditingController();
  
  // Local state for the current filter
  PrincipalAccountFilter _activeFilter = PrincipalAccountFilter();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddPrincipalAccountDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const AddPrincipalAccountDialog());
  }

  /// Opens the filter dialog and updates the local filter state
  void _showFilterDialog() async {
    final result = await showDialog<PrincipalAccountFilter>(
      context: context,
      builder: (context) => PrincipalAccountFilterDialog(initialFilter: _activeFilter),
    );

    if (result != null) {
      setState(() {
        _activeFilter = result;
      });
      // You can add logic here to trigger a filtered fetch from the provider
      // context.read<PrincipalAccountProvider>().fetchPrincipalAccounts(filter: _activeFilter);
    }
  }

  void _showEditPrincipalAccountDialog(PrincipalAccount account) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditPrincipalAccountDialog(account: account),
    );
  }

  void _showDeletePrincipalAccountDialog(PrincipalAccount account) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeletePrincipalAccountDialog(account: account),
    );
  }

  void _showViewPrincipalAccountDialog(PrincipalAccount account) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ViewPrincipalAccountDetailsDialog(account: account),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!context.isMinimumSupported) {
      return _buildUnsupportedScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.creamWhite,
      body: SingleChildScrollView( // Make entire screen scrollable
        child: Padding(
          padding: EdgeInsets.all(context.mainPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Use minimum size
            children: [
              ResponsiveBreakpoints.responsive(
                context,
                tablet: _buildTabletHeader(),
                small: _buildMobileHeader(),
                medium: _buildDesktopHeader(),
                large: _buildDesktopHeader(),
                ultrawide: _buildDesktopHeader(),
              ),
              SizedBox(height: context.mainPadding),
              Consumer<PrincipalAccountProvider>(
                builder: (context, provider, child) {
                  return context.statsCardColumns == 2 ? _buildMobileStatsGrid(provider) : _buildDesktopStatsRow(provider);
                },
              ),
              SizedBox(height: context.cardPadding * 0.5),
              _buildSearchSection(),
              SizedBox(height: context.cardPadding * 0.5),
              // Remove Expanded and add height constraint to table
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6, // Max 60% of screen height
                ),
                child: PrincipalAccountTable(
                  onEdit: _showEditPrincipalAccountDialog,
                  onDelete: _showDeletePrincipalAccountDialog,
                  onView: _showViewPrincipalAccountDialog,
                ),
              ),
              // Add bottom padding for scroll space
              SizedBox(height: context.mainPadding),
            ],
          ),
        ),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('large')),
                  SizedBox(width: context.cardPadding),
                  Text(
                    l10n.principalAccountLedger,
                    style: TextStyle(
                      fontSize: context.headerFontSize,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.charcoalGray,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.cardPadding / 4),
              Text(
                l10n.trackAllCashMovements,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildTabletHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('large')),
            SizedBox(width: context.cardPadding),
            Text(
              l10n.principalAccount,
              style: TextStyle(
                fontSize: context.headerFontSize,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoalGray,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.trackCashMovementsAndBalance,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
        ),
        SizedBox(height: context.cardPadding),
        SizedBox(width: double.infinity, child: _buildAddButton()),
      ],
    );
  }

  Widget _buildMobileHeader() {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
            SizedBox(width: context.smallPadding),
            Text(
              l10n.ledger,
              style: TextStyle(
                fontSize: context.headerFontSize,
                fontWeight: FontWeight.w700,
                color: AppTheme.charcoalGray,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        SizedBox(height: context.cardPadding / 4),
        Text(
          l10n.cashMovements,
          style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w400, color: Colors.grey[600]),
        ),
        SizedBox(height: context.cardPadding),
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
          onTap: _showAddPrincipalAccountDialog,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.cardPadding * 0.5, vertical: context.cardPadding / 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: AppTheme.pureWhite, size: context.iconSize('medium')),
                SizedBox(width: context.smallPadding),
                Text(
                  context.isTablet ? l10n.addEntry : l10n.addLedgerEntry,
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

  Widget _buildDesktopStatsRow(PrincipalAccountProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final stats = provider.accountStats;
    if (stats == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(child: _buildStatsCard(l10n.currentBalance, stats.formattedCurrentBalance, Icons.account_balance_wallet_rounded, Colors.blue)),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildStatsCard(l10n.totalEntries, stats.transactionCount.toString(), Icons.receipt_long_rounded, Colors.green)),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildStatsCard(l10n.totalCredits, stats.formattedTotalCredits, Icons.add_circle_outline, Colors.green)),
        SizedBox(width: context.cardPadding),
        Expanded(child: _buildStatsCard(l10n.totalDebits, stats.formattedTotalDebits, Icons.remove_circle_outline, Colors.red)),
      ],
    );
  }

  Widget _buildMobileStatsGrid(PrincipalAccountProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    final stats = provider.accountStats;
    if (stats == null) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: context.statsCardHeight / 1.2,
          padding: EdgeInsets.all(context.cardPadding),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primaryMaroon, AppTheme.secondaryMaroon]),
            borderRadius: BorderRadius.circular(context.borderRadius()),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(context.cardPadding),
                decoration: BoxDecoration(color: AppTheme.pureWhite.withOpacity(0.2), borderRadius: BorderRadius.circular(context.borderRadius())),
                child: Icon(Icons.account_balance_wallet_rounded, color: AppTheme.pureWhite, size: context.iconSize('large')),
              ),
              SizedBox(width: context.cardPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stats.formattedCurrentBalance,
                      style: TextStyle(fontSize: context.headerFontSize * 0.8, fontWeight: FontWeight.w800, color: AppTheme.pureWhite),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l10n.currentBalance,
                      style: TextStyle(
                        fontSize: context.bodyFontSize,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.pureWhite.withOpacity(0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(child: _buildStatsCard(l10n.total, stats.transactionCount.toString(), Icons.receipt_long_rounded, Colors.blue)),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildStatsCard(l10n.thisMonth, stats.monthlyTrend.length.toString(), Icons.calendar_month_rounded, Colors.green)),
          ],
        ),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(child: _buildStatsCard(l10n.credits, stats.formattedTotalCredits, Icons.add_circle_outline, Colors.green)),
            SizedBox(width: context.cardPadding),
            Expanded(child: _buildStatsCard(l10n.debits, stats.formattedTotalDebits, Icons.remove_circle_outline, Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(context.borderRadius('large')),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: context.shadowBlur(), offset: Offset(0, context.smallPadding))],
      ),
      child: ResponsiveBreakpoints.responsive(
        context,
        tablet: _buildTabletSearchLayout(),
        small: _buildMobileSearchLayout(),
        medium: _buildDesktopSearchLayout(),
        large: _buildDesktopSearchLayout(),
        ultrawide: _buildDesktopSearchLayout(),
      ),
    );
  }

  Widget _buildDesktopSearchLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildSearchBar()),
        SizedBox(width: context.cardPadding),
        Expanded(flex: 1, child: _buildFilterButton()),
      ],
    );
  }

  Widget _buildTabletSearchLayout() {
    return Column(
      children: [
        _buildSearchBar(),
        SizedBox(height: context.cardPadding),
        Row(
          children: [
            Expanded(child: _buildFilterButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileSearchLayout() {
    return Column(
      children: [
        _buildSearchBar(),
        SizedBox(height: context.smallPadding),
        Row(
          children: [
            Expanded(child: _buildFilterButton()),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: context.buttonHeight / 1.5,
      child: Consumer<PrincipalAccountProvider>(
        builder: (context, provider, child) {
          return TextField(
            controller: _searchController,
            onChanged: (query) => provider.searchAccounts(query),
            style: TextStyle(fontSize: context.bodyFontSize, color: AppTheme.charcoalGray),
            decoration: InputDecoration(
              hintText: context.isTablet ? l10n.searchLedgerEntries : l10n.searchByIdDescriptionAmount,
              hintStyle: TextStyle(fontSize: context.bodyFontSize * 0.9, color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500], size: context.iconSize('medium')),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  provider.searchAccounts('');
                },
                icon: Icon(Icons.clear_rounded, color: Colors.grey[500], size: context.iconSize('small')),
              )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2, vertical: context.cardPadding / 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterButton() {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: _showFilterDialog,
      borderRadius: BorderRadius.circular(context.borderRadius()),
      child: Container(
        height: context.buttonHeight / 1.5,
        padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(context.borderRadius()),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_rounded, color: AppTheme.primaryMaroon, size: context.iconSize('medium')),
            if (!context.isTablet) ...[
              SizedBox(width: context.smallPadding),
              Text(
                l10n.filter,
                style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.primaryMaroon),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: context.buttonHeight / 1.5,
      padding: EdgeInsets.symmetric(horizontal: context.cardPadding / 2),
      decoration: BoxDecoration(
        color: AppTheme.accentGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(context.borderRadius()),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_rounded, color: AppTheme.accentGold, size: context.iconSize('medium')),
          if (!context.isTablet) ...[
            SizedBox(width: context.smallPadding),
            Text(
              l10n.export,
              style: TextStyle(fontSize: context.bodyFontSize, fontWeight: FontWeight.w500, color: AppTheme.accentGold),
            ),
          ],
        ],
      ),
    );
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
            child: Icon(icon, color: color, size: context.dashboardIconSize('medium')),
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
                  style: TextStyle(fontSize: ResponsiveBreakpoints.getDashboardCaptionFontSize(context), fontWeight: FontWeight.w400, color: Colors.grey[600]),
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
